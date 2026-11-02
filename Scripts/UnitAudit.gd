extends Node
## Data-driven audit: every card -> unit scene, instantiated INTO the live tree and ticked.
## Run: godot --headless --path . res://Scenes/UnitAudit.tscn
## Prints every finding; exits 1 if any "ERROR" findings exist.

var findings: Array = []
var errors: int = 0

func _note(sev: String, who: String, msg: String):
	findings.append("[%s] %s: %s" % [sev, who, msg])
	if sev == "ERROR":
		errors += 1

func _collect_meshes(n: Node, out: Array):
	if n is MeshInstance3D and n.mesh != null:
		out.append(n)
	for c in n.get_children():
		_collect_meshes(c, out)

func _ready():
	await get_tree().process_frame
	var dir = DirAccess.open("res://Data/Cards")
	var names: Array = []
	dir.list_dir_begin()
	var f = dir.get_next()
	while f != "":
		if f.ends_with(".tres"):
			names.append(f)
		f = dir.get_next()
	names.sort()

	var arena = Node3D.new()
	arena.name = "AuditArena"
	add_child(arena)
	# Real floor so units settle exactly as they do in a match.
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(400, 2, 400)
	floor_shape.shape = floor_box
	floor_shape.position = Vector3(0, -1.0, 0)
	floor_body.add_child(floor_shape)
	arena.add_child(floor_body)

	var seen_scenes := {}
	var cmdr_count := 0
	for fn in names:
		var card = load("res://Data/Cards/" + fn)
		var who: String = fn.replace(".tres", "")
		if card == null:
			_note("ERROR", who, "card failed to load")
			continue
		# ---- card data sanity ----
		if card.cost <= 0.0 and card.card_type != "Commander":
			_note("ERROR", who, "non-positive cost %s" % card.cost)
		if card.card_name.strip_edges() == "" or card.card_name == "Unknown Unit":
			_note("ERROR", who, "card_name unset")
		if card.description.strip_edges() == "" or card.description == "A standard unit.":
			_note("WARN", who, "placeholder description")
		if card.unit_scene == null:
			_note("ERROR", who, "no unit_scene")
			continue
		if card.card_type == "Commander":
			cmdr_count += 1
		var sp: String = card.unit_scene.resource_path
		seen_scenes[sp] = seen_scenes.get(sp, 0) + 1

		if card.is_spell:
			continue

		# ---- instantiate into live tree ----
		var u = card.unit_scene.instantiate()
		u.name = who + "_audit"
		arena.add_child(u)
		if u is Node3D:
			# Same spawn offset ArenaManager.sync_spawn_card uses (+2.0 y, then gravity settles it)
			u.global_position = Vector3(randf_range(-30, 30), 2.0, randf_range(-30, 30))
		await get_tree().process_frame

		# stat consistency: apply card HP exactly like sync_spawn_card, then compare
		var hc = u.get_node_or_null("HealthComponent")
		if hc and hc.has_method("set_max_health") and (card.max_hp != 100.0 or hc.max_health == 100.0):
			hc.set_max_health(card.max_hp)
		if hc == null:
			_note("ERROR", who, "no HealthComponent")
		else:
			if absf(hc.max_health - card.max_hp) > 0.5:
				_note("WARN", who, "card max_hp %.0f != HealthComponent max_health %.0f" % [card.max_hp, hc.max_health])
			if hc.current_health > hc.max_health + 0.01 or hc.current_health <= 0.0:
				_note("ERROR", who, "bad starting health %.1f/%.1f" % [hc.current_health, hc.max_health])
		# NOTE: Unit.max_health is only a one-time seed into HealthComponent (the HealthComponent
		# is the source of truth for damage/heal/AI), so it is intentionally not compared here.

		# ---- tick physics with a nearby enemy so move/attack animation code paths run ----
		var foe = null
		var u_team := ""
		for g in u.get_groups():
			if str(g).begins_with("Side"):
				u_team = str(g)
		if "team" in u:
			u.set("team", "SideA")
		u.add_to_group("SideA")
		u.add_to_group("Targetable")
		foe = Node3D.new()
		foe.name = "AuditDummyFoe"
		var fhc = HealthComponent.new()
		fhc.name = "HealthComponent"
		fhc.max_health = 99999.0
		fhc.current_health = 99999.0
		foe.add_child(fhc)
		foe.add_to_group("SideB")
		foe.add_to_group("Targetable")
		arena.add_child(foe)
		if u is Node3D:
			foe.global_position = u.global_position + Vector3(0, 0, -6.0)
		for i in range(3):
			await get_tree().physics_frame
			if not is_instance_valid(u):
				break
		if is_instance_valid(u):
			_check_visual(u, who)
		if is_instance_valid(u) and u is Node3D:
			var p: Vector3 = u.global_position
			if is_nan(p.x) or is_nan(p.y) or is_nan(p.z):
				_note("ERROR", who, "position became NaN after ticking")
			elif p.y < -5.0:
				_note("ERROR", who, "fell through the world (y=%.1f)" % p.y)
		if is_instance_valid(foe):
			foe.queue_free()
		if is_instance_valid(u):
			u.queue_free()
		await get_tree().process_frame

	if cmdr_count < 12:
		_note("WARN", "decks", "only %d commander cards found (expected >= 12 factions)" % cmdr_count)

	print("\n================ UNIT AUDIT FINDINGS ================")
	for l in findings:
		print(l)
	print("================ %d cards audited, %d ERROR(S), %d total findings ================" % [names.size(), errors, findings.size()])
	await get_tree().process_frame
	await get_tree().physics_frame
	get_tree().quit(1 if errors > 0 else 0)

const FLYER_HINTS := ["Plane", "Flyer", "Pyrodactyl", "Dragon", "Bat", "Beetle", "Jelly", "Eagle", "Condor", "Raven", "Owl", "Hornet", "Wasp", "Bee", "Mosquito", "Dragonfly", "Locust", "Falcon", "Crow", "Jay", "Magpie", "Rook", "Jackdaw", "Goose", "Pelican", "Shoebill", "Woodpecker", "Sprite", "Gargoyle", "Reindeer", "Spire", "Tower", "Bay", "Overlord", "Meteor", "Drone", "Harpy", "Secretary", "Pecking", "Hawk", "Vulture", "Stork"]

func _check_visual(u: Node, who: String):
	var meshes: Array = []
	_collect_meshes(u, meshes)
	if meshes.is_empty():
		_note("ERROR", who, "NO visible mesh at all (invisible unit)")
		return
	var low := INF
	var high := -INF
	var bad_nan := false
	for m in meshes:
		var a: AABB = m.global_transform * m.get_aabb()
		if is_nan(a.position.x) or is_nan(a.size.x) or is_inf(a.size.x):
			bad_nan = true
			continue
		low = minf(low, a.position.y)
		high = maxf(high, a.position.y + a.size.y)
	if bad_nan:
		_note("ERROR", who, "mesh AABB has NaN/Inf (broken transform)")
		return
	if low == INF:
		return
	var height: float = high - low
	var is_flyer := false
	for h in FLYER_HINTS:
		if h in who:
			is_flyer = true
			break
	if height < 0.15:
		_note("WARN", who, "model very flat/tiny (height %.2f)" % height)
	if height > 14.0 and not ("Dragon" in who or "Beast" in who or "Maw" in who):
		_note("WARN", who, "model very tall (height %.1f)" % height)
	# floor is at y=0 in the audit arena, so lowest vertex is the true buried depth
	if low < -0.6:
		_note("ERROR", who, "model buried %.2fm below ground (lowest vertex y=%.2f)" % [-low, low])
	if low > 2.5 and not is_flyer:
		_note("WARN", who, "model floats %.2fm above ground (non-flyer?)" % low)

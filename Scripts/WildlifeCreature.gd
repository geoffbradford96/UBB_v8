extends CharacterBody3D
class_name WildlifeCreature

const WildlifeModelBuilder = preload("res://Scripts/WildlifeModelBuilder.gd")
const GpuAcceleratorScript = preload("res://Scripts/GpuAccelerator.gd")

@export var species_id: String = "WildlifeMonkey"
@export var speed: float = 5.0
@export var attack_damage: float = 12.0
@export var attack_range: float = 1.8
@export var attack_speed: float = 1.2
@export var aggro_range: float = 12.0
@export var is_flying: bool = false
@export var flight_height: float = 5.5
@export var drops_rocks: bool = false
@export var is_pecking: bool = false
@export var poison_dps: float = 0.0
@export var poison_ticks: int = 0
@export var projectile_type: String = "NONE"
@export var is_commander: bool = false
@export var unit_attribute: String = "Beast"

var team: String = "SideA":
	set(val):
		team = val
		if val != "":
			add_to_group(val)
var target: Node3D = null
var attack_timer: float = 0.0
var is_selected: bool = false
var manual_target_pos: Vector3 = Vector3.ZERO
var has_manual_order: bool = false
var manual_attack_target: Node3D = null
var patrol_point_a: Vector3 = Vector3.ZERO
var patrol_point_b: Vector3 = Vector3.ZERO
var is_patrolling: bool = false
var assigned_lane: String = "Center"
var is_following_lane: bool = true

var _anim_phase: float = 0.0
var _retarget_timer: float = 0.0
var _aura_timer: float = 0.0
var _queen_spawn_timer: float = 0.0
var _strike_flash: float = 0.0
var _archetype: String = "QUADRUPED"

var _model_root: Node3D = null
var _base_model_scale: Vector3 = Vector3.ONE
var _base_head_pos: Vector3 = Vector3.ZERO
var _head_pivot: Node3D = null
var _jaw_pivot: Node3D = null
var _tail_pivot: Node3D = null
var _wing_l: Node3D = null
var _wing_r: Node3D = null
var _leg_fl: Node3D = null
var _leg_fr: Node3D = null
var _leg_ml: Node3D = null
var _leg_mr: Node3D = null
var _leg_bl: Node3D = null
var _leg_br: Node3D = null
var _held_rock: Node3D = null
var _trunk_pivot: Node3D = null
var _ear_l: Node3D = null
var _ear_r: Node3D = null
var _neck_frill: Node3D = null
var _ballistic_tongue: Node3D = null
var _rattle_pivot: Node3D = null
var _multi_legs_l: Array[Node3D] = []
var _multi_legs_r: Array[Node3D] = []
var _body_segments: Array[Node3D] = []

@onready var health_comp: HealthComponent = get_node_or_null("HealthComponent")
@onready var visual_pivot: Node3D = get_node_or_null("VisualPivot")
@onready var selection_ring: MeshInstance3D = get_node_or_null("SelectionRing")

func is_humanoid() -> bool:
	return false

func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var r = (loop as SceneTree).root
		if r and r.has_node("GameState"):
			return r.get_node("GameState")
	return null

func _get_my_team() -> String:
	for g in get_groups():
		var gs_str = String(g)
		if gs_str.begins_with("Side"):
			return gs_str
	return team

func _is_same_team(other: Node) -> bool:
	if not is_instance_valid(other):
		return false
	var my_t = _get_my_team()
	if my_t != "" and other.is_in_group(my_t):
		return true
	for g in other.get_groups():
		var gs_str = String(g)
		if gs_str.begins_with("Side"):
			return gs_str == my_t
	var ot = other.get("team")
	if ot != null and String(ot) != "":
		return String(ot) == my_t or String(ot) == team
	return false

func _ready():
	add_to_group("Targetable")
	add_to_group("Units")
	add_to_group("WildlifeUnits")
	if team != "":
		add_to_group(team)
	_anim_phase = randf() * TAU
	_retarget_timer = randf() * 0.25

	var raw_key = species_id if (species_id != "" and species_id != "WildlifeMonkey") else name
	species_id = WildlifeModelBuilder.get_species_key(raw_key)
	var info: Dictionary = WildlifeModelBuilder.get_species_info(species_id)
	_archetype = info.get("archetype", "QUADRUPED")
	speed = float(info.get("spd", speed))
	attack_damage = float(info.get("dmg", attack_damage))
	attack_range = float(info.get("rng", attack_range))
	attack_speed = float(info.get("aspd", attack_speed))
	is_flying = bool(info.get("fly", is_flying))
	drops_rocks = bool(info.get("rock", drops_rocks))
	is_pecking = bool(info.get("peck", is_pecking))
	poison_dps = float(info.get("poison_dps", poison_dps))
	poison_ticks = int(info.get("poison_ticks", poison_ticks))
	projectile_type = String(info.get("proj", projectile_type))
	is_commander = bool(info.get("cmdr", is_commander))
	unit_attribute = "Flying" if is_flying else "Beast"

	if is_flying:
		add_to_group("Flyer")
	if is_commander:
		add_to_group("Commander")
		add_to_group("CommanderUnit")

	if health_comp:
		var base_hp = float(info.get("hp", 60.0))
		health_comp.max_health = base_hp
		health_comp.current_health = base_hp
		var nat_armor = float(info.get("armor", 0.0))
		health_comp.max_armor = nat_armor
		health_comp.current_armor = nat_armor
		if nat_armor > 0.0:
			health_comp.armor_style = "CHITIN"
		health_comp.max_shield = 0.0
		health_comp.current_shield = 0.0
		if health_comp.has_method("_setup_shield_and_armor_visuals"):
			health_comp._setup_shield_and_armor_visuals()
		if health_comp.has_method("_refresh_hp_visuals"):
			health_comp._refresh_hp_visuals()

	_model_root = WildlifeModelBuilder.build_animal_model(self, species_id)
	if _model_root:
		_base_model_scale = _model_root.scale
		_head_pivot = _model_root.get_node_or_null("HeadPivot")
		if _head_pivot:
			_base_head_pos = _head_pivot.position
			_jaw_pivot = _head_pivot.get_node_or_null("JawPivot")
			_trunk_pivot = _head_pivot.get_node_or_null("TrunkPivot")
			_ear_l = _head_pivot.get_node_or_null("EarL")
			_ear_r = _head_pivot.get_node_or_null("EarR")
			_neck_frill = _head_pivot.get_node_or_null("NeckFrill")
			if _jaw_pivot:
				_ballistic_tongue = _jaw_pivot.get_node_or_null("BallisticTongue")
		_tail_pivot = _model_root.get_node_or_null("TailPivot")
		if _tail_pivot:
			_rattle_pivot = _tail_pivot.get_node_or_null("RattlePivot")
			for i in range(9):
				var coil = _tail_pivot.get_node_or_null("Coil" + str(i)) as Node3D
				if coil:
					_body_segments.append(coil)
		for i in range(7):
			var seg = _model_root.get_node_or_null("Seg" + str(i)) as Node3D
			if seg:
				_body_segments.append(seg)
		_wing_l = _model_root.get_node_or_null("WingL")
		_wing_r = _model_root.get_node_or_null("WingR")
		_leg_fl = _model_root.get_node_or_null("LegFL")
		_leg_fr = _model_root.get_node_or_null("LegFR")
		_leg_ml = _model_root.get_node_or_null("LegML")
		_leg_mr = _model_root.get_node_or_null("LegMR")
		_leg_bl = _model_root.get_node_or_null("LegBL")
		_leg_br = _model_root.get_node_or_null("LegBR")
		_held_rock = _model_root.get_node_or_null("HeldRock")
		for idx in range(4):
			var pfx = "LegF" if idx < 2 else "LegB"
			var ml = _model_root.get_node_or_null(pfx + "L" + str(idx)) as Node3D
			var mr = _model_root.get_node_or_null(pfx + "R" + str(idx)) as Node3D
			if ml:
				_multi_legs_l.append(ml)
			if mr:
				_multi_legs_r.append(mr)

	set_selected(false)
	update_team_visuals()
	if is_flying:
		global_position.y = flight_height

func update_team_visuals():
	if visual_pivot:
		var old_ring = visual_pivot.get_node_or_null("WildlifeTeamMarker")
		if old_ring:
			old_ring.queue_free()
	if health_comp and health_comp.has_method("update_health_bar_colors"):
		health_comp.update_health_bar_colors()

func set_selected(val: bool):
	is_selected = val
	if selection_ring:
		selection_ring.visible = val

func give_move_order(pos: Vector3):
	manual_target_pos = pos
	has_manual_order = true
	is_patrolling = false
	manual_attack_target = null
	is_following_lane = false

func give_attack_order(enemy: Node3D):
	manual_attack_target = enemy
	has_manual_order = false
	is_patrolling = false
	is_following_lane = false

func give_patrol_order(p1: Vector3, p2: Vector3):
	patrol_point_a = p1
	patrol_point_b = p2
	manual_target_pos = p2
	is_patrolling = true
	has_manual_order = true
	manual_attack_target = null
	is_following_lane = false

func _physics_process(delta: float):
	if health_comp and health_comp.current_health <= 0.0:
		return
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		_animate_creature(delta, velocity.length() > 0.2)
		return

	if is_commander:
		_process_commander_abilities(delta)

	if is_flying:
		global_position.y = lerpf(global_position.y, flight_height, delta * 5.0)
		velocity.y = 0.0
	else:
		if not is_on_floor():
			velocity.y -= 18.0 * delta
		else:
			velocity.y = 0.0

	_retarget_timer -= delta
	if _retarget_timer <= 0.0:
		_retarget_timer = 0.25
		_find_target()

	var spd_mult = 1.0
	if has_meta("wildlife_pack_speed_until") and Time.get_ticks_msec() < int(get_meta("wildlife_pack_speed_until")):
		spd_mult = 1.22
	var cur_speed = speed * spd_mult

	if is_instance_valid(manual_attack_target):
		var m_hc = manual_attack_target.get_node_or_null("HealthComponent") as HealthComponent
		if m_hc and m_hc.current_health > 0.0:
			target = manual_attack_target
		else:
			manual_attack_target = null

	var moving = false
	if is_instance_valid(target):
		var d2 = Vector2(global_position.x - target.global_position.x, global_position.z - target.global_position.z).length()
		var eff_range = attack_range
		if "Base" in target.name or "CommandBay" in target.name:
			eff_range += 2.6
		elif "Tower" in target.name:
			eff_range += 1.6
		elif "Den" in target.name or "Burrow" in target.name or "Hill" in target.name or "Pit" in target.name:
			eff_range += 4.5

		if d2 <= eff_range:
			velocity.x = 0.0
			velocity.z = 0.0
			_face_position(target.global_position, delta)
			_process_combat(delta)
		else:
			_move_towards(target.global_position, cur_speed, delta)
			moving = true
	elif has_manual_order:
		var d_man = Vector2(global_position.x - manual_target_pos.x, global_position.z - manual_target_pos.z).length()
		if d_man < 1.2:
			if is_patrolling:
				var tmp = patrol_point_a
				patrol_point_a = patrol_point_b
				patrol_point_b = tmp
				manual_target_pos = patrol_point_b
			else:
				has_manual_order = false
				is_following_lane = true
		else:
			_move_towards(manual_target_pos, cur_speed, delta)
			moving = true
	else:
		var my_t = _get_my_team()
		var map_span: float = GameState.current_map_radius if GameState and GameState.current_map_radius > 15.0 else 56.0
		var forward_z = -1.0 if (my_t == "SideA" or my_t == "Player") else 1.0
		var goal_z = -map_span if (my_t == "SideA" or my_t == "Player") else map_span
		var lane_x = _get_lane_x()
		var next_pos = Vector3(lane_x, global_position.y, clampf(global_position.z + forward_z * 12.0, -map_span, map_span))
		if absf(global_position.z - goal_z) < 10.0:
			next_pos.x = 0.0
			next_pos.z = goal_z
		_move_towards(next_pos, cur_speed, delta)
		moving = true

	move_and_slide()
	if is_flying:
		global_position.y = flight_height
	_animate_creature(delta, moving)

func _get_lane_x() -> float:
	if assigned_lane == "Left":
		return -20.0
	elif assigned_lane == "Right":
		return 20.0
	return 0.0

func _face_position(pos: Vector3, delta: float):
	if not visual_pivot:
		return
	var dir = Vector3(pos.x - global_position.x, 0.0, pos.z - global_position.z)
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
		var target_basis = Basis.looking_at(dir, Vector3.UP)
		visual_pivot.basis = visual_pivot.basis.slerp(target_basis, minf(1.0, delta * 12.0)).orthonormalized()

func _move_towards(dest: Vector3, cur_speed: float, delta: float):
	var raw_dir = Vector3(dest.x - global_position.x, 0.0, dest.z - global_position.z)
	if raw_dir.length_squared() < 0.001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dir = raw_dir.normalized()

	var sep = Vector3.ZERO
	var nearby_units = GpuAcceleratorScript.query_nearby_units(global_position, 1.45, get_tree())
	for u in nearby_units:
		if u == self or not is_instance_valid(u) or not (u is Node3D):
			continue
		var u_fly = bool(u.get("is_flying")) if "is_flying" in u else false
		if u_fly != is_flying:
			continue
		var diff = Vector3(global_position.x - u.global_position.x, 0.0, global_position.z - u.global_position.z)
		var dist = diff.length()
		if dist > 0.01 and dist < 1.35:
			sep += diff.normalized() * ((1.35 - dist) / 1.35)

	if not is_flying:
		var space = get_world_3d().direct_space_state
		var from = global_position + Vector3(0, 0.5, 0)
		var q = PhysicsRayQueryParameters3D.create(from, from + dir * 2.2)
		q.exclude = [self.get_rid()]
		var hit = space.intersect_ray(q)
		if hit and hit.has("collider"):
			var col = hit["collider"]
			if is_instance_valid(col) and not col.is_in_group("Units"):
				var n = Vector3(hit["normal"].x, 0.0, hit["normal"].z).normalized()
				var slide = (dir - n * dir.dot(n)).normalized()
				if slide.length_squared() > 0.05:
					dir = slide

	var final_dir = (dir + sep * 0.75).normalized()
	if not is_flying and is_following_lane and not has_manual_order:
		var gs = _get_game_state()
		if gs and gs.has_method("get_nearest_lane_point"):
			var nearest_lp = gs.get_nearest_lane_point(global_position)
			var to_lane = Vector3(nearest_lp.x - global_position.x, 0.0, nearest_lp.z - global_position.z)
			var lane_dist = to_lane.length()
			var max_w = gs.lane_half_width if "lane_half_width" in gs else 3.2
			if lane_dist > max_w * 0.75 and (not is_instance_valid(target) or global_position.distance_to(target.global_position) > attack_range + 4.5):
				var pull_weight = clampf((lane_dist - max_w * 0.75) / maxf(0.5, max_w * 0.5), 0.0, 0.85)
				final_dir = final_dir.lerp(to_lane.normalized(), pull_weight).normalized()
	velocity.x = final_dir.x * cur_speed
	velocity.z = final_dir.z * cur_speed
	_face_position(global_position + final_dir, delta)

func _find_target():
	var best_unit: Node3D = null
	var best_unit_dist: float = aggro_range
	var best_struct: Node3D = null
	var best_struct_dist: float = 999999.0

	# O(n) candidate merge (dictionary de-dup instead of O(n^2) Array.has())
	var seen: Dictionary = {}
	var candidates: Array = []
	for grp in ["Targetable", "Units", "Structures"]:
		for c in get_tree().get_nodes_in_group(grp):
			var cid: int = c.get_instance_id()
			if not seen.has(cid):
				seen[cid] = true
				candidates.append(c)

	var can_hit_air = is_flying or drops_rocks or projectile_type != "NONE" or attack_range >= 4.0
	var gs = _get_game_state()
	var my_pos2 := Vector2(global_position.x, global_position.z)

	for node in candidates:
		if not is_instance_valid(node) or node.is_queued_for_deletion() or node == self or not (node is Node3D):
			continue
		# Cheap distance pre-filter BEFORE expensive team/HealthComponent/stealth lookups
		var pre_d: float = my_pos2.distance_to(Vector2(node.global_position.x, node.global_position.z))
		var pre_is_struct: bool = node.is_in_group("Structures") or node.is_in_group("Structure") or "Base" in node.name or "Tower" in node.name or "CommandBay" in node.name
		if pre_is_struct:
			if pre_d >= best_struct_dist:
				continue
		elif pre_d > best_unit_dist:
			continue
		if _is_same_team(node):
			continue
		if (node.is_in_group("ExplosiveBarrel") or node.is_in_group("DestructibleRock") or node.is_in_group("NeutralStructure")) and node != manual_attack_target:
			continue
		var n_hc = node.get_node_or_null("HealthComponent") as HealthComponent
		if not n_hc or n_hc.is_dead or n_hc.current_health <= 0.0:
			continue
		if gs and gs.has_method("is_unit_stealthed_from") and gs.is_unit_stealthed_from(node, self):
			continue
		var target_fly = false
		if "is_flying" in node:
			target_fly = bool(node.get("is_flying"))
		elif node.get("unit_attribute") == "Flying" or node.is_in_group("Flyer") or node.get("flight_height") != null:
			target_fly = true
		if target_fly and not can_hit_air:
			continue

		var d = Vector2(global_position.x - node.global_position.x, global_position.z - node.global_position.z).length()
		var is_struct = node.is_in_group("Structures") or node.is_in_group("Structure") or "Base" in node.name or "Tower" in node.name or "CommandBay" in node.name
		if is_struct:
			if d < best_struct_dist:
				best_struct_dist = d
				best_struct = node
		else:
			if d <= best_unit_dist:
				best_unit_dist = d
				best_unit = node

	if is_instance_valid(best_unit):
		target = best_unit
	elif is_instance_valid(best_struct):
		target = best_struct
	else:
		target = null

func _process_combat(delta: float):
	var aspd_mult = 1.0
	if has_meta("wildlife_pack_aspd_until") and Time.get_ticks_msec() < int(get_meta("wildlife_pack_aspd_until")):
		aspd_mult = 1.20
	attack_timer -= delta * aspd_mult
	if attack_timer <= 0.0:
		attack_timer = 1.0 / maxf(0.2, attack_speed)
		_perform_attack()

func _perform_attack():
	if not is_instance_valid(target):
		return
	var target_hc = target.get_node_or_null("HealthComponent") as HealthComponent
	if not target_hc or target_hc.current_health <= 0.0:
		return

	_strike_flash = 1.0

	var dmg = attack_damage
	if is_pecking and target_hc.current_armor > 0.0:
		dmg *= 1.25
	elif ("MantisShrimp" in species_id or "PistolShrimp" in species_id or "CoconutCrab" in species_id) and target_hc.current_armor > 0.0:
		dmg *= 1.45

	if drops_rocks:
		_spawn_projectile_fx(target.global_position, "ROCK")
	elif projectile_type != "NONE":
		_spawn_projectile_fx(target.global_position, projectile_type)

	target_hc.take_damage(dmg, global_position)

	if poison_dps > 0.0 and poison_ticks > 0:
		target_hc.apply_poison(poison_ticks, poison_dps)

	if "Mosquito" in species_id and health_comp and health_comp.current_health > 0.0:
		health_comp.current_health = minf(health_comp.max_health, health_comp.current_health + dmg * 0.35)

func _spawn_projectile_fx(target_pos: Vector3, p_type: String):
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	var proj = MeshInstance3D.new()
	var start_pos = global_position + Vector3(0, 0.5, 0)
	var col = Color(0.50, 0.48, 0.44)
	if p_type == "ROCK":
		var sm = SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.30
		proj.mesh = sm
		proj.scale = Vector3(1.2, 0.85, 1.05)
		start_pos = global_position + Vector3(0, -0.25 if is_flying else 0.65, 0)
	elif p_type == "VENOM" or p_type == "ACID":
		var sm = SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		proj.mesh = sm
		col = Color(0.35, 1.0, 0.20) if p_type == "VENOM" else Color(0.95, 0.85, 0.15)
	elif p_type == "QUILL":
		var cm = CylinderMesh.new()
		cm.top_radius = 0.01
		cm.bottom_radius = 0.035
		cm.height = 0.45
		proj.mesh = cm
		col = Color(0.95, 0.94, 0.88)
	elif p_type == "LIGHTNING" or p_type == "SONIC":
		var sm = SphereMesh.new()
		sm.radius = 0.18
		sm.height = 0.36
		proj.mesh = sm
		col = Color(0.25, 0.90, 1.0)
	elif p_type == "TONGUE":
		var bm = BoxMesh.new()
		bm.size = Vector3(0.08, 0.08, 0.55)
		proj.mesh = bm
		col = Color(0.95, 0.35, 0.50)
	else:
		var sm = SphereMesh.new()
		sm.radius = 0.14
		sm.height = 0.28
		proj.mesh = sm
		col = Color(0.92, 0.92, 0.96)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.2 if p_type != "ROCK" else 0.15
	proj.material_override = mat
	scene_root.add_child(proj)
	proj.global_position = start_pos

	var tw = proj.create_tween()
	tw.tween_property(proj, "global_position", target_pos + Vector3(0, 0.4, 0), 0.18)
	tw.tween_callback(proj.queue_free)

func _process_commander_abilities(delta: float):
	_aura_timer -= delta
	if _aura_timer <= 0.0:
		_aura_timer = 1.0
		var expire_ms = Time.get_ticks_msec() + 1500
		for u in get_tree().get_nodes_in_group("WildlifeUnits"):
			if not is_instance_valid(u) or not (u is Node3D):
				continue
			if not _is_same_team(u):
				continue
			if global_position.distance_to(u.global_position) <= 14.0:
				u.set_meta("wildlife_pack_speed_until", expire_ms)
				u.set_meta("wildlife_pack_aspd_until", expire_ms)

	if "QueenHornet" in species_id:
		_queen_spawn_timer += delta
		if _queen_spawn_timer >= 9.0:
			_queen_spawn_timer = 0.0
			var arena = get_tree().current_scene
			if arena and ResourceLoader.exists("res://Scenes/Units/WildlifeHornetSwarm.tscn"):
				var hornet_scene = load("res://Scenes/Units/WildlifeHornetSwarm.tscn") as PackedScene
				if hornet_scene:
					var h = hornet_scene.instantiate()
					var my_t = _get_my_team()
					h.team = my_t
					h.add_to_group(my_t)
					h.assigned_lane = assigned_lane
					arena.add_child(h)
					h.global_position = global_position + Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.5, 1.5))
					if h.has_method("update_team_visuals"):
						h.update_team_visuals()

func _animate_creature(delta: float, moving: bool):
	if not is_instance_valid(_model_root):
		return
	var rate = (8.8 if moving else 2.4) * (1.35 if is_flying else 1.0)
	_anim_phase += delta * rate
	if _strike_flash > 0.0:
		_strike_flash = maxf(0.0, _strike_flash - delta * 4.2)

	_model_root.position = Vector3.ZERO
	_model_root.rotation_degrees = Vector3.ZERO
	_model_root.scale = _base_model_scale
	if is_instance_valid(_head_pivot):
		_head_pivot.position = _base_head_pos
		_head_pivot.rotation_degrees = Vector3.ZERO
	if is_instance_valid(_jaw_pivot):
		_jaw_pivot.rotation_degrees = Vector3.ZERO
	if is_instance_valid(_held_rock):
		_held_rock.visible = (_strike_flash < 0.55)

	match _archetype:
		"SERPENT", "EEL":
			var wave_amp = 0.24 if moving else 0.08
			var yaw_amp = 24.0 if moving else 8.0
			for i in range(_body_segments.size()):
				var coil = _body_segments[i]
				if is_instance_valid(coil):
					var ph = _anim_phase * 1.45 - float(i) * 0.85
					coil.position.x = sin(ph) * wave_amp
					coil.rotation_degrees.y = cos(ph) * yaw_amp
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.y = sin(_anim_phase * 1.45) * (10.0 if moving else 4.0)
			if is_instance_valid(_head_pivot):
				_head_pivot.position.x = _base_head_pos.x + sin(_anim_phase * 1.45 + 0.6) * (0.08 if moving else 0.03)
				_head_pivot.position.z = _base_head_pos.z - _strike_flash * 0.38
				_head_pivot.rotation_degrees.x = -_strike_flash * 14.0
			if is_instance_valid(_jaw_pivot):
				_jaw_pivot.rotation_degrees.x = _strike_flash * 42.0
			if is_instance_valid(_rattle_pivot):
				var buzz = _anim_phase * (12.0 if (_strike_flash > 0.0 or is_instance_valid(target)) else 7.0)
				_rattle_pivot.rotation_degrees.x = sin(buzz) * 18.0
				_rattle_pivot.rotation_degrees.z = cos(buzz) * 18.0

		"CENTIPEDE":
			for i in range(_body_segments.size()):
				var seg = _body_segments[i]
				if is_instance_valid(seg):
					var ph = _anim_phase * 1.55 - float(i) * 0.90
					seg.position.x = sin(ph) * (0.14 if moving else 0.03)
					seg.rotation_degrees.y = cos(ph) * (22.0 if moving else 5.0)
					seg.rotation_degrees.z = sin(ph * 1.5) * (10.0 if moving else 2.0)
			if is_instance_valid(_head_pivot):
				_head_pivot.position.x = _base_head_pos.x + sin(_anim_phase * 1.55 + 0.5) * (0.08 if moving else 0.02)
				_head_pivot.position.z = _base_head_pos.z - _strike_flash * 0.24
				_head_pivot.rotation_degrees.x = _strike_flash * 18.0

		"ARACHNID", "SCORPION":
			var scuttle_amp = 24.0 if moving else 4.0
			var lift_amp = 18.0 if moving else 2.0
			for i in range(_multi_legs_l.size()):
				var ph_l = _anim_phase * 1.65 + float(i) * 1.55
				var ph_r = ph_l + PI
				var ll = _multi_legs_l[i]
				if is_instance_valid(ll):
					ll.rotation_degrees.y = sin(ph_l) * scuttle_amp
					ll.rotation_degrees.z = maxf(0.0, cos(ph_l)) * lift_amp
				if i < _multi_legs_r.size():
					var lr = _multi_legs_r[i]
					if is_instance_valid(lr):
						lr.rotation_degrees.y = sin(ph_r) * scuttle_amp
						lr.rotation_degrees.z = -maxf(0.0, cos(ph_r)) * lift_amp
			if _archetype == "SCORPION":
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.y = -_strike_flash * 28.0 + sin(_anim_phase * 0.8) * 5.0
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.y = _strike_flash * 28.0 - sin(_anim_phase * 0.8) * 5.0
				if is_instance_valid(_tail_pivot):
					_tail_pivot.rotation_degrees.x = 12.0 + sin(_anim_phase * 0.9) * 6.0 + _strike_flash * 54.0
					_tail_pivot.rotation_degrees.z = cos(_anim_phase * 0.7) * 5.0
			else:
				_model_root.rotation_degrees.x = _strike_flash * 16.0
				if is_instance_valid(_head_pivot):
					_head_pivot.rotation_degrees.x = -_strike_flash * 28.0

		"INSECT", "FLYING_INSECT", "BEETLE":
			var tri_a = sin(_anim_phase * 1.55) * (26.0 if moving else 4.0)
			var tri_b = -tri_a
			if "Mantis" in species_id:
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.x = -_strike_flash * 62.0 + sin(_anim_phase * 0.7) * 6.0
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.x = -_strike_flash * 62.0 - sin(_anim_phase * 0.7) * 6.0
			else:
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.x = tri_a
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.x = tri_b
			if is_instance_valid(_leg_mr):
				_leg_mr.rotation_degrees.x = tri_a
			if is_instance_valid(_leg_ml):
				_leg_ml.rotation_degrees.x = tri_b
			if is_instance_valid(_leg_bl):
				_leg_bl.rotation_degrees.x = tri_a
			if is_instance_valid(_leg_br):
				_leg_br.rotation_degrees.x = tri_b
			if is_instance_valid(_wing_l) and is_instance_valid(_wing_r):
				var buzz = sin(_anim_phase * 5.2) * (44.0 if is_flying else 12.0)
				_wing_l.rotation_degrees.z = buzz
				_wing_r.rotation_degrees.z = -buzz
			if is_flying:
				_model_root.position.y = sin(_anim_phase * 1.4) * 0.10
				_model_root.rotation_degrees.x = -_strike_flash * 22.0
			elif "Bombardier" in species_id:
				_model_root.rotation_degrees.x = -_strike_flash * 18.0
			if is_instance_valid(_head_pivot):
				if _archetype == "BEETLE":
					_head_pivot.rotation_degrees.x = (-10.0 if moving else 0.0) + _strike_flash * 38.0
				else:
					_head_pivot.rotation_degrees.x = -_strike_flash * 20.0 + sin(_anim_phase * 0.6) * 4.0

		"CRAB":
			var is_shrimp = ("Shrimp" in species_id)
			if not is_shrimp and moving:
				_model_root.rotation_degrees.y = 28.0
				_model_root.rotation_degrees.z = sin(_anim_phase * 1.6) * 5.0
			var c_amp = 22.0 if moving else 4.0
			for i in range(_multi_legs_l.size()):
				var ph_l = _anim_phase * 1.7 + float(i) * 1.4
				var ph_r = ph_l + PI
				var ll = _multi_legs_l[i]
				if is_instance_valid(ll):
					ll.rotation_degrees.y = sin(ph_l) * c_amp
					ll.rotation_degrees.z = maxf(0.0, cos(ph_l)) * 14.0
				if i < _multi_legs_r.size():
					var lr = _multi_legs_r[i]
					if is_instance_valid(lr):
						lr.rotation_degrees.y = sin(ph_r) * c_amp
						lr.rotation_degrees.z = -maxf(0.0, cos(ph_r)) * 14.0
			if "MantisShrimp" in species_id:
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.x = -_strike_flash * 58.0
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.x = -_strike_flash * 58.0
			elif "PistolShrimp" in species_id:
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.y = _strike_flash * 36.0
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.y = -_strike_flash * 16.0
			else:
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.y = -_strike_flash * 30.0 + sin(_anim_phase * 0.7) * 6.0
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.y = _strike_flash * 30.0 - sin(_anim_phase * 0.7) * 6.0
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.x = sin(_anim_phase * 1.8) * 16.0

		"WALRUS":
			var row_f = sin(_anim_phase) * (28.0 if moving else 5.0)
			if is_instance_valid(_leg_fl):
				_leg_fl.rotation_degrees.x = row_f
			if is_instance_valid(_leg_fr):
				_leg_fr.rotation_degrees.x = row_f
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.x = -row_f * 0.5
			if moving:
				_model_root.position.y = absf(sin(_anim_phase)) * 0.10
				_model_root.rotation_degrees.x = cos(_anim_phase) * 6.0
			if is_instance_valid(_head_pivot):
				_head_pivot.rotation_degrees.x = -_strike_flash * 36.0 + sin(_anim_phase * 0.5) * 4.0
			if is_instance_valid(_jaw_pivot):
				_jaw_pivot.rotation_degrees.x = _strike_flash * 24.0

		"SHARK", "FISH":
			if "Orca" in species_id:
				if is_instance_valid(_tail_pivot):
					_tail_pivot.rotation_degrees.x = sin(_anim_phase * 1.35) * (28.0 if moving else 10.0)
					_tail_pivot.rotation_degrees.y = 0.0
				_model_root.rotation_degrees.x = cos(_anim_phase * 1.35) * (8.0 if moving else 2.0) - _strike_flash * 16.0
				_model_root.position.y = absf(sin(_anim_phase * 0.68)) * (0.16 if moving else 0.03)
			elif "MantaRay" in species_id:
				if is_instance_valid(_wing_l) and is_instance_valid(_wing_r):
					var m_flap = sin(_anim_phase * 1.25) * 32.0
					_wing_l.rotation_degrees.z = m_flap
					_wing_r.rotation_degrees.z = -m_flap
				_model_root.position.y = sin(_anim_phase * 1.25) * 0.10
				if is_instance_valid(_tail_pivot):
					_tail_pivot.rotation_degrees.y = sin(_anim_phase) * 10.0
			elif "Mudskipper" in species_id:
				var crutch = sin(_anim_phase * 1.5) * (34.0 if moving else 6.0)
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.x = crutch
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.x = crutch
				if moving:
					_model_root.position.y = maxf(0.0, sin(_anim_phase * 1.5)) * 0.18
				if is_instance_valid(_tail_pivot):
					_tail_pivot.rotation_degrees.y = cos(_anim_phase * 1.5) * 18.0
			else:
				_model_root.rotation_degrees.y = sin(_anim_phase * 1.5) * (10.0 if moving else 3.0)
				if is_instance_valid(_tail_pivot):
					_tail_pivot.rotation_degrees.y = -cos(_anim_phase * 1.5) * (28.0 if moving else 10.0)
				if is_instance_valid(_leg_fl) and is_instance_valid(_leg_fr):
					var p_fin = sin(_anim_phase * 1.5) * 12.0
					_leg_fl.rotation_degrees.z = p_fin
					_leg_fr.rotation_degrees.z = -p_fin
				if "Piranha" in species_id and moving:
					_model_root.position.y = absf(sin(_anim_phase * 1.8)) * 0.14
				elif "Pufferfish" in species_id:
					var puff = 1.0 + _strike_flash * 0.35 + (0.12 if is_instance_valid(target) else 0.0)
					_model_root.scale = _base_model_scale * puff
			if is_instance_valid(_head_pivot):
				_head_pivot.rotation_degrees.x = -_strike_flash * 16.0
			if is_instance_valid(_jaw_pivot):
				_jaw_pivot.rotation_degrees.x = _strike_flash * 38.0

		"PRIMATE":
			var p_swing = sin(_anim_phase) * (30.0 if moving else 4.0)
			if "Gorilla" in species_id or "Chimpanzee" in species_id:
				if moving:
					_model_root.rotation_degrees.z = sin(_anim_phase) * 7.0
					_model_root.position.y = absf(sin(_anim_phase)) * 0.08
				_model_root.rotation_degrees.x = -_strike_flash * 14.0
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.x = p_swing - _strike_flash * 75.0
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.x = -p_swing - _strike_flash * 75.0
			elif "Orangutan" in species_id:
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.x = p_swing
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.x = -p_swing - _strike_flash * 85.0
			elif "Gibbon" in species_id:
				var br_swing = sin(_anim_phase) * (44.0 if moving else 8.0)
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.x = br_swing - _strike_flash * 50.0
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.x = -br_swing - _strike_flash * 50.0
			else:
				if moving:
					_model_root.position.y = absf(sin(_anim_phase * 1.3)) * 0.12
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.x = p_swing - _strike_flash * 45.0
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.x = -p_swing - _strike_flash * 45.0
			if is_instance_valid(_leg_bl):
				_leg_bl.rotation_degrees.x = -p_swing
			if is_instance_valid(_leg_br):
				_leg_br.rotation_degrees.x = p_swing
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.z = sin(_anim_phase * 1.2) * 18.0
				_tail_pivot.rotation_degrees.x = cos(_anim_phase * 0.8) * 12.0
			if is_instance_valid(_head_pivot):
				_head_pivot.rotation_degrees.x = -_strike_flash * 16.0 + sin(_anim_phase * 0.5) * 4.0
			if is_instance_valid(_jaw_pivot):
				_jaw_pivot.rotation_degrees.x = _strike_flash * 32.0

		"CORVID", "AVIAN_FLYER":
			if is_instance_valid(_wing_l) and is_instance_valid(_wing_r):
				var w_rate = 3.8 if "Hummingbird" in species_id else 2.2
				var flap = sin(_anim_phase * w_rate) * 38.0
				_wing_l.rotation_degrees.z = flap
				_wing_r.rotation_degrees.z = -flap
			_model_root.position.y = sin(_anim_phase * 2.2) * 0.10
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.x = cos(_anim_phase * 2.2) * 8.0
			var is_raptor = ("Eagle" in species_id or "Falcon" in species_id or "Owl" in species_id or "Condor" in species_id)
			if is_instance_valid(_leg_bl) and is_instance_valid(_leg_br):
				var talon_ang = -_strike_flash * (58.0 if is_raptor else 24.0)
				_leg_bl.rotation_degrees.x = talon_ang
				_leg_br.rotation_degrees.x = talon_ang
			if is_instance_valid(_head_pivot):
				if is_pecking:
					var jackhammer = absf(sin(_strike_flash * PI * 4.0)) if _strike_flash > 0.0 else 0.0
					_head_pivot.rotation_degrees.x = -jackhammer * 42.0 + sin(_anim_phase * 0.5) * 4.0
					_head_pivot.position.z = _base_head_pos.z - jackhammer * 0.16
				else:
					_head_pivot.rotation_degrees.x = -_strike_flash * 22.0 + sin(_anim_phase * 0.5) * 4.0

		"AVIAN_WALKER":
			var run_s = sin(_anim_phase * 1.35) * (38.0 if moving else 4.0)
			if is_instance_valid(_leg_bl):
				_leg_bl.rotation_degrees.x = run_s - _strike_flash * 65.0
			if is_instance_valid(_leg_br):
				_leg_br.rotation_degrees.x = -run_s
			if moving or _strike_flash > 0.0:
				_model_root.position.y = absf(sin(_anim_phase * 1.35)) * (0.10 if moving else 0.0) + _strike_flash * 0.20
			if is_instance_valid(_wing_l) and is_instance_valid(_wing_r):
				var flare = _strike_flash * 35.0 + (absf(sin(_anim_phase)) * 8.0 if moving else 0.0)
				_wing_l.rotation_degrees.z = flare
				_wing_r.rotation_degrees.z = -flare
			if is_instance_valid(_head_pivot):
				_head_pivot.position.z = _base_head_pos.z - absf(sin(_anim_phase * 1.35)) * (0.10 if moving else 0.02) - _strike_flash * 0.18
				_head_pivot.rotation_degrees.x = -_strike_flash * (38.0 if is_pecking else 22.0)
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.x = sin(_anim_phase * 1.35) * 8.0

		"CROCODILIAN":
			var c_walk = sin(_anim_phase) * (24.0 if moving else 3.0)
			if is_instance_valid(_leg_fl):
				_leg_fl.rotation_degrees.x = c_walk
			if is_instance_valid(_leg_br):
				_leg_br.rotation_degrees.x = c_walk
			if is_instance_valid(_leg_fr):
				_leg_fr.rotation_degrees.x = -c_walk
			if is_instance_valid(_leg_bl):
				_leg_bl.rotation_degrees.x = -c_walk
			_model_root.rotation_degrees.y = sin(_anim_phase) * (7.0 if moving else 1.5)
			if _strike_flash > 0.01:
				_model_root.rotation_degrees.z = (1.0 - _strike_flash) * 360.0
			for i in range(_body_segments.size()):
				var t_seg = _body_segments[i]
				if is_instance_valid(t_seg):
					t_seg.position.x = sin(_anim_phase * 1.3 - float(i) * 0.7) * (0.10 if moving else 0.03)
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.y = -cos(_anim_phase * 1.3) * (18.0 if moving else 6.0)
			if is_instance_valid(_head_pivot):
				_head_pivot.rotation_degrees.x = _strike_flash * 14.0
			if is_instance_valid(_jaw_pivot):
				_jaw_pivot.rotation_degrees.x = _strike_flash * 42.0

		"LIZARD":
			var l_rate = 0.65 if "Chameleon" in species_id else 1.25
			var l_walk = sin(_anim_phase * l_rate) * (26.0 if moving else 3.0)
			if is_instance_valid(_leg_fl):
				_leg_fl.rotation_degrees.x = l_walk
			if is_instance_valid(_leg_br):
				_leg_br.rotation_degrees.x = l_walk
			if is_instance_valid(_leg_fr):
				_leg_fr.rotation_degrees.x = -l_walk
			if is_instance_valid(_leg_bl):
				_leg_bl.rotation_degrees.x = -l_walk
			if "Frilled" in species_id:
				if moving:
					_model_root.rotation_degrees.x = 18.0
					_model_root.rotation_degrees.z = sin(_anim_phase * 1.5) * 6.0
				if is_instance_valid(_neck_frill):
					var frill_open = maxf(_strike_flash, 0.45 if is_instance_valid(target) else 0.0)
					_neck_frill.scale = Vector3(1.0 + frill_open * 0.65, 1.0 + frill_open * 0.65, 1.0)
			elif "Chameleon" in species_id:
				if moving:
					_model_root.position.z = sin(_anim_phase * 1.5) * 0.06
				if is_instance_valid(_ballistic_tongue):
					_ballistic_tongue.scale = Vector3(1.0, 1.0 + _strike_flash * 5.5, 1.0)
					_ballistic_tongue.position.z = -0.22 - _strike_flash * 0.65
			else:
				_model_root.rotation_degrees.y = sin(_anim_phase) * (8.0 if moving else 2.0)
				for i in range(_body_segments.size()):
					var t_s = _body_segments[i]
					if is_instance_valid(t_s):
						t_s.position.x = sin(_anim_phase * 1.4 - float(i) * 0.7) * (0.09 if moving else 0.02)
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.y = sin(_anim_phase * l_rate) * 16.0
			if is_instance_valid(_jaw_pivot):
				_jaw_pivot.rotation_degrees.x = _strike_flash * 34.0

		"TURTLE":
			var t_walk = sin(_anim_phase * 0.85) * (18.0 if moving else 2.0)
			if is_instance_valid(_leg_fl):
				_leg_fl.rotation_degrees.x = t_walk
			if is_instance_valid(_leg_br):
				_leg_br.rotation_degrees.x = t_walk
			if is_instance_valid(_leg_fr):
				_leg_fr.rotation_degrees.x = -t_walk
			if is_instance_valid(_leg_bl):
				_leg_bl.rotation_degrees.x = -t_walk
			if is_instance_valid(_head_pivot):
				_head_pivot.position.z = _base_head_pos.z - _strike_flash * (0.34 if "Snapping" in species_id else 0.16)
			if is_instance_valid(_jaw_pivot):
				_jaw_pivot.rotation_degrees.x = _strike_flash * 38.0

		"BIPED_HOPPER":
			var hop_s = sin(_anim_phase * 1.35)
			if moving:
				_model_root.position.y = absf(hop_s) * 0.32
				_model_root.rotation_degrees.x = -hop_s * 10.0 + _strike_flash * 18.0
			else:
				_model_root.rotation_degrees.x = _strike_flash * 18.0
			var leg_ang = (hop_s * 34.0 if moving else 0.0) - _strike_flash * 60.0
			if is_instance_valid(_leg_bl):
				_leg_bl.rotation_degrees.x = leg_ang
			if is_instance_valid(_leg_br):
				_leg_br.rotation_degrees.x = leg_ang
			if is_instance_valid(_leg_fl):
				_leg_fl.rotation_degrees.x = -_strike_flash * 55.0 + sin(_anim_phase * 2.0) * 8.0
			if is_instance_valid(_leg_fr):
				_leg_fr.rotation_degrees.x = -_strike_flash * 55.0 - sin(_anim_phase * 2.0) * 8.0
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.x = (-absf(hop_s) * 20.0 if moving else 0.0) - _strike_flash * 18.0

		"TANK_MAMMAL":
			var h_walk = sin(_anim_phase * 0.85) * (20.0 if moving else 3.0)
			if is_instance_valid(_leg_fl):
				_leg_fl.rotation_degrees.x = h_walk
			if is_instance_valid(_leg_br):
				_leg_br.rotation_degrees.x = h_walk
			if is_instance_valid(_leg_fr):
				_leg_fr.rotation_degrees.x = -h_walk
			if is_instance_valid(_leg_bl):
				_leg_bl.rotation_degrees.x = -h_walk
			if is_instance_valid(_ear_l) and is_instance_valid(_ear_r):
				var ear_flap = absf(sin(_anim_phase * 0.9)) * 26.0 + _strike_flash * 28.0
				_ear_l.rotation_degrees.y = -ear_flap
				_ear_r.rotation_degrees.y = ear_flap
			if is_instance_valid(_trunk_pivot):
				_trunk_pivot.rotation_degrees.z = sin(_anim_phase * 0.8) * 14.0
				_trunk_pivot.rotation_degrees.x = -_strike_flash * 68.0 + cos(_anim_phase * 0.8) * 8.0
			if is_instance_valid(_head_pivot):
				var charge_dip = -12.0 if (moving and ("Rhino" in species_id or "Buffalo" in species_id)) else 0.0
				_head_pivot.rotation_degrees.x = charge_dip + _strike_flash * 34.0
			if is_instance_valid(_jaw_pivot):
				_jaw_pivot.rotation_degrees.x = _strike_flash * (62.0 if "Hippo" in species_id else 26.0)
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.z = sin(_anim_phase) * 12.0

		_:
			var is_galloper = ("Lion" in species_id or "Tiger" in species_id or "Cheetah" in species_id or "Panther" in species_id or "Sabertooth" in species_id or "Wolf" in species_id or "Hyena" in species_id)
			if is_galloper and moving:
				var g_f1 = sin(_anim_phase * 1.25) * 32.0
				var g_f2 = sin(_anim_phase * 1.25 + 0.45) * 32.0
				var g_b1 = -sin(_anim_phase * 1.25 + 0.20) * 34.0
				var g_b2 = -sin(_anim_phase * 1.25 + 0.65) * 34.0
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.x = g_f1 - _strike_flash * 48.0
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.x = g_f2 - _strike_flash * 48.0
				if is_instance_valid(_leg_bl):
					_leg_bl.rotation_degrees.x = g_b1
				if is_instance_valid(_leg_br):
					_leg_br.rotation_degrees.x = g_b2
				_model_root.rotation_degrees.x = cos(_anim_phase * 1.25) * 5.5 - _strike_flash * 10.0
				_model_root.position.y = absf(sin(_anim_phase * 1.25)) * 0.10 + _strike_flash * 0.14
			else:
				var q_swing = sin(_anim_phase) * (26.0 if moving else 4.0)
				if is_instance_valid(_leg_fl):
					_leg_fl.rotation_degrees.x = q_swing - _strike_flash * (65.0 if "Bear" in species_id else 35.0)
				if is_instance_valid(_leg_br):
					_leg_br.rotation_degrees.x = q_swing
				if is_instance_valid(_leg_fr):
					_leg_fr.rotation_degrees.x = -q_swing - _strike_flash * 35.0
				if is_instance_valid(_leg_bl):
					_leg_bl.rotation_degrees.x = -q_swing
				if "Bear" in species_id:
					_model_root.rotation_degrees.x = _strike_flash * 14.0
				elif "Porcupine" in species_id:
					_model_root.rotation_degrees.x = -_strike_flash * 16.0
			if is_instance_valid(_tail_pivot):
				_tail_pivot.rotation_degrees.y = sin(_anim_phase) * 16.0
			if is_instance_valid(_head_pivot):
				_head_pivot.rotation_degrees.x = -_strike_flash * 18.0 + sin(_anim_phase * 0.5) * 4.0
			if is_instance_valid(_jaw_pivot):
				_jaw_pivot.rotation_degrees.x = _strike_flash * 36.0

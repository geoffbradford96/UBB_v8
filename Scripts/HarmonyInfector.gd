extends CharacterBody3D
class_name HarmonyInfector

const HarmonyHuskBuilderScript = preload("res://Scripts/HarmonyHuskBuilder.gd")

@export var team: String = "SideHarmony":
	set(v):
		team = v
		if is_inside_tree():
			for g in get_groups():
				if g.begins_with("Side") or g == "Harmony":
					remove_from_group(g)
			add_to_group(team)
			if team == "SideHarmony":
				add_to_group("Harmony")
@export var is_gilded: bool = false
@export var speed: float = 4.2
@export var max_hp: float = 220.0
@export var convert_range: float = 13.5
@export var convert_duration: float = 4.0
@export var convert_cooldown: float = 1.8
@export var fallback_attack_damage: float = 16.0

var home_position: Vector3 = Vector3.ZERO
var channel_target: Node3D = null
var current_target: Node3D = null:
	set(v):
		current_target = v
		channel_target = v
	get:
		return channel_target
var move_target: Node3D = null
var channel_progress: float = 0.0
var cooldown_timer: float = 0.0
var wander_target: Vector3 = Vector3.ZERO
var wander_timer: float = 0.0
var anim_time: float = 0.0

var visual_root: Node3D = null
var core_orb: Node3D = null
var crown_rings: Array[Node3D] = []
var tendrils: Array[Node3D] = []
var conversion_beam: MeshInstance3D = null
var conversion_halo: MeshInstance3D = null

func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var root = (loop as SceneTree).root
		if root and root.has_node("GameState"):
			return root.get_node("GameState")
	return null

func _ready() -> void:
	add_to_group("Targetable")
	add_to_group("Units")
	add_to_group("HarmonyInfector")
	var has_side: bool = false
	for g in get_groups():
		if g.begins_with("Side") and g != "SideHarmony":
			has_side = true
			team = g
			break
	if not has_side:
		if team != "" and team != "SideHarmony":
			add_to_group(team)
		else:
			add_to_group("SideHarmony")
			add_to_group("Harmony")

	set_meta("is_husk_of_harmony", true)
	set_meta("is_gilded_harmony", is_gilded)
	collision_layer = 2
	collision_mask = 1

	if home_position == Vector3.ZERO:
		home_position = global_position
	wander_target = home_position
	anim_time = randf() * 10.0

	if get_node_or_null("CollisionShape3D") == null:
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap := CapsuleShape3D.new()
		cap.radius = 0.65
		cap.height = 2.2
		col.shape = cap
		col.position = Vector3(0.0, 1.1, 0.0)
		add_child(col)

	var hc := get_node_or_null("HealthComponent")
	if hc == null:
		hc = HealthComponent.new()
		hc.name = "HealthComponent"
		hc.max_health = max_hp
		add_child(hc)
	else:
		hc.max_health = max_hp
		hc.current_health = max_hp

	_rebuild_visuals()

func configure_infector(gilded_mode: bool, spawn_pos: Vector3, team_group: String = "SideHarmony") -> void:
	is_gilded = gilded_mode
	team = team_group
	set_meta("is_gilded_harmony", is_gilded)
	home_position = spawn_pos
	global_position = spawn_pos
	wander_target = spawn_pos

	for g in get_groups():
		if g.begins_with("Side") or g == "Harmony":
			remove_from_group(g)
	add_to_group(team_group)
	if team_group == "SideHarmony":
		add_to_group("Harmony")

	if is_inside_tree():
		_rebuild_visuals()

func _get_my_team() -> String:
	for g in get_groups():
		if g.begins_with("Side") and g != "SideHarmony":
			if is_in_group("SideHarmony"):
				remove_from_group("SideHarmony")
			if is_in_group("Harmony"):
				remove_from_group("Harmony")
			return g
	if team != "" and team != "SideHarmony":
		return team
	return "SideHarmony"

func _rebuild_visuals() -> void:
	if visual_root and is_instance_valid(visual_root):
		visual_root.queue_free()
	crown_rings.clear()
	tendrils.clear()
	conversion_beam = null
	conversion_halo = null

	visual_root = Node3D.new()
	visual_root.name = "InfectorVisuals"
	add_child(visual_root)

	var gold_mat := HarmonyHuskBuilderScript.get_gold_vein_material()
	var primary_mat: StandardMaterial3D = HarmonyHuskBuilderScript.get_gilded_dark_green_material() if is_gilded else HarmonyHuskBuilderScript.get_husk_body_material()
	var secondary_mat: StandardMaterial3D = HarmonyHuskBuilderScript.get_gilded_pale_blue_material() if is_gilded else gold_mat

	# Lower hovering spire robe / bio-stalk connected into core_orb
	var stalk := MeshInstance3D.new()
	var stalk_cyl := CylinderMesh.new()
	stalk_cyl.top_radius = 0.40
	stalk_cyl.bottom_radius = 0.16
	stalk_cyl.height = 1.85
	stalk.mesh = stalk_cyl
	stalk.position = Vector3(0.0, 1.02, 0.0)
	stalk.material_override = primary_mat
	visual_root.add_child(stalk)

	var neck_chalice := MeshInstance3D.new()
	var nc_tor := TorusMesh.new()
	nc_tor.inner_radius = 0.28
	nc_tor.outer_radius = 0.42
	neck_chalice.mesh = nc_tor
	neck_chalice.position = Vector3(0.0, 1.72, 0.0)
	neck_chalice.material_override = gold_mat
	visual_root.add_child(neck_chalice)

	# Golden/Pale-Blue helical ribs wrapping the torso
	for i in range(4):
		var rib := MeshInstance3D.new()
		var r_torus := TorusMesh.new()
		r_torus.inner_radius = 0.36 + float(i) * 0.05
		r_torus.outer_radius = 0.44 + float(i) * 0.05
		rib.mesh = r_torus
		rib.position = Vector3(0.0, 0.65 + float(i) * 0.32, 0.0)
		rib.rotation_degrees = Vector3(18.0 * (1.0 if i % 2 == 0 else -1.0), float(i) * 45.0, 12.0)
		rib.material_override = gold_mat if i % 2 == 0 else secondary_mat
		visual_root.add_child(rib)

	# Central Conversion Focus Orb
	core_orb = MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.42
	orb_mesh.height = 0.84
	(core_orb as MeshInstance3D).mesh = orb_mesh
	core_orb.position = Vector3(0.0, 2.05, 0.0)
	(core_orb as MeshInstance3D).material_override = secondary_mat
	visual_root.add_child(core_orb)

	# Sculpted Gold Face on the front of the orb
	var face := HarmonyHuskBuilderScript._create_mini_gold_face(0.52, gold_mat)
	face.position = Vector3(0.0, 0.0, 0.36)
	core_orb.add_child(face)

	# 2 Interlocking Crown Rings
	for r_i in range(2):
		var c_ring := MeshInstance3D.new()
		var c_torus := TorusMesh.new()
		c_torus.inner_radius = 0.68 + float(r_i) * 0.20
		c_torus.outer_radius = 0.76 + float(r_i) * 0.20
		c_ring.mesh = c_torus
		c_ring.position = Vector3(0.0, 2.05, 0.0)
		c_ring.rotation_degrees = Vector3(45.0 + float(r_i) * 50.0, 30.0 * float(r_i), 0.0)
		c_ring.material_override = gold_mat if r_i == 0 else secondary_mat
		visual_root.add_child(c_ring)
		crown_rings.append(c_ring)

	# 4 Forward Injector Tendrils
	for t_i in range(4):
		var t_piv := Node3D.new()
		var ang: float = (TAU / 4.0) * float(t_i) + PI * 0.25
		t_piv.position = Vector3(cos(ang) * 0.38, 1.75 + sin(ang) * 0.22, 0.25)
		visual_root.add_child(t_piv)
		tendrils.append(t_piv)

		var t_mesh := MeshInstance3D.new()
		var t_cyl := CylinderMesh.new()
		t_cyl.top_radius = 0.02
		t_cyl.bottom_radius = 0.06
		t_cyl.height = 0.95
		t_mesh.mesh = t_cyl
		t_mesh.rotation_degrees = Vector3(75.0, 0.0, 0.0)
		t_mesh.position = Vector3(0.0, 0.0, 0.45)
		t_mesh.material_override = gold_mat if t_i % 2 == 0 else secondary_mat
		t_piv.add_child(t_mesh)

	# 3D Conversion Beam & Target Halo (visible while converting 1 target)
	conversion_beam = MeshInstance3D.new()
	conversion_beam.name = "ConversionBeam"
	var b_cyl := CylinderMesh.new()
	b_cyl.top_radius = 0.14
	b_cyl.bottom_radius = 0.22
	b_cyl.height = 1.0
	conversion_beam.mesh = b_cyl
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(0.55, 0.90, 1.0, 0.82) if is_gilded else Color(1.0, 0.85, 0.20, 0.82)
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.emission_enabled = true
	beam_mat.emission = Color(0.45, 0.88, 1.0) if is_gilded else Color(1.0, 0.78, 0.16)
	beam_mat.emission_energy_multiplier = 4.2
	conversion_beam.material_override = beam_mat
	conversion_beam.visible = false
	add_child(conversion_beam)

	conversion_halo = MeshInstance3D.new()
	conversion_halo.name = "ConversionTargetHalo"
	var h_tor := TorusMesh.new()
	h_tor.inner_radius = 1.05
	h_tor.outer_radius = 1.25
	conversion_halo.mesh = h_tor
	conversion_halo.material_override = gold_mat
	conversion_halo.visible = false
	add_child(conversion_halo)

func _physics_process(delta: float) -> void:
	anim_time += delta
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	var my_team: String = _get_my_team()

	# Validate current channel_target (can only convert ONE unit at a time!)
	if is_instance_valid(channel_target):
		var thc := channel_target.get_node_or_null("HealthComponent")
		var dist: float = global_position.distance_to(channel_target.global_position)
		if thc == null or thc.is_dead or thc.current_health <= 0 or _is_already_on_my_side(channel_target, my_team) or dist > convert_range * 1.35:
			_stop_channeling()

	if channel_target == null and cooldown_timer <= 0.0:
		_acquire_convertible_target(my_team)

	if is_instance_valid(channel_target):
		var d_to_t: float = global_position.distance_to(channel_target.global_position)
		if d_to_t <= convert_range:
			# Stop and channel conversion beam on this single unit for several seconds!
			velocity.x = 0.0
			velocity.z = 0.0
			_face_position(channel_target.global_position, delta)
			channel_progress += delta
			_update_conversion_beam_visuals(channel_target)
			if channel_progress >= convert_duration:
				_complete_conversion(channel_target, my_team)
		else:
			if conversion_beam:
				conversion_beam.visible = false
			if conversion_halo:
				conversion_halo.visible = false
			_move_toward_point(channel_target.global_position, delta)
	else:
		if conversion_beam:
			conversion_beam.visible = false
		if conversion_halo:
			conversion_halo.visible = false

		# If no convertible mobile unit is nearby, advance toward enemy structures or roam
		_update_fallback_movement(my_team, delta)

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	if global_position.y < 0.0:
		global_position.y = 0.0

	_animate_visuals(delta)

func _stop_channeling() -> void:
	channel_target = null
	channel_progress = 0.0
	if conversion_beam:
		conversion_beam.visible = false
	if conversion_halo:
		conversion_halo.visible = false

func _is_already_on_my_side(node: Node, my_team: String) -> bool:
	if node == null or not is_instance_valid(node):
		return true
	if my_team == "SideHarmony":
		return node.is_in_group("SideHarmony") or node.is_in_group("Harmony") or node.has_meta("is_husk_of_harmony")
	return node.is_in_group(my_team)

func _is_convertible_unit(node: Node, my_team: String) -> bool:
	if node == null or not is_instance_valid(node) or node == self or not (node is Node3D):
		return false
	if _is_already_on_my_side(node, my_team):
		return false
	var gs = _get_game_state()
	if gs and gs.is_unit_stealthed_from(node, self):
		return false
	if node.is_in_group("Structure") or node.is_in_group("Buildings") or node.is_in_group("Beast"):
		return false
	var n: String = node.name
	if "Base" in n or "Tower" in n or "CommandBay" in n or "Nest" in n or "Hill" in n or "Mine" in n:
		return false
	if my_team != "SideHarmony":
		if node.is_in_group("NeutralCreature") and global_position.distance_to((node as Node3D).global_position) > 12.0:
			return false
		if node.is_in_group("SideHarmony") and global_position.distance_to((node as Node3D).global_position) > 14.0:
			return false
	var hc := node.get_node_or_null("HealthComponent")
	if hc == null or hc.is_dead or hc.current_health <= 0:
		return false
	return true

func _acquire_convertible_target(my_team: String) -> void:
	if not is_inside_tree() or not get_tree():
		return
	var max_search: float = 42.0 if my_team == "SideHarmony" else 9999.0
	var best_dist: float = max_search
	var best_unit: Node3D = null

	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group("Targetable"))
	for u in get_tree().get_nodes_in_group("Units"):
		if not candidates.has(u):
			candidates.append(u)

	for node in candidates:
		if not _is_convertible_unit(node, my_team):
			continue
		var u3 := node as Node3D
		var d: float = global_position.distance_to(u3.global_position)
		if d < best_dist:
			best_dist = d
			best_unit = u3

	if best_unit != null:
		channel_target = best_unit
		channel_progress = 0.0

func _complete_conversion(target: Node3D, my_team: String = "") -> void:
	if not is_instance_valid(target):
		_stop_channeling()
		return
	var eff_team: String = my_team if my_team != "" else _get_my_team()
	HarmonyHuskBuilderScript.transform_into_husk(target, is_gilded, eff_team)
	if is_gilded:
		var mitosis_script = load("res://Scripts/GildedMitosisComponent.gd")
		if mitosis_script and target.get_node_or_null("GildedMitosisComponent") == null:
			var comp = mitosis_script.new()
			comp.name = "GildedMitosisComponent"
			target.add_child(comp)
	cooldown_timer = convert_cooldown
	_stop_channeling()

func _update_conversion_beam_visuals(target: Node3D) -> void:
	if conversion_beam == null or core_orb == null or not is_instance_valid(target):
		return
	var start_pos: Vector3 = core_orb.global_position
	var end_pos: Vector3 = target.global_position + Vector3(0.0, 1.1, 0.0)
	var diff: Vector3 = end_pos - start_pos
	var dist: float = maxf(0.4, diff.length())
	var mid: Vector3 = start_pos + diff * 0.5

	conversion_beam.visible = true
	conversion_beam.global_position = mid
	var up_dir: Vector3 = diff.normalized()
	var ref_vec: Vector3 = Vector3.FORWARD if absf(up_dir.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var right_vec: Vector3 = ref_vec.cross(up_dir).normalized()
	var fwd_vec: Vector3 = up_dir.cross(right_vec).normalized()
	var pulse_w: float = 1.0 + sin(anim_time * 18.0) * 0.28
	conversion_beam.global_transform.basis = Basis(right_vec * pulse_w, up_dir * dist, fwd_vec * pulse_w)

	if conversion_halo:
		conversion_halo.visible = true
		var ratio: float = clampf(channel_progress / maxf(0.1, convert_duration), 0.0, 1.0)
		conversion_halo.global_position = target.global_position + Vector3(0.0, 0.35 + ratio * 1.4, 0.0)
		conversion_halo.rotation.y = anim_time * 5.0

func _update_fallback_movement(my_team: String, delta: float) -> void:
	if my_team == "SideHarmony":
		wander_timer -= delta
		if wander_timer <= 0.0 or global_position.distance_to(wander_target) < 2.2:
			wander_timer = randf_range(3.5, 6.5)
			wander_target = home_position + Vector3(randf_range(-26.0, 26.0), 0.0, randf_range(-26.0, 26.0))
			wander_target.x = clampf(wander_target.x, -100.0, 100.0)
			wander_target.z = clampf(wander_target.z, -85.0, 85.0)
			wander_target.y = global_position.y
		_move_toward_point(wander_target, delta)
	else:
		# Find nearest enemy structure to advance toward and pulse-damage if no units exist
		var best_s: Node3D = null
		var best_d: float = 9999.0
		if is_inside_tree() and get_tree():
			for node in get_tree().get_nodes_in_group("Targetable"):
				if not is_instance_valid(node) or not (node is Node3D):
					continue
				if node.is_in_group(my_team) or node.is_in_group("NeutralStructure") or node.is_in_group("NeutralCreature") or node.is_in_group("SideHarmony"):
					continue
				var hc := node.get_node_or_null("HealthComponent")
				if hc == null or hc.is_dead or hc.current_health <= 0:
					continue
				var d: float = global_position.distance_to((node as Node3D).global_position)
				if d < best_d:
					best_d = d
					best_s = node as Node3D
		if best_s != null:
			var eff_r: float = convert_range + (5.5 if "Base" in best_s.name else 2.5)
			if best_d <= eff_r:
				velocity.x = 0.0
				velocity.z = 0.0
				_face_position(best_s.global_position, delta)
				if cooldown_timer <= 0.0:
					var shc := best_s.get_node_or_null("HealthComponent")
					if shc and shc.has_method("take_damage"):
						shc.take_damage(fallback_attack_damage)
					cooldown_timer = 1.25
			else:
				_move_toward_point(best_s.global_position, delta)
		else:
			velocity.x = 0.0
			velocity.z = 0.0

func _move_toward_point(goal: Vector3, delta: float) -> void:
	var diff := Vector3(goal.x - global_position.x, 0.0, goal.z - global_position.z)
	if diff.length_squared() < 0.08:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dir := diff.normalized()
	var space_state := get_world_3d().direct_space_state
	if space_state:
		var from_pos := global_position + Vector3(0.0, 0.8, 0.0)
		var q := PhysicsRayQueryParameters3D.create(from_pos, from_pos + dir * 3.2, 1, [get_rid()])
		var hit := space_state.intersect_ray(q)
		if not hit.is_empty():
			for ang_deg in [40.0, -40.0, 75.0, -75.0]:
				var cand := dir.rotated(Vector3.UP, deg_to_rad(ang_deg))
				var q2 := PhysicsRayQueryParameters3D.create(from_pos, from_pos + cand * 3.0, 1, [get_rid()])
				if space_state.intersect_ray(q2).is_empty():
					dir = cand
					break
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	var my_team: String = _get_my_team()
	var gs = _get_game_state()
	if my_team != "SideHarmony" and gs:
		var dist_lane: float = gs.get_distance_to_nearest_lane(global_position)
		if dist_lane > 11.5:
			var pull: Vector3 = gs.get_vector_towards_nearest_lane(global_position)
			velocity.x += pull.x * speed * 0.9
			velocity.z += pull.z * speed * 0.9
	_face_position(global_position + dir, delta)

func _face_position(target_pos: Vector3, delta: float) -> void:
	var diff := Vector3(target_pos.x - global_position.x, 0.0, target_pos.z - global_position.z)
	if diff.length_squared() < 0.01:
		return
	var target_yaw: float = atan2(diff.x, diff.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 8.0))

func _animate_visuals(_delta: float) -> void:
	if visual_root == null or not is_instance_valid(visual_root):
		return
	visual_root.position.y = sin(anim_time * 3.0) * 0.14
	for i in range(crown_rings.size()):
		var r := crown_rings[i]
		if is_instance_valid(r):
			r.rotation.y += 0.025 * (1.0 if i % 2 == 0 else -1.0)
			r.rotation.x += 0.015
	for t_i in range(tendrils.size()):
		var t := tendrils[t_i]
		if is_instance_valid(t):
			var flare: float = 0.35 if is_instance_valid(channel_target) else 0.12
			t.rotation.x = sin(anim_time * 6.0 + float(t_i) * 1.4) * flare
			t.rotation.y = cos(anim_time * 5.0 + float(t_i) * 1.4) * flare

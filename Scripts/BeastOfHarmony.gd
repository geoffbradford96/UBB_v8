extends CharacterBody3D
class_name BeastOfHarmony

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
@export var beast_variant: String = "MELEE" # "MELEE" or "RANGED"
@export var speed: float = 4.6
@export var max_hp: float = 480.0
@export var attack_damage: float = 42.0
@export var attack_range: float = 3.6
@export var attack_cooldown: float = 1.15
@export var detection_range: float = 34.0

var home_position: Vector3 = Vector3.ZERO
var current_target: Node3D = null
var attack_timer: float = 0.0
var wander_target: Vector3 = Vector3.ZERO
var wander_timer: float = 0.0
var anim_time: float = 0.0

var visual_root: Node3D = null
var main_eye_pivot: Node3D = null
var main_pupil_node: Node3D = null
var satellite_eyes: Array[Node3D] = []
var satellite_jaws_upper: Array[Node3D] = []
var satellite_jaws_lower: Array[Node3D] = []
var harmony_rings: Array[Node3D] = []
var laser_beam_mesh: MeshInstance3D = null
var laser_core_mesh: MeshInstance3D = null
var laser_flash_timer: float = 0.0
var bite_lunge_timer: float = 0.0
var nav_agent: NavigationAgent3D = null

const EYE_IRIS_COLORS: Array[Color] = [
	Color(1.0, 0.22, 0.35),
	Color(0.18, 0.88, 1.0),
	Color(0.45, 1.0, 0.28),
	Color(1.0, 0.62, 0.14),
	Color(0.78, 0.28, 1.0),
	Color(1.0, 0.92, 0.22),
	Color(0.22, 0.48, 1.0),
	Color(1.0, 0.32, 0.78)
]

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
	add_to_group("BeastOfHarmony")
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
	set_meta("is_beast_of_harmony", true)
	set_meta("beast_of_harmony_variant", beast_variant)
	collision_layer = 2
	collision_mask = 1

	if home_position == Vector3.ZERO:
		home_position = global_position
	wander_target = home_position
	anim_time = randf() * 10.0

	if get_node_or_null("CollisionShape3D") == null:
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var sphere := SphereShape3D.new()
		sphere.radius = 1.35
		col.shape = sphere
		col.position = Vector3(0.0, 1.5, 0.0)
		add_child(col)

	if get_node_or_null("HealthComponent") == null:
		var hc := HealthComponent.new()
		hc.name = "HealthComponent"
		hc.max_health = max_hp
		add_child(hc)

	nav_agent = get_node_or_null("NavigationAgent3D") as NavigationAgent3D
	if nav_agent == null:
		nav_agent = NavigationAgent3D.new()
		nav_agent.name = "NavigationAgent3D"
		nav_agent.path_desired_distance = 1.2
		nav_agent.target_desired_distance = 1.5
		nav_agent.avoidance_enabled = true
		nav_agent.radius = 1.4
		add_child(nav_agent)

	_rebuild_visuals()

func configure_beast(variant: String, spawn_pos: Vector3) -> void:
	beast_variant = variant.to_upper()
	set_meta("beast_of_harmony_variant", beast_variant)
	home_position = spawn_pos
	global_position = spawn_pos
	wander_target = spawn_pos

	if beast_variant == "RANGED":
		max_hp = 420.0
		speed = 4.2
		attack_damage = 38.0
		attack_range = 19.5
		attack_cooldown = 1.35
		detection_range = 36.0
	else:
		beast_variant = "MELEE"
		max_hp = 560.0
		speed = 5.1
		attack_damage = 48.0
		attack_range = 3.8
		attack_cooldown = 0.95
		detection_range = 34.0

	var hc := get_node_or_null("HealthComponent")
	if hc:
		hc.max_health = max_hp
		hc.current_health = max_hp
		if hc.has_method("_refresh_hp_visuals"):
			hc._refresh_hp_visuals()

	if is_inside_tree():
		_rebuild_visuals()

func _make_gold_mat(albedo: Color = Color(1.0, 0.84, 0.22), emission_energy: float = 1.8) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = 0.92
	mat.roughness = 0.16
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.78, 0.18)
	mat.emission_energy_multiplier = emission_energy
	return mat

func _make_sclera_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.98, 0.96, 0.90)
	mat.roughness = 0.22
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.90, 0.72)
	mat.emission_energy_multiplier = 0.35
	return mat

func _make_iris_mat(col: Color, energy: float = 2.2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.15
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	return mat

func _make_pupil_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.02, 0.06)
	mat.roughness = 0.1
	return mat

func _rebuild_visuals() -> void:
	if visual_root and is_instance_valid(visual_root):
		visual_root.queue_free()
	satellite_eyes.clear()
	satellite_jaws_upper.clear()
	satellite_jaws_lower.clear()
	harmony_rings.clear()
	laser_beam_mesh = null
	laser_core_mesh = null

	visual_root = Node3D.new()
	visual_root.name = "BeastVisuals"
	add_child(visual_root)

	if beast_variant == "RANGED":
		_build_ranged_laser_eye_model()
	else:
		_build_melee_many_eyes_eater_model()

func _build_melee_many_eyes_eater_model() -> void:
	var gold_mat := _make_gold_mat(Color(1.0, 0.84, 0.22), 2.1)
	var sclera_mat := _make_sclera_mat()
	var pupil_mat := _make_pupil_mat()
	var maw_mat := _make_iris_mat(Color(0.88, 0.12, 0.28), 1.4)

	main_eye_pivot = Node3D.new()
	main_eye_pivot.name = "MainEyePivot"
	main_eye_pivot.position = Vector3(0.0, 1.85, 0.0)
	visual_root.add_child(main_eye_pivot)

	# Central large eyeball
	var main_ball := MeshInstance3D.new()
	var ball_mesh := SphereMesh.new()
	ball_mesh.radius = 0.92
	ball_mesh.height = 1.84
	main_ball.mesh = ball_mesh
	main_ball.material_override = sclera_mat
	main_eye_pivot.add_child(main_ball)

	# Golden filigree veins wrapping the main eye
	for i in range(4):
		var vein_ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.88
		torus.outer_radius = 0.98
		vein_ring.mesh = torus
		vein_ring.rotation_degrees = Vector3(45.0 * float(i), 35.0 * float(i), 20.0 * float(i))
		vein_ring.material_override = gold_mat
		main_eye_pivot.add_child(vein_ring)

	# Central iris and devouring pupil
	var main_iris := MeshInstance3D.new()
	var iris_mesh := SphereMesh.new()
	iris_mesh.radius = 0.48
	iris_mesh.height = 0.42
	main_iris.mesh = iris_mesh
	main_iris.position = Vector3(0.0, 0.0, 0.74)
	main_iris.material_override = _make_iris_mat(Color(1.0, 0.72, 0.12), 2.5)
	main_eye_pivot.add_child(main_iris)

	main_pupil_node = MeshInstance3D.new()
	var pupil_mesh := SphereMesh.new()
	pupil_mesh.radius = 0.28
	pupil_mesh.height = 0.28
	(main_pupil_node as MeshInstance3D).mesh = pupil_mesh
	main_pupil_node.position = Vector3(0.0, 0.0, 0.88)
	(main_pupil_node as MeshInstance3D).material_override = pupil_mat
	main_eye_pivot.add_child(main_pupil_node)

	# Upper and lower golden teeth rims around the central eye
	var upper_brow := MeshInstance3D.new()
	var brow_box := BoxMesh.new()
	brow_box.size = Vector3(1.1, 0.18, 0.45)
	upper_brow.mesh = brow_box
	upper_brow.position = Vector3(0.0, 0.56, 0.72)
	upper_brow.material_override = gold_mat
	main_eye_pivot.add_child(upper_brow)

	var lower_brow := MeshInstance3D.new()
	lower_brow.mesh = brow_box
	lower_brow.position = Vector3(0.0, -0.56, 0.72)
	lower_brow.material_override = gold_mat
	main_eye_pivot.add_child(lower_brow)

	# Many different smaller eyes around it that eat things (10 orbiting/lunging eye-maws)
	var count: int = 10
	for i in range(count):
		var sat_holder := Node3D.new()
		sat_holder.name = "SatelliteEye_" + str(i)
		var angle: float = (TAU / float(count)) * float(i)
		var elev: float = sin(float(i) * 1.7) * 0.55
		var radius: float = 1.55 + float(i % 2) * 0.28
		sat_holder.position = Vector3(cos(angle) * radius, elev, sin(angle) * radius)
		main_eye_pivot.add_child(sat_holder)
		satellite_eyes.append(sat_holder)

		# Golden tendril connecting central eye to satellite eye
		var tendril := MeshInstance3D.new()
		var t_cyl := CylinderMesh.new()
		t_cyl.top_radius = 0.06
		t_cyl.bottom_radius = 0.11
		t_cyl.height = radius
		tendril.mesh = t_cyl
		tendril.position = -sat_holder.position * 0.5
		tendril.rotation = Vector3(PI * 0.5, atan2(-sat_holder.position.x, -sat_holder.position.z), 0.0)
		tendril.material_override = gold_mat
		sat_holder.add_child(tendril)

		# Satellite eyeball
		var sub_eye := MeshInstance3D.new()
		var sub_sphere := SphereMesh.new()
		var sub_r: float = 0.30 + float(i % 3) * 0.05
		sub_sphere.radius = sub_r
		sub_sphere.height = sub_r * 2.0
		sub_eye.mesh = sub_sphere
		sub_eye.material_override = sclera_mat
		sat_holder.add_child(sub_eye)

		# Multicolored iris for each satellite eye
		var iris_col: Color = EYE_IRIS_COLORS[i % EYE_IRIS_COLORS.size()]
		var sub_iris := MeshInstance3D.new()
		var sub_iris_mesh := SphereMesh.new()
		sub_iris_mesh.radius = sub_r * 0.58
		sub_iris_mesh.height = sub_r * 0.55
		sub_iris.mesh = sub_iris_mesh
		sub_iris.position = Vector3(0.0, 0.0, sub_r * 0.78)
		sub_iris.material_override = _make_iris_mat(iris_col, 2.4)
		sat_holder.add_child(sub_iris)

		var sub_pupil := MeshInstance3D.new()
		var sub_p_mesh := SphereMesh.new()
		sub_p_mesh.radius = sub_r * 0.32
		sub_p_mesh.height = sub_r * 0.32
		sub_pupil.mesh = sub_p_mesh
		sub_pupil.position = Vector3(0.0, 0.0, sub_r * 0.94)
		sub_pupil.material_override = pupil_mat
		sat_holder.add_child(sub_pupil)

		# Biting jaws with golden fangs on each satellite eye so they visibly chomp/eat things!
		var upper_jaw := Node3D.new()
		upper_jaw.position = Vector3(0.0, sub_r * 0.35, sub_r * 0.45)
		sat_holder.add_child(upper_jaw)
		satellite_jaws_upper.append(upper_jaw)

		var lower_jaw := Node3D.new()
		lower_jaw.position = Vector3(0.0, -sub_r * 0.35, sub_r * 0.45)
		sat_holder.add_child(lower_jaw)
		satellite_jaws_lower.append(lower_jaw)

		var lip_mesh := BoxMesh.new()
		lip_mesh.size = Vector3(sub_r * 1.4, 0.08, sub_r * 0.85)
		var u_lip := MeshInstance3D.new()
		u_lip.mesh = lip_mesh
		u_lip.material_override = maw_mat
		upper_jaw.add_child(u_lip)

		var l_lip := MeshInstance3D.new()
		l_lip.mesh = lip_mesh
		l_lip.material_override = maw_mat
		lower_jaw.add_child(l_lip)

		for f_idx in range(-1, 2):
			var u_fang := MeshInstance3D.new()
			var fang_cone := CylinderMesh.new()
			fang_cone.top_radius = 0.04
			fang_cone.bottom_radius = 0.005
			fang_cone.height = 0.18
			u_fang.mesh = fang_cone
			u_fang.position = Vector3(float(f_idx) * sub_r * 0.38, -0.09, sub_r * 0.32)
			u_fang.material_override = gold_mat
			upper_jaw.add_child(u_fang)

			var l_fang := MeshInstance3D.new()
			var l_cone := CylinderMesh.new()
			l_cone.top_radius = 0.005
			l_cone.bottom_radius = 0.04
			l_cone.height = 0.18
			l_fang.mesh = l_cone
			l_fang.position = Vector3(float(f_idx) * sub_r * 0.38, 0.09, sub_r * 0.32)
			l_fang.material_override = gold_mat
			lower_jaw.add_child(l_fang)

func _build_ranged_laser_eye_model() -> void:
	var gold_mat := _make_gold_mat(Color(1.0, 0.86, 0.24), 2.4)
	var sclera_mat := _make_sclera_mat()

	main_eye_pivot = Node3D.new()
	main_eye_pivot.name = "MainEyePivot"
	main_eye_pivot.position = Vector3(0.0, 2.35, 0.0)
	visual_root.add_child(main_eye_pivot)

	# Large main eye
	var main_ball := MeshInstance3D.new()
	var ball_mesh := SphereMesh.new()
	ball_mesh.radius = 1.05
	ball_mesh.height = 2.10
	main_ball.mesh = ball_mesh
	main_ball.material_override = sclera_mat
	main_eye_pivot.add_child(main_ball)

	# Glowing prismatic iris + laser lens pupil
	var main_iris := MeshInstance3D.new()
	var iris_mesh := CylinderMesh.new()
	iris_mesh.top_radius = 0.56
	iris_mesh.bottom_radius = 0.62
	iris_mesh.height = 0.18
	main_iris.mesh = iris_mesh
	main_iris.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	main_iris.position = Vector3(0.0, 0.0, 0.92)
	main_iris.material_override = _make_iris_mat(Color(0.22, 0.92, 1.0), 3.0)
	main_eye_pivot.add_child(main_iris)

	main_pupil_node = MeshInstance3D.new()
	var lens_mesh := SphereMesh.new()
	lens_mesh.radius = 0.34
	lens_mesh.height = 0.34
	(main_pupil_node as MeshInstance3D).mesh = lens_mesh
	main_pupil_node.position = Vector3(0.0, 0.0, 1.02)
	(main_pupil_node as MeshInstance3D).material_override = _make_iris_mat(Color(1.0, 0.24, 0.45), 4.2)
	main_eye_pivot.add_child(main_pupil_node)

	# Interlocking rotating golden rings with smaller watchful eyes around the main eye
	for r_idx in range(3):
		var ring_node := MeshInstance3D.new()
		var torus := TorusMesh.new()
		var r_inner: float = 1.32 + float(r_idx) * 0.32
		torus.inner_radius = r_inner
		torus.outer_radius = r_inner + 0.11
		ring_node.mesh = torus
		ring_node.rotation_degrees = Vector3(35.0 * float(r_idx + 1), 45.0 * float(r_idx), 25.0 * float(r_idx))
		ring_node.material_override = gold_mat
		main_eye_pivot.add_child(ring_node)
		harmony_rings.append(ring_node)

		for e_idx in range(4):
			var mini_eye := MeshInstance3D.new()
			var m_sphere := SphereMesh.new()
			m_sphere.radius = 0.16
			m_sphere.height = 0.32
			mini_eye.mesh = m_sphere
			var ang: float = (TAU / 4.0) * float(e_idx)
			mini_eye.position = Vector3(cos(ang) * (r_inner + 0.05), 0.0, sin(ang) * (r_inner + 0.05))
			mini_eye.material_override = _make_iris_mat(EYE_IRIS_COLORS[(r_idx * 4 + e_idx) % EYE_IRIS_COLORS.size()], 2.2)
			ring_node.add_child(mini_eye)

	# 3D Laser beam nodes attached to root (positioned in world/local space when firing)
	laser_beam_mesh = MeshInstance3D.new()
	laser_beam_mesh.name = "HarmonyLaserBeam"
	var beam_cyl := CylinderMesh.new()
	beam_cyl.top_radius = 0.22
	beam_cyl.bottom_radius = 0.22
	beam_cyl.height = 1.0
	laser_beam_mesh.mesh = beam_cyl
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(1.0, 0.85, 0.22, 0.82)
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.emission_enabled = true
	beam_mat.emission = Color(1.0, 0.78, 0.18)
	beam_mat.emission_energy_multiplier = 4.5
	laser_beam_mesh.material_override = beam_mat
	laser_beam_mesh.visible = false
	add_child(laser_beam_mesh)

	laser_core_mesh = MeshInstance3D.new()
	laser_core_mesh.name = "HarmonyLaserCore"
	var core_cyl := CylinderMesh.new()
	core_cyl.top_radius = 0.09
	core_cyl.bottom_radius = 0.09
	core_cyl.height = 1.0
	laser_core_mesh.mesh = core_cyl
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 0.28, 0.62, 0.95)
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.35, 0.72)
	core_mat.emission_energy_multiplier = 6.0
	laser_core_mesh.material_override = core_mat
	laser_core_mesh.visible = false
	add_child(laser_core_mesh)

func _physics_process(delta: float) -> void:
	anim_time += delta
	if attack_timer > 0.0:
		attack_timer -= delta
	if laser_flash_timer > 0.0:
		laser_flash_timer -= delta
		if laser_flash_timer <= 0.0:
			if laser_beam_mesh:
				laser_beam_mesh.visible = false
			if laser_core_mesh:
				laser_core_mesh.visible = false
	if bite_lunge_timer > 0.0:
		bite_lunge_timer -= delta

	_update_target()

	var move_goal: Vector3 = global_position
	var has_goal: bool = false
	var my_team: String = _get_my_team()

	if is_instance_valid(current_target):
		var flat_my := Vector2(global_position.x, global_position.z)
		var flat_t := Vector2(current_target.global_position.x, current_target.global_position.z)
		var dist: float = flat_my.distance_to(flat_t)
		var eff_range: float = attack_range
		if "Base" in current_target.name:
			eff_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			eff_range += 2.5

		if dist <= eff_range:
			velocity = Vector3.ZERO
			_face_position(current_target.global_position, delta)
			if attack_timer <= 0.0:
				_perform_attack(current_target)
				attack_timer = attack_cooldown
		else:
			move_goal = current_target.global_position
			has_goal = true
	else:
		wander_timer -= delta
		if wander_timer <= 0.0 or global_position.distance_to(wander_target) < 2.2:
			wander_timer = randf_range(3.0, 6.0)
			var offset := Vector3(randf_range(-24.0, 24.0), 0.0, randf_range(-24.0, 24.0))
			wander_target = home_position + offset
			wander_target.x = clampf(wander_target.x, -110.0, 110.0)
			wander_target.z = clampf(wander_target.z, -95.0, 95.0)
			wander_target.y = global_position.y
		move_goal = wander_target
		has_goal = true

	if has_goal:
		var dir: Vector3 = _compute_steered_direction(move_goal)
		if dir.length_squared() > 0.001:
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			# Keep player/AI Eye Creatures near the golden path unless actively engaging a close target
			var gs = _get_game_state()
			if my_team != "SideHarmony" and gs:
				var dist_lane: float = gs.get_distance_to_nearest_lane(global_position)
				if dist_lane > 11.5:
					var pull: Vector3 = gs.get_vector_towards_nearest_lane(global_position)
					velocity.x += pull.x * speed * 0.9
					velocity.z += pull.z * speed * 0.9
			_face_position(global_position + dir, delta)
		else:
			velocity.x = 0.0
			velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	if global_position.y < 0.0:
		global_position.y = 0.0

	_animate_visuals(delta)

func _compute_steered_direction(goal: Vector3) -> Vector3:
	var flat_goal := Vector3(goal.x, global_position.y, goal.z)
	var direct := flat_goal - global_position
	direct.y = 0.0
	if direct.length() < 0.25:
		return Vector3.ZERO
	var desired_dir := direct.normalized()

	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return desired_dir

	var from_pos := global_position + Vector3(0.0, 1.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from_pos, from_pos + desired_dir * 3.5)
	query.exclude = [get_rid()]
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return desired_dir

	var collider: Object = hit.get("collider")
	if collider == current_target:
		return desired_dir

	for angle_deg in [35.0, -35.0, 70.0, -70.0, 110.0, -110.0]:
		var candidate := desired_dir.rotated(Vector3.UP, deg_to_rad(angle_deg))
		var q2 := PhysicsRayQueryParameters3D.create(from_pos, from_pos + candidate * 3.2)
		q2.exclude = [get_rid()]
		var h2 := space_state.intersect_ray(q2)
		if h2.is_empty():
			return candidate
	return desired_dir

func _face_position(target_pos: Vector3, delta: float) -> void:
	var flat := Vector3(target_pos.x, global_position.y, target_pos.z)
	var diff := flat - global_position
	if diff.length_squared() < 0.01:
		return
	var target_yaw: float = atan2(diff.x, diff.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 7.5))

func _get_my_team() -> String:
	for g in get_groups():
		if g.begins_with("Side") and g != "SideHarmony":
			if is_in_group("SideHarmony"):
				remove_from_group("SideHarmony")
			if is_in_group("Harmony"):
				remove_from_group("Harmony")
			return g
	return "SideHarmony"

func _update_target() -> void:
	if not is_inside_tree() or not get_tree():
		return
	var my_team: String = _get_my_team()
	var eff_detect: float = 9999.0 if my_team != "SideHarmony" else detection_range
	var gs = _get_game_state()

	if is_instance_valid(current_target):
		var hc := current_target.get_node_or_null("HealthComponent")
		if hc and not hc.is_dead and hc.current_health > 0 and not _is_harmony_ally(current_target):
			if not (gs and gs.is_unit_stealthed_from(current_target, self)):
				var d: float = global_position.distance_to(current_target.global_position)
				if d <= eff_detect * 1.35:
					return
		current_target = null

	var best_dist: float = eff_detect
	var best_node: Node3D = null
	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group("Targetable"))
	candidates.append_array(get_tree().get_nodes_in_group("Units"))
	candidates.append_array(get_tree().get_nodes_in_group("Buildings"))

	for u in candidates:
		if not is_instance_valid(u) or u == self or not (u is Node3D):
			continue
		if _is_harmony_ally(u):
			continue
		if gs and gs.is_unit_stealthed_from(u, self):
			continue
		var u3 := u as Node3D
		if my_team != "SideHarmony":
			if (u.is_in_group("NeutralCreature") or u.is_in_group("NeutralStructure")) and global_position.distance_to(u3.global_position) > 9.0:
				continue
			if u.is_in_group("SideHarmony") and global_position.distance_to(u3.global_position) > 12.0:
				continue
		var hc := u.get_node_or_null("HealthComponent")
		if hc == null or hc.is_dead or hc.current_health <= 0:
			continue
		var d: float = global_position.distance_to(u3.global_position)
		if d < best_dist:
			best_dist = d
			best_node = u3

	current_target = best_node

func _is_harmony_ally(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	var my_team: String = _get_my_team()
	if my_team != "SideHarmony":
		return node.is_in_group(my_team)
	if node.is_in_group("SideHarmony") or node.is_in_group("Harmony"):
		return true
	return false

func _perform_attack(target: Node3D) -> void:
	if not is_instance_valid(target):
		return
	var hc := target.get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.take_damage(attack_damage, global_position)

	if beast_variant == "RANGED":
		_fire_eye_laser_at(target.global_position + Vector3(0.0, 1.1, 0.0))
	else:
		bite_lunge_timer = 0.38

func _fire_eye_laser_at(target_world_pos: Vector3) -> void:
	if laser_beam_mesh == null or main_eye_pivot == null:
		return
	var start_world: Vector3 = main_eye_pivot.global_position
	if main_pupil_node and is_instance_valid(main_pupil_node):
		start_world = main_pupil_node.global_position
	var diff: Vector3 = target_world_pos - start_world
	var dist: float = maxf(0.5, diff.length())
	var mid_world: Vector3 = start_world + diff * 0.5

	laser_beam_mesh.visible = true
	laser_beam_mesh.global_position = mid_world
	var up_dir: Vector3 = diff.normalized()
	var ref_vec: Vector3 = Vector3.FORWARD if absf(up_dir.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var right_vec: Vector3 = ref_vec.cross(up_dir).normalized()
	var fwd_vec: Vector3 = up_dir.cross(right_vec).normalized()
	laser_beam_mesh.global_transform.basis = Basis(right_vec, up_dir * dist, fwd_vec)

	if laser_core_mesh:
		laser_core_mesh.visible = true
		laser_core_mesh.global_position = mid_world
		laser_core_mesh.global_transform.basis = Basis(right_vec, up_dir * dist, fwd_vec)

	laser_flash_timer = 0.28

func _animate_visuals(_delta: float) -> void:
	if main_eye_pivot == null or not is_instance_valid(main_eye_pivot):
		return

	var base_y: float = 2.35 if beast_variant == "RANGED" else 1.85
	main_eye_pivot.position.y = base_y + sin(anim_time * 3.1) * 0.18

	if beast_variant == "MELEE":
		var lunge_factor: float = 1.0
		if bite_lunge_timer > 0.0:
			lunge_factor = 1.38 + sin(bite_lunge_timer * 24.0) * 0.25

		for i in range(satellite_eyes.size()):
			var sat: Node3D = satellite_eyes[i]
			if not is_instance_valid(sat):
				continue
			var angle: float = (TAU / float(satellite_eyes.size())) * float(i) + anim_time * (1.2 + float(i % 3) * 0.35)
			var radius: float = (1.55 + float(i % 2) * 0.28) * lunge_factor
			var elev: float = sin(anim_time * 2.8 + float(i) * 1.5) * 0.55
			sat.position = Vector3(cos(angle) * radius, elev, sin(angle) * radius)

			var bite_speed: float = 16.0 if bite_lunge_timer > 0.0 else 5.5
			var jaw_angle: float = absf(sin(anim_time * bite_speed + float(i) * 0.8)) * 0.65
			if i < satellite_jaws_upper.size() and is_instance_valid(satellite_jaws_upper[i]):
				satellite_jaws_upper[i].rotation.x = -jaw_angle
			if i < satellite_jaws_lower.size() and is_instance_valid(satellite_jaws_lower[i]):
				satellite_jaws_lower[i].rotation.x = jaw_angle
	else:
		for r_idx in range(harmony_rings.size()):
			var ring: Node3D = harmony_rings[r_idx]
			if not is_instance_valid(ring):
				continue
			var spd: float = 1.1 + float(r_idx) * 0.55
			ring.rotation.x += 0.018 * spd * (1.0 if r_idx % 2 == 0 else -1.0)
			ring.rotation.y += 0.024 * spd
			ring.rotation.z += 0.014 * spd

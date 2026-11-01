extends CharacterBody3D
class_name SeaLionCreature

@export var max_health: float = 175.0
@export var speed: float = 5.0
@export var attack_damage: float = 26.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.2
@export var home_position: Vector3 = Vector3.ZERO
@export var leash_radius: float = 38.0
@export var nest_radius: float = 20.0

var current_target: Node3D = null
var attack_timer: float = 0.0
var recheck_timer: float = 0.0
var idle_patrol_timer: float = 0.0
var idle_patrol_offset: Vector3 = Vector3.ZERO
var visual_mesh: Node3D = null
var anim_time: float = 0.0
var left_flipper: Node3D = null
var right_flipper: Node3D = null
var head_node: Node3D = null

func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var r = (loop as SceneTree).root
		if r and r.has_node("GameState"):
			return r.get_node("GameState")
	return null

func _ready():
	add_to_group("Targetable")
	add_to_group("NeutralCreature")
	add_to_group("SeaLion")

	var hc = get_node_or_null("HealthComponent")
	if not hc:
		hc = HealthComponent.new()
		hc.name = "HealthComponent"
		add_child(hc)
	hc.set_max_health(max_health)
	if not hc.died.is_connected(_on_died):
		hc.died.connect(_on_died)
	if not hc.health_changed.is_connected(_on_health_changed):
		hc.health_changed.connect(_on_health_changed)

	if home_position == Vector3.ZERO:
		home_position = global_position

	recheck_timer = randf_range(0.15, 0.35)
	idle_patrol_timer = randf_range(1.0, 3.5)

	_setup_collision()
	_setup_model()

func _setup_collision():
	var col = get_node_or_null("CollisionShape3D")
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var shape = SphereShape3D.new()
		shape.radius = 0.75
		col.shape = shape
		col.position.y = 0.45
		add_child(col)

func _setup_model():
	visual_mesh = Node3D.new()
	visual_mesh.name = "SeaLionVisuals"
	add_child(visual_mesh)
	_build_sealion_mesh()

func _build_sealion_mesh():
	# Wet glossy seal skin
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.18, 0.20, 0.24) # Dark wet slate pelt
	skin_mat.roughness = 0.22
	skin_mat.metallic = 0.15

	var belly_mat = StandardMaterial3D.new()
	belly_mat.albedo_color = Color(0.28, 0.30, 0.34) # Lighter counter-shaded belly
	belly_mat.roughness = 0.25

	var snout_mat = StandardMaterial3D.new()
	snout_mat.albedo_color = Color(0.12, 0.13, 0.15)
	snout_mat.roughness = 0.3

	var nose_mat = StandardMaterial3D.new()
	nose_mat.albedo_color = Color(0.06, 0.06, 0.07)
	nose_mat.roughness = 0.15

	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.08, 0.09, 0.10)
	eye_mat.metallic = 0.8
	eye_mat.roughness = 0.05

	var whisker_mat = StandardMaterial3D.new()
	whisker_mat.albedo_color = Color(0.85, 0.88, 0.92)
	whisker_mat.roughness = 0.4

	var fang_mat = StandardMaterial3D.new()
	fang_mat.albedo_color = Color(0.92, 0.90, 0.80)
	fang_mat.roughness = 0.2

	# 1. Main Torso / Heavy Blubber Body
	var body = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(0.95, 0.65, 1.4)
	body.mesh = body_box
	body.material_override = skin_mat
	body.position = Vector3(0, 0.45, 0.1)
	visual_mesh.add_child(body)

	# Belly pad
	var belly = MeshInstance3D.new()
	var belly_box = BoxMesh.new()
	belly_box.size = Vector3(0.85, 0.2, 1.3)
	belly.mesh = belly_box
	belly.material_override = belly_mat
	belly.position = Vector3(0, 0.22, 0.1)
	visual_mesh.add_child(belly)

	# 2. Chest & Muscular Arched Neck
	var chest = MeshInstance3D.new()
	var chest_box = BoxMesh.new()
	chest_box.size = Vector3(0.85, 0.7, 0.8)
	chest.mesh = chest_box
	chest.material_override = skin_mat
	chest.position = Vector3(0, 0.62, -0.6)
	chest.rotation_degrees.x = -18.0
	visual_mesh.add_child(chest)

	# 3. Head & Snout Pivot
	head_node = Node3D.new()
	head_node.name = "SeaLionHead"
	head_node.position = Vector3(0, 0.85, -0.95)
	visual_mesh.add_child(head_node)

	var head_mesh = MeshInstance3D.new()
	var head_sph = SphereMesh.new()
	head_sph.radius = 0.32
	head_sph.height = 0.52
	head_mesh.mesh = head_sph
	head_mesh.material_override = skin_mat
	head_node.add_child(head_mesh)

	# Blunt muzzle / snout
	var snout = MeshInstance3D.new()
	var sn_box = BoxMesh.new()
	sn_box.size = Vector3(0.36, 0.22, 0.38)
	snout.mesh = sn_box
	snout.material_override = snout_mat
	snout.position = Vector3(0, -0.06, -0.32)
	head_node.add_child(snout)

	# Wet black nose pad
	var nose = MeshInstance3D.new()
	var nose_sph = SphereMesh.new()
	nose_sph.radius = 0.08
	nose_sph.height = 0.12
	nose.mesh = nose_sph
	nose.material_override = nose_mat
	nose.position = Vector3(0, 0.04, -0.52)
	head_node.add_child(nose)

	# Eyes
	for s in [-1.0, 1.0]:
		var eye = MeshInstance3D.new()
		var eye_sph = SphereMesh.new()
		eye_sph.radius = 0.06
		eye_sph.height = 0.10
		eye.mesh = eye_sph
		eye.material_override = eye_mat
		eye.position = Vector3(s * 0.22, 0.10, -0.22)
		head_node.add_child(eye)

	# Whiskers (3 on left, 3 on right)
	for s in [-1.0, 1.0]:
		for w_i in range(3):
			var whisker = MeshInstance3D.new()
			var w_cyl = CylinderMesh.new()
			w_cyl.top_radius = 0.008
			w_cyl.bottom_radius = 0.015
			w_cyl.height = 0.32
			whisker.mesh = w_cyl
			whisker.material_override = whisker_mat
			whisker.position = Vector3(s * 0.22, -0.04 + float(w_i) * 0.04, -0.36)
			whisker.rotation_degrees = Vector3(0, s * (65.0 + float(w_i) * 12.0), s * (15.0 - float(w_i) * 15.0))
			head_node.add_child(whisker)

	# Fanged Jaws & Canine Tusks
	for s in [-1.0, 1.0]:
		var fang = MeshInstance3D.new()
		var fang_cyl = CylinderMesh.new()
		fang_cyl.top_radius = 0.038
		fang_cyl.bottom_radius = 0.006
		fang_cyl.height = 0.16
		fang.mesh = fang_cyl
		fang.material_override = fang_mat
		fang.position = Vector3(s * 0.12, -0.16, -0.38)
		fang.rotation_degrees.x = 15.0
		head_node.add_child(fang)

	# 4. Wide Front Pectoral Flippers (Left and Right)
	for s in [-1.0, 1.0]:
		var flipper_root = Node3D.new()
		flipper_root.position = Vector3(s * 0.52, 0.35, -0.35)
		visual_mesh.add_child(flipper_root)
		if s < 0: left_flipper = flipper_root
		else: right_flipper = flipper_root

		var flipper = MeshInstance3D.new()
		var fl_box = BoxMesh.new()
		fl_box.size = Vector3(0.55, 0.08, 0.38)
		flipper.mesh = fl_box
		flipper.material_override = skin_mat
		flipper.position = Vector3(s * 0.24, -0.12, 0.05)
		flipper.rotation_degrees = Vector3(10.0, s * 22.0, s * -32.0)
		flipper_root.add_child(flipper)

	# 5. Rear Hind Flippers / Tail
	for s in [-1.0, 1.0]:
		var r_flipper = MeshInstance3D.new()
		var rf_box = BoxMesh.new()
		rf_box.size = Vector3(0.28, 0.06, 0.55)
		r_flipper.mesh = rf_box
		r_flipper.material_override = skin_mat
		r_flipper.position = Vector3(s * 0.26, 0.24, 0.95)
		r_flipper.rotation_degrees = Vector3(-12.0, s * -25.0, s * 14.0)
		visual_mesh.add_child(r_flipper)

func is_valid_organic_target(node: Node) -> bool:
	if not is_instance_valid(node): return false
	if node == self: return false
	if node.is_in_group("SeaLion") or node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure") or node.is_in_group("Structure"):
		return false
	var n_name = node.name
	# Strictly ignores tanks, planes, mechs, mechanical units, and buildings!
	if "Base" in n_name or "Tower" in n_name or "CommandBay" in n_name or "Structure" in n_name:
		return false
	if "is_flying" in node:
		if bool(node.get("is_flying")):
			return false
	else:
		if "Plane" in n_name or "Flyer" in n_name or "Gargoyle" in n_name or "Jellyfish" in n_name or "Beetle" in n_name:
			return false
		if node.get("unit_attribute") == "Flying" or node.is_in_group("Flyer") or node.get("flight_height") != null:
			return false
	if "Tank" in n_name or "Mech" in n_name or "Walker" in n_name or "Spiker" in n_name:
		return false
	if node.get("unit_attribute") == "Mechanical" or node.get("unit_attribute") == "Ethereal":
		return false

	var hc = node.get_node_or_null("HealthComponent")
	if hc and hc.is_dead:
		return false

	var gs = _get_game_state()
	if gs and gs.is_unit_stealthed_from(node, self):
		return false

	return true

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if has_meta("stealth_revealed_timer"):
		var __s_timer = get_meta("stealth_revealed_timer", 0.0)
		if __s_timer > 0.0:
			set_meta("stealth_revealed_timer", max(0.0, __s_timer - delta))

	recheck_timer -= delta
	if recheck_timer <= 0.0:
		recheck_timer = randf_range(0.25, 0.45)
		_evaluate_targeting()

	var is_moving = false

	if current_target != null and is_instance_valid(current_target) and is_valid_organic_target(current_target):
		var dist_to_target = global_position.distance_to(current_target.global_position)
		var dist_from_home = home_position.distance_to(current_target.global_position)

		# Leash break check
		if dist_from_home > leash_radius:
			current_target = null
		elif dist_to_target > attack_range:
			# Chase organic target
			var move_dir = (current_target.global_position - global_position).normalized()
			velocity.x = move_dir.x * speed
			velocity.z = move_dir.z * speed
			is_moving = true

			var look_pos = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
			if global_position.distance_to(look_pos) > 0.1:
				var s_before = scale
				look_at(look_pos, Vector3.UP)
				scale = s_before
		else:
			# Close-quarters fanged bite
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

			var look_pos = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
			if global_position.distance_to(look_pos) > 0.1:
				var s_before = scale
				look_at(look_pos, Vector3.UP)
				scale = s_before

			attack_timer -= delta
			if attack_timer <= 0.0:
				attack_timer = 1.0 / max(0.01, attack_speed)
				var th = current_target.get_node_or_null("HealthComponent")
				if th and not th.is_dead:
					set_meta("stealth_revealed_timer", 2.0)
					th.take_damage(attack_damage, global_position)
					if head_node:
						head_node.position.z -= 0.35 # Lunge bite
	else:
		# Return to ice hole or patrol
		var dist_to_home = global_position.distance_to(home_position)
		if dist_to_home > nest_radius * 0.7:
			var home_dir = (home_position + idle_patrol_offset - global_position).normalized()
			velocity.x = home_dir.x * (speed * 0.75)
			velocity.z = home_dir.z * (speed * 0.75)
			is_moving = true

			var look_pos = global_position + Vector3(home_dir.x, 0, home_dir.z)
			if global_position.distance_to(look_pos) > 0.1:
				var s_before = scale
				look_at(look_pos, Vector3.UP)
				scale = s_before
		else:
			idle_patrol_timer -= delta
			if idle_patrol_timer <= 0.0:
				idle_patrol_timer = randf_range(2.0, 5.0)
				var angle = randf() * TAU
				var r = randf_range(1.5, nest_radius * 0.65)
				idle_patrol_offset = Vector3(cos(angle) * r, 0, sin(angle) * r)

			var patrol_target = home_position + idle_patrol_offset
			if global_position.distance_to(patrol_target) > 0.6:
				var p_dir = (patrol_target - global_position).normalized()
				velocity.x = p_dir.x * (speed * 0.45)
				velocity.z = p_dir.z * (speed * 0.45)
				is_moving = true

				var look_pos = global_position + Vector3(p_dir.x, 0, p_dir.z)
				if global_position.distance_to(look_pos) > 0.1:
					var s_before = scale
					look_at(look_pos, Vector3.UP)
					scale = s_before
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)

	# Anti-stuck wall sliding against rocks and ice
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.length() < 0.1: wall_normal = Vector3.UP
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < speed * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * speed * 1.5

	move_and_slide()

	# Procedural Sea Lion waddle & flipper paddling
	if visual_mesh:
		if is_moving:
			anim_time += delta * speed * 4.2
			visual_mesh.rotation.y = sin(anim_time) * 0.14
			visual_mesh.position.y = abs(sin(anim_time * 2.0)) * 0.06
			if left_flipper: left_flipper.rotation.z = sin(anim_time) * 0.35
			if right_flipper: right_flipper.rotation.z = -sin(anim_time) * 0.35
		else:
			visual_mesh.rotation.y = lerp(visual_mesh.rotation.y, 0.0, 10.0 * delta)
			visual_mesh.position.y = lerp(visual_mesh.position.y, 0.0, 10.0 * delta)
			if left_flipper: left_flipper.rotation.z = lerp(left_flipper.rotation.z, 0.0, 10.0 * delta)
			if right_flipper: right_flipper.rotation.z = lerp(right_flipper.rotation.z, 0.0, 10.0 * delta)

		if head_node:
			head_node.position.z = lerp(head_node.position.z, -0.95, 8.0 * delta)

func _evaluate_targeting():
	if not is_instance_valid(current_target) or not is_valid_organic_target(current_target):
		current_target = null

	if current_target == null and is_inside_tree() and get_tree():
		var best_target: Node3D = null
		var closest_dist = nest_radius

		for node in get_tree().get_nodes_in_group("Targetable"):
			if not is_valid_organic_target(node): continue
			var dist_from_nest = home_position.distance_to(node.global_position)
			var dist_from_creature = global_position.distance_to(node.global_position)
			var in_range = (dist_from_nest <= nest_radius) or (dist_from_creature <= nest_radius * 0.75 and dist_from_nest <= leash_radius * 0.85)
			if in_range and dist_from_nest < closest_dist:
				closest_dist = dist_from_nest
				best_target = node

		current_target = best_target

func _on_health_changed(new_h: float, max_h: float):
	if current_target == null and new_h < max_h:
		_evaluate_retaliation()

func _evaluate_retaliation():
	if not is_inside_tree() or not get_tree(): return
	var closest_d: float = leash_radius
	var best: Node3D = null
	for node in get_tree().get_nodes_in_group("Targetable"):
		if not is_valid_organic_target(node): continue
		var d = global_position.distance_to(node.global_position)
		if d < closest_d:
			closest_d = d
			best = node
	if best != null:
		current_target = best

func _on_died():
	set_physics_process(false)

func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO):
	var hc = get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.take_damage(amount, source_pos)

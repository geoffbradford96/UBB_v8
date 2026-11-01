extends CharacterBody3D
class_name FireSpriteMelee

@export var max_health: float = 55.0
@export var speed: float = 6.2
@export var attack_damage: float = 16.0
@export var attack_range: float = 1.8
@export var attack_speed: float = 1.4

var current_target: Node3D = null
var attack_timer: float = 0.0
var recheck_timer: float = 0.0
var visual_mesh: Node3D = null
var left_claw: Node3D = null
var right_claw: Node3D = null
var anim_time: float = 0.0

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
	add_to_group("FireEntity")
	add_to_group("FireMonster")

	var hc = get_node_or_null("HealthComponent")
	if not hc:
		hc = HealthComponent.new()
		hc.name = "HealthComponent"
		add_child(hc)
	hc.set_max_health(max_health)
	if not hc.died.is_connected(_on_died):
		hc.died.connect(_on_died)

	_setup_collision()
	_setup_model()

func _setup_collision():
	var col = get_node_or_null("CollisionShape3D")
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var shape = SphereShape3D.new()
		shape.radius = 0.45
		col.shape = shape
		col.position.y = 0.45
		add_child(col)

func _setup_model():
	visual_mesh = Node3D.new()
	visual_mesh.name = "MeleeSpriteVisuals"
	add_child(visual_mesh)
	_build_model()

func _build_model():
	var fire_mat = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.38, 0.08)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.42, 0.05)
	fire_mat.emission_energy_multiplier = 2.8

	var core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 0.92, 0.35)
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.90, 0.30)
	core_mat.emission_energy_multiplier = 3.5

	var claw_mat = StandardMaterial3D.new()
	claw_mat.albedo_color = Color(0.25, 0.08, 0.04) # Basalt ember
	claw_mat.roughness = 0.7

	# 1. Floating Fiery Core
	var core = MeshInstance3D.new()
	var cs = SphereMesh.new()
	cs.radius = 0.28
	cs.height = 0.48
	core.mesh = cs
	core.material_override = core_mat
	core.position = Vector3(0, 0.55, 0)
	visual_mesh.add_child(core)

	# 2. Outer Swirling Flame Shroud
	var shroud = MeshInstance3D.new()
	var sm = CylinderMesh.new()
	sm.top_radius = 0.1
	sm.bottom_radius = 0.32
	sm.height = 0.75
	shroud.mesh = sm
	shroud.material_override = fire_mat
	shroud.position = Vector3(0, 0.52, 0)
	visual_mesh.add_child(shroud)

	# 3. Horn Crest / Flame Crown
	for s in [-1.0, 1.0]:
		var horn = MeshInstance3D.new()
		var hm = PrismMesh.new()
		hm.size = Vector3(0.12, 0.35, 0.12)
		horn.mesh = hm
		horn.material_override = fire_mat
		horn.position = Vector3(s * 0.16, 0.82, -0.05)
		horn.rotation_degrees = Vector3(15.0, 0.0, s * -25.0)
		visual_mesh.add_child(horn)

	# 4. Jagged Burning Claw Arms (Left and Right)
	for s in [-1.0, 1.0]:
		var arm_root = Node3D.new()
		arm_root.position = Vector3(s * 0.32, 0.58, -0.1)
		visual_mesh.add_child(arm_root)
		if s < 0: left_claw = arm_root
		else: right_claw = arm_root

		var arm_bone = MeshInstance3D.new()
		var ab = BoxMesh.new()
		ab.size = Vector3(0.10, 0.12, 0.42)
		arm_bone.mesh = ab
		arm_bone.material_override = claw_mat
		arm_bone.position = Vector3(s * 0.12, -0.06, -0.18)
		arm_root.add_child(arm_bone)

		# 3 Fiery Talons per hand
		for t_i in range(3):
			var talon = MeshInstance3D.new()
			var tm = PrismMesh.new()
			tm.size = Vector3(0.04, 0.18, 0.05)
			talon.mesh = tm
			talon.material_override = fire_mat
			talon.position = Vector3(s * (0.08 + float(t_i) * 0.04), -0.08, -0.42)
			talon.rotation_degrees.x = -75.0
			arm_root.add_child(talon)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	recheck_timer -= delta
	if recheck_timer <= 0.0:
		recheck_timer = randf_range(0.2, 0.4)
		_evaluate_targeting()

	var is_moving = false

	if is_instance_valid(current_target):
		var target_hc = current_target.get_node_or_null("HealthComponent")
		if target_hc and target_hc.is_dead:
			current_target = null
			return

		var dist = global_position.distance_to(current_target.global_position)
		if dist > attack_range:
			# Fast chase
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
			# Stop and Claw
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
				if target_hc and not target_hc.is_dead:
					target_hc.take_damage(attack_damage, global_position)
					# Claw strike thrust
					if left_claw: left_claw.position.z -= 0.3
					if right_claw: right_claw.position.z -= 0.3
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Animation
	if visual_mesh:
		anim_time += delta * 6.0
		visual_mesh.position.y = 0.08 + sin(anim_time) * 0.08
		if left_claw: left_claw.position.z = lerp(left_claw.position.z, -0.1, 8.0 * delta)
		if right_claw: right_claw.position.z = lerp(right_claw.position.z, -0.1, 8.0 * delta)

func _evaluate_targeting():
	if not is_instance_valid(current_target):
		current_target = null

	if current_target == null and is_inside_tree() and get_tree():
		var closest_dist = 28.0
		var best: Node3D = null
		for node in get_tree().get_nodes_in_group("Targetable"):
			if node == self or not is_instance_valid(node): continue
			if node.is_in_group("FireEntity") or node.is_in_group("FireMonster") or node.is_in_group("NeutralStructure") or node.is_in_group("NeutralCreature"): continue
			var hc = node.get_node_or_null("HealthComponent")
			if hc and hc.is_dead: continue

			var d = global_position.distance_to(node.global_position)
			if d < closest_dist:
				closest_dist = d
				best = node
		current_target = best

func _on_died():
	set_physics_process(false)

func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO):
	var hc = get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.take_damage(amount, source_pos)

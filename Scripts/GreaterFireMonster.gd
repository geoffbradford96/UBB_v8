class_name GreaterFireMonster
extends CharacterBody3D

@export var max_health: float = 480.0
@export var current_health: float = 480.0
@export var speed: float = 4.2
@export var ranged_attack_range: float = 16.0
@export var melee_attack_range: float = 3.8
@export var ranged_damage: float = 32.0
@export var melee_damage: float = 48.0
@export var attack_cooldown: float = 1.6

var current_target: Node3D = null
var attack_timer: float = 0.0
var walk_anim_time: float = 0.0
var is_slamming: bool = false
var slam_timer: float = 0.0

var visual_pivot: Node3D = null
var torso_node: Node3D = null
var left_arm: Node3D = null
var right_arm: Node3D = null
var left_leg: Node3D = null
var right_leg: Node3D = null
var head_node: Node3D = null
var core_mesh: MeshInstance3D = null

func _ready():
	add_to_group("Targetable")
	add_to_group("NeutralCreature")
	add_to_group("FireMonster")
	add_to_group("FireEntity")
	current_health = max_health
	
	_setup_collision()
	_setup_health_component()
	_build_3d_model()

func _setup_collision():
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 1.2
	cap.height = 3.6
	col.shape = cap
	col.position = Vector3(0, 1.8, 0)
	add_child(col)

func _setup_health_component():
	var health_script = load("res://Scripts/HealthComponent.gd")
	if health_script:
		var hc = health_script.new()
		hc.name = "HealthComponent"
		add_child(hc)
		hc.set_max_health(max_health)

func _build_3d_model():
	visual_pivot = Node3D.new()
	visual_pivot.name = "VisualPivot"
	add_child(visual_pivot)

	# Materials
	var basalt_mat = StandardMaterial3D.new()
	basalt_mat.albedo_color = Color(0.12, 0.10, 0.11)
	basalt_mat.roughness = 0.92
	basalt_mat.metallic = 0.15

	var lava_vein_mat = StandardMaterial3D.new()
	lava_vein_mat.albedo_color = Color(1.0, 0.35, 0.05)
	lava_vein_mat.emission_enabled = true
	lava_vein_mat.emission = Color(1.0, 0.42, 0.08)
	lava_vein_mat.emission_energy_multiplier = 4.2

	var core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 0.65, 0.15)
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.70, 0.20)
	core_mat.emission_energy_multiplier = 6.0

	var horn_mat = StandardMaterial3D.new()
	horn_mat.albedo_color = Color(0.18, 0.05, 0.02)
	horn_mat.emission_enabled = true
	horn_mat.emission = Color(0.9, 0.2, 0.0)
	horn_mat.emission_energy_multiplier = 2.0

	# 1. Torso
	torso_node = Node3D.new()
	torso_node.position = Vector3(0, 2.2, 0)
	visual_pivot.add_child(torso_node)

	var torso_mesh = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(1.8, 1.9, 1.3)
	torso_mesh.mesh = t_box
	torso_mesh.material_override = basalt_mat
	torso_node.add_child(torso_mesh)

	# Molten Core in chest
	core_mesh = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.9, 1.1, 0.3)
	core_mesh.mesh = c_box
	core_mesh.material_override = core_mat
	core_mesh.position = Vector3(0, 0.1, -0.6)
	torso_node.add_child(core_mesh)

	# Glowing chest fissure ribs
	for r in [-0.35, 0.35]:
		var rib = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(0.22, 1.2, 0.25)
		rib.mesh = r_box
		rib.material_override = basalt_mat
		rib.position = Vector3(r, 0.1, -0.65)
		rib.rotation_degrees.z = -15.0 if r < 0 else 15.0
		torso_node.add_child(rib)

	# 2. Spiked Shoulder Pauldrons
	for side in [-1.0, 1.0]:
		var sh_spike = MeshInstance3D.new()
		var pyr = PrismMesh.new()
		pyr.size = Vector3(0.7, 0.9, 0.7)
		sh_spike.mesh = pyr
		sh_spike.material_override = basalt_mat
		sh_spike.position = Vector3(side * 1.15, 0.9, 0.0)
		sh_spike.rotation_degrees.z = -35.0 * side
		torso_node.add_child(sh_spike)

	# 3. Head & Horns
	head_node = Node3D.new()
	head_node.position = Vector3(0, 1.15, -0.2)
	torso_node.add_child(head_node)

	var skull = MeshInstance3D.new()
	var sk_box = BoxMesh.new()
	sk_box.size = Vector3(0.9, 0.8, 0.9)
	skull.mesh = sk_box
	skull.material_override = basalt_mat
	head_node.add_child(skull)

	# Glowing eyes & maw
	for e_side in [-0.22, 0.22]:
		var eye = MeshInstance3D.new()
		var e_sph = SphereMesh.new()
		e_sph.radius = 0.09
		e_sph.height = 0.18
		eye.mesh = e_sph
		eye.material_override = core_mat
		eye.position = Vector3(e_side, 0.1, -0.47)
		head_node.add_child(eye)

	var maw = MeshInstance3D.new()
	var m_box = BoxMesh.new()
	m_box.size = Vector3(0.5, 0.14, 0.15)
	maw.mesh = m_box
	maw.material_override = lava_vein_mat
	maw.position = Vector3(0, -0.22, -0.47)
	head_node.add_child(maw)

	# Curved Horns
	for h_side in [-1.0, 1.0]:
		var horn = MeshInstance3D.new()
		var h_cone = CylinderMesh.new()
		h_cone.top_radius = 0.02
		h_cone.bottom_radius = 0.22
		h_cone.height = 1.1
		horn.mesh = h_cone
		horn.material_override = horn_mat
		horn.position = Vector3(h_side * 0.45, 0.6, 0.05)
		horn.rotation_degrees = Vector3(15.0, 0, -32.0 * h_side)
		head_node.add_child(horn)

	# 4. Arms & Fists
	left_arm = _create_arm(-1.0, basalt_mat, lava_vein_mat, core_mat)
	left_arm.position = Vector3(-1.25, 0.5, 0)
	torso_node.add_child(left_arm)

	right_arm = _create_arm(1.0, basalt_mat, lava_vein_mat, core_mat)
	right_arm.position = Vector3(1.25, 0.5, 0)
	torso_node.add_child(right_arm)

	# 5. Heavy Basalt Legs
	left_leg = _create_leg(-0.55, basalt_mat, lava_vein_mat)
	visual_pivot.add_child(left_leg)

	right_leg = _create_leg(0.55, basalt_mat, lava_vein_mat)
	visual_pivot.add_child(right_leg)

func _create_arm(side: float, b_mat: Material, l_mat: Material, c_mat: Material) -> Node3D:
	var arm_root = Node3D.new()
	
	# Upper arm
	var u_arm = MeshInstance3D.new()
	var u_box = BoxMesh.new()
	u_box.size = Vector3(0.65, 1.1, 0.65)
	u_arm.mesh = u_box
	u_arm.material_override = b_mat
	u_arm.position = Vector3(side * 0.1, -0.45, 0)
	arm_root.add_child(u_arm)

	# Forearm & giant magma fist
	var fist = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.9, 1.0, 0.9)
	f_box.material = c_mat
	fist.mesh = f_box
	fist.material_override = c_mat
	fist.position = Vector3(side * 0.15, -1.3, -0.2)
	arm_root.add_child(fist)

	# Spiked knuckles
	for k in [-0.25, 0.0, 0.25]:
		var kn = MeshInstance3D.new()
		var kn_p = PrismMesh.new()
		kn_p.size = Vector3(0.2, 0.35, 0.2)
		kn.mesh = kn_p
		kn.material_override = l_mat
		kn.position = Vector3(side * 0.15 + k, -1.3, -0.7)
		kn.rotation_degrees.x = 90.0
		arm_root.add_child(kn)

	return arm_root

func _create_leg(x_pos: float, b_mat: Material, l_mat: Material) -> Node3D:
	var leg_root = Node3D.new()
	leg_root.position = Vector3(x_pos, 1.3, 0)

	var thigh = MeshInstance3D.new()
	var th_box = BoxMesh.new()
	th_box.size = Vector3(0.65, 1.4, 0.65)
	thigh.mesh = th_box
	thigh.material_override = b_mat
	thigh.position = Vector3(0, -0.6, 0)
	leg_root.add_child(thigh)

	# Foot / Stomp base
	var foot = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.85, 0.45, 1.1)
	foot.mesh = f_box
	foot.material_override = l_mat
	foot.position = Vector3(0, -1.2, -0.15)
	leg_root.add_child(foot)

	return leg_root

func _physics_process(delta: float):
	attack_timer = max(0.0, attack_timer - delta)

	if is_slamming:
		slam_timer -= delta
		if slam_timer <= 0.0:
			is_slamming = false
			_reset_slam_pose()
		else:
			_animate_slam(slam_timer)
		return

	if not is_instance_valid(current_target) or not _is_target_valid(current_target):
		current_target = _find_closest_target()

	if is_instance_valid(current_target):
		var target_pos = current_target.global_position
		var diff = target_pos - global_position
		diff.y = 0.0
		var dist = diff.length()

		# Face target
		if diff.length_squared() > 0.01 and visual_pivot:
			var s = scale
			look_at(Vector3(target_pos.x, global_position.y, target_pos.z), Vector3.UP)
			scale = s

		# Attack logic:
		# If in melee range (<= 3.8m): slam!
		if dist <= melee_attack_range:
			velocity = Vector3.ZERO
			if attack_timer <= 0.0:
				_execute_melee_slam()
		# If in ranged attack range (3.8m to 16.0m): can shoot boulder, but keep advancing!
		elif dist <= ranged_attack_range:
			if attack_timer <= 0.0:
				_execute_ranged_boulder()
			# Keep advancing into close melee range
			var dir = diff.normalized()
			velocity = dir * speed
			walk_anim_time += delta * 6.5
			_animate_walk()
		else:
			# Move towards target
			var dir = diff.normalized()
			velocity = dir * speed
			walk_anim_time += delta * 6.5
			_animate_walk()
	else:
		velocity = Vector3.ZERO
		_animate_idle(delta)

	move_and_slide()

func _find_closest_target() -> Node3D:
	var best: Node3D = null
	var best_dist = 40.0
	for node in get_tree().get_nodes_in_group("Targetable"):
		if node == self or not is_instance_valid(node):
			continue
		if node.is_in_group("FireMonster") or node.is_in_group("FireEntity") or node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure"):
			continue
		var d = global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	return best

func _is_target_valid(t: Node3D) -> bool:
	if not is_instance_valid(t) or t.is_queued_for_deletion():
		return false
	var hc = t.get_node_or_null("HealthComponent")
	if hc and hc.current_health <= 0:
		return false
	return true

func _execute_melee_slam():
	is_slamming = true
	slam_timer = 0.65
	attack_timer = attack_cooldown

	# Deal melee damage to target and nearby enemies (splash slam)
	var targets_hit: Array = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if node == self or not is_instance_valid(node):
			continue
		if node.is_in_group("FireMonster") or node.is_in_group("NeutralCreature"):
			continue
		if global_position.distance_to(node.global_position) <= melee_attack_range + 1.2:
			targets_hit.append(node)

	for t in targets_hit:
		var hc = t.get_node_or_null("HealthComponent")
		if hc and hc.has_method("take_damage"):
			hc.take_damage(melee_damage)
		elif t.has_method("take_damage"):
			t.take_damage(melee_damage)

	_spawn_slam_shockwave()

func _execute_ranged_boulder():
	attack_timer = attack_cooldown
	_spawn_magma_boulder(current_target)

func _spawn_magma_boulder(target: Node3D):
	if not is_instance_valid(target):
		return
	var boulder = MeshInstance3D.new()
	var b_sph = SphereMesh.new()
	b_sph.radius = 0.55
	b_sph.height = 1.1
	boulder.mesh = b_sph

	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(1.0, 0.35, 0.05)
	b_mat.emission_enabled = true
	b_mat.emission = Color(1.0, 0.45, 0.1)
	b_mat.emission_energy_multiplier = 4.5
	boulder.material_override = b_mat

	var spawn_pos = global_position + Vector3(0, 2.5, 0) + (-global_transform.basis.z * 1.5)
	boulder.position = spawn_pos
	var parent_node = get_parent() if get_parent() else self
	parent_node.add_child(boulder)

	# Animate projectile arc towards target
	var target_pos = target.global_position + Vector3(0, 1.0, 0)
	var tween = boulder.create_tween()
	var mid_pos = (spawn_pos + target_pos) * 0.5 + Vector3(0, 3.5, 0)
	tween.tween_property(boulder, "position", mid_pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(boulder, "position", target_pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "_on_boulder_impact").bind(boulder, target))

func _on_boulder_impact(boulder: Node3D, target: Node3D):
	if is_instance_valid(boulder):
		_spawn_boulder_explosion_fx(boulder.global_position)
		boulder.queue_free()

	if is_instance_valid(target):
		var hc = target.get_node_or_null("HealthComponent")
		if hc and hc.has_method("take_damage"):
			hc.take_damage(ranged_damage)
		elif target.has_method("take_damage"):
			target.take_damage(ranged_damage)

func _spawn_boulder_explosion_fx(pos: Vector3):
	var fx = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 1.2
	sph.height = 2.4
	fx.mesh = sph
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	mat.emission_energy_multiplier = 6.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fx.material_override = mat
	fx.position = pos
	var parent_node = get_parent() if get_parent() else self
	parent_node.add_child(fx)

	var tw = fx.create_tween()
	tw.set_parallel(true)
	tw.tween_property(fx, "scale", Vector3(2.5, 2.5, 2.5), 0.35)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tw.finished.connect(Callable(fx, "queue_free"))

func _spawn_slam_shockwave():
	var ring = MeshInstance3D.new()
	var tor = TorusMesh.new()
	tor.inner_radius = 2.0
	tor.outer_radius = 2.6
	ring.mesh = tor
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(1.0, 0.4, 0.05)
	r_mat.emission_enabled = true
	r_mat.emission = Color(1.0, 0.5, 0.1)
	r_mat.emission_energy_multiplier = 5.0
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = r_mat
	ring.position = global_position + Vector3(0, 0.1, 0)
	var parent_node = get_parent() if get_parent() else self
	parent_node.add_child(ring)

	var tw = ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(2.2, 1.0, 2.2), 0.42)
	tw.tween_property(r_mat, "albedo_color:a", 0.0, 0.42)
	tw.finished.connect(Callable(ring, "queue_free"))

func _animate_walk():
	var s = sin(walk_anim_time)
	if left_leg and right_leg:
		left_leg.rotation_degrees.x = s * 24.0
		right_leg.rotation_degrees.x = -s * 24.0
	if left_arm and right_arm:
		left_arm.rotation_degrees.x = -s * 28.0
		right_arm.rotation_degrees.x = s * 28.0
	if torso_node:
		torso_node.position.y = 2.2 + abs(s) * 0.12

func _animate_idle(delta: float):
	walk_anim_time += delta * 2.0
	var s = sin(walk_anim_time)
	if torso_node:
		torso_node.position.y = 2.2 + s * 0.06
	if left_arm and right_arm:
		left_arm.rotation_degrees.x = s * 4.0
		right_arm.rotation_degrees.x = -s * 4.0
	if core_mesh and core_mesh.material_override:
		core_mesh.material_override.emission_energy_multiplier = 5.0 + s * 1.5

func _animate_slam(progress: float):
	# Windup then rapid smash
	if progress > 0.35:
		# Raise both arms high
		if left_arm and right_arm:
			left_arm.rotation_degrees.x = -110.0
			right_arm.rotation_degrees.x = -110.0
		if torso_node:
			torso_node.position.y = 2.6
			torso_node.rotation_degrees.x = -15.0
	else:
		# Smash down
		if left_arm and right_arm:
			left_arm.rotation_degrees.x = 45.0
			right_arm.rotation_degrees.x = 45.0
		if torso_node:
			torso_node.position.y = 1.9
			torso_node.rotation_degrees.x = 25.0

func _reset_slam_pose():
	if left_arm and right_arm:
		left_arm.rotation_degrees.x = 0.0
		right_arm.rotation_degrees.x = 0.0
	if torso_node:
		torso_node.position.y = 2.2
		torso_node.rotation_degrees.x = 0.0

func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO):
	var hc = get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.take_damage(amount, source_pos)
		current_health = hc.current_health
	else:
		current_health -= amount
		if current_health <= 0:
			queue_free()

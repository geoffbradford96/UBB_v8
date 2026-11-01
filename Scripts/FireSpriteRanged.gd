extends CharacterBody3D
class_name FireSpriteRanged

@export var max_health: float = 42.0
@export var speed: float = 4.6
@export var attack_damage: float = 12.0
@export var attack_range: float = 14.0
@export var attack_speed: float = 1.0

var current_target: Node3D = null
var attack_timer: float = 0.0
var recheck_timer: float = 0.0
var visual_mesh: Node3D = null
var orbit_ring: Node3D = null
var motes: Array[MeshInstance3D] = []
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
		col.position.y = 1.0
		add_child(col)

func _setup_model():
	visual_mesh = Node3D.new()
	visual_mesh.name = "RangedSpriteVisuals"
	add_child(visual_mesh)
	_build_model()

func _build_model():
	var core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 0.95, 0.50)
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.90, 0.35)
	core_mat.emission_energy_multiplier = 3.6

	var fire_mat = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.45, 0.08)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.40, 0.06)
	fire_mat.emission_energy_multiplier = 2.6

	var mote_mat = StandardMaterial3D.new()
	mote_mat.albedo_color = Color(1.0, 0.25, 0.05)
	mote_mat.emission_enabled = true
	mote_mat.emission = Color(1.0, 0.20, 0.05)
	mote_mat.emission_energy_multiplier = 3.0

	# 1. Floating Incandescent Pyro-Orb
	var orb = MeshInstance3D.new()
	var os = SphereMesh.new()
	os.radius = 0.32
	os.height = 0.60
	orb.mesh = os
	orb.material_override = core_mat
	orb.position.y = 1.05
	visual_mesh.add_child(orb)

	# 2. Fiery Corona / Halo Ring
	var halo = MeshInstance3D.new()
	var hm = TorusMesh.new()
	hm.inner_radius = 0.38
	hm.outer_radius = 0.46
	halo.mesh = hm
	halo.material_override = fire_mat
	halo.position.y = 1.05
	halo.rotation_degrees.x = 25.0
	visual_mesh.add_child(halo)

	# 3. Orbiting Burning Motes (4 crystals circling core)
	orbit_ring = Node3D.new()
	orbit_ring.position.y = 1.05
	visual_mesh.add_child(orbit_ring)

	for k in range(4):
		var mote = MeshInstance3D.new()
		var mm = PrismMesh.new()
		mm.size = Vector3(0.12, 0.22, 0.12)
		mote.mesh = mm
		mote.material_override = mote_mat
		var ang = (TAU / 4.0) * k
		mote.position = Vector3(cos(ang) * 0.62, sin(ang * 2.0) * 0.15, sin(ang) * 0.62)
		orbit_ring.add_child(mote)
		motes.append(mote)

func _physics_process(delta):
	# Floats above ground
	velocity.y = 0.0

	recheck_timer -= delta
	if recheck_timer <= 0.0:
		recheck_timer = randf_range(0.25, 0.45)
		_evaluate_targeting()

	var is_moving = false

	if is_instance_valid(current_target):
		var target_hc = current_target.get_node_or_null("HealthComponent")
		if target_hc and target_hc.is_dead:
			current_target = null
			return

		var dist = global_position.distance_to(current_target.global_position)
		if dist > attack_range * 0.85:
			# Close in to comfortable firing range
			var move_dir = (current_target.global_position - global_position).normalized()
			velocity.x = move_dir.x * speed
			velocity.z = move_dir.z * speed
			is_moving = true

			var look_pos = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
			if global_position.distance_to(look_pos) > 0.1:
				var s_before = scale
				look_at(look_pos, Vector3.UP)
				scale = s_before
		elif dist < 4.0:
			# Kite away slightly if target is right in face
			var away_dir = (global_position - current_target.global_position).normalized()
			velocity.x = away_dir.x * (speed * 0.7)
			velocity.z = away_dir.z * (speed * 0.7)
			is_moving = true
		else:
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
				_shoot_fireball(current_target)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Idle hovering & mote spin animation
	anim_time += delta * 4.5
	if visual_mesh:
		visual_mesh.position.y = sin(anim_time) * 0.12
	if orbit_ring:
		orbit_ring.rotation.y += delta * 3.5

func _shoot_fireball(target_node: Node3D):
	if not is_instance_valid(target_node): return
	var proj_scene = preload("res://Scenes/Projectile.tscn")
	if proj_scene:
		var proj = proj_scene.instantiate()
		var scene_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if scene_root:
			scene_root.add_child(proj)
			proj.global_position = global_position + Vector3(0, 1.05, 0)
			proj.target = target_node
			proj.set("damage", attack_damage)
			proj.set("speed", 24.0)

			var p_mesh = proj.get_node_or_null("MeshInstance3D")
			if p_mesh:
				var f_mat = StandardMaterial3D.new()
				f_mat.albedo_color = Color(1.0, 0.45, 0.05)
				f_mat.emission_enabled = true
				f_mat.emission = Color(1.0, 0.50, 0.08)
				f_mat.emission_energy_multiplier = 3.5
				p_mesh.material_override = f_mat

func _evaluate_targeting():
	if not is_instance_valid(current_target):
		current_target = null

	if current_target == null and is_inside_tree() and get_tree():
		var closest_dist = 30.0
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

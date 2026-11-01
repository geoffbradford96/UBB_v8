class_name QuicksandSinkhole
extends Area3D

const GpuAcceleratorScript = preload("res://Scripts/GpuAccelerator.gd")

@export var sinkhole_radius: float = 4.8
@export var sink_damage: float = 14.0
@export var slow_factor: float = 0.35

var damage_tick_timer: float = 0.0
var swirl_mesh: MeshInstance3D = null
var bubbles: Array[MeshInstance3D] = []
var bubble_phases: Array[float] = []

func _ready():
	collision_layer = 0
	collision_mask = 1 | 2
	add_to_group("Quicksand")
	add_to_group("EnvironmentalHazard")

	_setup_collision()
	_setup_visuals()

	body_exited.connect(_on_body_exited)

func _setup_collision():
	var col = get_node_or_null("CollisionShape3D")
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cyl = CylinderShape3D.new()
		cyl.radius = sinkhole_radius
		cyl.height = 2.5
		col.shape = cyl
		col.position.y = 0.8
		add_child(col)

func _setup_visuals():
	# 1. Outer mud crater rim
	var rim = MeshInstance3D.new()
	var rim_tor = TorusMesh.new()
	rim_tor.inner_radius = sinkhole_radius * 0.72
	rim_tor.outer_radius = sinkhole_radius * 1.12
	rim.mesh = rim_tor
	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.24, 0.16, 0.08) # Moist jungle soil
	rim_mat.roughness = 0.92
	rim.material_override = rim_mat
	rim.position = Vector3(0, 0.06, 0)
	add_child(rim)

	# 2. Main Quicksand Slurry Pool
	var pool = MeshInstance3D.new()
	var pool_cyl = CylinderMesh.new()
	pool_cyl.top_radius = sinkhole_radius * 0.88
	pool_cyl.bottom_radius = sinkhole_radius * 0.88
	pool_cyl.height = 0.12
	pool.mesh = pool_cyl
	var pool_mat = StandardMaterial3D.new()
	pool_mat.albedo_color = Color(0.48, 0.36, 0.20) # Churning quicksand slurry
	pool_mat.roughness = 0.95
	pool.material_override = pool_mat
	pool.position = Vector3(0, 0.03, 0)
	add_child(pool)

	# 3. Swirling Vortex Spiral Layer (GPU Shader-Animated)
	swirl_mesh = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = sinkhole_radius * 0.65
	s_cyl.bottom_radius = sinkhole_radius * 0.65
	s_cyl.height = 0.04
	swirl_mesh.mesh = s_cyl
	swirl_mesh.material_override = GpuAcceleratorScript.get_quicksand_vortex_shader()
	swirl_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	swirl_mesh.position = Vector3(0, 0.05, 0)
	add_child(swirl_mesh)

	# 4. Perimeter Mossy Roots and Boulders
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.32, 0.22, 0.12)
	r_mat.roughness = 0.85
	for r_i in range(6):
		var ang = (TAU / 6.0) * r_i + randf_range(-0.15, 0.15)
		var r_dist = sinkhole_radius * randf_range(0.95, 1.15)
		var root_box = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(randf_range(0.8, 1.6), randf_range(0.2, 0.4), randf_range(0.35, 0.6))
		root_box.mesh = bm
		root_box.material_override = r_mat
		root_box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root_box.position = Vector3(cos(ang) * r_dist, 0.12, sin(ang) * r_dist)
		root_box.rotation = Vector3(randf_range(-0.1, 0.1), ang + PI * 0.5, randf_range(-0.1, 0.1))
		add_child(root_box)

	# 5. Bubbling Mud Nodes (GPU Vertex Shader-Animated)
	var b_mat = GpuAcceleratorScript.get_quicksand_bubble_shader()
	for b_i in range(5):
		var b_node = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = randf_range(0.12, 0.24)
		sm.height = sm.radius * 1.8
		b_node.mesh = sm
		b_node.material_override = b_mat
		b_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var b_ang = randf() * TAU
		var b_rad = randf_range(0.5, sinkhole_radius * 0.65)
		b_node.position = Vector3(cos(b_ang) * b_rad, 0.05, sin(b_ang) * b_rad)
		add_child(b_node)
		bubbles.append(b_node)
		bubble_phases.append(randf() * TAU)

func _is_unit_flying(unit: Node) -> bool:
	if not is_instance_valid(unit):
		return false
	if "is_flying" in unit:
		return bool(unit.get("is_flying"))
	if unit.get("unit_attribute") == "Flying" or unit.get("unit_attribute") == "Ethereal":
		return true
	if unit.is_in_group("Flyer"):
		return true
	if unit.get("flight_height") != null:
		return true
	var n = unit.name
	if "Plane" in n or "Flyer" in n or "Gargoyle" in n or "Jellyfish" in n or "Beetle" in n:
		return true
	return false

func _physics_process(delta: float):
	# Visual rotation and bubble pulsing are offloaded to GPU shaders;
	# skip CPU physics work completely when no units are overlapping the sinkhole!
	if not has_overlapping_bodies():
		return

	damage_tick_timer -= delta
	var do_damage = false
	if damage_tick_timer <= 0.0:
		damage_tick_timer = 0.35
		do_damage = true

	for body in get_overlapping_bodies():
		if not is_instance_valid(body) or body.is_queued_for_deletion() or body == self:
			continue
		if not (body is CharacterBody3D):
			continue
		if _is_unit_flying(body):
			continue

		# 1. Apply heavy quicksand slowing
		body.velocity.x *= slow_factor
		body.velocity.z *= slow_factor

		# 2. Visually sink down based on closeness to center
		var dist = Vector2(body.global_position.x - global_position.x, body.global_position.z - global_position.z).length()
		var frac = clampf(1.0 - (dist / maxf(1.0, sinkhole_radius)), 0.0, 1.0)
		var target_sink = -lerpf(0.12, 0.55, frac)
		_apply_unit_sink(body, target_sink, delta)

		# 3. Apply periodic suffocating / churning sand damage
		if do_damage:
			var hc = body.get_node_or_null("HealthComponent")
			if hc and hc.has_method("take_damage") and not hc.is_dead:
				hc.take_damage(sink_damage * 0.35, global_position)
			elif body.has_method("take_damage"):
				body.take_damage(sink_damage * 0.35)

func _apply_unit_sink(b: Node, target_y: float, delta: float):
	if b.has_node("VisualPivot"):
		var vp = b.get_node("VisualPivot") as Node3D
		if vp: vp.position.y = lerpf(vp.position.y, target_y, delta * 3.5)
	elif b.has_node("CreatureVisuals"):
		var cv = b.get_node("CreatureVisuals") as Node3D
		if cv: cv.position.y = lerpf(cv.position.y, target_y, delta * 3.5)
	elif b.has_node("HumanoidRig"):
		var hr = b.get_node("HumanoidRig") as Node3D
		if hr: hr.position.y = lerpf(hr.position.y, target_y, delta * 3.5)
	else:
		b.position.y = lerpf(b.position.y, target_y * 0.4, delta * 2.5)

func _restore_unit_sink(b: Node):
	if not is_instance_valid(b) or b.is_queued_for_deletion():
		return
	if b.has_node("VisualPivot"):
		var vp = b.get_node("VisualPivot") as Node3D
		if vp: vp.position.y = 0.0
	elif b.has_node("CreatureVisuals"):
		var cv = b.get_node("CreatureVisuals") as Node3D
		if cv: cv.position.y = 0.0
	elif b.has_node("HumanoidRig"):
		var hr = b.get_node("HumanoidRig") as Node3D
		if hr: hr.position.y = 0.0

func _on_body_exited(body: Node3D):
	_restore_unit_sink(body)

func _exit_tree():
	for body in get_overlapping_bodies():
		_restore_unit_sink(body)

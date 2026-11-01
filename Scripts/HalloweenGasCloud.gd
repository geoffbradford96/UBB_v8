extends Area3D
class_name HalloweenGasCloud

@export var radius: float = 5.2
@export var duration: float = 4.8
@export var damage_per_sec: float = 14.0
@export var slow_factor: float = 0.35

var _elapsed: float = 0.0
var _tick_timer: float = 0.0
var _mist_mesh: MeshInstance3D = null
var _core_mesh: MeshInstance3D = null

func _ready():
	name = "HalloweenGasCloud"
	add_to_group("Hazard")
	monitoring = true
	monitorable = false

	# Setup collision shape
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = radius
	col.shape = sphere
	col.position = Vector3(0, 1.0, 0)
	add_child(col)

	# Outer Spooky Noxious Green/Orange Mist
	_mist_mesh = MeshInstance3D.new()
	var m_sphere = SphereMesh.new()
	m_sphere.radius = radius * 0.95
	m_sphere.height = radius * 1.5
	_mist_mesh.mesh = m_sphere
	var mist_mat = StandardMaterial3D.new()
	mist_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist_mat.albedo_color = Color(0.18, 0.75, 0.12, 0.32) # Sickly Halloween Green
	mist_mat.emission_enabled = true
	mist_mat.emission = Color(0.95, 0.45, 0.05) # Pumpkin Orange Glow
	mist_mat.emission_energy_multiplier = 0.85
	mist_mat.roughness = 0.95
	mist_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_mist_mesh.material_override = mist_mat
	_mist_mesh.position = Vector3(0, 1.2, 0)
	add_child(_mist_mesh)

	# Inner Dense Poison Core
	_core_mesh = MeshInstance3D.new()
	var c_sphere = SphereMesh.new()
	c_sphere.radius = radius * 0.55
	c_sphere.height = radius * 0.95
	_core_mesh.mesh = c_sphere
	var core_mat = StandardMaterial3D.new()
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.albedo_color = Color(0.85, 0.35, 0.05, 0.42)
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.25, 0.95, 0.20)
	core_mat.emission_energy_multiplier = 1.4
	_core_mesh.material_override = core_mat
	_core_mesh.position = Vector3(0, 1.0, 0)
	add_child(_core_mesh)

func _process(delta: float):
	_elapsed += delta
	_tick_timer += delta

	# Animate swirling gas pulsation
	if _mist_mesh:
		var pulse: float = 1.0 + sin(_elapsed * 3.5) * 0.08
		_mist_mesh.scale = Vector3(pulse, 1.0 + cos(_elapsed * 2.8) * 0.05, pulse)
		_mist_mesh.rotate_y(0.45 * delta)
	if _core_mesh:
		_core_mesh.rotate_y(-0.75 * delta)

	# Periodic damage and slow tick (every 0.5 sec)
	if _tick_timer >= 0.5:
		_tick_timer = 0.0
		_apply_gas_effects(0.5)

	# Fade out near end of duration
	if _elapsed >= duration:
		queue_free()
	elif _elapsed >= (duration - 1.0):
		var alpha_ratio = (duration - _elapsed) / 1.0
		if _mist_mesh and _mist_mesh.material_override:
			var m = _mist_mesh.material_override as StandardMaterial3D
			m.albedo_color.a = 0.32 * alpha_ratio
		if _core_mesh and _core_mesh.material_override:
			var cm = _core_mesh.material_override as StandardMaterial3D
			cm.albedo_color.a = 0.42 * alpha_ratio

func _apply_gas_effects(step_time: float):
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if not is_instance_valid(body) or body == self:
			continue
		# Only affect living units / enemies (Undead are immune to gas!)
		if "Skeleton" in body.name or "Bone" in body.name or "Ghost" in body.name:
			continue
		var hc = body.get_node_or_null("HealthComponent")
		if hc and not hc.is_dead and hc.has_method("take_damage"):
			hc.take_damage(damage_per_sec * step_time, null)
		# Apply temporary slow speed debuff
		if body.get("speed") != null and body.get("base_speed") != null:
			var b_speed: float = float(body.get("base_speed"))
			body.speed = maxf(1.5, b_speed * (1.0 - slow_factor))

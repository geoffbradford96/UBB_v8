class_name VolcanicFireHazard
extends Area3D

const GpuAcceleratorScript = preload("res://Scripts/GpuAccelerator.gd")

@export var erupt_cooldown_min: float = 2.5
@export var erupt_cooldown_max: float = 5.0
@export var eruption_duration: float = 1.6
@export var burn_damage: float = 18.0
@export var hazard_radius: float = 2.4

var state: String = "IDLE" # "IDLE", "WARNING", "ERUPTING"
var timer: float = 2.0
var damage_tick_timer: float = 0.0

var vent_base: MeshInstance3D = null
var vent_core: MeshInstance3D = null
var flame_column: MeshInstance3D = null
var ember_ring: MeshInstance3D = null

var vent_mat: StandardMaterial3D = null
var flame_mat: StandardMaterial3D = null

func _ready():
	add_to_group("FireHazard")
	timer = randf_range(erupt_cooldown_min, erupt_cooldown_max)
	_setup_collision()
	_build_visuals()
	body_entered.connect(_on_body_entered)

func _setup_collision():
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = hazard_radius
	cyl.height = 4.0
	col.shape = cyl
	col.position = Vector3(0, 2.0, 0)
	add_child(col)

func _build_visuals():
	# 1. Basalt rocky crater rim
	vent_mat = StandardMaterial3D.new()
	vent_mat.albedo_color = Color(0.18, 0.08, 0.06)
	vent_mat.roughness = 0.9

	var crater = MeshInstance3D.new()
	var tor = TorusMesh.new()
	tor.inner_radius = hazard_radius * 0.7
	tor.outer_radius = hazard_radius * 1.15
	crater.mesh = tor
	crater.material_override = vent_mat
	crater.position = Vector3(0, 0.08, 0)
	add_child(crater)

	# 2. Glowing molten fissure inside (GPU Shader-Animated)
	vent_core = MeshInstance3D.new()
	var c_cyl = CylinderMesh.new()
	c_cyl.top_radius = hazard_radius * 0.75
	c_cyl.bottom_radius = hazard_radius * 0.75
	c_cyl.height = 0.15
	vent_core.mesh = c_cyl
	vent_core.material_override = GpuAcceleratorScript.get_volcanic_molten_shader()
	vent_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vent_core.position = Vector3(0, 0.04, 0)
	add_child(vent_core)

	# 3. Flame Geyser Column (GPU Shader-Animated, initially hidden/scale 0)
	flame_column = MeshInstance3D.new()
	var f_cyl = CylinderMesh.new()
	f_cyl.top_radius = hazard_radius * 0.5
	f_cyl.bottom_radius = hazard_radius * 0.85
	f_cyl.height = 4.2
	flame_column.mesh = f_cyl
	flame_column.material_override = GpuAcceleratorScript.get_volcanic_flame_shader()
	flame_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame_column.position = Vector3(0, 2.1, 0)
	flame_column.scale = Vector3(0.01, 0.01, 0.01)
	flame_column.visible = false
	add_child(flame_column)

	# 4. Swirling ember ring
	var e_mat = StandardMaterial3D.new()
	e_mat.albedo_color = Color(1.0, 0.85, 0.2, 0.75)
	e_mat.emission_enabled = true
	e_mat.emission = Color(1.0, 0.85, 0.2)
	e_mat.emission_energy_multiplier = 4.0
	e_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	ember_ring = MeshInstance3D.new()
	var e_tor = TorusMesh.new()
	e_tor.inner_radius = hazard_radius * 0.8
	e_tor.outer_radius = hazard_radius * 1.05
	ember_ring.mesh = e_tor
	ember_ring.material_override = e_mat
	ember_ring.position = Vector3(0, 0.6, 0)
	ember_ring.visible = false
	add_child(ember_ring)

func _physics_process(delta: float):
	timer -= delta

	match state:
		"IDLE":
			if timer <= 0.0:
				state = "WARNING"
				timer = 0.5

		"WARNING":
			if timer <= 0.0:
				_start_eruption()

		"ERUPTING":
			if ember_ring and ember_ring.visible:
				ember_ring.rotation.y += delta * 8.0
				ember_ring.position.y = 0.4 + sin(timer * 10.0) * 0.3

			# Periodic damage tick
			damage_tick_timer -= delta
			if damage_tick_timer <= 0.0:
				damage_tick_timer = 0.32
				_damage_overlapping_units()

			if timer <= 0.0:
				_end_eruption()

func _start_eruption():
	state = "ERUPTING"
	timer = eruption_duration
	damage_tick_timer = 0.0

	flame_column.visible = true
	ember_ring.visible = true

	var tw = create_tween()
	tw.tween_property(flame_column, "scale", Vector3(1.0, 1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_damage_overlapping_units()

func _end_eruption():
	state = "IDLE"
	timer = randf_range(erupt_cooldown_min, erupt_cooldown_max)

	var tw = create_tween()
	tw.tween_property(flame_column, "scale", Vector3(0.01, 0.01, 0.01), 0.22)
	tw.finished.connect(func():
		if is_instance_valid(flame_column): flame_column.visible = false
		if is_instance_valid(ember_ring): ember_ring.visible = false
	)

func _damage_overlapping_units():
	if not has_overlapping_bodies():
		return
	for body in get_overlapping_bodies():
		if not is_instance_valid(body) or body == self:
			continue
		if body.is_in_group("FireMonster") or body.is_in_group("FireEntity"):
			continue # Fire entities are immune to fire hazards
		var hc = body.get_node_or_null("HealthComponent")
		if hc and hc.has_method("take_damage"):
			hc.take_damage(burn_damage)
		elif body.has_method("take_damage"):
			body.take_damage(burn_damage)

func _on_body_entered(body: Node3D):
	if state == "ERUPTING" and is_instance_valid(body) and not (body.is_in_group("FireMonster") or body.is_in_group("FireEntity")):
		var hc = body.get_node_or_null("HealthComponent")
		if hc and hc.has_method("take_damage"):
			hc.take_damage(burn_damage)
		elif body.has_method("take_damage"):
			body.take_damage(burn_damage)

class_name Volcano
extends StaticBody3D

@export var max_health: float = 1200.0
@export var eruption_cooldown_min: float = 9.0
@export var eruption_cooldown_max: float = 14.0
@export var launch_radius: float = 48.0

var eruption_timer: float = 6.0
var is_rumbling: bool = false
var rumble_timer: float = 0.0

var crater_lava_mesh: MeshInstance3D = null
var lava_mat: StandardMaterial3D = null
var basalt_mat: StandardMaterial3D = null
var rock_projectile_script = preload("res://Scripts/MagmaRockProjectile.gd")

func _ready():
	add_to_group("Volcano")
	add_to_group("Structure")
	add_to_group("NeutralStructure")
	add_to_group("Targetable")

	eruption_timer = randf_range(eruption_cooldown_min, eruption_cooldown_max)
	_setup_collision()
	_setup_health_component()
	_build_volcano_model()

func _setup_collision() -> void:
	var col = get_node_or_null("CollisionShape3D")
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cyl = CylinderShape3D.new()
		cyl.radius = 4.8
		cyl.height = 7.5
		col.shape = cyl
		col.position.y = 3.75
		add_child(col)

func _setup_health_component() -> void:
	var hc = get_node_or_null("HealthComponent")
	if not hc:
		var hc_script = load("res://Scripts/HealthComponent.gd")
		if hc_script:
			hc = hc_script.new()
			hc.name = "HealthComponent"
			hc.max_health = max_health
			hc.current_health = max_health
			add_child(hc)

func _build_volcano_model() -> void:
	var model_root = Node3D.new()
	model_root.name = "VolcanoModel"
	add_child(model_root)

	basalt_mat = StandardMaterial3D.new()
	basalt_mat.albedo_color = Color(0.14, 0.11, 0.12)
	basalt_mat.roughness = 0.95

	var obsidian_mat = StandardMaterial3D.new()
	obsidian_mat.albedo_color = Color(0.08, 0.06, 0.08)
	obsidian_mat.roughness = 0.4
	obsidian_mat.metallic = 0.6

	lava_mat = StandardMaterial3D.new()
	lava_mat.albedo_color = Color(1.0, 0.38, 0.05)
	lava_mat.emission_enabled = true
	lava_mat.emission = Color(1.0, 0.38, 0.05)
	lava_mat.emission_energy_multiplier = 3.5

	# 1. Base Caldera Terrace Tier 1
	var base_cone = MeshInstance3D.new()
	var c1 = CylinderMesh.new()
	c1.top_radius = 4.5
	c1.bottom_radius = 7.2
	c1.height = 3.2
	base_cone.mesh = c1
	base_cone.material_override = basalt_mat
	base_cone.position.y = 1.6
	model_root.add_child(base_cone)

	# 2. Mid Mountain Caldera Tier 2
	var mid_cone = MeshInstance3D.new()
	var c2 = CylinderMesh.new()
	c2.top_radius = 2.8
	c2.bottom_radius = 4.8
	c2.height = 3.4
	mid_cone.mesh = c2
	mid_cone.material_override = obsidian_mat
	mid_cone.position.y = 4.8
	model_root.add_child(mid_cone)

	# 3. Crater Rim Tier 3
	var rim = MeshInstance3D.new()
	var c3 = CylinderMesh.new()
	c3.top_radius = 3.2
	c3.bottom_radius = 2.6
	c3.height = 1.2
	rim.mesh = c3
	rim.material_override = basalt_mat
	rim.position.y = 7.0
	model_root.add_child(rim)

	# 4. Glowing Molten Lava Lake at Summit
	crater_lava_mesh = MeshInstance3D.new()
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 2.4
	l_cyl.bottom_radius = 2.4
	l_cyl.height = 0.2
	crater_lava_mesh.mesh = l_cyl
	crater_lava_mesh.material_override = lava_mat
	crater_lava_mesh.position.y = 7.35
	model_root.add_child(crater_lava_mesh)

	# 5. Volcanic Basalt Fissures & Glowing Ribs
	for i in range(6):
		var rib = MeshInstance3D.new()
		var p_mesh = PrismMesh.new()
		p_mesh.size = Vector3(0.65, 4.2, 0.85)
		rib.mesh = p_mesh
		rib.material_override = lava_mat
		var ang = (TAU / 6.0) * float(i)
		rib.position = Vector3(cos(ang) * 4.6, 3.2, sin(ang) * 4.6)
		rib.rotation = Vector3(deg_to_rad(-18.0), -ang + PI * 0.5, 0.0)
		model_root.add_child(rib)

func _physics_process(delta: float) -> void:
	# Subtle lava bubbling pulse
	if lava_mat:
		var pulse = 3.0 + sin(Time.get_ticks_msec() * 0.005) * 1.2
		lava_mat.emission_energy_multiplier = pulse

	if is_rumbling:
		rumble_timer -= delta
		# Shake the volcano during pre-eruption rumble
		var shake = Vector3(randf_range(-0.06, 0.06), 0.0, randf_range(-0.06, 0.06))
		var v_mod = get_node_or_null("VolcanoModel")
		if v_mod: v_mod.position = shake

		if rumble_timer <= 0.0:
			is_rumbling = false
			if v_mod: v_mod.position = Vector3.ZERO
			_erupt_magma_rocks()
	else:
		eruption_timer -= delta
		if eruption_timer <= 0.0:
			eruption_timer = randf_range(eruption_cooldown_min, eruption_cooldown_max)
			is_rumbling = true
			rumble_timer = 1.4 # 1.4s warning rumble before eruption!

func _erupt_magma_rocks() -> void:
	if not is_inside_tree() or not get_tree():
		return
	var scene_root = get_tree().current_scene if get_tree().current_scene else get_parent()
	if not scene_root: return

	var launch_count = randi_range(1, 3)
	var spawn_origin = global_position + Vector3(0.0, 7.5, 0.0)

	var eff_launch_radius = launch_radius
	var max_extent = 120.0
	var gs = get_node_or_null("/root/GameState")
	if gs and "current_map_radius" in gs and gs.current_map_radius > 40.0:
		eff_launch_radius = clampf(gs.current_map_radius * 0.35, 42.0, 95.0)
		max_extent = maxf(80.0, gs.current_map_radius * 0.82)

	for i in range(launch_count):
		var angle = randf() * TAU
		var dist = randf_range(14.0, eff_launch_radius)
		var target_loc = global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		target_loc.x = clampf(target_loc.x, -max_extent, max_extent)
		target_loc.z = clampf(target_loc.z, -max_extent, max_extent)

		var proj = rock_projectile_script.new()
		scene_root.add_child(proj)
		proj.launch(spawn_origin, target_loc, randf_range(2.0, 3.2), randf_range(12.0, 18.0))

	print("🌋 Volcano erupted at ", global_position, " launching ", launch_count, " magma rocks!")

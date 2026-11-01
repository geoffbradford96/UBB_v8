extends StaticBody3D
class_name EvergreenYuletideTree

# =============================================================================
# EVERGREEN YULETIDE TREE — MAJESTIC HOLIDAY PINE
# =============================================================================
# A towering snow-laden evergreen fir tree adorned with glowing colorful
# fairy lights, a radiant golden star at the peak, and gift packages nestled
# beneath its snow-dusted boughs. Emits a gentle warm festive aura.

var _pulse_timer: float = 0.0
var _fairy_lights: Array[MeshInstance3D] = []

func _ready():
	add_to_group("HolidayTree")
	add_to_group("Obstacle")
	_build_tree_mesh()
	_setup_collision()

func _build_tree_mesh() -> void:
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.28, 0.18, 0.10) # Rich pine bark
	trunk_mat.roughness = 0.90

	var pine_mat = StandardMaterial3D.new()
	pine_mat.albedo_color = Color(0.10, 0.32, 0.16) # Deep forest evergreen green
	pine_mat.roughness = 0.85

	var snow_mat = StandardMaterial3D.new()
	snow_mat.albedo_color = Color(0.92, 0.96, 1.0) # Sparkling snow cap
	snow_mat.roughness = 0.60

	var star_mat = StandardMaterial3D.new()
	star_mat.albedo_color = Color(1.0, 0.88, 0.20)
	star_mat.emission_enabled = true
	star_mat.emission = Color(1.0, 0.82, 0.15)
	star_mat.emission_energy_multiplier = 4.0

	var trunk = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.45
	t_cyl.bottom_radius = 0.85
	t_cyl.height = 4.2
	trunk.mesh = t_cyl
	trunk.material_override = trunk_mat
	trunk.position.y = 2.1
	add_child(trunk)

	# 4 Tapering conical tiers of pine foliage with snow fringes
	var tiers = [
		{"radius": 3.6, "height": 3.0, "y": 3.2},
		{"radius": 2.8, "height": 2.6, "y": 5.0},
		{"radius": 2.0, "height": 2.2, "y": 6.8},
		{"radius": 1.2, "height": 1.8, "y": 8.2}
	]

	var light_colors = [
		Color(1.0, 0.2, 0.2), # Ruby Red
		Color(1.0, 0.85, 0.1), # Holiday Gold
		Color(0.2, 0.9, 0.3), # Emerald Green
		Color(0.2, 0.6, 1.0), # Ice Sapphire
		Color(0.9, 0.3, 0.9)  # Sugarplum Purple
	]

	for i in range(tiers.size()):
		var t_info = tiers[i]
		# Pine foliage cone
		var foliage = MeshInstance3D.new()
		var f_cone = CylinderMesh.new()
		f_cone.top_radius = 0.1
		f_cone.bottom_radius = t_info["radius"]
		f_cone.height = t_info["height"]
		foliage.mesh = f_cone
		foliage.material_override = pine_mat
		foliage.position.y = t_info["y"]
		add_child(foliage)

		# Snow cap on top edge of cone
		var snow_cap = MeshInstance3D.new()
		var sc_cone = CylinderMesh.new()
		sc_cone.top_radius = 0.12
		sc_cone.bottom_radius = t_info["radius"] * 0.95
		sc_cone.height = t_info["height"] * 0.45
		snow_cap.mesh = sc_cone
		snow_cap.material_override = snow_mat
		snow_cap.position.y = t_info["y"] + t_info["height"] * 0.28
		add_child(snow_cap)

		# Ring of colorful glowing festive fairy lights around tier perimeter
		var num_lights = 6 + i * 2
		for l_idx in range(num_lights):
			var angle = (float(l_idx) / float(num_lights)) * TAU + (float(i) * 0.5)
			var light_rad = t_info["radius"] * 0.92
			var l_mesh = MeshInstance3D.new()
			var l_sphere = SphereMesh.new()
			l_sphere.radius = 0.14
			l_sphere.height = 0.28
			l_mesh.mesh = l_sphere

			var l_color = light_colors[(l_idx + i) % light_colors.size()]
			var l_mat = StandardMaterial3D.new()
			l_mat.albedo_color = l_color
			l_mat.emission_enabled = true
			l_mat.emission = l_color
			l_mat.emission_energy_multiplier = 3.2
			l_mesh.material_override = l_mat
			l_mesh.position = Vector3(cos(angle) * light_rad, t_info["y"] - t_info["height"] * 0.35, sin(angle) * light_rad)
			add_child(l_mesh)
			_fairy_lights.append(l_mesh)

	# Radiant Golden Star at apex
	var star_center = MeshInstance3D.new()
	var star_sphere = SphereMesh.new()
	star_sphere.radius = 0.35
	star_sphere.height = 0.70
	star_center.mesh = star_sphere
	star_center.material_override = star_mat
	star_center.position.y = 9.4
	add_child(star_center)

	for p_idx in range(5):
		var p_ang = (float(p_idx) / 5.0) * TAU
		var star_point = MeshInstance3D.new()
		var sp_cone = CylinderMesh.new()
		sp_cone.top_radius = 0.02
		sp_cone.bottom_radius = 0.16
		sp_cone.height = 0.75
		star_point.mesh = sp_cone
		star_point.material_override = star_mat
		star_point.position = Vector3(cos(p_ang) * 0.35, 9.4 + sin(p_ang) * 0.35, 0.0)
		star_point.rotation.z = p_ang - PI * 0.5
		add_child(star_point)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 1.3
	shape.height = 4.5
	col.shape = shape
	col.position.y = 2.25
	add_child(col)

func _process(delta: float) -> void:
	_pulse_timer += delta * 2.5
	var pulse_glow = 2.5 + sin(_pulse_timer) * 1.2
	for l in _fairy_lights:
		if is_instance_valid(l) and l.material_override is StandardMaterial3D:
			(l.material_override as StandardMaterial3D).emission_energy_multiplier = pulse_glow

extends Area3D
class_name BreakableIcePatch

@export var patch_size: String = "SMALL" # "SMALL" (radius ~3.8m) or "LARGE" (radius ~8.5m)
@export var patch_radius: float = 3.8

var is_broken: bool = false
var is_cracking: bool = false
var crack_timer: float = 0.0

var ice_mesh: MeshInstance3D = null
var water_mesh: MeshInstance3D = null
var crack_lines_root: Node3D = null
var broken_floes_root: Node3D = null

func _ready():
	collision_layer = 0
	collision_mask = 1 | 2 # Detect CharacterBody3D and units

	if patch_size == "LARGE":
		patch_radius = 8.5
	else:
		patch_radius = 3.8

	_setup_collision()
	_setup_visuals()

	body_entered.connect(_on_body_entered)

func _setup_collision():
	var col = get_node_or_null("CollisionShape3D")
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cyl = CylinderShape3D.new()
		cyl.radius = patch_radius
		cyl.height = 1.2
		col.shape = cyl
		col.position.y = 0.6
		add_child(col)

func _setup_visuals():
	# 1. Dark freezing abyss water beneath the ice
	water_mesh = MeshInstance3D.new()
	var w_cyl = CylinderMesh.new()
	w_cyl.top_radius = patch_radius * 1.05
	w_cyl.bottom_radius = patch_radius * 1.12
	w_cyl.height = 0.12
	var w_mat = StandardMaterial3D.new()
	w_mat.albedo_color = Color(0.03, 0.08, 0.18) # Deep sub-zero glacial water
	w_mat.roughness = 0.08
	w_mat.metallic = 0.35
	water_mesh.mesh = w_cyl
	water_mesh.material_override = w_mat
	water_mesh.position.y = 0.02
	add_child(water_mesh)

	# 2. Glacial Thin Ice Surface
	ice_mesh = MeshInstance3D.new()
	var i_cyl = CylinderMesh.new()
	i_cyl.top_radius = patch_radius
	i_cyl.bottom_radius = patch_radius * 1.02
	i_cyl.height = 0.14
	var i_mat = StandardMaterial3D.new()
	i_mat.albedo_color = Color(0.72, 0.90, 0.98, 0.88)
	i_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	i_mat.roughness = 0.12
	i_mat.metallic = 0.1
	i_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ice_mesh.mesh = i_cyl
	ice_mesh.material_override = i_mat
	ice_mesh.position.y = 0.09
	add_child(ice_mesh)

	# 3. Stress Crack Lines
	crack_lines_root = Node3D.new()
	crack_lines_root.name = "CrackLines"
	add_child(crack_lines_root)
	var crack_mat = StandardMaterial3D.new()
	crack_mat.albedo_color = Color(0.25, 0.55, 0.75, 0.85)
	crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var line_count = 6 if patch_size == "SMALL" else 14
	for k in range(line_count):
		var cl = MeshInstance3D.new()
		var cl_box = BoxMesh.new()
		var l_len = randf_range(patch_radius * 0.4, patch_radius * 0.9)
		cl_box.size = Vector3(0.08, 0.02, l_len)
		cl.mesh = cl_box
		cl.material_override = crack_mat
		var ang = (TAU / float(line_count)) * k + randf_range(-0.2, 0.2)
		cl.position = Vector3(cos(ang) * (l_len * 0.45), 0.17, sin(ang) * (l_len * 0.45))
		cl.rotation.y = ang + randf_range(-0.35, 0.35)
		crack_lines_root.add_child(cl)

	# 4. Broken Ice Floes Root (initially hidden)
	broken_floes_root = Node3D.new()
	broken_floes_root.name = "BrokenFloes"
	broken_floes_root.visible = false
	add_child(broken_floes_root)

func _is_unit_flying(unit: Node) -> bool:
	if not is_instance_valid(unit): return false
	if "is_flying" in unit:
		return bool(unit.get("is_flying"))
	if unit.get("unit_attribute") == "Flying" or unit.get("unit_attribute") == "Ethereal": return true
	if unit.is_in_group("Flyer"): return true
	if unit.get("flight_height") != null: return true
	var n = unit.name
	if "Plane" in n or "Flyer" in n or "Gargoyle" in n or "Jellyfish" in n or "Beetle" in n:
		return true
	return false

func _is_unit_heavy(unit: Node) -> bool:
	var n = unit.name
	if "Tank" in n or "Mech" in n or "Leviathan" in n or "Monstrous" in n or "Mutant" in n or "Big" in n:
		return true
	if unit.get("unit_attribute") == "Mechanical":
		return true
	var hc = unit.get_node_or_null("HealthComponent")
	if hc and hc.max_health >= 200.0:
		return true
	return false

func _on_body_entered(_body):
	if is_broken or is_cracking: return
	_check_for_collapse()

func _process(delta):
	if is_broken: return

	if is_cracking:
		crack_timer -= delta
		# Violent ice tremor effect
		if ice_mesh:
			ice_mesh.position.x = randf_range(-0.06, 0.06)
			ice_mesh.position.z = randf_range(-0.06, 0.06)
		if crack_timer <= 0.0:
			_shatter_ice()
	else:
		_check_for_collapse()

func _check_for_collapse():
	if is_broken or is_cracking: return

	var units_on_ice = []
	var has_heavy = false

	for b in get_overlapping_bodies():
		if not is_instance_valid(b) or b == self: continue
		if b is CharacterBody3D and not _is_unit_flying(b):
			var hc = b.get_node_or_null("HealthComponent")
			if hc and not hc.is_dead:
				units_on_ice.append(b)
				if _is_unit_heavy(b):
					has_heavy = true

	if patch_size == "SMALL":
		# Small patches collapse under smaller/normal units
		if units_on_ice.size() >= 1 and not has_heavy:
			is_cracking = true
			crack_timer = 0.38
	else: # LARGE
		# Large patches collapse under heavy units OR several units
		if has_heavy or units_on_ice.size() >= 2:
			is_cracking = true
			crack_timer = 0.45

func _shatter_ice():
	is_broken = true
	is_cracking = false

	if ice_mesh: ice_mesh.visible = false
	if crack_lines_root: crack_lines_root.visible = false
	if broken_floes_root:
		broken_floes_root.visible = true
		_generate_broken_floes()

	# Plunge all units on the ice into the freezing abyss!
	var victims = []
	for b in get_overlapping_bodies():
		if is_instance_valid(b) and b is CharacterBody3D and not _is_unit_flying(b):
			var hc = b.get_node_or_null("HealthComponent")
			if hc and not hc.is_dead:
				victims.append(b)

	for v in victims:
		if is_instance_valid(v):
			var hc = v.get_node_or_null("HealthComponent")
			if hc:
				print("Unit plunged through broken ice: ", v.name)
				hc.take_damage(99999.0, global_position)

	# Spawn Sea Lions from the open ice hole!
	_spawn_sea_lions()

func _generate_broken_floes():
	var floe_mat = StandardMaterial3D.new()
	floe_mat.albedo_color = Color(0.82, 0.94, 1.0, 0.92)
	floe_mat.roughness = 0.15
	floe_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var count = 8 if patch_size == "SMALL" else 18
	for i in range(count):
		var floe = MeshInstance3D.new()
		var fb = BoxMesh.new()
		var sx = randf_range(0.8, 1.8)
		var sz = randf_range(0.8, 2.2)
		fb.size = Vector3(sx, 0.14, sz)
		floe.mesh = fb
		floe.material_override = floe_mat

		var ang = (TAU / float(count)) * i + randf_range(-0.15, 0.15)
		var dist = randf_range(patch_radius * 0.65, patch_radius * 0.95)
		floe.position = Vector3(cos(ang) * dist, 0.06, sin(ang) * dist)
		floe.rotation = Vector3(randf_range(-0.08, 0.08), randf() * TAU, randf_range(-0.08, 0.08))
		broken_floes_root.add_child(floe)

func _spawn_sea_lions():
	var spawn_count = 1 if patch_size == "SMALL" else randi_range(2, 3)
	var parent_node = get_parent() if get_parent() else self
	var sea_lion_script = load("res://Scripts/SeaLionCreature.gd")

	for s_idx in range(spawn_count):
		var sea_lion = sea_lion_script.new()
		var ang = (TAU / float(spawn_count)) * s_idx + randf_range(-0.2, 0.2)
		var dist = randf_range(0.5, patch_radius * 0.45)
		var spawn_pos = global_position + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist)
		sea_lion.position = spawn_pos
		sea_lion.home_position = global_position
		parent_node.add_child(sea_lion)
		print("Sea Lion emerged from broken ice hole at: ", spawn_pos)

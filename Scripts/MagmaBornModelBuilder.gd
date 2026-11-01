class_name MagmaBornModelBuilder
extends RefCounted

static var _mat_cache: Dictionary = {}

static func _get_mat(key: String, albedo: Color, rough: float = 0.8, metal: float = 0.0, emit_col: Color = Color.BLACK, emit_energy: float = 0.0) -> StandardMaterial3D:
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = rough
	mat.metallic = metal
	if emit_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emit_col
		mat.emission_energy_multiplier = emit_energy
	_mat_cache[key] = mat
	return mat

static func build_model(unit: Node3D, unit_name: String) -> void:
	var vp = unit.get_node_or_null("VisualPivot")
	if not vp:
		vp = unit.get_node_or_null("MeshInstance3D")
	if not vp:
		return

	var old = vp.get_node_or_null("MagmaBornRigRoot")
	if old:
		old.queue_free()

	var root = Node3D.new()
	root.name = "MagmaBornRigRoot"
	vp.add_child(root)

	if "MagmaOverlord" in unit_name:
		_build_magma_overlord(root)
	elif "MagmaLavaGrunt" in unit_name:
		_build_magma_lava_grunt(root)
	elif "MagmaTentacleLavaDog" in unit_name:
		_build_magma_tentacle_lava_dog(root)
	elif "MagmaSpitter" in unit_name:
		_build_magma_spitter(root)
	elif "MagmaGolem" in unit_name:
		_build_magma_golem(root)
	elif "MagmaPyrodactyl" in unit_name:
		_build_magma_pyrodactyl(root)
	elif "MagmaTurretSpire" in unit_name:
		_build_magma_turret_spire(root)
	elif "MagmaColossalDragon" in unit_name:
		_build_magma_colossal_dragon(root)

# 1. MAGMA OVERLORD (COMMANDER)
static func _build_magma_overlord(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.14, 0.12, 0.13), 0.9)
	var obsidian = _get_mat("m_obsidian", Color(0.08, 0.06, 0.08), 0.35, 0.65)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.4, 0.0, Color(1.0, 0.42, 0.05), 3.8)

	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new(); t_box.size = Vector3(1.1, 1.4, 0.75)
	torso.mesh = t_box; torso.material_override = obsidian; torso.position.y = 1.65
	root.add_child(torso)

	# Molten Core Vent in Chest
	var vent = MeshInstance3D.new()
	vent.name = "MoltenCore"
	var v_sph = SphereMesh.new(); v_sph.radius = 0.32; v_sph.height = 0.5
	vent.mesh = v_sph; vent.material_override = magma; vent.position = Vector3(0, 0.12, 0.35)
	torso.add_child(vent)

	# Horned Obsidian Helm
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_box = BoxMesh.new(); h_box.size = Vector3(0.55, 0.6, 0.55)
	head.mesh = h_box; head.material_override = basalt; head.position = Vector3(0, 0.95, 0)
	torso.add_child(head)

	for s in [-1.0, 1.0]:
		var horn = MeshInstance3D.new()
		var p = PrismMesh.new(); p.size = Vector3(0.2, 0.65, 0.2)
		horn.mesh = p; horn.material_override = magma
		horn.position = Vector3(s * 0.32, 0.35, -0.08)
		horn.rotation = Vector3(deg_to_rad(-25), 0, deg_to_rad(s * -28))
		head.add_child(horn)

		var pauldron = MeshInstance3D.new()
		var p_box = BoxMesh.new(); p_box.size = Vector3(0.48, 0.48, 0.55)
		pauldron.mesh = p_box; pauldron.material_override = basalt
		pauldron.position = Vector3(s * 0.78, 0.52, 0.0)
		torso.add_child(pauldron)

	# Limbs
	var leg_l = MeshInstance3D.new(); leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.24; l_cyl.bottom_radius = 0.20; l_cyl.height = 1.05
	leg_l.mesh = l_cyl; leg_l.material_override = basalt; leg_l.position = Vector3(-0.35, 0.52, 0.0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new(); leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl; leg_r.material_override = basalt; leg_r.position = Vector3(0.35, 0.52, 0.0)
	root.add_child(leg_r)

	var arm_l = MeshInstance3D.new(); arm_l.name = "LeftArm"
	var a_cyl = CylinderMesh.new(); a_cyl.top_radius = 0.18; a_cyl.bottom_radius = 0.16; a_cyl.height = 1.1
	arm_l.mesh = a_cyl; arm_l.material_override = obsidian; arm_l.position = Vector3(-0.85, 1.35, 0.0)
	root.add_child(arm_l)

	var arm_r = MeshInstance3D.new(); arm_r.name = "RightArm"
	arm_r.mesh = a_cyl; arm_r.material_override = obsidian; arm_r.position = Vector3(0.85, 1.35, 0.0)
	root.add_child(arm_r)

	# Molten War Hammer (Weapon)
	var weapon = MeshInstance3D.new()
	weapon.name = "Weapon"
	var shaft = CylinderMesh.new(); shaft.top_radius = 0.06; shaft.bottom_radius = 0.06; shaft.height = 1.8
	weapon.mesh = shaft; weapon.material_override = basalt; weapon.position = Vector3(0.88, 1.35, -0.45)
	weapon.rotation_degrees = Vector3(65, 0, 0)
	root.add_child(weapon)

	var hammer_head = MeshInstance3D.new()
	var h_mesh = BoxMesh.new(); h_mesh.size = Vector3(0.55, 0.65, 0.95)
	hammer_head.mesh = h_mesh; hammer_head.material_override = magma
	hammer_head.position = Vector3(0, 0.85, 0)
	weapon.add_child(hammer_head)

# 2. MAGMA LAVA GRUNT (CHEAP STUMPY CLUBBER)
static func _build_magma_lava_grunt(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.16, 0.14, 0.15), 0.95)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.4, 0.0, Color(1.0, 0.42, 0.05), 3.8)

	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new(); t_box.size = Vector3(0.85, 0.75, 0.65)
	torso.mesh = t_box; torso.material_override = basalt; torso.position.y = 0.85
	root.add_child(torso)

	# Craggy head sunken into shoulders
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_sph = SphereMesh.new(); h_sph.radius = 0.28; h_sph.height = 0.48
	head.mesh = h_sph; head.material_override = basalt; head.position = Vector3(0, 0.52, -0.08)
	torso.add_child(head)

	var eye = MeshInstance3D.new()
	var e_box = BoxMesh.new(); e_box.size = Vector3(0.32, 0.08, 0.12)
	eye.mesh = e_box; eye.material_override = magma; eye.position = Vector3(0, 0.04, 0.22)
	head.add_child(eye)

	# Short stubby legs
	var leg_l = MeshInstance3D.new(); leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.16; l_cyl.bottom_radius = 0.15; l_cyl.height = 0.55
	leg_l.mesh = l_cyl; leg_l.material_override = basalt; leg_l.position = Vector3(-0.26, 0.28, 0.0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new(); leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl; leg_r.material_override = basalt; leg_r.position = Vector3(0.26, 0.28, 0.0)
	root.add_child(leg_r)

	# Thick rocky stone club
	var weapon = MeshInstance3D.new()
	weapon.name = "Weapon"
	var club_mesh = CylinderMesh.new(); club_mesh.top_radius = 0.22; club_mesh.bottom_radius = 0.08; club_mesh.height = 1.15
	weapon.mesh = club_mesh; weapon.material_override = basalt; weapon.position = Vector3(0.55, 0.75, -0.28)
	weapon.rotation_degrees = Vector3(45, 0, 0)
	root.add_child(weapon)

# 3. MAGMA TENTACLE LAVA DOG
static func _build_magma_tentacle_lava_dog(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.14, 0.11, 0.12), 0.9)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.42, 0.05), 3.8)

	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new(); t_box.size = Vector3(0.65, 0.55, 1.25)
	torso.mesh = t_box; torso.material_override = basalt; torso.position.y = 0.75
	root.add_child(torso)

	# Snapping Head & Molten Jaws
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_box = BoxMesh.new(); h_box.size = Vector3(0.42, 0.45, 0.65)
	head.mesh = h_box; head.material_override = basalt; head.position = Vector3(0, 0.28, -0.75)
	torso.add_child(head)

	var mouth = MeshInstance3D.new()
	mouth.name = "Mouth"
	var m_box = BoxMesh.new(); m_box.size = Vector3(0.35, 0.18, 0.42)
	mouth.mesh = m_box; mouth.material_override = magma; mouth.position = Vector3(0, -0.16, -0.12)
	head.add_child(mouth)

	# Quadruped legs
	var leg_coords = [
		Vector3(-0.35, 0.35, -0.42), Vector3(0.35, 0.35, -0.42),
		Vector3(-0.35, 0.35, 0.42), Vector3(0.35, 0.35, 0.42)
	]
	var leg_names = ["Leg_FL", "Leg_FR", "Leg_BL", "Leg_BR"]
	var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.12; l_cyl.bottom_radius = 0.10; l_cyl.height = 0.7
	for i in range(4):
		var leg = MeshInstance3D.new()
		leg.name = leg_names[i]
		leg.mesh = l_cyl; leg.material_override = basalt; leg.position = leg_coords[i]
		root.add_child(leg)

	# Writhing Molten Tentacles sprouting from shoulders
	for t_idx in range(2):
		var side = -1.0 if t_idx == 0 else 1.0
		var tent = MeshInstance3D.new()
		tent.name = "Tentacle_" + str(t_idx)
		var t_cyl = CylinderMesh.new(); t_cyl.top_radius = 0.05; t_cyl.bottom_radius = 0.12; t_cyl.height = 1.35
		tent.mesh = t_cyl; tent.material_override = magma
		tent.position = Vector3(side * 0.32, 0.35, -0.15)
		tent.rotation_degrees = Vector3(-45, 0, side * 35)
		torso.add_child(tent)

	# Tail
	var tail = MeshInstance3D.new()
	tail.name = "Tail"
	var tail_cyl = CylinderMesh.new(); tail_cyl.top_radius = 0.05; tail_cyl.bottom_radius = 0.10; tail_cyl.height = 0.8
	tail.mesh = tail_cyl; tail.material_override = magma
	tail.position = Vector3(0, 0.15, 0.65); tail.rotation_degrees.x = 45
	torso.add_child(tail)

# 4. MAGMA SPITTER (RANGED VOLCANIC CRAWLER)
static func _build_magma_spitter(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.15, 0.12, 0.13), 0.9)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.42, 0.05), 3.8)

	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_sph = SphereMesh.new(); t_sph.radius = 0.65; t_sph.height = 0.95
	torso.mesh = t_sph; torso.material_override = basalt; torso.position.y = 0.7
	root.add_child(torso)

	# Back Crater Vents (where fireballs shoot from)
	var crater = MeshInstance3D.new()
	crater.name = "Crater"
	var c_cyl = CylinderMesh.new(); c_cyl.top_radius = 0.38; c_cyl.bottom_radius = 0.48; c_cyl.height = 0.35
	crater.mesh = c_cyl; crater.material_override = magma; crater.position = Vector3(0, 0.45, 0.12)
	torso.add_child(crater)

	# 4 Sprawling basalt crawler legs
	var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.11; l_cyl.bottom_radius = 0.08; l_cyl.height = 0.85
	for i in range(4):
		var ang = (TAU / 4.0) * float(i) + (PI / 4.0)
		var leg = MeshInstance3D.new()
		leg.name = "Leg_" + str(i)
		leg.mesh = l_cyl; leg.material_override = basalt
		leg.position = Vector3(cos(ang) * 0.45, 0.35, sin(ang) * 0.45)
		leg.rotation_degrees = Vector3(0, rad_to_deg(ang), 35)
		root.add_child(leg)

# 5. MAGMA GOLEM (COLOSSAL MELEE JUGGERNAUT)
static func _build_magma_golem(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.12, 0.10, 0.11), 0.95)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.42, 0.05), 4.0)

	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new(); t_box.size = Vector3(1.5, 1.6, 1.1)
	torso.mesh = t_box; torso.material_override = basalt; torso.position.y = 1.85
	root.add_child(torso)

	# Glowing lava fissure cross on chest
	var fissure = MeshInstance3D.new()
	var f_box = BoxMesh.new(); f_box.size = Vector3(1.1, 0.25, 0.2)
	fissure.mesh = f_box; fissure.material_override = magma; fissure.position = Vector3(0, 0.2, 0.52)
	torso.add_child(fissure)

	# Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_box = BoxMesh.new(); h_box.size = Vector3(0.65, 0.55, 0.6)
	head.mesh = h_box; head.material_override = basalt; head.position = Vector3(0, 0.95, -0.05)
	torso.add_child(head)

	var eyes = MeshInstance3D.new()
	var e_box = BoxMesh.new(); e_box.size = Vector3(0.42, 0.12, 0.15)
	eyes.mesh = e_box; eyes.material_override = magma; eyes.position = Vector3(0, 0.08, 0.28)
	head.add_child(eyes)

	# Giant heavy pillar legs
	var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.32; l_cyl.bottom_radius = 0.28; l_cyl.height = 1.15
	var leg_l = MeshInstance3D.new(); leg_l.name = "LeftLeg"
	leg_l.mesh = l_cyl; leg_l.material_override = basalt; leg_l.position = Vector3(-0.48, 0.58, 0.0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new(); leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl; leg_r.material_override = basalt; leg_r.position = Vector3(0.48, 0.58, 0.0)
	root.add_child(leg_r)

	# Massive boulder fists
	var f_box_mesh = BoxMesh.new(); f_box_mesh.size = Vector3(0.55, 0.65, 0.65)
	var fist_l = MeshInstance3D.new(); fist_l.name = "LeftFist"
	fist_l.mesh = f_box_mesh; fist_l.material_override = magma; fist_l.position = Vector3(-1.15, 1.35, -0.25)
	root.add_child(fist_l)

	var fist_r = MeshInstance3D.new(); fist_r.name = "RightFist"
	fist_r.mesh = f_box_mesh; fist_r.material_override = magma; fist_r.position = Vector3(1.15, 1.35, -0.25)
	root.add_child(fist_r)

# 6. MAGMA PYRODACTYL (AIRBORNE FLYER)
static func _build_magma_pyrodactyl(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.14, 0.11, 0.12), 0.9)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.42, 0.05), 3.8)

	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_cyl = CylinderMesh.new(); t_cyl.top_radius = 0.22; t_cyl.bottom_radius = 0.28; t_cyl.height = 1.15
	torso.mesh = t_cyl; torso.material_override = basalt; torso.position.y = 1.85
	torso.rotation_degrees.x = 75
	root.add_child(torso)

	# Crested Wyvern Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_mesh = BoxMesh.new(); h_mesh.size = Vector3(0.35, 0.32, 0.75)
	head.mesh = h_mesh; head.material_override = basalt; head.position = Vector3(0, 0.55, -0.35)
	torso.add_child(head)

	var crest = MeshInstance3D.new()
	var c_mesh = PrismMesh.new(); c_mesh.size = Vector3(0.12, 0.65, 0.45)
	crest.mesh = c_mesh; crest.material_override = magma; crest.position = Vector3(0, 0.22, 0.25)
	crest.rotation_degrees.x = -45
	head.add_child(crest)

	# Broad Molten Wings
	for s in [-1.0, 1.0]:
		var wing = MeshInstance3D.new()
		wing.name = "WingL" if s < 0 else "WingR"
		var w_mesh = PrismMesh.new(); w_mesh.size = Vector3(1.65, 0.06, 0.95)
		wing.mesh = w_mesh; wing.material_override = magma
		wing.position = Vector3(s * 1.0, 0.15, 0.0)
		wing.rotation_degrees = Vector3(0, 0, s * -15)
		torso.add_child(wing)

# 7. MAGMA TURRET SPIRE (DEFENSIVE STRUCTURE)
static func _build_magma_turret_spire(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.15, 0.12, 0.13), 0.95)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.42, 0.05), 4.0)

	var spire = MeshInstance3D.new()
	spire.name = "Torso"
	var c_mesh = CylinderMesh.new(); c_mesh.top_radius = 0.55; c_mesh.bottom_radius = 1.25; c_mesh.height = 2.8
	spire.mesh = c_mesh; spire.material_override = basalt; spire.position.y = 1.4
	root.add_child(spire)

	var core = MeshInstance3D.new()
	core.name = "LavaCore"
	var sph = SphereMesh.new(); sph.radius = 0.48; sph.height = 0.8
	core.mesh = sph; core.material_override = magma; core.position.y = 1.2
	spire.add_child(core)

	var turret = MeshInstance3D.new()
	turret.name = "Turret"
	var t_cyl = CylinderMesh.new(); t_cyl.top_radius = 0.22; t_cyl.bottom_radius = 0.28; t_cyl.height = 0.85
	turret.mesh = t_cyl; turret.material_override = basalt; turret.position = Vector3(0, 1.5, -0.35)
	turret.rotation_degrees.x = 90
	spire.add_child(turret)

# 8. MAGMA COLOSSAL DRAGON (APEX TITAN)
static func _build_magma_colossal_dragon(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.13, 0.10, 0.11), 0.9)
	var obsidian = _get_mat("m_obsidian", Color(0.06, 0.05, 0.07), 0.35, 0.7)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.42, 0.05), 4.2)

	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_sph = SphereMesh.new(); t_sph.radius = 1.15; t_sph.height = 2.4
	torso.mesh = t_sph; torso.material_override = obsidian; torso.position.y = 2.5
	torso.rotation_degrees.x = 20
	root.add_child(torso)

	# Massive Dragon Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_mesh = BoxMesh.new(); h_mesh.size = Vector3(0.85, 0.75, 1.45)
	head.mesh = h_mesh; head.material_override = basalt; head.position = Vector3(0, 0.65, -1.35)
	torso.add_child(head)

	var mouth = MeshInstance3D.new()
	mouth.name = "Mouth"
	var m_box = BoxMesh.new(); m_box.size = Vector3(0.72, 0.35, 0.85)
	mouth.mesh = m_box; mouth.material_override = magma; mouth.position = Vector3(0, -0.28, -0.35)
	head.add_child(mouth)

	# Dual sweeping dragon horns
	for s in [-1.0, 1.0]:
		var horn = MeshInstance3D.new()
		var p_mesh = PrismMesh.new(); p_mesh.size = Vector3(0.22, 1.25, 0.35)
		horn.mesh = p_mesh; horn.material_override = magma
		horn.position = Vector3(s * 0.45, 0.45, 0.35)
		horn.rotation_degrees = Vector3(-35, 0, s * -25)
		head.add_child(horn)

	# Colossal Wings
	for s in [-1.0, 1.0]:
		var wing = MeshInstance3D.new()
		wing.name = "WingL" if s < 0 else "WingR"
		var w_mesh = PrismMesh.new(); w_mesh.size = Vector3(3.2, 0.12, 1.85)
		wing.mesh = w_mesh; wing.material_override = magma
		wing.position = Vector3(s * 2.2, 0.35, 0.15)
		wing.rotation_degrees = Vector3(15, s * -15, s * -20)
		torso.add_child(wing)

	# Dragon Tail
	var tail = MeshInstance3D.new()
	tail.name = "Tail"
	var tail_cyl = CylinderMesh.new(); tail_cyl.top_radius = 0.12; tail_cyl.bottom_radius = 0.45; tail_cyl.height = 2.2
	tail.mesh = tail_cyl; tail.material_override = basalt
	tail.position = Vector3(0, -0.25, 1.45); tail.rotation_degrees.x = -25
	torso.add_child(tail)

	# 4 Heavy Draconic Legs
	var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.32; l_cyl.bottom_radius = 0.25; l_cyl.height = 1.35
	var leg_coords = [
		Vector3(-0.75, 0.85, -0.55), Vector3(0.75, 0.85, -0.55),
		Vector3(-0.75, 0.85, 0.55), Vector3(0.75, 0.85, 0.55)
	]
	var leg_names = ["Leg_FL", "Leg_FR", "Leg_BL", "Leg_BR"]
	for i in range(4):
		var leg = MeshInstance3D.new()
		leg.name = leg_names[i]
		leg.mesh = l_cyl; leg.material_override = obsidian; leg.position = leg_coords[i]
		root.add_child(leg)

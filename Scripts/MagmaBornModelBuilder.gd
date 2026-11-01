class_name MagmaBornModelBuilder
extends RefCounted

static var _mat_cache: Dictionary = {}

static func clear_caches() -> void:
	_mat_cache.clear()

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

# =========================================================================
# 1. MAGMA OVERLORD (APEX VOLCANIC TYRANT & SUPREME COMMANDER)
# =========================================================================
static func _build_magma_overlord(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.13, 0.11, 0.12), 0.95)
	var obsidian = _get_mat("m_obsidian", Color(0.06, 0.05, 0.07), 0.28, 0.75)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.40, 0.04), 4.2)
	var magma_core = _get_mat("m_magma_core", Color(1.0, 0.82, 0.22), 0.2, 0.0, Color(1.0, 0.85, 0.25), 5.5)

	# Massive Asymmetric Obsidian Plate Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new(); t_box.size = Vector3(1.25, 1.5, 0.85)
	torso.mesh = t_box; torso.material_override = obsidian; torso.position.y = 1.75
	root.add_child(torso)

	# Searing Molten Core Vent in Sternum
	var vent = MeshInstance3D.new()
	vent.name = "MoltenCore"
	var v_sph = SphereMesh.new(); v_sph.radius = 0.38; v_sph.height = 0.58
	vent.mesh = v_sph; vent.material_override = magma_core; vent.position = Vector3(0, 0.18, 0.40)
	torso.add_child(vent)

	# Jagged Molten Chest Fissures (4 crossing lava lines)
	for i in range(4):
		var fis = MeshInstance3D.new()
		var f_box = BoxMesh.new(); f_box.size = Vector3(0.12, 0.75, 0.06)
		fis.mesh = f_box; fis.material_override = magma
		var f_ang = deg_to_rad(-35.0 if i % 2 == 0 else 35.0)
		fis.position = Vector3(-0.35 + float(i) * 0.23, 0.15, 0.44)
		fis.rotation.z = f_ang
		torso.add_child(fis)

	# Horned Obsidian Helm & Craggy Face
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_box = BoxMesh.new(); h_box.size = Vector3(0.62, 0.65, 0.62)
	head.mesh = h_box; head.material_override = basalt; head.position = Vector3(0, 1.05, -0.05)
	torso.add_child(head)

	# Searing Magma Eyes & Jagged Grin
	var eye_l = MeshInstance3D.new(); eye_l.mesh = BoxMesh.new(); eye_l.mesh.size = Vector3(0.14, 0.06, 0.08)
	eye_l.material_override = magma_core; eye_l.position = Vector3(-0.16, 0.10, 0.32)
	head.add_child(eye_l)
	var eye_r = MeshInstance3D.new(); eye_r.mesh = BoxMesh.new(); eye_r.mesh.size = Vector3(0.14, 0.06, 0.08)
	eye_r.material_override = magma_core; eye_r.position = Vector3(0.16, 0.10, 0.32)
	head.add_child(eye_r)

	var jaw = MeshInstance3D.new(); jaw.mesh = BoxMesh.new(); jaw.mesh.size = Vector3(0.38, 0.14, 0.15)
	jaw.material_override = magma; jaw.position = Vector3(0, -0.22, 0.30)
	head.add_child(jaw)

	# 4 Jagged Demon Horns on Helm
	for s in [-1.0, 1.0]:
		# Primary sweeping horn
		var horn = MeshInstance3D.new()
		var p1 = PrismMesh.new(); p1.size = Vector3(0.22, 0.85, 0.25)
		horn.mesh = p1; horn.material_override = magma
		horn.position = Vector3(s * 0.38, 0.45, -0.10)
		horn.rotation = Vector3(deg_to_rad(-30), 0, deg_to_rad(s * -32))
		head.add_child(horn)

		# Secondary brow thorn
		var thorn = MeshInstance3D.new()
		var p2 = PrismMesh.new(); p2.size = Vector3(0.12, 0.35, 0.15)
		thorn.mesh = p2; thorn.material_override = obsidian
		thorn.position = Vector3(s * 0.26, 0.22, 0.25)
		thorn.rotation = Vector3(deg_to_rad(45), 0, deg_to_rad(s * -20))
		head.add_child(thorn)

	# Asymmetric Volcanic Pauldrons
	# Left: Triple stepped basalt rock spires
	for si in range(3):
		var p_spire = MeshInstance3D.new()
		var sp_m = PrismMesh.new(); sp_m.size = Vector3(0.22, 0.55 + float(si) * 0.25, 0.28)
		p_spire.mesh = sp_m; p_spire.material_override = basalt
		p_spire.position = Vector3(-0.95 - float(si) * 0.15, 0.55 + float(si) * 0.18, -0.15 + float(si) * 0.15)
		torso.add_child(p_spire)

	# Right: Heavy obsidian fortress pauldron with glowing lava vent
	var r_pauldron = MeshInstance3D.new(); r_pauldron.mesh = BoxMesh.new(); r_pauldron.mesh.size = Vector3(0.65, 0.60, 0.70)
	r_pauldron.material_override = obsidian; r_pauldron.position = Vector3(0.95, 0.55, 0.0)
	torso.add_child(r_pauldron)
	var r_vent = MeshInstance3D.new(); r_vent.mesh = CylinderMesh.new(); r_vent.mesh.top_radius = 0.16; r_vent.mesh.bottom_radius = 0.12; r_vent.mesh.height = 0.35
	r_vent.material_override = magma; r_vent.position = Vector3(0.95, 0.90, 0.0)
	torso.add_child(r_vent)

	# Heavy Craggy Basalt Legs with Molten Knees
	for s in [-1.0, 1.0]:
		var leg = MeshInstance3D.new()
		leg.name = "LeftLeg" if s < 0 else "RightLeg"
		var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.26; l_cyl.bottom_radius = 0.22; l_cyl.height = 1.15
		leg.mesh = l_cyl; leg.material_override = basalt; leg.position = Vector3(s * 0.38, 0.58, 0.0)
		root.add_child(leg)

		var knee = MeshInstance3D.new(); knee.mesh = SphereMesh.new(); knee.mesh.radius = 0.16; knee.mesh.height = 0.28
		knee.material_override = magma; knee.position = Vector3(0, 0.08, 0.22)
		leg.add_child(knee)

	# Heavy Arms
	var arm_l = MeshInstance3D.new(); arm_l.name = "LeftArm"
	var a_cyl = CylinderMesh.new(); a_cyl.top_radius = 0.20; a_cyl.bottom_radius = 0.18; a_cyl.height = 1.15
	arm_l.mesh = a_cyl; arm_l.material_override = obsidian; arm_l.position = Vector3(-0.95, 1.45, 0.0)
	root.add_child(arm_l)

	var arm_r = MeshInstance3D.new(); arm_r.name = "RightArm"
	arm_r.mesh = a_cyl; arm_r.material_override = obsidian; arm_r.position = Vector3(0.95, 1.45, 0.0)
	root.add_child(arm_r)

	# "Volcanic Worldbreaker" Molten War Hammer (Weapon)
	var weapon = MeshInstance3D.new()
	weapon.name = "Weapon"
	var shaft = CylinderMesh.new(); shaft.top_radius = 0.07; shaft.bottom_radius = 0.07; shaft.height = 2.1
	weapon.mesh = shaft; weapon.material_override = basalt; weapon.position = Vector3(0.98, 1.45, -0.45)
	weapon.rotation_degrees = Vector3(65, 0, 0)
	root.add_child(weapon)

	# Fractured Obsidian Hammer Back-Wedge
	var h_wedge = MeshInstance3D.new(); h_wedge.mesh = PrismMesh.new(); h_wedge.mesh.size = Vector3(0.45, 0.75, 0.55)
	h_wedge.material_override = obsidian; h_wedge.position = Vector3(0, 0.95, 0.45)
	h_wedge.rotation_degrees.x = -90
	weapon.add_child(h_wedge)

	# Searing Incandescent Magma Striking Head
	var h_face = MeshInstance3D.new(); h_face.mesh = BoxMesh.new(); h_face.mesh.size = Vector3(0.68, 0.75, 0.85)
	h_face.material_override = magma; h_face.position = Vector3(0, 0.95, -0.35)
	weapon.add_child(h_face)

	# 4 Molten Basalt Hammer Spikes on the striking face
	for hi in range(4):
		var h_spike = MeshInstance3D.new(); h_spike.mesh = PrismMesh.new(); h_spike.mesh.size = Vector3(0.12, 0.35, 0.12)
		h_spike.material_override = magma_core
		var x_off = -0.18 if hi % 2 == 0 else 0.18
		var y_off = -0.18 if hi < 2 else 0.18
		h_spike.position = Vector3(x_off, 0.95 + y_off, -0.85)
		h_spike.rotation_degrees.x = 90
		weapon.add_child(h_spike)

# =========================================================================
# 2. MAGMA LAVA GRUNT (SQUAT, HUNTER-CLUBBER STONE MONSTER)
# =========================================================================
static func _build_magma_lava_grunt(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt_rough", Color(0.15, 0.13, 0.14), 0.98)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.40, 0.04), 4.2)
	var magma_core = _get_mat("m_magma_core", Color(1.0, 0.82, 0.22), 0.2, 0.0, Color(1.0, 0.85, 0.25), 5.5)

	# Deformed, Hunched Basalt Boulder Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new(); t_box.size = Vector3(0.95, 0.80, 0.75)
	torso.mesh = t_box; torso.material_override = basalt; torso.position.y = 0.85
	root.add_child(torso)

	# Massive Jagged Basalt Hunchback on the upper spine
	var hunch = MeshInstance3D.new()
	var h_box = BoxMesh.new(); h_box.size = Vector3(0.85, 0.65, 0.65)
	hunch.mesh = h_box; hunch.material_override = basalt; hunch.position = Vector3(0, 0.35, 0.38)
	hunch.rotation_degrees.x = -22
	torso.add_child(hunch)

	# 3 Jagged Rock Spikes jutting out of the hunchback
	for si in range(3):
		var sp = MeshInstance3D.new()
		var sp_m = PrismMesh.new(); sp_m.size = Vector3(0.16, 0.45 + float(si) * 0.15, 0.18)
		sp.mesh = sp_m; sp.material_override = magma
		sp.position = Vector3(-0.25 + float(si) * 0.25, 0.35, 0.18)
		sp.rotation_degrees.x = -35
		hunch.add_child(sp)

	# Sunken Craggy Head low in shoulders (no visible neck)
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_sph = SphereMesh.new(); h_sph.radius = 0.32; h_sph.height = 0.52
	head.mesh = h_sph; head.material_override = basalt; head.position = Vector3(0, 0.42, -0.22)
	torso.add_child(head)

	# Asymmetric Cyclopean Glowing Molten Eye Fissure
	var eye = MeshInstance3D.new(); eye.mesh = BoxMesh.new(); eye.mesh.size = Vector3(0.35, 0.09, 0.14)
	eye.material_override = magma_core; eye.position = Vector3(0.04, 0.05, 0.26)
	eye.rotation_degrees.z = -12
	head.add_child(eye)

	# Crooked Molten Jaw Underbite
	var jaw = MeshInstance3D.new(); jaw.mesh = BoxMesh.new(); jaw.mesh.size = Vector3(0.38, 0.16, 0.22)
	jaw.material_override = magma; jaw.position = Vector3(0, -0.18, 0.24)
	head.add_child(jaw)

	# Thick, Wide-Stance Stubby Legs for Stomping
	for s in [-1.0, 1.0]:
		var leg = MeshInstance3D.new()
		leg.name = "LeftLeg" if s < 0 else "RightLeg"
		var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.20; l_cyl.bottom_radius = 0.22; l_cyl.height = 0.55
		leg.mesh = l_cyl; leg.material_override = basalt; leg.position = Vector3(s * 0.35, 0.28, 0.0)
		root.add_child(leg)

		var foot = MeshInstance3D.new(); foot.mesh = BoxMesh.new(); foot.mesh.size = Vector3(0.28, 0.16, 0.36)
		foot.material_override = basalt; foot.position = Vector3(0, -0.22, 0.08)
		leg.add_child(foot)

	# Left Arm: Short, thick craggy arm with stone claws
	var arm_l = MeshInstance3D.new(); arm_l.name = "LeftArm"
	var al_cyl = CylinderMesh.new(); al_cyl.top_radius = 0.16; al_cyl.bottom_radius = 0.14; al_cyl.height = 0.75
	arm_l.mesh = al_cyl; arm_l.material_override = basalt; arm_l.position = Vector3(-0.62, 0.75, 0.0)
	root.add_child(arm_l)

	# Right Arm: Extra thick elongated brute arm dragging the club
	var arm_r = MeshInstance3D.new(); arm_r.name = "RightArm"
	var ar_cyl = CylinderMesh.new(); ar_cyl.top_radius = 0.22; ar_cyl.bottom_radius = 0.18; ar_cyl.height = 0.95
	arm_r.mesh = ar_cyl; arm_r.material_override = basalt; arm_r.position = Vector3(0.65, 0.72, 0.0)
	root.add_child(arm_r)

	# Heavy Jagged Basalt Boulder Club with Molten Spikes (Weapon)
	var weapon = MeshInstance3D.new()
	weapon.name = "Weapon"
	var shaft = CylinderMesh.new(); shaft.top_radius = 0.07; shaft.bottom_radius = 0.06; shaft.height = 1.35
	weapon.mesh = shaft; weapon.material_override = basalt; weapon.position = Vector3(0.68, 0.75, -0.32)
	weapon.rotation_degrees = Vector3(45, 0, 0)
	root.add_child(weapon)

	# Club Boulder Head
	var c_head = MeshInstance3D.new(); c_head.mesh = BoxMesh.new(); c_head.mesh.size = Vector3(0.48, 0.65, 0.48)
	c_head.material_override = basalt; c_head.position = Vector3(0, 0.55, 0)
	weapon.add_child(c_head)

	# Molten Spikes protruding from Club
	for ci in range(4):
		var c_spike = MeshInstance3D.new(); c_spike.mesh = PrismMesh.new(); c_spike.mesh.size = Vector3(0.12, 0.28, 0.12)
		c_spike.material_override = magma
		var c_ang = (TAU / 4.0) * float(ci)
		c_spike.position = Vector3(cos(c_ang) * 0.28, 0.55, sin(c_ang) * 0.28)
		c_spike.rotation = Vector3(0, -c_ang + PI * 0.5, deg_to_rad(90))
		weapon.add_child(c_spike)

# =========================================================================
# 3. MAGMA TENTACLE LAVA DOG (PREDATORY HOUND WITH WRITHING LAVA TENDRILS)
# =========================================================================
static func _build_magma_tentacle_lava_dog(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.13, 0.11, 0.12), 0.92)
	var obsidian = _get_mat("m_obsidian", Color(0.06, 0.05, 0.07), 0.32, 0.70)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.40, 0.04), 4.2)
	var magma_core = _get_mat("m_magma_core", Color(1.0, 0.82, 0.22), 0.2, 0.0, Color(1.0, 0.85, 0.25), 5.5)

	# Muscular Basalt Hound Torso with Molten Underbelly
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new(); t_box.size = Vector3(0.72, 0.62, 1.45)
	torso.mesh = t_box; torso.material_override = basalt; torso.position.y = 0.80
	root.add_child(torso)

	# Molten Underbelly Heat Line
	var belly = MeshInstance3D.new(); belly.mesh = BoxMesh.new(); belly.mesh.size = Vector3(0.55, 0.15, 1.25)
	belly.material_override = magma; belly.position = Vector3(0, -0.28, 0.0)
	torso.add_child(belly)

	# Jagged Basalt Spinal Ridge Plates
	for si in range(4):
		var ridge = MeshInstance3D.new(); ridge.mesh = PrismMesh.new(); ridge.mesh.size = Vector3(0.12, 0.32, 0.22)
		ridge.material_override = obsidian; ridge.position = Vector3(0, 0.42, -0.45 + float(si) * 0.30)
		ridge.rotation_degrees.x = -25
		torso.add_child(ridge)

	# Snapping Basalt Hound Skull
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_box = BoxMesh.new(); h_box.size = Vector3(0.48, 0.48, 0.75)
	head.mesh = h_box; head.material_override = basalt; head.position = Vector3(0, 0.32, -0.88)
	torso.add_child(head)

	# Blazing Searing Eyes
	for s in [-1.0, 1.0]:
		var eye = MeshInstance3D.new(); eye.mesh = BoxMesh.new(); eye.mesh.size = Vector3(0.08, 0.06, 0.12)
		eye.material_override = magma_core; eye.position = Vector3(s * 0.18, 0.14, -0.22)
		head.add_child(eye)

	# Gaping Molten Maw with Fangs (Mouth)
	var mouth = MeshInstance3D.new()
	mouth.name = "Mouth"
	var m_box = BoxMesh.new(); m_box.size = Vector3(0.38, 0.20, 0.48)
	mouth.mesh = m_box; mouth.material_override = magma; mouth.position = Vector3(0, -0.18, -0.25)
	head.add_child(mouth)

	# Sharp Fangs
	for fi in [-1.0, 1.0]:
		var fang = MeshInstance3D.new(); fang.mesh = PrismMesh.new(); fang.mesh.size = Vector3(0.06, 0.16, 0.08)
		fang.material_override = magma_core; fang.position = Vector3(fi * 0.12, 0.14, -0.15)
		fang.rotation_degrees.x = 180
		mouth.add_child(fang)

	# 4 Muscular Quadruped Legs with Sharp Talons
	var leg_coords = [
		Vector3(-0.38, 0.38, -0.52), Vector3(0.38, 0.38, -0.52),
		Vector3(-0.38, 0.38, 0.52), Vector3(0.38, 0.38, 0.52)
	]
	var leg_names = ["Leg_FL", "Leg_FR", "Leg_BL", "Leg_BR"]
	var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.14; l_cyl.bottom_radius = 0.12; l_cyl.height = 0.76
	for i in range(4):
		var leg = MeshInstance3D.new()
		leg.name = leg_names[i]
		leg.mesh = l_cyl; leg.material_override = basalt; leg.position = leg_coords[i]
		root.add_child(leg)

		# Molten paw pad & claws
		var claw = MeshInstance3D.new(); claw.mesh = BoxMesh.new(); claw.mesh.size = Vector3(0.22, 0.12, 0.28)
		claw.material_override = obsidian; claw.position = Vector3(0, -0.32, -0.06)
		leg.add_child(claw)

	# 4 Writhing Molten Tentacles Sprouting from Volcanic Shoulder Vents
	# 2 Primary Large Tentacles
	for t_idx in range(2):
		var side = -1.0 if t_idx == 0 else 1.0
		var tent = MeshInstance3D.new()
		tent.name = "Tentacle_" + str(t_idx)
		var t_cyl = CylinderMesh.new(); t_cyl.top_radius = 0.05; t_cyl.bottom_radius = 0.14; t_cyl.height = 1.55
		tent.mesh = t_cyl; tent.material_override = magma
		tent.position = Vector3(side * 0.36, 0.42, -0.18)
		tent.rotation_degrees = Vector3(-45, 0, side * 35)
		torso.add_child(tent)

		# Glowing bulbous tip
		var bulb = MeshInstance3D.new(); bulb.mesh = SphereMesh.new(); bulb.mesh.radius = 0.12; bulb.mesh.height = 0.24
		bulb.material_override = magma_core; bulb.position = Vector3(0, 0.78, 0)
		tent.add_child(bulb)

	# 2 Secondary Undulating Dorsal Tendrils
	for t_idx2 in range(2):
		var side2 = -1.0 if t_idx2 == 0 else 1.0
		var tent2 = MeshInstance3D.new()
		tent2.name = "Tentacle_" + str(t_idx2 + 2)
		var t2_cyl = CylinderMesh.new(); t2_cyl.top_radius = 0.04; t2_cyl.bottom_radius = 0.10; t2_cyl.height = 1.15
		tent2.mesh = t2_cyl; tent2.material_override = magma
		tent2.position = Vector3(side2 * 0.28, 0.42, 0.25)
		tent2.rotation_degrees = Vector3(35, 0, side2 * 40)
		torso.add_child(tent2)

	# Tail
	var tail = MeshInstance3D.new()
	tail.name = "Tail"
	var tail_cyl = CylinderMesh.new(); tail_cyl.top_radius = 0.05; tail_cyl.bottom_radius = 0.11; tail_cyl.height = 0.95
	tail.mesh = tail_cyl; tail.material_override = magma
	tail.position = Vector3(0, 0.22, 0.75); tail.rotation_degrees.x = 42
	torso.add_child(tail)

# =========================================================================
# 4. MAGMA SPITTER (GROTESQUE VOLCANIC CALDERA CRAWLER)
# =========================================================================
static func _build_magma_spitter(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt_rough", Color(0.14, 0.11, 0.13), 0.95)
	var obsidian = _get_mat("m_obsidian", Color(0.06, 0.05, 0.07), 0.32, 0.70)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.40, 0.04), 4.2)
	var magma_core = _get_mat("m_magma_core", Color(1.0, 0.82, 0.22), 0.2, 0.0, Color(1.0, 0.85, 0.25), 5.5)

	# Wide Low-Slung Caldera Carapace Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_sph = SphereMesh.new(); t_sph.radius = 0.78; t_sph.height = 1.05
	torso.mesh = t_sph; torso.material_override = basalt; torso.position.y = 0.75
	root.add_child(torso)

	# Searing Volcanic Caldera Crater on the Back (where magma projectiles erupt from)
	var crater = MeshInstance3D.new()
	crater.name = "Crater"
	var c_cyl = CylinderMesh.new(); c_cyl.top_radius = 0.42; c_cyl.bottom_radius = 0.55; c_cyl.height = 0.42
	crater.mesh = c_cyl; crater.material_override = magma_core; crater.position = Vector3(0, 0.52, 0.10)
	torso.add_child(crater)

	# 3 Volcanic Slag Chimneys around the Crater
	for ci in range(3):
		var chim = MeshInstance3D.new()
		var ch_m = CylinderMesh.new(); ch_m.top_radius = 0.10; ch_m.bottom_radius = 0.14; ch_m.height = 0.35
		chim.mesh = ch_m; chim.material_override = basalt
		var ang = (TAU / 3.0) * float(ci)
		chim.position = Vector3(cos(ang) * 0.48, 0.52, sin(ang) * 0.48)
		torso.add_child(chim)

	# Gaping Volcanic Maw Facing Forward (Throat)
	var maw = MeshInstance3D.new()
	maw.name = "Throat"
	var m_cyl = CylinderMesh.new(); m_cyl.top_radius = 0.28; m_cyl.bottom_radius = 0.38; m_cyl.height = 0.55
	maw.mesh = m_cyl; maw.material_override = magma; maw.position = Vector3(0, 0.18, -0.65)
	maw.rotation_degrees.x = 85
	torso.add_child(maw)

	# 4 Heavy Sprawling Basalt Crawler Legs
	var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.14; l_cyl.bottom_radius = 0.09; l_cyl.height = 0.95
	for i in range(4):
		var ang = (TAU / 4.0) * float(i) + (PI / 4.0)
		var leg = MeshInstance3D.new()
		leg.name = "Leg_" + str(i)
		leg.mesh = l_cyl; leg.material_override = basalt
		leg.position = Vector3(cos(ang) * 0.52, 0.38, sin(ang) * 0.52)
		leg.rotation_degrees = Vector3(0, rad_to_deg(ang), 35)
		root.add_child(leg)

		var claw = MeshInstance3D.new(); claw.mesh = PrismMesh.new(); claw.mesh.size = Vector3(0.12, 0.32, 0.14)
		claw.material_override = obsidian; claw.position = Vector3(0, -0.42, 0.0)
		claw.rotation_degrees.z = 90
		leg.add_child(claw)

# =========================================================================
# 5. MAGMA GOLEM (COLOSSAL ASYMMETRIC BASALT BRUTE)
# =========================================================================
static func _build_magma_golem(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt_heavy", Color(0.12, 0.10, 0.11), 0.98)
	var obsidian = _get_mat("m_obsidian", Color(0.06, 0.05, 0.07), 0.30, 0.75)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.40, 0.04), 4.2)
	var magma_core = _get_mat("m_magma_core", Color(1.0, 0.82, 0.22), 0.2, 0.0, Color(1.0, 0.85, 0.25), 5.5)

	# Massive Tectonic Slab Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new(); t_box.size = Vector3(1.65, 1.75, 1.25)
	torso.mesh = t_box; torso.material_override = basalt; torso.position.y = 1.95
	root.add_child(torso)

	# Searing Magma Cross Fissure on Chest
	var f_horiz = MeshInstance3D.new(); f_horiz.mesh = BoxMesh.new(); f_horiz.mesh.size = Vector3(1.35, 0.25, 0.25)
	f_horiz.material_override = magma_core; f_horiz.position = Vector3(0, 0.25, 0.58)
	torso.add_child(f_horiz)

	var f_vert = MeshInstance3D.new(); f_vert.mesh = BoxMesh.new(); f_vert.mesh.size = Vector3(0.28, 1.15, 0.25)
	f_vert.material_override = magma; f_vert.position = Vector3(0, 0.15, 0.58)
	torso.add_child(f_vert)

	# 4 Jagged Basalt Spines rising behind shoulders
	for si in range(4):
		var sp = MeshInstance3D.new(); sp.mesh = PrismMesh.new(); sp.mesh.size = Vector3(0.25, 0.75 + float(si % 2) * 0.35, 0.28)
		sp.material_override = basalt; sp.position = Vector3(-0.55 + float(si) * 0.38, 0.85, 0.42)
		sp.rotation_degrees.x = -25
		torso.add_child(sp)

	# Sunken Basalt Boulder Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_box = BoxMesh.new(); h_box.size = Vector3(0.72, 0.58, 0.68)
	head.mesh = h_box; head.material_override = basalt; head.position = Vector3(0, 1.05, -0.08)
	torso.add_child(head)

	# Incandescent Dual Slit Eyes
	var eye_l = MeshInstance3D.new(); eye_l.mesh = BoxMesh.new(); eye_l.mesh.size = Vector3(0.22, 0.08, 0.12)
	eye_l.material_override = magma_core; eye_l.position = Vector3(-0.18, 0.08, 0.32)
	head.add_child(eye_l)
	var eye_r = MeshInstance3D.new(); eye_r.mesh = BoxMesh.new(); eye_r.mesh.size = Vector3(0.22, 0.08, 0.12)
	eye_r.material_override = magma_core; eye_r.position = Vector3(0.18, 0.08, 0.32)
	head.add_child(eye_r)

	# Colossal Pillar Basalt Legs
	for s in [-1.0, 1.0]:
		var leg = MeshInstance3D.new()
		leg.name = "LeftLeg" if s < 0 else "RightLeg"
		var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.36; l_cyl.bottom_radius = 0.32; l_cyl.height = 1.25
		leg.mesh = l_cyl; leg.material_override = basalt; leg.position = Vector3(s * 0.55, 0.62, 0.0)
		root.add_child(leg)

		var foot = MeshInstance3D.new(); foot.mesh = BoxMesh.new(); foot.mesh.size = Vector3(0.48, 0.25, 0.65)
		foot.material_override = obsidian; foot.position = Vector3(0, -0.52, 0.12)
		leg.add_child(foot)

	# Left Arm: Armored Basalt Slab Guard / Claw (LeftFist)
	var fist_l = MeshInstance3D.new()
	fist_l.name = "LeftFist"
	var fl_mesh = BoxMesh.new(); fl_mesh.size = Vector3(0.58, 0.95, 0.72)
	fist_l.mesh = fl_mesh; fist_l.material_override = basalt; fist_l.position = Vector3(-1.25, 1.45, -0.25)
	root.add_child(fist_l)
	var fl_magma = MeshInstance3D.new(); fl_magma.mesh = BoxMesh.new(); fl_magma.mesh.size = Vector3(0.15, 0.75, 0.74)
	fl_magma.material_override = magma; fl_magma.position = Vector3(-0.25, 0, 0)
	fist_l.add_child(fl_magma)

	# Right Arm: GIGANTIC Over-Sized Wrecking-Boulder Fist (RightFist)
	var fist_r = MeshInstance3D.new()
	fist_r.name = "RightFist"
	var fr_mesh = BoxMesh.new(); fr_mesh.size = Vector3(0.85, 1.05, 0.95)
	fist_r.mesh = fr_mesh; fist_r.material_override = magma; fist_r.position = Vector3(1.35, 1.40, -0.28)
	root.add_child(fist_r)

	# Knuckle Spikes on the Wrecking Fist
	for ki in range(3):
		var k_sp = MeshInstance3D.new(); k_sp.mesh = PrismMesh.new(); k_sp.mesh.size = Vector3(0.18, 0.42, 0.22)
		k_sp.material_override = magma_core; k_sp.position = Vector3(-0.25 + float(ki) * 0.25, 0, -0.55)
		k_sp.rotation_degrees.x = 90
		fist_r.add_child(k_sp)

# =========================================================================
# 6. MAGMA PYRODACTYL (AIRBORNE SERRATED VOLCANIC WYVERN)
# =========================================================================
static func _build_magma_pyrodactyl(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt", Color(0.14, 0.11, 0.12), 0.92)
	var obsidian = _get_mat("m_obsidian", Color(0.06, 0.05, 0.07), 0.28, 0.75)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.40, 0.04), 4.2)
	var magma_core = _get_mat("m_magma_core", Color(1.0, 0.82, 0.22), 0.2, 0.0, Color(1.0, 0.85, 0.25), 5.5)

	# Aerodynamic Basalt Fuselage Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_cyl = CylinderMesh.new(); t_cyl.top_radius = 0.24; t_cyl.bottom_radius = 0.32; t_cyl.height = 1.35
	torso.mesh = t_cyl; torso.material_override = basalt; torso.position.y = 1.95
	torso.rotation_degrees.x = 75
	root.add_child(torso)

	# Elongated Serrated Wyvern Skull
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_mesh = BoxMesh.new(); h_mesh.size = Vector3(0.38, 0.35, 0.95)
	head.mesh = h_mesh; head.material_override = basalt; head.position = Vector3(0, 0.65, -0.45)
	torso.add_child(head)

	# Serrated Obsidian Beak dripping fire
	var beak = MeshInstance3D.new(); beak.mesh = PrismMesh.new(); beak.mesh.size = Vector3(0.22, 0.65, 0.28)
	beak.material_override = magma; beak.position = Vector3(0, -0.05, -0.65)
	beak.rotation_degrees.x = 90
	head.add_child(beak)

	# Swept-Back Flaming Obsidian Crest
	var crest = MeshInstance3D.new()
	crest.name = "Crest"
	var c_mesh = PrismMesh.new(); c_mesh.size = Vector3(0.12, 0.85, 0.45)
	crest.mesh = c_mesh; crest.material_override = obsidian; crest.position = Vector3(0, 0.28, 0.32)
	crest.rotation_degrees.x = -45
	head.add_child(crest)

	var c_fire = MeshInstance3D.new(); c_fire.mesh = BoxMesh.new(); c_fire.mesh.size = Vector3(0.06, 0.75, 0.12)
	c_fire.material_override = magma_core; c_fire.position = Vector3(0, 0.15, 0.0)
	crest.add_child(c_fire)

	# Broad Molten Wings with Obsidian Struts (WingL, WingR)
	for s in [-1.0, 1.0]:
		var wing = MeshInstance3D.new()
		wing.name = "WingL" if s < 0 else "WingR"
		var w_mesh = PrismMesh.new(); w_mesh.size = Vector3(2.1, 0.08, 1.15)
		wing.mesh = w_mesh; wing.material_override = magma
		wing.position = Vector3(s * 1.25, 0.18, 0.0)
		wing.rotation_degrees = Vector3(0, 0, s * -15)
		torso.add_child(wing)

		# Wing Elbow Claw
		var w_claw = MeshInstance3D.new(); w_claw.mesh = PrismMesh.new(); w_claw.mesh.size = Vector3(0.08, 0.28, 0.14)
		w_claw.material_override = obsidian; w_claw.position = Vector3(s * 0.95, 0, -0.55)
		wing.add_child(w_claw)

	# Volcanic Tail with Steering Rudder
	var tail = MeshInstance3D.new()
	tail.name = "Tail"
	var tail_cyl = CylinderMesh.new(); tail_cyl.top_radius = 0.06; tail_cyl.bottom_radius = 0.18; tail_cyl.height = 1.25
	tail.mesh = tail_cyl; tail.material_override = basalt; tail.position = Vector3(0, -0.75, 0.12)
	torso.add_child(tail)

	var rudder = MeshInstance3D.new(); rudder.mesh = PrismMesh.new(); rudder.mesh.size = Vector3(0.08, 0.45, 0.35)
	rudder.material_override = magma; rudder.position = Vector3(0, -0.55, 0)
	tail.add_child(rudder)

# =========================================================================
# 7. MAGMA TURRET SPIRE (LIVING GEOLOGICAL SPIRE & MAGMA CANNON)
# =========================================================================
static func _build_magma_turret_spire(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt_heavy", Color(0.14, 0.11, 0.13), 0.96)
	var obsidian = _get_mat("m_obsidian", Color(0.06, 0.05, 0.07), 0.28, 0.75)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.40, 0.04), 4.2)
	var magma_core = _get_mat("m_magma_core", Color(1.0, 0.82, 0.22), 0.2, 0.0, Color(1.0, 0.85, 0.25), 5.5)

	# Stepped Jagged Basalt Spire Column
	var spire = MeshInstance3D.new()
	spire.name = "Torso"
	var c_mesh = CylinderMesh.new(); c_mesh.top_radius = 0.62; c_mesh.bottom_radius = 1.35; c_mesh.height = 2.9
	spire.mesh = c_mesh; spire.material_override = basalt; spire.position.y = 1.45
	root.add_child(spire)

	# Hexagonal Basalt Base Foundation
	var base_plinth = MeshInstance3D.new(); base_plinth.mesh = CylinderMesh.new(); base_plinth.mesh.top_radius = 1.55; base_plinth.mesh.bottom_radius = 1.75; base_plinth.mesh.height = 0.45; base_plinth.mesh.radial_segments = 6
	base_plinth.material_override = obsidian; base_plinth.position.y = -1.25
	spire.add_child(base_plinth)

	# Churning Molten Lava Core (LavaCore) visible through fissures
	var core = MeshInstance3D.new()
	core.name = "LavaCore"
	var sph = SphereMesh.new(); sph.radius = 0.55; sph.height = 0.95
	core.mesh = sph; core.material_override = magma_core; core.position.y = 1.25
	spire.add_child(core)

	# 4 Vertical Glowing Fissures in the Spire
	for i in range(4):
		var fis = MeshInstance3D.new(); fis.mesh = BoxMesh.new(); fis.mesh.size = Vector3(0.08, 1.6, 0.15)
		fis.material_override = magma
		var ang = (TAU / 4.0) * float(i)
		fis.position = Vector3(cos(ang) * 0.65, 0.15, sin(ang) * 0.65)
		fis.rotation.y = -ang
		spire.add_child(fis)

	# Swiveling Obsidian Magma Cannon Head (Turret)
	var turret = MeshInstance3D.new()
	turret.name = "Turret"
	var t_box = BoxMesh.new(); t_box.size = Vector3(0.72, 0.55, 0.95)
	turret.mesh = t_box; turret.material_override = obsidian; turret.position = Vector3(0, 1.55, -0.32)
	spire.add_child(turret)

	# Dual Bored Basalt Cannon Barrels
	for bi in [-1.0, 1.0]:
		var barrel = MeshInstance3D.new(); barrel.mesh = CylinderMesh.new(); barrel.mesh.top_radius = 0.12; barrel.mesh.bottom_radius = 0.15; barrel.mesh.height = 1.15
		barrel.material_override = basalt; barrel.position = Vector3(bi * 0.22, 0, -0.85)
		barrel.rotation_degrees.x = 90
		turret.add_child(barrel)

		var m_glow = MeshInstance3D.new(); m_glow.mesh = SphereMesh.new(); m_glow.mesh.radius = 0.10; m_glow.mesh.height = 0.18
		m_glow.material_override = magma_core; m_glow.position = Vector3(0, -0.58, 0)
		barrel.add_child(m_glow)

# =========================================================================
# 8. MAGMA COLOSSAL DRAGON (APEX STONE & MAGMA TITAN)
# =========================================================================
static func _build_magma_colossal_dragon(root: Node3D) -> void:
	var basalt = _get_mat("m_basalt_heavy", Color(0.12, 0.10, 0.11), 0.96)
	var obsidian = _get_mat("m_obsidian", Color(0.06, 0.05, 0.07), 0.28, 0.75)
	var magma = _get_mat("m_magma", Color(1.0, 0.42, 0.05), 0.35, 0.0, Color(1.0, 0.40, 0.04), 4.4)
	var magma_core = _get_mat("m_magma_core", Color(1.0, 0.85, 0.25), 0.2, 0.0, Color(1.0, 0.88, 0.28), 5.8)

	# Massive Draconic Obsidian & Basalt Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_sph = SphereMesh.new(); t_sph.radius = 1.25; t_sph.height = 2.6
	torso.mesh = t_sph; torso.material_override = obsidian; torso.position.y = 2.65
	torso.rotation_degrees.x = 22
	root.add_child(torso)

	# Searing Molten Lava Ribcage Plates
	for ri in range(5):
		var rib = MeshInstance3D.new(); rib.mesh = BoxMesh.new(); rib.mesh.size = Vector3(1.45 - float(ri) * 0.12, 0.15, 0.25)
		rib.material_override = magma; rib.position = Vector3(0, -0.45 + float(ri) * 0.25, -0.65 + float(ri) * 0.32)
		torso.add_child(rib)

	# 5 Dorsal Basalt Spines along Spine
	for si in range(5):
		var sp = MeshInstance3D.new(); sp.mesh = PrismMesh.new(); sp.mesh.size = Vector3(0.22, 0.85 + float(si % 2) * 0.35, 0.45)
		sp.material_override = basalt; sp.position = Vector3(0, 0.85, -0.65 + float(si) * 0.35)
		sp.rotation_degrees.x = -25
		torso.add_child(sp)

	# Massive Horrifying Horned Dragon Skull
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_mesh = BoxMesh.new(); h_mesh.size = Vector3(0.95, 0.82, 1.55)
	head.mesh = h_mesh; head.material_override = basalt; head.position = Vector3(0, 0.75, -1.45)
	torso.add_child(head)

	# Burning Golden Eye Crevices
	for s in [-1.0, 1.0]:
		var eye = MeshInstance3D.new(); eye.mesh = BoxMesh.new(); eye.mesh.size = Vector3(0.18, 0.08, 0.28)
		eye.material_override = magma_core; eye.position = Vector3(s * 0.42, 0.22, -0.25)
		eye.rotation_degrees.y = s * 15
		head.add_child(eye)

	# Gaping Molten Maw (Mouth) with Serrated Teeth
	var mouth = MeshInstance3D.new()
	mouth.name = "Mouth"
	var m_box = BoxMesh.new(); m_box.size = Vector3(0.82, 0.42, 0.95)
	mouth.mesh = m_box; mouth.material_override = magma; mouth.position = Vector3(0, -0.32, -0.38)
	head.add_child(mouth)

	# 4 Sweeping Horns (2 Main Backward Sweeping, 2 Forward Brow Horns)
	for s in [-1.0, 1.0]:
		# Giant primary horn
		var horn = MeshInstance3D.new()
		var p_mesh = PrismMesh.new(); p_mesh.size = Vector3(0.28, 1.55, 0.45)
		horn.mesh = p_mesh; horn.material_override = magma
		horn.position = Vector3(s * 0.52, 0.55, 0.42)
		horn.rotation_degrees = Vector3(-42, 0, s * -28)
		head.add_child(horn)

		# Forward brow thorn
		var f_horn = MeshInstance3D.new(); f_horn.mesh = PrismMesh.new(); f_horn.mesh.size = Vector3(0.18, 0.65, 0.25)
		f_horn.material_override = obsidian; f_horn.position = Vector3(s * 0.38, 0.38, -0.55)
		f_horn.rotation_degrees = Vector3(45, 0, s * -15)
		head.add_child(f_horn)

	# Colossal Jagged Wings (WingL, WingR)
	for s in [-1.0, 1.0]:
		var wing = MeshInstance3D.new()
		wing.name = "WingL" if s < 0 else "WingR"
		var w_mesh = PrismMesh.new(); w_mesh.size = Vector3(3.6, 0.15, 2.1)
		wing.mesh = w_mesh; wing.material_override = magma
		wing.position = Vector3(s * 2.4, 0.42, 0.15)
		wing.rotation_degrees = Vector3(15, s * -15, s * -20)
		torso.add_child(wing)

		# Giant Obsidian Wing Claws
		var w_claw = MeshInstance3D.new(); w_claw.mesh = PrismMesh.new(); w_claw.mesh.size = Vector3(0.18, 0.55, 0.28)
		w_claw.material_override = obsidian; w_claw.position = Vector3(s * 1.5, 0, -0.95)
		wing.add_child(w_claw)

	# Heavy Draconic Tail with Spiked Basalt Mace
	var tail = MeshInstance3D.new()
	tail.name = "Tail"
	var tail_cyl = CylinderMesh.new(); tail_cyl.top_radius = 0.15; tail_cyl.bottom_radius = 0.52; tail_cyl.height = 2.4
	tail.mesh = tail_cyl; tail.material_override = basalt; tail.position = Vector3(0, -0.32, 1.55)
	tail.rotation_degrees.x = -28
	torso.add_child(tail)

	# Spiked Volcanic Mace Tip
	var mace = MeshInstance3D.new(); mace.mesh = SphereMesh.new(); mace.mesh.radius = 0.38; mace.mesh.height = 0.75
	mace.material_override = magma; mace.position = Vector3(0, -1.2, 0)
	tail.add_child(mace)
	for mi in range(4):
		var m_sp = MeshInstance3D.new(); m_sp.mesh = PrismMesh.new(); m_sp.mesh.size = Vector3(0.14, 0.35, 0.14)
		m_sp.material_override = magma_core
		var mang = (TAU / 4.0) * float(mi)
		m_sp.position = Vector3(cos(mang) * 0.38, -1.2, sin(mang) * 0.38)
		m_sp.rotation = Vector3(0, -mang + PI * 0.5, deg_to_rad(90))
		tail.add_child(m_sp)

	# 4 Heavy Draconic Pillar Legs (Leg_FL, Leg_FR, Leg_BL, Leg_BR)
	var l_cyl = CylinderMesh.new(); l_cyl.top_radius = 0.38; l_cyl.bottom_radius = 0.30; l_cyl.height = 1.45
	var leg_coords = [
		Vector3(-0.85, 0.85, -0.65), Vector3(0.85, 0.85, -0.65),
		Vector3(-0.85, 0.85, 0.65), Vector3(0.85, 0.85, 0.65)
	]
	var leg_names = ["Leg_FL", "Leg_FR", "Leg_BL", "Leg_BR"]
	for i in range(4):
		var leg = MeshInstance3D.new()
		leg.name = leg_names[i]
		leg.mesh = l_cyl; leg.material_override = obsidian; leg.position = leg_coords[i]
		root.add_child(leg)

		var foot = MeshInstance3D.new(); foot.mesh = BoxMesh.new(); foot.mesh.size = Vector3(0.55, 0.28, 0.72)
		foot.material_override = basalt; foot.position = Vector3(0, -0.62, 0.15)
		leg.add_child(foot)

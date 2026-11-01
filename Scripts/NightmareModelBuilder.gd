extends RefCounted
class_name NightmareModelBuilder

# =============================================================================
# THE NIGHTMARE COURT — PROCEDURAL 3D ANATOMY & MODEL BUILDER
# =============================================================================

static var _cached_materials: Dictionary = {}

static func clear_caches():
	_cached_materials.clear()

static func _get_mat(key: String, albedo: Color, rough: float = 0.8, metallic: float = 0.0, emit_col: Color = Color.BLACK, emit_energy: float = 0.0) -> StandardMaterial3D:
	if _cached_materials.has(key):
		return _cached_materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = metallic
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = emit_col
		m.emission_energy_multiplier = emit_energy
	_cached_materials[key] = m
	return m

static func build_model(unit: CharacterBody3D, unit_name: String) -> Node3D:
	var pivot = unit.get_node_or_null("VisualPivot")
	if not pivot:
		pivot = unit.get_node_or_null("MeshInstance3D")
	if not pivot:
		pivot = unit.get_node_or_null("Visuals")
	if not pivot:
		pivot = Node3D.new()
		pivot.name = "VisualPivot"
		unit.add_child(pivot)

	# Hide previous raw mesh if it exists
	if pivot is MeshInstance3D:
		pivot.mesh = null
	for child in pivot.get_children():
		if child.name == "NightmareRigRoot":
			child.queue_free()
		elif child.name == "ShieldVisualRoot" or child.name == "ArmorPlatesRoot":
			continue
		else:
			child.visible = false

	var root = Node3D.new()
	root.name = "NightmareRigRoot"
	pivot.add_child(root)

	if "SupremeNecromancer" in unit_name:
		_build_supreme_necromancer(root)
	elif "GrandVampire" in unit_name:
		_build_grand_vampire(root)
	elif "DemonKnight" in unit_name:
		_build_demon_knight(root)
	elif "SkeletonSwordsman" in unit_name:
		_build_skeleton_swordsman(root)
	elif "SkeletonArcher" in unit_name:
		_build_skeleton_archer(root)
	elif "Zombie" in unit_name:
		_build_zombie(root)
	elif "BoneGiant" in unit_name:
		_build_bone_giant(root)
	elif "VampireDuelist" in unit_name:
		_build_vampire_duelist(root)
	elif "BatSwarm" in unit_name:
		_build_bat_swarm(root)
	elif "Werewolf" in unit_name:
		_build_werewolf(root)
	elif "DireWolf" in unit_name:
		_build_dire_wolf(root)
	elif "FireImp" in unit_name:
		_build_fire_imp(root)
	elif "HornedDemon" in unit_name:
		_build_horned_demon(root)
	elif "Hellhound" in unit_name:
		_build_hellhound(root)
	elif "JackOLantern" in unit_name or "Jack" in unit_name:
		_build_jack_o_lantern(root)
	else:
		_build_zombie(root)

	return root

# -----------------------------------------------------------------------------
# 1. SUPREME NECROMANCER (Commander)
# -----------------------------------------------------------------------------
static func _build_supreme_necromancer(root: Node3D):
	root.scale = Vector3(1.2, 1.2, 1.2)
	var robe_mat = _get_mat("necro_robe", Color(0.12, 0.06, 0.18), 0.85)
	var bone_mat = _get_mat("bone_mat", Color(0.86, 0.84, 0.76), 0.6)
	var soul_mat = _get_mat("soul_green", Color(0.2, 1.0, 0.35), 0.3, 0.0, Color(0.2, 1.0, 0.35), 3.2)
	var gold_mat = _get_mat("dark_gold", Color(0.78, 0.62, 0.22), 0.3, 0.8)

	# Hovering Body Center
	var body = Node3D.new()
	body.name = "Body"
	body.position = Vector3(0, 0.15, 0)
	root.add_child(body)

	# Flared Tattered Skirt / Robe
	var skirt = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.32
	s_cyl.bottom_radius = 0.68
	s_cyl.height = 1.1
	skirt.mesh = s_cyl
	skirt.material_override = robe_mat
	skirt.position = Vector3(0, 0.65, 0)
	body.add_child(skirt)

	# Torso with Ribcage Opening
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.48, 0.55, 0.32)
	torso.mesh = t_box
	torso.material_override = robe_mat
	torso.position = Vector3(0, 1.25, 0)
	body.add_child(torso)

	# Skeletal Floating Arms for spellcasting
	var arm_l = MeshInstance3D.new()
	arm_l.name = "LeftArm"
	var al_box = BoxMesh.new()
	al_box.size = Vector3(0.10, 0.10, 0.55)
	arm_l.mesh = al_box
	arm_l.material_override = bone_mat
	arm_l.position = Vector3(-0.35, 1.25, 0.22)
	arm_l.rotation.x = deg_to_rad(-20.0)
	body.add_child(arm_l)

	var arm_r = MeshInstance3D.new()
	arm_r.name = "RightArm"
	arm_r.mesh = al_box
	arm_r.material_override = bone_mat
	arm_r.position = Vector3(0.35, 1.25, 0.22)
	arm_r.rotation.x = deg_to_rad(-20.0)
	body.add_child(arm_r)

	# Glowing Soul Inside Chest
	var soul_core = MeshInstance3D.new()
	var sc_sphere = SphereMesh.new()
	sc_sphere.radius = 0.12
	sc_sphere.height = 0.24
	soul_core.mesh = sc_sphere
	soul_core.material_override = soul_mat
	soul_core.position = Vector3(0, 1.25, 0.08)
	body.add_child(soul_core)

	# Hood & Skull Head
	var hood = MeshInstance3D.new()
	var h_cyl = CylinderMesh.new()
	h_cyl.top_radius = 0.18
	h_cyl.bottom_radius = 0.28
	h_cyl.height = 0.42
	hood.mesh = h_cyl
	hood.material_override = robe_mat
	hood.position = Vector3(0, 1.68, 0)
	body.add_child(hood)

	var skull = MeshInstance3D.new()
	skull.name = "Head"
	var sk_sphere = SphereMesh.new()
	sk_sphere.radius = 0.16
	sk_sphere.height = 0.30
	skull.mesh = sk_sphere
	skull.material_override = bone_mat
	skull.position = Vector3(0, 1.65, 0.06)
	body.add_child(skull)

	# Glowing Green Eyes
	for x_side in [-0.06, 0.06]:
		var eye = MeshInstance3D.new()
		var e_box = BoxMesh.new()
		e_box.size = Vector3(0.04, 0.04, 0.04)
		eye.mesh = e_box
		eye.material_override = soul_mat
		eye.position = Vector3(x_side, 1.67, 0.21)
		body.add_child(eye)

	# Floating Bone Staff with Eldritch Skull
	var staff = Node3D.new()
	staff.name = "Staff"
	staff.position = Vector3(0.42, 0.6, 0.22)
	body.add_child(staff)

	var pole = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.035
	p_cyl.bottom_radius = 0.04
	p_cyl.height = 1.95
	pole.mesh = p_cyl
	pole.material_override = bone_mat
	pole.position = Vector3(0, 0.5, 0)
	staff.add_child(pole)

	var staff_skull = MeshInstance3D.new()
	var ss_sphere = SphereMesh.new()
	ss_sphere.radius = 0.14
	ss_sphere.height = 0.26
	staff_skull.mesh = ss_sphere
	staff_skull.material_override = bone_mat
	staff_skull.position = Vector3(0, 1.52, 0)
	staff.add_child(staff_skull)

	var staff_flame = MeshInstance3D.new()
	staff_flame.name = "StaffFlame"
	var sf_sphere = SphereMesh.new()
	sf_sphere.radius = 0.18
	sf_sphere.height = 0.38
	staff_flame.mesh = sf_sphere
	staff_flame.material_override = soul_mat
	staff_flame.position = Vector3(0, 1.76, 0)
	staff.add_child(staff_flame)

# -----------------------------------------------------------------------------
# 2. GRAND VAMPIRE LORD (Commander)
# -----------------------------------------------------------------------------
static func _build_grand_vampire(root: Node3D):
	root.scale = Vector3(1.15, 1.15, 1.15)
	var cape_black = _get_mat("vamp_black", Color(0.08, 0.08, 0.10), 0.7)
	var cape_red = _get_mat("vamp_red", Color(0.65, 0.08, 0.14), 0.4)
	var skin_pale = _get_mat("vamp_skin", Color(0.92, 0.90, 0.92), 0.7)
	var blood_gem = _get_mat("vamp_gem", Color(0.95, 0.10, 0.15), 0.2, 0.0, Color(1.0, 0.15, 0.20), 2.5)
	var steel_mat = _get_mat("vamp_steel", Color(0.85, 0.88, 0.92), 0.2, 0.9)

	# Torso & Waistcoat
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.44, 0.62, 0.26)
	torso.mesh = t_box
	torso.material_override = cape_red
	torso.position = Vector3(0, 1.15, 0)
	root.add_child(torso)

	# High Flared Gothic Standing Collar
	var collar_l = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.12, 0.45, 0.28)
	collar_l.mesh = c_box
	collar_l.material_override = cape_black
	collar_l.position = Vector3(-0.24, 1.55, -0.06)
	collar_l.rotation.z = -0.32
	root.add_child(collar_l)

	var collar_r = MeshInstance3D.new()
	collar_r.mesh = c_box
	collar_r.material_override = cape_black
	collar_r.position = Vector3(0.24, 1.55, -0.06)
	collar_r.rotation.z = 0.32
	root.add_child(collar_r)

	# Flowing Midnight Cape
	var cape = MeshInstance3D.new()
	cape.name = "Cape"
	var cp_box = BoxMesh.new()
	cp_box.size = Vector3(0.68, 1.25, 0.06)
	cape.mesh = cp_box
	cape.material_override = cape_black
	cape.position = Vector3(0, 0.95, -0.16)
	cape.rotation.x = 0.18
	root.add_child(cape)

	# Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_sphere = SphereMesh.new()
	h_sphere.radius = 0.16
	h_sphere.height = 0.32
	head.mesh = h_sphere
	head.material_override = skin_pale
	head.position = Vector3(0, 1.62, 0)
	root.add_child(head)

	# Glowing Crimson Eyes
	for x in [-0.06, 0.06]:
		var eye = MeshInstance3D.new()
		var e_box = BoxMesh.new()
		e_box.size = Vector3(0.04, 0.03, 0.03)
		eye.mesh = e_box
		eye.material_override = blood_gem
		eye.position = Vector3(x, 1.64, 0.15)
		root.add_child(eye)

	# Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.08
	l_cyl.bottom_radius = 0.06
	l_cyl.height = 0.85
	leg_l.mesh = l_cyl
	leg_l.material_override = cape_black
	leg_l.position = Vector3(-0.14, 0.44, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = cape_black
	leg_r.position = Vector3(0.14, 0.44, 0)
	root.add_child(leg_r)

	# Dual Blood Rapiers
	var rapier_l = MeshInstance3D.new()
	rapier_l.name = "WeaponL"
	var r_cyl = CylinderMesh.new()
	r_cyl.top_radius = 0.015
	r_cyl.bottom_radius = 0.03
	r_cyl.height = 1.05
	rapier_l.mesh = r_cyl
	rapier_l.material_override = steel_mat
	rapier_l.rotation.x = deg_to_rad(65.0)
	rapier_l.position = Vector3(-0.36, 0.95, 0.35)
	root.add_child(rapier_l)

	var rapier_r = MeshInstance3D.new()
	rapier_r.name = "WeaponR"
	rapier_r.mesh = r_cyl
	rapier_r.material_override = steel_mat
	rapier_r.rotation.x = deg_to_rad(65.0)
	rapier_r.position = Vector3(0.36, 0.95, 0.35)
	root.add_child(rapier_r)

# -----------------------------------------------------------------------------
# 3. DEMON KNIGHT (Commander)
# -----------------------------------------------------------------------------
static func _build_demon_knight(root: Node3D):
	root.scale = Vector3(1.25, 1.25, 1.25)
	var plate_mat = _get_mat("obsidian_plate", Color(0.12, 0.11, 0.14), 0.4, 0.75)
	var fire_mat = _get_mat("hellfire", Color(1.0, 0.35, 0.05), 0.2, 0.0, Color(1.0, 0.42, 0.05), 3.5)
	var horn_mat = _get_mat("demon_horns", Color(0.08, 0.07, 0.08), 0.5)

	# Heavy Plate Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.56, 0.65, 0.38)
	torso.mesh = t_box
	torso.material_override = plate_mat
	torso.position = Vector3(0, 1.15, 0)
	root.add_child(torso)

	# Spiked Spikes on Shoulders
	for x in [-0.34, 0.34]:
		var pld = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.24, 0.22, 0.28)
		pld.mesh = p_box
		pld.material_override = plate_mat
		pld.position = Vector3(x, 1.45, 0)
		root.add_child(pld)

		var spike = MeshInstance3D.new()
		var s_cyl = CylinderMesh.new()
		s_cyl.top_radius = 0.01
		s_cyl.bottom_radius = 0.06
		s_cyl.height = 0.32
		spike.mesh = s_cyl
		spike.material_override = plate_mat
		spike.position = Vector3(x * 1.1, 1.62, 0)
		root.add_child(spike)

	# Greathelm with Visor
	var helm = MeshInstance3D.new()
	helm.name = "Head"
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.32, 0.36, 0.34)
	helm.mesh = h_box
	helm.material_override = plate_mat
	helm.position = Vector3(0, 1.65, 0)
	root.add_child(helm)

	# Fiery Visor Slit
	var visor = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.22, 0.05, 0.04)
	visor.mesh = v_box
	visor.material_override = fire_mat
	visor.position = Vector3(0, 1.66, 0.17)
	root.add_child(visor)

	# Curved Demon Horns
	for x_side in [-0.22, 0.22]:
		var horn = MeshInstance3D.new()
		var hn_cyl = CylinderMesh.new()
		hn_cyl.top_radius = 0.02
		hn_cyl.bottom_radius = 0.08
		hn_cyl.height = 0.52
		horn.mesh = hn_cyl
		horn.material_override = horn_mat
		horn.rotation.z = deg_to_rad(-45.0 if x_side > 0 else 45.0)
		horn.rotation.x = deg_to_rad(-25.0)
		horn.position = Vector3(x_side, 1.82, 0.04)
		root.add_child(horn)

	# Armored Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_box = BoxMesh.new()
	l_box.size = Vector3(0.18, 0.85, 0.20)
	leg_l.mesh = l_box
	leg_l.material_override = plate_mat
	leg_l.position = Vector3(-0.16, 0.44, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_box
	leg_r.material_override = plate_mat
	leg_r.position = Vector3(0.16, 0.44, 0)
	root.add_child(leg_r)

	# Massive Jagged Flaming Greatsword
	var sword = Node3D.new()
	sword.name = "Weapon"
	sword.position = Vector3(0.38, 1.0, 0.25)
	sword.rotation.x = deg_to_rad(30.0)
	root.add_child(sword)

	var blade = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.14, 1.45, 0.04)
	blade.mesh = b_box
	blade.material_override = plate_mat
	blade.position = Vector3(0, 0.5, 0)
	sword.add_child(blade)

	var flame_edge = MeshInstance3D.new()
	var fe_box = BoxMesh.new()
	fe_box.size = Vector3(0.18, 1.42, 0.02)
	flame_edge.mesh = fe_box
	flame_edge.material_override = fire_mat
	flame_edge.position = Vector3(0, 0.5, 0)
	sword.add_child(flame_edge)

# -----------------------------------------------------------------------------
# 4. SKELETON SWORDSMAN
# -----------------------------------------------------------------------------
static func _build_skeleton_swordsman(root: Node3D):
	var bone_mat = _get_mat("bone_mat", Color(0.86, 0.84, 0.76), 0.6)
	var rust_mat = _get_mat("rusty_iron", Color(0.42, 0.32, 0.28), 0.7, 0.6)
	var eye_mat = _get_mat("amber_eye", Color(1.0, 0.55, 0.1), 0.2, 0.0, Color(1.0, 0.55, 0.1), 2.2)

	# Ribcage
	var rib = MeshInstance3D.new()
	rib.name = "Torso"
	var r_box = BoxMesh.new()
	r_box.size = Vector3(0.38, 0.48, 0.22)
	rib.mesh = r_box
	rib.material_override = bone_mat
	rib.position = Vector3(0, 1.15, 0)
	root.add_child(rib)

	# Skull
	var skull = MeshInstance3D.new()
	skull.name = "Head"
	var s_sphere = SphereMesh.new()
	s_sphere.radius = 0.15
	s_sphere.height = 0.28
	skull.mesh = s_sphere
	skull.material_override = bone_mat
	skull.position = Vector3(0, 1.55, 0)
	root.add_child(skull)

	for x in [-0.05, 0.05]:
		var eye = MeshInstance3D.new()
		var e_box = BoxMesh.new()
		e_box.size = Vector3(0.03, 0.03, 0.03)
		eye.mesh = e_box
		eye.material_override = eye_mat
		eye.position = Vector3(x, 1.56, 0.14)
		root.add_child(eye)

	# Bony Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.04
	l_cyl.bottom_radius = 0.035
	l_cyl.height = 0.82
	leg_l.mesh = l_cyl
	leg_l.material_override = bone_mat
	leg_l.position = Vector3(-0.12, 0.45, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = bone_mat
	leg_r.position = Vector3(0.12, 0.45, 0)
	root.add_child(leg_r)

	# Rusty Scimitar / Shortsword
	var sword = MeshInstance3D.new()
	sword.name = "Weapon"
	var sw_box = BoxMesh.new()
	sw_box.size = Vector3(0.06, 0.85, 0.03)
	sword.mesh = sw_box
	sword.material_override = rust_mat
	sword.rotation.x = deg_to_rad(60.0)
	sword.position = Vector3(0.28, 0.95, 0.25)
	root.add_child(sword)

	# Chipped Buckler Shield
	var buckler = MeshInstance3D.new()
	buckler.name = "Shield"
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.22
	b_cyl.bottom_radius = 0.22
	b_cyl.height = 0.04
	buckler.mesh = b_cyl
	buckler.material_override = rust_mat
	buckler.rotation.x = deg_to_rad(90.0)
	buckler.position = Vector3(-0.28, 1.05, 0.15)
	root.add_child(buckler)

# -----------------------------------------------------------------------------
# 5. SKELETON ARCHER
# -----------------------------------------------------------------------------
static func _build_skeleton_archer(root: Node3D):
	var bone_mat = _get_mat("bone_mat", Color(0.86, 0.84, 0.76), 0.6)
	var wood_mat = _get_mat("bow_wood", Color(0.38, 0.26, 0.16), 0.8)
	var cloth_mat = _get_mat("archer_cloth", Color(0.25, 0.20, 0.18), 0.9)

	# Ribcage
	var rib = MeshInstance3D.new()
	rib.name = "Torso"
	var r_box = BoxMesh.new()
	r_box.size = Vector3(0.36, 0.46, 0.20)
	rib.mesh = r_box
	rib.material_override = bone_mat
	rib.position = Vector3(0, 1.15, 0)
	root.add_child(rib)

	# Skull with tattered hood
	var hood = MeshInstance3D.new()
	hood.name = "Head"
	var h_cyl = CylinderMesh.new()
	h_cyl.top_radius = 0.18
	h_cyl.bottom_radius = 0.24
	h_cyl.height = 0.32
	hood.mesh = h_cyl
	hood.material_override = cloth_mat
	hood.position = Vector3(0, 1.58, 0)
	root.add_child(hood)

	# Bone Bow
	var bow = MeshInstance3D.new()
	bow.name = "Weapon"
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.025
	b_cyl.bottom_radius = 0.025
	b_cyl.height = 1.15
	bow.mesh = b_cyl
	bow.material_override = wood_mat
	bow.position = Vector3(-0.28, 1.15, 0.3)
	root.add_child(bow)

	# Bony Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.04
	l_cyl.bottom_radius = 0.035
	l_cyl.height = 0.82
	leg_l.mesh = l_cyl
	leg_l.material_override = bone_mat
	leg_l.position = Vector3(-0.12, 0.45, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = bone_mat
	leg_r.position = Vector3(0.12, 0.45, 0)
	root.add_child(leg_r)

# -----------------------------------------------------------------------------
# 6. SHAMBLING ZOMBIE
# -----------------------------------------------------------------------------
static func _build_zombie(root: Node3D):
	var rot_skin = _get_mat("zombie_skin", Color(0.42, 0.48, 0.38), 0.85)
	var rag_mat = _get_mat("zombie_rags", Color(0.24, 0.22, 0.20), 0.95)

	# Hunched Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.48, 0.58, 0.32)
	torso.mesh = t_box
	torso.material_override = rot_skin
	torso.position = Vector3(0, 1.05, 0.08)
	torso.rotation.x = 0.22 # Hunched forward
	root.add_child(torso)

	# Tattered Rags on Torso
	var rags = MeshInstance3D.new()
	var rg_box = BoxMesh.new()
	rg_box.size = Vector3(0.52, 0.34, 0.36)
	rags.mesh = rg_box
	rags.material_override = rag_mat
	rags.position = Vector3(0, 1.12, 0.08)
	torso.add_child(rags)

	# Rotting Head with slack jaw
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_sphere = SphereMesh.new()
	h_sphere.radius = 0.17
	h_sphere.height = 0.32
	head.mesh = h_sphere
	head.material_override = rot_skin
	head.position = Vector3(0, 1.48, 0.18)
	head.rotation.z = -0.15 # Tilted crooked neck
	root.add_child(head)

	# Reaching Outstretched Zombie Arms
	var arm_l = MeshInstance3D.new()
	arm_l.name = "LeftArm"
	var a_box = BoxMesh.new()
	a_box.size = Vector3(0.12, 0.12, 0.65)
	arm_l.mesh = a_box
	arm_l.material_override = rot_skin
	arm_l.position = Vector3(-0.28, 1.15, 0.35)
	root.add_child(arm_l)

	var arm_r = MeshInstance3D.new()
	arm_r.name = "RightArm"
	arm_r.mesh = a_box
	arm_r.material_override = rot_skin
	arm_r.position = Vector3(0.28, 1.15, 0.35)
	root.add_child(arm_r)

	# Asymmetrical Stumbling Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var ll_box = BoxMesh.new()
	ll_box.size = Vector3(0.16, 0.80, 0.16)
	leg_l.mesh = ll_box
	leg_l.material_override = rag_mat
	leg_l.position = Vector3(-0.14, 0.40, 0.04)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = ll_box
	leg_r.material_override = rag_mat
	leg_r.position = Vector3(0.14, 0.40, -0.08)
	leg_r.rotation.z = 0.14 # Dragging limping leg
	root.add_child(leg_r)

# -----------------------------------------------------------------------------
# 7. BONE GIANT
# -----------------------------------------------------------------------------
static func _build_bone_giant(root: Node3D):
	root.scale = Vector3(1.45, 1.45, 1.45)
	var bone_mat = _get_mat("bone_mat", Color(0.86, 0.84, 0.76), 0.6)
	var dark_mat = _get_mat("bone_dark", Color(0.32, 0.30, 0.28), 0.8)

	# Colossal Chest
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.85, 0.95, 0.55)
	torso.mesh = t_box
	torso.material_override = bone_mat
	torso.position = Vector3(0, 1.55, 0)
	root.add_child(torso)

	# Multiple Skulls Embedded on Chest
	for off in [Vector3(-0.25, 1.7, 0.3), Vector3(0.25, 1.7, 0.3), Vector3(0, 1.35, 0.3)]:
		var sk = MeshInstance3D.new()
		var sk_s = SphereMesh.new()
		sk_s.radius = 0.12
		sk_s.height = 0.22
		sk.mesh = sk_s
		sk.material_override = bone_mat
		sk.position = off
		root.add_child(sk)

	# Giant Skull Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_s = SphereMesh.new()
	h_s.radius = 0.26
	h_s.height = 0.48
	head.mesh = h_s
	head.material_override = bone_mat
	head.position = Vector3(0, 2.25, 0.05)
	root.add_child(head)

	# Massive Bone Pillars for Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.16
	l_cyl.bottom_radius = 0.14
	l_cyl.height = 1.05
	leg_l.mesh = l_cyl
	leg_l.material_override = bone_mat
	leg_l.position = Vector3(-0.28, 0.55, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = bone_mat
	leg_r.position = Vector3(0.28, 0.55, 0)
	root.add_child(leg_r)

	# Giant Bone Club
	var club = MeshInstance3D.new()
	club.name = "Weapon"
	var c_cyl = CylinderMesh.new()
	c_cyl.top_radius = 0.22
	c_cyl.bottom_radius = 0.08
	c_cyl.height = 1.6
	club.mesh = c_cyl
	club.material_override = dark_mat
	club.rotation.x = deg_to_rad(45.0)
	club.position = Vector3(0.65, 1.35, 0.35)
	root.add_child(club)

# -----------------------------------------------------------------------------
# 8. VAMPIRE DUELIST
# -----------------------------------------------------------------------------
static func _build_vampire_duelist(root: Node3D):
	root.scale = Vector3(1.05, 1.05, 1.05)
	var coat_mat = _get_mat("vamp_black", Color(0.08, 0.08, 0.10), 0.7)
	var red_mat = _get_mat("vamp_red", Color(0.65, 0.08, 0.14), 0.4)
	var skin_pale = _get_mat("vamp_skin", Color(0.92, 0.90, 0.92), 0.7)
	var steel_mat = _get_mat("vamp_steel", Color(0.85, 0.88, 0.92), 0.2, 0.9)

	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.42, 0.58, 0.24)
	torso.mesh = t_box
	torso.material_override = coat_mat
	torso.position = Vector3(0, 1.10, 0)
	root.add_child(torso)

	var ascot = MeshInstance3D.new()
	var a_box = BoxMesh.new()
	a_box.size = Vector3(0.18, 0.22, 0.06)
	ascot.mesh = a_box
	ascot.material_override = red_mat
	ascot.position = Vector3(0, 1.25, 0.13)
	root.add_child(ascot)

	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_s = SphereMesh.new()
	h_s.radius = 0.15
	h_s.height = 0.30
	head.mesh = h_s
	head.material_override = skin_pale
	head.position = Vector3(0, 1.55, 0)
	root.add_child(head)

	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.07
	l_cyl.bottom_radius = 0.05
	l_cyl.height = 0.82
	leg_l.mesh = l_cyl
	leg_l.material_override = coat_mat
	leg_l.position = Vector3(-0.12, 0.42, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = coat_mat
	leg_r.position = Vector3(0.12, 0.42, 0)
	root.add_child(leg_r)

	var rapier = MeshInstance3D.new()
	rapier.name = "Weapon"
	var r_cyl = CylinderMesh.new()
	r_cyl.top_radius = 0.015
	r_cyl.bottom_radius = 0.025
	r_cyl.height = 0.95
	rapier.mesh = r_cyl
	rapier.material_override = steel_mat
	rapier.rotation.x = deg_to_rad(75.0)
	rapier.position = Vector3(0.32, 0.95, 0.4)
	root.add_child(rapier)

# -----------------------------------------------------------------------------
# 9. VAMPIRE BAT SWARM
# -----------------------------------------------------------------------------
static func _build_bat_swarm(root: Node3D):
	var bat_mat = _get_mat("bat_skin", Color(0.14, 0.12, 0.16), 0.8)
	var eye_mat = _get_mat("bat_eye", Color(1.0, 0.15, 0.20), 0.2, 0.0, Color(1.0, 0.15, 0.20), 3.0)

	var offsets = [Vector3(-0.35, 1.2, 0.1), Vector3(0.35, 1.45, -0.1), Vector3(0, 1.7, 0.25)]
	for i in range(offsets.size()):
		var bat = Node3D.new()
		bat.name = "Bat_" + str(i)
		bat.position = offsets[i]
		root.add_child(bat)

		# Bat Body
		var body = MeshInstance3D.new()
		body.name = "Body"
		var b_s = SphereMesh.new()
		b_s.radius = 0.10
		b_s.height = 0.22
		body.mesh = b_s
		body.material_override = bat_mat
		bat.add_child(body)

		# Wings
		var wing_l = MeshInstance3D.new()
		wing_l.name = "WingL"
		var w_box = BoxMesh.new()
		w_box.size = Vector3(0.35, 0.02, 0.20)
		wing_l.mesh = w_box
		wing_l.material_override = bat_mat
		wing_l.position = Vector3(-0.22, 0.02, 0)
		wing_l.rotation.z = deg_to_rad(-20.0)
		bat.add_child(wing_l)

		var wing_r = MeshInstance3D.new()
		wing_r.name = "WingR"
		wing_r.mesh = w_box
		wing_r.material_override = bat_mat
		wing_r.position = Vector3(0.22, 0.02, 0)
		wing_r.rotation.z = deg_to_rad(20.0)
		bat.add_child(wing_r)

		# Red Eyes
		for x in [-0.04, 0.04]:
			var eye = MeshInstance3D.new()
			var e_box = BoxMesh.new()
			e_box.size = Vector3(0.02, 0.02, 0.02)
			eye.mesh = e_box
			eye.material_override = eye_mat
			eye.position = Vector3(x, 0.05, 0.11)
			bat.add_child(eye)

# -----------------------------------------------------------------------------
# 10. GOTHIC WEREWOLF
# -----------------------------------------------------------------------------
static func _build_werewolf(root: Node3D):
	root.scale = Vector3(1.25, 1.25, 1.25)
	var fur_mat = _get_mat("werewolf_fur", Color(0.22, 0.18, 0.16), 0.95)
	var claw_mat = _get_mat("werewolf_claw", Color(0.08, 0.08, 0.08), 0.3)
	var eye_mat = _get_mat("werewolf_eye", Color(1.0, 0.85, 0.15), 0.2, 0.0, Color(1.0, 0.85, 0.15), 2.5)

	# Muscular Broad Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.62, 0.72, 0.42)
	torso.mesh = t_box
	torso.material_override = fur_mat
	torso.position = Vector3(0, 1.15, 0)
	torso.rotation.x = 0.25 # Hunched beast posture
	root.add_child(torso)

	# Snouted Lupine Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.32, 0.32, 0.32)
	head.mesh = h_box
	head.material_override = fur_mat
	head.position = Vector3(0, 1.62, 0.24)
	root.add_child(head)

	var snout = MeshInstance3D.new()
	var sn_box = BoxMesh.new()
	sn_box.size = Vector3(0.20, 0.18, 0.30)
	snout.mesh = sn_box
	snout.material_override = fur_mat
	snout.position = Vector3(0, 1.56, 0.48)
	root.add_child(snout)

	# Wolf Ears
	for x in [-0.12, 0.12]:
		var ear = MeshInstance3D.new()
		var e_cyl = CylinderMesh.new()
		e_cyl.top_radius = 0.01
		e_cyl.bottom_radius = 0.06
		e_cyl.height = 0.18
		ear.mesh = e_cyl
		ear.material_override = fur_mat
		ear.position = Vector3(x, 1.84, 0.20)
		root.add_child(ear)

	# Glowing Amber Eyes
	for x in [-0.07, 0.07]:
		var eye = MeshInstance3D.new()
		var e_box = BoxMesh.new()
		e_box.size = Vector3(0.04, 0.03, 0.03)
		eye.mesh = e_box
		eye.material_override = eye_mat
		eye.position = Vector3(x, 1.66, 0.38)
		root.add_child(eye)

	# Heavy Claws on Arms
	var arm_l = MeshInstance3D.new()
	arm_l.name = "LeftArm"
	var a_box = BoxMesh.new()
	a_box.size = Vector3(0.18, 0.72, 0.20)
	arm_l.mesh = a_box
	arm_l.material_override = fur_mat
	arm_l.position = Vector3(-0.38, 1.05, 0.28)
	arm_l.rotation.x = deg_to_rad(35.0)
	root.add_child(arm_l)

	var claws_l = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.14, 0.12, 0.16)
	claws_l.mesh = c_box
	claws_l.material_override = claw_mat
	claws_l.position = Vector3(-0.38, 0.72, 0.50)
	root.add_child(claws_l)

	var arm_r = MeshInstance3D.new()
	arm_r.name = "RightArm"
	arm_r.mesh = a_box
	arm_r.material_override = fur_mat
	arm_r.position = Vector3(0.38, 1.05, 0.28)
	arm_r.rotation.x = deg_to_rad(35.0)
	root.add_child(arm_r)

	var claws_r = MeshInstance3D.new()
	claws_r.mesh = c_box
	claws_r.material_override = claw_mat
	claws_r.position = Vector3(0.38, 0.72, 0.50)
	root.add_child(claws_r)

	# Digitigrade Wolf Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_box = BoxMesh.new()
	l_box.size = Vector3(0.20, 0.85, 0.24)
	leg_l.mesh = l_box
	leg_l.material_override = fur_mat
	leg_l.position = Vector3(-0.20, 0.44, -0.05)
	leg_l.rotation.x = -0.15
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_box
	leg_r.material_override = fur_mat
	leg_r.position = Vector3(0.20, 0.44, -0.05)
	leg_r.rotation.x = -0.15
	root.add_child(leg_r)

	# Wolf Tail
	var tail = MeshInstance3D.new()
	tail.name = "Tail"
	var tl_cyl = CylinderMesh.new()
	tl_cyl.top_radius = 0.04
	tl_cyl.bottom_radius = 0.08
	tl_cyl.height = 0.65
	tail.mesh = tl_cyl
	tail.material_override = fur_mat
	tail.position = Vector3(0, 0.75, -0.42)
	tail.rotation.x = deg_to_rad(-45.0)
	root.add_child(tail)

# -----------------------------------------------------------------------------
# 11. DIRE WOLF
# -----------------------------------------------------------------------------
static func _build_dire_wolf(root: Node3D):
	root.scale = Vector3(1.15, 1.15, 1.15)
	var fur_mat = _get_mat("dire_fur", Color(0.16, 0.15, 0.18), 0.9)
	var eye_mat = _get_mat("dire_eye", Color(1.0, 0.15, 0.15), 0.2, 0.0, Color(1.0, 0.15, 0.15), 2.8)

	# Quadruped Horizontal Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.48, 0.45, 0.95)
	torso.mesh = t_box
	torso.material_override = fur_mat
	torso.position = Vector3(0, 0.65, 0)
	root.add_child(torso)

	# Wolf Head & Snout
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.28, 0.26, 0.35)
	head.mesh = h_box
	head.material_override = fur_mat
	head.position = Vector3(0, 0.82, 0.55)
	root.add_child(head)

	for x in [-0.07, 0.07]:
		var eye = MeshInstance3D.new()
		var e_box = BoxMesh.new()
		e_box.size = Vector3(0.04, 0.03, 0.03)
		eye.mesh = e_box
		eye.material_override = eye_mat
		eye.position = Vector3(x, 0.88, 0.68)
		root.add_child(eye)

	# 4 Sturdy Wolf Legs
	for z in [-0.30, 0.30]:
		for x in [-0.18, 0.18]:
			var leg = MeshInstance3D.new()
			var leg_tag = ("Leg_FL" if (x < 0 and z > 0) else ("Leg_FR" if (x > 0 and z > 0) else ("Leg_BL" if (x < 0 and z < 0) else "Leg_BR")))
			leg.name = leg_tag
			var l_cyl = CylinderMesh.new()
			l_cyl.top_radius = 0.07
			l_cyl.bottom_radius = 0.05
			l_cyl.height = 0.65
			leg.mesh = l_cyl
			leg.material_override = fur_mat
			leg.position = Vector3(x, 0.32, z)
			root.add_child(leg)

# -----------------------------------------------------------------------------
# 12. FIRE IMP
# -----------------------------------------------------------------------------
static func _build_fire_imp(root: Node3D):
	root.scale = Vector3(0.85, 0.85, 0.85)
	var imp_skin = _get_mat("imp_skin", Color(0.78, 0.14, 0.12), 0.6)
	var fire_mat = _get_mat("hellfire", Color(1.0, 0.35, 0.05), 0.2, 0.0, Color(1.0, 0.42, 0.05), 3.5)
	var horn_mat = _get_mat("demon_horns", Color(0.08, 0.07, 0.08), 0.5)

	# Flying Body
	var body = Node3D.new()
	body.name = "Body"
	body.position = Vector3(0, 1.15, 0)
	root.add_child(body)

	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.32, 0.38, 0.24)
	torso.mesh = t_box
	torso.material_override = imp_skin
	body.add_child(torso)

	# Head with Devil Horns
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_s = SphereMesh.new()
	h_s.radius = 0.14
	h_s.height = 0.26
	head.mesh = h_s
	head.material_override = imp_skin
	head.position = Vector3(0, 0.32, 0.05)
	body.add_child(head)

	for x in [-0.08, 0.08]:
		var horn = MeshInstance3D.new()
		var hn_cyl = CylinderMesh.new()
		hn_cyl.top_radius = 0.01
		hn_cyl.bottom_radius = 0.04
		hn_cyl.height = 0.16
		horn.mesh = hn_cyl
		horn.material_override = horn_mat
		horn.position = Vector3(x, 0.48, 0.04)
		body.add_child(horn)

	# Leathery Bat Wings
	var wing_l = MeshInstance3D.new()
	wing_l.name = "WingL"
	var w_box = BoxMesh.new()
	w_box.size = Vector3(0.42, 0.02, 0.24)
	wing_l.mesh = w_box
	wing_l.material_override = horn_mat
	wing_l.position = Vector3(-0.28, 0.12, -0.12)
	wing_l.rotation.z = deg_to_rad(-30.0)
	body.add_child(wing_l)

	var wing_r = MeshInstance3D.new()
	wing_r.name = "WingR"
	wing_r.mesh = w_box
	wing_r.material_override = horn_mat
	wing_r.position = Vector3(0.28, 0.12, -0.12)
	wing_r.rotation.z = deg_to_rad(30.0)
	body.add_child(wing_r)

	# Flaming Fireball in Hand
	var fireball = MeshInstance3D.new()
	fireball.name = "Fireball"
	var fb_s = SphereMesh.new()
	fb_s.radius = 0.12
	fb_s.height = 0.24
	fireball.mesh = fb_s
	fireball.material_override = fire_mat
	fireball.position = Vector3(0.24, 0.05, 0.25)
	body.add_child(fireball)

# -----------------------------------------------------------------------------
# 13. HORNED DEMON
# -----------------------------------------------------------------------------
static func _build_horned_demon(root: Node3D):
	root.scale = Vector3(1.35, 1.35, 1.35)
	var demon_skin = _get_mat("demon_flesh", Color(0.68, 0.12, 0.14), 0.7)
	var horn_mat = _get_mat("demon_horns", Color(0.08, 0.07, 0.08), 0.5)
	var steel_mat = _get_mat("vamp_steel", Color(0.45, 0.45, 0.48), 0.4, 0.8)

	# Muscular Crimson Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.65, 0.75, 0.42)
	torso.mesh = t_box
	torso.material_override = demon_skin
	torso.position = Vector3(0, 1.25, 0)
	root.add_child(torso)

	# Head with Massive Ram Horns
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_s = SphereMesh.new()
	h_s.radius = 0.20
	h_s.height = 0.38
	head.mesh = h_s
	head.material_override = demon_skin
	head.position = Vector3(0, 1.82, 0.08)
	root.add_child(head)

	for x in [-0.24, 0.24]:
		var horn = MeshInstance3D.new()
		var hn_cyl = CylinderMesh.new()
		hn_cyl.top_radius = 0.02
		hn_cyl.bottom_radius = 0.09
		hn_cyl.height = 0.65
		horn.mesh = hn_cyl
		horn.material_override = horn_mat
		horn.rotation.z = deg_to_rad(-60.0 if x > 0 else 60.0)
		horn.position = Vector3(x, 2.05, 0)
		root.add_child(horn)

	# Hoofed Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.14
	l_cyl.bottom_radius = 0.09
	l_cyl.height = 0.95
	leg_l.mesh = l_cyl
	leg_l.material_override = demon_skin
	leg_l.position = Vector3(-0.22, 0.48, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = demon_skin
	leg_r.position = Vector3(0.22, 0.48, 0)
	root.add_child(leg_r)

	# Spiked Hell Cleaver
	var cleaver = MeshInstance3D.new()
	cleaver.name = "Weapon"
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.24, 1.15, 0.06)
	cleaver.mesh = c_box
	cleaver.material_override = steel_mat
	cleaver.rotation.x = deg_to_rad(45.0)
	cleaver.position = Vector3(0.48, 1.15, 0.38)
	root.add_child(cleaver)

# -----------------------------------------------------------------------------
# 14. HELLHOUND
# -----------------------------------------------------------------------------
static func _build_hellhound(root: Node3D):
	root.scale = Vector3(1.1, 1.1, 1.1)
	var hound_skin = _get_mat("hound_skin", Color(0.14, 0.12, 0.14), 0.8)
	var fire_mat = _get_mat("hellfire", Color(1.0, 0.35, 0.05), 0.2, 0.0, Color(1.0, 0.42, 0.05), 3.5)

	# Hound Body
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.44, 0.42, 0.88)
	torso.mesh = t_box
	torso.material_override = hound_skin
	torso.position = Vector3(0, 0.62, 0)
	root.add_child(torso)

	# Fiery Molten Spine Crest
	var crest = MeshInstance3D.new()
	crest.name = "Crest"
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.06, 0.14, 0.72)
	crest.mesh = c_box
	crest.material_override = fire_mat
	crest.position = Vector3(0, 0.88, 0)
	root.add_child(crest)

	# Snouted Head with Flaming Eyes
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.26, 0.24, 0.32)
	head.mesh = h_box
	head.material_override = hound_skin
	head.position = Vector3(0, 0.78, 0.52)
	root.add_child(head)

	for x in [-0.07, 0.07]:
		var eye = MeshInstance3D.new()
		var e_box = BoxMesh.new()
		e_box.size = Vector3(0.04, 0.03, 0.03)
		eye.mesh = e_box
		eye.material_override = fire_mat
		eye.position = Vector3(x, 0.84, 0.66)
		root.add_child(eye)

	# 4 Sturdy Hound Legs
	for z in [-0.28, 0.28]:
		for x in [-0.16, 0.16]:
			var leg = MeshInstance3D.new()
			var leg_tag = ("Leg_FL" if (x < 0 and z > 0) else ("Leg_FR" if (x > 0 and z > 0) else ("Leg_BL" if (x < 0 and z < 0) else "Leg_BR")))
			leg.name = leg_tag
			var l_cyl = CylinderMesh.new()
			l_cyl.top_radius = 0.06
			l_cyl.bottom_radius = 0.05
			l_cyl.height = 0.62
			leg.mesh = l_cyl
			leg.material_override = hound_skin
			leg.position = Vector3(x, 0.31, z)
			root.add_child(leg)

# -----------------------------------------------------------------------------
# 15. JACK-O'-LANTERN FIEND
# -----------------------------------------------------------------------------
static func _build_jack_o_lantern(root: Node3D):
	root.scale = Vector3(0.95, 0.95, 0.95)
	var pump_mat = _get_mat("jack_pumpkin", Color(0.95, 0.44, 0.04), 0.6)
	var vine_mat = _get_mat("jack_vine", Color(0.24, 0.18, 0.12), 0.9)
	var glow_mat = _get_mat("jack_glow", Color(1.0, 0.85, 0.15), 0.2, 0.0, Color(1.0, 0.75, 0.08), 4.2)

	# Knotted Vine Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.16
	t_cyl.bottom_radius = 0.12
	t_cyl.height = 0.48
	torso.mesh = t_cyl
	torso.material_override = vine_mat
	torso.position = Vector3(0, 0.58, 0)
	root.add_child(torso)

	# Carved Pumpkin Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var p_sphere = SphereMesh.new()
	p_sphere.radius = 0.32
	p_sphere.height = 0.55
	head.mesh = p_sphere
	head.material_override = pump_mat
	head.position = Vector3(0, 1.05, 0)
	root.add_child(head)

	# Pumpkin Stem
	var stem = MeshInstance3D.new()
	var st_cyl = CylinderMesh.new()
	st_cyl.top_radius = 0.03
	st_cyl.bottom_radius = 0.04
	st_cyl.height = 0.18
	stem.mesh = st_cyl
	stem.material_override = vine_mat
	stem.position = Vector3(0, 1.38, 0)
	stem.rotation.z = 0.2
	root.add_child(stem)

	# Glowing Triangular Eyes
	for x in [-0.10, 0.10]:
		var eye = MeshInstance3D.new()
		var e_box = BoxMesh.new()
		e_box.size = Vector3(0.07, 0.07, 0.04)
		eye.mesh = e_box
		eye.material_override = glow_mat
		eye.position = Vector3(x, 1.10, 0.28)
		root.add_child(eye)

	# Jagged Carved Grin
	var mouth = MeshInstance3D.new()
	mouth.name = "Mouth"
	var m_box = BoxMesh.new()
	m_box.size = Vector3(0.24, 0.06, 0.04)
	mouth.mesh = m_box
	mouth.material_override = glow_mat
	mouth.position = Vector3(0, 0.96, 0.27)
	root.add_child(mouth)

	# Vine Root Limbs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.045
	l_cyl.bottom_radius = 0.035
	l_cyl.height = 0.55
	leg_l.mesh = l_cyl
	leg_l.material_override = vine_mat
	leg_l.position = Vector3(-0.12, 0.27, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = vine_mat
	leg_r.position = Vector3(0.12, 0.27, 0)
	root.add_child(leg_r)

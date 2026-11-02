extends RefCounted
class_name WinterModelBuilder

# =============================================================================
# THE WINTER COURT — PROCEDURAL 3D ANATOMY & MODEL BUILDER
# =============================================================================
# High-fidelity procedural models for all 15 units of The Winter Court:
# Holiday commanders (Yuletide King, Krampus, Frost Queen), clockwork toys,
# arctic beasts (War Reindeer, Yeti, Frost Wolf), elves, witches, and siege sleds.

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

	if pivot is MeshInstance3D:
		pivot.mesh = null
	for child in pivot.get_children():
		if child.name == "WinterRigRoot":
			child.queue_free()
		elif child.name == "ShieldVisualRoot" or child.name == "ArmorPlatesRoot":
			continue
		else:
			child.visible = false

	var root = Node3D.new()
	root.name = "WinterRigRoot"
	pivot.add_child(root)

	if "YuletideKing" in unit_name:
		_build_yuletide_king(root)
	elif "KrampusLord" in unit_name:
		_build_krampus_lord(root)
	elif "FrostQueen" in unit_name:
		_build_frost_queen(root)
	elif "ToySoldier" in unit_name:
		_build_toy_soldier(root)
	elif "Nutcracker" in unit_name:
		_build_nutcracker(root)
	elif "ToyGolem" in unit_name:
		_build_toy_golem(root)
	elif "GingerbreadBrawler" in unit_name:
		_build_gingerbread_brawler(root)
	elif "WarReindeer" in unit_name:
		_build_war_reindeer(root)
	elif "AbominableYeti" in unit_name:
		_build_abominable_yeti(root)
	elif "FrostWolf" in unit_name:
		_build_frost_wolf(root)
	elif "SnowSprite" in unit_name:
		_build_snow_sprite(root)
	elif "FrostElf" in unit_name:
		_build_frost_elf(root)
	elif "BlizzardWitch" in unit_name:
		_build_blizzard_witch(root)
	elif "SnowballCatapult" in unit_name:
		_build_snowball_catapult(root)
	elif "YuleLog" in unit_name:
		_build_yule_log(root)

	return root

# -----------------------------------------------------------------------------
# 1. YULETIDE KING (COMMANDER)
# -----------------------------------------------------------------------------
static func _build_yuletide_king(root: Node3D):
	var red_mat = _get_mat("w_red", Color(0.85, 0.12, 0.15), 0.6)
	var fur_mat = _get_mat("w_fur", Color(0.96, 0.96, 0.96), 0.9)
	var skin_mat = _get_mat("w_skin", Color(0.95, 0.78, 0.68), 0.7)
	var gold_mat = _get_mat("w_gold", Color(1.0, 0.85, 0.2), 0.3, 0.8)
	var boot_mat = _get_mat("w_boot", Color(0.12, 0.10, 0.10), 0.5)

	# Robe / Torso
	var robe = MeshInstance3D.new()
	robe.name = "Torso"
	var r_mesh = CylinderMesh.new()
	r_mesh.top_radius = 0.55
	r_mesh.bottom_radius = 0.85
	r_mesh.height = 1.6
	robe.mesh = r_mesh
	robe.material_override = red_mat
	robe.position.y = 1.0
	root.add_child(robe)

	# Fur Trim along bottom
	var fur_trim = MeshInstance3D.new()
	var ft_mesh = TorusMesh.new()
	ft_mesh.inner_radius = 0.75
	ft_mesh.outer_radius = 0.95
	fur_trim.mesh = ft_mesh
	fur_trim.material_override = fur_mat
	fur_trim.position.y = 0.25
	root.add_child(fur_trim)

	# Gold Belt
	var belt = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.62
	b_mesh.bottom_radius = 0.64
	b_mesh.height = 0.22
	belt.mesh = b_mesh
	belt.material_override = boot_mat
	belt.position.y = 1.05
	root.add_child(belt)

	var buckle = MeshInstance3D.new()
	var bu_mesh = BoxMesh.new()
	bu_mesh.size = Vector3(0.35, 0.28, 0.15)
	buckle.mesh = bu_mesh
	buckle.material_override = gold_mat
	buckle.position = Vector3(0, 1.05, 0.62)
	root.add_child(buckle)

	# Head & Beard
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_mesh = SphereMesh.new()
	h_mesh.radius = 0.32
	h_mesh.height = 0.60
	head.mesh = h_mesh
	head.material_override = skin_mat
	head.position = Vector3(0, 1.95, 0)
	root.add_child(head)

	# Majestic White Beard
	var beard = MeshInstance3D.new()
	beard.name = "Beard"
	var bd_mesh = CylinderMesh.new()
	bd_mesh.top_radius = 0.32
	bd_mesh.bottom_radius = 0.08
	bd_mesh.height = 0.75
	beard.mesh = bd_mesh
	beard.material_override = fur_mat
	beard.position = Vector3(0, 1.65, 0.24)
	beard.rotation_degrees.x = 20
	root.add_child(beard)

	# Santa Cap
	var cap = MeshInstance3D.new()
	var c_mesh = CylinderMesh.new()
	c_mesh.top_radius = 0.05
	c_mesh.bottom_radius = 0.36
	c_mesh.height = 0.65
	cap.mesh = c_mesh
	cap.material_override = red_mat
	cap.position = Vector3(0, 2.30, -0.08)
	cap.rotation_degrees.x = -25
	root.add_child(cap)

	var cap_rim = MeshInstance3D.new()
	var cr_mesh = TorusMesh.new()
	cr_mesh.inner_radius = 0.28
	cr_mesh.outer_radius = 0.40
	cap_rim.mesh = cr_mesh
	cap_rim.material_override = fur_mat
	cap_rim.position = Vector3(0, 2.15, 0)
	root.add_child(cap_rim)

	var pompom = MeshInstance3D.new()
	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.14
	pompom.mesh = p_mesh
	pompom.material_override = fur_mat
	pompom.position = Vector3(0, 2.35, -0.40)
	root.add_child(pompom)

	# Candy Cane War Scepter
	var scepter = MeshInstance3D.new()
	scepter.name = "Weapon"
	var sc_mesh = CylinderMesh.new()
	sc_mesh.top_radius = 0.06
	sc_mesh.bottom_radius = 0.06
	sc_mesh.height = 1.9
	scepter.mesh = sc_mesh
	scepter.material_override = fur_mat
	scepter.position = Vector3(0.65, 1.1, 0.4)
	scepter.rotation_degrees = Vector3(10, 0, -15)
	root.add_child(scepter)

	var hook = MeshInstance3D.new()
	hook.name = "WeaponHook"
	var hk_mesh = TorusMesh.new()
	hk_mesh.inner_radius = 0.12
	hk_mesh.outer_radius = 0.28
	hook.mesh = hk_mesh
	hook.material_override = red_mat
	hook.position = Vector3(0.65, 2.05, 0.4)
	hook.rotation_degrees.x = 90
	root.add_child(hook)

# -----------------------------------------------------------------------------
# 2. KRAMPUS LORD (COMMANDER)
# -----------------------------------------------------------------------------
static func _build_krampus_lord(root: Node3D):
	var dark_mat = _get_mat("w_kramp_fur", Color(0.12, 0.09, 0.08), 0.9)
	var horn_mat = _get_mat("w_horn", Color(0.18, 0.16, 0.18), 0.4, 0.2)
	var iron_mat = _get_mat("w_iron", Color(0.4, 0.42, 0.45), 0.3, 0.8)
	var red_eye = _get_mat("w_red_glow", Color(1.0, 0.1, 0.1), 0.2, 0.0, Color(1.0, 0.1, 0.1), 3.5)
	var birch_mat = _get_mat("w_birch", Color(0.65, 0.55, 0.38), 0.8)

	# Muscular Beast Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(0.9, 1.2, 0.6)
	torso.mesh = t_mesh
	torso.material_override = dark_mat
	torso.position.y = 1.3
	root.add_child(torso)

	# Legs & Hooves
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_mesh = CylinderMesh.new()
	l_mesh.top_radius = 0.18
	l_mesh.bottom_radius = 0.14
	l_mesh.height = 1.0
	leg_l.mesh = l_mesh
	leg_l.material_override = dark_mat
	leg_l.position = Vector3(-0.3, 0.5, 0)
	root.add_child(leg_l)

	var hoof_l = MeshInstance3D.new()
	var hf_mesh = CylinderMesh.new()
	hf_mesh.top_radius = 0.15
	hf_mesh.bottom_radius = 0.20
	hf_mesh.height = 0.25
	hoof_l.mesh = hf_mesh
	hoof_l.material_override = horn_mat
	hoof_l.position = Vector3(-0.3, 0.12, 0.05)
	root.add_child(hoof_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_mesh
	leg_r.material_override = dark_mat
	leg_r.position = Vector3(0.3, 0.5, 0)
	root.add_child(leg_r)

	var hoof_r = MeshInstance3D.new()
	hoof_r.mesh = hf_mesh
	hoof_r.material_override = horn_mat
	hoof_r.position = Vector3(0.3, 0.12, 0.05)
	root.add_child(hoof_r)

	# Head with Goat Snout
	var head = MeshInstance3D.new()
	head.name = "Head"
	var hd_mesh = BoxMesh.new()
	hd_mesh.size = Vector3(0.5, 0.55, 0.65)
	head.mesh = hd_mesh
	head.material_override = dark_mat
	head.position = Vector3(0, 2.1, 0.1)
	root.add_child(head)

	# Glowing Red Eyes
	for s in [-1.0, 1.0]:
		var eye = MeshInstance3D.new()
		var e_mesh = SphereMesh.new()
		e_mesh.radius = 0.07
		eye.mesh = e_mesh
		eye.material_override = red_eye
		eye.position = Vector3(s * 0.18, 2.18, 0.42)
		root.add_child(eye)

	# Long Recurving Ram Horns
	for s in [-1.0, 1.0]:
		var horn = MeshInstance3D.new()
		var hn_mesh = CylinderMesh.new()
		hn_mesh.top_radius = 0.04
		hn_mesh.bottom_radius = 0.14
		hn_mesh.height = 0.95
		horn.mesh = hn_mesh
		horn.material_override = horn_mat
		horn.position = Vector3(s * 0.28, 2.55, -0.1)
		horn.rotation_degrees = Vector3(-35, 0, s * 40)
		root.add_child(horn)

	# Clanking Iron Chains coiled around chest
	var chain = MeshInstance3D.new()
	chain.name = "Chain"
	var ch_mesh = TorusMesh.new()
	ch_mesh.inner_radius = 0.42
	ch_mesh.outer_radius = 0.52
	chain.mesh = ch_mesh
	chain.material_override = iron_mat
	chain.position.y = 1.35
	chain.rotation_degrees = Vector3(25, 15, 0)
	root.add_child(chain)

	# Bundle of Birch Switches (Weapon)
	var birch_bundle = MeshInstance3D.new()
	birch_bundle.name = "Weapon"
	var bb_mesh = CylinderMesh.new()
	bb_mesh.top_radius = 0.15
	bb_mesh.bottom_radius = 0.08
	bb_mesh.height = 1.4
	birch_bundle.mesh = bb_mesh
	birch_bundle.material_override = birch_mat
	birch_bundle.position = Vector3(0.65, 1.2, 0.3)
	birch_bundle.rotation_degrees = Vector3(15, 0, -25)
	root.add_child(birch_bundle)

	# Wicker Basket on back
	var basket = MeshInstance3D.new()
	var bk_mesh = BoxMesh.new()
	bk_mesh.size = Vector3(0.7, 0.9, 0.45)
	basket.mesh = bk_mesh
	basket.material_override = birch_mat
	basket.position = Vector3(0, 1.45, -0.45)
	root.add_child(basket)

# -----------------------------------------------------------------------------
# 3. FROST QUEEN (COMMANDER)
# -----------------------------------------------------------------------------
static func _build_frost_queen(root: Node3D):
	var ice_mat = _get_mat("w_ice_blue", Color(0.4, 0.85, 1.0, 0.85), 0.2, 0.1, Color(0.3, 0.8, 1.0), 1.5)
	var gown_mat = _get_mat("w_gown_blue", Color(0.12, 0.28, 0.55), 0.5)
	var skin_mat = _get_mat("w_pale_skin", Color(0.85, 0.92, 0.98), 0.4)
	var crown_mat = _get_mat("w_ice_crystal", Color(0.8, 0.95, 1.0), 0.1, 0.4, Color(0.6, 0.95, 1.0), 3.0)

	# Flowing Ice Gown
	var gown = MeshInstance3D.new()
	gown.name = "Torso"
	var g_mesh = CylinderMesh.new()
	g_mesh.top_radius = 0.35
	g_mesh.bottom_radius = 0.85
	g_mesh.height = 1.7
	gown.mesh = g_mesh
	gown.material_override = gown_mat
	gown.position.y = 0.85
	root.add_child(gown)

	# Glacial Ice Crystal Trim
	var trim = MeshInstance3D.new()
	var t_mesh = TorusMesh.new()
	t_mesh.inner_radius = 0.75
	t_mesh.outer_radius = 0.92
	trim.mesh = t_mesh
	trim.material_override = ice_mat
	trim.position.y = 0.15
	root.add_child(trim)

	# Torso & Shoulders
	var torso = MeshInstance3D.new()
	var ts_mesh = CylinderMesh.new()
	ts_mesh.top_radius = 0.30
	ts_mesh.bottom_radius = 0.32
	ts_mesh.height = 0.6
	torso.mesh = ts_mesh
	torso.material_override = gown_mat
	torso.position.y = 1.75
	root.add_child(torso)

	# Pale Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var hd_mesh = SphereMesh.new()
	hd_mesh.radius = 0.25
	hd_mesh.height = 0.50
	head.mesh = hd_mesh
	head.material_override = skin_mat
	head.position.y = 2.2
	root.add_child(head)

	# Spiked Crystalline Ice Crown
	for i in range(5):
		var ang = (float(i) / 5.0) * PI - (PI * 0.5)
		var spike = MeshInstance3D.new()
		var sp_mesh = CylinderMesh.new()
		sp_mesh.top_radius = 0.02
		sp_mesh.bottom_radius = 0.06
		sp_mesh.height = 0.45 + (0.2 if i == 2 else 0.0)
		spike.mesh = sp_mesh
		spike.material_override = crown_mat
		spike.position = Vector3(sin(ang) * 0.24, 2.55, cos(ang) * 0.24)
		root.add_child(spike)

	# Glacial Ice Lance / Scepter
	var scepter = MeshInstance3D.new()
	scepter.name = "Weapon"
	var sc_mesh = CylinderMesh.new()
	sc_mesh.top_radius = 0.05
	sc_mesh.bottom_radius = 0.05
	sc_mesh.height = 2.1
	scepter.mesh = sc_mesh
	scepter.material_override = crown_mat
	scepter.position = Vector3(0.55, 1.25, 0.3)
	root.add_child(scepter)

	# Floating Diamond Crystal at Scepter Tip
	var dia = MeshInstance3D.new()
	dia.name = "IceOrb"
	var d_mesh = SphereMesh.new()
	d_mesh.radius = 0.22
	d_mesh.height = 0.44
	dia.mesh = d_mesh
	dia.material_override = crown_mat
	dia.position = Vector3(0.55, 2.35, 0.3)
	dia.rotation_degrees = Vector3(45, 45, 0)
	root.add_child(dia)

# -----------------------------------------------------------------------------
# 4. TOY SOLDIER
# -----------------------------------------------------------------------------
static func _build_toy_soldier(root: Node3D):
	var red_mat = _get_mat("w_soldier_red", Color(0.85, 0.15, 0.15), 0.5)
	var blue_mat = _get_mat("w_soldier_blue", Color(0.12, 0.20, 0.45), 0.5)
	var white_mat = _get_mat("w_soldier_white", Color(0.95, 0.95, 0.95), 0.6)
	var brass_mat = _get_mat("w_brass", Color(0.85, 0.70, 0.20), 0.3, 0.8)
	var black_mat = _get_mat("w_black_tin", Color(0.12, 0.12, 0.12), 0.4)

	# Tin Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 0.30
	t_mesh.bottom_radius = 0.32
	t_mesh.height = 0.75
	torso.mesh = t_mesh
	torso.material_override = red_mat
	torso.position.y = 1.0
	root.add_child(torso)

	# White Cross Straps
	var strap = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(0.55, 0.65, 0.05)
	strap.mesh = s_mesh
	strap.material_override = white_mat
	strap.position = Vector3(0, 1.0, 0.30)
	root.add_child(strap)

	# Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_mesh = CylinderMesh.new()
	l_mesh.top_radius = 0.12
	l_mesh.bottom_radius = 0.10
	l_mesh.height = 0.75
	leg_l.mesh = l_mesh
	leg_l.material_override = white_mat
	leg_l.position = Vector3(-0.18, 0.45, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_mesh
	leg_r.material_override = white_mat
	leg_r.position = Vector3(0.18, 0.45, 0)
	root.add_child(leg_r)

	# Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var h_mesh = SphereMesh.new()
	h_mesh.radius = 0.22
	head.mesh = h_mesh
	head.material_override = _get_mat("w_skin", Color(0.95, 0.80, 0.70))
	head.position.y = 1.55
	root.add_child(head)

	# Tall Shako Hat
	var shako = MeshInstance3D.new()
	var sh_mesh = CylinderMesh.new()
	sh_mesh.top_radius = 0.24
	sh_mesh.bottom_radius = 0.24
	sh_mesh.height = 0.55
	shako.mesh = sh_mesh
	shako.material_override = black_mat
	shako.position.y = 1.95
	root.add_child(shako)

	# Spinning Brass Wind-up Key on back
	var key_stem = MeshInstance3D.new()
	var ks_mesh = CylinderMesh.new()
	ks_mesh.top_radius = 0.04
	ks_mesh.bottom_radius = 0.04
	ks_mesh.height = 0.25
	key_stem.mesh = ks_mesh
	key_stem.material_override = brass_mat
	key_stem.rotation_degrees.x = 90
	key_stem.position = Vector3(0, 1.0, -0.42)
	root.add_child(key_stem)

	var key_wing = MeshInstance3D.new()
	key_wing.name = "WindupKey"
	var kw_mesh = BoxMesh.new()
	kw_mesh.size = Vector3(0.45, 0.25, 0.04)
	key_wing.mesh = kw_mesh
	key_wing.material_override = brass_mat
	key_wing.position = Vector3(0, 1.0, -0.55)
	root.add_child(key_wing)

	# Miniature Musket with Bayonet
	var gun = MeshInstance3D.new()
	gun.name = "Weapon"
	var g_mesh = CylinderMesh.new()
	g_mesh.top_radius = 0.03
	g_mesh.bottom_radius = 0.04
	g_mesh.height = 1.3
	gun.mesh = g_mesh
	gun.material_override = black_mat
	gun.position = Vector3(0.35, 1.0, 0.35)
	gun.rotation_degrees.x = 25
	root.add_child(gun)

# -----------------------------------------------------------------------------
# 5. NUTCRACKER (HEAVY MELEE)
# -----------------------------------------------------------------------------
static func _build_nutcracker(root: Node3D):
	var wood_mat = _get_mat("w_nut_wood", Color(0.35, 0.22, 0.12), 0.7)
	var blue_mat = _get_mat("w_nut_blue", Color(0.12, 0.22, 0.52), 0.5)
	var gold_mat = _get_mat("w_gold", Color(1.0, 0.85, 0.2), 0.3, 0.8)
	var white_mat = _get_mat("w_white", Color(0.95, 0.95, 0.95), 0.6)

	# Heavy Carved Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(0.75, 1.0, 0.5)
	torso.mesh = t_mesh
	torso.material_override = blue_mat
	torso.position.y = 1.15
	root.add_child(torso)

	# Stiff Wooden Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.12
	l_cyl.bottom_radius = 0.10
	l_cyl.height = 0.75
	leg_l.mesh = l_cyl
	leg_l.material_override = wood_mat
	leg_l.position = Vector3(-0.20, 0.45, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = wood_mat
	leg_r.position = Vector3(0.20, 0.45, 0)
	root.add_child(leg_r)

	# Gold Shoulder Epaulets
	for s in [-1.0, 1.0]:
		var ep = MeshInstance3D.new()
		var ep_mesh = CylinderMesh.new()
		ep_mesh.top_radius = 0.18
		ep_mesh.bottom_radius = 0.18
		ep_mesh.height = 0.10
		ep.mesh = ep_mesh
		ep.material_override = gold_mat
		ep.position = Vector3(s * 0.45, 1.62, 0)
		root.add_child(ep)

	# Head with Distinct Chomping Jaws
	var head = MeshInstance3D.new()
	head.name = "Head"
	var hd_mesh = BoxMesh.new()
	hd_mesh.size = Vector3(0.55, 0.55, 0.5)
	head.mesh = hd_mesh
	head.material_override = _get_mat("w_skin", Color(0.95, 0.82, 0.72))
	head.position.y = 1.85
	root.add_child(head)

	# Square Wooden Chomping Teeth / Jaw
	var teeth = MeshInstance3D.new()
	teeth.name = "Jaw"
	var tt_mesh = BoxMesh.new()
	tt_mesh.size = Vector3(0.30, 0.16, 0.12)
	teeth.mesh = tt_mesh
	teeth.material_override = white_mat
	teeth.position = Vector3(0, 1.70, 0.26)
	root.add_child(teeth)

	# Crown Hat
	var hat = MeshInstance3D.new()
	var ht_mesh = CylinderMesh.new()
	ht_mesh.top_radius = 0.32
	ht_mesh.bottom_radius = 0.30
	ht_mesh.height = 0.6
	hat.mesh = ht_mesh
	hat.material_override = gold_mat
	hat.position.y = 2.35
	root.add_child(hat)

	# Ceremonial Golden Halberd
	var halberd = MeshInstance3D.new()
	halberd.name = "Weapon"
	var hb_mesh = CylinderMesh.new()
	hb_mesh.top_radius = 0.04
	hb_mesh.bottom_radius = 0.04
	hb_mesh.height = 2.4
	halberd.mesh = hb_mesh
	halberd.material_override = wood_mat
	halberd.position = Vector3(0.55, 1.2, 0.2)
	root.add_child(halberd)

	var blade = MeshInstance3D.new()
	blade.name = "WeaponBlade"
	var bl_mesh = BoxMesh.new()
	bl_mesh.size = Vector3(0.55, 0.6, 0.06)
	blade.mesh = bl_mesh
	blade.material_override = gold_mat
	blade.position = Vector3(0.55, 2.2, 0.35)
	root.add_child(blade)

# -----------------------------------------------------------------------------
# 6. TOY GOLEM (AUTOMATON)
# -----------------------------------------------------------------------------
static func _build_toy_golem(root: Node3D):
	var wood_mat = _get_mat("w_golem_wood", Color(0.40, 0.28, 0.16), 0.8)
	var brass_mat = _get_mat("w_golem_brass", Color(0.85, 0.68, 0.25), 0.3, 0.8)
	var fire_mat = _get_mat("w_furnace_fire", Color(1.0, 0.5, 0.1), 0.2, 0.0, Color(1.0, 0.4, 0.0), 3.5)

	# Chunky Barrel Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 0.7
	t_mesh.bottom_radius = 0.85
	t_mesh.height = 1.4
	torso.mesh = t_mesh
	torso.material_override = wood_mat
	torso.position.y = 1.3
	root.add_child(torso)

	# Sturdy Piston Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_mesh = CylinderMesh.new()
	l_mesh.top_radius = 0.22
	l_mesh.bottom_radius = 0.26
	l_mesh.height = 0.75
	leg_l.mesh = l_mesh
	leg_l.material_override = wood_mat
	leg_l.position = Vector3(-0.45, 0.45, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_mesh
	leg_r.material_override = wood_mat
	leg_r.position = Vector3(0.45, 0.45, 0)
	root.add_child(leg_r)

	# Iron/Brass Furnace Grate with Glowing Fire
	var furnace = MeshInstance3D.new()
	var fn_mesh = BoxMesh.new()
	fn_mesh.size = Vector3(0.65, 0.55, 0.2)
	furnace.mesh = fn_mesh
	furnace.material_override = fire_mat
	furnace.position = Vector3(0, 1.25, 0.75)
	root.add_child(furnace)

	# Rotating Cog Gear on Chest/Shoulder
	var gear = MeshInstance3D.new()
	gear.name = "WindupKey"
	var gr_mesh = CylinderMesh.new()
	gr_mesh.top_radius = 0.32
	gr_mesh.bottom_radius = 0.32
	gr_mesh.height = 0.12
	gear.mesh = gr_mesh
	gear.material_override = brass_mat
	gear.position = Vector3(0, 1.85, 0.68)
	gear.rotation_degrees.x = 90
	root.add_child(gear)

	# Heavy Wood and Riveted Brass Punching Fists
	var fist_l = MeshInstance3D.new()
	fist_l.name = "LeftArm"
	var ft_mesh = BoxMesh.new()
	ft_mesh.size = Vector3(0.55, 0.55, 0.75)
	fist_l.mesh = ft_mesh
	fist_l.material_override = brass_mat
	fist_l.position = Vector3(-1.05, 0.9, 0.4)
	root.add_child(fist_l)

	var fist_r = MeshInstance3D.new()
	fist_r.name = "RightArm"
	fist_r.mesh = ft_mesh
	fist_r.material_override = brass_mat
	fist_r.position = Vector3(1.05, 0.9, 0.4)
	root.add_child(fist_r)

# -----------------------------------------------------------------------------
# 7. GINGERBREAD BRAWLER
# -----------------------------------------------------------------------------
static func _build_gingerbread_brawler(root: Node3D):
	var ginger_mat = _get_mat("w_ginger", Color(0.72, 0.48, 0.28), 0.9)
	var icing_mat = _get_mat("w_icing", Color(0.98, 0.98, 0.98), 0.5)
	var gumdrop_mat = _get_mat("w_gumdrop", Color(0.9, 0.1, 0.2), 0.3)
	var pepperm_mat = _get_mat("w_peppermint", Color(1.0, 0.2, 0.3), 0.4)

	# Cookie Body
	var body = MeshInstance3D.new()
	body.name = "Torso"
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.65, 0.85, 0.22)
	body.mesh = b_mesh
	body.material_override = ginger_mat
	body.position.y = 0.95
	root.add_child(body)

	# Sturdy Cookie Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.08
	l_cyl.bottom_radius = 0.07
	l_cyl.height = 0.55
	leg_l.mesh = l_cyl
	leg_l.material_override = ginger_mat
	leg_l.position = Vector3(-0.18, 0.32, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = ginger_mat
	leg_r.position = Vector3(0.18, 0.32, 0)
	root.add_child(leg_r)

	# Round Cookie Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var hd_mesh = CylinderMesh.new()
	hd_mesh.top_radius = 0.28
	hd_mesh.bottom_radius = 0.28
	hd_mesh.height = 0.22
	head.mesh = hd_mesh
	head.material_override = ginger_mat
	head.rotation_degrees.x = 90
	head.position.y = 1.6
	root.add_child(head)

	# White Icing Border Piping
	for s in [-1.0, 1.0]:
		var piping = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 0.03
		p_mesh.bottom_radius = 0.03
		p_mesh.height = 0.75
		piping.mesh = p_mesh
		piping.material_override = icing_mat
		piping.position = Vector3(s * 0.30, 0.95, 0.12)
		root.add_child(piping)

	# Gumdrop Buttons
	for i in range(2):
		var btn = MeshInstance3D.new()
		var bt_mesh = SphereMesh.new()
		bt_mesh.radius = 0.08
		btn.mesh = bt_mesh
		btn.material_override = gumdrop_mat
		btn.position = Vector3(0, 0.85 + i * 0.25, 0.13)
		root.add_child(btn)

	# Peppermint Swirl Buckler Shield
	var shield = MeshInstance3D.new()
	shield.name = "Shield"
	var sh_mesh = CylinderMesh.new()
	sh_mesh.top_radius = 0.35
	sh_mesh.bottom_radius = 0.35
	sh_mesh.height = 0.08
	shield.mesh = sh_mesh
	shield.material_override = pepperm_mat
	shield.position = Vector3(-0.45, 0.95, 0.3)
	shield.rotation_degrees.x = 90
	root.add_child(shield)

	# Candy Cane Cudgel (Weapon)
	var cudgel = MeshInstance3D.new()
	cudgel.name = "Weapon"
	var cd_mesh = CylinderMesh.new()
	cd_mesh.top_radius = 0.05
	cd_mesh.bottom_radius = 0.06
	cd_mesh.height = 0.85
	cudgel.mesh = cd_mesh
	cudgel.material_override = pepperm_mat
	cudgel.position = Vector3(0.42, 0.95, 0.3)
	cudgel.rotation_degrees.x = 45
	root.add_child(cudgel)

# -----------------------------------------------------------------------------
# 8. WAR REINDEER (CAVALRY)
# -----------------------------------------------------------------------------
static func _build_war_reindeer(root: Node3D):
	var hide_mat = _get_mat("w_rein_fur", Color(0.42, 0.28, 0.18), 0.85)
	var mane_mat = _get_mat("w_rein_mane", Color(0.92, 0.92, 0.90), 0.9)
	var antler_mat = _get_mat("w_antler", Color(0.85, 0.92, 0.98), 0.3, 0.2, Color(0.5, 0.8, 1.0), 1.5)
	var harness_mat = _get_mat("w_harness", Color(0.8, 0.15, 0.15), 0.6)
	var bell_mat = _get_mat("w_gold", Color(1.0, 0.85, 0.2), 0.3, 0.8)

	# Quadruped Body Barrel
	var body = MeshInstance3D.new()
	body.name = "Torso"
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.85, 0.85, 1.8)
	body.mesh = b_mesh
	body.material_override = hide_mat
	body.position.y = 1.15
	root.add_child(body)

	# Snowy White Mane / Chest
	var chest = MeshInstance3D.new()
	var ch_mesh = SphereMesh.new()
	ch_mesh.radius = 0.45
	ch_mesh.height = 0.90
	chest.mesh = ch_mesh
	chest.material_override = mane_mat
	chest.position = Vector3(0, 1.35, 0.75)
	root.add_child(chest)

	# 4 Slender Legs
	for x_s in [-1.0, 1.0]:
		for z_s in [-1.0, 1.0]:
			var leg = MeshInstance3D.new()
			var leg_tag = ("Leg_FL" if (x_s < 0 and z_s > 0) else ("Leg_FR" if (x_s > 0 and z_s > 0) else ("Leg_BL" if (x_s < 0 and z_s < 0) else "Leg_BR")))
			leg.name = leg_tag
			var l_mesh = CylinderMesh.new()
			l_mesh.top_radius = 0.12
			l_mesh.bottom_radius = 0.08
			l_mesh.height = 1.0
			leg.mesh = l_mesh
			leg.material_override = hide_mat
			leg.position = Vector3(x_s * 0.35, 0.5, z_s * 0.65)
			root.add_child(leg)

	# Reindeer Head & Snout
	var head = MeshInstance3D.new()
	head.name = "Head"
	var hd_mesh = BoxMesh.new()
	hd_mesh.size = Vector3(0.42, 0.45, 0.75)
	head.mesh = hd_mesh
	head.material_override = hide_mat
	head.position = Vector3(0, 1.85, 0.95)
	root.add_child(head)

	# Red Harness with Brass Jingling Bells
	var harness = MeshInstance3D.new()
	var hr_mesh = TorusMesh.new()
	hr_mesh.inner_radius = 0.38
	hr_mesh.outer_radius = 0.48
	harness.mesh = hr_mesh
	harness.material_override = harness_mat
	harness.position = Vector3(0, 1.45, 0.65)
	root.add_child(harness)

	# Crystal-Frosted Branched Antlers
	for s in [-1.0, 1.0]:
		var antler_main = MeshInstance3D.new()
		var am_mesh = CylinderMesh.new()
		am_mesh.top_radius = 0.03
		am_mesh.bottom_radius = 0.08
		am_mesh.height = 0.95
		antler_main.mesh = am_mesh
		antler_main.material_override = antler_mat
		antler_main.position = Vector3(s * 0.28, 2.35, 0.8)
		antler_main.rotation_degrees = Vector3(-25, 0, s * 35)
		root.add_child(antler_main)

		var antler_tine = MeshInstance3D.new()
		var at_mesh = CylinderMesh.new()
		at_mesh.top_radius = 0.02
		at_mesh.bottom_radius = 0.06
		at_mesh.height = 0.45
		antler_tine.mesh = at_mesh
		antler_tine.material_override = antler_mat
		antler_tine.position = Vector3(s * 0.45, 2.50, 0.95)
		antler_tine.rotation_degrees = Vector3(25, 0, s * 45)
		root.add_child(antler_tine)

# -----------------------------------------------------------------------------
# 9. ABOMINABLE YETI (COLOSSUS)
# -----------------------------------------------------------------------------
static func _build_abominable_yeti(root: Node3D):
	var fur_mat = _get_mat("w_yeti_fur", Color(0.92, 0.94, 0.98), 0.95)
	var blue_skin = _get_mat("w_yeti_skin", Color(0.25, 0.45, 0.68), 0.7)
	var horn_mat = _get_mat("w_yeti_horn", Color(0.6, 0.8, 0.95), 0.3)

	# Massive Hulking Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(1.4, 1.6, 1.1)
	torso.mesh = t_mesh
	torso.material_override = fur_mat
	torso.position.y = 1.6
	root.add_child(torso)

	# Sturdy Yeti Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.35
	l_cyl.bottom_radius = 0.32
	l_cyl.height = 0.95
	leg_l.mesh = l_cyl
	leg_l.material_override = fur_mat
	leg_l.position = Vector3(-0.48, 0.55, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = fur_mat
	leg_r.position = Vector3(0.48, 0.55, 0)
	root.add_child(leg_r)

	# Blue Frost Chest Plate
	var chest = MeshInstance3D.new()
	var ch_mesh = BoxMesh.new()
	ch_mesh.size = Vector3(0.9, 0.9, 0.2)
	chest.mesh = ch_mesh
	chest.material_override = blue_skin
	chest.position = Vector3(0, 1.65, 0.58)
	root.add_child(chest)

	# Massive Ape Arms & Giant Fists
	var arm_l = MeshInstance3D.new()
	arm_l.name = "LeftArm"
	var a_mesh = CylinderMesh.new()
	a_mesh.top_radius = 0.32
	a_mesh.bottom_radius = 0.28
	a_mesh.height = 1.4
	arm_l.mesh = a_mesh
	arm_l.material_override = fur_mat
	arm_l.position = Vector3(-1.05, 1.3, 0.2)
	root.add_child(arm_l)

	var fist_l = MeshInstance3D.new()
	fist_l.name = "LeftFist"
	var f_mesh = BoxMesh.new()
	f_mesh.size = Vector3(0.48, 0.52, 0.58)
	fist_l.mesh = f_mesh
	fist_l.material_override = blue_skin
	fist_l.position = Vector3(-1.05, 0.55, 0.35)
	root.add_child(fist_l)

	var arm_r = MeshInstance3D.new()
	arm_r.name = "RightArm"
	arm_r.mesh = a_mesh
	arm_r.material_override = fur_mat
	arm_r.position = Vector3(1.05, 1.3, 0.2)
	root.add_child(arm_r)

	var fist_r = MeshInstance3D.new()
	fist_r.name = "RightFist"
	fist_r.mesh = f_mesh
	fist_r.material_override = blue_skin
	fist_r.position = Vector3(1.05, 0.55, 0.35)
	root.add_child(fist_r)

	# Head with Blue Snout and Icy Horns
	var head = MeshInstance3D.new()
	head.name = "Head"
	var hd_mesh = BoxMesh.new()
	hd_mesh.size = Vector3(0.7, 0.65, 0.7)
	head.mesh = hd_mesh
	head.material_override = fur_mat
	head.position = Vector3(0, 2.65, 0.15)
	root.add_child(head)

	for s in [-1.0, 1.0]:
		var horn = MeshInstance3D.new()
		var hn_mesh = CylinderMesh.new()
		hn_mesh.top_radius = 0.04
		hn_mesh.bottom_radius = 0.12
		hn_mesh.height = 0.55
		horn.mesh = hn_mesh
		horn.material_override = horn_mat
		horn.position = Vector3(s * 0.42, 3.0, 0.05)
		horn.rotation_degrees = Vector3(-15, 0, s * 45)
		root.add_child(horn)

# -----------------------------------------------------------------------------
# 10. FROST WOLF
# -----------------------------------------------------------------------------
static func _build_frost_wolf(root: Node3D):
	var fur_mat = _get_mat("w_wolf_white", Color(0.92, 0.95, 1.0), 0.85)
	var eye_mat = _get_mat("w_wolf_eye", Color(0.2, 0.8, 1.0), 0.2, 0.0, Color(0.2, 0.8, 1.0), 3.0)

	# Sleek Wolf Torso
	var body = MeshInstance3D.new()
	body.name = "Torso"
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.55, 0.55, 1.2)
	body.mesh = b_mesh
	body.material_override = fur_mat
	body.position.y = 0.65
	root.add_child(body)

	# 4 Paws
	for x_s in [-1.0, 1.0]:
		for z_s in [-1.0, 1.0]:
			var leg = MeshInstance3D.new()
			var leg_tag = ("Leg_FL" if (x_s < 0 and z_s > 0) else ("Leg_FR" if (x_s > 0 and z_s > 0) else ("Leg_BL" if (x_s < 0 and z_s < 0) else "Leg_BR")))
			leg.name = leg_tag
			var l_mesh = CylinderMesh.new()
			l_mesh.top_radius = 0.09
			l_mesh.bottom_radius = 0.07
			l_mesh.height = 0.65
			leg.mesh = l_mesh
			leg.material_override = fur_mat
			leg.position = Vector3(x_s * 0.22, 0.32, z_s * 0.45)
			root.add_child(leg)

	# Head & Muzzle
	var head = MeshInstance3D.new()
	head.name = "Head"
	var hd_mesh = BoxMesh.new()
	hd_mesh.size = Vector3(0.32, 0.32, 0.5)
	head.mesh = hd_mesh
	head.material_override = fur_mat
	head.position = Vector3(0, 0.95, 0.65)
	root.add_child(head)

	for s in [-1.0, 1.0]:
		var eye = MeshInstance3D.new()
		var e_mesh = SphereMesh.new()
		e_mesh.radius = 0.04
		eye.mesh = e_mesh
		eye.material_override = eye_mat
		eye.position = Vector3(s * 0.12, 1.02, 0.80)
		root.add_child(eye)

	# Bushy Frost Tail
	var tail = MeshInstance3D.new()
	tail.name = "Tail"
	var tl_mesh = CylinderMesh.new()
	tl_mesh.top_radius = 0.04
	tl_mesh.bottom_radius = 0.12
	tl_mesh.height = 0.65
	tail.mesh = tl_mesh
	tail.material_override = fur_mat
	tail.position = Vector3(0, 0.75, -0.85)
	tail.rotation_degrees.x = -45
	root.add_child(tail)

# -----------------------------------------------------------------------------
# 11. SNOW SPRITE (FLYER)
# -----------------------------------------------------------------------------
static func _build_snow_sprite(root: Node3D):
	var ice_glow = _get_mat("w_sprite_glow", Color(0.6, 0.95, 1.0, 0.9), 0.2, 0.1, Color(0.5, 0.9, 1.0), 3.5)
	var wing_mat = _get_mat("w_sprite_wing", Color(0.8, 0.95, 1.0, 0.5), 0.1, 0.5, Color(0.6, 0.9, 1.0), 2.0)

	# Tiny Luminous Body
	var body = MeshInstance3D.new()
	body.name = "Body"
	var b_mesh = SphereMesh.new()
	b_mesh.radius = 0.22
	b_mesh.height = 0.44
	body.mesh = b_mesh
	body.material_override = ice_glow
	body.position.y = 0.6
	root.add_child(body)

	# Crystalline Snowflake Wings
	var wing_l = MeshInstance3D.new()
	wing_l.name = "WingL"
	var w_mesh = BoxMesh.new()
	w_mesh.size = Vector3(0.55, 0.35, 0.04)
	wing_l.mesh = w_mesh
	wing_l.material_override = wing_mat
	wing_l.position = Vector3(-0.32, 0.75, -0.1)
	wing_l.rotation_degrees = Vector3(15, -25, -20)
	root.add_child(wing_l)

	var wing_r = MeshInstance3D.new()
	wing_r.name = "WingR"
	wing_r.mesh = w_mesh
	wing_r.material_override = wing_mat
	wing_r.position = Vector3(0.32, 0.75, -0.1)
	wing_r.rotation_degrees = Vector3(15, 25, 20)
	root.add_child(wing_r)

# -----------------------------------------------------------------------------
# 12. FROST ELF
# -----------------------------------------------------------------------------
static func _build_frost_elf(root: Node3D):
	var green_mat = _get_mat("w_elf_green", Color(0.12, 0.35, 0.18), 0.7)
	var fur_mat = _get_mat("w_fur", Color(0.96, 0.96, 0.96), 0.9)
	var silver_mat = _get_mat("w_silver", Color(0.85, 0.92, 0.98), 0.2, 0.8)

	# Slender Torso
	var torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 0.26
	t_mesh.bottom_radius = 0.28
	t_mesh.height = 0.75
	torso.mesh = t_mesh
	torso.material_override = green_mat
	torso.position.y = 1.0
	root.add_child(torso)

	# Legs
	var leg_l = MeshInstance3D.new()
	leg_l.name = "LeftLeg"
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.08
	l_cyl.bottom_radius = 0.06
	l_cyl.height = 0.75
	leg_l.mesh = l_cyl
	leg_l.material_override = green_mat
	leg_l.position = Vector3(-0.14, 0.45, 0)
	root.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.name = "RightLeg"
	leg_r.mesh = l_cyl
	leg_r.material_override = green_mat
	leg_r.position = Vector3(0.14, 0.45, 0)
	root.add_child(leg_r)

	# Pointed Hooded Cap with Fur Trim
	var hood = MeshInstance3D.new()
	hood.name = "Head"
	var hd_mesh = CylinderMesh.new()
	hd_mesh.top_radius = 0.05
	hd_mesh.bottom_radius = 0.28
	hd_mesh.height = 0.55
	hood.mesh = hd_mesh
	hood.material_override = green_mat
	hood.position = Vector3(0, 1.85, -0.05)
	hood.rotation_degrees.x = -20
	root.add_child(hood)

	# Silver Recurve Bow
	var bow = MeshInstance3D.new()
	bow.name = "Weapon"
	var bw_mesh = TorusMesh.new()
	bw_mesh.inner_radius = 0.35
	bw_mesh.outer_radius = 0.42
	bow.mesh = bw_mesh
	bow.material_override = silver_mat
	bow.position = Vector3(0.35, 1.05, 0.25)
	bow.rotation_degrees.y = 90
	root.add_child(bow)

# -----------------------------------------------------------------------------
# 13. BLIZZARD WITCH
# -----------------------------------------------------------------------------
static func _build_blizzard_witch(root: Node3D):
	var dark_blue = _get_mat("w_witch_blue", Color(0.08, 0.15, 0.32), 0.6)
	var fur_mat = _get_mat("w_fur", Color(0.96, 0.96, 0.96), 0.9)
	var orb_mat = _get_mat("w_ice_crystal", Color(0.8, 0.95, 1.0), 0.1, 0.4, Color(0.6, 0.95, 1.0), 3.0)

	# Dark Flowing Gown
	var gown = MeshInstance3D.new()
	gown.name = "Torso"
	var g_mesh = CylinderMesh.new()
	g_mesh.top_radius = 0.32
	g_mesh.bottom_radius = 0.75
	g_mesh.height = 1.5
	gown.mesh = g_mesh
	gown.material_override = dark_blue
	gown.position.y = 0.75
	root.add_child(gown)

	# Fur Mantle Collar
	var mantle = MeshInstance3D.new()
	var m_mesh = TorusMesh.new()
	m_mesh.inner_radius = 0.30
	m_mesh.outer_radius = 0.45
	mantle.mesh = m_mesh
	mantle.material_override = fur_mat
	mantle.position.y = 1.6
	root.add_child(mantle)

	# Gnarled Staff with Swirling Blizzard Orb
	var staff = MeshInstance3D.new()
	staff.name = "Weapon"
	var st_mesh = CylinderMesh.new()
	st_mesh.top_radius = 0.04
	st_mesh.bottom_radius = 0.05
	st_mesh.height = 2.0
	staff.mesh = st_mesh
	staff.material_override = _get_mat("w_staff_wood", Color(0.35, 0.25, 0.18))
	staff.position = Vector3(0.5, 1.1, 0.2)
	root.add_child(staff)

	var orb = MeshInstance3D.new()
	orb.name = "IceOrb"
	var ob_mesh = SphereMesh.new()
	ob_mesh.radius = 0.22
	orb.mesh = ob_mesh
	orb.material_override = orb_mat
	orb.position = Vector3(0.5, 2.15, 0.2)
	root.add_child(orb)

# -----------------------------------------------------------------------------
# 14. SNOWBALL CATAPULT
# -----------------------------------------------------------------------------
static func _build_snowball_catapult(root: Node3D):
	var timber_mat = _get_mat("w_sled_timber", Color(0.38, 0.25, 0.15), 0.8)
	var iron_mat = _get_mat("w_iron", Color(0.4, 0.42, 0.45), 0.3, 0.8)
	var snow_mat = _get_mat("w_snowball", Color(0.92, 0.96, 1.0), 0.5)

	# Sled Ski Runners
	for s in [-1.0, 1.0]:
		var ski = MeshInstance3D.new()
		var sk_mesh = BoxMesh.new()
		sk_mesh.size = Vector3(0.18, 0.12, 2.2)
		ski.mesh = sk_mesh
		ski.material_override = iron_mat
		ski.position = Vector3(s * 0.65, 0.06, 0)
		root.add_child(ski)

	# Timber Sled Frame
	var frame = MeshInstance3D.new()
	var fr_mesh = BoxMesh.new()
	fr_mesh.size = Vector3(1.4, 0.25, 1.8)
	frame.mesh = fr_mesh
	frame.material_override = timber_mat
	frame.position.y = 0.25
	root.add_child(frame)

	# A-Frame Uprights
	for s in [-1.0, 1.0]:
		var post = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 0.08
		p_mesh.bottom_radius = 0.10
		p_mesh.height = 1.3
		post.mesh = p_mesh
		post.material_override = timber_mat
		post.position = Vector3(s * 0.55, 0.85, 0)
		root.add_child(post)

	# Catapult Throwing Arm
	var arm = MeshInstance3D.new()
	arm.name = "CatapultArm"
	var a_mesh = BoxMesh.new()
	a_mesh.size = Vector3(0.2, 1.6, 0.2)
	arm.mesh = a_mesh
	arm.material_override = timber_mat
	arm.position = Vector3(0, 1.1, -0.3)
	arm.rotation_degrees.x = 35
	root.add_child(arm)

	# Giant Packed Snowball Loaded in Bucket
	var snowball = MeshInstance3D.new()
	snowball.name = "Snowball"
	var sb_mesh = SphereMesh.new()
	sb_mesh.radius = 0.38
	snowball.mesh = sb_mesh
	snowball.material_override = snow_mat
	snowball.position = Vector3(0, 1.65, -0.75)
	root.add_child(snowball)

# -----------------------------------------------------------------------------
# 15. FESTIVE YULE LOG
# -----------------------------------------------------------------------------
static func _build_yule_log(root: Node3D):
	var bark_mat = _get_mat("w_yule_bark", Color(0.28, 0.18, 0.10), 0.9)
	var holly_green = _get_mat("w_holly_g", Color(0.10, 0.45, 0.18), 0.7)
	var holly_red = _get_mat("w_holly_r", Color(0.9, 0.12, 0.15), 0.4)
	var holiday_fire = _get_mat("w_yule_fire", Color(1.0, 0.5, 0.1), 0.2, 0.0, Color(1.0, 0.45, 0.0), 4.0)

	# Gnarled Wooden Log (horizontal cylinder)
	var yule_log = MeshInstance3D.new()
	yule_log.name = "Log"
	var lg_mesh = CylinderMesh.new()
	lg_mesh.top_radius = 0.32
	lg_mesh.bottom_radius = 0.32
	lg_mesh.height = 1.5
	yule_log.mesh = lg_mesh
	yule_log.material_override = bark_mat
	yule_log.rotation_degrees.z = 90
	yule_log.position.y = 0.35
	root.add_child(yule_log)

	# Holly Leaves & Red Berries
	var holly = MeshInstance3D.new()
	var hl_mesh = BoxMesh.new()
	hl_mesh.size = Vector3(0.45, 0.12, 0.35)
	holly.mesh = hl_mesh
	holly.material_override = holly_green
	holly.position = Vector3(0, 0.70, 0)
	root.add_child(holly)

	var berry = MeshInstance3D.new()
	var br_mesh = SphereMesh.new()
	br_mesh.radius = 0.10
	berry.mesh = br_mesh
	berry.material_override = holly_red
	berry.position = Vector3(0, 0.78, 0.05)
	root.add_child(berry)

	# Crackling Holiday Flames along top
	for i in range(3):
		var flame = MeshInstance3D.new()
		flame.name = "Flame_" + str(i)
		var fl_mesh = CylinderMesh.new()
		fl_mesh.top_radius = 0.02
		fl_mesh.bottom_radius = 0.16
		fl_mesh.height = 0.45
		flame.mesh = fl_mesh
		flame.material_override = holiday_fire
		flame.position = Vector3(-0.4 + i * 0.4, 0.85, 0)
		root.add_child(flame)

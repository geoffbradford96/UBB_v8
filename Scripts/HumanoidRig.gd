extends Node
class_name HumanoidRig

func _init():
	name = "HumanoidRig"

# Reference to the unit CharacterBody3D
var unit: CharacterBody3D = null
var rig_root: Node3D = null

# Anatomical Rig Nodes
var torso: Node3D = null
var head: Node3D = null
var left_arm_pivot: Node3D = null
var left_arm_mesh: Node3D = null
var right_arm_pivot: Node3D = null
var right_arm_mesh: Node3D = null
var left_leg_pivot: Node3D = null
var left_leg_mesh: Node3D = null
var right_leg_pivot: Node3D = null
var right_leg_mesh: Node3D = null
var weapon_node: Node3D = null

# Base resting positions
var base_torso_pos: Vector3 = Vector3(0, 0.95, 0)
var base_head_pos: Vector3 = Vector3(0, 1.55, 0)
var base_left_arm_pos: Vector3 = Vector3(-0.29, 1.26, 0)
var base_right_arm_pos: Vector3 = Vector3(0.29, 1.26, 0)
var base_left_leg_pos: Vector3 = Vector3(-0.16, 0.62, 0)
var base_right_leg_pos: Vector3 = Vector3(0.16, 0.62, 0)

# Animation timers & state
var walk_time: float = 0.0
var idle_time: float = 0.0
var limp_time: float = 0.0
var attack_anim_timer: float = 0.0
var attack_anim_duration: float = 0.32
var is_active: bool = false

func trigger_attack(duration: float = 0.32):
	attack_anim_duration = clampf(duration, 0.15, 0.65)
	attack_anim_timer = attack_anim_duration

func setup(p_unit: CharacterBody3D):
	unit = p_unit
	if not unit: return
	
	# Hide or remove any existing raw placeholder meshes in the unit visual root
	var visual_root = unit.get_node_or_null("VisualPivot")
	if not visual_root: visual_root = unit.get_node_or_null("MeshInstance3D")
	if not visual_root: visual_root = unit.get_node_or_null("Visuals")
	if not visual_root:
		visual_root = Node3D.new()
		visual_root.name = "VisualPivot"
		unit.add_child(visual_root)
		
	# Hide previous raw mesh if it exists
	if visual_root is MeshInstance3D:
		visual_root.mesh = null
	for child in visual_root.get_children():
		if child.name == "HumanoidRigRoot":
			child.queue_free()
		elif child.name == "ShieldVisualRoot" or child.name == "ArmorPlatesRoot":
			continue
		else:
			child.visible = false
			
	_build_humanoid_anatomy(visual_root)
	is_active = true

func _build_humanoid_anatomy(parent: Node3D):
	rig_root = Node3D.new()
	rig_root.name = "HumanoidRigRoot"
	rig_root.rotation.y = PI # Align with Godot's forward vector (-Z) so infantry face where they walk and shoot!
	parent.add_child(rig_root)
	
	# Determine Faction & Styling
	var u_name = unit.name
	var is_reach = "Reach" in u_name
	var is_scrap = "Scrap" in u_name
	var is_beast_speaker = "GreatBeastSpeaker" in u_name
	var is_rimworlder = "Rimworlder" in u_name or is_beast_speaker
	var is_medic = "Medic" in u_name or "Repair" in u_name
	var is_commander = "Commander" in u_name or "Hero" in u_name or is_beast_speaker
	var is_hunter = "Hunter" in u_name or "Assassin" in u_name
	var is_primitive = "Primitive" in u_name
	var is_caveman = is_primitive and ("Chieftain" in u_name or "Caveman" in u_name or "Clubber" in u_name or "Spearman" in u_name or "ShortBow" in u_name or "RockThrower" in u_name)
	var is_feudal = is_primitive and not is_caveman
	
	# Namesake Proportional Rig Scaling
	if "Chieftain" in u_name:
		rig_root.scale = Vector3(1.24, 1.22, 1.24) # Imposing, massive barbarian leader
	elif "Knight" in u_name:
		rig_root.scale = Vector3(1.12, 1.10, 1.12) # Broad, heavily armored chivalric knight
	elif "Commander" in u_name and ("Primitive" in u_name or "Sol" in u_name):
		rig_root.scale = Vector3(1.15, 1.14, 1.15) # Regal feudal lord
	elif "CavemanBuilder" in u_name:
		rig_root.scale = Vector3(1.08, 1.06, 1.08) # Sturdy stone crafter
	elif "Clubber" in u_name:
		rig_root.scale = Vector3(0.92, 0.88, 0.92) # Low-slung, agile swarm cavemen
	elif "Squire" in u_name or ("Builder" in u_name and "Primitive" in u_name):
		rig_root.scale = Vector3(0.95, 0.95, 0.95) # Agile foot squires and craftsmen
	elif "ShortBow" in u_name or "RockThrower" in u_name:
		rig_root.scale = Vector3(0.95, 0.95, 0.95) # Quick hunters
	
	# Materials
	var body_mat = StandardMaterial3D.new()
	var armor_mat = StandardMaterial3D.new()
	var visor_mat = StandardMaterial3D.new()
	var weapon_mat = StandardMaterial3D.new()
	
	if is_caveman:
		# Primal Stone Age: Sun-baked skin, wild fur pelts, mammoth ivory, dark knapped flint
		body_mat.albedo_color = Color(0.72, 0.50, 0.38)
		body_mat.roughness = 0.9
		armor_mat.albedo_color = Color(0.38, 0.24, 0.16)
		armor_mat.roughness = 0.95
		visor_mat.albedo_color = Color(0.92, 0.88, 0.76)
		visor_mat.roughness = 0.65
		weapon_mat.albedo_color = Color(0.22, 0.18, 0.14)
		weapon_mat.roughness = 0.85
	elif is_feudal:
		# Medieval Feudal Empire: Heavy wool/linen gambeson, forged steel plate, brass trim
		body_mat.albedo_color = Color(0.28, 0.34, 0.44) if "Commander" not in u_name else Color(0.55, 0.12, 0.16)
		body_mat.roughness = 0.8
		armor_mat.albedo_color = Color(0.68, 0.70, 0.74)
		armor_mat.metallic = 0.75
		armor_mat.roughness = 0.35
		visor_mat.albedo_color = Color(0.88, 0.75, 0.25)
		visor_mat.metallic = 0.85
		visor_mat.roughness = 0.25
		weapon_mat.albedo_color = Color(0.45, 0.48, 0.52)
		weapon_mat.metallic = 0.85
		weapon_mat.roughness = 0.3
	elif is_beast_speaker:
		# Primal Shaman Beast-Speaker: dark beast-hide pelts, bleached bone armor, glowing emerald totem energy
		body_mat.albedo_color = Color(0.32, 0.22, 0.14)
		body_mat.roughness = 0.85
		armor_mat.albedo_color = Color(0.86, 0.82, 0.70)
		armor_mat.roughness = 0.55
		visor_mat.albedo_color = Color(0.15, 1.0, 0.45)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.15, 1.0, 0.45)
		visor_mat.emission_energy_multiplier = 3.2
		weapon_mat.albedo_color = Color(0.55, 0.42, 0.25)
		weapon_mat.roughness = 0.7
	elif is_reach:
		# Sleek cybernetic white with glowing cyan energy
		body_mat.albedo_color = Color(0.92, 0.95, 0.98)
		body_mat.metallic = 0.8
		body_mat.roughness = 0.2
		armor_mat.albedo_color = Color(0.82, 0.88, 0.94)
		armor_mat.metallic = 0.9
		armor_mat.roughness = 0.15
		visor_mat.albedo_color = Color(0.0, 0.9, 1.0)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.0, 0.9, 1.0)
		visor_mat.emission_energy_multiplier = 3.5
		weapon_mat.albedo_color = Color(0.2, 0.25, 0.3)
		weapon_mat.metallic = 0.9
	elif is_scrap:
		# Weathered rust iron and junk metal
		body_mat.albedo_color = Color(0.46, 0.26, 0.16)
		body_mat.roughness = 0.85
		armor_mat.albedo_color = Color(0.32, 0.3, 0.28)
		armor_mat.metallic = 0.6
		armor_mat.roughness = 0.7
		visor_mat.albedo_color = Color(1.0, 0.35, 0.1)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(1.0, 0.35, 0.1)
		visor_mat.emission_energy_multiplier = 2.0
		weapon_mat.albedo_color = Color(0.28, 0.25, 0.22)
		weapon_mat.metallic = 0.7
	elif is_rimworlder:
		# Leather duster / survival khaki
		body_mat.albedo_color = Color(0.45, 0.32, 0.22)
		body_mat.roughness = 0.8
		armor_mat.albedo_color = Color(0.55, 0.48, 0.36)
		armor_mat.roughness = 0.75
		visor_mat.albedo_color = Color(0.2, 0.85, 0.35)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.2, 0.85, 0.35)
		visor_mat.emission_energy_multiplier = 1.6
		weapon_mat.albedo_color = Color(0.25, 0.22, 0.2)
		weapon_mat.metallic = 0.5
	elif is_medic:
		# Medical white with red cross
		body_mat.albedo_color = Color(0.9, 0.9, 0.92)
		body_mat.roughness = 0.5
		armor_mat.albedo_color = Color(0.85, 0.15, 0.15)
		visor_mat.albedo_color = Color(0.1, 0.8, 0.3)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.1, 0.8, 0.3)
		visor_mat.emission_energy_multiplier = 2.0
		weapon_mat.albedo_color = Color(0.3, 0.3, 0.3)
	elif is_hunter or "Assassin" in u_name:
		# Stealth midnight charcoal / purple visor
		body_mat.albedo_color = Color(0.12, 0.12, 0.14)
		body_mat.roughness = 0.6
		armor_mat.albedo_color = Color(0.18, 0.18, 0.22)
		visor_mat.albedo_color = Color(0.75, 0.15, 0.9)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.75, 0.15, 0.9)
		visor_mat.emission_energy_multiplier = 3.0
		weapon_mat.albedo_color = Color(0.1, 0.1, 0.12)
		weapon_mat.metallic = 0.9
	elif is_commander:
		# Majestic heavy slate plate with gold trim
		body_mat.albedo_color = Color(0.18, 0.22, 0.28)
		body_mat.metallic = 0.7
		armor_mat.albedo_color = Color(0.95, 0.78, 0.2)
		armor_mat.metallic = 0.9
		armor_mat.roughness = 0.2
		visor_mat.albedo_color = Color(1.0, 0.85, 0.3)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(1.0, 0.85, 0.3)
		visor_mat.emission_energy_multiplier = 2.5
		weapon_mat.albedo_color = Color(0.9, 0.8, 0.2)
		weapon_mat.metallic = 0.95
	else:
		# Standard Dominion military combat uniform (olive drab / slate)
		body_mat.albedo_color = Color(0.24, 0.34, 0.2)
		body_mat.roughness = 0.7
		armor_mat.albedo_color = Color(0.18, 0.24, 0.16)
		armor_mat.metallic = 0.4
		visor_mat.albedo_color = Color(0.2, 0.7, 0.9)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.2, 0.7, 0.9)
		visor_mat.emission_energy_multiplier = 2.0
		weapon_mat.albedo_color = Color(0.18, 0.18, 0.18)
		weapon_mat.metallic = 0.8

	# --- 1. TORSO & CHEST ---
	torso = Node3D.new()
	torso.name = "Torso"
	torso.position = base_torso_pos
	rig_root.add_child(torso)
	
	var chest_mesh = MeshInstance3D.new()
	var box_t = BoxMesh.new()
	box_t.size = Vector3(0.48, 0.65, 0.28)
	chest_mesh.mesh = box_t
	chest_mesh.material_override = body_mat
	torso.add_child(chest_mesh)
	
	# Armor vest plate
	var armor_plate = MeshInstance3D.new()
	var box_ap = BoxMesh.new()
	box_ap.size = Vector3(0.52, 0.45, 0.32)
	armor_plate.mesh = box_ap
	armor_plate.material_override = armor_mat
	armor_plate.position = Vector3(0, 0.08, 0)
	torso.add_child(armor_plate)
	
	# Tactical belt
	var belt = MeshInstance3D.new()
	var box_b = BoxMesh.new()
	box_b.size = Vector3(0.5, 0.12, 0.3)
	belt.mesh = box_b
	belt.material_override = weapon_mat
	belt.position = Vector3(0, -0.28, 0)
	torso.add_child(belt)

	# Pelvis / Hip block bridging lower torso to upper leg sockets
	var pelvis = MeshInstance3D.new()
	var box_pelvis = BoxMesh.new()
	box_pelvis.size = Vector3(0.44, 0.18, 0.26)
	pelvis.mesh = box_pelvis
	pelvis.material_override = body_mat
	pelvis.position = Vector3(0, -0.36, 0)
	torso.add_child(pelvis)

	# Armored Neck / Gorget Cylinder bridging upper torso (y=1.275) to head base (y=1.36)
	var neck = MeshInstance3D.new()
	var cyl_neck = CylinderMesh.new()
	cyl_neck.top_radius = 0.095
	cyl_neck.bottom_radius = 0.115
	cyl_neck.height = 0.22
	neck.mesh = cyl_neck
	neck.material_override = armor_mat
	neck.position = Vector3(0, 0.38, 0)
	torso.add_child(neck)

	# Faction & Role Back / Torso Silhouette Accessories
	if is_caveman:
		# Primal Beast Fur Mantle & Bone Trophy across the shoulders
		var fur_mantle = MeshInstance3D.new()
		var fm_box = BoxMesh.new()
		fm_box.size = Vector3(0.68, 0.24, 0.42)
		fur_mantle.mesh = fm_box
		fur_mantle.material_override = armor_mat
		fur_mantle.position = Vector3(0, 0.28, -0.04)
		torso.add_child(fur_mantle)
		
		var bone_talisman = MeshInstance3D.new()
		var bt_box = BoxMesh.new()
		bt_box.size = Vector3(0.46, 0.08, 0.36)
		bone_talisman.mesh = bt_box
		bone_talisman.material_override = visor_mat
		bone_talisman.position = Vector3(0, 0.16, 0.02)
		torso.add_child(bone_talisman)
	elif is_feudal:
		if "Commander" in u_name:
			# Royal War Cape with gold clasp
			var cape = MeshInstance3D.new()
			var cape_box = BoxMesh.new()
			cape_box.size = Vector3(0.58, 0.95, 0.04)
			cape.mesh = cape_box
			var cape_mat = StandardMaterial3D.new()
			cape_mat.albedo_color = Color(0.62, 0.08, 0.12)
			cape.material_override = cape_mat
			cape.position = Vector3(0, -0.12, -0.18)
			cape.rotation_degrees.x = 9.0
			torso.add_child(cape)
		elif "Knight" in u_name:
			# Heavy Steel Cuirass Backplate & Gorget Rim
			var back_cuirass = MeshInstance3D.new()
			var bc_box = BoxMesh.new()
			bc_box.size = Vector3(0.54, 0.48, 0.12)
			back_cuirass.mesh = bc_box
			back_cuirass.material_override = armor_mat
			back_cuirass.position = Vector3(0, 0.08, -0.14)
			torso.add_child(back_cuirass)
		elif "Crossbowman" in u_name or "ShortBow" in u_name:
			# Quiver of arrows / quarrels on back
			var quiver = MeshInstance3D.new()
			var q_cyl = CylinderMesh.new()
			q_cyl.top_radius = 0.10
			q_cyl.bottom_radius = 0.08
			q_cyl.height = 0.70
			quiver.mesh = q_cyl
			quiver.material_override = armor_mat
			quiver.position = Vector3(-0.16, 0.08, -0.20)
			quiver.rotation_degrees = Vector3(15.0, 0.0, -25.0)
			torso.add_child(quiver)
		elif "Builder" in u_name:
			# Craftsman Leather Apron & Tool Pouch
			var apron = MeshInstance3D.new()
			var a_box = BoxMesh.new()
			a_box.size = Vector3(0.44, 0.62, 0.04)
			apron.mesh = a_box
			apron.material_override = armor_mat
			apron.position = Vector3(0, -0.22, 0.18)
			torso.add_child(apron)
			var pouch = MeshInstance3D.new()
			var p_box = BoxMesh.new()
			p_box.size = Vector3(0.24, 0.20, 0.14)
			pouch.mesh = p_box
			pouch.material_override = armor_mat
			pouch.position = Vector3(0.24, -0.22, 0.12)
			torso.add_child(pouch)
	elif is_beast_speaker:
		# Fur mantle + bone trophy spines across the back
		var fur_mantle = MeshInstance3D.new()
		var fm_box = BoxMesh.new()
		fm_box.size = Vector3(0.68, 0.24, 0.42)
		fur_mantle.mesh = fm_box
		fur_mantle.material_override = body_mat
		fur_mantle.position = Vector3(0, 0.28, -0.04)
		torso.add_child(fur_mantle)
	elif is_reach:
		# Cybernetic Halo Mounting Spine Bracket + Cyan Halo Ring behind shoulders
		var halo_mount = MeshInstance3D.new()
		var hm_box = BoxMesh.new()
		hm_box.size = Vector3(0.10, 0.20, 0.16)
		halo_mount.mesh = hm_box
		halo_mount.material_override = armor_mat
		halo_mount.position = Vector3(0, 0.22, -0.18)
		torso.add_child(halo_mount)

		var reach_halo = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 0.24
		torus.outer_radius = 0.30
		reach_halo.mesh = torus
		reach_halo.material_override = visor_mat
		reach_halo.rotation_degrees.x = 90.0
		reach_halo.position = Vector3(0, 0.22, -0.24)
		torso.add_child(reach_halo)
	elif is_scrap:
		# Twin Belching Scrap Exhaust Pipes on back with manifold block
		var manifold = MeshInstance3D.new()
		var mf_box = BoxMesh.new()
		mf_box.size = Vector3(0.38, 0.18, 0.14)
		manifold.mesh = mf_box
		manifold.material_override = armor_mat
		manifold.position = Vector3(0, 0.12, -0.18)
		torso.add_child(manifold)
		for side in [-1.0, 1.0]:
			var pipe = MeshInstance3D.new()
			var cyl_p = CylinderMesh.new()
			cyl_p.top_radius = 0.05
			cyl_p.bottom_radius = 0.06
			cyl_p.height = 0.48
			pipe.mesh = cyl_p
			pipe.material_override = weapon_mat
			pipe.position = Vector3(side * 0.15, 0.26, -0.20)
			pipe.rotation_degrees.z = side * 14.0
			torso.add_child(pipe)
	elif is_medic:
		# Medical Field Pack with glowing bio-stabilizer core
		var med_pack = MeshInstance3D.new()
		var mp_box = BoxMesh.new()
		mp_box.size = Vector3(0.36, 0.38, 0.18)
		med_pack.mesh = mp_box
		med_pack.material_override = armor_mat
		med_pack.position = Vector3(0, 0.08, -0.20)
		torso.add_child(med_pack)
		var med_glow = MeshInstance3D.new()
		var mg_box = BoxMesh.new()
		mg_box.size = Vector3(0.14, 0.14, 0.06)
		med_glow.mesh = mg_box
		med_glow.material_override = visor_mat
		med_glow.position = Vector3(0, 0.08, -0.30)
		torso.add_child(med_glow)
	elif is_commander:
		# Heroic Command Mantle Cape anchored to upper back armor
		var cape = MeshInstance3D.new()
		var cape_box = BoxMesh.new()
		cape_box.size = Vector3(0.54, 0.72, 0.05)
		cape.mesh = cape_box
		cape.material_override = armor_mat
		cape.position = Vector3(0, -0.06, -0.17)
		cape.rotation_degrees.x = 8.0
		torso.add_child(cape)

	# --- 2. HEAD & HELMET ---
	head = Node3D.new()
	head.name = "Head"
	head.position = base_head_pos
	rig_root.add_child(head)
	
	var head_mesh = MeshInstance3D.new()
	var sphere_h = SphereMesh.new()
	sphere_h.radius = 0.2
	sphere_h.height = 0.38
	head_mesh.mesh = sphere_h
	head_mesh.material_override = body_mat
	head.add_child(head_mesh)
	
	# Helmet / Cowl
	var helm_mesh = MeshInstance3D.new()
	var sphere_helm = SphereMesh.new()
	sphere_helm.radius = 0.23
	sphere_helm.height = 0.4
	helm_mesh.mesh = sphere_helm
	helm_mesh.material_override = armor_mat
	helm_mesh.position = Vector3(0, 0.04, -0.02)
	head.add_child(helm_mesh)
	
	# Eye Visor / Face Guard
	var visor_mesh = MeshInstance3D.new()
	var box_v = BoxMesh.new()
	box_v.size = Vector3(0.24, 0.08, 0.14)
	visor_mesh.mesh = box_v
	visor_mesh.material_override = visor_mat
	visor_mesh.position = Vector3(0, 0.02, 0.16)
	head.add_child(visor_mesh)

	if is_caveman:
		if "Chieftain" in u_name:
			# Massive Mammoth Tusk Skull Crown with Ivory Tusks
			for side in [-1.0, 1.0]:
				var tusk = MeshInstance3D.new()
				var cyl_t = CylinderMesh.new()
				cyl_t.top_radius = 0.02
				cyl_t.bottom_radius = 0.07
				cyl_t.height = 0.55
				tusk.mesh = cyl_t
				tusk.material_override = visor_mat
				tusk.position = Vector3(side * 0.22, 0.12, 0.18)
				tusk.rotation_degrees = Vector3(35.0, side * 18.0, side * -32.0)
				head.add_child(tusk)
			var crest_bone = MeshInstance3D.new()
			var cb_box = BoxMesh.new()
			cb_box.size = Vector3(0.12, 0.22, 0.28)
			crest_bone.mesh = cb_box
			crest_bone.material_override = visor_mat
			crest_bone.position = Vector3(0, 0.26, 0.0)
			head.add_child(crest_bone)
		else:
			# Wild Shaggy Hair Mane & Browband
			var hair = MeshInstance3D.new()
			var hair_box = BoxMesh.new()
			hair_box.size = Vector3(0.42, 0.36, 0.42)
			hair.mesh = hair_box
			hair.material_override = armor_mat
			hair.position = Vector3(0, 0.08, -0.04)
			head.add_child(hair)
			var headband = MeshInstance3D.new()
			var hb_box = BoxMesh.new()
			hb_box.size = Vector3(0.44, 0.06, 0.44)
			headband.mesh = hb_box
			headband.material_override = weapon_mat
			headband.position = Vector3(0, 0.04, 0.0)
			head.add_child(headband)
	elif is_feudal:
		if "Knight" in u_name:
			# Steel Great Helm (Bucket Helm) with Cross-Slit Visor
			var bucket = MeshInstance3D.new()
			var b_cyl = CylinderMesh.new()
			b_cyl.top_radius = 0.24
			b_cyl.bottom_radius = 0.23
			b_cyl.height = 0.46
			bucket.mesh = b_cyl
			bucket.material_override = armor_mat
			bucket.position = Vector3(0, 0.06, 0.0)
			head.add_child(bucket)
			# Brass Cross Visor Plate
			var h_slit = MeshInstance3D.new()
			var hs_box = BoxMesh.new()
			hs_box.size = Vector3(0.32, 0.04, 0.04)
			h_slit.mesh = hs_box
			h_slit.material_override = visor_mat
			h_slit.position = Vector3(0, 0.05, 0.23)
			head.add_child(h_slit)
			var v_slit = MeshInstance3D.new()
			var vs_box = BoxMesh.new()
			vs_box.size = Vector3(0.06, 0.24, 0.04)
			v_slit.mesh = vs_box
			v_slit.material_override = visor_mat
			v_slit.position = Vector3(0, 0.05, 0.23)
			head.add_child(v_slit)
		elif "Commander" in u_name:
			# Royal Golden Crown with Fleur-de-lis Spikes
			var crown_ring = MeshInstance3D.new()
			var cr_tor = TorusMesh.new()
			cr_tor.inner_radius = 0.20
			cr_tor.outer_radius = 0.26
			crown_ring.mesh = cr_tor
			crown_ring.material_override = visor_mat
			crown_ring.position = Vector3(0, 0.20, 0.0)
			head.add_child(crown_ring)
			for i in range(4):
				var spike = MeshInstance3D.new()
				var sp_cyl = CylinderMesh.new()
				sp_cyl.top_radius = 0.01
				sp_cyl.bottom_radius = 0.04
				sp_cyl.height = 0.16
				spike.mesh = sp_cyl
				spike.material_override = visor_mat
				var a = i * PI / 2.0
				spike.position = Vector3(cos(a) * 0.22, 0.30, sin(a) * 0.22)
				head.add_child(spike)
		elif "Squire" in u_name:
			# Iron Kettle Hat with Flared Brim
			var kettle_brim = MeshInstance3D.new()
			var kb_cyl = CylinderMesh.new()
			kb_cyl.top_radius = 0.32
			kb_cyl.bottom_radius = 0.34
			kb_cyl.height = 0.04
			kettle_brim.mesh = kb_cyl
			kettle_brim.material_override = armor_mat
			kettle_brim.position = Vector3(0, 0.12, 0.0)
			head.add_child(kettle_brim)
		elif "Builder" in u_name:
			# Peasant Working Cowl / Cap
			var cowl = MeshInstance3D.new()
			var c_box = BoxMesh.new()
			c_box.size = Vector3(0.38, 0.22, 0.40)
			cowl.mesh = c_box
			cowl.material_override = body_mat
			cowl.position = Vector3(0, 0.10, -0.04)
			head.add_child(cowl)
	elif is_beast_speaker:
		# Curved Primal Beast Horns on the Skull Helm
		for side in [-1.0, 1.0]:
			var horn = MeshInstance3D.new()
			var cyl_h = CylinderMesh.new()
			cyl_h.top_radius = 0.02
			cyl_h.bottom_radius = 0.07
			cyl_h.height = 0.42
			horn.mesh = cyl_h
			horn.material_override = armor_mat
			horn.position = Vector3(side * 0.20, 0.18, 0.04)
			horn.rotation_degrees = Vector3(-25.0, 0.0, side * -38.0)
			head.add_child(horn)
	elif is_rimworlder:
		# Wide-brimmed Frontier Duster Hat
		var brim = MeshInstance3D.new()
		var cyl_brim = CylinderMesh.new()
		cyl_brim.top_radius = 0.36
		cyl_brim.bottom_radius = 0.38
		cyl_brim.height = 0.04
		brim.mesh = cyl_brim
		brim.material_override = body_mat
		brim.position = Vector3(0, 0.14, 0.0)
		head.add_child(brim)
	elif is_commander:
		# Regal Command Crest Fin
		var crest = MeshInstance3D.new()
		var box_cr = BoxMesh.new()
		box_cr.size = Vector3(0.06, 0.16, 0.32)
		crest.mesh = box_cr
		crest.material_override = visor_mat
		crest.position = Vector3(0, 0.24, 0.0)
		head.add_child(crest)

	# --- 3. LEFT ARM (SHOULDER PIVOT) ---
	left_arm_pivot = Node3D.new()
	left_arm_pivot.name = "LeftArmPivot"
	left_arm_pivot.position = base_left_arm_pos
	rig_root.add_child(left_arm_pivot)

	# Left Shoulder Socket Joint connecting into torso
	var left_shoulder_joint = MeshInstance3D.new()
	var sph_ls = SphereMesh.new()
	sph_ls.radius = 0.115
	sph_ls.height = 0.23
	left_shoulder_joint.mesh = sph_ls
	left_shoulder_joint.material_override = armor_mat
	left_shoulder_joint.position = Vector3(0.03, 0.0, 0.0)
	left_arm_pivot.add_child(left_shoulder_joint)
	
	left_arm_mesh = MeshInstance3D.new()
	var cyl_la = CapsuleMesh.new()
	cyl_la.radius = 0.09
	cyl_la.height = 0.55
	left_arm_mesh.mesh = cyl_la
	left_arm_mesh.material_override = body_mat
	left_arm_mesh.position = Vector3(0, -0.25, 0)
	left_arm_pivot.add_child(left_arm_mesh)

	# Left Gauntlet / Hand
	var left_hand = MeshInstance3D.new()
	var sph_lh = SphereMesh.new()
	sph_lh.radius = 0.085
	sph_lh.height = 0.17
	left_hand.mesh = sph_lh
	left_hand.material_override = weapon_mat
	left_hand.position = Vector3(0, -0.48, 0.03)
	left_arm_pivot.add_child(left_hand)
	
	# Shoulder pauldron
	var left_pad = MeshInstance3D.new()
	var box_lp = BoxMesh.new()
	box_lp.size = Vector3(0.26, 0.22, 0.28) if "ArmoredInfantry" in u_name else Vector3(0.18, 0.16, 0.2)
	left_pad.mesh = box_lp
	left_pad.material_override = armor_mat
	left_pad.position = Vector3(0, 0.04, 0)
	left_arm_pivot.add_child(left_pad)

	if "Knight" in u_name:
		# Medieval Feudal Heater Shield strapped to Left Arm
		var shield = MeshInstance3D.new()
		shield.name = "LeftHeaterShield"
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.48, 0.72, 0.06)
		shield.mesh = s_box
		shield.material_override = armor_mat
		shield.position = Vector3(-0.08, -0.32, 0.18)
		shield.rotation_degrees = Vector3(80.0, 18.0, 0.0)
		left_arm_pivot.add_child(shield)

		# Golden Heraldic Cross on front of shield
		var s_cross_v = MeshInstance3D.new()
		var scv_box = BoxMesh.new()
		scv_box.size = Vector3(0.10, 0.56, 0.02)
		s_cross_v.mesh = scv_box
		s_cross_v.material_override = visor_mat
		s_cross_v.position = Vector3(-0.08, -0.32, 0.22)
		s_cross_v.rotation_degrees = Vector3(80.0, 18.0, 0.0)
		left_arm_pivot.add_child(s_cross_v)
	elif "Squire" in u_name or ("Commander" in u_name and is_feudal):
		# Round Iron Buckler Shield
		var buckler = MeshInstance3D.new()
		buckler.name = "LeftBuckler"
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.24
		b_cyl.bottom_radius = 0.22
		b_cyl.height = 0.05
		buckler.mesh = b_cyl
		buckler.material_override = armor_mat
		buckler.position = Vector3(-0.06, -0.32, 0.16)
		buckler.rotation_degrees = Vector3(75.0, 20.0, 0.0)
		left_arm_pivot.add_child(buckler)
		var boss = MeshInstance3D.new()
		var b_sph = SphereMesh.new()
		b_sph.radius = 0.07; b_sph.height = 0.08
		boss.mesh = b_sph
		boss.material_override = visor_mat
		boss.position = Vector3(-0.06, -0.32, 0.20)
		left_arm_pivot.add_child(boss)
	elif "Spearman" in u_name:
		# Primal Round Rawhide Shield
		var tribal_shield = MeshInstance3D.new()
		tribal_shield.name = "LeftTribalShield"
		var ts_cyl = CylinderMesh.new()
		ts_cyl.top_radius = 0.28
		ts_cyl.bottom_radius = 0.26
		ts_cyl.height = 0.05
		tribal_shield.mesh = ts_cyl
		tribal_shield.material_override = armor_mat
		tribal_shield.position = Vector3(-0.06, -0.32, 0.16)
		tribal_shield.rotation_degrees = Vector3(75.0, 20.0, 0.0)
		left_arm_pivot.add_child(tribal_shield)
	elif "RockThrower" in u_name:
		# Secondary throwing stone gripped in left hand
		var left_rock = MeshInstance3D.new()
		var lr_sph = SphereMesh.new()
		lr_sph.radius = 0.12; lr_sph.height = 0.20; lr_sph.radial_segments = 6; lr_sph.rings = 4
		left_rock.mesh = lr_sph
		left_rock.material_override = weapon_mat
		left_rock.position = Vector3(0, -0.32, 0.08)
		left_arm_pivot.add_child(left_rock)
	elif "ShieldInfantry" in u_name or ("Commander" in u_name and is_reach):
		# Forearm clamp bracket + Left-arm mounted hardlight buckler emitter
		var buckler_brace = MeshInstance3D.new()
		var bb_box = BoxMesh.new()
		bb_box.size = Vector3(0.14, 0.14, 0.20)
		buckler_brace.mesh = bb_box
		buckler_brace.material_override = armor_mat
		buckler_brace.position = Vector3(-0.04, -0.34, 0.10)
		left_arm_pivot.add_child(buckler_brace)

		var buckler = MeshInstance3D.new()
		buckler.name = "LeftShieldBuckler"
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.28
		b_cyl.bottom_radius = 0.24
		b_cyl.height = 0.06
		buckler.mesh = b_cyl
		buckler.material_override = visor_mat
		buckler.position = Vector3(-0.06, -0.34, 0.18)
		buckler.rotation_degrees = Vector3(75.0, 20.0, 0.0)
		left_arm_pivot.add_child(buckler)

	# --- 4. RIGHT ARM (SHOULDER PIVOT & WEAPON) ---
	right_arm_pivot = Node3D.new()
	right_arm_pivot.name = "RightArmPivot"
	right_arm_pivot.position = base_right_arm_pos
	rig_root.add_child(right_arm_pivot)

	# Right Shoulder Socket Joint connecting into torso
	var right_shoulder_joint = MeshInstance3D.new()
	var sph_rs = SphereMesh.new()
	sph_rs.radius = 0.115
	sph_rs.height = 0.23
	right_shoulder_joint.mesh = sph_rs
	right_shoulder_joint.material_override = armor_mat
	right_shoulder_joint.position = Vector3(-0.03, 0.0, 0.0)
	right_arm_pivot.add_child(right_shoulder_joint)
	
	right_arm_mesh = MeshInstance3D.new()
	var cyl_ra = CapsuleMesh.new()
	cyl_ra.radius = 0.09
	cyl_ra.height = 0.55
	right_arm_mesh.mesh = cyl_ra
	right_arm_mesh.material_override = body_mat
	right_arm_mesh.position = Vector3(0, -0.25, 0)
	right_arm_pivot.add_child(right_arm_mesh)

	# Right Gauntlet / Hand gripping weapon
	var right_hand = MeshInstance3D.new()
	var sph_rh = SphereMesh.new()
	sph_rh.radius = 0.088
	sph_rh.height = 0.175
	right_hand.mesh = sph_rh
	right_hand.material_override = weapon_mat
	right_hand.position = Vector3(0, -0.46, 0.05)
	right_arm_pivot.add_child(right_hand)
	
	# Shoulder pauldron
	var right_pad = MeshInstance3D.new()
	var box_rp = BoxMesh.new()
	box_rp.size = Vector3(0.26, 0.22, 0.28) if "ArmoredInfantry" in u_name else Vector3(0.18, 0.16, 0.2)
	right_pad.mesh = box_rp
	right_pad.material_override = armor_mat
	right_pad.position = Vector3(0, 0.04, 0)
	right_arm_pivot.add_child(right_pad)
	
	if "Knight" in u_name:
		# Flared Chivalric Steel Spaulders
		var l_spaulder = MeshInstance3D.new()
		var ls_box = BoxMesh.new(); ls_box.size = Vector3(0.24, 0.16, 0.28)
		l_spaulder.mesh = ls_box; l_spaulder.material_override = armor_mat; l_spaulder.position = Vector3(0.02, 0.08, 0.0)
		left_arm_pivot.add_child(l_spaulder)
		var r_spaulder = MeshInstance3D.new()
		var rs_box = BoxMesh.new(); rs_box.size = Vector3(0.24, 0.16, 0.28)
		r_spaulder.mesh = rs_box; r_spaulder.material_override = armor_mat; r_spaulder.position = Vector3(-0.02, 0.08, 0.0)
		right_arm_pivot.add_child(r_spaulder)
	
	# --- WEAPON IN HAND ---
	weapon_node = Node3D.new()
	weapon_node.name = "EquippedWeapon"
	weapon_node.position = Vector3(0, -0.46, 0.08)
	right_arm_pivot.add_child(weapon_node)
	
	_build_weapon(weapon_node, u_name, weapon_mat, visor_mat)

	# --- 5. LEFT LEG (HIP PIVOT & BOOT) ---
	left_leg_pivot = Node3D.new()
	left_leg_pivot.name = "LeftLegPivot"
	left_leg_pivot.position = base_left_leg_pos
	rig_root.add_child(left_leg_pivot)

	var left_hip = MeshInstance3D.new()
	var sph_lh_joint = SphereMesh.new()
	sph_lh_joint.radius = 0.105
	sph_lh_joint.height = 0.21
	left_hip.mesh = sph_lh_joint
	left_hip.material_override = armor_mat
	left_leg_pivot.add_child(left_hip)
	
	left_leg_mesh = MeshInstance3D.new()
	var cyl_ll = CapsuleMesh.new()
	cyl_ll.radius = 0.1
	cyl_ll.height = 0.6
	left_leg_mesh.mesh = cyl_ll
	left_leg_mesh.material_override = body_mat
	left_leg_mesh.position = Vector3(0, -0.28, 0)
	left_leg_pivot.add_child(left_leg_mesh)
	
	# Left Boot
	var left_boot = MeshInstance3D.new()
	var box_lb = BoxMesh.new()
	box_lb.size = Vector3(0.18, 0.16, 0.28)
	left_boot.mesh = box_lb
	left_boot.material_override = weapon_mat
	left_boot.position = Vector3(0, -0.52, 0.05)
	left_leg_pivot.add_child(left_boot)

	# --- 6. RIGHT LEG (HIP PIVOT & BOOT) ---
	right_leg_pivot = Node3D.new()
	right_leg_pivot.name = "RightLegPivot"
	right_leg_pivot.position = base_right_leg_pos
	rig_root.add_child(right_leg_pivot)

	var right_hip = MeshInstance3D.new()
	var sph_rh_joint = SphereMesh.new()
	sph_rh_joint.radius = 0.105
	sph_rh_joint.height = 0.21
	right_hip.mesh = sph_rh_joint
	right_hip.material_override = armor_mat
	right_leg_pivot.add_child(right_hip)
	
	right_leg_mesh = MeshInstance3D.new()
	var cyl_rl = CapsuleMesh.new()
	cyl_rl.radius = 0.1
	cyl_rl.height = 0.6
	right_leg_mesh.mesh = cyl_rl
	right_leg_mesh.material_override = body_mat
	right_leg_mesh.position = Vector3(0, -0.28, 0)
	right_leg_pivot.add_child(right_leg_mesh)
	
	# Right Boot
	var right_boot = MeshInstance3D.new()
	var box_rb = BoxMesh.new()
	box_rb.size = Vector3(0.18, 0.16, 0.28)
	right_boot.mesh = box_rb
	right_boot.material_override = weapon_mat
	right_boot.position = Vector3(0, -0.52, 0.05)
	right_leg_pivot.add_child(right_boot)
	
	if "Knight" in u_name:
		# Steel Plate Greaves on shins
		var l_greave = MeshInstance3D.new()
		var lg_box = BoxMesh.new(); lg_box.size = Vector3(0.22, 0.38, 0.22)
		l_greave.mesh = lg_box; l_greave.material_override = armor_mat; l_greave.position = Vector3(0, -0.32, 0.02)
		left_leg_pivot.add_child(l_greave)
		var r_greave = MeshInstance3D.new()
		var rg_box = BoxMesh.new(); rg_box.size = Vector3(0.22, 0.38, 0.22)
		r_greave.mesh = rg_box; r_greave.material_override = armor_mat; r_greave.position = Vector3(0, -0.32, 0.02)
		right_leg_pivot.add_child(r_greave)

func _build_weapon(w_root: Node3D, u_name: String, w_mat: Material, energy_mat: Material):
	var w_mesh = MeshInstance3D.new()
	
	# Universal Pistol Grip / Hilt Socket connecting hand (0, 0, -0.02) into weapon body
	var grip_mount = MeshInstance3D.new()
	var grip_box = BoxMesh.new()
	grip_box.size = Vector3(0.06, 0.15, 0.08)
	grip_mount.mesh = grip_box
	grip_mount.material_override = w_mat
	grip_mount.position = Vector3(0, -0.02, 0.0)
	grip_mount.rotation_degrees.x = 15.0
	w_root.add_child(grip_mount)
	
	if "Crossbowman" in u_name:
		# Medieval Crossbow: Wooden tiller stock, transverse bow prod, iron stirrup & quarrel bolt
		var stock = BoxMesh.new()
		stock.size = Vector3(0.08, 0.10, 0.76)
		w_mesh.mesh = stock
		w_mesh.material_override = w_mat
		w_mesh.position = Vector3(0, 0.04, 0.28)
		w_root.add_child(w_mesh)
		# Bow Prod (Transverse Limb)
		var prod = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.68, 0.04, 0.06)
		prod.mesh = p_box
		prod.material_override = energy_mat
		prod.position = Vector3(0, 0.05, 0.60)
		w_root.add_child(prod)
		# Iron Stirrup
		var stirrup = MeshInstance3D.new()
		var st_tor = TorusMesh.new()
		st_tor.inner_radius = 0.06; st_tor.outer_radius = 0.09
		stirrup.mesh = st_tor
		stirrup.material_override = energy_mat
		stirrup.position = Vector3(0, 0.05, 0.68)
		stirrup.rotation_degrees.x = 90.0
		w_root.add_child(stirrup)
		# Loaded Crossbow Bolt
		var bolt = MeshInstance3D.new()
		var bl_cyl = CylinderMesh.new()
		bl_cyl.top_radius = 0.015; bl_cyl.bottom_radius = 0.015; bl_cyl.height = 0.45
		bolt.mesh = bl_cyl
		bolt.material_override = energy_mat
		bolt.rotation_degrees.x = 90.0
		bolt.position = Vector3(0, 0.09, 0.42)
		w_root.add_child(bolt)
	elif "ShortBow" in u_name:
		# Primal Curved Short Bow & Notched Arrow
		var bow_stave = MeshInstance3D.new()
		var b_tor = TorusMesh.new()
		b_tor.inner_radius = 0.38; b_tor.outer_radius = 0.42
		bow_stave.mesh = b_tor
		bow_stave.material_override = w_mat
		bow_stave.position = Vector3(0, 0.06, 0.32)
		bow_stave.rotation_degrees = Vector3(0.0, 90.0, 0.0)
		w_root.add_child(bow_stave)
		# Notched Flint Arrow
		var arrow = MeshInstance3D.new()
		var a_cyl = CylinderMesh.new()
		a_cyl.top_radius = 0.012; a_cyl.bottom_radius = 0.012; a_cyl.height = 0.65
		arrow.mesh = a_cyl
		arrow.material_override = energy_mat
		arrow.rotation_degrees.x = 90.0
		arrow.position = Vector3(0, 0.06, 0.32)
		w_root.add_child(arrow)
	elif "RockThrower" in u_name:
		# Primal Heavy Throwing Boulder gripped in hand
		var rock = SphereMesh.new()
		rock.radius = 0.16; rock.height = 0.28; rock.radial_segments = 6; rock.rings = 4
		w_mesh.mesh = rock
		w_mesh.material_override = w_mat
		w_mesh.position = Vector3(0, 0.06, 0.18)
		w_root.add_child(w_mesh)
	elif "Spearman" in u_name:
		# Primal Long Flint Spear
		var shaft = CylinderMesh.new()
		shaft.top_radius = 0.024; shaft.bottom_radius = 0.024; shaft.height = 1.85
		w_mesh.mesh = shaft
		w_mesh.material_override = w_mat
		w_mesh.rotation_degrees.x = 24.0
		w_mesh.position = Vector3(0, 0.32, 0.24)
		w_root.add_child(w_mesh)
		# Flint Spearhead
		var spearhead = MeshInstance3D.new()
		var sh_cyl = CylinderMesh.new()
		sh_cyl.top_radius = 0.005; sh_cyl.bottom_radius = 0.055; sh_cyl.height = 0.32
		spearhead.mesh = sh_cyl
		spearhead.material_override = energy_mat
		spearhead.rotation_degrees.x = 24.0
		spearhead.position = Vector3(0, 1.15, 0.60)
		w_root.add_child(spearhead)
	elif "Clubber" in u_name:
		# Knotty Spiked Primal Club
		var club = CylinderMesh.new()
		club.top_radius = 0.09; club.bottom_radius = 0.035; club.height = 0.95
		w_mesh.mesh = club
		w_mesh.material_override = w_mat
		w_mesh.rotation_degrees.x = 30.0
		w_mesh.position = Vector3(0, 0.18, 0.35)
		w_root.add_child(w_mesh)
		# Stone Spikes
		for side in [-1.0, 1.0]:
			var spike = MeshInstance3D.new()
			var spk_box = BoxMesh.new()
			spk_box.size = Vector3(0.04, 0.04, 0.18)
			spike.mesh = spk_box
			spike.material_override = energy_mat
			spike.position = Vector3(side * 0.08, 0.35, 0.50)
			w_root.add_child(spike)
	elif "Chieftain" in u_name:
		# Colossal Primal Bone Cleaver / Great Stone Axe
		var handle = CylinderMesh.new()
		handle.top_radius = 0.04; handle.bottom_radius = 0.04; handle.height = 1.55
		w_mesh.mesh = handle
		w_mesh.material_override = w_mat
		w_mesh.rotation_degrees.x = 20.0
		w_mesh.position = Vector3(0, 0.28, 0.20)
		w_root.add_child(w_mesh)
		# Giant Flint Blade
		var blade = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.08, 0.48, 0.36)
		blade.mesh = b_box
		blade.material_override = energy_mat
		blade.rotation_degrees.x = 20.0
		blade.position = Vector3(0, 0.88, 0.42)
		w_root.add_child(blade)
	elif "CavemanBuilder" in u_name:
		# Heavy Stone Mallet
		var haft = CylinderMesh.new()
		haft.top_radius = 0.035; haft.bottom_radius = 0.035; haft.height = 1.10
		w_mesh.mesh = haft
		w_mesh.material_override = w_mat
		w_mesh.rotation_degrees.x = 25.0
		w_mesh.position = Vector3(0, 0.20, 0.25)
		w_root.add_child(w_mesh)
		var stone_head = MeshInstance3D.new()
		var sh_box = BoxMesh.new()
		sh_box.size = Vector3(0.24, 0.22, 0.35)
		stone_head.mesh = sh_box
		stone_head.material_override = energy_mat
		stone_head.rotation_degrees.x = 25.0
		stone_head.position = Vector3(0, 0.65, 0.45)
		w_root.add_child(stone_head)
	elif "Builder" in u_name and "Primitive" in u_name:
		# Medieval Construction Worker Utility Knife in hand & Framing Hammer
		var knife_blade = BoxMesh.new()
		knife_blade.size = Vector3(0.03, 0.08, 0.52)
		w_mesh.mesh = knife_blade
		w_mesh.material_override = energy_mat
		w_mesh.position = Vector3(0, 0.02, 0.26)
		w_root.add_child(w_mesh)
		var knife_guard = MeshInstance3D.new()
		var kg_box = BoxMesh.new()
		kg_box.size = Vector3(0.14, 0.03, 0.05)
		knife_guard.mesh = kg_box
		knife_guard.material_override = energy_mat
		knife_guard.position = Vector3(0, 0.02, 0.04)
		w_root.add_child(knife_guard)
		# Framing Hammer at hip
		var hammer = MeshInstance3D.new()
		var h_cyl = CylinderMesh.new()
		h_cyl.top_radius = 0.02; h_cyl.bottom_radius = 0.02; h_cyl.height = 0.45
		hammer.mesh = h_cyl
		hammer.material_override = w_mat
		hammer.rotation_degrees.z = 45.0
		hammer.position = Vector3(0.12, -0.10, 0.05)
		w_root.add_child(hammer)
	elif "Commander" in u_name and "Primitive" in u_name:
		# Regal Royal Broadsword with Gilded Crossguard and Pommel
		var royal_blade = BoxMesh.new()
		royal_blade.size = Vector3(0.045, 0.14, 1.25)
		w_mesh.mesh = royal_blade
		w_mesh.material_override = energy_mat
		w_mesh.position = Vector3(0, 0.02, 0.62)
		w_root.add_child(w_mesh)
		var royal_guard = MeshInstance3D.new()
		var rg_box = BoxMesh.new()
		rg_box.size = Vector3(0.42, 0.06, 0.07)
		royal_guard.mesh = rg_box
		royal_guard.material_override = energy_mat
		royal_guard.position = Vector3(0, 0.02, 0.06)
		w_root.add_child(royal_guard)
		var royal_pommel = MeshInstance3D.new()
		var rp_sph = SphereMesh.new()
		rp_sph.radius = 0.06; rp_sph.height = 0.08
		royal_pommel.mesh = rp_sph
		royal_pommel.material_override = energy_mat
		royal_pommel.position = Vector3(0, 0.02, -0.14)
		w_root.add_child(royal_pommel)
	elif "Knight" in u_name:
		# Medieval Chivalric Arming Sword with Wide Steel Crossguard
		var blade = BoxMesh.new()
		blade.size = Vector3(0.04, 0.12, 1.15)
		w_mesh.mesh = blade
		w_mesh.material_override = energy_mat
		w_mesh.position = Vector3(0, 0.02, 0.58)
		w_root.add_child(w_mesh)
		var crossguard = MeshInstance3D.new()
		var cg_box = BoxMesh.new()
		cg_box.size = Vector3(0.38, 0.05, 0.06)
		crossguard.mesh = cg_box
		crossguard.material_override = energy_mat
		crossguard.position = Vector3(0, 0.02, 0.06)
		w_root.add_child(crossguard)
		var pommel = MeshInstance3D.new()
		var p_sph = SphereMesh.new()
		p_sph.radius = 0.05; p_sph.height = 0.06
		pommel.mesh = p_sph
		pommel.material_override = energy_mat
		pommel.position = Vector3(0, 0.02, -0.12)
		w_root.add_child(pommel)
	elif "Squire" in u_name:
		# Feudal Short Sword / Arming Blade
		var blade = BoxMesh.new()
		blade.size = Vector3(0.035, 0.10, 0.85)
		w_mesh.mesh = blade
		w_mesh.material_override = energy_mat
		w_mesh.position = Vector3(0, 0.02, 0.44)
		w_root.add_child(w_mesh)
		var crossguard = MeshInstance3D.new()
		var cg_box = BoxMesh.new()
		cg_box.size = Vector3(0.26, 0.04, 0.05)
		crossguard.mesh = cg_box
		crossguard.material_override = energy_mat
		crossguard.position = Vector3(0, 0.02, 0.05)
		w_root.add_child(crossguard)
	elif "GreatBeastSpeaker" in u_name:
		# Tall Shamanic Bone-Totem Staff with bone cradle & glowing emerald beast crystal
		var staff = CylinderMesh.new()
		staff.top_radius = 0.048
		staff.bottom_radius = 0.036
		staff.height = 1.65
		w_mesh.mesh = staff
		w_mesh.material_override = w_mat
		w_mesh.rotation_degrees.x = 18.0
		w_mesh.position = Vector3(0, 0.25, 0.06)
		w_root.add_child(w_mesh)

		var cradle = MeshInstance3D.new()
		var c_tor = TorusMesh.new()
		c_tor.inner_radius = 0.08
		c_tor.outer_radius = 0.14
		cradle.mesh = c_tor
		cradle.material_override = w_mat
		cradle.position = Vector3(0, 0.94, 0.28)
		cradle.rotation_degrees.x = 18.0
		w_root.add_child(cradle)

		var totem_orb = MeshInstance3D.new()
		var sph = SphereMesh.new()
		sph.radius = 0.14
		sph.height = 0.28
		totem_orb.mesh = sph
		totem_orb.material_override = energy_mat
		totem_orb.position = Vector3(0, 1.02, 0.30)
		w_root.add_child(totem_orb)
	elif "Sniper" in u_name or "ReachRanged" in u_name or "ScrapRanged" in u_name:
		# Long-barreled sniper rifle with stock & scope Mount
		var rifle_body = BoxMesh.new()
		rifle_body.size = Vector3(0.08, 0.12, 1.15)
		w_mesh.mesh = rifle_body
		w_mesh.material_override = w_mat
		w_mesh.position = Vector3(0, 0.02, 0.28)
		w_root.add_child(w_mesh)
		
		var scope_mount = MeshInstance3D.new()
		var sm_box = BoxMesh.new()
		sm_box.size = Vector3(0.05, 0.06, 0.22)
		scope_mount.mesh = sm_box
		scope_mount.material_override = w_mat
		scope_mount.position = Vector3(0, 0.08, 0.14)
		w_root.add_child(scope_mount)

		var scope = MeshInstance3D.new()
		var cyl_s = CylinderMesh.new()
		cyl_s.top_radius = 0.035
		cyl_s.bottom_radius = 0.035
		cyl_s.height = 0.35
		scope.mesh = cyl_s
		scope.rotation.x = deg_to_rad(90.0)
		scope.position = Vector3(0, 0.12, 0.14)
		scope.material_override = energy_mat
		w_root.add_child(scope)
	elif "Rocket" in u_name:
		# Shoulder rocket tube + vertical hand-grip strut connecting down to right hand
		var r_strut = MeshInstance3D.new()
		var rs_box = BoxMesh.new()
		rs_box.size = Vector3(0.06, 0.30, 0.08)
		r_strut.mesh = rs_box
		r_strut.material_override = w_mat
		r_strut.position = Vector3(0.02, 0.12, 0.04)
		w_root.add_child(r_strut)

		var tube = CylinderMesh.new()
		tube.top_radius = 0.12
		tube.bottom_radius = 0.12
		tube.height = 1.2
		w_mesh.mesh = tube
		w_mesh.material_override = w_mat
		w_mesh.rotation.x = deg_to_rad(90.0)
		w_mesh.position = Vector3(0.04, 0.26, 0.1)
		w_root.add_child(w_mesh)
	elif "Medic" in u_name or "Repair" in u_name:
		# Medical Injector or Wrench
		var tool_box = BoxMesh.new()
		tool_box.size = Vector3(0.1, 0.18, 0.48)
		w_mesh.mesh = tool_box
		w_mesh.material_override = w_mat
		w_mesh.position = Vector3(0, 0.02, 0.12)
		w_root.add_child(w_mesh)
		
		var tip = MeshInstance3D.new()
		var tip_mesh = CylinderMesh.new()
		tip_mesh.top_radius = 0.02
		tip_mesh.bottom_radius = 0.05
		tip_mesh.height = 0.25
		tip.mesh = tip_mesh
		tip.rotation.x = deg_to_rad(90.0)
		tip.position = Vector3(0, 0.02, 0.42)
		tip.material_override = energy_mat
		w_root.add_child(tip)
	elif "Melee" in u_name or "Commander" in u_name or "Hero" in u_name or "ShieldInfantry" in u_name or "ArmoredInfantry" in u_name:
		# Sword / Combat Blade connected directly into crossguard hilt at hand
		var blade = BoxMesh.new()
		blade.size = Vector3(0.04, 0.14, 0.95)
		w_mesh.mesh = blade
		w_mesh.material_override = energy_mat
		w_mesh.position = Vector3(0, 0.02, 0.48)
		w_root.add_child(w_mesh)
		
		var hilt = MeshInstance3D.new()
		var hilt_mesh = BoxMesh.new()
		hilt_mesh.size = Vector3(0.10, 0.30, 0.08)
		hilt.mesh = hilt_mesh
		hilt.material_override = w_mat
		hilt.position = Vector3(0, 0.02, 0.04)
		w_root.add_child(hilt)
	elif "Hunter" in u_name or "Assassin" in u_name:
		# Combat dagger with hilt in hand
		var dagger = BoxMesh.new()
		dagger.size = Vector3(0.04, 0.08, 0.58)
		w_mesh.mesh = dagger
		w_mesh.material_override = energy_mat
		w_mesh.position = Vector3(0, 0.02, 0.26)
		w_root.add_child(w_mesh)
	else:
		# Combat Assault Rifle / Carbine with stock and connected barrel
		var gun = BoxMesh.new()
		gun.size = Vector3(0.08, 0.13, 0.68)
		w_mesh.mesh = gun
		w_mesh.material_override = w_mat
		w_mesh.position = Vector3(0, 0.02, 0.18)
		w_root.add_child(w_mesh)
		
		var barrel = MeshInstance3D.new()
		var bar_mesh = CylinderMesh.new()
		bar_mesh.top_radius = 0.025
		bar_mesh.bottom_radius = 0.028
		bar_mesh.height = 0.32
		barrel.mesh = bar_mesh
		barrel.rotation.x = deg_to_rad(90.0)
		barrel.position = Vector3(0, 0.03, 0.56)
		barrel.material_override = w_mat
		w_root.add_child(barrel)

func animate(delta: float, is_moving: bool, is_critically_wounded: bool, move_speed: float):
	if not is_active or not torso or not head or not left_arm_pivot or not right_arm_pivot or not left_leg_pivot or not right_leg_pivot: return
	
	if is_critically_wounded:
		# --- CRITICALLY WOUNDED ANATOMY STATE ---
		# Hunched forward in agony
		torso.rotation.x = deg_to_rad(24.0)
		head.rotation.x = deg_to_rad(18.0)
		
		# Left arm tightly clutching torso wound across the abdomen
		left_arm_pivot.rotation.z = deg_to_rad(45.0)
		left_arm_pivot.rotation.x = deg_to_rad(22.0)
		left_arm_pivot.rotation.y = deg_to_rad(25.0)
		
		# Right arm lower, struggling with weapon
		right_arm_pivot.rotation.x = deg_to_rad(-12.0)
		right_arm_pivot.rotation.y = deg_to_rad(-8.0)
		
		if is_moving:
			# Limping hobble gait: asymmetric dragging stride
			limp_time += delta * clamp(move_speed * 1.4, 2.0, 4.2)
			
			# Left leg drags forward heavily
			left_leg_pivot.rotation.x = sin(limp_time) * 0.52
			# Right leg hitches short and stiff
			right_leg_pivot.rotation.x = -sin(limp_time) * 0.26 + 0.12
			
			# Severe lateral limp lurch
			torso.rotation.z = sin(limp_time) * 0.14
			torso.position.y = base_torso_pos.y - 0.06 + abs(sin(limp_time)) * 0.04
			head.position.y = base_head_pos.y - 0.08 + abs(sin(limp_time)) * 0.03
		else:
			# Standing wounded: heavy pained breathing shudder
			idle_time += delta * 3.2
			torso.rotation.z = lerp(torso.rotation.z, 0.0, 8.0 * delta)
			torso.position.y = base_torso_pos.y + sin(idle_time) * 0.025
			head.position.y = base_head_pos.y + sin(idle_time) * 0.015
			left_leg_pivot.rotation = Vector3.ZERO
			right_leg_pivot.rotation = Vector3.ZERO
	else:
		# --- HEALTHY / NORMAL STATE ---
		torso.rotation.x = lerp(torso.rotation.x, 0.0, 10.0 * delta)
		torso.rotation.y = lerp(torso.rotation.y, 0.0, 10.0 * delta)
		torso.position.z = lerp(torso.position.z, base_torso_pos.z, 10.0 * delta)
		head.rotation.x = lerp(head.rotation.x, 0.0, 10.0 * delta)
		var u_name_stance: String = str(unit.name) if unit else ""
		var has_buckler: bool = "ShieldInfantry" in u_name_stance or ("Commander" in u_name_stance and "Reach" in u_name_stance)
		
		if is_moving:
			# Authentic alternating two-legged stride
			walk_time += delta * clamp(move_speed * 2.2, 3.5, 9.0)
			
			# Leg stride (left vs right alternating)
			left_leg_pivot.rotation.x = sin(walk_time) * 0.65
			right_leg_pivot.rotation.x = -sin(walk_time) * 0.65
			left_leg_pivot.rotation.z = 0.0
			right_leg_pivot.rotation.z = 0.0
			
			# Arm swing opposite legs (or held forward if bracing shield buckler)
			if has_buckler:
				left_arm_pivot.rotation.x = deg_to_rad(-48.0) + sin(walk_time) * 0.14
				left_arm_pivot.rotation.y = deg_to_rad(24.0)
				left_arm_pivot.rotation.z = deg_to_rad(10.0)
			else:
				left_arm_pivot.rotation.x = -sin(walk_time) * 0.55
				left_arm_pivot.rotation.z = deg_to_rad(-6.0)
				left_arm_pivot.rotation.y = 0.0
			
			# Right arm swings while holding weapon ready forward
			right_arm_pivot.rotation.x = deg_to_rad(-22.0) + sin(walk_time) * 0.32
			right_arm_pivot.rotation.y = deg_to_rad(-10.0)
			right_arm_pivot.rotation.z = 0.0
			
			# Torso bounce / vertical bob & sway
			torso.position.y = base_torso_pos.y + abs(sin(walk_time)) * 0.07
			torso.rotation.z = sin(walk_time) * 0.04
			head.position.y = base_head_pos.y + abs(sin(walk_time)) * 0.03
		else:
			# Standing pose: natural resting breathing stance with weapon at ready
			idle_time += delta * 2.2
			walk_time = 0.0
			
			# Gentle breathing cycle
			torso.position.y = base_torso_pos.y + sin(idle_time) * 0.022
			torso.rotation.z = lerp(torso.rotation.z, 0.0, 8.0 * delta)
			head.position.y = base_head_pos.y + sin(idle_time) * 0.014
			
			# Arms in ready standing posture
			right_arm_pivot.rotation.x = lerp(right_arm_pivot.rotation.x, deg_to_rad(-24.0), 8.0 * delta)
			right_arm_pivot.rotation.y = lerp(right_arm_pivot.rotation.y, deg_to_rad(-12.0), 8.0 * delta)
			right_arm_pivot.rotation.z = lerp(right_arm_pivot.rotation.z, 0.0, 8.0 * delta)
			
			if has_buckler:
				left_arm_pivot.rotation.x = lerp(left_arm_pivot.rotation.x, deg_to_rad(-52.0), 8.0 * delta)
				left_arm_pivot.rotation.y = lerp(left_arm_pivot.rotation.y, deg_to_rad(26.0), 8.0 * delta)
				left_arm_pivot.rotation.z = lerp(left_arm_pivot.rotation.z, deg_to_rad(12.0), 8.0 * delta)
			else:
				left_arm_pivot.rotation.x = lerp(left_arm_pivot.rotation.x, deg_to_rad(4.0), 8.0 * delta)
				left_arm_pivot.rotation.z = lerp(left_arm_pivot.rotation.z, deg_to_rad(-8.0), 8.0 * delta)
				left_arm_pivot.rotation.y = lerp(left_arm_pivot.rotation.y, 0.0, 8.0 * delta)
			
			# Stable standing stance
			left_leg_pivot.rotation.x = lerp(left_leg_pivot.rotation.x, 0.0, 8.0 * delta)
			right_leg_pivot.rotation.x = lerp(right_leg_pivot.rotation.x, 0.0, 8.0 * delta)
			left_leg_pivot.rotation.z = deg_to_rad(2.5)
			right_leg_pivot.rotation.z = deg_to_rad(-2.5)

	# --- ACTIVE ATTACK / ACTION ANIMATION OVERLAY ---
	if attack_anim_timer > 0.0:
		attack_anim_timer = max(0.0, attack_anim_timer - delta)
		var p: float = 1.0 - (attack_anim_timer / max(0.01, attack_anim_duration))
		var swing: float = sin(p * PI)
		var u_name: String = str(unit.name) if unit else ""
		if "Melee" in u_name or "Commander" in u_name or "Hero" in u_name or "Assassin" in u_name or "GreatBeastSpeaker" in u_name or "Grunt" in u_name or "Runner" in u_name or "ShieldInfantry" in u_name or "ArmoredInfantry" in u_name:
			# Dynamic melee weapon slash / staff slam
			var slash_angle: float = lerpf(-1.55, 0.65, p)
			right_arm_pivot.rotation.x = slash_angle * swing + right_arm_pivot.rotation.x * (1.0 - swing)
			right_arm_pivot.rotation.y = deg_to_rad(-28.0 * swing)
			torso.rotation.y = sin(p * PI) * 0.36
			torso.rotation.x = deg_to_rad(14.0 * swing)
			torso.position.z = base_torso_pos.z + 0.14 * swing
		elif "Medic" in u_name or "Repair" in u_name:
			# Extend medical injector / repair welder forward
			right_arm_pivot.rotation.x = deg_to_rad(-65.0 * swing)
			left_arm_pivot.rotation.x = deg_to_rad(-35.0 * swing)
			torso.rotation.x = deg_to_rad(10.0 * swing)
		else:
			# Crisp firearm / sniper / rocket recoil kick
			right_arm_pivot.rotation.x = deg_to_rad(-32.0 - 24.0 * swing)
			left_arm_pivot.rotation.x = deg_to_rad(-28.0 - 14.0 * swing)
			torso.rotation.x = deg_to_rad(-8.0 * swing)
			if weapon_node:
				weapon_node.position.z = 0.08 - 0.08 * swing
	elif weapon_node:
		weapon_node.position.z = lerpf(weapon_node.position.z, 0.08, 12.0 * delta)


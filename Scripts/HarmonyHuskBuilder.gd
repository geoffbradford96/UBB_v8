extends Node
class_name HarmonyHuskBuilder

const MELEE_HUSK_SCENES: Array[String] = [
	"res://Scenes/Units/CheapGrunt.tscn",
	"res://Scenes/Units/RimworlderMelee.tscn",
	"res://Scenes/Units/ScrapMelee.tscn",
	"res://Scenes/Units/ReachMelee.tscn",
	"res://Scenes/Units/Assassin.tscn",
	"res://Scenes/Units/HeroHunter.tscn",
	"res://Scenes/Units/ScrapHunter.tscn",
	"res://Scenes/Units/ReachHunter.tscn",
	"res://Scenes/Units/RimworlderMutant.tscn",
	"res://Scenes/Units/GiantSquid.tscn"
]

const RANGED_HUSK_SCENES: Array[String] = [
	"res://Scenes/Units/SupportingFire.tscn",
	"res://Scenes/Units/Sniper.tscn",
	"res://Scenes/Units/RocketInfantry.tscn",
	"res://Scenes/Units/RimworlderGunner.tscn",
	"res://Scenes/Units/ScrapRanged.tscn",
	"res://Scenes/Units/ReachRanged.tscn"
]

const TANK_HUSK_SCENES: Array[String] = [
	"res://Scenes/Units/Tank.tscn",
	"res://Scenes/Units/HeavyTank.tscn",
	"res://Scenes/Units/SpiderTank.tscn",
	"res://Scenes/Units/ScrapTank.tscn",
	"res://Scenes/Units/ReachTank.tscn"
]

const PLANE_HUSK_SCENES: Array[String] = [
	"res://Scenes/Units/Plane.tscn",
	"res://Scenes/Units/ScrapPlane.tscn",
	"res://Scenes/Units/ReachPlane.tscn",
	"res://Scenes/Units/SkyBeetle.tscn",
	"res://Scenes/Units/SkyJellyfish.tscn"
]

const BIG_MONSTER_HUSK_SCENES: Array[String] = [
	"res://Scenes/Units/DominionMech.tscn",
	"res://Scenes/Units/BoxyWalker.tscn",
	"res://Scenes/Units/ScrapMech.tscn",
	"res://Scenes/Units/ReachMech.tscn",
	"res://Scenes/Units/VoidSpiker.tscn",
	"res://Scenes/Units/RimworlderLeviathan.tscn",
	"res://Scenes/Units/RimworlderMonstrous.tscn",
	"res://Scenes/Units/RimworlderMutant.tscn",
	"res://Scenes/Units/GiantSquid.tscn",
	"res://Scenes/Units/StoneOctopus.tscn",
	"res://Scenes/Units/SkyJellyfish.tscn",
	"res://Scenes/Units/SkyBeetle.tscn"
]

static func get_random_husk_scene_for_category(category: String) -> String:
	var cat := category.to_upper()
	if cat == "MELEE":
		return MELEE_HUSK_SCENES[randi() % MELEE_HUSK_SCENES.size()]
	elif cat == "RANGED":
		return RANGED_HUSK_SCENES[randi() % RANGED_HUSK_SCENES.size()]
	elif cat == "TANK":
		return TANK_HUSK_SCENES[randi() % TANK_HUSK_SCENES.size()]
	elif cat == "PLANE":
		return PLANE_HUSK_SCENES[randi() % PLANE_HUSK_SCENES.size()]
	elif cat == "BIG":
		return BIG_MONSTER_HUSK_SCENES[randi() % BIG_MONSTER_HUSK_SCENES.size()]
	else:
		var all_scenes: Array[String] = []
		all_scenes.append_array(MELEE_HUSK_SCENES)
		all_scenes.append_array(RANGED_HUSK_SCENES)
		all_scenes.append_array(TANK_HUSK_SCENES)
		all_scenes.append_array(PLANE_HUSK_SCENES)
		all_scenes.append_array(BIG_MONSTER_HUSK_SCENES)
		return all_scenes[randi() % all_scenes.size()]

static func get_gold_vein_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.16)
	mat.metallic = 0.95
	mat.roughness = 0.15
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.78, 0.12)
	mat.emission_energy_multiplier = 2.8
	return mat

static func get_gilded_pale_blue_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.56, 0.88, 1.0)
	mat.metallic = 0.55
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.82, 1.0)
	mat.emission_energy_multiplier = 2.4
	return mat

static func get_gilded_dark_green_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.34, 0.18)
	mat.metallic = 0.45
	mat.roughness = 0.28
	mat.emission_enabled = true
	mat.emission = Color(0.08, 0.42, 0.22)
	mat.emission_energy_multiplier = 1.1
	return mat

static func get_husk_body_material(base_color: Color = Color(0.88, 0.86, 0.82), is_gilded: bool = false) -> StandardMaterial3D:
	if is_gilded:
		return get_gilded_dark_green_material()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color.lerp(Color(0.92, 0.89, 0.82), 0.7)
	mat.metallic = 0.35
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.35, 0.08)
	mat.emission_energy_multiplier = 0.45
	return mat

static func get_husk_armor_material(is_gilded: bool = false) -> StandardMaterial3D:
	if is_gilded:
		return get_gilded_pale_blue_material()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.22, 0.26)
	mat.metallic = 0.75
	mat.roughness = 0.25
	mat.emission_enabled = true
	mat.emission = Color(0.65, 0.48, 0.10)
	mat.emission_energy_multiplier = 0.35
	return mat

static func transform_into_husk(unit: Node3D, is_gilded: bool = false, target_team: String = "SideHarmony") -> void:
	if not is_instance_valid(unit):
		return

	unit.set_meta("is_husk_of_harmony", true)
	unit.set_meta("is_gilded_harmony", is_gilded)

	# Switch allegiance to target_team ("SideHarmony" for wild map husks, or "SideA"/"SideB" for faction husks/infectors)
	for g in unit.get_groups():
		if g.begins_with("Side") or g == "NeutralCreature" or g == "Harmony":
			unit.remove_from_group(g)

	if "team" in unit:
		unit.set("team", target_team)
	unit.add_to_group(target_team)
	unit.add_to_group("HuskOfHarmony")
	if target_team == "SideHarmony":
		unit.add_to_group("Harmony")
	if is_gilded:
		unit.add_to_group("GildedHarmony")

	if "current_target" in unit:
		unit.current_target = null

	# Clear any new allies that were previously targeting this unit before conversion
	if unit.is_inside_tree() and unit.get_tree():
		for ally in unit.get_tree().get_nodes_in_group(target_team):
			if is_instance_valid(ally) and ally != unit:
				if "current_target" in ally and ally.get("current_target") == unit:
					ally.set("current_target", null)
				if "targets_in_range" in ally and ally.get("targets_in_range") is Array:
					(ally.get("targets_in_range") as Array).erase(unit)

	# Restore health and refresh healthbar/marker colors
	var hc := unit.get_node_or_null("HealthComponent")
	if hc:
		if "max_health" in hc and "current_health" in hc:
			hc.current_health = hc.max_health
		if hc.has_method("update_health_bar_colors"):
			hc.update_health_bar_colors()
		if hc.has_method("update_ground_marker_color"):
			hc.update_ground_marker_color()

	if unit.is_inside_tree():
		_spawn_harmony_burst(unit, is_gilded)

	# Only build the 3D vein meshes once per unit
	if unit.find_child("HuskGoldVeins", true, false) == null:
		var marker_root := Node3D.new()
		marker_root.name = "HuskGoldVeins"
		unit.add_child(marker_root)
		if unit.get_node_or_null("HarmonyHuskVisuals") == null:
			var vis_marker := Node3D.new()
			vis_marker.name = "HarmonyHuskVisuals"
			unit.add_child(vis_marker)

		var h_rig := unit.get_node_or_null("HumanoidRig")
		if h_rig and h_rig.get("rig_root") != null:
			_apply_humanoid_husk_veins(h_rig, is_gilded)
		elif "Tank" in unit.name or "Spider" in unit.name:
			_apply_tank_husk_veins(unit, is_gilded)
		elif "Mech" in unit.name or "Walker" in unit.name:
			_apply_mech_husk_veins(unit, is_gilded)
		elif "Plane" in unit.name:
			_apply_plane_husk_veins(unit, is_gilded)
		else:
			_apply_generic_mesh_husk_veins(unit, is_gilded)

static func _spawn_harmony_burst(unit: Node3D, is_gilded: bool = false) -> void:
	var scene_root = unit.get_tree().current_scene if (unit.get_tree() and unit.get_tree().current_scene) else unit.get_parent()
	if not scene_root:
		return
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.6
	tm.outer_radius = 1.2
	ring.mesh = tm
	ring.material_override = get_gilded_pale_blue_material() if is_gilded else get_gold_vein_material()
	scene_root.add_child(ring)
	ring.global_position = unit.global_position + Vector3(0, 1.0, 0)
	var tw := ring.create_tween()
	if tw:
		tw.set_parallel(true)
		tw.tween_property(ring, "scale", Vector3(3.2, 1.0, 3.2), 0.55)
		tw.tween_property(ring, "position:y", ring.position.y + 1.8, 0.55)
		tw.chain().tween_callback(ring.queue_free)
	else:
		ring.queue_free()

# =========================================================================
# 1. HUMANOID RIG GOLD VEINS (Moves & animates with limbs, torso, head, gun)
# =========================================================================
static func _apply_humanoid_husk_veins(rig: Node, is_gilded: bool = false) -> void:
	var gold_mat := get_gold_vein_material()
	var accent_mat := get_gilded_pale_blue_material() if is_gilded else gold_mat
	var body_mat := get_husk_body_material(Color(0.88, 0.86, 0.82), is_gilded)
	var armor_mat := get_husk_armor_material(is_gilded)

	if rig.rig_root:
		_recolor_hierarchy_for_husk(rig.rig_root, body_mat, armor_mat, gold_mat)

	if rig.torso:
		var torso_veins := Node3D.new()
		torso_veins.name = "HuskTorsoVeins"
		rig.torso.add_child(torso_veins)

		var vein_configs := [
			{"pos": Vector3(0.0, 0.05, 0.165), "rot": Vector3(0, 0, 0.35), "h": 0.62, "r": 0.028, "mat": gold_mat},
			{"pos": Vector3(-0.12, 0.08, 0.165), "rot": Vector3(0, 0, -0.55), "h": 0.48, "r": 0.022, "mat": accent_mat},
			{"pos": Vector3(0.14, -0.04, 0.165), "rot": Vector3(0, 0, 0.65), "h": 0.45, "r": 0.022, "mat": gold_mat},
			{"pos": Vector3(0.0, 0.05, -0.165), "rot": Vector3(0, 0, -0.30), "h": 0.60, "r": 0.026, "mat": accent_mat},
			{"pos": Vector3(0.25, 0.02, 0.0), "rot": Vector3(0.25, 0, 0), "h": 0.55, "r": 0.022, "mat": gold_mat},
			{"pos": Vector3(-0.25, 0.02, 0.0), "rot": Vector3(-0.25, 0, 0), "h": 0.55, "r": 0.022, "mat": accent_mat}
		]
		for vc in vein_configs:
			_add_vein_cylinder(torso_veins, vc["pos"], vc["rot"], vc["r"], vc["h"], vc["mat"])

		var chest_face := _create_mini_gold_face(0.22, gold_mat)
		chest_face.position = Vector3(0, 0.10, 0.17)
		torso_veins.add_child(chest_face)

	if rig.head:
		var head_veins := Node3D.new()
		head_veins.name = "HuskHeadVeins"
		rig.head.add_child(head_veins)

		var halo := MeshInstance3D.new()
		var hm := TorusMesh.new()
		hm.inner_radius = 0.28
		hm.outer_radius = 0.34
		halo.mesh = hm
		halo.material_override = gold_mat
		halo.rotation.x = deg_to_rad(90.0)
		halo.position = Vector3(0, 0.12, -0.14)
		head_veins.add_child(halo)

		var head_face := _create_mini_gold_face(0.24, gold_mat)
		head_face.position = Vector3(0, 0.0, 0.21)
		head_veins.add_child(head_face)

		_add_vein_cylinder(head_veins, Vector3(0.12, 0.08, 0.12), Vector3(0.4, 0, -0.5), 0.018, 0.32, gold_mat)
		_add_vein_cylinder(head_veins, Vector3(-0.12, 0.08, 0.12), Vector3(0.4, 0, 0.5), 0.018, 0.32, accent_mat)

	for arm_pivot in [rig.left_arm_pivot, rig.right_arm_pivot]:
		if arm_pivot:
			var arm_veins := Node3D.new()
			arm_veins.name = "HuskArmVeins"
			arm_pivot.add_child(arm_veins)
			_add_vein_cylinder(arm_veins, Vector3(0, -0.24, 0.085), Vector3(0, 0, 0.22), 0.022, 0.52, gold_mat)
			_add_vein_cylinder(arm_veins, Vector3(0.06, -0.26, -0.06), Vector3(0.18, 0, -0.28), 0.018, 0.46, accent_mat)

	if rig.weapon_node:
		var w_veins := Node3D.new()
		w_veins.name = "HuskWeaponVeins"
		rig.weapon_node.add_child(w_veins)
		_add_vein_cylinder(w_veins, Vector3(0, 0.04, 0.28), Vector3(deg_to_rad(90.0), 0, 0.12), 0.02, 0.65, gold_mat)
		_add_vein_cylinder(w_veins, Vector3(0.03, -0.02, 0.25), Vector3(deg_to_rad(90.0), 0, -0.18), 0.016, 0.55, accent_mat)

	for leg_pivot in [rig.left_leg_pivot, rig.right_leg_pivot]:
		if leg_pivot:
			var leg_veins := Node3D.new()
			leg_veins.name = "HuskLegVeins"
			leg_pivot.add_child(leg_veins)
			_add_vein_cylinder(leg_veins, Vector3(0, -0.28, 0.095), Vector3(0, 0, 0.18), 0.024, 0.56, gold_mat)
			_add_vein_cylinder(leg_veins, Vector3(-0.06, -0.28, -0.08), Vector3(0, 0, -0.22), 0.020, 0.52, accent_mat)

# =========================================================================
# 2. TANK & SPIDER VEHICLE GOLD VEINS
# =========================================================================
static func _apply_tank_husk_veins(unit: Node3D, is_gilded: bool = false) -> void:
	var gold_mat := get_gold_vein_material()
	var accent_mat := get_gilded_pale_blue_material() if is_gilded else gold_mat
	var body_mat := get_husk_body_material(Color(0.28, 0.26, 0.30), is_gilded)
	var armor_mat := get_husk_armor_material(is_gilded)
	_recolor_hierarchy_for_husk(unit, body_mat, armor_mat, gold_mat)

	var vein_root := Node3D.new()
	vein_root.name = "HuskTankVeins"
	unit.add_child(vein_root)

	_add_vein_cylinder(vein_root, Vector3(-1.26, 0.85, 0.0), Vector3(deg_to_rad(82.0), 0, 0), 0.08, 3.4, gold_mat)
	_add_vein_cylinder(vein_root, Vector3(1.26, 0.85, 0.0), Vector3(deg_to_rad(98.0), 0, 0), 0.08, 3.4, accent_mat)
	_add_vein_cylinder(vein_root, Vector3(0.0, 1.52, 0.2), Vector3(deg_to_rad(90.0), 0.45, 0), 0.07, 3.2, gold_mat)
	_add_vein_cylinder(vein_root, Vector3(0.0, 1.52, -0.2), Vector3(deg_to_rad(90.0), -0.45, 0), 0.07, 3.2, accent_mat)
	_add_vein_cylinder(vein_root, Vector3(0.0, 2.05, -2.0), Vector3(deg_to_rad(90.0), 0.08, 0), 0.065, 2.8, gold_mat)
	_add_vein_cylinder(vein_root, Vector3(0.18, 1.98, -1.8), Vector3(deg_to_rad(90.0), -0.12, 0), 0.05, 2.5, accent_mat)

	var halo := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.25
	tm.outer_radius = 1.42
	halo.mesh = tm
	halo.material_override = gold_mat
	halo.position = Vector3(0, 2.55, 0)
	vein_root.add_child(halo)

	var front_face := _create_mini_gold_face(0.85, gold_mat)
	front_face.position = Vector3(0, 1.1, -1.78)
	front_face.rotation.y = PI
	vein_root.add_child(front_face)

# =========================================================================
# 3. MECH & WALKER GOLD VEINS
# =========================================================================
static func _apply_mech_husk_veins(unit: Node3D, is_gilded: bool = false) -> void:
	var gold_mat := get_gold_vein_material()
	var accent_mat := get_gilded_pale_blue_material() if is_gilded else gold_mat
	var body_mat := get_husk_body_material(Color(0.32, 0.30, 0.35), is_gilded)
	var armor_mat := get_husk_armor_material(is_gilded)
	_recolor_hierarchy_for_husk(unit, body_mat, armor_mat, gold_mat)

	var vein_root := Node3D.new()
	vein_root.name = "HuskMechVeins"
	unit.add_child(vein_root)

	_add_vein_cylinder(vein_root, Vector3(-0.65, 1.2, 0.15), Vector3(0.15, 0, 0.2), 0.07, 2.4, gold_mat)
	_add_vein_cylinder(vein_root, Vector3(0.65, 1.2, 0.15), Vector3(0.15, 0, -0.2), 0.07, 2.4, accent_mat)
	_add_vein_cylinder(vein_root, Vector3(0.0, 2.4, 0.55), Vector3(0, 0, 0.55), 0.08, 1.9, gold_mat)
	_add_vein_cylinder(vein_root, Vector3(0.0, 2.4, 0.55), Vector3(0, 0, -0.55), 0.08, 1.9, accent_mat)
	_add_vein_cylinder(vein_root, Vector3(-1.1, 2.3, -0.4), Vector3(deg_to_rad(85.0), 0, 0), 0.06, 1.8, gold_mat)
	_add_vein_cylinder(vein_root, Vector3(1.1, 2.3, -0.4), Vector3(deg_to_rad(85.0), 0, 0), 0.06, 1.8, accent_mat)

	var chest_face := _create_mini_gold_face(0.9, gold_mat)
	chest_face.position = Vector3(0, 2.4, -0.85)
	chest_face.rotation.y = PI
	vein_root.add_child(chest_face)

# =========================================================================
# 4. AIRCRAFT / PLANE GOLD VEINS
# =========================================================================
static func _apply_plane_husk_veins(unit: Node3D, is_gilded: bool = false) -> void:
	var gold_mat := get_gold_vein_material()
	var accent_mat := get_gilded_pale_blue_material() if is_gilded else gold_mat
	var body_mat := get_husk_body_material(Color(0.30, 0.28, 0.34), is_gilded)
	var armor_mat := get_husk_armor_material(is_gilded)
	_recolor_hierarchy_for_husk(unit, body_mat, armor_mat, gold_mat)

	var vein_root := Node3D.new()
	vein_root.name = "HuskPlaneVeins"
	var p_mesh := unit.get_node_or_null("MeshInstance3D")
	if p_mesh:
		p_mesh.add_child(vein_root)
	else:
		unit.add_child(vein_root)

	_add_vein_cylinder(vein_root, Vector3(0, 0.35, 0), Vector3(deg_to_rad(90.0), 0.08, 0), 0.065, 3.6, gold_mat)
	_add_vein_cylinder(vein_root, Vector3(0, 0.15, 0.2), Vector3(0, 0, deg_to_rad(86.0)), 0.06, 3.8, accent_mat)
	_add_vein_cylinder(vein_root, Vector3(0, 0.15, -0.2), Vector3(0, 0, deg_to_rad(94.0)), 0.06, 3.8, gold_mat)

# =========================================================================
# 5. BEASTS, VOID SWARM & ALL OTHER MODELS GOLD VEINS
# =========================================================================
static func _apply_generic_mesh_husk_veins(unit: Node3D, is_gilded: bool = false) -> void:
	var gold_mat := get_gold_vein_material()
	var accent_mat := get_gilded_pale_blue_material() if is_gilded else gold_mat
	var body_mat := get_husk_body_material(Color(0.88, 0.86, 0.82), is_gilded)
	var armor_mat := get_husk_armor_material(is_gilded)
	_recolor_hierarchy_for_husk(unit, body_mat, armor_mat, gold_mat)

	var vein_root := Node3D.new()
	vein_root.name = "HuskGenericVeins"
	unit.add_child(vein_root)

	for i in range(8):
		var ang: float = (TAU / 8.0) * float(i)
		var pos := Vector3(cos(ang) * 0.45, 0.8 + float(i % 3) * 0.35, sin(ang) * 0.45)
		var rot := Vector3(sin(ang) * 0.7, ang, cos(ang) * 0.65)
		_add_vein_cylinder(vein_root, pos, rot, 0.045, 1.45, gold_mat if i % 2 == 0 else accent_mat)

	var halo := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.65
	tm.outer_radius = 0.78
	halo.mesh = tm
	halo.material_override = gold_mat
	halo.position = Vector3(0, 1.85, 0)
	vein_root.add_child(halo)

	var face := _create_mini_gold_face(0.55, gold_mat)
	face.position = Vector3(0, 1.15, -0.65)
	face.rotation.y = PI
	vein_root.add_child(face)

# =========================================================================
# 6. CORPSE GOLD VEINS (For dead Husks of Harmony)
# =========================================================================
static func apply_corpse_gold_veins(corpse: Node3D, is_gilded: bool = false) -> void:
	if not is_instance_valid(corpse):
		return
	var gold_mat := get_gold_vein_material()
	var accent_mat := get_gilded_pale_blue_material() if is_gilded else gold_mat
	var body_mat := get_husk_body_material(Color(0.88, 0.86, 0.82), is_gilded)
	var armor_mat := get_husk_armor_material(is_gilded)
	_recolor_hierarchy_for_husk(corpse, body_mat, armor_mat, gold_mat)

	var vein_root := Node3D.new()
	vein_root.name = "CorpseGoldVeins"
	corpse.add_child(vein_root)
	for i in range(6):
		var ang: float = (TAU / 6.0) * float(i)
		var pos := Vector3(cos(ang) * 0.35, 0.18, sin(ang) * 0.35)
		var rot := Vector3(deg_to_rad(82.0), ang, 0.25)
		_add_vein_cylinder(vein_root, pos, rot, 0.032, 1.1, gold_mat if i % 2 == 0 else accent_mat)

static func _recolor_hierarchy_for_husk(root: Node, body_mat: Material, armor_mat: Material, gold_mat: Material) -> void:
	var idx: int = 0
	for child in root.get_children():
		if child.name == "GroundTeamMarker" or "Health" in child.name or "Husk" in child.name:
			continue
		if child is MeshInstance3D:
			var n_low := child.name.to_lower()
			if "visor" in n_low or "eye" in n_low or "optic" in n_low or "core" in n_low:
				child.material_override = gold_mat
			elif idx % 3 == 0:
				child.material_override = armor_mat
			else:
				child.material_override = body_mat
			idx += 1
		elif child is CSGShape3D:
			child.material = gold_mat if (idx % 2 == 0) else armor_mat
			idx += 1
		if child.get_child_count() > 0:
			_recolor_hierarchy_for_husk(child, body_mat, armor_mat, gold_mat)

static func _add_vein_cylinder(parent: Node3D, pos: Vector3, rot: Vector3, radius: float, height: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius * 0.65
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 8
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)

static func _create_mini_gold_face(scale_factor: float, gold_mat: Material) -> Node3D:
	var face_root := Node3D.new()
	face_root.scale = Vector3.ONE * scale_factor

	var mask := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 1.05
	mask.mesh = sm
	mask.scale = Vector3(1.0, 1.0, 0.32)
	mask.material_override = gold_mat
	face_root.add_child(mask)

	var dark_gold := StandardMaterial3D.new()
	dark_gold.albedo_color = Color(0.55, 0.38, 0.05)
	dark_gold.metallic = 0.9
	dark_gold.roughness = 0.25

	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.08
		es.height = 0.14
		eye.mesh = es
		eye.material_override = dark_gold
		eye.position = Vector3(side * 0.16, 0.10, 0.13)
		face_root.add_child(eye)

	var nose := MeshInstance3D.new()
	var nb := BoxMesh.new()
	nb.size = Vector3(0.08, 0.24, 0.10)
	nose.mesh = nb
	nose.material_override = gold_mat
	nose.position = Vector3(0, 0.02, 0.15)
	face_root.add_child(nose)

	var mouth := MeshInstance3D.new()
	var mb := BoxMesh.new()
	mb.size = Vector3(0.22, 0.06, 0.08)
	mouth.mesh = mb
	mouth.material_override = dark_gold
	mouth.position = Vector3(0, -0.20, 0.13)
	face_root.add_child(mouth)

	return face_root

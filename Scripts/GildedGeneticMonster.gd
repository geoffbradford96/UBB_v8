extends CharacterBody3D
class_name GildedGeneticMonster

const HarmonyHuskBuilderScript = preload("res://Scripts/HarmonyHuskBuilder.gd")
const GildedMitosisScript = preload("res://Scripts/GildedMitosisComponent.gd")

@export var team: String = "SideA":
	set(v):
		team = v
		if is_inside_tree():
			for g in get_groups():
				if g.begins_with("Side"):
					remove_from_group(g)
			add_to_group(team)
@export var monster_role: String = "MELEE" # "MELEE", "RANGED", "TANK", "PLANE", "BIG", "COMMANDER"
@export var split_generation: int = 0
@export var base_hp: float = 240.0
@export var base_damage: float = 28.0
@export var speed: float = 4.6
@export var attack_range: float = 3.2
@export var attack_cooldown: float = 1.0

var current_target: Node3D = null
var attack_timer: float = 0.0
var anim_time: float = 0.0
var is_flying: bool = false
var flight_height: float = 0.0

var visual_root: Node3D = null
var helix_nodes: Array[Node3D] = []
var ring_nodes: Array[Node3D] = []
var limb_nodes: Array[Node3D] = []
var bio_beam_mesh: MeshInstance3D = null
var beam_flash_timer: float = 0.0

func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var root = (loop as SceneTree).root
		if root and root.has_node("GameState"):
			return root.get_node("GameState")
	return null

func _ready() -> void:
	add_to_group("Targetable")
	add_to_group("Units")
	add_to_group("GildedHarmony")
	set_meta("is_husk_of_harmony", true)
	set_meta("is_gilded_harmony", true)
	collision_layer = 2
	collision_mask = 1
	anim_time = randf() * 10.0

	if get_node_or_null("CollisionShape3D") == null:
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var sph := SphereShape3D.new()
		sph.radius = 1.05
		col.shape = sph
		col.position = Vector3(0.0, 1.1, 0.0)
		add_child(col)

	if get_node_or_null("HealthComponent") == null:
		var hc := HealthComponent.new()
		hc.name = "HealthComponent"
		hc.max_health = base_hp
		add_child(hc)

	var team_grp: String = _get_my_team()
	configure_monster(monster_role, split_generation, team_grp)

func _get_my_team() -> String:
	for g in get_groups():
		if g.begins_with("Side"):
			return g
	if team != "":
		return team
	return "SideA"

func configure_monster(role: String, gen: int = 0, team_group: String = "SideA") -> void:
	monster_role = role.to_upper()
	split_generation = clampi(gen, 0, 2)
	team = team_group

	for g in get_groups():
		if g.begins_with("Side"):
			remove_from_group(g)
	add_to_group(team_group)

	if monster_role == "MELEE":
		base_hp = 230.0
		base_damage = 28.0
		speed = 5.2
		attack_range = 3.2
		attack_cooldown = 0.9
		is_flying = false
	elif monster_role == "RANGED":
		base_hp = 175.0
		base_damage = 24.0
		speed = 4.3
		attack_range = 16.5
		attack_cooldown = 1.15
		is_flying = false
	elif monster_role == "TANK":
		base_hp = 520.0
		base_damage = 40.0
		speed = 3.4
		attack_range = 9.5
		attack_cooldown = 1.4
		is_flying = false
	elif monster_role == "PLANE":
		base_hp = 240.0
		base_damage = 30.0
		speed = 6.4
		attack_range = 15.0
		attack_cooldown = 1.1
		is_flying = true
		flight_height = 6.2
		add_to_group("Flyer")
	elif monster_role == "BIG":
		base_hp = 680.0
		base_damage = 54.0
		speed = 3.6
		attack_range = 4.5
		attack_cooldown = 1.25
		is_flying = false
	elif monster_role == "COMMANDER":
		base_hp = 820.0
		base_damage = 62.0
		speed = 4.2
		attack_range = 14.0
		attack_cooldown = 1.05
		is_flying = false
		add_to_group("CommanderUnit")

	var gen_scale: float = pow(0.68, float(split_generation))
	var stat_mult: float = pow(0.55, float(split_generation))
	scale = Vector3.ONE * gen_scale

	var scaled_hp: float = maxf(20.0, base_hp * stat_mult)
	var hc := get_node_or_null("HealthComponent")
	if hc:
		hc.max_health = scaled_hp
		hc.current_health = scaled_hp
		if monster_role == "COMMANDER":
			hc.max_shield = 350.0
			hc.current_shield = 350.0
			hc.shield_type = "360"
			hc.shield_color = Color(1.0, 0.85, 0.25, 0.5)
			hc.shield_recharge_rate = 25.0
			hc._setup_shield_and_armor_visuals()
		if hc.has_method("_refresh_hp_visuals"):
			hc._refresh_hp_visuals()

	var mitosis = get_node_or_null("GildedMitosisComponent")
	if mitosis == null:
		mitosis = GildedMitosisScript.new()
		mitosis.name = "GildedMitosisComponent"
		add_child(mitosis)
	mitosis.split_generation = split_generation
	mitosis.regen_per_second = maxf(2.5, scaled_hp * 0.028)

	if is_inside_tree():
		_rebuild_visuals()

func _rebuild_visuals() -> void:
	if visual_root and is_instance_valid(visual_root):
		visual_root.queue_free()
	helix_nodes.clear()
	ring_nodes.clear()
	limb_nodes.clear()
	bio_beam_mesh = null

	visual_root = Node3D.new()
	visual_root.name = "GildedMonsterVisuals"
	add_child(visual_root)

	# Ensure HuskGoldVeins marker exists for verification
	if get_node_or_null("HuskGoldVeins") == null:
		var marker := Node3D.new()
		marker.name = "HuskGoldVeins"
		add_child(marker)

	var gold_mat := HarmonyHuskBuilderScript.get_gold_vein_material()
	var pale_blue_mat := HarmonyHuskBuilderScript.get_gilded_pale_blue_material()
	var dark_green_mat := HarmonyHuskBuilderScript.get_gilded_dark_green_material()

	var size_mult: float = 1.0
	if monster_role == "TANK":
		size_mult = 1.35
	elif monster_role == "BIG":
		size_mult = 1.55
	elif monster_role == "COMMANDER":
		size_mult = 1.65

	# 1. Unnatural Spliced Alien Double-Helix Core (Dark Green & Pale Blue DNA strands)
	var helix_pivot := Node3D.new()
	helix_pivot.name = "DNAHelixCore"
	helix_pivot.position = Vector3(0.0, 1.35 * size_mult, 0.0)
	visual_root.add_child(helix_pivot)
	helix_nodes.append(helix_pivot)

	var rung_count: int = 7 if size_mult > 1.2 else 5
	for i in range(rung_count):
		var t_ratio: float = float(i) / float(max(1, rung_count - 1)) - 0.5
		var y_off: float = t_ratio * 1.6 * size_mult
		var twist_ang: float = float(i) * 0.95

		for side in [-1.0, 1.0]:
			var node_ball := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 0.20 * size_mult
			sph.height = 0.40 * size_mult
			node_ball.mesh = sph
			var p_curr := Vector3(cos(twist_ang) * 0.48 * size_mult * side, y_off, sin(twist_ang) * 0.48 * size_mult * side)
			node_ball.position = p_curr
			node_ball.material_override = dark_green_mat if side < 0.0 else pale_blue_mat
			helix_pivot.add_child(node_ball)

			if i < rung_count - 1:
				var next_ratio: float = float(i + 1) / float(max(1, rung_count - 1)) - 0.5
				var next_y: float = next_ratio * 1.6 * size_mult
				var next_ang: float = float(i + 1) * 0.95
				var p_next := Vector3(cos(next_ang) * 0.48 * size_mult * side, next_y, sin(next_ang) * 0.48 * size_mult * side)
				var strand_link := MeshInstance3D.new()
				var sl_cyl := CylinderMesh.new()
				sl_cyl.top_radius = 0.055 * size_mult
				sl_cyl.bottom_radius = 0.055 * size_mult
				sl_cyl.height = p_curr.distance_to(p_next)
				strand_link.mesh = sl_cyl
				strand_link.position = (p_curr + p_next) * 0.5
				strand_link.material_override = dark_green_mat if side < 0.0 else pale_blue_mat
				helix_pivot.add_child(strand_link)

		# Golden genetic bridge rung connecting the two strands
		var rung := MeshInstance3D.new()
		var r_cyl := CylinderMesh.new()
		r_cyl.top_radius = 0.045 * size_mult
		r_cyl.bottom_radius = 0.045 * size_mult
		r_cyl.height = 0.96 * size_mult
		rung.mesh = r_cyl
		rung.position = Vector3(0.0, y_off, 0.0)
		rung.rotation = Vector3(0.0, -twist_ang, PI * 0.5)
		rung.material_override = gold_mat
		helix_pivot.add_child(rung)

	# 2. Asymmetric Bioluminescent Gestation Sacs & Spliced Carapace Plates
	for c_i in range(4):
		var sac := MeshInstance3D.new()
		var s_mesh := SphereMesh.new()
		s_mesh.radius = (0.28 + float(c_i % 2) * 0.10) * size_mult
		s_mesh.height = s_mesh.radius * 2.2
		sac.mesh = s_mesh
		var c_ang: float = (TAU / 4.0) * float(c_i) + 0.4
		sac.position = Vector3(cos(c_ang) * 0.48 * size_mult, (1.1 + float(c_i % 2) * 0.4) * size_mult, sin(c_ang) * 0.48 * size_mult)
		sac.material_override = pale_blue_mat if c_i % 2 == 0 else dark_green_mat
		visual_root.add_child(sac)

	# 3. Golden Harmony Containment Rings keeping the alien genetic mutation in control
	var ring_total: int = 3 if (monster_role == "COMMANDER" or monster_role == "BIG") else 2
	for r_i in range(ring_total):
		var h_ring := MeshInstance3D.new()
		var tor := TorusMesh.new()
		var r_rad: float = (0.85 + float(r_i) * 0.24) * size_mult
		tor.inner_radius = r_rad
		tor.outer_radius = r_rad + 0.08 * size_mult
		h_ring.mesh = tor
		h_ring.position = Vector3(0.0, 1.45 * size_mult, 0.0)
		h_ring.rotation_degrees = Vector3(35.0 * float(r_i + 1), 50.0 * float(r_i), 20.0)
		h_ring.material_override = gold_mat
		visual_root.add_child(h_ring)
		ring_nodes.append(h_ring)

	# Sculpted Gold Harmony Face Mask fused onto the alien's anterior cluster
	var face := HarmonyHuskBuilderScript._create_mini_gold_face(0.58 * size_mult, gold_mat)
	face.position = Vector3(0.0, 1.55 * size_mult, 0.52 * size_mult)
	visual_root.add_child(face)

	# 4. Role-Specific Genetic Appendages (Scythes, Bio-Prisms, Quad-Legs, or Bio-Wings) with Socket Joints
	var limb_count: int = 4
	if monster_role == "TANK" or monster_role == "BIG":
		limb_count = 6
	for l_i in range(limb_count):
		var l_piv := Node3D.new()
		var l_ang: float = (TAU / float(limb_count)) * float(l_i) + PI * 0.25
		l_piv.position = Vector3(cos(l_ang) * 0.50 * size_mult, 1.15 * size_mult, sin(l_ang) * 0.50 * size_mult)
		visual_root.add_child(l_piv)
		limb_nodes.append(l_piv)

		var l_sock := MeshInstance3D.new()
		var ls_sph := SphereMesh.new()
		ls_sph.radius = 0.14 * size_mult
		l_sock.mesh = ls_sph
		l_sock.material_override = gold_mat
		l_piv.add_child(l_sock)

		var l_mesh := MeshInstance3D.new()
		if is_flying:
			var wing_box := BoxMesh.new()
			wing_box.size = Vector3(1.45 * size_mult, 0.06 * size_mult, 0.48 * size_mult)
			l_mesh.mesh = wing_box
			l_mesh.position = Vector3(cos(l_ang) * 0.65 * size_mult, 0.05, sin(l_ang) * 0.25)
			l_mesh.material_override = pale_blue_mat if l_i % 2 == 0 else dark_green_mat
		else:
			var blade_prism := PrismMesh.new()
			blade_prism.size = Vector3(0.18 * size_mult, 1.15 * size_mult, 0.32 * size_mult)
			l_mesh.mesh = blade_prism
			l_mesh.position = Vector3(0.0, -0.35 * size_mult, 0.28 * size_mult)
			l_mesh.rotation_degrees = Vector3(45.0, 0.0, 0.0)
			l_mesh.material_override = gold_mat if l_i % 2 == 0 else dark_green_mat
		l_piv.add_child(l_mesh)

	# 5. Ranged / Tank / Plane / Commander Bio-Harmony Beam Visual
	if attack_range > 5.0:
		bio_beam_mesh = MeshInstance3D.new()
		bio_beam_mesh.name = "GildedBioBeam"
		var b_cyl := CylinderMesh.new()
		b_cyl.top_radius = 0.12
		b_cyl.bottom_radius = 0.12
		b_cyl.height = 1.0
		bio_beam_mesh.mesh = b_cyl
		var b_mat := StandardMaterial3D.new()
		b_mat.albedo_color = Color(0.55, 0.92, 1.0, 0.85)
		b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		b_mat.emission_enabled = true
		b_mat.emission = Color(0.45, 0.88, 1.0)
		b_mat.emission_energy_multiplier = 4.5
		bio_beam_mesh.material_override = b_mat
		bio_beam_mesh.visible = false
		add_child(bio_beam_mesh)

func _physics_process(delta: float) -> void:
	anim_time += delta
	if attack_timer > 0.0:
		attack_timer -= delta
	if beam_flash_timer > 0.0:
		beam_flash_timer -= delta
		if beam_flash_timer <= 0.0 and bio_beam_mesh:
			bio_beam_mesh.visible = false

	_update_target()

	if is_instance_valid(current_target):
		var flat_my := Vector3(global_position.x, 0.0, global_position.z)
		var flat_t := Vector3(current_target.global_position.x, 0.0, current_target.global_position.z)
		var dist: float = flat_my.distance_to(flat_t)
		var eff_range: float = attack_range
		if "Base" in current_target.name:
			eff_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			eff_range += 2.5

		if dist <= eff_range:
			velocity.x = 0.0
			velocity.z = 0.0
			_face_position(current_target.global_position, delta)
			if attack_timer <= 0.0:
				_perform_attack(current_target)
				attack_timer = attack_cooldown
		else:
			var dir := (flat_t - flat_my).normalized()
			if not is_flying:
				var space_state := get_world_3d().direct_space_state
				if space_state:
					var from_pos := global_position + Vector3(0.0, 0.8, 0.0)
					var q := PhysicsRayQueryParameters3D.create(from_pos, from_pos + dir * 3.2, 1, [get_rid()])
					var hit := space_state.intersect_ray(q)
					if not hit.is_empty() and hit.get("collider") != current_target:
						for ang_deg in [40.0, -40.0, 75.0, -75.0]:
							var cand := dir.rotated(Vector3.UP, deg_to_rad(ang_deg))
							var q2 := PhysicsRayQueryParameters3D.create(from_pos, from_pos + cand * 3.0, 1, [get_rid()])
							if space_state.intersect_ray(q2).is_empty():
								dir = cand
								break
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			var gs = _get_game_state()
			if not is_flying and gs:
				var dist_lane: float = gs.get_distance_to_nearest_lane(global_position)
				if dist_lane > 11.5:
					var pull: Vector3 = gs.get_vector_towards_nearest_lane(global_position)
					velocity.x += pull.x * speed * 0.9
					velocity.z += pull.z * speed * 0.9
			_face_position(global_position + dir, delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	if is_flying:
		velocity.y = 0.0
		global_position.y = lerpf(global_position.y, flight_height, minf(1.0, delta * 5.0))
	else:
		if not is_on_floor():
			velocity.y -= 9.8 * delta
		else:
			velocity.y = 0.0

	move_and_slide()
	if not is_flying and global_position.y < 0.0:
		global_position.y = 0.0

	_animate_visuals(delta)

func _update_target() -> void:
	if not is_inside_tree() or not get_tree():
		return
	var my_team: String = _get_my_team()
	var gs = _get_game_state()
	if is_instance_valid(current_target):
		var thc := current_target.get_node_or_null("HealthComponent")
		if thc and not thc.is_dead and thc.current_health > 0 and not current_target.is_in_group(my_team):
			if not (gs and gs.is_unit_stealthed_from(current_target, self)):
				return
		current_target = null

	var best_dist: float = 99999.0
	var best_node: Node3D = null
	for node in get_tree().get_nodes_in_group("Targetable"):
		if not is_instance_valid(node) or node == self or not (node is Node3D):
			continue
		if node.is_in_group(my_team):
			continue
		if gs and gs.is_unit_stealthed_from(node, self):
			continue
		var u3 := node as Node3D
		if (node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure")) and global_position.distance_to(u3.global_position) > 8.5:
			continue
		if node.is_in_group("SideHarmony") and global_position.distance_to(u3.global_position) > 12.0:
			continue
		var hc := node.get_node_or_null("HealthComponent")
		if hc == null or hc.is_dead or hc.current_health <= 0:
			continue
		var d: float = global_position.distance_to(u3.global_position)
		if d < best_dist:
			best_dist = d
			best_node = u3
	current_target = best_node

func _perform_attack(target: Node3D) -> void:
	if not is_instance_valid(target):
		return
	var stat_mult: float = pow(0.55, float(split_generation))
	var actual_dmg: float = maxf(4.0, base_damage * stat_mult)
	var hc := target.get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.take_damage(actual_dmg, global_position)

	if bio_beam_mesh and attack_range > 5.0:
		var start_p: Vector3 = global_position + Vector3(0.0, 1.5 * scale.y, 0.0)
		var end_p: Vector3 = target.global_position + Vector3(0.0, 1.0, 0.0)
		var diff: Vector3 = end_p - start_p
		var dist: float = maxf(0.4, diff.length())
		var mid: Vector3 = start_p + diff * 0.5
		bio_beam_mesh.visible = true
		bio_beam_mesh.global_position = mid
		var up_dir: Vector3 = diff.normalized()
		var ref_v: Vector3 = Vector3.FORWARD if absf(up_dir.dot(Vector3.UP)) > 0.95 else Vector3.UP
		var right_v: Vector3 = ref_v.cross(up_dir).normalized()
		var fwd_v: Vector3 = up_dir.cross(right_v).normalized()
		bio_beam_mesh.global_transform.basis = Basis(right_v, up_dir * dist, fwd_v)
		beam_flash_timer = 0.24

func _face_position(target_pos: Vector3, delta: float) -> void:
	var diff := Vector3(target_pos.x - global_position.x, 0.0, target_pos.z - global_position.z)
	if diff.length_squared() < 0.01:
		return
	var target_yaw: float = atan2(diff.x, diff.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 8.0))

func _animate_visuals(_delta: float) -> void:
	for h in helix_nodes:
		if is_instance_valid(h):
			h.rotation.y += 0.035
	for r_i in range(ring_nodes.size()):
		var r := ring_nodes[r_i]
		if is_instance_valid(r):
			r.rotation.x += 0.02 * (1.0 if r_i % 2 == 0 else -1.0)
			r.rotation.z += 0.025
	for l_i in range(limb_nodes.size()):
		var l := limb_nodes[l_i]
		if is_instance_valid(l):
			var spd: float = 8.0 if is_flying else 4.5
			l.rotation.z = sin(anim_time * spd + float(l_i) * 1.2) * 0.35

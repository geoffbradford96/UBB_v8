class_name PrimitiveWoodTower
extends StaticBody3D

@export var max_health: float = 420.0
@export var current_health: float = 420.0
@export var attack_range: float = 16.0
@export var attack_rate: float = 0.45 # Fast shooting bow person
@export var attack_damage: float = 10.0
@export var unit_attribute: String = "Structure"

var team: String = "SideA":
	set(val):
		team = val
		if is_inside_tree():
			for g in get_groups():
				if g.begins_with("Side"):
					remove_from_group(g)
			if team != "":
				add_to_group(team)

var current_target: Node3D = null
var fire_timer: float = 0.0
var visual_root: Node3D = null
var archer_node: Node3D = null
var bow_arm: Node3D = null

func _ready():
	add_to_group("Targetable")
	add_to_group("Structure")
	add_to_group("FactionStructures")
	current_health = max_health

	_setup_collision()
	_setup_health_component()
	_build_wood_tower_model()

func _setup_collision():
	var col = get_node_or_null("CollisionShape3D")
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cyl = CylinderShape3D.new()
		cyl.radius = 1.6
		cyl.height = 4.8
		col.shape = cyl
		col.position.y = 2.4
		add_child(col)

func _setup_health_component():
	var hc = get_node_or_null("HealthComponent")
	if not hc:
		var health_script = load("res://Scripts/HealthComponent.gd")
		if health_script:
			hc = health_script.new()
			hc.name = "HealthComponent"
			add_child(hc)
	if hc:
		hc.set_max_health(max_health)
		if not hc.died.is_connected(_on_destroyed):
			hc.died.connect(_on_destroyed)

func _build_wood_tower_model():
	visual_root = Node3D.new()
	visual_root.name = "WoodTowerVisuals"
	add_child(visual_root)

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.46, 0.30, 0.16)
	wood_mat.roughness = 0.88

	var plank_mat = StandardMaterial3D.new()
	plank_mat.albedo_color = Color(0.55, 0.38, 0.22)
	plank_mat.roughness = 0.82

	var thatch_mat = StandardMaterial3D.new()
	thatch_mat.albedo_color = Color(0.78, 0.68, 0.32) # Straw thatch
	thatch_mat.roughness = 0.95

	# 4 Sturdy Log Legs
	for i in range(4):
		var ang = (TAU / 4.0) * i + (PI / 4.0)
		var post = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.14
		p_cyl.bottom_radius = 0.22
		p_cyl.height = 4.2
		post.mesh = p_cyl
		post.material_override = wood_mat
		post.position = Vector3(cos(ang) * 1.1, 2.1, sin(ang) * 1.1)
		post.rotation = Vector3(-sin(ang) * 0.08, 0, cos(ang) * 0.08)
		visual_root.add_child(post)

	# Cross braces
	for i in range(4):
		var ang = (TAU / 4.0) * i
		var brace = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(1.6, 0.1, 0.1)
		brace.mesh = b_box
		brace.material_override = wood_mat
		brace.position = Vector3(cos(ang) * 0.95, 1.8, sin(ang) * 0.95)
		brace.rotation.y = ang + (PI / 2.0)
		visual_root.add_child(brace)

	# Deck Platform
	var platform = MeshInstance3D.new()
	var pf_box = BoxMesh.new()
	pf_box.size = Vector3(2.4, 0.22, 2.4)
	platform.mesh = pf_box
	platform.material_override = plank_mat
	platform.position.y = 4.2
	visual_root.add_child(platform)

	# Safety Railing
	for i in range(4):
		var ang = (TAU / 4.0) * i
		var rail = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(2.3, 0.6, 0.08)
		rail.mesh = r_box
		rail.material_override = wood_mat
		rail.position = Vector3(cos(ang) * 1.15, 4.6, sin(ang) * 1.15)
		rail.rotation.y = ang + (PI / 2.0)
		visual_root.add_child(rail)

	# Thatched Roof
	var roof_post = MeshInstance3D.new()
	var rp_cyl = CylinderMesh.new()
	rp_cyl.top_radius = 0.08
	rp_cyl.bottom_radius = 0.1
	rp_cyl.height = 2.2
	roof_post.mesh = rp_cyl
	roof_post.material_override = wood_mat
	roof_post.position.y = 5.3
	visual_root.add_child(roof_post)

	var roof = MeshInstance3D.new()
	var r_cone = CylinderMesh.new()
	r_cone.top_radius = 0.05
	r_cone.bottom_radius = 2.0
	r_cone.height = 1.4
	roof.mesh = r_cone
	roof.material_override = thatch_mat
	roof.position.y = 6.4
	visual_root.add_child(roof)

	# Wooden Rung Ladder climbing the rear side of the tower
	var ladder_root = Node3D.new()
	ladder_root.name = "TowerLadder"
	ladder_root.position = Vector3(0.0, 2.1, 1.25)
	ladder_root.rotation_degrees.x = -8.0
	visual_root.add_child(ladder_root)
	for l_side in [-1.0, 1.0]:
		var rail_pole = MeshInstance3D.new()
		var rp_c = CylinderMesh.new()
		rp_c.top_radius = 0.045; rp_c.bottom_radius = 0.055; rp_c.height = 4.3
		rail_pole.mesh = rp_c
		rail_pole.material_override = wood_mat
		rail_pole.position = Vector3(l_side * 0.28, 0.0, 0.0)
		ladder_root.add_child(rail_pole)
	for rung_i in range(8):
		var rung = MeshInstance3D.new()
		var rg_c = CylinderMesh.new()
		rg_c.top_radius = 0.03; rg_c.bottom_radius = 0.03; rg_c.height = 0.58
		rung.mesh = rg_c
		rung.material_override = plank_mat
		rung.position = Vector3(0.0, -1.75 + float(rung_i) * 0.5, 0.0)
		rung.rotation_degrees.z = 90.0
		ladder_root.add_child(rung)

	# Bowman on Platform
	_build_archer_model()

func _build_archer_model():
	archer_node = Node3D.new()
	archer_node.name = "TowerArcher"
	archer_node.position = Vector3(0, 4.31, 0)
	visual_root.add_child(archer_node)

	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.78, 0.60, 0.44)

	var cloth_mat = StandardMaterial3D.new()
	cloth_mat.albedo_color = Color(0.35, 0.45, 0.28) # Rustic green tunic
	cloth_mat.roughness = 0.85

	var leather_mat = StandardMaterial3D.new()
	leather_mat.albedo_color = Color(0.32, 0.20, 0.12)
	leather_mat.roughness = 0.82

	var bow_wood = StandardMaterial3D.new()
	bow_wood.albedo_color = Color(0.38, 0.22, 0.12)

	var string_mat = StandardMaterial3D.new()
	string_mat.albedo_color = Color(0.88, 0.84, 0.72)

	# Legs & Boots
	for s_leg in [-1.0, 1.0]:
		var leg = MeshInstance3D.new()
		var l_cyl = CylinderMesh.new()
		l_cyl.top_radius = 0.085; l_cyl.bottom_radius = 0.07; l_cyl.height = 0.46
		leg.mesh = l_cyl
		leg.material_override = leather_mat
		leg.position = Vector3(s_leg * 0.12, 0.23, 0.0)
		archer_node.add_child(leg)

	# Torso & Leather Belt
	var torso = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.45, 0.62, 0.28)
	torso.mesh = t_box
	torso.material_override = cloth_mat
	torso.position.y = 0.74
	archer_node.add_child(torso)

	var belt = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.47, 0.09, 0.30)
	belt.mesh = b_box
	belt.material_override = leather_mat
	belt.position.y = 0.52
	archer_node.add_child(belt)

	# Back Quiver with Arrows
	var quiver = MeshInstance3D.new()
	var q_cyl = CylinderMesh.new()
	q_cyl.top_radius = 0.08; q_cyl.bottom_radius = 0.06; q_cyl.height = 0.48
	quiver.mesh = q_cyl
	quiver.material_override = leather_mat
	quiver.position = Vector3(-0.08, 0.82, 0.19)
	quiver.rotation_degrees.z = -18.0
	archer_node.add_child(quiver)

	# Head & Eyes
	var head = MeshInstance3D.new()
	var h_sph = SphereMesh.new()
	h_sph.radius = 0.18
	h_sph.height = 0.36
	head.mesh = h_sph
	head.material_override = skin_mat
	head.position.y = 1.22
	archer_node.add_child(head)

	# Straw Coif / Hat
	var hat = MeshInstance3D.new()
	var hat_c = CylinderMesh.new()
	hat_c.top_radius = 0.05
	hat_c.bottom_radius = 0.36
	hat_c.height = 0.25
	hat.mesh = hat_c
	hat.material_override = cloth_mat
	hat.position.y = 1.38
	archer_node.add_child(hat)

	# Left Arm extended holding the bow riser
	var left_arm = MeshInstance3D.new()
	var la_cyl = CylinderMesh.new()
	la_cyl.top_radius = 0.065; la_cyl.bottom_radius = 0.055; la_cyl.height = 0.48
	left_arm.mesh = la_cyl
	left_arm.material_override = skin_mat
	left_arm.position = Vector3(0.24, 0.88, -0.22)
	left_arm.rotation_degrees = Vector3(82.0, -12.0, 0.0)
	archer_node.add_child(left_arm)

	# Right String-Drawing Arm
	var right_arm = MeshInstance3D.new()
	right_arm.mesh = la_cyl
	right_arm.material_override = skin_mat
	right_arm.position = Vector3(-0.24, 0.88, -0.10)
	right_arm.rotation_degrees = Vector3(68.0, 18.0, 0.0)
	archer_node.add_child(right_arm)

	# Bow Arm Pivot (holding Recurve Bow, Bowstring & Nocked Arrow)
	bow_arm = Node3D.new()
	bow_arm.position = Vector3(0.20, 0.86, -0.42)
	archer_node.add_child(bow_arm)

	# Recurve Bow Arc
	var bow = MeshInstance3D.new()
	var b_tor = TorusMesh.new()
	b_tor.inner_radius = 0.42
	b_tor.outer_radius = 0.48
	bow.mesh = b_tor
	bow.material_override = bow_wood
	bow.rotation.y = PI / 2.0
	bow.rotation.z = PI / 4.0
	bow_arm.add_child(bow)

	var b_string = MeshInstance3D.new()
	var bs_cyl = CylinderMesh.new()
	bs_cyl.top_radius = 0.008; bs_cyl.bottom_radius = 0.008; bs_cyl.height = 0.86
	b_string.mesh = bs_cyl
	b_string.material_override = string_mat
	b_string.position = Vector3(0.0, 0.0, 0.14)
	bow_arm.add_child(b_string)

	var nocked_arrow = MeshInstance3D.new()
	var na_cyl = CylinderMesh.new()
	na_cyl.top_radius = 0.014; na_cyl.bottom_radius = 0.014; na_cyl.height = 0.65
	nocked_arrow.mesh = na_cyl
	nocked_arrow.material_override = string_mat
	nocked_arrow.position = Vector3(0.0, 0.02, -0.08)
	nocked_arrow.rotation_degrees.x = 90.0
	bow_arm.add_child(nocked_arrow)

func _physics_process(delta: float):
	fire_timer += delta

	if not is_instance_valid(current_target) or not _is_target_valid(current_target):
		current_target = _find_closest_enemy()

	if is_instance_valid(current_target):
		var target_pos = current_target.global_position
		var diff = target_pos - global_position
		diff.y = 0

		# Aim archer at target
		if diff.length_squared() > 0.01 and archer_node:
			var look_pos = Vector3(target_pos.x, archer_node.global_position.y, target_pos.z)
			archer_node.look_at(look_pos, Vector3.UP)

		if fire_timer >= attack_rate:
			fire_timer = 0.0
			_shoot_fast_arrow(current_target)

func _find_closest_enemy() -> Node3D:
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"):
			my_team = g
			break

	var best: Node3D = null
	var best_dist = attack_range
	for node in get_tree().get_nodes_in_group("Targetable"):
		if node == self or not is_instance_valid(node): continue
		if my_team != "" and node.is_in_group(my_team): continue
		if node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure"): continue
		var hc = node.get_node_or_null("HealthComponent")
		if hc and hc.is_dead: continue

		var d = global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	return best

func _is_target_valid(t: Node3D) -> bool:
	if not is_instance_valid(t) or t.is_queued_for_deletion(): return false
	var hc = t.get_node_or_null("HealthComponent")
	if hc and hc.is_dead: return false
	if global_position.distance_to(t.global_position) > attack_range + 2.0: return false
	return true

func _shoot_fast_arrow(target: Node3D):
	if not is_instance_valid(target): return

	var proj_scene = preload("res://Scenes/Projectile.tscn")
	var scene_root = get_tree().current_scene if (is_inside_tree() and get_tree() and get_tree().current_scene) else get_parent()
	if not proj_scene or not scene_root: return

	var proj = proj_scene.instantiate()
	scene_root.add_child(proj)
	proj.global_position = archer_node.global_position + Vector3(0, 0.8, 0)
	proj.target = target
	proj.set("damage", attack_damage)
	proj.set("speed", 28.0)

	# Recoil bow animation
	if bow_arm:
		var tw = create_tween()
		tw.tween_property(bow_arm, "position:z", 0.05, 0.06)
		tw.tween_property(bow_arm, "position:z", -0.15, 0.12)

	# Format projectile to look like a wooden arrow
	var p_mesh = proj.get_node_or_null("MeshInstance3D")
	if p_mesh:
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.02
		cyl.bottom_radius = 0.02
		cyl.height = 0.85
		p_mesh.mesh = cyl
		var a_mat = StandardMaterial3D.new()
		a_mat.albedo_color = Color(0.9, 0.85, 0.6)
		a_mat.emission_enabled = true
		a_mat.emission = Color(1.0, 0.9, 0.4)
		a_mat.emission_energy_multiplier = 2.0
		p_mesh.material_override = a_mat
		p_mesh.rotation_degrees.x = 90.0

func _on_destroyed():
	queue_free()

func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO):
	var hc = get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.take_damage(amount, source_pos)

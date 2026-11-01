extends StaticBody3D
class_name HangedManTree

@export var nest_radius: float = 22.0
@export var max_defenders: int = 2
@export var spawn_interval: float = 14.0

var _spawn_timer: float = 3.0 # Quick initial drop
var _active_defenders: Array = []
var _hanging_skeleton: Node3D = null
var _swaying_lantern: Node3D = null
var _anim_time: float = 0.0

func _ready():
	name = "HangedManTree"
	add_to_group("Targetable")
	add_to_group("HangedManTree")
	add_to_group("NeutralStructure")

	# Heavy Tree Trunk Collision Shape
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 1.6
	cyl.height = 5.5
	col.shape = cyl
	col.position = Vector3(0, 2.75, 0)
	add_child(col)

	_build_tree_visual()

func _build_tree_visual():
	var root = Node3D.new()
	root.name = "TreeVisual"
	add_child(root)

	var bark_mat = StandardMaterial3D.new()
	bark_mat.albedo_color = Color(0.14, 0.12, 0.11) # Gnarled charcoal dead bark
	bark_mat.roughness = 0.95

	var rope_mat = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.42, 0.36, 0.28) # Coarse hemp rope
	rope_mat.roughness = 0.9

	var bone_mat = StandardMaterial3D.new()
	bone_mat.albedo_color = Color(0.85, 0.82, 0.72) # Bleached skeleton bone
	bone_mat.roughness = 0.65

	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.45, 0.05) # Glowing amber pumpkin eye sockets
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.45, 0.05)
	eye_mat.emission_energy_multiplier = 2.8

	# 1. Gnarled Flared Trunk Base & Buttress Roots
	var trunk = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 1.05
	t_cyl.bottom_radius = 1.75
	t_cyl.height = 4.2
	trunk.mesh = t_cyl
	trunk.material_override = bark_mat
	trunk.position = Vector3(0, 2.1, 0)
	root.add_child(trunk)

	for i in range(5):
		var ang = (PI * 2.0 / 5.0) * float(i)
		var root_leg = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(0.5, 0.8, 1.8)
		root_leg.mesh = r_box
		root_leg.material_override = bark_mat
		root_leg.position = Vector3(cos(ang) * 1.5, 0.4, sin(ang) * 1.5)
		root_leg.rotation.y = ang + 0.3
		root_leg.rotation.x = -0.25
		root.add_child(root_leg)

	# 2. Main Outstretched Gallows Bough (Where the skeleton hangs)
	var bough = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.32
	b_cyl.bottom_radius = 0.55
	b_cyl.height = 4.0
	bough.mesh = b_cyl
	bough.material_override = bark_mat
	bough.rotation.z = deg_to_rad(75.0)
	bough.position = Vector3(1.8, 3.8, 0.2)
	root.add_child(bough)

	# 3. High Twisted Dead Branches
	var b2 = MeshInstance3D.new()
	b2.mesh = b_cyl
	b2.material_override = bark_mat
	b2.rotation.z = deg_to_rad(-65.0)
	b2.rotation.y = deg_to_rad(50.0)
	b2.position = Vector3(-1.6, 4.2, -0.8)
	root.add_child(b2)

	var b3 = MeshInstance3D.new()
	b3.mesh = b_cyl
	b3.material_override = bark_mat
	b3.rotation.x = deg_to_rad(60.0)
	b3.position = Vector3(0.2, 4.5, 1.8)
	root.add_child(b3)

	# 4. Hanging Noose & Skeleton Assembly
	_hanging_skeleton = Node3D.new()
	_hanging_skeleton.name = "HangingSkeletonPivot"
	_hanging_skeleton.position = Vector3(2.8, 3.6, 0.2) # Under the main bough
	root.add_child(_hanging_skeleton)

	# Rope
	var rope = MeshInstance3D.new()
	var r_cyl = CylinderMesh.new()
	r_cyl.top_radius = 0.03
	r_cyl.bottom_radius = 0.03
	r_cyl.height = 1.1
	rope.mesh = r_cyl
	rope.material_override = rope_mat
	rope.position = Vector3(0, -0.55, 0)
	_hanging_skeleton.add_child(rope)

	# Skeleton Skull
	var skull = MeshInstance3D.new()
	var s_sphere = SphereMesh.new()
	s_sphere.radius = 0.16
	s_sphere.height = 0.32
	skull.mesh = s_sphere
	skull.material_override = bone_mat
	skull.position = Vector3(0, -1.20, 0)
	_hanging_skeleton.add_child(skull)

	# Glowing Eye Sockets
	var eye_l = MeshInstance3D.new()
	var e_box = BoxMesh.new()
	e_box.size = Vector3(0.04, 0.04, 0.04)
	eye_l.mesh = e_box
	eye_l.material_override = eye_mat
	eye_l.position = Vector3(-0.06, -1.18, 0.14)
	_hanging_skeleton.add_child(eye_l)

	var eye_r = MeshInstance3D.new()
	eye_r.mesh = e_box
	eye_r.material_override = eye_mat
	eye_r.position = Vector3(0.06, -1.18, 0.14)
	_hanging_skeleton.add_child(eye_r)

	# Skeleton Ribcage
	var ribcage = MeshInstance3D.new()
	var rc_box = BoxMesh.new()
	rc_box.size = Vector3(0.32, 0.44, 0.20)
	ribcage.mesh = rc_box
	ribcage.material_override = bone_mat
	ribcage.position = Vector3(0, -1.55, 0)
	_hanging_skeleton.add_child(ribcage)

	# Dangling Bony Legs
	var leg_l = MeshInstance3D.new()
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.04
	l_cyl.bottom_radius = 0.03
	l_cyl.height = 0.55
	leg_l.mesh = l_cyl
	leg_l.material_override = bone_mat
	leg_l.position = Vector3(-0.09, -2.05, 0)
	_hanging_skeleton.add_child(leg_l)

	var leg_r = MeshInstance3D.new()
	leg_r.mesh = l_cyl
	leg_r.material_override = bone_mat
	leg_r.position = Vector3(0.09, -2.05, 0)
	_hanging_skeleton.add_child(leg_r)

	# 5. Swaying Jack-o'-Lantern on opposite branch
	_swaying_lantern = Node3D.new()
	_swaying_lantern.position = Vector3(-1.8, 3.4, 0.8)
	root.add_child(_swaying_lantern)

	var pump_mesh = MeshInstance3D.new()
	var p_sphere = SphereMesh.new()
	p_sphere.radius = 0.26
	p_sphere.height = 0.45
	pump_mesh.mesh = p_sphere
	var pump_mat = StandardMaterial3D.new()
	pump_mat.albedo_color = Color(0.92, 0.45, 0.06)
	pump_mat.emission_enabled = true
	pump_mat.emission = Color(1.0, 0.55, 0.08)
	pump_mat.emission_energy_multiplier = 1.8
	pump_mesh.material_override = pump_mat
	pump_mesh.position = Vector3(0, -0.4, 0)
	_swaying_lantern.add_child(pump_mesh)

func _process(delta: float):
	_anim_time += delta

	# Gentle eerie wind sway for the hanged skeleton
	if _hanging_skeleton:
		var sway_z = sin(_anim_time * 1.4) * 0.14
		var sway_x = cos(_anim_time * 1.1) * 0.08
		_hanging_skeleton.rotation.z = sway_z
		_hanging_skeleton.rotation.x = sway_x

	if _swaying_lantern:
		_swaying_lantern.rotation.z = -sin(_anim_time * 1.8) * 0.12

	# Periodic Guardian Spawning
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_check_and_spawn_guardian()

func _check_and_spawn_guardian():
	# Clean up any dead defender references
	var valid_list = []
	for d in _active_defenders:
		if is_instance_valid(d):
			var hc = d.get_node_or_null("HealthComponent")
			if hc and not hc.is_dead:
				valid_list.append(d)
	_active_defenders = valid_list

	if _active_defenders.size() >= max_defenders:
		return

	# Drop a Skeleton Swordsman or Skeleton Archer from the tree!
	var is_archer = (randf() < 0.4)
	var scene_path = "res://Scenes/Units/NightmareSkeletonArcher.tscn" if is_archer else "res://Scenes/Units/NightmareSkeletonSwordsman.tscn"
	var skel_scene = load(scene_path)
	if not skel_scene:
		return

	var skel = skel_scene.instantiate()
	skel.team = "Neutral"

	var tree = get_tree()
	var am_scene = tree.current_scene if (tree and tree.current_scene) else get_parent()
	if am_scene:
		am_scene.add_child(skel)

	# Position dropping around the tree base
	var drop_offset = Vector3(randf_range(-2.8, 2.8), 0.2, randf_range(-2.8, 2.8))
	skel.global_position = global_position + drop_offset
	_active_defenders.append(skel)

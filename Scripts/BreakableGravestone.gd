extends StaticBody3D
class_name BreakableGravestone

@export var max_health: float = 45.0
@export var spawn_zombie_scene: PackedScene = null
@export var spawn_jack_scene: PackedScene = null

var is_broken: bool = false
var health_comp: HealthComponent = null
var stone_mesh: Node3D = null

func _ready():
	name = "BreakableGravestone"
	add_to_group("Targetable")
	add_to_group("Gravestone")
	add_to_group("NeutralStructure")

	# Collision Shape (Box around tombstone)
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1.1, 1.4, 0.4)
	col.shape = box_shape
	col.position = Vector3(0, 0.7, 0)
	add_child(col)

	# Health Component
	health_comp = HealthComponent.new()
	health_comp.name = "HealthComponent"
	health_comp.max_health = max_health
	health_comp.current_health = max_health
	add_child(health_comp)
	health_comp.died.connect(_on_destroyed)

	_build_tombstone_visual()

func _build_tombstone_visual():
	stone_mesh = Node3D.new()
	stone_mesh.name = "StoneVisual"
	add_child(stone_mesh)

	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.28, 0.28, 0.26) # Weathered graveyard granite
	stone_mat.roughness = 0.92

	var moss_mat = StandardMaterial3D.new()
	moss_mat.albedo_color = Color(0.22, 0.35, 0.18) # Eerie green tombstone moss
	moss_mat.roughness = 0.88

	var dirt_mat = StandardMaterial3D.new()
	dirt_mat.albedo_color = Color(0.16, 0.12, 0.08) # Disturbed grave dirt

	# 1. Disturbed Fresh Grave Mound at Base
	var mound = MeshInstance3D.new()
	var m_cyl = CylinderMesh.new()
	m_cyl.top_radius = 0.7
	m_cyl.bottom_radius = 0.95
	m_cyl.height = 0.22
	mound.mesh = m_cyl
	mound.material_override = dirt_mat
	mound.position = Vector3(0, 0.11, 0)
	stone_mesh.add_child(mound)

	# 2. Main Weathered Stone Slab (Gothic Arch / Arched Top)
	var slab = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.78, 1.05, 0.22)
	slab.mesh = s_box
	slab.material_override = stone_mat
	slab.position = Vector3(0, 0.65, 0)
	stone_mesh.add_child(slab)

	# Arched Cap
	var cap = MeshInstance3D.new()
	var c_cyl = CylinderMesh.new()
	c_cyl.top_radius = 0.39
	c_cyl.bottom_radius = 0.39
	c_cyl.height = 0.22
	cap.mesh = c_cyl
	cap.material_override = stone_mat
	cap.rotation.x = deg_to_rad(90.0)
	cap.position = Vector3(0, 1.17, 0)
	stone_mesh.add_child(cap)

	# 3. Engraved Cross / Skull Motif
	var cross_v = MeshInstance3D.new()
	var cv_box = BoxMesh.new()
	cv_box.size = Vector3(0.08, 0.42, 0.06)
	cross_v.mesh = cv_box
	cross_v.material_override = moss_mat
	cross_v.position = Vector3(0, 0.75, 0.10)
	stone_mesh.add_child(cross_v)

	var cross_h = MeshInstance3D.new()
	var ch_box = BoxMesh.new()
	ch_box.size = Vector3(0.28, 0.08, 0.06)
	cross_h.mesh = ch_box
	cross_h.material_override = moss_mat
	cross_h.position = Vector3(0, 0.82, 0.10)
	stone_mesh.add_child(cross_h)

	# Random slight tilt to make it look ancient and dilapidated
	stone_mesh.rotation.z = randf_range(-0.12, 0.12)
	stone_mesh.rotation.x = randf_range(-0.08, 0.08)

func _on_destroyed():
	if is_broken:
		return
	is_broken = true

	# Spawn either Zombie rising from grave, or Mini Jack-o'-Lantern gas bomber!
	var spawn_pos = global_position + Vector3(0, 0.2, 0)
	var tree = get_tree()
	var am_scene = tree.current_scene if (tree and tree.current_scene) else get_parent()

	var roll = randf()
	if roll < 0.5:
		# Spawn Shambling Zombie
		var z_scene = load("res://Scenes/Units/NightmareZombie.tscn")
		if z_scene:
			var z = z_scene.instantiate()
			z.team = "Neutral"
			if am_scene:
				am_scene.add_child(z)
			z.global_position = spawn_pos
	else:
		# Spawn Mini Jack-o'-Lantern (which explodes into HalloweenGasCloud on death!)
		var j_scene = load("res://Scenes/Units/NightmareJackOLantern.tscn")
		if j_scene:
			var j = j_scene.instantiate()
			j.team = "Neutral"
			if am_scene:
				am_scene.add_child(j)
			j.global_position = spawn_pos

	queue_free()

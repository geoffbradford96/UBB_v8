class_name MagmaRockProjectile
extends Node3D

@export var blast_radius: float = 4.8
@export var blast_damage: float = 45.0

var start_pos: Vector3 = Vector3.ZERO
var target_pos: Vector3 = Vector3.ZERO
var flight_duration: float = 2.4
var elapsed_time: float = 0.0
var arc_height: float = 12.0
var rock_mesh: MeshInstance3D = null
var ember_particles: Array[MeshInstance3D] = []

func _ready():
	_build_visuals()

func launch(from_pos: Vector3, to_pos: Vector3, duration: float = 2.4, peak_height: float = 14.0) -> void:
	start_pos = from_pos
	target_pos = to_pos
	flight_duration = maxf(1.0, duration)
	arc_height = peak_height
	elapsed_time = 0.0
	global_position = start_pos

func _build_visuals() -> void:
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.18, 0.12, 0.12)
	rock_mat.roughness = 0.85
	rock_mat.emission_enabled = true
	rock_mat.emission = Color(1.0, 0.42, 0.05)
	rock_mat.emission_energy_multiplier = 3.5

	rock_mesh = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 0.45
	sph.height = 0.90
	rock_mesh.mesh = sph
	rock_mesh.material_override = rock_mat
	add_child(rock_mesh)

	var core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 0.75, 0.2)
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.8, 0.2)
	core_mat.emission_energy_multiplier = 4.0
	for i in range(4):
		var spark = MeshInstance3D.new()
		var s_sph = SphereMesh.new()
		s_sph.radius = 0.12
		s_sph.height = 0.24
		spark.mesh = s_sph
		spark.material_override = core_mat
		spark.position = Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
		add_child(spark)
		ember_particles.append(spark)

func _process(delta: float) -> void:
	elapsed_time += delta
	var progress = clampf(elapsed_time / flight_duration, 0.0, 1.0)

	# Ballistic Parabolic Arc
	var current_ground = start_pos.lerp(target_pos, progress)
	var current_y = current_ground.y + sin(progress * PI) * arc_height
	global_position = Vector3(current_ground.x, current_y, current_ground.z)

	# Tumble rock in flight
	if rock_mesh:
		rock_mesh.rotation.x += delta * 6.0
		rock_mesh.rotation.y += delta * 4.5

	if progress >= 1.0:
		_on_impact()

func _on_impact() -> void:
	var impact_pos = global_position
	impact_pos.y = 0.0

	# Spawn fiery blast visuals at impact site
	_spawn_impact_fx(impact_pos)

	# AoE Damage Detection
	var units_hit = 0
	if is_inside_tree() and get_tree():
		for node in get_tree().get_nodes_in_group("Targetable"):
			if not is_instance_valid(node) or node == self:
				continue
			if "Volcano" in node.name or node.is_in_group("Volcano") or node.is_in_group("FireMonster"):
				continue
			var d = impact_pos.distance_to(node.global_position)
			if d <= blast_radius:
				units_hit += 1
				var hc = node.get_node_or_null("HealthComponent")
				if hc and not hc.is_dead and hc.has_method("take_damage"):
					hc.take_damage(blast_damage, impact_pos)

	# IF IT HITS NOTHING (Empty ground): Spawns 1 of 3 Magma entities!
	if units_hit == 0 and is_inside_tree() and get_tree():
		_spawn_magma_entity(impact_pos)

	queue_free()

func _spawn_impact_fx(pos: Vector3) -> void:
	var scene_root = get_tree().current_scene if (is_inside_tree() and get_tree() and get_tree().current_scene) else get_parent()
	if not scene_root: return

	var blast_node = Node3D.new()
	scene_root.add_child(blast_node)
	blast_node.global_position = pos

	var lava_mat = StandardMaterial3D.new()
	lava_mat.albedo_color = Color(1.0, 0.45, 0.05)
	lava_mat.emission_enabled = true
	lava_mat.emission = Color(1.0, 0.45, 0.05)
	lava_mat.emission_energy_multiplier = 4.0

	var crater = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 2.0
	cyl.height = 0.15
	crater.mesh = cyl
	crater.material_override = lava_mat
	crater.position.y = 0.08
	blast_node.add_child(crater)

	var tw = blast_node.create_tween()
	if tw:
		tw.tween_property(crater, "scale", Vector3(1.4, 1.0, 1.4), 0.3)
		tw.tween_property(lava_mat, "emission_energy_multiplier", 0.0, 3.5)
		tw.tween_callback(blast_node.queue_free)

func _spawn_magma_entity(pos: Vector3) -> void:
	var scene_root = get_tree().current_scene if (is_inside_tree() and get_tree() and get_tree().current_scene) else get_parent()
	if not scene_root: return

	var roll = randf()
	var entity_scene = null

	if roll < 0.40:
		# 1. Magma Golem (Melee bruiser seeking nearest hostile unit or tower)
		entity_scene = load("res://Scenes/Units/MagmaGolem.tscn")
	elif roll < 0.75:
		# 2. Ranged Magma Spitter OR Airborne Magma Pyrodactyl
		if randf() < 0.5:
			entity_scene = load("res://Scenes/Units/MagmaSpitter.tscn")
		else:
			entity_scene = load("res://Scenes/Units/MagmaPyrodactyl.tscn")
	else:
		# 3. Small Magma Tower / Turret Spire
		entity_scene = load("res://Scenes/Units/MagmaTurretSpire.tscn")

	if entity_scene:
		var unit = entity_scene.instantiate()
		scene_root.add_child(unit)
		unit.global_position = pos
		# Set as neutral volcanic faction hostile to all lane armies
		unit.add_to_group("FireMonster")
		unit.add_to_group("Beast")
		unit.add_to_group("NeutralCreature")
		print("🌋 Magma Rock solidified into ", unit.name, " at ", pos)

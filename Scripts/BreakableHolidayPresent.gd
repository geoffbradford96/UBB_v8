extends StaticBody3D
class_name BreakableHolidayPresent

# =============================================================================
# BREAKABLE HOLIDAY PRESENT — INTERACTIVE YULETIDE SURPRISE
# =============================================================================
# A wrapped holiday gift box scattered across the snow.
# When destroyed by units:
# - 60% Chance: Spawns a festive helper (WinterToySoldier or WinterSnowSprite)
#   aligned to the attacking team!
# - 40% Chance: Explodes in a Festive Fireworks blast (40 damage + knockback)!

@export var max_health: float = 35.0
var health_component: HealthComponent = null
var _last_attacker_team: String = ""

func _ready():
	add_to_group("HolidayPresent")
	add_to_group("Obstacle")
	add_to_group("Targetable")

	_setup_health()
	_setup_collision()
	_build_present_visuals()

func _setup_health() -> void:
	health_component = HealthComponent.new()
	health_component.name = "HealthComponent"
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.died.connect(_on_destroyed)
	add_child(health_component)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.2, 1.2, 1.2)
	col.shape = shape
	col.position.y = 0.6
	add_child(col)

func _build_present_visuals() -> void:
	# Randomize present color scheme (Ruby/Gold, Emerald/Silver, Sapphire/White)
	var box_schemes = [
		{"box": Color(0.85, 0.12, 0.15), "ribbon": Color(1.0, 0.85, 0.20)}, # Classic Crimson & Gold
		{"box": Color(0.12, 0.55, 0.22), "ribbon": Color(0.92, 0.94, 0.98)}, # Fir Green & Silver
		{"box": Color(0.15, 0.35, 0.85), "ribbon": Color(1.0, 0.90, 0.40)}, # Royal Sapphire & Gold
		{"box": Color(0.80, 0.20, 0.70), "ribbon": Color(0.95, 0.95, 0.95)}  # Sugarplum Violet & White
	]
	var chosen = box_schemes[randi() % box_schemes.size()]

	var box_mat = StandardMaterial3D.new()
	box_mat.albedo_color = chosen["box"]
	box_mat.roughness = 0.45

	var ribbon_mat = StandardMaterial3D.new()
	ribbon_mat.albedo_color = chosen["ribbon"]
	ribbon_mat.metallic = 0.70
	ribbon_mat.roughness = 0.30

	# Main Present Box
	var box_mesh = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.0, 1.0, 1.0)
	box_mesh.mesh = b_box
	box_mesh.material_override = box_mat
	box_mesh.position.y = 0.5
	box_mesh.rotation.y = randf_range(-0.4, 0.4)
	add_child(box_mesh)

	# Horizontal & Vertical Ribbons
	var r_h = MeshInstance3D.new()
	var rh_box = BoxMesh.new()
	rh_box.size = Vector3(1.04, 1.02, 0.22)
	r_h.mesh = rh_box
	r_h.material_override = ribbon_mat
	box_mesh.add_child(r_h)

	var r_v = MeshInstance3D.new()
	var rv_box = BoxMesh.new()
	rv_box.size = Vector3(0.22, 1.02, 1.04)
	r_v.mesh = rv_box
	r_v.material_override = ribbon_mat
	box_mesh.add_child(r_v)

	# Ribbon Bow Knot on top
	var bow_knot = MeshInstance3D.new()
	var bk_sphere = SphereMesh.new()
	bk_sphere.radius = 0.16
	bk_sphere.height = 0.30
	bow_knot.mesh = bk_sphere
	bow_knot.material_override = ribbon_mat
	bow_knot.position = Vector3(0, 0.58, 0)
	box_mesh.add_child(bow_knot)

	# Ribbon Loops
	for side in [-1.0, 1.0]:
		var loop = MeshInstance3D.new()
		var l_torus = TorusMesh.new()
		l_torus.inner_radius = 0.08
		l_torus.outer_radius = 0.22
		loop.mesh = l_torus
		loop.material_override = ribbon_mat
		loop.position = Vector3(side * 0.16, 0.68, 0)
		loop.rotation_degrees = Vector3(30, 0, side * 45)
		box_mesh.add_child(loop)

func _on_destroyed() -> void:
	# Identify the nearest attacking unit's team
	if is_inside_tree() and get_tree():
		var nearest_dist = 999.0
		for node in get_tree().get_nodes_in_group("Units"):
			if is_instance_valid(node) and node is Node3D:
				var d = node.global_position.distance_to(global_position)
				if d < nearest_dist:
					nearest_dist = d
					for g in node.get_groups():
						if g.begins_with("Side"):
							_last_attacker_team = g
							break

	var roll = randf()
	var am = get_tree().current_scene if (is_inside_tree() and get_tree()) else get_parent()
	var spawn_pos = global_position + Vector3(0, 0.1, 0)

	if roll < 0.60:
		# 60% Chance: Unwrap festive helper
		var spawn_unit_name = "WinterToySoldier" if randf() < 0.50 else "WinterSnowSprite"
		var u_scene = load("res://Scenes/Units/" + spawn_unit_name + ".tscn")
		if u_scene and am:
			var helper = u_scene.instantiate()
			helper.team = _last_attacker_team if _last_attacker_team != "" else "SideA"
			am.add_child(helper)
			helper.global_position = spawn_pos
			helper.add_to_group(helper.team)
			helper.add_to_group("Units")
			helper.add_to_group("Targetable")
	else:
		# 40% Chance: Festive Fireworks Blast! (40 dmg + AoE knockback to hostiles)
		_trigger_festive_fireworks(spawn_pos, am)

	queue_free()

func _trigger_festive_fireworks(pos: Vector3, arena: Node) -> void:
	if not arena or not is_inside_tree() or not get_tree():
		return

	# Damage nearby hostile units
	for node in get_tree().get_nodes_in_group("Targetable"):
		if is_instance_valid(node) and node is CharacterBody3D:
			if _last_attacker_team != "" and node.is_in_group(_last_attacker_team):
				continue # Protect ally team
			var d = node.global_position.distance_to(pos)
			if d <= 5.5:
				var hc = node.get_node_or_null("HealthComponent")
				if hc and hc.has_method("take_damage"):
					hc.take_damage(40.0, pos)
				# Knockback away from explosion
				var dir = (node.global_position - pos).normalized()
				dir.y = 0.35
				node.velocity += dir * 8.5

	# Visual fireworks spark bursts
	var blast_node = Node3D.new()
	arena.add_child(blast_node)
	blast_node.global_position = pos

	var spark_colors = [
		Color(1.0, 0.2, 0.2), Color(0.2, 0.9, 0.3),
		Color(1.0, 0.85, 0.1), Color(0.2, 0.6, 1.0)
	]
	for i in range(12):
		var spark = MeshInstance3D.new()
		var sp_sphere = SphereMesh.new()
		sp_sphere.radius = 0.15
		sp_sphere.height = 0.30
		spark.mesh = sp_sphere
		var s_mat = StandardMaterial3D.new()
		var c = spark_colors[i % spark_colors.size()]
		s_mat.albedo_color = c
		s_mat.emission_enabled = true
		s_mat.emission = c
		s_mat.emission_energy_multiplier = 4.0
		spark.material_override = s_mat

		var a = randf() * TAU
		var elev = randf_range(0.2, 1.2)
		var rad = randf_range(1.0, 3.2)
		spark.position = Vector3(cos(a) * rad, elev, sin(a) * rad)
		blast_node.add_child(spark)

	# Clean up fireworks visual after brief burst
	var tween = blast_node.create_tween()
	if tween:
		tween.tween_property(blast_node, "scale", Vector3(1.6, 1.6, 1.6), 0.4)
		tween.parallel().tween_property(blast_node, "position:y", pos.y + 0.8, 0.4)
		tween.tween_callback(blast_node.queue_free)
	else:
		blast_node.queue_free()

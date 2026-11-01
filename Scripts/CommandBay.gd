extends CharacterBody3D

@export var unit_attribute: String = "Mechanical"
var faction: String = "Dominion"

@export var damage: float = 5.0
@export var attack_range: float = 10.0
@export var attack_rate: float = 1.0

var current_target: Node3D = null
var attack_timer: float = 0.0

var projectile_scene = preload("res://Scenes/Projectile.tscn")

func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var root = (loop as SceneTree).root
		if root and root.has_node("GameState"):
			return root.get_node("GameState")
	return null

func _ready():
	add_to_group("Targetable")
	var m_inst = get_node_or_null("MeshInstance3D")
	if m_inst and m_inst.get_node_or_null("DishSupportMast") == null:
		var mast = MeshInstance3D.new()
		mast.name = "DishSupportMast"
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.18
		cyl.height = 0.55
		mast.mesh = cyl
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.16, 0.18, 0.20)
		mat.metallic = 0.85
		mat.roughness = 0.35
		mast.material_override = mat
		mast.position = Vector3(0.8, 1.02, 0.0)
		m_inst.add_child(mast)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
		
	velocity.x = 0
	velocity.z = 0
	move_and_slide()
	
	if not has_meta("target_recheck"):
		set_meta("target_recheck", randf_range(0.8, 1.2))
	var __target_timer = get_meta("target_recheck") - delta
	set_meta("target_recheck", __target_timer)
	
	var target_is_dead = false
	if is_instance_valid(current_target):
		var target_hc = current_target.get_node_or_null("HealthComponent")
		if (target_hc and target_hc.is_dead) or not current_target.is_in_group("Targetable"):
			target_is_dead = true
	else:
		current_target = null
			
	if current_target == null or target_is_dead or __target_timer <= 0.0:
		if __target_timer <= 0.0 or target_is_dead: set_meta("target_recheck", randf_range(0.8, 1.2))
		find_new_target()
		
	if is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = attack_range
		if "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist <= effective_range:
			attack_timer += delta
			if attack_timer >= attack_rate:
				attack_timer = 0.0
				shoot()
		else:
			current_target = null

func shoot():
	if not is_instance_valid(current_target): return
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		var scene_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if scene_root:
			scene_root.add_child(proj)
			proj.global_position = global_position + Vector3(0, 1.5, 0)
			proj.target = current_target
			proj.set("damage", damage)
			proj.set("speed", 15.0)
		
		var mesh = proj.get_node_or_null("MeshInstance3D")
		if mesh and mesh.mesh:
			var mat = StandardMaterial3D.new()
			var laser_color = Color(0.2, 1.0, 0.2)
			if faction == "Void": laser_color = Color(0.85, 0.1, 0.85)
			elif faction == "The Reach": laser_color = Color(0.0, 0.85, 1.0)
			elif faction == "Dominion": laser_color = Color(1.0, 0.65, 0.1)
			elif faction == "Pirates": laser_color = Color(1.0, 0.45, 0.1)
			elif faction == "Rimworlders": laser_color = Color(1.0, 0.35, 0.05)
			elif faction == "Plague of Harmony": laser_color = Color(1.0, 0.88, 0.22)
			elif faction == "Gilded Harmony": laser_color = Color(0.56, 0.88, 1.0)
			mat.albedo_color = laser_color
			mat.emission_enabled = true
			mat.emission = laser_color
			mat.emission_energy_multiplier = 2.0
			mesh.material_override = mat

func find_new_target():
	current_target = null
	if not is_inside_tree() or not get_tree():
		return
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"):
			my_team = g
			break
	if my_team == "":
		return
	var closest = 99999.0
	var my_pos = global_position

	for node in get_tree().get_nodes_in_group("Targetable"):
		if node == self or not is_instance_valid(node) or node.is_in_group(my_team):
			continue
		var d = my_pos.distance_to(node.global_position)
		var effective_range = attack_range + 0.5
		if "Base" in node.name:
			effective_range += 5.5
		elif "Tower" in node.name or "CommandBay" in node.name:
			effective_range += 2.5
			
		if d >= effective_range or d >= closest:
			continue
		var target_hc = node.get_node_or_null("HealthComponent")
		if target_hc and target_hc.is_dead:
			continue
		var gs = _get_game_state()
		if gs and gs.is_unit_stealthed_from(node, self):
			continue

		closest = d
		current_target = node

extends StaticBody3D

var faction: String = "Dominion"

@export var unit_attribute: String = "Mechanical"

# This allows you to drag and drop the Projectile.tscn into the inspector
@export var projectile_scene: PackedScene 
@export var team: String = "SideB":
	set(val):
		team = val
		if is_inside_tree():
			for g in get_groups():
				if g.begins_with("Side"):
					remove_from_group(g)
			if team != "":
				add_to_group(team)
		enemy_team = "SideB" if team == "SideA" else "SideA"

var current_target: Node3D = null
var fire_rate = 1.0 # shoots once every second
var fire_timer = 0.0
var enemy_team: String = "SideA"

func _ready():
	add_to_group("Targetable")
	for g in get_groups():
		if g.begins_with("Side"):
			remove_from_group(g)
	add_to_group(team)
	if team == "SideA":
		enemy_team = "SideB"
	else:
		enemy_team = "SideA"
		
	# Connect death signal to update the Comeback Mechanic
	var health = get_node_or_null("HealthComponent")
	if health:
		health.connect("died", Callable(self, "_on_tower_destroyed"))
		
	# Check for units already spawned inside detection area
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var det = get_node_or_null("DetectionArea")
	if det and is_instance_valid(det):
		for b in det.get_overlapping_bodies():
			_on_detection_area_body_entered(b)

func _on_tower_destroyed():
	# If this is a Player tower, tell the ArenaManager to speed up Requisition!
	var tree = get_tree()
	if not tree:
		return
	var manager = tree.current_scene
	if manager and is_instance_valid(manager) and manager.has_method("tower_lost"):
		manager.tower_lost()

var targets_in_range: Array = []
var _target_cleanup_timer: float = 0.0

func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var r = (loop as SceneTree).root
		if r and r.has_node("GameState"):
			return r.get_node("GameState")
	return null

func _process(delta):
	var gs = _get_game_state()
	_target_cleanup_timer -= delta
	if _target_cleanup_timer <= 0.0:
		_target_cleanup_timer = 0.35
		var valid_targets: Array = []
		for t in targets_in_range:
			if is_instance_valid(t) and not t.is_in_group(team):
				var hc = t.get_node_or_null("HealthComponent")
				if hc and not hc.is_dead and t.is_in_group("Targetable") and not (gs and gs.is_unit_stealthed_from(t, self)):
					valid_targets.append(t)
		targets_in_range = valid_targets

	if is_instance_valid(current_target):
		var curr_hc = current_target.get_node_or_null("HealthComponent")
		if (curr_hc and curr_hc.is_dead) or not current_target.is_in_group("Targetable") or current_target.is_in_group(team) or (gs and gs.is_unit_stealthed_from(current_target, self)):
			targets_in_range.erase(current_target)
			current_target = null
	else:
		current_target = null
			
	if current_target == null:
		while targets_in_range.size() > 0:
			var candidate = targets_in_range[0]
			if is_instance_valid(candidate) and not candidate.is_in_group(team):
				var c_hc = candidate.get_node_or_null("HealthComponent")
				if c_hc and not c_hc.is_dead and candidate.is_in_group("Targetable") and not (gs and gs.is_unit_stealthed_from(candidate, self)):
					current_target = candidate
					break
			targets_in_range.pop_front()
			
	if is_instance_valid(current_target):
		var f_mesh = get_meta("faction_mesh", null)
		if f_mesh and is_instance_valid(f_mesh):
			if f_mesh.has_meta("dominion_turret"):
				var turret = f_mesh.get_meta("dominion_turret")
				if is_instance_valid(turret):
					var dir = (current_target.global_position - turret.global_position).normalized()
					var ang = atan2(dir.x, dir.z) - global_rotation.y
					turret.rotation.y = lerp_angle(turret.rotation.y, ang, 8.0 * delta)
		
		fire_timer += delta
		if fire_timer >= fire_rate:
			fire_timer = 0.0
			shoot_at_target()

func shoot_at_target():
	if not is_instance_valid(current_target): return
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		var scene_root: Node = null
		if is_inside_tree() and get_tree() and get_tree().current_scene:
			scene_root = get_tree().current_scene
		else:
			scene_root = get_parent()
		if scene_root:
			scene_root.add_child(proj)
			proj.global_position = global_position + Vector3(0, 6, 0) 
			proj.target = current_target
			proj.set("damage", 25.0)
			proj.set("speed", 25.0)
		
		# Turret firing recoil kick
		var f_mesh = get_meta("faction_mesh", null)
		if f_mesh and is_instance_valid(f_mesh):
			if f_mesh.has_meta("ballista_turret"):
				var b_turret = f_mesh.get_meta("ballista_turret")
				if is_instance_valid(b_turret):
					var tw = create_tween()
					if tw:
						tw.tween_property(b_turret, "position:z", -0.45, 0.05)
						tw.tween_property(b_turret, "position:z", 0.0, 0.22)
			elif f_mesh.has_meta("dominion_turret"):
				var turret = f_mesh.get_meta("dominion_turret")
				if is_instance_valid(turret):
					var tw = create_tween()
					if tw:
						tw.tween_property(turret, "position:z", -0.3, 0.06)
						tw.tween_property(turret, "position:z", 0.0, 0.15)
		
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
			elif faction == "Planetary Primitives":
				# Heavy Ballista Bolt
				proj.set("damage", 45.0)
				proj.set("speed", 28.0)
				var bolt_cyl = CylinderMesh.new()
				bolt_cyl.top_radius = 0.045
				bolt_cyl.bottom_radius = 0.065
				bolt_cyl.height = 1.6
				mesh.mesh = bolt_cyl
				mesh.rotation_degrees.x = 90.0
				laser_color = Color(0.85, 0.70, 0.35)
			mat.albedo_color = laser_color
			mat.emission_enabled = true
			mat.emission = laser_color
			mat.emission_energy_multiplier = 3.0
			mesh.material_override = mat

func _on_detection_area_body_entered(body):
	if body.is_in_group("Targetable") and not body.is_in_group(team):
		if not targets_in_range.has(body):
			targets_in_range.append(body)

func _on_detection_area_body_exited(body):
	if targets_in_range.has(body):
		targets_in_range.erase(body)
	if body == current_target:
		current_target = null





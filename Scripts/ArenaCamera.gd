extends Camera3D

@export var player_id: int = 1 # 1, 2, 3, or 4
@export var assigned_team: String = "SideA"

var target_position: Vector3 = Vector3.ZERO
var is_snapped: bool = false
var hero: Node3D = null

var zoom_level: float = 1.0
var min_zoom: float = 0.4
var max_zoom: float = 6.8

var is_spectator: bool = false
var spectator_view: String = "OVERVIEW" # "OVERVIEW", "SIDE_A", "SIDE_B", "FOLLOW", "FREE"
var follow_target: Node3D = null

func _ready():
	is_spectator = (assigned_team == "Spectator" or GameState.current_mode == "AI_VS_AI")
	if is_spectator:
		snap_to_overview()
	else:
		var start_pos = Vector3(0, 0, 60.0 if assigned_team == "SideA" else -60.0)
		if get_tree():
			for n in get_tree().get_nodes_in_group(assigned_team):
				if is_instance_valid(n) and "Base" in n.name:
					start_pos = n.global_position * 0.72
					break
		target_position = start_pos
		is_snapped = true
		var camera_offset = Vector3(0, 20.0 * zoom_level, 16.0 * zoom_level)
		global_position = target_position + camera_offset

func _process(delta):
	if is_spectator:
		_process_spectator(delta)
		return
		
	# Find the Commander if we don't have one and we're not manually exploring
	if hero == null or not is_instance_valid(hero):
		if is_inside_tree() and get_tree():
			var potential_heroes = get_tree().get_nodes_in_group(assigned_team)
			for p in potential_heroes:
				if p.is_in_group("CommanderUnit") or "Commander" in p.name or "Overlord" in p.name or "GreatBeastSpeaker" in p.name:
					hero = p
					return_to_hero()
					break
	
	# Handle input using our dynamic mapped inputs (p1_up, p2_up, etc)
	var move_dir = Vector3.ZERO
	var prefix = "p" + str(player_id) + "_"
	
	if Input.is_action_pressed(prefix + "up"): move_dir.z -= 1
	if Input.is_action_pressed(prefix + "down"): move_dir.z += 1
	if Input.is_action_pressed(prefix + "left"): move_dir.x -= 1
	if Input.is_action_pressed(prefix + "right"): move_dir.x += 1
		
	if move_dir != Vector3.ZERO:
		if not is_snapped and hero != null and is_instance_valid(hero):
			target_position = hero.global_position
		is_snapped = true
		target_position += move_dir.normalized() * 45.0 * delta * maxf(1.0, zoom_level * 0.85)
		
	var max_pan = maxf(95.0, GameState.current_map_radius * 0.92)
	target_position.x = clamp(target_position.x, -max_pan, max_pan)
	target_position.z = clamp(target_position.z, -max_pan, max_pan)
				
	var camera_offset = Vector3(0, 20.0 * zoom_level, 16.0 * zoom_level)
	
	if is_snapped:
		global_position = global_position.lerp(target_position + camera_offset, 10.0 * delta)
	elif hero != null and is_instance_valid(hero):
		global_position = global_position.lerp(hero.global_position + camera_offset, 10.0 * delta)

func _process_spectator(delta):
	var move_dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move_dir.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move_dir.z += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_dir.x += 1
	
	if move_dir != Vector3.ZERO:
		spectator_view = "FREE"
		follow_target = null
		target_position += move_dir.normalized() * 60.0 * delta * maxf(1.0, zoom_level)
		
	if spectator_view == "FOLLOW" and follow_target != null and is_instance_valid(follow_target):
		target_position = target_position.lerp(follow_target.global_position, 6.0 * delta)
		
	var max_pan = maxf(105.0, GameState.current_map_radius * 0.95)
	target_position.x = clamp(target_position.x, -max_pan, max_pan)
	target_position.z = clamp(target_position.z, -max_pan, max_pan)
	
	var camera_offset = Vector3(0, 22.0 * zoom_level, 18.0 * zoom_level)
	if spectator_view == "SIDE_B":
		camera_offset = Vector3(0, 22.0 * zoom_level, -18.0 * zoom_level)
	elif spectator_view == "OVERVIEW":
		camera_offset = Vector3(0, 36.0 * zoom_level, 10.0 * zoom_level)
		
	global_position = global_position.lerp(target_position + camera_offset, 8.0 * delta)
	if global_position.distance_squared_to(target_position) > 0.01:
		var dir = (target_position - global_position).normalized()
		if absf(dir.dot(Vector3.UP)) < 0.999:
			look_at(target_position, Vector3.UP)
		else:
			look_at(target_position, Vector3.FORWARD)

func snap_to_side_a():
	spectator_view = "SIDE_A"
	follow_target = null
	var map_z = maxf(70.0, GameState.current_map_radius * 0.72)
	target_position = Vector3(0, 0, map_z * 0.55)
	zoom_level = 1.15
	GameState.local_player_team = "SideA"
	_refresh_all_unit_markers_and_bars()

func snap_to_side_b():
	spectator_view = "SIDE_B"
	follow_target = null
	var map_z = maxf(70.0, GameState.current_map_radius * 0.72)
	target_position = Vector3(0, 0, -map_z * 0.55)
	zoom_level = 1.15
	GameState.local_player_team = "SideB"
	_refresh_all_unit_markers_and_bars()

var current_spec_team_idx: int = -1

func snap_to_overview():
	spectator_view = "OVERVIEW"
	follow_target = null
	target_position = Vector3(0, 0, 0)
	zoom_level = clampf(GameState.current_map_radius / 75.0, 1.4, 3.8)
	GameState.local_player_team = "Spectator"
	_refresh_all_unit_markers_and_bars()

func cycle_team_perspective() -> String:
	var active_teams: Array = GameState.active_match_teams
	if active_teams.is_empty():
		active_teams = ["SideA", "SideB"]
	current_spec_team_idx = (current_spec_team_idx + 1) % active_teams.size()
	var chosen_team: String = String(active_teams[current_spec_team_idx])
	snap_to_team(chosen_team)
	return chosen_team

func snap_to_team(team_name: String):
	spectator_view = "TEAM_" + team_name
	follow_target = null
	GameState.local_player_team = team_name
	var found_pos := Vector3.ZERO
	if get_tree():
		for n in get_tree().get_nodes_in_group(team_name):
			if is_instance_valid(n) and "Base" in n.name:
				found_pos = n.global_position * 0.65
				break
	target_position = found_pos
	zoom_level = 1.15
	_refresh_all_unit_markers_and_bars()

func toggle_player_vision():
	GameState.player_vision_enabled = not GameState.player_vision_enabled
	_refresh_all_unit_markers_and_bars()

func _refresh_all_unit_markers_and_bars():
	if not is_inside_tree() or not get_tree(): return
	for u in get_tree().get_nodes_in_group("Targetable"):
		if not is_instance_valid(u): continue
		var hc = u.get_node_or_null("HealthComponent")
		if hc:
			if hc.has_method("update_health_bar_colors"):
				hc.update_health_bar_colors()
			if hc.has_method("update_ground_marker_color"):
				hc.update_ground_marker_color()

func cycle_follow_target():
	if not is_inside_tree() or not get_tree(): return
	var units = []
	for u in get_tree().get_nodes_in_group("Targetable"):
		if is_instance_valid(u) and not "Base" in u.name and not "Tower" in u.name:
			units.append(u)
	if units.is_empty():
		snap_to_overview()
		return
	var curr_idx = units.find(follow_target)
	var next_idx = (curr_idx + 1) % units.size()
	follow_target = units[next_idx]
	spectator_view = "FOLLOW"

func return_to_hero():
	if hero != null and is_instance_valid(hero):
		is_snapped = false
	else:
		var base_pos := Vector3(0, 0, 60.0 if assigned_team == "SideA" else -60.0)
		if get_tree():
			for n in get_tree().get_nodes_in_group(assigned_team):
				if is_instance_valid(n) and "Base" in n.name:
					base_pos = n.global_position * 0.72
					break
		target_position = base_pos
		is_snapped = true

func _unhandled_input(event):
	if is_spectator:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_1: snap_to_side_a()
			elif event.keycode == KEY_2: snap_to_side_b()
			elif event.keycode == KEY_3: snap_to_overview()
			elif event.keycode == KEY_Q: cycle_team_perspective()
			elif event.keycode == KEY_TAB: cycle_follow_target()
			elif event.keycode == KEY_V: toggle_player_vision()
		
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_level = clamp(zoom_level - 0.1, min_zoom, max_zoom)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_level = clamp(zoom_level + 0.1, min_zoom, max_zoom)
		return

	var prefix = "p" + str(player_id) + "_"
	if event.is_action_pressed(prefix + "action"):
		return_to_hero()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C or event.keycode == KEY_HOME:
			return_to_hero()
		
	# Quick zoom check
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = clamp(zoom_level - 0.1, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = clamp(zoom_level + 0.1, min_zoom, max_zoom)


func snap_to(pos: Vector3):
	target_position = pos
	is_snapped = true

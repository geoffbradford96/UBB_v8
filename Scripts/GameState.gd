extends Node

var current_mode = "LOCAL"
var player_faction = "Dominion of Sol"
var local_player_team: String = "SideA"
var player_vision_enabled: bool = true
var previous_menu: String = "res://Scenes/MainMenu.tscn"

# Supports up to 6 local players
var player_decks = {
	"Player1": [],
	"Guest1": [],
	"Guest2": [],
	"Guest3": [],
	"Guest4": [],
	"Guest5": []
}
var editing_profile = "Player1"

var peer = ENetMultiplayerPeer.new()

# Match Setup Options
const ALL_TEAMS: Array[String] = [
	"SideA", "SideB", "SideC", "SideD", "SideE",
	"SideF", "SideG", "SideH", "SideI", "SideJ",
	"SideK", "SideL", "SideM", "SideN", "SideO",
	"SideP", "SideQ", "SideR", "SideS", "SideT",
	"SideU", "SideV", "SideW", "SideX", "SideY"
]

const TEAM_NAMES: Dictionary = {
	"SideA": "Sapphire Blue",
	"SideB": "Crimson Red",
	"SideC": "Emerald Green",
	"SideD": "Solar Amber",
	"SideE": "Royal Magenta",
	"SideF": "Cyber Gold",
	"SideG": "Aqua Cyan",
	"SideH": "Flamingo Pink",
	"SideI": "Acid Lime",
	"SideJ": "Deep Violet",
	"SideK": "Peach Bronze",
	"SideL": "Mint Jade",
	"SideM": "Ruby Rose",
	"SideN": "Cobalt Indigo",
	"SideO": "Polar Frost",
	"SideP": "Coral Sunset",
	"SideQ": "Electric Chartreuse",
	"SideR": "Amethyst Plum",
	"SideS": "Electric Teal",
	"SideT": "Blazing Tangerine",
	"SideU": "Forest Emerald",
	"SideV": "Neon Fuchsia",
	"SideW": "Goldenrod Sand",
	"SideX": "Deep Sea Azure",
	"SideY": "Blood Garnet"
}

var ai_difficulty: String = "MEDIUM"
var ai_faction_override: String = "RANDOM" # "RANDOM" (Dice Roll with Chaos included), or specific faction
var game_mode: String = "DOMINATION" # "DOMINATION", "DESTROY_BASE", "KOTH", "FFA_DOMINATION", "FFA_KOTH"
var map_selected: String = "Arena.tscn"
var map_layout_id: String = "CLASSIC_1V1"
var team_comp: String = "2_TEAMS" # "2_TEAMS", "3_TEAMS", "4_TEAMS", "5_TEAMS", "6_TEAMS", "8_TEAMS", "FFA", "ASYM_*"
var map_biome: String = "RANDOM"
var match_player_count: int = 2
var sudden_death_timer: float = 600.0
var current_map_radius: float = 125.0
var lane_segments: Array = [] # Array of {"a": Vector3, "b": Vector3, "width": float}
var active_match_teams: Array[String] = ["SideA", "SideB"]
var slot_teams: Array[String] = ["SideA", "SideB"]
var energy_penalty_per_extra_player: float = 0.35

# Online & Private Room Settings
var room_privacy: String = "PUBLIC" # "PUBLIC", "PRIVATE"
var room_code: String = "UBB25"
var network_port: int = 8910
var max_online_players: int = 25
var player_display_name: String = "Commander 1"

# Corpse & Battlefield Debris Settings
var corpse_max_count: int = 30 # Options: 10, 30, 60, 120
var corpse_duration: float = 15.0 # Options: 5.0, 15.0, 30.0, 60.0, -1.0 (Permanent)
var active_corpses: Array = []

# v8 Optimization, Environment Pre-Rendering & GPU Acceleration Settings
var version_tag: String = "v0.8"
var gpu_acceleration_enabled: bool = true
var environment_pre_render_enabled: bool = true
var lod_max_distance: float = 220.0

func _ready():
	print("Global GameState is active!")
	load_decks()
	load_settings()

func _exit_tree():
	var pre_script = load("res://Scripts/EnvironmentPreRenderer.gd")
	if pre_script and pre_script.has_method("clear_caches"):
		pre_script.clear_caches()

func load_settings():
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		corpse_max_count = cfg.get_value("gameplay", "corpse_max_count", 30)
		corpse_duration = cfg.get_value("gameplay", "corpse_duration", 15.0)

func register_corpse(corpse_node: Node3D):
	if not is_instance_valid(corpse_node): return
	active_corpses.append(corpse_node)
	while active_corpses.size() > max(1, corpse_max_count):
		var oldest = active_corpses.pop_front()
		if is_instance_valid(oldest):
			_fade_and_free_corpse(oldest)
	if corpse_duration > 0.0:
		var tw = corpse_node.create_tween()
		if tw:
			tw.tween_interval(corpse_duration)
			tw.tween_callback(Callable(self, "_on_corpse_expired").bind(corpse_node))
		else:
			_on_corpse_expired(corpse_node)

func _on_corpse_expired(corpse_node: Node3D):
	active_corpses.erase(corpse_node)
	if is_instance_valid(corpse_node):
		_fade_and_free_corpse(corpse_node)

func _fade_and_free_corpse(node: Node3D):
	if not is_instance_valid(node): return
	var tw = node.create_tween()
	if tw:
		tw.tween_property(node, "scale", node.scale * 0.001, 1.2)
		tw.tween_callback(node.queue_free)
	else:
		node.queue_free()
	
func save_decks():
	var save_path = "user://local_decks.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json = JSON.stringify(player_decks)
		file.store_string(json)
		file.close()
		
func load_decks():
	var load_path = "user://local_decks.json"
	if FileAccess.file_exists(load_path):
		var file = FileAccess.open(load_path, FileAccess.READ)
		var json = file.get_as_text()
		file.close()
		
		var parsed = JSON.parse_string(json)
		if typeof(parsed) == TYPE_DICTIONARY:
			for key in parsed.keys():
				player_decks[key] = parsed[key]
				
	if not player_decks.has("Player1") or player_decks["Player1"].is_empty():
		player_decks["Player1"] = ["CommanderCard", "CheapGruntCard", "SupportingFireCard", "MedicCard", "CallArtilleryCard", "SniperCard"]
	if not player_decks.has("Guest1") or player_decks["Guest1"].is_empty():
		player_decks["Guest1"] = ["VoidOverlordCard", "VoidCrawlerCard", "VoidSpitterCard", "VoidStalkerCard", "VoidMeteorCard", "VoidSpikerCard"]
	if not player_decks.has("Guest2") or player_decks["Guest2"].is_empty():
		player_decks["Guest2"] = ["GreatBeastSpeakerCard", "RimworlderGunnerCard", "RimworlderMeleeCard", "SkyBeetleCard", "StoneOctopusCard", "RimworlderLeviathanCard"]
	if not player_decks.has("Guest3") or player_decks["Guest3"].is_empty():
		player_decks["Guest3"] = ["ScrapCommanderCard", "ScrapMeleeCard", "ScrapRangedCard", "ScrapTankCard", "ScrapPlaneCard", "ScrapMechCard"]
	if not player_decks.has("Guest4") or player_decks["Guest4"].is_empty():
		player_decks["Guest4"] = ["ReachCommanderCard", "ReachMeleeCard", "ReachRangedCard", "ReachTankCard", "ReachPlaneCard", "ReachMechCard"]
	if not player_decks.has("Guest5") or player_decks["Guest5"].is_empty():
		player_decks["Guest5"] = ["CommanderCard", "HeavyTankCard", "DominionMechCard", "FighterPlaneCard", "HeroHunterCard", "RepairManCard"]

# Backwards compatibility for older scripts that used player_deck
var player_deck:
	get:
		return player_decks["Player1"]
	set(value):
		player_decks["Player1"] = value

func host_game(port: int = -1, max_players: int = -1, code: String = "") -> Error:
	disconnect_multiplayer()
	peer = ENetMultiplayerPeer.new()
	if port > 0:
		network_port = port
	if max_players >= 2:
		max_online_players = clampi(max_players, 2, 25)
	else:
		max_online_players = clampi(match_player_count, 2, 25)
	if code != "":
		room_code = code.to_upper().strip_edges()
		room_privacy = "PRIVATE"
	var error = peer.create_server(network_port, max_online_players) 
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Hosting game on port ", network_port, " (Max Players: ", max_online_players, ", Privacy: ", room_privacy, ", Room Code: ", room_code, ")")
	else:
		print("Failed to host game on port ", network_port, ": Error ", error)
	return error

func join_game(ip: String, port: int = -1, code_attempt: String = "") -> Error:
	disconnect_multiplayer()
	peer = ENetMultiplayerPeer.new()
	var clean_ip = ip.strip_edges()
	if clean_ip.is_empty():
		clean_ip = "127.0.0.1"
	if port > 0:
		network_port = port
	if code_attempt != "":
		room_code = code_attempt.to_upper().strip_edges()
	var error = peer.create_client(clean_ip, network_port)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Connecting to game at ", clean_ip, ":", network_port, " (Room Code: ", room_code, ")")
	else:
		print("Failed to join game at ", clean_ip, ":", network_port, " Error ", error)
	return error

func disconnect_multiplayer():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer = null
	if peer:
		peer.close()
	peer = ENetMultiplayerPeer.new()

func is_unit_stealthed_from(target: Node3D, observer: Node3D) -> bool:
	if not is_instance_valid(target) or not target.is_inside_tree(): return false
	if not target.has_meta("in_stealth_grass"): return false
	if not (target.has_meta("in_stealth_grass") and bool(target.get_meta("in_stealth_grass"))): return false
	
	# Flying units NEVER get stealth in grass
	if "Plane" in target.name or target.get("flight_height") != null or target.get("is_flying") == true or target.get("unit_attribute") == "Flying":
		return false
	if target.global_position.y > 4.5:
		return false
		
	# If target recently fired/attacked, it is temporarily revealed for retaliation
	if target.has_meta("stealth_revealed_timer"):
		if target.has_meta("stealth_revealed_timer") and float(target.get_meta("stealth_revealed_timer")) > 0.0:
			return false
		
	# Friendly / same team check
	if observer != null and is_instance_valid(observer) and observer.is_inside_tree():
		var target_team = ""
		for g in target.get_groups():
			if g.begins_with("Side") or g == "Beast": target_team = g
		if target_team != "" and observer.is_in_group(target_team):
			return false
			
		# Close proximity face-to-face detection
		if target.global_position.distance_to(observer.global_position) <= 4.0:
			return false
			
		# Same stealth brush zone
		if observer.has_meta("current_brush_zone") and target.has_meta("current_brush_zone"):
			var obs_brush = observer.get_meta("current_brush_zone")
			var tgt_brush = target.get_meta("current_brush_zone")
			if obs_brush != null and obs_brush == tgt_brush and target.global_position.distance_to(observer.global_position) <= 7.0:
				return false
				
	return true

func is_koth_mode() -> bool:
	return game_mode == "KOTH" or game_mode == "FFA_KOTH"

func is_domination_mode() -> bool:
	return game_mode == "DOMINATION" or game_mode == "DESTROY_BASE" or game_mode == "FFA_DOMINATION"

func is_ffa_mode() -> bool:
	return team_comp == "FFA" or game_mode == "FFA_DOMINATION" or game_mode == "FFA_KOTH"

func get_team_color(team_name: String) -> Color:
	match team_name:
		"SideA": return Color(0.20, 0.65, 1.00) # Sapphire Blue
		"SideB": return Color(0.95, 0.22, 0.22) # Crimson Red
		"SideC": return Color(0.20, 0.88, 0.40) # Emerald Green
		"SideD": return Color(1.00, 0.58, 0.12) # Solar Amber
		"SideE": return Color(0.88, 0.22, 0.88) # Royal Magenta
		"SideF": return Color(0.96, 0.92, 0.20) # Cyber Gold
		"SideG": return Color(0.12, 0.94, 0.92) # Aqua Cyan
		"SideH": return Color(1.00, 0.38, 0.65) # Flamingo Pink
		"SideI": return Color(0.62, 0.96, 0.16) # Acid Lime
		"SideJ": return Color(0.58, 0.34, 1.00) # Deep Violet
		"SideK": return Color(1.00, 0.76, 0.42) # Peach Bronze
		"SideL": return Color(0.22, 0.92, 0.68) # Mint Jade
		"SideM": return Color(0.92, 0.16, 0.48) # Ruby Rose
		"SideN": return Color(0.36, 0.50, 1.00) # Cobalt Indigo
		"SideO": return Color(0.82, 0.86, 0.96) # Polar Frost
		"SideP": return Color(1.00, 0.45, 0.32) # Coral Sunset
		"SideQ": return Color(0.78, 1.00, 0.18) # Electric Chartreuse
		"SideR": return Color(0.72, 0.25, 0.95) # Amethyst Plum
		"SideS": return Color(0.10, 0.88, 0.76) # Electric Teal
		"SideT": return Color(1.00, 0.42, 0.00) # Blazing Tangerine
		"SideU": return Color(0.18, 0.78, 0.32) # Forest Emerald
		"SideV": return Color(1.00, 0.15, 0.75) # Neon Fuchsia
		"SideW": return Color(0.92, 0.75, 0.12) # Goldenrod Sand
		"SideX": return Color(0.12, 0.48, 0.96) # Deep Sea Azure
		"SideY": return Color(0.85, 0.10, 0.25) # Blood Garnet
		_: return Color(0.65, 0.65, 0.65)

func get_team_color_name(team_name: String) -> String:
	return String(TEAM_NAMES.get(team_name, "Neutral Neutral"))

func get_team_display_name(team_name: String) -> String:
	var idx: int = ALL_TEAMS.find(team_name)
	var num_str: String = str(idx + 1) if idx >= 0 else "?"
	var col_name: String = get_team_color_name(team_name)
	return "Team " + num_str + " [" + col_name + "]"

func get_teams_for_slots(total_slots: int, comp_override: String = "") -> Array[String]:
	var count: int = clampi(total_slots, 2, 25)
	var eff_comp: String = comp_override if comp_override != "" else team_comp
	var eff_upper: String = eff_comp.to_upper()
	if eff_upper == "FFA" or (comp_override == "" and is_ffa_mode()):
		var ffa_teams: Array[String] = []
		for i in range(count):
			ffa_teams.append(ALL_TEAMS[i % ALL_TEAMS.size()])
		slot_teams = ffa_teams.duplicate()
		return ffa_teams

	if eff_upper.begins_with("ASYM_"):
		var raw_split: String = eff_upper.trim_prefix("ASYM_")
		var parts: PackedStringArray = raw_split.split("V")
		var split_counts: Array[int] = []
		for p_str: String in parts:
			var val: int = p_str.to_int()
			if val > 0:
				split_counts.append(val)
		if split_counts.size() >= 2:
			var asym_assigned: Array[String] = []
			for t_idx in range(split_counts.size()):
				var c_num: int = split_counts[t_idx]
				var t_name: String = ALL_TEAMS[t_idx % ALL_TEAMS.size()]
				for _k in range(c_num):
					if asym_assigned.size() < count:
						asym_assigned.append(t_name)
			var fallback_team: String = ALL_TEAMS[mini(split_counts.size() - 1, ALL_TEAMS.size() - 1)]
			while asym_assigned.size() < count:
				asym_assigned.append(fallback_team)
			slot_teams = asym_assigned.duplicate()
			return asym_assigned

	var num_teams: int = 2
	if eff_upper in ["3_TEAMS", "2V2V2", "3V3V3", "4V4V4", "5V5V5", "3X3", "3X5"]:
		num_teams = 3
	elif eff_upper in ["4_TEAMS", "2V2V2V2", "3V3V3V3", "4V4V4V4", "4X4", "4X5"]:
		num_teams = 4
	elif eff_upper in ["5_TEAMS", "5X5", "2X5", "5X4", "5X3", "5X2"]:
		num_teams = 5
	elif eff_upper in ["6_TEAMS", "2X6", "6X2", "6X3", "6X4"]:
		num_teams = 6
	elif eff_upper in ["8_TEAMS", "2X8", "8X2", "8X3"]:
		num_teams = 8
	elif eff_upper in ["10_TEAMS", "2X10", "10X2"]:
		num_teams = 10
	elif eff_upper in ["12_TEAMS", "2X12", "12X2"]:
		num_teams = 12
	elif eff_upper.begins_with("3"): num_teams = 3
	elif eff_upper.begins_with("4"): num_teams = 4
	elif eff_upper.begins_with("5") and eff_upper != "5V5": num_teams = 5
	elif eff_upper.begins_with("6") and eff_upper != "6V6": num_teams = 6
	elif eff_upper.begins_with("8") and eff_upper != "8V8": num_teams = 8
	elif eff_upper.begins_with("10") and eff_upper != "10V10": num_teams = 10
	elif eff_upper.begins_with("12") and eff_upper != "12V12": num_teams = 12
	num_teams = clampi(num_teams, 2, count)

	var assigned: Array[String] = []
	for i in range(count):
		# Group contiguous slots into balanced teams so Slot 0 (Player 1) and nearby slots share SideA
		var t_idx: int = int(floor(float(i * num_teams) / float(count)))
		t_idx = clampi(t_idx, 0, num_teams - 1)
		assigned.append(ALL_TEAMS[t_idx])
	slot_teams = assigned.duplicate()
	return assigned

func get_team_player_count(team_name: String) -> int:
	var c: int = 0
	for t: String in slot_teams:
		if t == team_name:
			c += 1
	return maxi(1, c)

func get_min_team_player_count() -> int:
	if active_match_teams.size() <= 1 and slot_teams.is_empty():
		return 1
	var counts := {}
	for t: String in slot_teams:
		counts[t] = int(counts.get(t, 0)) + 1
	if counts.is_empty():
		return 1
	var min_c: int = 999
	for k in counts.keys():
		var val: int = int(counts[k])
		if val > 0 and val < min_c:
			min_c = val
	return min_c if min_c < 999 else 1

func get_team_extra_players(team_name: String) -> int:
	var my_c: int = get_team_player_count(team_name)
	var min_c: int = get_min_team_player_count()
	return maxi(0, my_c - min_c)

func get_team_energy_multiplier(team_name: String) -> float:
	var extra: int = get_team_extra_players(team_name)
	if extra <= 0:
		return 1.0
	return 1.0 / (1.0 + float(extra) * energy_penalty_per_extra_player)

func get_team_energy_penalty_pct(team_name: String) -> int:
	var mult: float = get_team_energy_multiplier(team_name)
	return int(round((1.0 - mult) * 100.0))

func is_asymmetric_match() -> bool:
	var min_c: int = get_min_team_player_count()
	for t: String in active_match_teams:
		if get_team_player_count(t) > min_c:
			return true
	return false

# Pre-baked 2D spatial lookup grid for environment lane distance & pull vectors
const LANE_GRID_CELL_SIZE: float = 2.5
var _lane_grid_half_extent: float = 450.0
var _lane_grid_dim: int = 361
var _lane_closest_grid: PackedVector2Array = PackedVector2Array()
var _lane_valid_grid: PackedByteArray = PackedByteArray()
var _lane_grid_baked_seg_count: int = -1

func bake_lane_spatial_grid() -> void:
	if lane_segments.is_empty():
		_lane_closest_grid.clear()
		_lane_valid_grid.clear()
		_lane_grid_baked_seg_count = 0
		return

	_lane_grid_half_extent = maxf(160.0, current_map_radius + 45.0)
	_lane_grid_dim = int(ceil((_lane_grid_half_extent * 2.0) / LANE_GRID_CELL_SIZE)) + 1
	var total_cells: int = _lane_grid_dim * _lane_grid_dim
	_lane_closest_grid.resize(total_cells)
	_lane_valid_grid.resize(total_cells)
	_lane_valid_grid.fill(0)
	_lane_grid_baked_seg_count = lane_segments.size()

	# Pre-bake all cells along the active lane corridors immediately so common unit paths are warm from frame 0
	for seg in lane_segments:
		var a3: Vector3 = seg.get("a", Vector3.ZERO)
		var b3: Vector3 = seg.get("b", Vector3.ZERO)
		var margin: float = float(seg.get("width", 22.0)) * 0.5 + 14.0
		var min_x: float = minf(a3.x, b3.x) - margin
		var max_x: float = maxf(a3.x, b3.x) + margin
		var min_z: float = minf(a3.z, b3.z) - margin
		var max_z: float = maxf(a3.z, b3.z) + margin
		var gx0: int = clampi(int(floor((min_x + _lane_grid_half_extent) / LANE_GRID_CELL_SIZE)), 0, _lane_grid_dim - 1)
		var gx1: int = clampi(int(ceil((max_x + _lane_grid_half_extent) / LANE_GRID_CELL_SIZE)), 0, _lane_grid_dim - 1)
		var gz0: int = clampi(int(floor((min_z + _lane_grid_half_extent) / LANE_GRID_CELL_SIZE)), 0, _lane_grid_dim - 1)
		var gz1: int = clampi(int(ceil((max_z + _lane_grid_half_extent) / LANE_GRID_CELL_SIZE)), 0, _lane_grid_dim - 1)
		for gz in range(gz0, gz1 + 1):
			var row_offset: int = gz * _lane_grid_dim
			var cz: float = -_lane_grid_half_extent + float(gz) * LANE_GRID_CELL_SIZE
			for gx in range(gx0, gx1 + 1):
				var idx: int = row_offset + gx
				if _lane_valid_grid[idx] == 0:
					var cx: float = -_lane_grid_half_extent + float(gx) * LANE_GRID_CELL_SIZE
					_lane_closest_grid[idx] = _compute_exact_nearest_lane_point(Vector2(cx, cz))
					_lane_valid_grid[idx] = 1

func _compute_exact_nearest_lane_point(p2: Vector2) -> Vector2:
	var min_d_sq := 999999999.0
	var best_closest := p2
	for seg in lane_segments:
		var a3: Vector3 = seg.get("a", Vector3.ZERO)
		var b3: Vector3 = seg.get("b", Vector3.ZERO)
		var a2 := Vector2(a3.x, a3.z)
		var b2 := Vector2(b3.x, b3.z)
		var ab := b2 - a2
		var len_sq := ab.length_squared()
		var t := 0.0
		if len_sq > 0.001:
			t = clampf((p2 - a2).dot(ab) / len_sq, 0.0, 1.0)
		var closest := a2 + ab * t
		var d_sq := p2.distance_squared_to(closest)
		if d_sq < min_d_sq:
			min_d_sq = d_sq
			best_closest = closest
	return best_closest

func _get_cached_nearest_lane_point(px: float, pz: float) -> Vector2:
	if _lane_grid_baked_seg_count != lane_segments.size() or _lane_valid_grid.is_empty():
		bake_lane_spatial_grid()
	var gx: int = clampi(int(round((px + _lane_grid_half_extent) / LANE_GRID_CELL_SIZE)), 0, _lane_grid_dim - 1)
	var gz: int = clampi(int(round((pz + _lane_grid_half_extent) / LANE_GRID_CELL_SIZE)), 0, _lane_grid_dim - 1)
	var idx: int = gz * _lane_grid_dim + gx
	if _lane_valid_grid[idx] == 1:
		return _lane_closest_grid[idx]
	var cx: float = -_lane_grid_half_extent + float(gx) * LANE_GRID_CELL_SIZE
	var cz: float = -_lane_grid_half_extent + float(gz) * LANE_GRID_CELL_SIZE
	var pt: Vector2 = _compute_exact_nearest_lane_point(Vector2(cx, cz))
	_lane_closest_grid[idx] = pt
	_lane_valid_grid[idx] = 1
	return pt

func get_distance_to_nearest_lane(pos: Vector3) -> float:
	if lane_segments.size() > 0:
		var closest: Vector2 = _get_cached_nearest_lane_point(pos.x, pos.z)
		return Vector2(pos.x, pos.z).distance_to(closest)

	if map_selected == "Arena_6P.tscn":
		var r = Vector2(pos.x, pos.z).length()
		if r < 18.0: return 0.0 # Central hub junction
		var ang = atan2(pos.z, pos.x)
		var lane_ang = round((ang - PI / 6.0) / (PI / 3.0)) * (PI / 3.0) + (PI / 6.0)
		var dir = Vector3(cos(lane_ang), 0, sin(lane_ang))
		var proj = Vector3(pos.x, 0, pos.z).dot(dir)
		var closest = dir * max(0.0, proj)
		return Vector3(pos.x, 0, pos.z).distance_to(closest)
	elif map_selected == "Arena_4P.tscn":
		var r = Vector2(pos.x, pos.z).length()
		if r < 15.0: return 0.0 # Center
		return min(abs(pos.x), abs(pos.z))
	else: # Default 1v1 Arena
		return abs(pos.x)

func get_vector_towards_nearest_lane(pos: Vector3) -> Vector3:
	if lane_segments.size() > 0:
		var closest: Vector2 = _get_cached_nearest_lane_point(pos.x, pos.z)
		var to_lane := Vector3(closest.x - pos.x, 0.0, closest.y - pos.z)
		if to_lane.length_squared() > 0.001:
			return to_lane.normalized()
		return Vector3.ZERO

	if map_selected == "Arena_6P.tscn":
		var r = Vector2(pos.x, pos.z).length()
		if r < 18.0: return Vector3.ZERO
		var ang = atan2(pos.z, pos.x)
		var lane_ang = round((ang - PI / 6.0) / (PI / 3.0)) * (PI / 3.0) + (PI / 6.0)
		var dir = Vector3(cos(lane_ang), 0, sin(lane_ang))
		var proj = Vector3(pos.x, 0, pos.z).dot(dir)
		var closest = dir * max(0.0, proj)
		var to_lane = closest - Vector3(pos.x, 0, pos.z)
		if to_lane.length_squared() > 0.01:
			return to_lane.normalized()
		return Vector3.ZERO
	elif map_selected == "Arena_4P.tscn":
		var r = Vector2(pos.x, pos.z).length()
		if r < 15.0: return Vector3.ZERO
		if abs(pos.x) < abs(pos.z):
			return Vector3(-sign(pos.x), 0, 0)
		else:
			return Vector3(0, 0, -sign(pos.z))
	else:
		return Vector3(-sign(pos.x), 0, 0)



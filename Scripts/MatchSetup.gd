extends Control

const MapLayoutBuilderScript = preload("res://Scripts/MapLayoutBuilder.gd")

@onready var role_option = $CenterContainer/VBoxContainer/HBoxRole/RoleDropdown
@onready var map_option = $CenterContainer/VBoxContainer/HBoxMap/MapDropdown
@onready var biome_option = $CenterContainer/VBoxContainer/HBoxBiome/BiomeDropdown
@onready var mode_option = $CenterContainer/VBoxContainer/HBoxMode/ModeDropdown
@onready var players_option = $CenterContainer/VBoxContainer/HBoxPlayers/PlayersDropdown
@onready var diff_option = $CenterContainer/VBoxContainer/HBoxDiff/DiffDropdown
@onready var timer_option = $CenterContainer/VBoxContainer/HBoxTimer/TimerDropdown

var ai_faction_option: OptionButton = null
var current_map_comps: Array = []

func _ready():
	var players_lbl = $CenterContainer/VBoxContainer/HBoxPlayers.get_node_or_null("Label")
	if players_lbl:
		players_lbl.text = "Players & Team Comp"

	role_option.add_item("Play as Player 1")
	role_option.add_item("Spectate (AI vs AI)")
	if GameState.current_mode == "AI_VS_AI":
		role_option.select(1)
	else:
		role_option.select(0)
	
	for entry in MapLayoutBuilderScript.MAP_CATALOG:
		map_option.add_item(entry["title"])
	map_option.add_item("Random Map & Size (2P - 25P)")

	biome_option.add_item("Sunny Plains")
	biome_option.add_item("Scorching Sand Dunes")
	biome_option.add_item("The Realm of Harmony")
	biome_option.add_item("Glacial Frozen Tundra")
	biome_option.add_item("Volcanic Brimstone")
	biome_option.add_item("Deep Space Vacuum")
	biome_option.add_item("Verdant Deep Jungle")
	biome_option.add_item("Random Biome")
	biome_option.select(7) # Default to Random Biome
	
	mode_option.add_item("Domination (Destroy Every Base)")
	mode_option.add_item("King of the Hill")
	mode_option.add_item("Free For All — Domination")
	mode_option.add_item("Free For All — King of the Hill")
	
	diff_option.add_item("Easy")
	diff_option.add_item("Medium")
	diff_option.add_item("Hard")
	diff_option.select(1) # Default to Medium
	
	# AI Factions Selection (Random Dice Roll including Chaos by default)
	var v_box = $CenterContainer/VBoxContainer
	var diff_box = v_box.get_node_or_null("HBoxDiff")
	if diff_box:
		var faction_box = HBoxContainer.new()
		faction_box.name = "HBoxAIFaction"
		var faction_lbl = Label.new()
		faction_lbl.custom_minimum_size = Vector2(250, 0)
		faction_lbl.add_theme_font_size_override("font_size", 24)
		faction_lbl.text = "AI Factions"
		faction_box.add_child(faction_lbl)

		ai_faction_option = OptionButton.new()
		ai_faction_option.custom_minimum_size = Vector2(250, 0)
		ai_faction_option.add_theme_font_size_override("font_size", 24)
		ai_faction_option.add_item("🎲 Random Dice Roll (All 9 + Chaos)") # 0
		ai_faction_option.add_item("Dominion of Sol")                    # 1
		ai_faction_option.add_item("The Reach")                          # 2
		ai_faction_option.add_item("Pirates")                            # 3
		ai_faction_option.add_item("Rimworlders")                        # 4
		ai_faction_option.add_item("The Void")                           # 5
		ai_faction_option.add_item("Plague of Harmony")                  # 6
		ai_faction_option.add_item("Gilded Harmony")                     # 7
		ai_faction_option.add_item("Planetary Primitives")               # 8
		ai_faction_option.add_item("Galactic Wildlife")                  # 9
		ai_faction_option.add_item("Chaos (Completely Random Deck)")     # 10
		ai_faction_option.select(0) # Default to Random Dice Roll
		faction_box.add_child(ai_faction_option)

		v_box.add_child(faction_box)
		v_box.move_child(faction_box, diff_box.get_index() + 1)

	timer_option.add_item("2.5 Minutes") # 0
	timer_option.add_item("5 Minutes")   # 1
	timer_option.add_item("10 Minutes")  # 2
	timer_option.add_item("15 Minutes")  # 3
	timer_option.add_item("20 Minutes")  # 4
	timer_option.add_item("25 Minutes")  # 5
	timer_option.add_item("30 Minutes")  # 6
	timer_option.add_item("35 Minutes")  # 7
	timer_option.add_item("40 Minutes")  # 8
	timer_option.add_item("45 Minutes")  # 9
	timer_option.add_item("50 Minutes")  # 10
	timer_option.add_item("55 Minutes")  # 11
	timer_option.add_item("60 Minutes")  # 12
	timer_option.select(2) # Default 10 min
	
	if not map_option.item_selected.is_connected(_on_map_item_selected):
		map_option.item_selected.connect(_on_map_item_selected)
	if not players_option.item_selected.is_connected(_on_players_item_selected):
		players_option.item_selected.connect(_on_players_item_selected)

	_update_players_dropdown(0)
	_build_roster_preview_ui()
	_update_roster_preview()
	
	GameState.ai_difficulty = "MEDIUM"
	GameState.ai_faction_override = "RANDOM"
	GameState.game_mode = "DOMINATION"
	GameState.map_selected = "Arena.tscn"
	GameState.map_layout_id = "CLASSIC_1V1"
	GameState.team_comp = "2_TEAMS"
	if GameState.current_mode != "ONLINE_HOST":
		GameState.match_player_count = 2
	GameState.sudden_death_timer = 600.0

var roster_preview_lbl: Label = null
var net_status_banner: Label = null

func _build_roster_preview_ui():
	var bg = get_node_or_null("ColorRect")
	if bg:
		bg.color = Color(0.06, 0.10, 0.16, 1.0)
	var top_trim = ColorRect.new()
	top_trim.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_trim.offset_bottom = 10.0
	top_trim.color = Color(0.88, 0.74, 0.22, 1.0)
	add_child(top_trim)
	var bot_trim = ColorRect.new()
	bot_trim.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_trim.offset_top = -10.0
	bot_trim.color = Color(0.18, 0.78, 0.95, 1.0)
	add_child(bot_trim)

	var back_btn = get_node_or_null("BackBtn")
	if back_btn is Button:
		var bst = StyleBoxFlat.new()
		bst.bg_color = Color(0.12, 0.19, 0.29, 0.95)
		bst.border_color = Color(0.82, 0.70, 0.24, 1.0)
		bst.set_border_width_all(2)
		bst.set_corner_radius_all(6)
		back_btn.add_theme_stylebox_override("normal", bst)

	var v_box = $CenterContainer/VBoxContainer
	if not v_box: return
	var title_lbl = v_box.get_node_or_null("Title")
	if not title_lbl:
		title_lbl = v_box.get_node_or_null("Label")
	if title_lbl:
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
	var start_btn = v_box.get_node_or_null("StartBtn")
	if start_btn is Button:
		var st = StyleBoxFlat.new()
		st.bg_color = Color(0.14, 0.38, 0.22, 0.95)
		st.border_color = Color(0.40, 0.95, 0.55, 1.0)
		st.set_border_width_all(2)
		st.set_corner_radius_all(6)
		start_btn.add_theme_stylebox_override("normal", st)

	net_status_banner = Label.new()
	net_status_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	net_status_banner.add_theme_font_size_override("font_size", 14)
	if GameState.current_mode == "ONLINE_HOST":
		var priv_text = "Private (Room Code: " + GameState.room_code + ")" if GameState.room_privacy == "PRIVATE" else "Public Room"
		net_status_banner.text = "HOSTING ONLINE SERVER on Port " + str(GameState.network_port) + " | " + priv_text + " | Max " + str(GameState.max_online_players) + " Players"
		net_status_banner.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		net_status_banner.text = "LOCAL / SANDBOX MATCH CONFIGURATION"
		net_status_banner.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
	v_box.add_child(net_status_banner)
	v_box.move_child(net_status_banner, 2)

	roster_preview_lbl = Label.new()
	roster_preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roster_preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roster_preview_lbl.add_theme_font_size_override("font_size", 13)
	roster_preview_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	v_box.add_child(roster_preview_lbl)
	v_box.move_child(roster_preview_lbl, v_box.get_child_count() - 2)


func _update_roster_preview():
	if not roster_preview_lbl: return
	var catalog_size: int = MapLayoutBuilderScript.MAP_CATALOG.size()
	var sel_map_idx: int = map_option.selected
	var entry: Dictionary = MapLayoutBuilderScript.MAP_CATALOG[sel_map_idx] if (sel_map_idx >= 0 and sel_map_idx < catalog_size) else MapLayoutBuilderScript.MAP_CATALOG[0]
	var comp_idx: int = clampi(players_option.selected, 0, max(0, current_map_comps.size() - 1))
	var c_info: Dictionary = current_map_comps[comp_idx] if current_map_comps.size() > 0 else {"players": entry["default_players"], "comp": "2_TEAMS"}
	var p_cnt: int = int(c_info.get("players", entry["default_players"]))
	if p_cnt <= 0: p_cnt = int(entry["default_players"])
	var c_str: String = String(c_info.get("comp", "2_TEAMS"))

	var slots: Array[String] = GameState.get_teams_for_slots(p_cnt, c_str)
	var team_counts := {}
	for t: String in slots:
		team_counts[t] = int(team_counts.get(t, 0)) + 1

	var preview_parts: Array[String] = []
	for t: String in team_counts.keys():
		var count: int = int(team_counts[t])
		var col_name: String = GameState.get_team_color_name(t)
		var pen: int = GameState.get_team_energy_penalty_pct(t)
		var pen_txt: String = (" [-" + str(pen) + "% Asym Energy]") if pen > 0 else " [100% Energy]"
		preview_parts.append(t + " (" + col_name + "): " + str(count) + "P" + pen_txt)

	roster_preview_lbl.text = "Team Setup (" + str(p_cnt) + "P Total):\n" + "  •  ".join(preview_parts)

func _update_players_dropdown(map_index: int):
	players_option.clear()
	current_map_comps.clear()
	var catalog_size: int = MapLayoutBuilderScript.MAP_CATALOG.size()
	if map_index >= 0 and map_index < catalog_size:
		var entry: Dictionary = MapLayoutBuilderScript.MAP_CATALOG[map_index]
		var comps: Array = entry["comps"]
		for c in comps:
			players_option.add_item(c["label"])
			current_map_comps.append(c)
		var def_p: int = int(entry["default_players"])
		if def_p >= 12:
			timer_option.select(5) # 25 min for massive 12P-25P maps
		elif def_p >= 6:
			timer_option.select(4) # 20 min for 6P-10P maps
		else:
			timer_option.select(2) # 10 min for 2P-5P maps
	else:
		# Random Map & Size
		var rand_opts := [
			{"label": "Auto-Match Map Default Teams", "players": 0, "comp": "AUTO"},
			{"label": "Force Free For All (Every Player for Themselves)", "players": 0, "comp": "FFA"},
			{"label": "Force 2 Grand Teams", "players": 0, "comp": "2_TEAMS"}
		]
		for rc in rand_opts:
			players_option.add_item(rc["label"])
			current_map_comps.append(rc)
		timer_option.select(3)
	_update_roster_preview()

func _on_map_item_selected(index):
	_update_players_dropdown(index)

func _on_players_item_selected(_index):
	_update_roster_preview()

func _on_start_pressed():
	var catalog_size: int = MapLayoutBuilderScript.MAP_CATALOG.size()
	var sel_map_idx: int = map_option.selected
	var chosen_entry: Dictionary = {}
	if sel_map_idx >= 0 and sel_map_idx < catalog_size:
		chosen_entry = MapLayoutBuilderScript.MAP_CATALOG[sel_map_idx]
	else:
		chosen_entry = MapLayoutBuilderScript.MAP_CATALOG[randi() % catalog_size]

	GameState.map_layout_id = String(chosen_entry["id"])

	var comp_idx: int = clampi(players_option.selected, 0, max(0, current_map_comps.size() - 1))
	var chosen_comp_info: Dictionary = current_map_comps[comp_idx] if current_map_comps.size() > 0 else {"players": chosen_entry["default_players"], "comp": "2_TEAMS"}
	var p_count: int = int(chosen_comp_info.get("players", 0))
	var c_mode: String = String(chosen_comp_info.get("comp", "2_TEAMS"))
	if p_count <= 0:
		var def_comps: Array = chosen_entry["comps"]
		var first_c: Dictionary = def_comps[0]
		p_count = int(first_c["players"])
		if c_mode == "AUTO":
			c_mode = String(first_c["comp"])

	GameState.match_player_count = clampi(p_count, 2, 25)
	GameState.team_comp = c_mode

	if GameState.match_player_count >= 6:
		GameState.map_selected = "Arena_6P.tscn"
	elif GameState.match_player_count >= 4:
		GameState.map_selected = "Arena_4P.tscn"
	else:
		GameState.map_selected = "Arena.tscn"
		
	if biome_option.selected == 0:
		GameState.map_biome = "SUNNY_PLAINS"
	elif biome_option.selected == 1:
		GameState.map_biome = "SCORCHING_DUNES"
	elif biome_option.selected == 2:
		GameState.map_biome = "REALM_OF_HARMONY"
	elif biome_option.selected == 3:
		GameState.map_biome = "FROZEN_TUNDRA"
	elif biome_option.selected == 4:
		GameState.map_biome = "VOLCANIC_BRIMSTONE"
	elif biome_option.selected == 5:
		GameState.map_biome = "SPACE_VACUUM"
	elif biome_option.selected == 6:
		GameState.map_biome = "DEEP_JUNGLE"
	else:
		GameState.map_biome = "RANDOM"
		
	if mode_option.selected == 0:
		GameState.game_mode = "DOMINATION"
	elif mode_option.selected == 1:
		GameState.game_mode = "KOTH"
	elif mode_option.selected == 2:
		GameState.game_mode = "FFA_DOMINATION"
		GameState.team_comp = "FFA"
	else:
		GameState.game_mode = "FFA_KOTH"
		GameState.team_comp = "FFA"
		
	if role_option.selected == 0:
		if GameState.current_mode != "ONLINE_HOST":
			GameState.current_mode = "LOCAL"
	else:
		GameState.current_mode = "AI_VS_AI"
	
	var diff = diff_option.selected
	if diff == 0: GameState.ai_difficulty = "EASY"
	elif diff == 2: GameState.ai_difficulty = "HARD"
	else: GameState.ai_difficulty = "MEDIUM"
	
	if ai_faction_option:
		var sel_f = ai_faction_option.selected
		if sel_f == 0: GameState.ai_faction_override = "RANDOM"
		elif sel_f == 1: GameState.ai_faction_override = "Dominion"
		elif sel_f == 2: GameState.ai_faction_override = "The Reach"
		elif sel_f == 3: GameState.ai_faction_override = "Pirates"
		elif sel_f == 4: GameState.ai_faction_override = "Rimworlders"
		elif sel_f == 5: GameState.ai_faction_override = "Void"
		elif sel_f == 6: GameState.ai_faction_override = "Plague of Harmony"
		elif sel_f == 7: GameState.ai_faction_override = "Gilded Harmony"
		elif sel_f == 8: GameState.ai_faction_override = "Planetary Primitives"
		elif sel_f == 9: GameState.ai_faction_override = "Galactic Wildlife"
		elif sel_f == 10: GameState.ai_faction_override = "Chaos"
	else:
		GameState.ai_faction_override = "RANDOM"
	
	var time_map = {0: 150.0, 1: 300.0, 2: 600.0, 3: 900.0, 4: 1200.0, 5: 1500.0, 6: 1800.0, 7: 2100.0, 8: 2400.0, 9: 2700.0, 10: 3000.0, 11: 3300.0, 12: 3600.0}
	GameState.sudden_death_timer = time_map.get(timer_option.selected, 600.0)
	
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/" + GameState.map_selected)

func _on_back_pressed():
	if GameState.current_mode == "ONLINE_HOST":
		GameState.disconnect_multiplayer()
		get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


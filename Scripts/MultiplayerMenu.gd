extends Control

@onready var old_vbox = get_node_or_null("VBoxContainer")
var status_label: Label = null
var host_btn: Button = null
var join_btn: Button = null
var ip_input: LineEdit = null
var port_input: LineEdit = null
var code_input: LineEdit = null
var join_code_input: LineEdit = null
var join_port_input: LineEdit = null
var max_players_option: OptionButton = null
var privacy_option: OptionButton = null
var roster_vbox: VBoxContainer = null

func _ready():
	# Clean up any lingering connections from previous sessions
	GameState.disconnect_multiplayer()
	
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	if old_vbox:
		old_vbox.visible = false

	_build_advanced_multiplayer_ui()

func _exit_tree():
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	if multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.disconnect(_on_connection_failed)
	if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)

func _build_advanced_multiplayer_ui():
	var root_margin = MarginContainer.new()
	root_margin.name = "AdvancedMultiplayerUI"
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 36)
	root_margin.add_theme_constant_override("margin_right", 36)
	root_margin.add_theme_constant_override("margin_top", 24)
	root_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(root_margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	root_margin.add_child(main_vbox)

	# --- Header Bar ---
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(header_hbox)

	var title_lbl = Label.new()
	title_lbl.text = "WAR GAMES & MULTIPLAYER HUB (2 - 25 PLAYERS)"
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	header_hbox.add_child(title_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	var back_btn = Button.new()
	back_btn.text = "Back to Mode Hub"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.connect("pressed", Callable(self, "_on_back_pressed"))
	header_hbox.add_child(back_btn)

	# --- Status Banner ---
	status_label = Label.new()
	status_label.text = "Ready. Configure an Online room, join a Private match, or play Local / Split-Screen."
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	main_vbox.add_child(status_label)

	# --- Tab Container ---
	var tabs = TabContainer.new()
	tabs.name = "TabContainer"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 15)
	main_vbox.add_child(tabs)

	# =========================================================================
	# TAB 1: Online & Private Rooms (Up to 25 Players)
	# =========================================================================
	var tab_online = MarginContainer.new()
	tab_online.name = "Online & Private Rooms (2-25P)"
	tab_online.add_theme_constant_override("margin_left", 18)
	tab_online.add_theme_constant_override("margin_right", 18)
	tab_online.add_theme_constant_override("margin_top", 14)
	tab_online.add_theme_constant_override("margin_bottom", 14)
	tabs.add_child(tab_online)

	var online_hbox = HBoxContainer.new()
	online_hbox.add_theme_constant_override("separation", 24)
	tab_online.add_child(online_hbox)

	# Left Column: Host & Join Panels
	var net_controls_vbox = VBoxContainer.new()
	net_controls_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	net_controls_vbox.add_theme_constant_override("separation", 16)
	online_hbox.add_child(net_controls_vbox)

	# 1. Host Section
	var host_panel = PanelContainer.new()
	net_controls_vbox.add_child(host_panel)
	var host_box = VBoxContainer.new()
	host_box.add_theme_constant_override("separation", 8)
	host_panel.add_child(host_box)

	var h_title = Label.new()
	h_title.text = "HOST ONLINE ROOM (PUBLIC OR PRIVATE)"
	h_title.add_theme_font_size_override("font_size", 16)
	h_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	host_box.add_child(h_title)

	var h_row1 = HBoxContainer.new()
	h_row1.add_theme_constant_override("separation", 12)
	host_box.add_child(h_row1)

	var p_lbl = Label.new(); p_lbl.text = "Max Players:"; h_row1.add_child(p_lbl)
	max_players_option = OptionButton.new()
	for p_c in [2, 3, 4, 5, 6, 8, 9, 10, 12, 16, 20, 25]:
		max_players_option.add_item(str(p_c) + " Players", p_c)
	max_players_option.select(11) # Default 25 Players
	max_players_option.connect("item_selected", Callable(self, "_on_max_players_selected"))
	h_row1.add_child(max_players_option)

	var priv_lbl = Label.new(); priv_lbl.text = "Privacy:"; h_row1.add_child(priv_lbl)
	privacy_option = OptionButton.new()
	privacy_option.add_item("Public Match (Any Peer)", 0)
	privacy_option.add_item("Private Room (Requires Code)", 1)
	h_row1.add_child(privacy_option)

	var h_row2 = HBoxContainer.new()
	h_row2.add_theme_constant_override("separation", 12)
	host_box.add_child(h_row2)

	var code_lbl = Label.new(); code_lbl.text = "Room Code:"; h_row2.add_child(code_lbl)
	code_input = LineEdit.new()
	code_input.text = GameState.room_code
	code_input.custom_minimum_size = Vector2(100, 0)
	h_row2.add_child(code_input)

	var gen_code_btn = Button.new()
	gen_code_btn.text = "Roll Code"
	gen_code_btn.connect("pressed", Callable(self, "_on_roll_code_pressed"))
	h_row2.add_child(gen_code_btn)

	var port_lbl = Label.new(); port_lbl.text = "Port:"; h_row2.add_child(port_lbl)
	port_input = LineEdit.new()
	port_input.text = "8910"
	port_input.custom_minimum_size = Vector2(70, 0)
	h_row2.add_child(port_input)

	host_btn = Button.new()
	host_btn.text = "Host Room & Configure Match (Up to 25 Players)"
	host_btn.add_theme_font_size_override("font_size", 16)
	host_btn.connect("pressed", Callable(self, "_on_host_pressed"))
	host_box.add_child(host_btn)

	# 2. Join Section
	var join_panel = PanelContainer.new()
	net_controls_vbox.add_child(join_panel)
	var join_box = VBoxContainer.new()
	join_box.add_theme_constant_override("separation", 8)
	join_panel.add_child(join_box)

	var j_title = Label.new()
	j_title.text = "JOIN ONLINE OR PRIVATE ROOM"
	j_title.add_theme_font_size_override("font_size", 16)
	j_title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	join_box.add_child(j_title)

	var j_row = HBoxContainer.new()
	j_row.add_theme_constant_override("separation", 10)
	join_box.add_child(j_row)

	var ip_lbl = Label.new(); ip_lbl.text = "Host IP:"; j_row.add_child(ip_lbl)
	ip_input = LineEdit.new()
	ip_input.text = "127.0.0.1"
	ip_input.placeholder_text = "Host IP (e.g. 192.168.1.100)"
	ip_input.custom_minimum_size = Vector2(170, 0)
	ip_input.connect("text_submitted", Callable(self, "_on_ip_input_text_submitted"))
	j_row.add_child(ip_input)

	var local_ip_btn = Button.new()
	local_ip_btn.text = "Localhost"
	local_ip_btn.connect("pressed", Callable(self, "_on_set_localhost_pressed"))
	j_row.add_child(local_ip_btn)

	var j_row2 = HBoxContainer.new()
	j_row2.add_theme_constant_override("separation", 10)
	join_box.add_child(j_row2)

	var j_code_lbl = Label.new(); j_code_lbl.text = "Room Code (if private):"; j_row2.add_child(j_code_lbl)
	join_code_input = LineEdit.new()
	join_code_input.placeholder_text = "e.g. UBB25 (or blank for public)"
	join_code_input.text = GameState.room_code
	join_code_input.custom_minimum_size = Vector2(170, 0)
	join_code_input.connect("text_submitted", Callable(self, "_on_ip_input_text_submitted"))
	j_row2.add_child(join_code_input)

	var j_port_lbl = Label.new(); j_port_lbl.text = "Port:"; j_row2.add_child(j_port_lbl)
	join_port_input = LineEdit.new()
	join_port_input.text = "8910"
	join_port_input.custom_minimum_size = Vector2(65, 0)
	j_row2.add_child(join_port_input)

	join_btn = Button.new()
	join_btn.text = "Connect & Join Battle"
	join_btn.add_theme_font_size_override("font_size", 16)
	join_btn.connect("pressed", Callable(self, "_on_join_pressed"))
	join_box.add_child(join_btn)

	# Right Column: 25-Slot Connected Roster Preview
	var roster_panel = PanelContainer.new()
	roster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_panel.custom_minimum_size = Vector2(340, 0)
	online_hbox.add_child(roster_panel)

	var r_box = VBoxContainer.new()
	r_box.add_theme_constant_override("separation", 6)
	roster_panel.add_child(r_box)

	var r_title = Label.new()
	r_title.text = "MATCH STAGING ROSTER (25 SLOTS)"
	r_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r_title.add_theme_font_size_override("font_size", 14)
	r_title.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	r_box.add_child(r_title)

	var r_scroll = ScrollContainer.new()
	r_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r_box.add_child(r_scroll)

	roster_vbox = VBoxContainer.new()
	roster_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_vbox.add_theme_constant_override("separation", 4)
	r_scroll.add_child(roster_vbox)
	_refresh_staging_roster()

	# =========================================================================
	# TAB 2: Local & Split-Screen Play
	# =========================================================================
	var tab_local = MarginContainer.new()
	tab_local.name = "Local & Split-Screen Play"
	tab_local.add_theme_constant_override("margin_left", 24)
	tab_local.add_theme_constant_override("margin_right", 24)
	tab_local.add_theme_constant_override("margin_top", 16)
	tab_local.add_theme_constant_override("margin_bottom", 16)
	tabs.add_child(tab_local)

	var local_vbox = VBoxContainer.new()
	local_vbox.add_theme_constant_override("separation", 12)
	tab_local.add_child(local_vbox)

	var l_desc = Label.new()
	l_desc.text = "Play locally against customizable Bot AI commanders (2 to 25 players on any of 31 maps), spectate sandbox AI battles, or play multi-controller split-screen."
	l_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	local_vbox.add_child(l_desc)

	var sp_btn = Button.new()
	sp_btn.text = "Singleplayer Match (1 Human vs Up to 24 Bot Commanders) -> Configure Match"
	sp_btn.add_theme_font_size_override("font_size", 16)
	sp_btn.connect("pressed", Callable(self, "_on_singleplayer_pressed"))
	local_vbox.add_child(sp_btn)

	var spec_btn = Button.new()
	spec_btn.text = "Spectator Sandbox (AI vs AI — Up to 25 Bots Fighting) -> Configure Match"
	spec_btn.add_theme_font_size_override("font_size", 16)
	spec_btn.connect("pressed", Callable(self, "_on_spectator_pressed"))
	local_vbox.add_child(spec_btn)

	var split_sep = HSeparator.new(); local_vbox.add_child(split_sep)

	var split_lbl = Label.new()
	split_lbl.text = "LOCAL SPLIT-SCREEN (CONTROLLERS & KEYBOARD):"
	split_lbl.add_theme_font_size_override("font_size", 15)
	local_vbox.add_child(split_lbl)

	var split_hbox = HBoxContainer.new()
	split_hbox.add_theme_constant_override("separation", 12)
	local_vbox.add_child(split_hbox)

	var l2p_btn = Button.new(); l2p_btn.text = "2-Player Split-Screen"; l2p_btn.connect("pressed", Callable(self, "_on_local_2p_pressed")); split_hbox.add_child(l2p_btn)
	var l4p_btn = Button.new(); l4p_btn.text = "4-Player Split-Screen"; l4p_btn.connect("pressed", Callable(self, "_on_local_4p_pressed")); split_hbox.add_child(l4p_btn)
	var l6p_btn = Button.new(); l6p_btn.text = "6-Player Split-Screen"; l6p_btn.connect("pressed", Callable(self, "_on_local_6p_pressed")); split_hbox.add_child(l6p_btn)

	# =========================================================================
	# TAB 3: 25-Player Team Color Roster & Guide
	# =========================================================================
	var tab_colors = MarginContainer.new()
	tab_colors.name = "25-Team Color System"
	tab_colors.add_theme_constant_override("margin_left", 24)
	tab_colors.add_theme_constant_override("margin_right", 24)
	tab_colors.add_theme_constant_override("margin_top", 16)
	tab_colors.add_theme_constant_override("margin_bottom", 16)
	tabs.add_child(tab_colors)

	var colors_vbox = VBoxContainer.new()
	colors_vbox.add_theme_constant_override("separation", 8)
	tab_colors.add_child(colors_vbox)

	var c_desc = Label.new()
	c_desc.text = "The 25 distinct handcrafted team colors used across all 31 maps, unit markers, bases, towers, minimap, and healthbars:"
	colors_vbox.add_child(c_desc)

	var c_scroll = ScrollContainer.new()
	c_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colors_vbox.add_child(c_scroll)

	var c_grid = GridContainer.new()
	c_grid.columns = 3
	c_grid.add_theme_constant_override("h_separation", 18)
	c_grid.add_theme_constant_override("v_separation", 8)
	c_scroll.add_child(c_grid)

	for t_idx in range(GameState.ALL_TEAMS.size()):
		var t_id: String = GameState.ALL_TEAMS[t_idx]
		var t_col: Color = GameState.get_team_color(t_id)
		var t_name: String = GameState.get_team_color_name(t_id)

		var card = HBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		c_grid.add_child(card)

		var swatch = ColorRect.new()
		swatch.color = t_col
		swatch.custom_minimum_size = Vector2(22, 22)
		card.add_child(swatch)

		var info_lbl = Label.new()
		info_lbl.text = "#" + str(t_idx + 1) + " " + t_id + ": " + t_name
		info_lbl.add_theme_font_size_override("font_size", 12)
		card.add_child(info_lbl)

func _refresh_staging_roster():
	if not roster_vbox: return
	for child in roster_vbox.get_children():
		child.queue_free()

	var max_p = max_players_option.get_selected_id() if max_players_option else 25
	for s_idx in range(max_p):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		roster_vbox.add_child(row)

		var t_id: String = GameState.ALL_TEAMS[s_idx % GameState.ALL_TEAMS.size()]
		var t_col: Color = GameState.get_team_color(t_id)

		var dot = ColorRect.new()
		dot.color = t_col
		dot.custom_minimum_size = Vector2(14, 14)
		row.add_child(dot)

		var slot_lbl = Label.new()
		if s_idx == 0:
			slot_lbl.text = "Slot 1: Host (Local Player) — " + t_id
			slot_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
		else:
			slot_lbl.text = "Slot " + str(s_idx + 1) + ": Open / AI Commander — " + t_id
			slot_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
		slot_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(slot_lbl)

func _on_max_players_selected(_index: int):
	_refresh_staging_roster()

func _on_roll_code_pressed():
	var chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var new_code = "UBB"
	for _i in range(3):
		new_code += chars[randi() % chars.length()]
	if code_input:
		code_input.text = new_code
	if join_code_input:
		join_code_input.text = new_code
	GameState.room_code = new_code
	if status_label:
		status_label.text = "Generated new private room code: " + new_code

func _on_set_localhost_pressed():
	if ip_input:
		ip_input.text = "127.0.0.1"

func _on_host_pressed():
	var port_val: int = port_input.text.to_int() if port_input else 8910
	if port_val <= 0: port_val = 8910
	var max_p: int = max_players_option.get_selected_id() if max_players_option else 25
	var code_val: String = code_input.text.strip_edges() if code_input else "UBB25"
	var is_priv: bool = privacy_option.selected == 1 if privacy_option else false

	if status_label:
		status_label.text = "Starting host server on port " + str(port_val) + " (Max " + str(max_p) + "P)..."
		status_label.modulate = Color(0.95, 0.85, 0.2)

	GameState.current_mode = "ONLINE_HOST"
	GameState.match_player_count = max_p
	GameState.room_privacy = "PRIVATE" if is_priv else "PUBLIC"
	var err = GameState.host_game(port_val, max_p, code_val if is_priv else "")
	if err == OK:
		GameState.load_decks()
		if status_label:
			status_label.text = "Host server ready! Opening match setup..."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		get_tree().change_scene_to_file("res://Scenes/MatchSetup.tscn")
	else:
		if status_label:
			status_label.text = "Failed to host: Port " + str(port_val) + " in use (Error " + str(err) + ")"
			status_label.modulate = Color(1.0, 0.3, 0.2)

func _on_join_pressed():
	var ip = ip_input.text.strip_edges() if ip_input else ""
	if ip == "": ip = "127.0.0.1"
	var port_val: int = join_port_input.text.to_int() if join_port_input else (port_input.text.to_int() if port_input else 8910)
	if port_val <= 0: port_val = 8910
	var code_val: String = join_code_input.text.strip_edges() if join_code_input else (code_input.text.strip_edges() if code_input else "")

	if status_label:
		status_label.text = "Connecting to " + ip + ":" + str(port_val) + "... Please wait."
		status_label.modulate = Color(0.95, 0.85, 0.2)

	if host_btn: host_btn.disabled = true
	if join_btn: join_btn.disabled = true

	GameState.current_mode = "ONLINE_JOIN"
	var err = GameState.join_game(ip, port_val, code_val)
	if err != OK:
		if status_label:
			status_label.text = "Failed to initialize client socket (Error " + str(err) + ")"
			status_label.modulate = Color(1.0, 0.3, 0.2)
		if host_btn: host_btn.disabled = false
		if join_btn: join_btn.disabled = false

func _on_connected_to_server():
	print("Connected to host server successfully!")
	if status_label:
		status_label.text = "Connected! Loading battle..."
		status_label.modulate = Color(0.2, 1.0, 0.4)
	GameState.load_decks()
	var target_map = GameState.map_selected if GameState.map_selected != "" else "Arena.tscn"
	get_tree().change_scene_to_file("res://Scenes/" + target_map)

func _on_connection_failed():
	print("Connection to host failed.")
	var ip = ip_input.text.strip_edges() if ip_input else "127.0.0.1"
	if ip == "": ip = "127.0.0.1"
	var port_val: int = port_input.text.to_int() if port_input else 8910
	if status_label:
		status_label.text = "Connection failed! Host not reachable at " + ip + ":" + str(port_val)
		status_label.modulate = Color(1.0, 0.3, 0.2)
	if host_btn: host_btn.disabled = false
	if join_btn: join_btn.disabled = false
	GameState.disconnect_multiplayer()

func _on_server_disconnected():
	print("Disconnected from server.")
	if status_label:
		status_label.text = "Server connection lost."
		status_label.modulate = Color(1.0, 0.3, 0.2)
	if host_btn: host_btn.disabled = false
	if join_btn: join_btn.disabled = false
	GameState.disconnect_multiplayer()

func _on_singleplayer_pressed():
	GameState.current_mode = "LOCAL"
	get_tree().change_scene_to_file("res://Scenes/MatchSetup.tscn")

func _on_spectator_pressed():
	GameState.current_mode = "AI_VS_AI"
	get_tree().change_scene_to_file("res://Scenes/MatchSetup.tscn")

func _on_local_2p_pressed():
	GameState.current_mode = "LOCAL_SPLIT_2P"
	GameState.match_player_count = 2
	GameState.map_layout_id = "CLASSIC_1V1"
	GameState.team_comp = "2_TEAMS"
	GameState.map_selected = "Arena.tscn"
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/Arena.tscn")

func _on_local_4p_pressed():
	GameState.current_mode = "LOCAL_SPLIT_4P"
	GameState.match_player_count = 4
	GameState.map_layout_id = "QUAD_4LANE_2V2"
	GameState.team_comp = "2_TEAMS"
	GameState.map_selected = "Arena_4P.tscn"
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/Arena_4P.tscn")

func _on_local_6p_pressed():
	GameState.current_mode = "LOCAL_SPLIT_4P" # Uses split-screen multi-viewport container
	GameState.match_player_count = 6
	GameState.map_layout_id = "HEX_STAR_6P"
	GameState.team_comp = "2_TEAMS"
	GameState.map_selected = "Arena_6P.tscn"
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/Arena_6P.tscn")


func _on_back_pressed():
	GameState.disconnect_multiplayer()
	get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _on_ip_input_text_submitted(_new_text: String):
	_on_join_pressed()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

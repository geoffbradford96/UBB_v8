extends Control

@onready var req_bar = $BottomPanel/RequisitionBar
@onready var req_label = $BottomPanel/RequisitionBar/Label
@onready var hand_container = $BottomPanel/HandContainer

var deck: Array = []
var discard: Array = []

var input_mode: String = "MOUSE"
var crosshair: ColorRect
var selected_card_idx: int = -1

var device_id: int = -1
var player_id: int = 1 # -1 means Keyboard/Mouse + Controller 0.
var player_profile: String = "Player1"

signal ui_card_selected(card_ui, ui_instance)

# 25-Player Match Scoreboard Overlay
var scoreboard_overlay: Control = null
var scoreboard_rows_container: VBoxContainer = null
var scoreboard_info_label: Label = null
var roster_button: Button = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var exit_btn = get_node_or_null("ExitButton")
	if exit_btn:
		exit_btn.text = "Exit Match"
		exit_btn.connect("pressed", Callable(self, "_on_exit_button_pressed"))
	
	# Top Roster / Scoreboard Button
	roster_button = Button.new()
	roster_button.name = "RosterButton"
	roster_button.text = "Roster (Tab)" if GameState.current_mode != "AI_VS_AI" else "Roster (F1)"
	roster_button.offset_left = 20.0
	roster_button.offset_top = 70.0
	roster_button.offset_right = 120.0
	roster_button.offset_bottom = 105.0
	roster_button.add_theme_font_size_override("font_size", 12)
	roster_button.connect("pressed", Callable(self, "toggle_match_scoreboard"))
	add_child(roster_button)
	
	_build_scoreboard_overlay()
	
	if GameState.current_mode == "AI_VS_AI":
		var bp = get_node_or_null("BottomPanel")
		if bp: bp.visible = false
		_build_spectator_hud()
		_build_pause_menu()
		return
	
	if GameState.player_decks.has(player_profile) and GameState.player_decks[player_profile].size() > 0:
		deck = GameState.player_decks[player_profile].duplicate()
	else:
		deck = ["CommanderCard", "CheapGruntCard", "SupportingFireCard", "MedicCard", "CallArtilleryCard", "SniperCard"]
		
	deck.shuffle()
	for card_ui in hand_container.get_children():
		card_ui.connect("card_clicked", Callable(self, "_on_card_clicked"))
		draw_card(card_ui)
		
	# Create top panel for Enemy / Opponent Requisition display
	_build_enemy_req_ui()
	_build_pause_menu()
		
	crosshair = ColorRect.new()
	crosshair.color = Color(1, 1, 1, 0.8)
	crosshair.custom_minimum_size = Vector2(8, 8)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.visible = false
	add_child(crosshair)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if scoreboard_overlay and scoreboard_overlay.visible:
			scoreboard_overlay.visible = false
			get_viewport().set_input_as_handled()
			return
		if pause_overlay and not pause_overlay.visible and GameState.current_mode != "AI_VS_AI" and hand_container:
			if selected_card_idx >= 0 and selected_card_idx < hand_container.get_child_count():
				var cur_card = hand_container.get_child(selected_card_idx)
				if cur_card and "is_selected" in cur_card and cur_card.is_selected:
					selected_card_idx = -1
					emit_signal("ui_card_selected", cur_card, self)
					get_viewport().set_input_as_handled()
					return
		toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			toggle_match_scoreboard()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_TAB:
			if GameState.current_mode != "AI_VS_AI" or event.shift_pressed:
				toggle_match_scoreboard()
				get_viewport().set_input_as_handled()
				return
		elif GameState.current_mode != "AI_VS_AI" and player_id == 1 and hand_container:
			var hotkey_idx: int = -1
			if event.keycode == KEY_1: hotkey_idx = 0
			elif event.keycode == KEY_2: hotkey_idx = 1
			elif event.keycode == KEY_3: hotkey_idx = 2
			elif event.keycode == KEY_4: hotkey_idx = 3
			if hotkey_idx >= 0 and hotkey_idx < hand_container.get_child_count():
				var hk_card = hand_container.get_child(hotkey_idx)
				selected_card_idx = hotkey_idx
				emit_signal("ui_card_selected", hk_card, self)
				get_viewport().set_input_as_handled()
				return
		
	if GameState.current_mode == "AI_VS_AI":
		if event is InputEventKey and event.keycode == KEY_V and event.pressed and not event.echo:
			call_deferred("_update_vision_btn_text")
		return
		
	if device_id != -1 and event.device != device_id:
		return
		
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		if input_mode != "MOUSE":
			input_mode = "MOUSE"
			crosshair.visible = false
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		if input_mode != "CONTROLLER":
			input_mode = "CONTROLLER"
			crosshair.visible = true
			if selected_card_idx == -1:
				selected_card_idx = 0
				_update_controller_selection()
				
	if input_mode == "CONTROLLER":
		var prefix = "p" + str(player_id) + "_"
		if event.is_action_pressed(prefix + "prev_card"):
			selected_card_idx -= 1
			if selected_card_idx < 0: selected_card_idx = hand_container.get_child_count() - 1
			_update_controller_selection()
		elif event.is_action_pressed(prefix + "next_card"):
			selected_card_idx += 1
			if selected_card_idx >= hand_container.get_child_count(): selected_card_idx = 0
			_update_controller_selection()


func _update_controller_selection():
	if selected_card_idx >= 0 and selected_card_idx < hand_container.get_child_count():
		var child = hand_container.get_child(selected_card_idx)
		emit_signal("ui_card_selected", child, self)

func draw_card(card_ui):
	if deck.is_empty() and discard.is_empty():
		return
	if deck.is_empty():
		deck = discard.duplicate()
		discard.clear()
		deck.shuffle()
		
	var card_name = deck.pop_front()
	var data = load("res://Data/Cards/" + card_name + ".tres")
	if data:
		card_ui.set_card_data(data)

func _on_card_clicked(card_ui):
	selected_card_idx = card_ui.get_index()
	emit_signal("ui_card_selected", card_ui, self)

func _on_exit_button_pressed():
	toggle_pause_menu()

var pause_overlay: Control = null
var pause_settings_container: VBoxContainer = null

func _build_pause_menu():
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.05, 0.08, 0.8)
	pause_overlay.add_child(dim)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 320)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	var title = Label.new()
	var is_online = multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	title.text = "MATCH OPTIONS" if is_online else "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var resume_btn = Button.new()
	resume_btn.text = "Resume Match"
	resume_btn.custom_minimum_size = Vector2(0, 42)
	resume_btn.add_theme_font_size_override("font_size", 18)
	resume_btn.connect("pressed", Callable(self, "toggle_pause_menu"))
	vbox.add_child(resume_btn)
	
	var settings_toggle_btn = Button.new()
	settings_toggle_btn.text = "Audio & Video Settings"
	settings_toggle_btn.custom_minimum_size = Vector2(0, 42)
	settings_toggle_btn.add_theme_font_size_override("font_size", 18)
	settings_toggle_btn.connect("pressed", Callable(self, "_toggle_pause_settings"))
	vbox.add_child(settings_toggle_btn)
	
	pause_settings_container = VBoxContainer.new()
	pause_settings_container.visible = false
	vbox.add_child(pause_settings_container)
	
	var vol_lbl = Label.new()
	vol_lbl.text = "Master Volume"
	pause_settings_container.add_child(vol_lbl)
	
	var vol_slider = HSlider.new()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	var cur_db = AudioServer.get_bus_volume_db(0)
	vol_slider.value = db_to_linear(cur_db)
	vol_slider.connect("value_changed", Callable(self, "_on_pause_vol_changed"))
	pause_settings_container.add_child(vol_slider)
	
	var fs_check = CheckBox.new()
	fs_check.text = "Fullscreen Mode"
	fs_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fs_check.connect("toggled", Callable(self, "_on_pause_fs_toggled"))
	pause_settings_container.add_child(fs_check)
	
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	var surrender_btn = Button.new()
	surrender_btn.text = "Surrender & Return to Hub"
	surrender_btn.custom_minimum_size = Vector2(0, 42)
	surrender_btn.add_theme_font_size_override("font_size", 18)
	surrender_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
	surrender_btn.connect("pressed", Callable(self, "_on_confirm_surrender"))
	vbox.add_child(surrender_btn)
	
	add_child(pause_overlay)

func toggle_pause_menu():
	if not pause_overlay: return
	var is_open = not pause_overlay.visible
	pause_overlay.visible = is_open
	
	var is_online = multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	if not is_online:
		get_tree().paused = is_open

func _toggle_pause_settings():
	if pause_settings_container:
		pause_settings_container.visible = not pause_settings_container.visible

func _on_pause_vol_changed(val: float):
	var db = linear_to_db(val)
	AudioServer.set_bus_volume_db(0, db)
	AudioServer.set_bus_mute(0, val <= 0.01)

func _on_pause_fs_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_confirm_surrender():
	if pause_overlay: pause_overlay.visible = false
	get_tree().paused = false
	GameState.disconnect_multiplayer()
	if GameState.current_mode == "ONLINE_HOST" or GameState.current_mode == "ONLINE_JOIN":
		get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")


var enemy_req_bar: ProgressBar = null
var enemy_req_label: Label = null

func _build_enemy_req_ui():
	var top_panel = PanelContainer.new()
	top_panel.name = "EnemyReqPanel"
	top_panel.offset_left = 130.0
	top_panel.offset_top = 18.0
	top_panel.offset_right = 370.0
	top_panel.offset_bottom = 62.0
	
	var vbox = VBoxContainer.new()
	top_panel.add_child(vbox)
	
	enemy_req_label = Label.new()
	enemy_req_label.text = "Enemy Energy: 0 / 100"
	enemy_req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_req_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(enemy_req_label)
	
	enemy_req_bar = ProgressBar.new()
	enemy_req_bar.custom_minimum_size = Vector2(230, 14)
	enemy_req_bar.show_percentage = false
	enemy_req_bar.max_value = 100.0
	enemy_req_bar.value = 0.0
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.1, 0.1, 0.85)
	style_bg.corner_radius_top_left = 4; style_bg.corner_radius_top_right = 4
	style_bg.corner_radius_bottom_left = 4; style_bg.corner_radius_bottom_right = 4
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.85, 0.25, 0.2)
	style_fill.corner_radius_top_left = 4; style_fill.corner_radius_top_right = 4
	style_fill.corner_radius_bottom_left = 4; style_fill.corner_radius_bottom_right = 4
	
	enemy_req_bar.add_theme_stylebox_override("background", style_bg)
	enemy_req_bar.add_theme_stylebox_override("fill", style_fill)
	vbox.add_child(enemy_req_bar)
	
	add_child(top_panel)

func update_requisition(current: float, max_req: float):
	req_bar.max_value = max_req
	req_bar.value = current
	var my_team: String = GameState.local_player_team if GameState.local_player_team != "Spectator" else "SideA"
	var pen_pct: int = GameState.get_team_energy_penalty_pct(my_team)
	var pen_tag: String = (" (-" + str(pen_pct) + "% Asym Penalty)") if pen_pct > 0 else ""
	var prefix: String = ("SideA Energy" + pen_tag) if GameState.current_mode == "AI_VS_AI" else ("Requisition" + pen_tag)
	req_label.text = prefix + ": " + str(floor(current)) + " / " + str(max_req)

func update_enemy_requisition(current: float, max_req: float, label_prefix: String = "Enemy"):
	if enemy_req_bar and enemy_req_label:
		enemy_req_bar.max_value = max_req
		enemy_req_bar.value = current
		var e_team: String = "SideB"
		for t_cand: String in GameState.ALL_TEAMS:
			if t_cand in label_prefix:
				e_team = t_cand
				break
		var pen_pct: int = GameState.get_team_energy_penalty_pct(e_team)
		var pen_tag: String = (" [-" + str(pen_pct) + "% Asym]") if pen_pct > 0 else ""
		enemy_req_label.text = label_prefix + pen_tag + " Energy: " + str(floor(current)) + " / " + str(max_req)

var warning_label: Label = null
var warning_tween: Tween = null

func show_placement_warning(msg: String):
	if not warning_label:
		warning_label = Label.new()
		warning_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		warning_label.offset_top = -290
		warning_label.offset_bottom = -260
		warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		warning_label.add_theme_font_size_override("font_size", 16)
		warning_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		warning_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		warning_label.add_theme_constant_override("outline_size", 4)
		warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(warning_label)
		
	warning_label.text = msg
	warning_label.modulate.a = 1.0
	warning_label.visible = true
	
	if warning_tween and warning_tween.is_valid():
		warning_tween.kill()
	warning_tween = create_tween()
	if warning_tween:
		warning_tween.tween_interval(1.2)
		warning_tween.tween_property(warning_label, "modulate:a", 0.0, 0.4)
		warning_tween.tween_callback(Callable(warning_label, "hide"))

var spectator_panel: Control = null
var spectator_a_bar: ProgressBar = null
var spectator_b_bar: ProgressBar = null
var spectator_a_label: Label = null
var spectator_b_label: Label = null
var spectator_vision_btn: Button = null

func _build_spectator_hud():
	spectator_panel = Control.new()
	spectator_panel.name = "SpectatorHUD"
	spectator_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	spectator_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spectator_panel)
	
	# 1. Top Panel: Dual Team Energy Bars (Side A Blue vs Side B Red)
	var top_panel = PanelContainer.new()
	top_panel.name = "SpectatorTopPanel"
	top_panel.offset_left = 130.0
	top_panel.offset_top = 14.0
	top_panel.offset_right = 620.0
	top_panel.offset_bottom = 68.0
	top_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	spectator_panel.add_child(top_panel)
	
	var top_vbox = VBoxContainer.new()
	top_vbox.add_theme_constant_override("separation", 4)
	top_panel.add_child(top_vbox)
	
	var mode_title = Label.new()
	mode_title.text = "SPECTATOR MODE - OBSERVING MATCH"
	mode_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_title.add_theme_font_size_override("font_size", 12)
	mode_title.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	top_vbox.add_child(mode_title)
	
	var dual_hbox = HBoxContainer.new()
	dual_hbox.add_theme_constant_override("separation", 16)
	top_vbox.add_child(dual_hbox)
	
	# Side A Box
	var a_vbox = VBoxContainer.new()
	a_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dual_hbox.add_child(a_vbox)
	
	spectator_a_label = Label.new()
	spectator_a_label.text = "Side A Energy: 0 / 100"
	spectator_a_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spectator_a_label.add_theme_font_size_override("font_size", 11)
	spectator_a_label.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0))
	a_vbox.add_child(spectator_a_label)
	
	spectator_a_bar = ProgressBar.new()
	spectator_a_bar.custom_minimum_size = Vector2(0, 14)
	spectator_a_bar.show_percentage = false
	spectator_a_bar.max_value = 100.0
	spectator_a_bar.value = 0.0
	var a_bg = StyleBoxFlat.new()
	a_bg.bg_color = Color(0.08, 0.12, 0.18, 0.9)
	a_bg.corner_radius_top_left = 3; a_bg.corner_radius_top_right = 3
	a_bg.corner_radius_bottom_left = 3; a_bg.corner_radius_bottom_right = 3
	var a_fg = StyleBoxFlat.new()
	a_fg.bg_color = Color(0.2, 0.65, 1.0)
	a_fg.corner_radius_top_left = 3; a_fg.corner_radius_top_right = 3
	a_fg.corner_radius_bottom_left = 3; a_fg.corner_radius_bottom_right = 3
	spectator_a_bar.add_theme_stylebox_override("background", a_bg)
	spectator_a_bar.add_theme_stylebox_override("fill", a_fg)
	a_vbox.add_child(spectator_a_bar)
	
	# Side B Box
	var b_vbox = VBoxContainer.new()
	b_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dual_hbox.add_child(b_vbox)
	
	spectator_b_label = Label.new()
	spectator_b_label.text = "Side B Energy: 0 / 100"
	spectator_b_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spectator_b_label.add_theme_font_size_override("font_size", 11)
	spectator_b_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	b_vbox.add_child(spectator_b_label)
	
	spectator_b_bar = ProgressBar.new()
	spectator_b_bar.custom_minimum_size = Vector2(0, 14)
	spectator_b_bar.show_percentage = false
	spectator_b_bar.max_value = 100.0
	spectator_b_bar.value = 0.0
	var b_bg = StyleBoxFlat.new()
	b_bg.bg_color = Color(0.18, 0.08, 0.08, 0.9)
	b_bg.corner_radius_top_left = 3; b_bg.corner_radius_top_right = 3
	b_bg.corner_radius_bottom_left = 3; b_bg.corner_radius_bottom_right = 3
	var b_fg = StyleBoxFlat.new()
	b_fg.bg_color = Color(0.95, 0.25, 0.25)
	b_fg.corner_radius_top_left = 3; b_fg.corner_radius_top_right = 3
	b_fg.corner_radius_bottom_left = 3; b_fg.corner_radius_bottom_right = 3
	spectator_b_bar.add_theme_stylebox_override("background", b_bg)
	spectator_b_bar.add_theme_stylebox_override("fill", b_fg)
	b_vbox.add_child(spectator_b_bar)
	
	# 2. Bottom Toolbar: Perspective Toggles & Player Vision
	var bottom_container = CenterContainer.new()
	bottom_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_container.offset_top = -90.0
	bottom_container.offset_bottom = -16.0
	bottom_container.mouse_filter = Control.MOUSE_FILTER_PASS
	spectator_panel.add_child(bottom_container)
	
	var bot_vbox = VBoxContainer.new()
	bot_vbox.add_theme_constant_override("separation", 6)
	bottom_container.add_child(bot_vbox)
	
	var hints = Label.new()
	hints.text = "[WASD / Arrows]: Pan Camera  |  [Wheel]: Zoom  |  [1-3 / Q / Tab / F1 / V]: Shortcuts"
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hints.add_theme_font_size_override("font_size", 12)
	hints.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 0.85))
	bot_vbox.add_child(hints)
	
	var btns_hbox = HBoxContainer.new()
	btns_hbox.add_theme_constant_override("separation", 10)
	bot_vbox.add_child(btns_hbox)
	
	var btn_side_a = Button.new()
	btn_side_a.text = "Side A View (1)"
	btn_side_a.add_theme_font_size_override("font_size", 13)
	btn_side_a.connect("pressed", Callable(self, "_on_spec_snap_a"))
	btns_hbox.add_child(btn_side_a)
	
	var btn_side_b = Button.new()
	btn_side_b.text = "Side B View (2)"
	btn_side_b.add_theme_font_size_override("font_size", 13)
	btn_side_b.connect("pressed", Callable(self, "_on_spec_snap_b"))
	btns_hbox.add_child(btn_side_b)
	
	var btn_overview = Button.new()
	btn_overview.text = "Overview (3)"
	btn_overview.add_theme_font_size_override("font_size", 13)
	btn_overview.connect("pressed", Callable(self, "_on_spec_snap_overview"))
	btns_hbox.add_child(btn_overview)

	var btn_cycle_team = Button.new()
	btn_cycle_team.name = "CycleTeamBtn"
	btn_cycle_team.text = "Cycle Team View (Q)"
	btn_cycle_team.add_theme_font_size_override("font_size", 13)
	btn_cycle_team.connect("pressed", Callable(self, "_on_spec_cycle_team"))
	btns_hbox.add_child(btn_cycle_team)
	
	var btn_cycle = Button.new()
	btn_cycle.text = "Cycle Unit (Tab)"
	btn_cycle.add_theme_font_size_override("font_size", 13)
	btn_cycle.connect("pressed", Callable(self, "_on_spec_cycle_unit"))
	btns_hbox.add_child(btn_cycle)
	
	var btn_roster = Button.new()
	btn_roster.name = "SpecRosterBtn"
	btn_roster.text = "25P Roster (F1)"
	btn_roster.add_theme_font_size_override("font_size", 13)
	btn_roster.connect("pressed", Callable(self, "toggle_match_scoreboard"))
	btns_hbox.add_child(btn_roster)
	
	spectator_vision_btn = Button.new()
	_update_vision_btn_text()
	spectator_vision_btn.add_theme_font_size_override("font_size", 13)
	spectator_vision_btn.connect("pressed", Callable(self, "_on_spec_toggle_vision"))
	btns_hbox.add_child(spectator_vision_btn)

func _update_vision_btn_text():
	if spectator_vision_btn:
		var v_state = "ON (V)" if GameState.player_vision_enabled else "OFF (V)"
		spectator_vision_btn.text = "Player Vision: " + v_state

func _get_active_cam():
	var cam = get_viewport().get_camera_3d()
	if not cam and get_tree() and get_tree().current_scene:
		cam = get_tree().current_scene.find_child("Camera3D", true, false)
	return cam

func _on_spec_snap_a():
	var cam = _get_active_cam()
	if cam and cam.has_method("snap_to_side_a"):
		cam.snap_to_side_a()

func _on_spec_snap_b():
	var cam = _get_active_cam()
	if cam and cam.has_method("snap_to_side_b"):
		cam.snap_to_side_b()

func _on_spec_snap_overview():
	var cam = _get_active_cam()
	if cam and cam.has_method("snap_to_overview"):
		cam.snap_to_overview()

func _on_spec_cycle_team():
	var cam = _get_active_cam()
	if cam and cam.has_method("cycle_team_perspective"):
		cam.cycle_team_perspective()

func _on_spec_cycle_unit():
	var cam = _get_active_cam()
	if cam and cam.has_method("cycle_follow_target"):
		cam.cycle_follow_target()

func _on_spec_toggle_vision():
	var cam = _get_active_cam()
	if cam and cam.has_method("toggle_player_vision"):
		cam.toggle_player_vision()
	else:
		GameState.player_vision_enabled = not GameState.player_vision_enabled
		if get_tree():
			for u in get_tree().get_nodes_in_group("Targetable"):
				var hc = u.get_node_or_null("HealthComponent")
				if hc and hc.has_method("update_ground_marker_color"):
					hc.update_ground_marker_color()
	_update_vision_btn_text()

func update_spectator_energy(a_cur: float, b_cur: float, max_e: float):
	if spectator_a_bar and spectator_a_label:
		spectator_a_bar.max_value = max_e
		spectator_a_bar.value = a_cur
		var a_pen: int = GameState.get_team_energy_penalty_pct("SideA")
		var a_tag: String = (" [-" + str(a_pen) + "%]") if a_pen > 0 else ""
		spectator_a_label.text = "Side A" + a_tag + " Energy: " + str(floor(a_cur)) + " / " + str(floor(max_e))
	if spectator_b_bar and spectator_b_label:
		spectator_b_bar.max_value = max_e
		spectator_b_bar.value = b_cur
		var b_pen: int = GameState.get_team_energy_penalty_pct("SideB")
		var b_tag: String = (" [-" + str(b_pen) + "%]") if b_pen > 0 else ""
		spectator_b_label.text = "Side B" + b_tag + " Energy: " + str(floor(b_cur)) + " / " + str(floor(max_e))

# =========================================================================
# 25-Player Match Scoreboard Overlay Implementation
# =========================================================================

func _build_scoreboard_overlay():
	scoreboard_overlay = Control.new()
	scoreboard_overlay.name = "ScoreboardOverlay"
	scoreboard_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	scoreboard_overlay.visible = false
	scoreboard_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.04, 0.07, 0.88)
	scoreboard_overlay.add_child(dim)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	scoreboard_overlay.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 580)
	center.add_child(panel)
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.07, 0.09, 0.14, 0.98)
	style_panel.border_color = Color(0.25, 0.45, 0.75, 0.8)
	style_panel.set_border_width_all(2)
	style_panel.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	
	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)
	
	# Top bar with title and close button
	var top_hbox = HBoxContainer.new()
	root_vbox.add_child(top_hbox)
	
	var title = Label.new()
	title.text = "MATCH SCOREBOARD & 25-PLAYER ROSTER"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "Close (Tab/Esc)"
	close_btn.custom_minimum_size = Vector2(130, 32)
	close_btn.connect("pressed", Callable(self, "toggle_match_scoreboard"))
	top_hbox.add_child(close_btn)
	
	scoreboard_info_label = Label.new()
	scoreboard_info_label.text = "Mode: DOMINATION  |  Map Layout: 1v1  |  Active Teams: 2"
	scoreboard_info_label.add_theme_font_size_override("font_size", 13)
	scoreboard_info_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9))
	root_vbox.add_child(scoreboard_info_label)
	
	root_vbox.add_child(HSeparator.new())
	
	# Column Headers
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	root_vbox.add_child(header_hbox)
	
	var col_color = Label.new()
	col_color.text = "Color"
	col_color.custom_minimum_size = Vector2(36, 0)
	header_hbox.add_child(col_color)
	
	var col_team = Label.new()
	col_team.text = "Team & Swatch Name"
	col_team.custom_minimum_size = Vector2(210, 0)
	col_team.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(col_team)
	
	var col_ctrl = Label.new()
	col_ctrl.text = "Controller / Faction"
	col_ctrl.custom_minimum_size = Vector2(180, 0)
	header_hbox.add_child(col_ctrl)
	
	var col_bases = Label.new()
	col_bases.text = "Citadels"
	col_bases.custom_minimum_size = Vector2(65, 0)
	col_bases.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_hbox.add_child(col_bases)
	
	var col_towers = Label.new()
	col_towers.text = "Towers"
	col_towers.custom_minimum_size = Vector2(65, 0)
	col_towers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_hbox.add_child(col_towers)
	
	var col_units = Label.new()
	col_units.text = "Units"
	col_units.custom_minimum_size = Vector2(60, 0)
	col_units.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_hbox.add_child(col_units)
	
	var col_rate = Label.new()
	col_rate.text = "Energy Rate"
	col_rate.custom_minimum_size = Vector2(110, 0)
	col_rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_hbox.add_child(col_rate)
	
	var col_act = Label.new()
	col_act.text = "Spectate"
	col_act.custom_minimum_size = Vector2(75, 0)
	col_act.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_hbox.add_child(col_act)
	
	root_vbox.add_child(HSeparator.new())
	
	# Scrollable table container
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 390)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)
	
	scoreboard_rows_container = VBoxContainer.new()
	scoreboard_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scoreboard_rows_container.add_theme_constant_override("separation", 6)
	scroll.add_child(scoreboard_rows_container)
	
	add_child(scoreboard_overlay)

func toggle_match_scoreboard():
	if not scoreboard_overlay: return
	var is_open = not scoreboard_overlay.visible
	scoreboard_overlay.visible = is_open
	if is_open:
		_refresh_scoreboard_data()

func _refresh_scoreboard_data():
	if not scoreboard_rows_container: return
	for child in scoreboard_rows_container.get_children():
		child.queue_free()
	
	var m_mode = GameState.game_mode
	var m_layout = GameState.map_layout_id
	var m_biome = GameState.map_biome
	var teams_cnt = GameState.active_match_teams.size()
	var net_extra = ""
	if GameState.current_mode.begins_with("ONLINE"):
		net_extra = "  |  Room: " + GameState.room_code + " (" + GameState.room_privacy + ")"
	if scoreboard_info_label:
		scoreboard_info_label.text = "Mode: " + m_mode + "  |  Layout: " + m_layout + "  |  Biome: " + m_biome + "  |  Teams: " + str(teams_cnt) + net_extra

	var teams_to_show: Array[String] = []
	if not GameState.active_match_teams.is_empty():
		for t: String in GameState.active_match_teams:
			if not teams_to_show.has(t):
				teams_to_show.append(t)
	else:
		for t: String in GameState.ALL_TEAMS:
			if get_tree() and get_tree().get_nodes_in_group(t).size() > 0:
				teams_to_show.append(t)
		if teams_to_show.is_empty():
			teams_to_show = ["SideA", "SideB"]

	var am = (get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent())
	var bot_archetypes := {}
	if am:
		for ch in am.get_children():
			if ch is BotAI:
				bot_archetypes[ch.my_team] = ch.archetype

	for team_name in teams_to_show:
		var bases_count = 0
		var towers_count = 0
		var units_count = 0
		if get_tree():
			for n in get_tree().get_nodes_in_group(team_name):
				if not is_instance_valid(n): continue
				if "Base" in n.name or n.is_in_group("Citadel"):
					bases_count += 1
				elif "Tower" in n.name:
					towers_count += 1
				elif n.is_in_group("Targetable") or n is CharacterBody3D:
					units_count += 1

		var t_col = GameState.get_team_color(team_name)
		var t_col_name = GameState.get_team_color_name(team_name)
		var pen_pct = GameState.get_team_energy_penalty_pct(team_name)

		var row_panel = PanelContainer.new()
		var row_style = StyleBoxFlat.new()
		row_style.bg_color = Color(t_col.r * 0.15, t_col.g * 0.15, t_col.b * 0.15, 0.75)
		row_style.border_color = t_col
		row_style.set_border_width_all(1)
		row_style.set_corner_radius_all(4)
		row_panel.add_theme_stylebox_override("panel", row_style)
		scoreboard_rows_container.add_child(row_panel)

		var row_margin = MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 8)
		row_margin.add_theme_constant_override("margin_right", 8)
		row_margin.add_theme_constant_override("margin_top", 4)
		row_margin.add_theme_constant_override("margin_bottom", 4)
		row_panel.add_child(row_margin)

		var row_hbox = HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 10)
		row_margin.add_child(row_hbox)

		# Color Swatch
		var swatch = ColorRect.new()
		swatch.color = t_col
		swatch.custom_minimum_size = Vector2(24, 24)
		row_hbox.add_child(swatch)

		# Team & Color Name
		var name_lbl = Label.new()
		name_lbl.text = team_name + " (" + t_col_name + ")"
		name_lbl.custom_minimum_size = Vector2(210, 0)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_color_override("font_color", t_col.lightened(0.2))
		name_lbl.add_theme_font_size_override("font_size", 13)
		row_hbox.add_child(name_lbl)

		# Controller / Faction
		var ctrl_lbl = Label.new()
		var ctrl_desc = "AI Commander"
		if team_name == GameState.local_player_team and GameState.current_mode != "AI_VS_AI":
			ctrl_desc = "Local Player (" + GameState.player_display_name + ")"
		elif bot_archetypes.has(team_name):
			ctrl_desc = "AI (" + str(bot_archetypes[team_name]) + ")"
		elif GameState.current_mode.begins_with("ONLINE"):
			ctrl_desc = "Online Player"
		ctrl_lbl.text = ctrl_desc
		ctrl_lbl.custom_minimum_size = Vector2(180, 0)
		ctrl_lbl.add_theme_font_size_override("font_size", 12)
		row_hbox.add_child(ctrl_lbl)

		# Citadels
		var bases_lbl = Label.new()
		bases_lbl.text = str(bases_count)
		bases_lbl.custom_minimum_size = Vector2(65, 0)
		bases_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bases_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4) if bases_count <= 0 else Color(0.4, 1.0, 0.4))
		row_hbox.add_child(bases_lbl)

		# Towers
		var towers_lbl = Label.new()
		towers_lbl.text = str(towers_count)
		towers_lbl.custom_minimum_size = Vector2(65, 0)
		towers_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row_hbox.add_child(towers_lbl)

		# Units
		var units_lbl = Label.new()
		units_lbl.text = str(units_count)
		units_lbl.custom_minimum_size = Vector2(60, 0)
		units_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row_hbox.add_child(units_lbl)

		# Energy Rate
		var rate_lbl = Label.new()
		rate_lbl.text = "100%" if pen_pct == 0 else ("-" + str(pen_pct) + "% Asym")
		rate_lbl.custom_minimum_size = Vector2(110, 0)
		rate_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rate_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3) if pen_pct > 0 else Color(0.7, 0.9, 1.0))
		row_hbox.add_child(rate_lbl)

		# Focus / Spectate Button
		var focus_btn = Button.new()
		focus_btn.text = "Focus"
		focus_btn.custom_minimum_size = Vector2(75, 26)
		focus_btn.add_theme_font_size_override("font_size", 12)
		focus_btn.connect("pressed", Callable(self, "_on_scoreboard_focus_team").bind(team_name))
		row_hbox.add_child(focus_btn)

func _on_scoreboard_focus_team(team_name: String):
	var cam = _get_active_cam()
	if cam and cam.has_method("snap_to_team"):
		cam.snap_to_team(team_name)
	if scoreboard_overlay:
		scoreboard_overlay.visible = false


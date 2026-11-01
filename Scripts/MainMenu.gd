extends Control

var _anim_t: float = 0.0

func _ready():
	var bg = get_node_or_null("ColorRect")
	if bg:
		bg.color = Color(0.06, 0.09, 0.14, 1.0)

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

	var vbox = get_node_or_null("CenterContainer/VBoxContainer")
	if vbox:
		vbox.custom_minimum_size = Vector2(460, 0)
		var title = vbox.get_node_or_null("Title")
		if title:
			title.add_theme_font_size_override("font_size", 44)
			title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))

		var sub = Label.new()
		sub.name = "SubtitleBanner"
		sub.text = "TACTICAL COMMAND  •  9 FACTIONS + CHAOS  •  2 TO 25 PLAYERS"
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", 14)
		sub.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0, 0.95))
		vbox.add_child(sub)
		vbox.move_child(sub, 1)

		for child in vbox.get_children():
			if child is Button:
				_style_menu_button(child, child.name == "QuitBtn")

func _process(delta: float):
	_anim_t += delta
	var title = get_node_or_null("CenterContainer/VBoxContainer/Title")
	if title:
		var pulse = 0.92 + sin(_anim_t * 2.6) * 0.08
		title.modulate = Color(1.0, pulse, 0.85 + (pulse - 0.85), 1.0)

func _style_menu_button(btn: Button, is_danger: bool = false):
	btn.custom_minimum_size = Vector2(420, 50)
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.24, 0.10, 0.12, 0.95) if is_danger else Color(0.12, 0.18, 0.28, 0.95)
	normal.border_color = Color(0.85, 0.32, 0.32, 1.0) if is_danger else Color(0.82, 0.70, 0.24, 1.0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.18)
	hover.border_color = Color(1.0, 0.55, 0.55, 1.0) if is_danger else Color(0.35, 0.92, 1.0, 1.0)

	var pressed = normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.15)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.48))

func _on_online_play_pressed():
	GameState.current_mode = "ONLINE"
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _on_local_play_pressed():
	GameState.current_mode = "LOCAL"
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _on_private_games_pressed():
	GameState.current_mode = "ONLINE"
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")

func _on_settings_pressed():
	GameState.previous_menu = "res://Scenes/MainMenu.tscn"
	get_tree().change_scene_to_file("res://Scenes/SettingsMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()



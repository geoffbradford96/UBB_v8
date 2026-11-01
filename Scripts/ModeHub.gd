extends Control

func _ready():
	var bg = get_node_or_null("ColorRect")
	if bg:
		bg.color = Color(0.07, 0.11, 0.17, 1.0)

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
			title.text = "COMMAND OPERATIONS HUB"
			title.add_theme_font_size_override("font_size", 38)
			title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))

		var mode_banner = Label.new()
		mode_banner.name = "ModeBanner"
		var active_mode_str = "ONLINE COMMAND NETWORK" if GameState.current_mode.begins_with("ONLINE") else "LOCAL / SKIRMISH COMMAND"
		mode_banner.text = "ACTIVE CHANNEL: " + active_mode_str
		mode_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mode_banner.add_theme_font_size_override("font_size", 14)
		mode_banner.add_theme_color_override("font_color", Color(0.45, 0.92, 1.0, 0.95))
		vbox.add_child(mode_banner)
		vbox.move_child(mode_banner, 1)

		for child in vbox.get_children():
			if child is Button:
				_style_hub_button(child)

	var back_btn = get_node_or_null("BackButton")
	if back_btn is Button:
		_style_hub_button(back_btn, true)

func _style_hub_button(btn: Button, is_compact: bool = false):
	if not is_compact:
		btn.custom_minimum_size = Vector2(440, 50)
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.19, 0.29, 0.95)
	normal.border_color = Color(0.82, 0.70, 0.24, 1.0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.18)
	hover.border_color = Color(0.35, 0.92, 1.0, 1.0)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.48))

func _on_deck_making_pressed():
	get_tree().change_scene_to_file("res://Scenes/ArmyGathering.tscn")

func _on_war_games_pressed():
	get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")

func _on_ai_vs_ai_pressed():
	GameState.current_mode = "LOCAL"
	get_tree().change_scene_to_file("res://Scenes/MatchSetup.tscn")

func _on_settings_pressed():
	GameState.previous_menu = "res://Scenes/ModeHub.tscn"
	get_tree().change_scene_to_file("res://Scenes/SettingsMenu.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


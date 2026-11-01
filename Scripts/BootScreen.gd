extends Control

var _transitioned: bool = false
var _pulse_time: float = 0.0
var _subtitle_lbl: Label = null

func _ready():
	print("Booting up...")
	var bg = get_node_or_null("ColorRect")
	if bg:
		bg.color = Color(0.04, 0.06, 0.10, 1.0)

	var top_trim = ColorRect.new()
	top_trim.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_trim.offset_bottom = 8.0
	top_trim.color = Color(0.85, 0.72, 0.22, 1.0)
	add_child(top_trim)

	var bot_trim = ColorRect.new()
	bot_trim.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_trim.offset_top = -8.0
	bot_trim.color = Color(0.18, 0.78, 0.95, 1.0)
	add_child(bot_trim)

	var cc = get_node_or_null("CenterContainer")
	var main_lbl = get_node_or_null("CenterContainer/Label")
	if main_lbl:
		main_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36, 1.0))
		main_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if cc:
		_subtitle_lbl = Label.new()
		_subtitle_lbl.text = "UNAVURE BATTLE BONANZA v0.8  •  9 FACTIONS + CHAOS  •  GPU PRE-RENDER & UP TO 25 COMMANDERS"
		_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_subtitle_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_subtitle_lbl.offset_top = -90.0
		_subtitle_lbl.offset_bottom = -45.0
		_subtitle_lbl.add_theme_font_size_override("font_size", 18)
		_subtitle_lbl.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0, 0.9))
		add_child(_subtitle_lbl)

	# Wait for 2 seconds (simulate loading or showing a logo)
	await get_tree().create_timer(2.0).timeout
	if _transitioned or not is_inside_tree():
		return
	_proceed()

func _process(delta: float):
	_pulse_time += delta
	var main_lbl = get_node_or_null("CenterContainer/Label")
	if main_lbl:
		var glow = 0.88 + sin(_pulse_time * 3.5) * 0.12
		main_lbl.modulate = Color(glow, glow, 1.0, 1.0)

func _input(event):
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if event.is_pressed():
			_proceed()

func _proceed():
	if _transitioned or not is_inside_tree() or get_tree() == null: return
	_transitioned = true
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


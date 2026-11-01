class_name LoadingScreen
extends CanvasLayer

signal pre_render_finished

var _bg: ColorRect = null
var _title_lbl: Label = null
var _stage_lbl: Label = null
var _stats_lbl: Label = null
var _tip_lbl: Label = null
var _progress_bar: ProgressBar = null
var _progress_val: float = 0.0
var _is_completed: bool = false

const TACTICAL_TIPS: Array[String] = [
	"TIP: Static biome scenery is pre-rendered into GPU MultiMesh batches & UPDATE_ONCE probes for maximum FPS.",
	"TIP: In Deep Space Vacuum, unshielded organic units take continuous exposure damage—deploy 360° shield emitters!",
	"TIP: In Deep Jungle, wooden board paths are safe, while off-path Quicksand Sinkholes slow and sink ground troops.",
	"TIP: Distant 3D props automatically scale detail and cull via hardware GPU Visibility Ranges (LOD).",
	"TIP: Territorial creatures (Scorpions, Gorillas, Monkeys, Swarm Ants) defend their nests until the structure is razed."
]

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	if _bg != null and is_instance_valid(_bg):
		return

	_bg = ColorRect.new()
	_bg.name = "CurtainBG"
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.03, 0.05, 0.09, 0.96)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	var top_bar := ColorRect.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 6.0
	top_bar.color = Color(0.18, 0.78, 0.95, 1.0)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(top_bar)

	var bot_bar := ColorRect.new()
	bot_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_bar.offset_top = -6.0
	bot_bar.color = Color(0.88, 0.72, 0.22, 1.0)
	bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(bot_bar)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(720, 260)
	vbox.add_theme_constant_override("separation", 16)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.name = "TitleLabel"
	_title_lbl.text = "PRE-RENDERING BATTLEFIELD ENVIRONMENT..."
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 28)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36, 1.0))
	vbox.add_child(_title_lbl)

	_stage_lbl = Label.new()
	_stage_lbl.name = "StageLabel"
	_stage_lbl.text = "Initializing GPU MultiMesh Batches & Hardware LODs..."
	_stage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_lbl.add_theme_font_size_override("font_size", 18)
	_stage_lbl.add_theme_color_override("font_color", Color(0.65, 0.90, 1.0, 0.95))
	vbox.add_child(_stage_lbl)

	_progress_bar = ProgressBar.new()
	_progress_bar.name = "PreRenderProgressBar"
	_progress_bar.custom_minimum_size = Vector2(680, 28)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 15.0
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_progress_bar)

	_stats_lbl = Label.new()
	_stats_lbl.name = "StatsLabel"
	_stats_lbl.text = "GPU Pipeline: Forward+  •  Environment Bake: Active"
	_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_lbl.add_theme_font_size_override("font_size", 14)
	_stats_lbl.add_theme_color_override("font_color", Color(0.55, 0.72, 0.82, 0.9))
	vbox.add_child(_stats_lbl)

	_tip_lbl = Label.new()
	_tip_lbl.name = "TipLabel"
	_tip_lbl.text = TACTICAL_TIPS[randi() % TACTICAL_TIPS.size()]
	_tip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_lbl.add_theme_font_size_override("font_size", 15)
	_tip_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92, 0.85))
	vbox.add_child(_tip_lbl)

func set_stage(progress: float, stage_text: String, stats_text: String = "") -> void:
	_build_ui()
	_progress_val = clampf(progress, 0.0, 100.0)
	if _progress_bar:
		_progress_bar.value = _progress_val
	if _stage_lbl:
		_stage_lbl.text = stage_text
	if stats_text != "" and _stats_lbl:
		_stats_lbl.text = stats_text

func run_arena_pre_render_sequence(arena: Node3D, biome_name: String, bake_stats: Dictionary) -> void:
	_build_ui()
	var nice_biome := biome_name.replace("_", " ")
	if _title_lbl:
		_title_lbl.text = "PRE-RENDERING BIOME: %s" % nice_biome

	var summary := "GPU MultiMesh Batches: %d  •  LOD Nodes: %d  •  Frozen Static Props: %d  •  Shaders: %d" % [
		int(bake_stats.get("multimesh_batches", 0)),
		int(bake_stats.get("configured_lod_nodes", 0)),
		int(bake_stats.get("frozen_static_nodes", 0)),
		int(bake_stats.get("compiled_gpu_shaders", 0))
	]
	set_stage(45.0, "Compiling GPU Shaders & Uploading MultiMesh Instance Buffers...", summary)

	# In headless mode or if not inside tree, complete immediately without frame awaits
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or get_tree() == null:
		set_stage(100.0, "Environment Pre-Rendered & Baked!", summary)
		_is_completed = true
		visible = false
		pre_render_finished.emit()
		return

	# Allow 2 rendering frames for ReflectionProbe (UPDATE_ONCE), MultiMesh buffers, and shaders to warm up
	await get_tree().process_frame
	if not is_inside_tree() or get_tree() == null:
		return
	set_stage(80.0, "Baking Static Environment Reflection Probe & Distance LODs...", summary)

	await get_tree().process_frame
	if not is_inside_tree() or get_tree() == null:
		return
	set_stage(100.0, "Battlefield Ready!", summary)
	_is_completed = true
	pre_render_finished.emit()

	var tw := create_tween()
	if tw and _bg:
		tw.tween_property(_bg, "modulate:a", 0.0, 0.32)
		tw.tween_callback(func():
			visible = false
			queue_free()
		)
	else:
		visible = false
		queue_free()

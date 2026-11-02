extends Control

const WildlifeModelBuilderScript = preload("res://Scripts/WildlifeModelBuilder.gd")

signal card_clicked(card_ui_node)

@export var card_data: Resource

@onready var cost_label = $CostLabel
@onready var name_label = $NameLabel
@onready var background = $Background
@onready var hp_label = $HPLabel
@onready var type_label = $TypeLabel

var is_selected: bool = false
var is_hovered: bool = false
var art_rect: TextureRect = null

var _base_bg_color: Color = Color(0.14, 0.16, 0.20, 1.0)
var _base_border_color: Color = Color(0.8, 0.7, 0.2, 1.0)

var _faction_badge_lbl: Label = null
var _emblem_glyph_lbl: Label = null
var _spawn_badge_lbl: Label = null
var _inner_art_frame: ColorRect = null

# Structured Stat Border/Footer controls
var _stat_panel: PanelContainer = null
var _hp_stat_lbl: Label = null
var _atk_stat_lbl: Label = null
var _rng_stat_lbl: Label = null
var _spd_stat_lbl: Label = null
var _def_stat_lbl: Label = null
var _role_stat_lbl: Label = null

static var _thumbnail_cache: Dictionary = {}
static var _stats_cache: Dictionary = {}

static func clear_caches():
	_thumbnail_cache.clear()
	_stats_cache.clear()

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("card_clicked", self)

func _ready():
	art_rect = get_node_or_null("CardArt")
	pivot_offset = custom_minimum_size * 0.5
	_setup_card_chrome()
	for child in get_children():
		if child is Control and child != self:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if card_data:
		set_card_data(card_data)

func _setup_card_chrome():
	# Ensure base card dimension
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(150, 220)

	# 1. Art Frame / Placeholder
	var art_ph = get_node_or_null("ArtPlaceholder")
	if art_ph:
		art_ph.anchor_left = 0.0
		art_ph.anchor_top = 0.0
		art_ph.anchor_right = 1.0
		art_ph.anchor_bottom = 0.0
		art_ph.offset_left = 7.0
		art_ph.offset_top = 18.0
		art_ph.offset_right = -7.0
		art_ph.offset_bottom = 98.0
		art_ph.color = Color(0.08, 0.10, 0.15, 1.0)

		if _inner_art_frame == null:
			_inner_art_frame = ColorRect.new()
			_inner_art_frame.name = "InnerArtFrame"
			_inner_art_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
			_inner_art_frame.offset_left = 2.0
			_inner_art_frame.offset_top = 2.0
			_inner_art_frame.offset_right = -2.0
			_inner_art_frame.offset_bottom = -2.0
			_inner_art_frame.color = Color(0.04, 0.06, 0.10, 0.95)
			_inner_art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			art_ph.add_child(_inner_art_frame)

			_emblem_glyph_lbl = Label.new()
			_emblem_glyph_lbl.name = "EmblemGlyph"
			_emblem_glyph_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			_emblem_glyph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_emblem_glyph_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_emblem_glyph_lbl.add_theme_font_size_override("font_size", 18)
			_emblem_glyph_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_inner_art_frame.add_child(_emblem_glyph_lbl)

	# 2. CardArt TextureRect
	if art_rect:
		if art_rect.get_parent() != self and _inner_art_frame != null:
			pass
		art_rect.anchor_left = 0.0
		art_rect.anchor_top = 0.0
		art_rect.anchor_right = 1.0
		art_rect.anchor_bottom = 0.0
		art_rect.offset_left = 9.0
		art_rect.offset_top = 20.0
		art_rect.offset_right = -9.0
		art_rect.offset_bottom = 96.0
		art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 3. Cost Label & Badge (Top Left)
	if cost_label:
		cost_label.offset_left = -3.0
		cost_label.offset_top = -3.0
		cost_label.offset_right = 25.0
		cost_label.offset_bottom = 23.0
		cost_label.add_theme_font_size_override("font_size", 15)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var cost_bg = cost_label.get_node_or_null("CostBackground")
		if cost_bg:
			cost_bg.color = Color(0.0, 0.85, 1.0, 1.0)

	# 4. Faction Banner Label (Top Center)
	if _faction_badge_lbl == null:
		_faction_badge_lbl = Label.new()
		_faction_badge_lbl.name = "FactionBadge"
		_faction_badge_lbl.anchor_left = 0.0
		_faction_badge_lbl.anchor_top = 0.0
		_faction_badge_lbl.anchor_right = 1.0
		_faction_badge_lbl.anchor_bottom = 0.0
		_faction_badge_lbl.offset_left = 26.0
		_faction_badge_lbl.offset_top = 1.0
		_faction_badge_lbl.offset_right = -34.0
		_faction_badge_lbl.offset_bottom = 17.0
		_faction_badge_lbl.add_theme_font_size_override("font_size", 8)
		_faction_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_faction_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_faction_badge_lbl.clip_text = true
		_faction_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_faction_badge_lbl)

	# 5. Spawn Count Badge (Top Right)
	if _spawn_badge_lbl == null:
		_spawn_badge_lbl = Label.new()
		_spawn_badge_lbl.name = "SpawnBadge"
		_spawn_badge_lbl.anchor_left = 1.0
		_spawn_badge_lbl.anchor_top = 0.0
		_spawn_badge_lbl.anchor_right = 1.0
		_spawn_badge_lbl.anchor_bottom = 0.0
		_spawn_badge_lbl.offset_left = -36.0
		_spawn_badge_lbl.offset_top = 1.0
		_spawn_badge_lbl.offset_right = -4.0
		_spawn_badge_lbl.offset_bottom = 17.0
		_spawn_badge_lbl.add_theme_font_size_override("font_size", 9)
		_spawn_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_spawn_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_spawn_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_spawn_badge_lbl)

	# 6. Name Label
	if name_label:
		name_label.anchor_left = 0.0
		name_label.anchor_top = 0.0
		name_label.anchor_right = 1.0
		name_label.anchor_bottom = 0.0
		name_label.offset_left = 6.0
		name_label.offset_top = 99.0
		name_label.offset_right = -6.0
		name_label.offset_bottom = 117.0
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.clip_text = true

	# 7. Description Label
	var desc_label = get_node_or_null("DescLabel")
	if desc_label:
		desc_label.anchor_left = 0.0
		desc_label.anchor_top = 0.0
		desc_label.anchor_right = 1.0
		desc_label.anchor_bottom = 0.0
		desc_label.offset_left = 7.0
		desc_label.offset_top = 117.0
		desc_label.offset_right = -7.0
		desc_label.offset_bottom = 162.0
		desc_label.add_theme_font_size_override("font_size", 8)
		desc_label.add_theme_color_override("font_color", Color(0.90, 0.93, 0.98, 0.95))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.clip_text = true
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 8. Stat Border / Footer Panel
	_setup_stat_panel()

	# Hide legacy raw labels if present
	if hp_label:
		hp_label.visible = false
	if type_label:
		type_label.visible = false

func _setup_stat_panel():
	if _stat_panel == null:
		_stat_panel = PanelContainer.new()
		_stat_panel.name = "StatBorderPanel"
		_stat_panel.anchor_left = 0.0
		_stat_panel.anchor_top = 0.0
		_stat_panel.anchor_right = 1.0
		_stat_panel.anchor_bottom = 0.0
		_stat_panel.offset_left = 6.0
		_stat_panel.offset_top = 163.0
		_stat_panel.offset_right = -6.0
		_stat_panel.offset_bottom = 215.0
		_stat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var stat_sb = StyleBoxFlat.new()
		stat_sb.bg_color = Color(0.04, 0.06, 0.10, 0.90)
		stat_sb.border_color = Color(0.4, 0.5, 0.65, 0.5)
		stat_sb.set_border_width_all(1)
		stat_sb.set_corner_radius_all(4)
		stat_sb.content_margin_left = 4
		stat_sb.content_margin_right = 4
		stat_sb.content_margin_top = 2
		stat_sb.content_margin_bottom = 2
		_stat_panel.add_theme_stylebox_override("panel", stat_sb)
		add_child(_stat_panel)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stat_panel.add_child(vbox)

		# Row 1: HP, ATK, RNG
		var row1 = HBoxContainer.new()
		row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row1.add_theme_constant_override("separation", 4)
		row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(row1)

		_hp_stat_lbl = _create_stat_label("HP 100", Color(0.4, 0.98, 0.5), HORIZONTAL_ALIGNMENT_LEFT)
		_hp_stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row1.add_child(_hp_stat_lbl)

		_atk_stat_lbl = _create_stat_label("ATK 15", Color(1.0, 0.65, 0.25), HORIZONTAL_ALIGNMENT_CENTER)
		_atk_stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row1.add_child(_atk_stat_lbl)

		_rng_stat_lbl = _create_stat_label("MEL", Color(0.45, 0.88, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
		_rng_stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row1.add_child(_rng_stat_lbl)

		# Row 2: SPD, ARM/SHD, ROLE
		var row2 = HBoxContainer.new()
		row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_theme_constant_override("separation", 4)
		row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(row2)

		_spd_stat_lbl = _create_stat_label("SPD 4.0", Color(1.0, 0.9, 0.35), HORIZONTAL_ALIGNMENT_LEFT)
		_spd_stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(_spd_stat_lbl)

		_def_stat_lbl = _create_stat_label("DEF -", Color(0.95, 0.82, 0.35), HORIZONTAL_ALIGNMENT_CENTER)
		_def_stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(_def_stat_lbl)

		_role_stat_lbl = _create_stat_label("Unit", Color(0.85, 0.85, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
		_role_stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(_role_stat_lbl)

func _create_stat_label(default_text: String, color: Color, align: HorizontalAlignment) -> Label:
	var lbl = Label.new()
	lbl.text = default_text
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

func _on_mouse_entered():
	is_hovered = true
	_refresh_visual_state()

func _on_mouse_exited():
	is_hovered = false
	_refresh_visual_state()

func set_selected(selected: bool):
	is_selected = selected
	var target_y = -22.0 if is_selected else 0.0
	var tw = create_tween()
	if tw:
		tw.tween_property(self, "position:y", target_y, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		position.y = target_y
	_refresh_visual_state()

func _refresh_visual_state():
	var border = get_node_or_null("Border")
	if is_selected:
		background.color = Color(0.16, 0.52, 0.24, 1.0)
		if border:
			border.border_color = Color(0.35, 1.0, 0.55, 1.0)
			border.border_width = 5.0
	elif is_hovered:
		background.color = _base_bg_color.lightened(0.14)
		if border:
			border.border_color = _base_border_color.lightened(0.28)
			border.border_width = 4.5
	else:
		background.color = _base_bg_color
		if border:
			border.border_color = _base_border_color
			border.border_width = 3.5

func _get_card_file_key(data: Resource) -> String:
	if not data:
		return ""
	if data.resource_path != "":
		return data.resource_path.get_file().trim_suffix(".remap").trim_suffix(".tres")
	return str(data.card_name).replace(" ", "") + "Card"

func _load_card_thumbnail(card_key: String) -> Texture2D:
	if card_key == "":
		return null
	if _thumbnail_cache.has(card_key):
		return _thumbnail_cache[card_key]

	var res_path = "res://UI/CardThumbnails/" + card_key + ".png"
	var tex: Texture2D = null
	if ResourceLoader.exists(res_path):
		tex = ResourceLoader.load(res_path) as Texture2D

	if tex == null:
		var global_p = ProjectSettings.globalize_path(res_path)
		if FileAccess.file_exists(global_p):
			var img = Image.load_from_file(global_p)
			if img and not img.is_empty():
				tex = ImageTexture.create_from_image(img)

	if tex != null:
		_thumbnail_cache[card_key] = tex
	return tex

func _get_unit_stats(data: Resource) -> Dictionary:
	if not data:
		return {}
	var key: String = data.resource_path if data.resource_path != "" else str(data.card_name)
	if _stats_cache.has(key):
		return _stats_cache[key]

	var stats := {
		"hp": float(data.get("max_hp")) if "max_hp" in data else 100.0,
		"atk": 15.0,
		"rng": 2.0 if ("is_melee" in data and data.is_melee) else 10.0,
		"spd": 4.0,
		"armor": 0.0,
		"shield": 0.0,
		"attribute": "Organic",
		"role": "Unit",
		"is_spell": bool(data.get("is_spell")) if "is_spell" in data else false,
		"spawn": int(data.get("spawn_count")) if "spawn_count" in data else 1
	}

	if "card_type" in data:
		stats["role"] = str(data.card_type)

	var u_scene: PackedScene = data.get("unit_scene") if "unit_scene" in data else null
	if u_scene and u_scene.can_instantiate():
		var state = u_scene.get_state()
		if state and state.get_node_count() > 0:
			for i in range(state.get_node_property_count(0)):
				var p_name = state.get_node_property_name(0, i)
				var p_val = state.get_node_property_value(0, i)
				match p_name:
					"max_health":
						stats["hp"] = float(p_val)
					"attack_damage":
						stats["atk"] = float(p_val)
					"attack_range":
						stats["rng"] = float(p_val)
					"speed":
						stats["spd"] = float(p_val)
					"max_armor":
						stats["armor"] = float(p_val)
					"max_shield":
						stats["shield"] = float(p_val)
					"unit_attribute":
						stats["attribute"] = str(p_val)

	var c_name = str(data.card_name)
	if "Wildlife" in c_name:
		var w_info = WildlifeModelBuilderScript.get_species_info(c_name)
		if not w_info.is_empty():
			if w_info.has("hp"): stats["hp"] = float(w_info["hp"])
			if w_info.has("dmg"): stats["atk"] = float(w_info["dmg"])
			if w_info.has("rng"): stats["rng"] = float(w_info["rng"])
			if w_info.has("spd"): stats["spd"] = float(w_info["spd"])
			if w_info.has("armor"): stats["armor"] = float(w_info["armor"])
			if w_info.get("fly", false): stats["role"] = "Flyer"
			elif w_info.get("cmdr", false): stats["role"] = "Commander"

	_stats_cache[key] = stats
	return stats

func _get_card_faction_style(c_name: String) -> Dictionary:
	if "Nightmare" in c_name or "Halloween" in c_name:
		return {
			"tag": "THE NIGHTMARE",
			"bg": Color(0.12, 0.05, 0.16, 1.0),
			"art": Color(0.24, 0.08, 0.32, 1.0),
			"border": Color(1.0, 0.48, 0.06, 1.0),
			"glyph": "* HALLOW *",
			"text": Color(1.0, 0.84, 0.45, 1.0)
		}
	elif "Winter" in c_name or "Yuletide" in c_name or "Yule" in c_name:
		return {
			"tag": "THE WINTER COURT",
			"bg": Color(0.06, 0.14, 0.25, 1.0),
			"art": Color(0.12, 0.26, 0.45, 1.0),
			"border": Color(0.45, 0.90, 1.0, 1.0),
			"glyph": "* YULE *",
			"text": Color(0.85, 0.96, 1.0, 1.0)
		}
	elif "Wildlife" in c_name:
		return {
			"tag": "GALACTIC WILDLIFE",
			"bg": Color(0.06, 0.22, 0.11, 1.0),
			"art": Color(0.11, 0.38, 0.18, 1.0),
			"border": Color(0.38, 0.96, 0.45, 1.0),
			"glyph": "~ FAUNA ~",
			"text": Color(0.72, 1.0, 0.76, 1.0)
		}
	elif "Primitive" in c_name:
		return {
			"tag": "PRIMITIVES",
			"bg": Color(0.22, 0.15, 0.09, 1.0),
			"art": Color(0.38, 0.26, 0.15, 1.0),
			"border": Color(0.88, 0.72, 0.44, 1.0),
			"glyph": "^ AGES ^",
			"text": Color(0.96, 0.86, 0.65, 1.0)
		}
	elif "Plague" in c_name:
		return {
			"tag": "PLAGUE OF HARMONY",
			"bg": Color(0.18, 0.15, 0.05, 1.0),
			"art": Color(0.36, 0.28, 0.06, 1.0),
			"border": Color(1.0, 0.85, 0.18, 1.0),
			"glyph": "[ EYE ]",
			"text": Color(1.0, 0.92, 0.45, 1.0)
		}
	elif "Gilded" in c_name:
		return {
			"tag": "GILDED HARMONY",
			"bg": Color(0.05, 0.18, 0.12, 1.0),
			"art": Color(0.08, 0.32, 0.20, 1.0),
			"border": Color(0.55, 0.92, 1.0, 1.0),
			"glyph": "< HARMONY >",
			"text": Color(0.75, 0.96, 1.0, 1.0)
		}
	elif "Void" in c_name:
		return {
			"tag": "THE VOID SWARM",
			"bg": Color(0.14, 0.06, 0.22, 1.0),
			"art": Color(0.28, 0.08, 0.42, 1.0),
			"border": Color(0.85, 0.25, 0.98, 1.0),
			"glyph": "{ VOID }",
			"text": Color(0.95, 0.65, 1.0, 1.0)
		}
	elif "Rimworlder" in c_name or "Sky" in c_name or "Stone" in c_name or "Giant" in c_name or "Great" in c_name or "Beast" in c_name:
		return {
			"tag": "THE RIMWORLDERS",
			"bg": Color(0.08, 0.19, 0.09, 1.0),
			"art": Color(0.14, 0.34, 0.16, 1.0),
			"border": Color(0.30, 0.90, 0.45, 1.0),
			"glyph": "/ BEAST \\",
			"text": Color(0.65, 1.0, 0.72, 1.0)
		}
	elif "Scrap" in c_name:
		return {
			"tag": "PIRATE KINGDOMS",
			"bg": Color(0.22, 0.12, 0.06, 1.0),
			"art": Color(0.40, 0.20, 0.08, 1.0),
			"border": Color(0.95, 0.50, 0.15, 1.0),
			"glyph": "# SCRAP #",
			"text": Color(1.0, 0.78, 0.45, 1.0)
		}
	elif "Reach" in c_name:
		return {
			"tag": "THE REACH",
			"bg": Color(0.06, 0.16, 0.22, 1.0),
			"art": Color(0.08, 0.28, 0.38, 1.0),
			"border": Color(0.15, 0.88, 0.98, 1.0),
			"glyph": "= SYN = ",
			"text": Color(0.60, 0.96, 1.0, 1.0)
		}
	else:
		return {
			"tag": "SOL DOMINION",
			"bg": Color(0.08, 0.15, 0.26, 1.0),
			"art": Color(0.14, 0.26, 0.45, 1.0),
			"border": Color(0.88, 0.74, 0.25, 1.0),
			"glyph": "* SOL *",
			"text": Color(1.0, 0.90, 0.55, 1.0)
		}

func set_card_data(data: Resource):
	if not data:
		return
	card_data = data
	_setup_card_chrome()

	cost_label.text = str(data.cost) if data.cost > 0 else "0"
	var display_title: String = data.card_name
	if "Wildlife" in str(data.card_name):
		var w_info = WildlifeModelBuilderScript.get_species_info(str(data.card_name))
		display_title = str(w_info.get("title", data.card_name))
	name_label.text = display_title

	var style = _get_card_faction_style(str(data.card_name))
	_base_bg_color = style["bg"]
	_base_border_color = style["border"]

	var art_ph = get_node_or_null("ArtPlaceholder")
	if art_ph:
		art_ph.color = style["art"]

	if _faction_badge_lbl:
		_faction_badge_lbl.text = style["tag"]
		_faction_badge_lbl.add_theme_color_override("font_color", style["text"])

	var sp_cnt: int = int(data.spawn_count) if "spawn_count" in data else 1
	if _spawn_badge_lbl:
		if data.is_spell:
			_spawn_badge_lbl.text = "AOE"
			_spawn_badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
		elif "card_type" in data and data.card_type == "Commander":
			_spawn_badge_lbl.text = "HERO"
			_spawn_badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
		else:
			_spawn_badge_lbl.text = "x" + str(maxi(1, sp_cnt))
			_spawn_badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))

	# Load & display unit thumbnail
	var card_key = _get_card_file_key(data)
	var thumb_tex = _load_card_thumbnail(card_key)
	if art_rect:
		if thumb_tex:
			art_rect.texture = thumb_tex
			art_rect.visible = true
			if _emblem_glyph_lbl:
				_emblem_glyph_lbl.visible = false
		else:
			art_rect.visible = false
			if _emblem_glyph_lbl:
				_emblem_glyph_lbl.text = style["glyph"]
				_emblem_glyph_lbl.visible = true

	name_label.add_theme_color_override("font_color", style["text"])

	# Unit description
	var desc_label = get_node_or_null("DescLabel")
	var d_txt: String = str(data.description).strip_edges() if "description" in data else ""
	if d_txt == "" or d_txt == "Description here...":
		d_txt = _get_card_fallback_description(data)
	if desc_label:
		desc_label.text = d_txt

	# Extract comprehensive stats
	var stats = _get_unit_stats(data)

	# Populate stat labels
	if stats["is_spell"]:
		_base_bg_color = Color(0.32, 0.08, 0.10, 1.0)
		_base_border_color = Color(1.0, 0.35, 0.25, 1.0)
		if _hp_stat_lbl:
			_hp_stat_lbl.text = "BURST"
			_hp_stat_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
		if _atk_stat_lbl:
			_atk_stat_lbl.text = "AOE"
			_atk_stat_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.25))
		if _rng_stat_lbl:
			_rng_stat_lbl.text = "GLOBAL"
			_rng_stat_lbl.add_theme_color_override("font_color", Color(0.45, 0.88, 1.0))
		if _spd_stat_lbl:
			_spd_stat_lbl.text = "INSTANT"
		if _def_stat_lbl:
			_def_stat_lbl.text = "SPELL"
		if _role_stat_lbl:
			_role_stat_lbl.text = "Strike"
	else:
		if _hp_stat_lbl:
			_hp_stat_lbl.text = "HP " + str(int(stats["hp"]))
			_hp_stat_lbl.add_theme_color_override("font_color", Color(0.4, 0.98, 0.5))

		if _atk_stat_lbl:
			_atk_stat_lbl.text = "ATK " + str(int(stats["atk"]))
			_atk_stat_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.25))

		if _rng_stat_lbl:
			if stats["rng"] <= 3.0:
				_rng_stat_lbl.text = "MEL"
				_rng_stat_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
			else:
				_rng_stat_lbl.text = str(int(stats["rng"])) + "m"
				_rng_stat_lbl.add_theme_color_override("font_color", Color(0.45, 0.88, 1.0))

		if _spd_stat_lbl:
			_spd_stat_lbl.text = "SPD " + ("%.1f" % stats["spd"])
			_spd_stat_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))

		if _def_stat_lbl:
			if stats["armor"] > 0:
				_def_stat_lbl.text = "ARM " + str(int(stats["armor"]))
				_def_stat_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
			elif stats["shield"] > 0:
				_def_stat_lbl.text = "SHD " + str(int(stats["shield"]))
				_def_stat_lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
			else:
				_def_stat_lbl.text = "DEF -"
				_def_stat_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))

		if _role_stat_lbl:
			var r_str: String = str(stats["role"])
			if r_str == "Commander":
				_base_border_color = Color(1.0, 0.84, 0.22, 1.0)
				_role_stat_lbl.text = "Cmdr"
				_role_stat_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
			elif r_str == "Vehicle":
				_role_stat_lbl.text = "Armor"
				_role_stat_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
			elif r_str == "Flyer":
				_role_stat_lbl.text = "Air"
				_role_stat_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
			else:
				_role_stat_lbl.text = r_str.substr(0, 5)
				_role_stat_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))

	# Update legacy labels for backward compatibility
	if hp_label:
		hp_label.text = "HP " + str(int(stats["hp"]))
	if type_label:
		type_label.text = "Melee" if (stats["rng"] <= 3.0) else "Ranged"

	# Multi-line inspection tooltip
	var tip_lines = []
	tip_lines.append(display_title + " (" + style["tag"] + ")")
	tip_lines.append("Role: " + str(stats["role"]) + " | Cost: " + str(data.cost) + " | Count: x" + str(maxi(1, sp_cnt)))
	if not stats["is_spell"]:
		tip_lines.append("HP: %d | ATK: %d | Range: %s | Speed: %.1f" % [int(stats["hp"]), int(stats["atk"]), ("Melee" if stats["rng"] <= 3.0 else str(int(stats["rng"])) + "m"), stats["spd"]])
		if stats["armor"] > 0:
			tip_lines.append("Armor: %d" % int(stats["armor"]))
		if stats["shield"] > 0:
			tip_lines.append("Shield: %d" % int(stats["shield"]))
		if stats["attribute"] != "":
			tip_lines.append("Attribute: " + str(stats["attribute"]))
	tip_lines.append("")
	tip_lines.append(d_txt)
	tooltip_text = "\n".join(tip_lines)

	_refresh_visual_state()

func _get_card_fallback_description(data: Resource) -> String:
	var cname: String = str(data.card_name).replace(" ", "")
	var fallback_map := {
		"Assassin": "Stealth flanker with twin vibrato blades. Eliminates backline targets rapidly.",
		"CheapGrunt": "Sol Dominion infantry squad. Reliable frontline riflemen.",
		"CommandBay": "Forward Command Bay: Expands deployment zone and spawns free infantry.",
		"HeroHunter": "Specialized bounty hunter dealing bonus damage to Commanders & Heroes.",
		"Medic": "Field Medic: Restores health to wounded biological and hybrid allies.",
		"RepairMan": "Combat Engineer: Repairs friendly Tanks, Mechs, and Walkers.",
		"Sniper": "Long-range sharpshooter with high single-target armor-piercing damage.",
		"SupportingFire": "Heavy weapons squad providing sustained suppressive rifle fire.",
		"ReachCommander": "Cybernetic Overmind: Leads The Reach and links nearby units (+15% per ally).",
		"ReachHunter": "Cyber-assassin that hunts Commanders and powers up near Reach allies.",
		"ReachMelee": "5x Cyber-Trooper squad. Gains +15% Speed, Attack & Scale per nearby Reach ally.",
		"ReachPlane": "Twin-thruster cybernetic strike craft that bypasses ground terrain.",
		"ReachRanged": "Precision plasma rifle squad boosted by Reach Network Synergy.",
		"ReachRepair": "Nano-engineer that repairs friendly armor and links to Reach networks.",
		"ReachTank": "Hover battle tank with cyan plasma core and Reach Network Synergy.",
		"ScrapCommander": "Pirate Warlord: Leads savage salvage raids with heavy scrap armor.",
		"ScrapHunter": "Pirate bounty hunter specializing in taking down enemy Commanders.",
		"ScrapMelee": "Raider boarding crew armed with jagged scrap blades.",
		"ScrapPlane": "Jury-rigged pirate gunship that rains fire from above.",
		"ScrapRanged": "Pirate blaster squad delivering heavy salvo fire.",
		"ScrapRepair": "Salvage mechanic that welds and repairs friendly Tanks & Mechs.",
		"ScrapTank": "Volatile Scrap Tank: Charges the frontline and detonates on destruction!"
	}
	if fallback_map.has(cname):
		return fallback_map[cname]
	var sp_cnt: int = int(data.spawn_count) if "spawn_count" in data else 1
	return "Deploys x" + str(maxi(1, sp_cnt)) + " " + str(data.card_name) + " to the battlefield."

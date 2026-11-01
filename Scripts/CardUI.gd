extends Control

const WildlifeModelBuilder = preload("res://Scripts/WildlifeModelBuilder.gd")

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

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("card_clicked", self)

func _ready():
	art_rect = get_node_or_null("CardArt")
	pivot_offset = custom_minimum_size * 0.5
	_setup_card_chrome()
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if card_data:
		set_card_data(card_data)

func _setup_card_chrome():
	var art_ph = get_node_or_null("ArtPlaceholder")
	if art_ph:
		art_ph.anchor_left = 0.0
		art_ph.anchor_top = 0.0
		art_ph.anchor_right = 1.0
		art_ph.anchor_bottom = 0.0
		art_ph.offset_left = 8.0
		art_ph.offset_top = 8.0
		art_ph.offset_right = -8.0
		art_ph.offset_bottom = 92.0
		if _inner_art_frame == null:
			_inner_art_frame = ColorRect.new()
			_inner_art_frame.name = "InnerArtFrame"
			_inner_art_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
			_inner_art_frame.offset_left = 3.0
			_inner_art_frame.offset_top = 18.0
			_inner_art_frame.offset_right = -3.0
			_inner_art_frame.offset_bottom = -3.0
			_inner_art_frame.color = Color(0.06, 0.08, 0.12, 0.85)
			_inner_art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			art_ph.add_child(_inner_art_frame)

			_faction_badge_lbl = Label.new()
			_faction_badge_lbl.name = "FactionBadge"
			_faction_badge_lbl.anchor_left = 0.0
			_faction_badge_lbl.anchor_top = 0.0
			_faction_badge_lbl.anchor_right = 1.0
			_faction_badge_lbl.anchor_bottom = 0.0
			_faction_badge_lbl.offset_left = 4.0
			_faction_badge_lbl.offset_top = 1.0
			_faction_badge_lbl.offset_right = -28.0
			_faction_badge_lbl.offset_bottom = 17.0
			_faction_badge_lbl.add_theme_font_size_override("font_size", 9)
			_faction_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_faction_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_faction_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			art_ph.add_child(_faction_badge_lbl)

			_spawn_badge_lbl = Label.new()
			_spawn_badge_lbl.name = "SpawnBadge"
			_spawn_badge_lbl.anchor_left = 1.0
			_spawn_badge_lbl.anchor_top = 0.0
			_spawn_badge_lbl.anchor_right = 1.0
			_spawn_badge_lbl.anchor_bottom = 0.0
			_spawn_badge_lbl.offset_left = -34.0
			_spawn_badge_lbl.offset_top = 1.0
			_spawn_badge_lbl.offset_right = -4.0
			_spawn_badge_lbl.offset_bottom = 17.0
			_spawn_badge_lbl.add_theme_font_size_override("font_size", 10)
			_spawn_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_spawn_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_spawn_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			art_ph.add_child(_spawn_badge_lbl)

			_emblem_glyph_lbl = Label.new()
			_emblem_glyph_lbl.name = "EmblemGlyph"
			_emblem_glyph_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			_emblem_glyph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_emblem_glyph_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_emblem_glyph_lbl.add_theme_font_size_override("font_size", 22)
			_emblem_glyph_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_inner_art_frame.add_child(_emblem_glyph_lbl)

	if art_rect:
		art_rect.anchor_left = 0.0
		art_rect.anchor_top = 0.0
		art_rect.anchor_right = 1.0
		art_rect.anchor_bottom = 0.0
		art_rect.offset_left = 11.0
		art_rect.offset_top = 26.0
		art_rect.offset_right = -11.0
		art_rect.offset_bottom = 89.0

	if name_label:
		name_label.anchor_left = 0.0
		name_label.anchor_top = 0.0
		name_label.anchor_right = 1.0
		name_label.anchor_bottom = 0.0
		name_label.offset_left = 6.0
		name_label.offset_top = 93.0
		name_label.offset_right = -6.0
		name_label.offset_bottom = 117.0
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.clip_text = true

	var desc_label = get_node_or_null("DescLabel")
	if desc_label:
		desc_label.anchor_left = 0.0
		desc_label.anchor_top = 0.0
		desc_label.anchor_right = 1.0
		desc_label.anchor_bottom = 0.0
		desc_label.offset_left = 8.0
		desc_label.offset_top = 118.0
		desc_label.offset_right = -8.0
		desc_label.offset_bottom = 188.0
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", Color(0.86, 0.90, 0.95, 0.95))

	if hp_label:
		hp_label.offset_left = 8.0
		hp_label.offset_top = 190.0
		hp_label.offset_right = 82.0
		hp_label.offset_bottom = 214.0
		hp_label.add_theme_font_size_override("font_size", 12)

	if type_label:
		type_label.offset_left = 82.0
		type_label.offset_top = 190.0
		type_label.offset_right = 142.0
		type_label.offset_bottom = 214.0
		type_label.add_theme_font_size_override("font_size", 12)

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

func _get_card_faction_style(c_name: String) -> Dictionary:
	if "Wildlife" in c_name:
		return {
			"tag": "WILDLIFE",
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
			"tag": "PLAGUE",
			"bg": Color(0.18, 0.15, 0.05, 1.0),
			"art": Color(0.36, 0.28, 0.06, 1.0),
			"border": Color(1.0, 0.85, 0.18, 1.0),
			"glyph": "[ EYE ]",
			"text": Color(1.0, 0.92, 0.45, 1.0)
		}
	elif "Gilded" in c_name:
		return {
			"tag": "GILDED",
			"bg": Color(0.05, 0.18, 0.12, 1.0),
			"art": Color(0.08, 0.32, 0.20, 1.0),
			"border": Color(0.55, 0.92, 1.0, 1.0),
			"glyph": "< HARMONY >",
			"text": Color(0.75, 0.96, 1.0, 1.0)
		}
	elif "Void" in c_name:
		return {
			"tag": "VOID SWARM",
			"bg": Color(0.14, 0.06, 0.22, 1.0),
			"art": Color(0.28, 0.08, 0.42, 1.0),
			"border": Color(0.85, 0.25, 0.98, 1.0),
			"glyph": "{ VOID }",
			"text": Color(0.95, 0.65, 1.0, 1.0)
		}
	elif "Rimworlder" in c_name or "Sky" in c_name or "Stone" in c_name or "Giant" in c_name or "Great" in c_name or "Beast" in c_name:
		return {
			"tag": "RIMWORLD",
			"bg": Color(0.08, 0.19, 0.09, 1.0),
			"art": Color(0.14, 0.34, 0.16, 1.0),
			"border": Color(0.30, 0.90, 0.45, 1.0),
			"glyph": "/ BEAST \\",
			"text": Color(0.65, 1.0, 0.72, 1.0)
		}
	elif "Scrap" in c_name:
		return {
			"tag": "PIRATES",
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
	cost_label.text = str(data.cost)
	if "Wildlife" in str(data.card_name):
		var w_info = WildlifeModelBuilder.get_species_info(str(data.card_name))
		name_label.text = str(w_info.get("title", data.card_name))
	else:
		name_label.text = data.card_name

	var style = _get_card_faction_style(str(data.card_name))
	_base_bg_color = style["bg"]
	_base_border_color = style["border"]

	var art_ph = get_node_or_null("ArtPlaceholder")
	if art_ph:
		art_ph.color = style["art"]
	if _faction_badge_lbl:
		_faction_badge_lbl.text = style["tag"]
		_faction_badge_lbl.add_theme_color_override("font_color", style["text"])
	if _spawn_badge_lbl:
		var sp_cnt: int = int(data.spawn_count) if "spawn_count" in data else 1
		if data.is_spell:
			_spawn_badge_lbl.text = "AOE"
		elif "card_type" in data and data.card_type == "Commander":
			_spawn_badge_lbl.text = "HERO"
		else:
			_spawn_badge_lbl.text = "x" + str(maxi(1, sp_cnt))
		_spawn_badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))

	var role_icon = style["glyph"]
	if data.is_spell:
		role_icon = "[ ORBITAL ]"
	elif "card_type" in data and data.card_type == "Commander":
		role_icon = "<< CMDR >>"
	elif "card_type" in data and data.card_type == "Vehicle":
		role_icon = "[ ARMOR ]"
	elif "Flyer" in data.card_name or "Plane" in data.card_name or "Beetle" in data.card_name or "Jellyfish" in data.card_name:
		role_icon = "^ AIR ^"
	elif "Infector" in data.card_name:
		role_icon = "~ BEAM ~"
	if _emblem_glyph_lbl:
		_emblem_glyph_lbl.text = role_icon
		_emblem_glyph_lbl.add_theme_color_override("font_color", style["border"])

	if art_rect:
		art_rect.visible = false

	name_label.add_theme_color_override("font_color", style["text"])

	var desc_label = get_node_or_null("DescLabel")
	if desc_label:
		var d_txt: String = str(data.description).strip_edges() if "description" in data else ""
		if d_txt == "" or d_txt == "Description here...":
			d_txt = _get_card_fallback_description(data)
		desc_label.text = d_txt

	if "max_hp" in data:
		hp_label.text = "HP " + str(data.max_hp)
		hp_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55))

	if "is_melee" in data:
		type_label.text = "Melee" if data.is_melee else "Ranged"
		type_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42) if data.is_melee else Color(0.55, 0.88, 1.0))

	if data.is_spell:
		_base_bg_color = Color(0.32, 0.08, 0.10, 1.0)
		_base_border_color = Color(1.0, 0.35, 0.25, 1.0)
		hp_label.text = "STRIKE"
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35))
		type_label.text = "Spell"
		type_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	elif "card_type" in data and data.card_type == "Commander":
		_base_border_color = Color(1.0, 0.84, 0.22, 1.0)
		type_label.text = "Cmdr"
		type_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
	elif "card_type" in data and data.card_type == "Vehicle":
		type_label.text = "Armor"
		type_label.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))

	_refresh_visual_state()

func _get_card_fallback_description(data: Resource) -> String:
	var cname: String = str(data.card_name).replace(" ", "")
	var fallback_map := {
		"Assassin": "Stealth flanker with twin blades. Eliminates backline targets rapidly.",
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



extends Control

@onready var bg = $Background
@onready var title_label = $Title
@onready var trim_top = $GoldTrimTop
@onready var trim_bot = $GoldTrimBottom
var all_cards = []
var deck_commander = null
var deck_units = []

@onready var main_body = $MainBody
var card_ui_scene = preload("res://Scenes/CardUI.tscn")

var left_grid: GridContainer
var right_commander_slot: CenterContainer
var right_deck_grid: GridContainer
var count_label: Label
var profile_dropdown: OptionButton
var current_tab: int = 0
var faction_doctrine_lbl: Label = null

func _ready():
	load_all_cards()
	build_ui()
	load_profile(GameState.editing_profile)

func load_all_cards():
	var dir = DirAccess.open("res://Data/Cards")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
				var clean_name = file_name.trim_suffix(".remap")
				var res = load("res://Data/Cards/" + clean_name)
				if res is CardData:
					all_cards.append(res)
			file_name = dir.get_next()

func build_ui():
	# Top Bar for Profile Selection
	var top_bar = HBoxContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 40)
	top_bar.offset_left = 150.0
	top_bar.offset_top = 36.0
	var label = Label.new()
	label.text = "Commander Profile: "
	label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.65))
	top_bar.add_child(label)
	
	profile_dropdown = OptionButton.new()
	profile_dropdown.add_item("Player1")
	profile_dropdown.add_item("Guest1")
	profile_dropdown.add_item("Guest2")
	profile_dropdown.add_item("Guest3")
	profile_dropdown.add_item("Guest4")
	profile_dropdown.add_item("Guest5")
	
	# Select correct dropdown item based on GameState
	for i in range(profile_dropdown.item_count):
		if profile_dropdown.get_item_text(i) == GameState.editing_profile:
			profile_dropdown.select(i)
			break
			
	profile_dropdown.connect("item_selected", Callable(self, "_on_profile_selected"))
	top_bar.add_child(profile_dropdown)
	
	# Insert top bar at the very top of the scene (before MainBody if possible, or inside it)
	add_child(top_bar)
	move_child(top_bar, 0)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.08, 0.13, 0.86)
	panel_style.border_color = Color(0.85, 0.72, 0.25, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 14
	panel_style.content_margin_right = 14
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12

	var left_panel = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_stylebox_override("panel", panel_style)
	main_body.add_child(left_panel)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 10)
	left_panel.add_child(left_vbox)
	
	var tab_bar = TabBar.new()
	tab_bar.add_tab("Dominion of Sol")
	tab_bar.add_tab("The Void Swarm")
	tab_bar.add_tab("The Rimworlders")
	tab_bar.add_tab("Pirate Kingdoms")
	tab_bar.add_tab("The Reach")
	tab_bar.add_tab("Plague of Harmony")
	tab_bar.add_tab("Gilded Harmony")
	tab_bar.add_tab("Planetary Primitives")
	tab_bar.add_tab("Galactic Wildlife")
	tab_bar.add_tab("Chaos (All Factions)")
	tab_bar.connect("tab_changed", Callable(self, "_on_tab_changed"))
	left_vbox.add_child(tab_bar)

	faction_doctrine_lbl = Label.new()
	faction_doctrine_lbl.name = "FactionDoctrineLabel"
	faction_doctrine_lbl.add_theme_font_size_override("font_size", 13)
	faction_doctrine_lbl.add_theme_color_override("font_color", Color(0.78, 0.92, 1.0))
	faction_doctrine_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_vbox.add_child(faction_doctrine_lbl)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(scroll)
	
	left_grid = GridContainer.new()
	left_grid.columns = 4
	left_grid.add_theme_constant_override("h_separation", 14)
	left_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(left_grid)
	
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(360, 0)
	right_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	main_body.add_child(right_panel)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 8)
	right_panel.add_child(right_vbox)
	
	var deck_title = Label.new()
	deck_title.text = "ACTIVE BATTLE DECK (1 CMDR + 5 UNITS)"
	deck_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_title.add_theme_font_size_override("font_size", 16)
	deck_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	right_vbox.add_child(deck_title)
	
	var cmdr_label = Label.new()
	cmdr_label.text = "Commander Slot (1/1)"
	cmdr_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	right_vbox.add_child(cmdr_label)
	
	right_commander_slot = CenterContainer.new()
	right_commander_slot.custom_minimum_size = Vector2(0, 224)
	right_vbox.add_child(right_commander_slot)
	
	count_label = Label.new()
	count_label.text = "Units & Spells (0/5)"
	right_vbox.add_child(count_label)
	
	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(right_scroll)
	
	right_deck_grid = GridContainer.new()
	right_deck_grid.columns = 2
	right_deck_grid.add_theme_constant_override("h_separation", 12)
	right_deck_grid.add_theme_constant_override("v_separation", 12)
	right_deck_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right_deck_grid)
	
	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	right_vbox.add_child(action_row)

	var autofill_btn = Button.new()
	autofill_btn.name = "AutoFillBtn"
	autofill_btn.text = "Auto-Fill Faction"
	autofill_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	autofill_btn.custom_minimum_size = Vector2(0, 36)
	autofill_btn.connect("pressed", Callable(self, "_on_autofill_pressed"))
	action_row.add_child(autofill_btn)

	var clear_btn = Button.new()
	clear_btn.name = "ClearDeckBtn"
	clear_btn.text = "Clear Deck"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.custom_minimum_size = Vector2(0, 36)
	clear_btn.connect("pressed", Callable(self, "_on_clear_deck_pressed"))
	action_row.add_child(clear_btn)

	var save_btn = Button.new()
	save_btn.name = "SaveDeckBtn"
	save_btn.text = "Save & Return to Hub"
	save_btn.custom_minimum_size = Vector2(0, 48)
	save_btn.add_theme_font_size_override("font_size", 18)
	var save_st = StyleBoxFlat.new()
	save_st.bg_color = Color(0.14, 0.36, 0.20, 0.95)
	save_st.border_color = Color(0.40, 0.95, 0.55, 1.0)
	save_st.set_border_width_all(2)
	save_st.set_corner_radius_all(6)
	save_btn.add_theme_stylebox_override("normal", save_st)
	save_btn.connect("pressed", Callable(self, "_on_back_pressed"))
	right_vbox.add_child(save_btn)

	var cancel_btn = Button.new()
	cancel_btn.name = "CancelDeckBtn"
	cancel_btn.text = "Discard Changes & Back (Esc)"
	cancel_btn.custom_minimum_size = Vector2(0, 34)
	cancel_btn.add_theme_font_size_override("font_size", 13)
	cancel_btn.connect("pressed", Callable(self, "_on_cancel_pressed"))
	right_vbox.add_child(cancel_btn)

func _on_autofill_pressed():
	for c in left_grid.get_children():
		if not ("card_data" in c) or c.card_data == null:
			continue
		var data = c.card_data
		if data.card_type == "Commander" and deck_commander == null:
			deck_commander = data
		elif data.card_type != "Commander" and deck_units.size() < 5 and not deck_units.has(data):
			deck_units.append(data)
	refresh_ui()

func _on_clear_deck_pressed():
	deck_commander = null
	deck_units.clear()
	refresh_ui()

func _on_profile_selected(index: int):
	# Save current deck before switching
	_save_current_profile_to_state()
	GameState.editing_profile = profile_dropdown.get_item_text(index)
	load_profile(GameState.editing_profile)

func load_profile(profile_name: String):
	deck_commander = null
	deck_units.clear()
	var saved_deck = GameState.player_decks[profile_name]
	for c_name in saved_deck:
		var res = load("res://Data/Cards/" + c_name + ".tres")
		if res:
			if res.card_type == "Commander":
				deck_commander = res
			else:
				deck_units.append(res)
				
	_on_tab_changed(current_tab) # refresh collection to apply P1 restrictions
	refresh_ui()

func _on_tab_changed(tab_idx: int):
	current_tab = tab_idx
	
	var faction_names = [
		"Dominion of Sol",
		"The Void Swarm",
		"The Rimworlders",
		"Pirate Kingdoms",
		"The Reach",
		"The Plague of Harmony",
		"Gilded Harmony",
		"Planetary Primitives",
		"Galactic Wildlife",
		"Chaos (Cross-Faction)"
	]
	var faction_doctrines = [
		"Doctrine: Combined Arms & Forward Command Bays (+Deployment Perimeter, Heavy Armor, Orbital Artillery).",
		"Doctrine: Relentless Bio-Swarm & Void Meteors (Low-cost chitin waves, flying Gargoyles, and Stalker flanks).",
		"Doctrine: Primal Stampede & Beast Master Aura (+20% Speed & Attack to nearby Beast & Mutant units).",
		"Doctrine: Salvage Blitz & Volatile Armor (Scrap Tanks detonate on death; Scrap Repair salvages armor).",
		"Doctrine: Cybernetic Network Synergy (+15% Speed, Attack & Scale per nearby friendly Reach unit, up to +75%).",
		"Doctrine: Golden Eye Conversion (Enlightened Husks & Eye Creatures screen while Infectors convert enemies in 4s).",
		"Doctrine: Mitosis & The Saved Horde (Genetic Monsters regenerate, divide at full HP, and split twice on death).",
		"Doctrine: Ages of Humanity (Stone Age swarm & crafters building forward watchtowers; Feudal knights, crossbowmen & siege ballistas; low cost, high numbers).",
		"Doctrine: Untamed Biosphere (108 Earth & Galactic fauna species! Venomous snakes, rock-dropping corvids, pecking birds, bug swarms, sharks, apes & megafauna).",
		"Doctrine: Chaos Unleashed (Mix and match commanders and units freely across all factions in the galaxy)."
	]
	if tab_idx >= 0 and tab_idx < faction_names.size():
		if title_label: title_label.text = faction_names[tab_idx] + " - Army Gathering"
		if faction_doctrine_lbl: faction_doctrine_lbl.text = faction_doctrines[tab_idx]
	
	if bg and trim_top and trim_bot:
		if tab_idx == 0: # Dominion
			bg.color = Color(0.05, 0.2, 0.4)
			trim_top.color = Color(0.8, 0.7, 0.2)
			trim_bot.color = Color(0.8, 0.7, 0.2)
		elif tab_idx == 1: # Void
			bg.color = Color(0.15, 0.0, 0.3)
			trim_top.color = Color(0.8, 0.1, 0.9)
			trim_bot.color = Color(0.8, 0.1, 0.9)
		elif tab_idx == 2: # Rimworlders
			bg.color = Color(0.1, 0.3, 0.1)
			trim_top.color = Color(0.2, 0.9, 0.4)
			trim_bot.color = Color(0.2, 0.9, 0.4)
		elif tab_idx == 3: # Pirates
			bg.color = Color(0.3, 0.15, 0.05)
			trim_top.color = Color(0.9, 0.4, 0.1)
			trim_bot.color = Color(0.9, 0.4, 0.1)
		elif tab_idx == 4: # Reach
			bg.color = Color(0.05, 0.15, 0.2)
			trim_top.color = Color(0.1, 0.8, 0.9)
			trim_bot.color = Color(0.1, 0.8, 0.9)
		elif tab_idx == 5: # Plague of Harmony
			bg.color = Color(0.28, 0.22, 0.04)
			trim_top.color = Color(1.0, 0.86, 0.18)
			trim_bot.color = Color(1.0, 0.86, 0.18)
		elif tab_idx == 6: # Gilded Harmony
			bg.color = Color(0.04, 0.24, 0.14)
			trim_top.color = Color(0.56, 0.88, 1.0)
			trim_bot.color = Color(1.0, 0.84, 0.20)
		elif tab_idx == 7: # Planetary Primitives
			bg.color = Color(0.24, 0.16, 0.10)
			trim_top.color = Color(0.88, 0.72, 0.45)
			trim_bot.color = Color(0.75, 0.55, 0.30)
		elif tab_idx == 8: # Galactic Wildlife
			bg.color = Color(0.06, 0.26, 0.12)
			trim_top.color = Color(0.35, 0.95, 0.42)
			trim_bot.color = Color(0.85, 0.68, 0.22)
		elif tab_idx == 9: # Chaos (All)
			bg.color = Color(0.16, 0.04, 0.22)
			trim_top.color = Color(0.92, 0.78, 0.22)
			trim_bot.color = Color(0.25, 0.88, 0.95)
			
	for c in left_grid.get_children():
		left_grid.remove_child(c)
		c.queue_free()
		
	# Determine if we need to restrict cards based on P1
	var restricted_card_names = []
	if GameState.editing_profile != "Player1":
		restricted_card_names = GameState.player_decks["Player1"]

	for card_data in all_cards:
		var is_wildlife = "Wildlife" in card_data.card_name
		var is_void = not is_wildlife and ("Void" in card_data.card_name)
		var is_rimworlder = not is_wildlife and ("Rimworlder" in card_data.card_name or "Sky" in card_data.card_name or "Stone" in card_data.card_name or "Giant" in card_data.card_name or "Great" in card_data.card_name or "Monstrous" in card_data.card_name)
		var is_pirate = not is_wildlife and ("Scrap" in card_data.card_name)
		var is_reach = not is_wildlife and ("Reach" in card_data.card_name)
		var is_plague = not is_wildlife and ("Plague" in card_data.card_name)
		var is_gilded = not is_wildlife and ("Gilded" in card_data.card_name)
		var is_primitive = not is_wildlife and ("Primitive" in card_data.card_name)
		var is_dominion = not is_void and not is_rimworlder and not is_pirate and not is_reach and not is_plague and not is_gilded and not is_primitive and not is_wildlife
		
		var is_valid = (tab_idx == 9) or (tab_idx == 0 and is_dominion) or (tab_idx == 1 and is_void) or (tab_idx == 2 and is_rimworlder) or (tab_idx == 3 and is_pirate) or (tab_idx == 4 and is_reach) or (tab_idx == 5 and is_plague) or (tab_idx == 6 and is_gilded) or (tab_idx == 7 and is_primitive) or (tab_idx == 8 and is_wildlife)
		if is_valid:

			# If this is a Guest profile, block cards that Player1 is using
			var raw_name = _get_card_file_key(card_data)
			if restricted_card_names.has(raw_name):
				continue # Skip adding this card to the Guest's collection grid!
				
			var c = card_ui_scene.instantiate()
			c.card_data = card_data
			c.connect("card_clicked", Callable(self, "_on_collection_card_clicked"))
			left_grid.add_child(c)
	refresh_ui()

func _get_card_file_key(data: Resource) -> String:
	if data and data.resource_path != "":
		return data.resource_path.get_file().trim_suffix(".remap").trim_suffix(".tres")
	return data.card_name.replace(" ", "") + "Card"

func _on_collection_card_clicked(card_ui):
	var data = card_ui.card_data
	if data.card_type == "Commander":
		if deck_commander == data:
			deck_commander = null
		else:
			deck_commander = data
	else:
		if deck_units.has(data):
			deck_units.erase(data)
		elif deck_units.size() < 5:
			deck_units.append(data)
	refresh_ui()

func _on_deck_card_clicked(card_ui):
	var data = card_ui.card_data
	if data.card_type == "Commander":
		deck_commander = null
	else:
		deck_units.erase(data)
	refresh_ui()

func refresh_ui():
	for c in right_commander_slot.get_children():
		right_commander_slot.remove_child(c)
		c.queue_free()
	for c in right_deck_grid.get_children():
		right_deck_grid.remove_child(c)
		c.queue_free()
		
	if deck_commander:
		var c = card_ui_scene.instantiate()
		c.card_data = deck_commander
		c.connect("card_clicked", Callable(self, "_on_deck_card_clicked"))
		right_commander_slot.add_child(c)
		
	for u in deck_units:
		var c = card_ui_scene.instantiate()
		c.card_data = u
		c.connect("card_clicked", Callable(self, "_on_deck_card_clicked"))
		right_deck_grid.add_child(c)

	for col_card in left_grid.get_children():
		if "card_data" in col_card and col_card.has_method("set_selected"):
			var in_deck: bool = (col_card.card_data == deck_commander) or deck_units.has(col_card.card_data)
			col_card.is_selected = in_deck
			col_card._refresh_visual_state()
		
	if deck_commander != null and deck_units.size() == 5:
		count_label.text = "Army Complete: 1 Cmdr + 5 Units (Ready!)"
		count_label.add_theme_color_override("font_color", Color(0.25, 0.95, 0.4))
	else:
		var cmdr_txt = "1/1 Cmdr" if deck_commander != null else "0/1 Cmdr"
		count_label.text = "Units & Spells (" + str(deck_units.size()) + "/5) | " + cmdr_txt
		count_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))


func _save_current_profile_to_state():
	var new_deck = []
	if deck_commander:
		new_deck.append(_get_card_file_key(deck_commander))
	for u in deck_units:
		new_deck.append(_get_card_file_key(u))
	GameState.player_decks[GameState.editing_profile] = new_deck
	GameState.save_decks()

func _on_back_pressed():
	if deck_commander == null or deck_units.size() < 5:
		var err_msg = "Cannot save! "
		if deck_commander == null and deck_units.size() < 5:
			err_msg += "Need 1 Commander and " + str(5 - deck_units.size()) + " more Units."
		elif deck_commander == null:
			err_msg += "Need to select 1 Commander."
		else:
			err_msg += "Need " + str(5 - deck_units.size()) + " more Units."
		print(err_msg)
		count_label.text = err_msg
		count_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
		return
		
	_save_current_profile_to_state()
	
	if GameState.current_mode == "ONLINE_HOST" or GameState.current_mode == "ONLINE_JOIN":
		get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _on_cancel_pressed():
	GameState.load_decks() # Discard uncommitted changes
	if GameState.current_mode == "ONLINE_HOST" or GameState.current_mode == "ONLINE_JOIN":
		get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()

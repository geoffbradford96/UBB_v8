extends Node
class_name HealthComponent

const HarmonyHuskBuilderScript = preload("res://Scripts/HarmonyHuskBuilder.gd")

var poison_ticks: int = 0
var poison_dps: float = 0.0
var poison_timer: float = 0.0
var scrap_heal_time: float = 0.0

func apply_poison(ticks: int, dps: float):
	var parent = get_parent()
	if parent and parent.get("unit_attribute") == "Golem":
		return # Immune to poison attrition!
	poison_ticks = ticks
	poison_dps = dps
	poison_timer = 1.0


signal died
signal health_changed(new_health, max_health)
signal shield_changed(current_shield, max_shield)
signal shield_broken
signal shield_recharged
signal armor_changed(current_armor, max_armor)
signal armor_broken

@export var max_health: float = 100.0:
	set(v):
		max_health = v
		if current_health == 100.0 or current_health <= 0.0:
			current_health = v
var current_health: float = 100.0
var is_dead: bool = false

# --- Shield System ---
@export var max_shield: float = 0.0:
	set(v):
		max_shield = v
		if current_shield <= 0.0 or current_shield > max_shield:
			current_shield = v
var current_shield: float = 0.0
@export var shield_type: String = "NONE" # "NONE", "360", "FRONT"
@export var shield_arc_deg: float = 150.0
@export var shield_recharge_rate: float = 0.0
@export var shield_recharge_delay: float = 4.5
@export var shield_color: Color = Color(0.2, 0.75, 1.0, 0.45)
var shield_recharge_timer: float = 0.0
var shield_mesh_root: Node3D = null
var shield_ring_node: Node3D = null
var shield_bar: ProgressBar = null

# --- Breakable Armor System ---
@export var max_armor: float = 0.0:
	set(v):
		max_armor = v
		if current_armor <= 0.0 or current_armor > max_armor:
			current_armor = v
var current_armor: float = 0.0
@export var armor_damage_reduction: float = 0.25
@export var armor_style: String = "NONE" # "NONE", "SCRAP", "CHITIN", "STONE", "BONE", "REACTIVE", "GOLD"
@export var armor_color: Color = Color(0.7, 0.65, 0.55, 1.0)
var armor_plates_root: Node3D = null
var is_armor_broken: bool = false
var armor_bar: ProgressBar = null
var bar_vbox: VBoxContainer = null



var hp_bar: ProgressBar
var hp_viewport: SubViewport = null
var hp_sprite: Sprite3D = null
var ground_marker: MeshInstance3D = null

# Vehicle / Mechanical Damage Smoke & Spark Emitters
var vehicle_smoke_emitter: Node3D = null
var vehicle_smoke_particles: CPUParticles3D = null
var vehicle_spark_particles: CPUParticles3D = null

func is_critically_wounded() -> bool:
	return (current_health / max(0.001, max_health)) <= 0.35

func is_vehicle_damaged() -> bool:
	return (current_health / max(0.001, max_health)) <= 0.40

func is_mechanical_entity(p: Node) -> bool:
	if not p: return false
	if p.get("unit_attribute") == "Mechanical": return true
	var p_name = p.name
	for keyword in ["Tank", "Mech", "Plane", "Walker", "Tower", "Base", "CommandBay", "Spiker"]:
		if keyword in p_name: return true
	return false

func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var root = (loop as SceneTree).root
		if root and root.has_node("GameState"):
			return root.get_node("GameState")
	return null



func _ready():
	get_parent().add_to_group("Targetable")
	current_health = max_health
	if max_shield > 0.0 and current_shield <= 0.0:
		current_shield = max_shield
	if max_armor > 0.0 and current_armor <= 0.0:
		current_armor = max_armor
	
	# Create Health Bar UI dynamically
	hp_viewport = SubViewport.new()
	hp_viewport.transparent_bg = true
	var v_height = 36 if (max_shield > 0.0 or max_armor > 0.0) else 30
	if "Base" in get_parent().name:
		hp_viewport.size = Vector2i(400, 40)
	else:
		hp_viewport.size = Vector2i(200, v_height)
	hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	bar_vbox = VBoxContainer.new()
	bar_vbox.name = "BarContainer"
	bar_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_vbox.add_theme_constant_override("separation", 2)
	hp_viewport.add_child(bar_vbox)
	
	if max_shield > 0.0:
		shield_bar = ProgressBar.new()
		shield_bar.name = "ShieldBar"
		shield_bar.min_value = 0
		shield_bar.max_value = max_shield
		shield_bar.value = current_shield
		shield_bar.custom_minimum_size = Vector2(0, 5)
		shield_bar.show_percentage = false
		var s_bg = StyleBoxFlat.new()
		s_bg.bg_color = Color(0.04, 0.08, 0.14, 0.9)
		var s_fg = StyleBoxFlat.new()
		s_fg.bg_color = shield_color
		s_fg.corner_radius_top_left = 2; s_fg.corner_radius_top_right = 2
		s_fg.corner_radius_bottom_left = 2; s_fg.corner_radius_bottom_right = 2
		shield_bar.add_theme_stylebox_override("background", s_bg)
		shield_bar.add_theme_stylebox_override("fill", s_fg)
		bar_vbox.add_child(shield_bar)
		
	if max_armor > 0.0:
		armor_bar = ProgressBar.new()
		armor_bar.name = "ArmorBar"
		armor_bar.min_value = 0
		armor_bar.max_value = max_armor
		armor_bar.value = current_armor
		armor_bar.custom_minimum_size = Vector2(0, 5)
		armor_bar.show_percentage = false
		var a_bg = StyleBoxFlat.new()
		a_bg.bg_color = Color(0.1, 0.08, 0.04, 0.9)
		var a_fg = StyleBoxFlat.new()
		a_fg.bg_color = Color(0.85, 0.65, 0.25) if (armor_style == "SCRAP" or armor_style == "REACTIVE") else (Color(0.85, 0.8, 0.7) if armor_style == "BONE" else Color(0.55, 0.58, 0.52))
		a_fg.corner_radius_top_left = 2; a_fg.corner_radius_top_right = 2
		a_fg.corner_radius_bottom_left = 2; a_fg.corner_radius_bottom_right = 2
		armor_bar.add_theme_stylebox_override("background", a_bg)
		armor_bar.add_theme_stylebox_override("fill", a_fg)
		bar_vbox.add_child(armor_bar)
	
	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = max_health
	hp_bar.value = current_health
	hp_bar.custom_minimum_size = Vector2(0, 16 if (max_shield > 0.0 or max_armor > 0.0) else 24)
	hp_bar.show_percentage = false
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.18, 0.85, 0.22)
	hp_bar.add_theme_stylebox_override("background", style_bg)
	hp_bar.add_theme_stylebox_override("fill", style_fg)
	
	bar_vbox.add_child(hp_bar)
	
	hp_sprite = Sprite3D.new()
	hp_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_sprite.texture = hp_viewport.get_texture()
	
	if "Base" in get_parent().name:
		hp_sprite.position = Vector3(0, 6.0, 0)
	elif "Tower" in get_parent().name:
		hp_sprite.position = Vector3(0, 7.5, 0)
	else:
		hp_sprite.position = Vector3(0, 3.0, 0)
		
	get_parent().call_deferred("add_child", hp_viewport)
	get_parent().call_deferred("add_child", hp_sprite)
	call_deferred("update_health_bar_colors")
	call_deferred("_setup_ground_marker")
	call_deferred("_setup_shield_and_armor_visuals")

func _setup_ground_marker():
	var parent = get_parent()
	if not parent or not is_instance_valid(parent): return
	if ground_marker != null and is_instance_valid(ground_marker): return
	
	ground_marker = MeshInstance3D.new()
	ground_marker.name = "UnitGroundMarker"
	
	var torus = TorusMesh.new()
	var r_outer = 1.15
	var r_inner = 0.92
	
	if "Base" in parent.name:
		r_outer = 6.2; r_inner = 5.4
	elif "Tower" in parent.name or "CommandBay" in parent.name or "Nest" in parent.name or "Hill" in parent.name:
		r_outer = 3.6; r_inner = 3.0
	elif "Tank" in parent.name or "Commander" in parent.name or "Overlord" in parent.name or "GreatBeastSpeaker" in parent.name:
		r_outer = 1.95; r_inner = 1.6
	elif "SwarmAnt" in parent.name or "Voidling" in parent.name:
		r_outer = 0.55; r_inner = 0.38
	elif "Beast" in parent.name:
		r_outer = 2.4; r_inner = 1.85
		
	torus.outer_radius = r_outer
	torus.inner_radius = r_inner
	ground_marker.mesh = torus
	ground_marker.position = Vector3(0, 0.04, 0)
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ground_marker.material_override = mat
	
	parent.add_child(ground_marker)
	update_ground_marker_color()

func update_ground_marker_color():
	if not ground_marker or not is_instance_valid(ground_marker): return
	var parent = get_parent()
	if not parent or not is_instance_valid(parent): return
	var gs = _get_game_state()
	
	var c = Color(0.65, 0.65, 0.65) # Neutral gray by default
	if parent.is_in_group("SideHarmony"):
		c = Color(1.0, 0.84, 0.16) # Wild Harmony Gold!
	elif parent.is_in_group("Beast") or parent.is_in_group("BeastHazard"):
		c = Color(0.72, 0.18, 0.95) # End Game Purple!
	elif parent.is_in_group("NeutralCreature") or parent.is_in_group("NeutralStructure") or "Scorpion" in parent.name or "Ant" in parent.name:
		c = Color(0.65, 0.65, 0.65) # Neutral Gray!
	else:
		var matched_side = ""
		for g in parent.get_groups():
			if g.begins_with("Side") and g != "SideHarmony":
				matched_side = g
				break
		if matched_side != "":
			if gs and gs.has_method("get_team_color"):
				c = gs.get_team_color(matched_side)
			elif matched_side == "SideA":
				c = Color(0.2, 0.65, 1.0)
			elif matched_side == "SideB":
				c = Color(0.95, 0.22, 0.22)
			else:
				c = Color(0.2, 0.85, 0.4)
		elif parent.is_in_group("Harmony") or parent.is_in_group("HuskOfHarmony") or parent.is_in_group("BeastOfHarmony") or parent.has_meta("is_husk_of_harmony"):
			c = Color(1.0, 0.84, 0.16) # Harmony Gold fallback
		
	c.a = 0.85
	var mat = ground_marker.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = c
	var vision_on = gs.player_vision_enabled if (gs and "player_vision_enabled" in gs) else true
	ground_marker.visible = vision_on and not is_dead

func set_ground_marker_visible(v: bool):
	if ground_marker and is_instance_valid(ground_marker):
		ground_marker.visible = v and not is_dead

func update_health_bar_colors():
	if not hp_bar: return
	var parent = get_parent()
	if not parent or not is_instance_valid(parent): return
	
	var my_team = ""
	for g in parent.get_groups():
		if g.begins_with("Side") or g == "Beast":
			my_team = g
			break
			
	var gs = _get_game_state()
	var local_team = gs.local_player_team if (gs and "local_player_team" in gs and gs.local_player_team != "") else "SideA"

	
	var is_neutral = parent.is_in_group("NeutralCreature") or parent.is_in_group("NeutralStructure")
	var is_ally = (my_team != "" and my_team == local_team)
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.08, 0.08, 0.08, 0.95) # Black background
	style_bg.set_border_width_all(1)
	style_bg.border_color = Color(0.16, 0.16, 0.16, 0.8)
	style_bg.corner_radius_top_left = 2; style_bg.corner_radius_top_right = 2
	style_bg.corner_radius_bottom_left = 2; style_bg.corner_radius_bottom_right = 2
	
	var style_fg = StyleBoxFlat.new()
	if is_neutral:
		style_fg.bg_color = Color(0.95, 0.68, 0.15) # Neutral gold/amber
	elif local_team == "Spectator":
		if my_team == "SideHarmony" or parent.is_in_group("Harmony"):
			style_fg.bg_color = Color(1.0, 0.84, 0.16) # Harmony Gold
		elif my_team == "Beast":
			style_fg.bg_color = Color(0.72, 0.18, 0.95) # End Game Purple
		elif my_team.begins_with("Side") and gs and gs.has_method("get_team_color"):
			style_fg.bg_color = gs.get_team_color(my_team)
		elif my_team == "SideA":
			style_fg.bg_color = Color(0.2, 0.65, 1.0) # Side A Blue
		elif my_team == "SideB":
			style_fg.bg_color = Color(0.95, 0.22, 0.22) # Side B Red
		else:
			style_fg.bg_color = Color(0.2, 0.85, 0.4)
	elif is_ally:
		style_fg.bg_color = Color(0.18, 0.85, 0.22) # Ally green
	else:
		if my_team == "SideHarmony" or parent.is_in_group("Harmony"):
			style_fg.bg_color = Color(1.0, 0.84, 0.16) # Harmony Gold
		elif my_team.begins_with("Side") and gs and "active_match_teams" in gs and gs.active_match_teams.size() > 2 and gs.has_method("get_team_color"):
			style_fg.bg_color = gs.get_team_color(my_team)
		else:
			style_fg.bg_color = Color(0.92, 0.18, 0.18) # Enemy red
	style_fg.corner_radius_top_left = 2; style_fg.corner_radius_top_right = 2
	style_fg.corner_radius_bottom_left = 2; style_fg.corner_radius_bottom_right = 2
		
	hp_bar.add_theme_stylebox_override("background", style_bg)
	hp_bar.add_theme_stylebox_override("fill", style_fg)
	if hp_viewport:
		hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	update_ground_marker_color()

func _ensure_bars_created():
	if not bar_vbox or not is_instance_valid(bar_vbox): return
	if max_shield > 0.0 and shield_bar == null:
		shield_bar = ProgressBar.new()
		shield_bar.name = "ShieldBar"
		shield_bar.min_value = 0
		shield_bar.max_value = max_shield
		shield_bar.value = current_shield
		shield_bar.custom_minimum_size = Vector2(0, 5)
		shield_bar.show_percentage = false
		var s_bg = StyleBoxFlat.new()
		s_bg.bg_color = Color(0.04, 0.08, 0.14, 0.9)
		var s_fg = StyleBoxFlat.new()
		s_fg.bg_color = shield_color
		s_fg.corner_radius_top_left = 2; s_fg.corner_radius_top_right = 2
		s_fg.corner_radius_bottom_left = 2; s_fg.corner_radius_bottom_right = 2
		shield_bar.add_theme_stylebox_override("background", s_bg)
		shield_bar.add_theme_stylebox_override("fill", s_fg)
		bar_vbox.add_child(shield_bar)
		bar_vbox.move_child(shield_bar, 0)
		if hp_viewport: hp_viewport.size = Vector2i(hp_viewport.size.x, 36)
	if max_armor > 0.0 and armor_bar == null:
		armor_bar = ProgressBar.new()
		armor_bar.name = "ArmorBar"
		armor_bar.min_value = 0
		armor_bar.max_value = max_armor
		armor_bar.value = current_armor
		armor_bar.custom_minimum_size = Vector2(0, 5)
		armor_bar.show_percentage = false
		var a_bg = StyleBoxFlat.new()
		a_bg.bg_color = Color(0.1, 0.08, 0.04, 0.9)
		var a_fg = StyleBoxFlat.new()
		a_fg.bg_color = Color(0.85, 0.65, 0.25) if (armor_style == "SCRAP" or armor_style == "REACTIVE") else (Color(0.85, 0.8, 0.7) if armor_style == "BONE" else Color(0.55, 0.58, 0.52))
		a_fg.corner_radius_top_left = 2; a_fg.corner_radius_top_right = 2
		a_fg.corner_radius_bottom_left = 2; a_fg.corner_radius_bottom_right = 2
		armor_bar.add_theme_stylebox_override("background", a_bg)
		armor_bar.add_theme_stylebox_override("fill", a_fg)
		bar_vbox.add_child(armor_bar)
		var target_idx = 1 if shield_bar else 0
		bar_vbox.move_child(armor_bar, target_idx)
		if hp_viewport: hp_viewport.size = Vector2i(hp_viewport.size.x, 36)

func _refresh_hp_visuals():
	_ensure_bars_created()
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
		update_health_bar_colors()
	if shield_bar and max_shield > 0.0:
		shield_bar.max_value = max_shield
		shield_bar.value = current_shield
	if armor_bar and max_armor > 0.0:
		armor_bar.max_value = max_armor
		armor_bar.value = current_armor
	if hp_viewport:
		hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func take_damage(amount: float, source_pos: Vector3 = Vector3.INF):
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			return # Only Server handles damage logic
		rpc("sync_take_damage", amount, source_pos)
	else:
		sync_take_damage(amount, source_pos)

@rpc("authority", "call_local", "reliable")
func sync_take_damage(amount: float, source_pos: Vector3 = Vector3.INF):
	if is_dead: return
	
	shield_recharge_timer = 0.0
	var remaining_damage = amount
	
	# 1. SHIELD ABSORPTION
	if current_shield > 0.0:
		var blocks_damage = false
		if shield_type == "360":
			blocks_damage = true
		elif shield_type == "FRONT":
			var p = get_parent()
			if p is Node3D and source_pos != Vector3.INF:
				var fwd = -p.global_transform.basis.z
				fwd.y = 0.0
				var to_src = source_pos - p.global_position
				to_src.y = 0.0
				if fwd.length_squared() > 0.01 and to_src.length_squared() > 0.01:
					var angle = rad_to_deg(fwd.normalized().angle_to(to_src.normalized()))
					if angle <= shield_arc_deg * 0.5:
						blocks_damage = true
			else:
				blocks_damage = true
				
		if blocks_damage:
			if remaining_damage <= current_shield:
				current_shield -= remaining_damage
				remaining_damage = 0.0
				_flash_shield_hit()
			else:
				remaining_damage -= current_shield
				current_shield = 0.0
				_break_shield()
			emit_signal("shield_changed", current_shield, max_shield)
			_refresh_shield_bar()
			
	# 2. BREAKABLE ARMOR ABSORPTION
	if remaining_damage > 0.0 and current_armor > 0.0:
		var dmg_to_armor = remaining_damage * (1.0 - armor_damage_reduction)
		if dmg_to_armor <= current_armor:
			current_armor -= dmg_to_armor
			remaining_damage = 0.0
			_flash_armor_hit()
		else:
			var absorbed = current_armor / max(0.01, (1.0 - armor_damage_reduction))
			remaining_damage -= absorbed
			current_armor = 0.0
			_break_armor()
		emit_signal("armor_changed", current_armor, max_armor)
		_refresh_armor_bar()
		
	# 3. BASE HEALTH DAMAGE
	if remaining_damage > 0.0:
		current_health -= remaining_damage
		if hp_bar:
			hp_bar.value = current_health
		emit_signal("health_changed", current_health, max_health)
		
	if hp_viewport:
		hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		
	if current_health <= 0:
		die()

func take_vacuum_damage(amount: float):
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			return
		rpc("sync_take_vacuum_damage", amount)
	else:
		sync_take_vacuum_damage(amount)

@rpc("authority", "call_local", "reliable")
func sync_take_vacuum_damage(amount: float):
	if is_dead or current_shield > 0.0:
		return
	current_health -= amount
	if hp_bar:
		hp_bar.value = current_health
	emit_signal("health_changed", current_health, max_health)
	if hp_viewport:
		hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	if current_health <= 0:
		die()

func heal(amount: float):
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			return
		rpc("sync_heal", amount)
	else:
		sync_heal(amount)


@rpc("authority", "call_local", "reliable")
func sync_heal(amount: float):
	if is_dead: return
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	if hp_bar:
		hp_bar.value = current_health
		if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	emit_signal("health_changed", current_health, max_health)
	

func die():
	if is_dead: return
	is_dead = true
	if ground_marker and is_instance_valid(ground_marker):
		ground_marker.visible = false
	if vehicle_smoke_emitter and is_instance_valid(vehicle_smoke_emitter):
		if vehicle_smoke_particles: vehicle_smoke_particles.emitting = false
		if vehicle_spark_particles: vehicle_spark_particles.emitting = false
		vehicle_smoke_emitter.visible = false

	# SCRAP TANK EXPLOSION
	if "ScrapTank" in get_parent().name and is_inside_tree() and get_tree():
		var p_node = get_parent()
		var p_pos = p_node.global_position
		var my_team_group = ""
		for g in p_node.get_groups():
			if g.begins_with("Side"):
				my_team_group = g
				break
		for e in get_tree().get_nodes_in_group("Targetable"):
			if e == p_node or not is_instance_valid(e) or (my_team_group != "" and e.is_in_group(my_team_group)):
				continue
			if p_pos.distance_squared_to(e.global_position) < 16.0:
				var hp = e.get_node_or_null("HealthComponent")
				if hp: hp.take_damage(50.0, p_pos)

	# SCRAP HEAL TRIGGER
	var my_t = ""
	for g in get_parent().get_groups():
		if g.begins_with("Side"):
			my_t = g
			break
	if my_t != "" and is_inside_tree() and get_tree():
		var p_node = get_parent()
		var p_pos = p_node.global_position
		for a in get_tree().get_nodes_in_group(my_t):
			if a != p_node and is_instance_valid(a) and "Scrap" in a.name and p_pos.distance_squared_to(a.global_position) < 25.0:
				var hp = a.get_node_or_null("HealthComponent")
				if hp and hp.has_method("trigger_scrap_heal"): hp.trigger_scrap_heal()

	#print(get_parent().name, " was destroyed!")
	emit_signal("died")
	
	if is_inside_tree() and get_tree():
		var am = get_tree().get_first_node_in_group("ArenaManager")
		if am == null:
			var cs = get_tree().current_scene
			if cs and cs.has_method("on_unit_died_biome_event"):
				am = cs
		if am and am.has_method("on_unit_died_biome_event"):
			am.on_unit_died_biome_event(get_parent())
	
	if "Base" in get_parent().name:
		var am = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent().get_parent()
		if am and am.has_method("_end_match"):
			get_parent().remove_from_group("Targetable")
			var my_team = "SideA"
			var gs = _get_game_state()
			if gs and gs.local_player_team != "":
				my_team = gs.local_player_team
			elif am.get("players") and am.players.size() > 0:
				my_team = am.players[0].team
			elif multiplayer.has_multiplayer_peer() and not multiplayer.is_server() and gs and gs.current_mode.begins_with("ONLINE"):
				my_team = "SideB"
			
			# Collect all remaining teams that have at least one Base alive
			var teams_alive = []
			if is_inside_tree() and get_tree():
				for b in get_tree().get_nodes_in_group("Targetable"):
					if "Base" in b.name and b != get_parent() and is_instance_valid(b):
						var bhc = b.get_node_or_null("HealthComponent")
						if bhc and bhc.is_dead:
							continue
						for g in b.get_groups():
							if g.begins_with("Side") and not teams_alive.has(g):
								teams_alive.append(g)

			var is_dom = (gs and gs.has_method("is_domination_mode") and gs.is_domination_mode()) or (gs and gs.game_mode == "DESTROY_BASE")
			if gs and (is_dom or teams_alive.size() <= 1 or am.get("sudden_death_active")):
				if teams_alive.size() == 0:
					am._end_match("DRAW! All bases were destroyed!")
					return
				elif teams_alive.size() == 1:
					var winner = teams_alive[0]
					if gs.current_mode == "AI_VS_AI":
						am._end_match("DOMINATION! " + winner + " IS VICTORIOUS!", winner)
					elif winner == my_team:
						am._end_match("DOMINATION VICTORY! All opposing bases destroyed.", winner)
					else:
						am._end_match("DEFEAT! " + winner + " achieved Domination by destroying all opposing bases.", winner)
					return


	# Destruction burst effect
	var parent_node = get_parent()
	var parent_pos = parent_node.global_position if parent_node.is_inside_tree() else parent_node.position
	var scene_root: Node = null
	if is_inside_tree() and get_tree() and get_tree().current_scene:
		scene_root = get_tree().current_scene
	elif parent_node and parent_node.get_parent():
		scene_root = parent_node.get_parent()
	if scene_root:
		var puff = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 1.0 if not "Base" in parent_node.name else 3.0
		sm.height = sm.radius * 2.0
		puff.mesh = sm
		var p_mat = StandardMaterial3D.new()
		p_mat.albedo_color = Color(0.9, 0.45, 0.1, 0.8)
		p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p_mat.emission_enabled = true
		p_mat.emission = Color(1.0, 0.5, 0.1)
		p_mat.emission_energy_multiplier = 2.5
		puff.material_override = p_mat
		scene_root.add_child(puff)
		puff.global_position = parent_pos + Vector3(0, 1.0, 0)
		var tw = puff.create_tween()
		if tw:
			tw.tween_property(puff, "scale", Vector3(1.5, 1.5, 1.5), 0.25)
			tw.parallel().tween_property(p_mat, "albedo_color:a", 0.0, 0.25)
			tw.tween_callback(puff.queue_free)
		else:
			puff.queue_free()


	var is_building = "Base" in parent_node.name or "Tower" in parent_node.name or "CommandBay" in parent_node.name or "ScorpionNest" in parent_node.name or "AntHill" in parent_node.name or "GorillaDen" in parent_node.name or "MonkeyBurrow" in parent_node.name or parent_node.is_in_group("Structure")
	if is_building:
		_apply_destroyed_building(parent_node)
	else:
		_spawn_unit_corpse(parent_node)
		parent_node.queue_free()

func _apply_destroyed_building(parent: Node3D):
	parent.remove_from_group("Targetable")
	for g in parent.get_groups():
		if g.begins_with("Side") or g == "NeutralStructure":
			parent.remove_from_group(g)
			
	parent.set_physics_process(false)
	parent.set_process(false)
	
	if hp_sprite: hp_sprite.visible = false
	if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	
	var p_name = parent.name
	var is_plague = "Plague" in p_name or parent.is_in_group("SideHarmony") or parent.is_in_group("Harmony")
	var is_gilded = "Gilded" in p_name or parent.is_in_group("GildedHarmony") or bool(parent.get_meta("is_gilded_harmony", false))
	var is_reach = "Reach" in p_name
	var is_scrap = "Scrap" in p_name
	var is_void = "Void" in p_name or parent.is_in_group("Beast")
	var is_rim = "Rimworlder" in p_name
	
	var sampled_color = Color(0.24, 0.22, 0.20)
	var sampled_accent = Color(0.14, 0.13, 0.12)
	var faction_mesh = parent.get_meta("faction_mesh", null)
	if faction_mesh and is_instance_valid(faction_mesh):
		var fm_name = faction_mesh.name
		if "Reach" in fm_name: is_reach = true
		elif "Scrap" in fm_name: is_scrap = true
		elif "Void" in fm_name: is_void = true
		elif "Harmony" in fm_name or "Plague" in fm_name: is_plague = true
		elif "Gilded" in fm_name: is_gilded = true
		elif "Rimworlder" in fm_name: is_rim = true
		for ch in faction_mesh.get_children():
			if ch is MeshInstance3D and ch.material_override is StandardMaterial3D:
				sampled_color = (ch.material_override as StandardMaterial3D).albedo_color.darkened(0.35)
				break
		faction_mesh.queue_free()
		parent.set_meta("faction_mesh", null)
		
	for c in parent.get_children():
		if c is MeshInstance3D or c is CSGShape3D:
			if c.name != "UnitGroundMarker":
				c.queue_free()
			
	var ruined_root = Node3D.new()
	ruined_root.name = "RuinedBuildingVisuals"
	parent.add_child(ruined_root)
	
	var r_mat = StandardMaterial3D.new()
	var dark_mat = StandardMaterial3D.new()
	var accent_mat = StandardMaterial3D.new()
	
	if is_plague:
		r_mat.albedo_color = Color(0.34, 0.14, 0.16); r_mat.roughness = 0.85
		dark_mat.albedo_color = Color(0.18, 0.08, 0.10); dark_mat.roughness = 0.92
		accent_mat.albedo_color = Color(0.82, 0.78, 0.65); accent_mat.roughness = 0.65 # Bone
	elif is_gilded:
		r_mat.albedo_color = Color(0.78, 0.76, 0.72); r_mat.roughness = 0.35
		dark_mat.albedo_color = Color(0.08, 0.22, 0.16); dark_mat.roughness = 0.5
		accent_mat.albedo_color = Color(0.85, 0.68, 0.18); accent_mat.metallic = 0.85; accent_mat.roughness = 0.25
	elif is_reach:
		r_mat.albedo_color = Color(0.65, 0.70, 0.76); r_mat.metallic = 0.6; r_mat.roughness = 0.45
		dark_mat.albedo_color = Color(0.22, 0.26, 0.32); dark_mat.metallic = 0.7; dark_mat.roughness = 0.6
		accent_mat.albedo_color = Color(0.0, 0.55, 0.75); accent_mat.emission_enabled = true; accent_mat.emission = Color(0.0, 0.45, 0.65); accent_mat.emission_energy_multiplier = 0.6
	elif is_scrap:
		r_mat.albedo_color = Color(0.38, 0.22, 0.14); r_mat.metallic = 0.55; r_mat.roughness = 0.92
		dark_mat.albedo_color = Color(0.18, 0.12, 0.09); dark_mat.roughness = 0.96
		accent_mat.albedo_color = Color(0.70, 0.50, 0.10); accent_mat.roughness = 0.85
	elif is_void:
		r_mat.albedo_color = Color(0.14, 0.06, 0.22); r_mat.metallic = 0.65; r_mat.roughness = 0.4
		dark_mat.albedo_color = Color(0.06, 0.02, 0.10); dark_mat.roughness = 0.8
		accent_mat.albedo_color = Color(0.65, 0.12, 0.85); accent_mat.emission_enabled = true; accent_mat.emission = Color(0.55, 0.08, 0.75); accent_mat.emission_energy_multiplier = 0.8
	elif is_rim:
		r_mat.albedo_color = Color(0.36, 0.26, 0.16); r_mat.roughness = 0.92
		dark_mat.albedo_color = Color(0.20, 0.15, 0.10); dark_mat.roughness = 0.96
		accent_mat.albedo_color = Color(0.78, 0.72, 0.60); accent_mat.roughness = 0.75
	else:
		r_mat.albedo_color = sampled_color; r_mat.roughness = 0.92
		dark_mat.albedo_color = sampled_accent; dark_mat.roughness = 0.98
		accent_mat.albedo_color = Color(0.32, 0.35, 0.30); accent_mat.metallic = 0.5
	
	if "Base" in p_name:
		var slab = MeshInstance3D.new()
		var sm = BoxMesh.new()
		sm.size = Vector3(10.5, 1.2, 10.5)
		slab.mesh = sm
		slab.material_override = dark_mat
		slab.position.y = 0.6
		ruined_root.add_child(slab)
		
		var heights = [2.8, 3.4, 2.2, 3.8]
		var offsets = [Vector3(-3.5, 0, -3.5), Vector3(3.5, 0, -3.5), Vector3(-3.5, 0, 3.5), Vector3(3.5, 0, 3.5)]
		for i in range(4):
			var wall = MeshInstance3D.new()
			var wm = BoxMesh.new()
			wm.size = Vector3(2.4, heights[i], 2.4)
			wall.mesh = wm
			wall.material_override = r_mat
			wall.position = offsets[i] + Vector3(0, heights[i] * 0.5 + 1.2, 0)
			wall.rotation = Vector3(deg_to_rad(randf_range(-12, 12)), randf() * TAU, deg_to_rad(randf_range(-12, 12)))
			ruined_root.add_child(wall)
			
		var roof = MeshInstance3D.new()
		var rm = BoxMesh.new()
		rm.size = Vector3(6.0, 0.6, 7.0)
		roof.mesh = rm
		roof.material_override = r_mat
		roof.position = Vector3(0.5, 2.2, -0.5)
		roof.rotation = Vector3(deg_to_rad(28.0), deg_to_rad(15.0), deg_to_rad(-18.0))
		ruined_root.add_child(roof)
		
		# Ruptured central core / faction centerpiece
		var core_ruin = MeshInstance3D.new()
		var crm = CylinderMesh.new(); crm.top_radius = 1.1; crm.bottom_radius = 1.6; crm.height = 2.4
		core_ruin.mesh = crm
		core_ruin.material_override = accent_mat
		core_ruin.position = Vector3(-0.4, 1.8, 0.3)
		core_ruin.rotation_degrees = Vector3(22, 10, -15)
		ruined_root.add_child(core_ruin)
		
		for i in range(8):
			var r_chunk = MeshInstance3D.new()
			var cm = BoxMesh.new()
			var sz = randf_range(0.8, 1.8)
			cm.size = Vector3(sz, randf_range(0.5, 1.2), sz)
			r_chunk.mesh = cm
			r_chunk.material_override = accent_mat if i % 3 == 0 else dark_mat
			var ang = randf() * TAU
			var dist = randf_range(2.0, 6.2)
			r_chunk.position = Vector3(cos(ang) * dist, 0.4, sin(ang) * dist)
			r_chunk.rotation = Vector3(randf() * 0.5, randf() * TAU, randf() * 0.5)
			ruined_root.add_child(r_chunk)
			
	elif "Tower" in p_name:
		var stump = MeshInstance3D.new()
		var st_m = CylinderMesh.new()
		st_m.top_radius = 1.4
		st_m.bottom_radius = 2.4
		st_m.height = 2.6
		stump.mesh = st_m
		stump.material_override = r_mat
		stump.position.y = 1.3
		ruined_root.add_child(stump)
		
		var spire = MeshInstance3D.new()
		var sp_m = BoxMesh.new()
		sp_m.size = Vector3(0.9, 2.8, 0.9)
		spire.mesh = sp_m
		spire.material_override = dark_mat
		spire.position = Vector3(0.4, 2.4, -0.2)
		spire.rotation = Vector3(deg_to_rad(32.0), deg_to_rad(25.0), deg_to_rad(-24.0))
		ruined_root.add_child(spire)
		
		# Toppled turret head lying beside the tower stump
		var fallen_head = MeshInstance3D.new()
		var fhm = SphereMesh.new(); fhm.radius = 0.95; fhm.height = 1.4
		fallen_head.mesh = fhm
		fallen_head.material_override = accent_mat
		fallen_head.position = Vector3(1.8, 0.55, 1.1)
		fallen_head.rotation_degrees = Vector3(40, 20, -35)
		ruined_root.add_child(fallen_head)
		
		for i in range(6):
			var rk = MeshInstance3D.new()
			var rk_m = BoxMesh.new()
			var rk_sz = randf_range(0.6, 1.2)
			rk_m.size = Vector3(rk_sz, randf_range(0.4, 0.8), rk_sz)
			rk.mesh = rk_m
			rk.material_override = accent_mat if i % 2 == 0 else dark_mat
			var ang = (TAU / 6.0) * i + randf_range(-0.2, 0.2)
			rk.position = Vector3(cos(ang) * 2.8, 0.3, sin(ang) * 2.8)
			rk.rotation = Vector3(randf() * 0.4, randf() * TAU, randf() * 0.4)
			ruined_root.add_child(rk)
			
	elif "CommandBay" in p_name:
		var pad = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.top_radius = 2.8
		pm.bottom_radius = 3.2
		pm.height = 0.4
		pad.mesh = pm
		pad.material_override = dark_mat
		pad.position.y = 0.2
		ruined_root.add_child(pad)
		
		if is_plague:
			# Ruptured organic flesh mound + shattered bone ribs + deflated eye
			var flesh_mound = MeshInstance3D.new()
			var fm = SphereMesh.new(); fm.radius = 1.9; fm.height = 1.4
			flesh_mound.mesh = fm; flesh_mound.material_override = r_mat
			flesh_mound.position = Vector3(0, 0.5, 0)
			ruined_root.add_child(flesh_mound)
			for i in range(6):
				var rib = MeshInstance3D.new()
				var rbm = CylinderMesh.new(); rbm.top_radius = 0.06; rbm.bottom_radius = 0.18; rbm.height = 1.8
				rib.mesh = rbm; rib.material_override = accent_mat
				var a = (TAU / 6.0) * i
				rib.position = Vector3(cos(a) * 1.8, 0.85, sin(a) * 1.8)
				rib.rotation = Vector3(deg_to_rad(35), a, deg_to_rad(25))
				ruined_root.add_child(rib)
			var dead_eye = MeshInstance3D.new()
			var dem = SphereMesh.new(); dem.radius = 0.65; dem.height = 0.6
			dead_eye.mesh = dem; dead_eye.material_override = HarmonyHuskBuilderScript.get_gold_vein_material()
			dead_eye.position = Vector3(0.4, 0.85, -0.3)
			ruined_root.add_child(dead_eye)
		elif is_gilded:
			# Shattered white-marble dais + broken golden halo rings + fallen pale-blue crystal
			for i in range(2):
				var ring = MeshInstance3D.new()
				var trm = TorusMesh.new(); trm.inner_radius = 1.4 + i * 0.5; trm.outer_radius = 1.65 + i * 0.5
				ring.mesh = trm; ring.material_override = accent_mat
				ring.position = Vector3(0.2 * i, 0.55 + i * 0.2, -0.2 * i)
				ring.rotation_degrees = Vector3(28 - i * 45, 35 * i, 18)
				ruined_root.add_child(ring)
			for i in range(4):
				var pillar = MeshInstance3D.new()
				var plm = BoxMesh.new(); plm.size = Vector3(0.45, 1.9, 0.45)
				pillar.mesh = plm; pillar.material_override = r_mat
				var a = (TAU / 4.0) * i + 0.4
				pillar.position = Vector3(cos(a) * 2.1, 0.75, sin(a) * 2.1)
				pillar.rotation = Vector3(deg_to_rad(42), a, deg_to_rad(-25))
				ruined_root.add_child(pillar)
		else:
			for i in range(4):
				var strut = MeshInstance3D.new()
				var stm = BoxMesh.new()
				stm.size = Vector3(0.35, 2.2, 0.35)
				strut.mesh = stm
				strut.material_override = r_mat
				var a = (TAU / 4.0) * i
				strut.position = Vector3(cos(a) * 2.2, 0.9, sin(a) * 2.2)
				strut.rotation = Vector3(deg_to_rad(randf_range(25, 50)), a, deg_to_rad(randf_range(-25, 25)))
				ruined_root.add_child(strut)
			var dish = MeshInstance3D.new()
			var dm = CylinderMesh.new(); dm.top_radius = 1.2; dm.bottom_radius = 0.4; dm.height = 0.35
			dish.mesh = dm; dish.material_override = accent_mat
			dish.position = Vector3(0.3, 0.55, -0.2)
			dish.rotation_degrees = Vector3(38, 15, -22)
			ruined_root.add_child(dish)
			
	elif "ScorpionNest" in p_name:
		var pit_crater = MeshInstance3D.new()
		var pcm = CylinderMesh.new()
		pcm.top_radius = 6.2
		pcm.bottom_radius = 6.8
		pcm.height = 0.08
		pit_crater.mesh = pcm
		pit_crater.material_override = dark_mat
		pit_crater.position.y = 0.04
		ruined_root.add_child(pit_crater)
		
		for i in range(8):
			var sk = MeshInstance3D.new()
			var sm_b = BoxMesh.new()
			sm_b.size = Vector3(randf_range(0.8, 1.5), randf_range(0.4, 0.8), randf_range(0.8, 1.5))
			sk.mesh = sm_b
			sk.material_override = r_mat
			var ang = randf() * TAU
			var d = randf_range(1.5, 5.5)
			sk.position = Vector3(cos(ang) * d, 0.25, sin(ang) * d)
			sk.rotation = Vector3(randf() * 0.4, randf() * TAU, randf() * 0.4)
			ruined_root.add_child(sk)
			
	elif "AntHill" in p_name:
		var mound = MeshInstance3D.new()
		var mm = CylinderMesh.new()
		mm.top_radius = 1.2
		mm.bottom_radius = 3.6
		mm.height = 0.9
		mound.mesh = mm
		mound.material_override = dark_mat
		mound.position.y = 0.45
		ruined_root.add_child(mound)
		
		var crater = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 1.1
		cm.bottom_radius = 0.4
		cm.height = 0.2
		var crater_mat = StandardMaterial3D.new()
		crater_mat.albedo_color = Color(0.18, 0.45, 0.12)
		crater_mat.emission_enabled = true
		crater_mat.emission = Color(0.15, 0.4, 0.1)
		crater_mat.emission_energy_multiplier = 0.8
		crater.mesh = cm
		crater.material_override = crater_mat
		crater.position.y = 0.95
		ruined_root.add_child(crater)

	elif "GorillaDen" in p_name:
		var log_arch = MeshInstance3D.new()
		var lm = CylinderMesh.new()
		lm.top_radius = 0.55
		lm.bottom_radius = 0.65
		lm.height = 3.6
		log_arch.mesh = lm
		log_arch.material_override = dark_mat
		log_arch.position = Vector3(0, 0.35, 0)
		log_arch.rotation_degrees = Vector3(8.0, 42.0, 85.0)
		ruined_root.add_child(log_arch)
		for i in range(6):
			var rk = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(randf_range(0.9, 1.4), randf_range(0.4, 0.7), randf_range(0.9, 1.4))
			rk.mesh = bm
			rk.material_override = r_mat
			var ang = randf() * TAU
			var d = randf_range(1.2, 4.5)
			rk.position = Vector3(cos(ang) * d, 0.25, sin(ang) * d)
			rk.rotation = Vector3(randf() * 0.3, randf() * TAU, randf() * 0.3)
			ruined_root.add_child(rk)

	elif "MonkeyBurrow" in p_name:
		var mound = MeshInstance3D.new()
		var mm = CylinderMesh.new()
		mm.top_radius = 0.8
		mm.bottom_radius = 3.2
		mm.height = 0.75
		mound.mesh = mm
		mound.material_override = dark_mat
		mound.position.y = 0.35
		ruined_root.add_child(mound)
		for i in range(5):
			var thatch = MeshInstance3D.new()
			var tm = BoxMesh.new()
			tm.size = Vector3(randf_range(0.6, 1.2), 0.12, randf_range(0.6, 1.2))
			thatch.mesh = tm
			thatch.material_override = r_mat
			var ang = randf() * TAU
			var d = randf_range(0.8, 3.2)
			thatch.position = Vector3(cos(ang) * d, 0.38, sin(ang) * d)
			thatch.rotation = Vector3(randf() * 0.2, randf() * TAU, randf() * 0.2)
			ruined_root.add_child(thatch)

	# Persistent smoldering smoke plume on ruined buildings
	var ruin_smoke = CPUParticles3D.new()
	ruin_smoke.name = "RuinedSmokePlume"
	ruin_smoke.amount = 14
	ruin_smoke.lifetime = 1.8
	ruin_smoke.direction = Vector3(0, 1, 0)
	ruin_smoke.spread = 22.0
	ruin_smoke.gravity = Vector3(0, 1.4, 0)
	ruin_smoke.initial_velocity_min = 0.8
	ruin_smoke.initial_velocity_max = 1.8
	var rs_mesh = SphereMesh.new(); rs_mesh.radius = 0.35; rs_mesh.height = 0.7
	var rs_mat = StandardMaterial3D.new()
	rs_mat.albedo_color = Color(0.14, 0.14, 0.14, 0.65)
	rs_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ruin_smoke.mesh = rs_mesh
	ruin_smoke.material_override = rs_mat
	ruin_smoke.position = Vector3(0, 1.2, 0)
	ruined_root.add_child(ruin_smoke)
	if ruin_smoke.is_inside_tree():
		ruin_smoke.emitting = true

func _spawn_unit_corpse(parent: Node3D):
	var p_pos = parent.global_position if parent.is_inside_tree() else parent.position
	var p_rot = parent.global_rotation if parent.is_inside_tree() else parent.rotation
	
	var corpse = Node3D.new()
	corpse.name = "Corpse_" + str(parent.name)
	
	var p_name = parent.name
	var is_gilded_unit: bool = bool(parent.get_meta("is_gilded_harmony", false)) or parent.is_in_group("GildedHarmony")
	var is_humanoid = false
	if parent.has_method("is_humanoid"):
		is_humanoid = parent.is_humanoid()
	elif parent.get_node_or_null("HumanoidRig") != null:
		is_humanoid = true
	else:
		var has_mech = "Tank" in p_name or "Mech" in p_name or "Plane" in p_name or "Walker" in p_name or "Spider" in p_name
		var has_beast = "Ant" in p_name or "Scorpion" in p_name or "Squid" in p_name or "Octopus" in p_name or "Jellyfish" in p_name or "Beetle" in p_name or "Spiker" in p_name or "Leviathan" in p_name or "Crawler" in p_name or "Stalker" in p_name or "Spitter" in p_name or "Corruptor" in p_name or "Overlord" in p_name or "Gargoyle" in p_name or "Voidling" in p_name or "Mutant" in p_name or "Monstrous" in p_name or "Digestive" in p_name or "EyeOfHarmony" in p_name or "BeastOfHarmony" in p_name or parent.is_in_group("BeastOfHarmony") or parent.is_in_group("HarmonyInfector") or parent.is_in_group("GildedHarmony")
		if not has_mech and not has_beast:
			is_humanoid = true

	if is_humanoid:
		_build_broken_humanoid(corpse, parent)
	elif "Plane" in p_name:
		_build_broken_aircraft(corpse, parent)
	elif "Mech" in p_name or "Walker" in p_name:
		_build_broken_mech(corpse, parent)
	elif "Tank" in p_name or "Spider" in p_name:
		_build_broken_tank(corpse, parent)
	else:
		_build_broken_beast(corpse, parent)

	if parent.has_meta("is_husk_of_harmony") or parent.is_in_group("HuskOfHarmony") or parent.is_in_group("SideHarmony") or is_gilded_unit:
		HarmonyHuskBuilderScript.apply_corpse_gold_veins(corpse, is_gilded_unit)

	if parent.has_meta("gilded_gen_scale"):
		corpse.scale = Vector3.ONE * float(parent.get_meta("gilded_gen_scale"))

	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	var scene_root: Node = null
	if tree and tree.current_scene:
		scene_root = tree.current_scene
	elif parent and parent.get_parent():
		scene_root = parent.get_parent()
	if scene_root:
		scene_root.add_child(corpse)
		if corpse.is_inside_tree():
			corpse.global_position = p_pos
			corpse.global_rotation = p_rot
		else:
			corpse.position = p_pos
			corpse.rotation = p_rot

		var gs = _get_game_state()
		if gs and gs.has_method("register_corpse"):
			gs.register_corpse(corpse)

func _process(delta):

	if is_dead: return
	if poison_ticks > 0:
		poison_timer -= delta
		if poison_timer <= 0:
			poison_timer = 1.0
			take_damage(poison_dps)
			poison_ticks -= 1

	if scrap_heal_time > 0:
		scrap_heal_time -= delta
		current_health += 15.0 * delta
		if current_health > max_health: current_health = max_health
		if hp_bar:
			hp_bar.value = current_health
			if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		emit_signal("health_changed", current_health, max_health)
			
	if current_health > 0 and current_health < max_health:
		var parent = get_parent()
		if parent and parent.get("unit_attribute") == "Organic":
			current_health += 1.0 * delta # Slow regen: 1 HP per second
			if current_health > max_health: current_health = max_health
			if hp_bar:
				hp_bar.value = current_health
				if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	# Shield Recharge over time
	if shield_recharge_rate > 0.0 and max_shield > 0.0 and not is_dead:
		shield_recharge_timer += delta
		if shield_recharge_timer >= shield_recharge_delay and current_shield < max_shield:
			var was_empty = (current_shield <= 0.0)
			current_shield = minf(max_shield, current_shield + shield_recharge_rate * delta)
			if was_empty and current_shield > 0.0:
				_restore_shield()
			emit_signal("shield_changed", current_shield, max_shield)
			_refresh_shield_bar()
			if hp_viewport:
				hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	if shield_ring_node and is_instance_valid(shield_ring_node) and current_shield > 0.0:
		shield_ring_node.rotate_y(1.6 * delta)

	_update_vehicle_smoke(delta)

func _setup_vehicle_smoke():
	var parent = get_parent()
	if not parent or not is_instance_valid(parent): return
	if vehicle_smoke_emitter != null and is_instance_valid(vehicle_smoke_emitter): return
	
	vehicle_smoke_emitter = Node3D.new()
	vehicle_smoke_emitter.name = "VehicleDamageSmoke"
	
	var p_name = parent.name
	var offset = Vector3(0, 1.4, -0.8)
	if "Tank" in p_name:
		offset = Vector3(0, 1.35, -1.0)
	elif "Mech" in p_name:
		offset = Vector3(0, 2.5, -0.5)
	elif "Plane" in p_name:
		offset = Vector3(0, 1.1, -1.6)
	elif "Walker" in p_name or "Spider" in p_name:
		offset = Vector3(0, 1.8, 0)
	elif "Base" in p_name:
		offset = Vector3(0, 4.2, 0)
	elif "Tower" in p_name or "CommandBay" in p_name:
		offset = Vector3(0, 3.8, 0)
	vehicle_smoke_emitter.position = offset
	
	# 1. Dark billowing smoke particles
	vehicle_smoke_particles = CPUParticles3D.new()
	vehicle_smoke_particles.name = "SmokePlume"
	vehicle_smoke_particles.amount = 20
	vehicle_smoke_particles.lifetime = 1.3
	vehicle_smoke_particles.explosiveness = 0.05
	vehicle_smoke_particles.randomness = 0.3
	vehicle_smoke_particles.direction = Vector3(0, 1, 0)
	vehicle_smoke_particles.spread = 28.0
	vehicle_smoke_particles.gravity = Vector3(0, 2.0, 0)
	vehicle_smoke_particles.initial_velocity_min = 1.2
	vehicle_smoke_particles.initial_velocity_max = 2.8
	vehicle_smoke_particles.scale_amount_min = 0.8
	vehicle_smoke_particles.scale_amount_max = 2.4
	
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.22
	s_mesh.height = 0.44
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.12, 0.12, 0.12, 0.75)
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.roughness = 1.0
	vehicle_smoke_particles.mesh = s_mesh
	vehicle_smoke_particles.material_override = s_mat
	vehicle_smoke_particles.emitting = false
	vehicle_smoke_emitter.add_child(vehicle_smoke_particles)
	
	# 2. Sputtering fiery sparks / flame bursts
	vehicle_spark_particles = CPUParticles3D.new()
	vehicle_spark_particles.name = "SparksFire"
	vehicle_spark_particles.amount = 8
	vehicle_spark_particles.lifetime = 0.55
	vehicle_spark_particles.randomness = 0.5
	vehicle_spark_particles.direction = Vector3(0, 1, 0)
	vehicle_spark_particles.spread = 45.0
	vehicle_spark_particles.gravity = Vector3(0, -3.2, 0)
	vehicle_spark_particles.initial_velocity_min = 2.2
	vehicle_spark_particles.initial_velocity_max = 4.6
	
	var sp_mesh = BoxMesh.new()
	sp_mesh.size = Vector3(0.06, 0.06, 0.06)
	var sp_mat = StandardMaterial3D.new()
	sp_mat.albedo_color = Color(1.0, 0.45, 0.05)
	sp_mat.emission_enabled = true
	sp_mat.emission = Color(1.0, 0.4, 0.0)
	sp_mat.emission_energy_multiplier = 4.0
	vehicle_spark_particles.mesh = sp_mesh
	vehicle_spark_particles.material_override = sp_mat
	vehicle_spark_particles.emitting = false
	vehicle_smoke_emitter.add_child(vehicle_spark_particles)
	
	parent.add_child(vehicle_smoke_emitter)

func _update_vehicle_smoke(_delta: float):
	var parent = get_parent()
	if not parent or not is_instance_valid(parent): return
	if not is_mechanical_entity(parent): return

	
	var is_smoking = not is_dead and is_vehicle_damaged()
	if is_smoking:
		if vehicle_smoke_emitter == null or not is_instance_valid(vehicle_smoke_emitter):
			_setup_vehicle_smoke()
		if vehicle_smoke_emitter:
			vehicle_smoke_emitter.visible = true
			if vehicle_smoke_emitter.is_inside_tree():
				if vehicle_smoke_particles and not vehicle_smoke_particles.emitting:
					vehicle_smoke_particles.emitting = true
				if vehicle_spark_particles and not vehicle_spark_particles.emitting:
					vehicle_spark_particles.emitting = true
	else:
		if vehicle_smoke_emitter and is_instance_valid(vehicle_smoke_emitter):
			if vehicle_smoke_particles and vehicle_smoke_particles.emitting:
				vehicle_smoke_particles.emitting = false
			if vehicle_spark_particles and vehicle_spark_particles.emitting:
				vehicle_spark_particles.emitting = false
			vehicle_smoke_emitter.visible = false



func trigger_scrap_heal():
	if scrap_heal_time <= 0: print(get_parent().name, " triggers SCRAP HEAL!")
	scrap_heal_time = 2.0

func set_max_health(new_max: float):
	max_health = new_max
	current_health = new_max
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
		update_health_bar_colors()
	if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _build_broken_humanoid(corpse: Node3D, parent: Node3D):
	var p_name = parent.name
	var is_reach = "Reach" in p_name
	var is_scrap = "Scrap" in p_name
	var is_beast_speaker = "GreatBeastSpeaker" in p_name
	var is_rimworlder = "Rimworlder" in p_name or is_beast_speaker
	var is_medic = "Medic" in p_name
	var is_repair = "Repair" in p_name
	var is_commander = "Commander" in p_name or "Hero" in p_name or is_beast_speaker
	var is_hunter = "Hunter" in p_name or "Assassin" in p_name
	var is_shield_inf = "ShieldInfantry" in p_name or (is_reach and is_commander)
	var is_armored_inf = "ArmoredInfantry" in p_name or (is_scrap and is_commander)
	
	var suit_mat = StandardMaterial3D.new()
	var armor_mat = StandardMaterial3D.new()
	var visor_mat = StandardMaterial3D.new()
	var weapon_mat = StandardMaterial3D.new()
	
	if is_beast_speaker:
		suit_mat.albedo_color = Color(0.32, 0.22, 0.14); suit_mat.roughness = 0.85
		armor_mat.albedo_color = Color(0.86, 0.82, 0.70); armor_mat.roughness = 0.55
		visor_mat.albedo_color = Color(0.15, 0.75, 0.35); visor_mat.emission_enabled = true; visor_mat.emission = Color(0.1, 0.55, 0.25); visor_mat.emission_energy_multiplier = 0.8
		weapon_mat.albedo_color = Color(0.76, 0.70, 0.58); weapon_mat.roughness = 0.65
	elif is_reach:
		suit_mat.albedo_color = Color(0.88, 0.92, 0.96); suit_mat.roughness = 0.3
		armor_mat.albedo_color = Color(0.75, 0.82, 0.90) if not is_commander else Color(0.88, 0.72, 0.22); armor_mat.metallic = 0.85
		visor_mat.albedo_color = Color(0.0, 0.7, 0.85); visor_mat.emission_enabled = true; visor_mat.emission = Color(0.0, 0.6, 0.8); visor_mat.emission_energy_multiplier = 0.8
		weapon_mat.albedo_color = Color(0.2, 0.65, 0.85) if ("Melee" in p_name or is_commander or is_shield_inf) else Color(0.2, 0.25, 0.3); weapon_mat.metallic = 0.9
	elif is_scrap:
		suit_mat.albedo_color = Color(0.35, 0.22, 0.16); suit_mat.roughness = 0.9
		armor_mat.albedo_color = Color(0.55, 0.32, 0.18); armor_mat.metallic = 0.65; armor_mat.roughness = 0.85
		visor_mat.albedo_color = Color(0.85, 0.5, 0.1); visor_mat.roughness = 0.75
		weapon_mat.albedo_color = Color(0.28, 0.22, 0.18); weapon_mat.metallic = 0.75
	elif is_rimworlder:
		suit_mat.albedo_color = Color(0.38, 0.28, 0.18); suit_mat.roughness = 0.9
		armor_mat.albedo_color = Color(0.48, 0.36, 0.24); armor_mat.roughness = 0.8
		visor_mat.albedo_color = Color(0.75, 0.22, 0.18); visor_mat.roughness = 0.7
		weapon_mat.albedo_color = Color(0.25, 0.2, 0.18); weapon_mat.metallic = 0.5
	elif is_medic:
		suit_mat.albedo_color = Color(0.82, 0.82, 0.84); suit_mat.roughness = 0.6
		armor_mat.albedo_color = Color(0.75, 0.15, 0.15); armor_mat.roughness = 0.5
		visor_mat.albedo_color = Color(0.1, 0.7, 0.3); visor_mat.emission_enabled = true; visor_mat.emission = Color(0.1, 0.6, 0.25); visor_mat.emission_energy_multiplier = 0.6
		weapon_mat.albedo_color = Color(0.25, 0.25, 0.25); weapon_mat.metallic = 0.8
	elif is_hunter:
		suit_mat.albedo_color = Color(0.12, 0.12, 0.14); suit_mat.roughness = 0.7
		armor_mat.albedo_color = Color(0.18, 0.18, 0.22); armor_mat.roughness = 0.6
		visor_mat.albedo_color = Color(0.65, 0.12, 0.8); visor_mat.emission_enabled = true; visor_mat.emission = Color(0.5, 0.1, 0.65); visor_mat.emission_energy_multiplier = 0.8
		weapon_mat.albedo_color = Color(0.55, 0.12, 0.75); weapon_mat.metallic = 0.9
	elif is_commander:
		suit_mat.albedo_color = Color(0.18, 0.22, 0.28); suit_mat.metallic = 0.6
		armor_mat.albedo_color = Color(0.85, 0.7, 0.18); armor_mat.metallic = 0.9; armor_mat.roughness = 0.3
		visor_mat.albedo_color = Color(0.9, 0.75, 0.25); visor_mat.emission_enabled = true; visor_mat.emission = Color(0.8, 0.65, 0.2); visor_mat.emission_energy_multiplier = 0.8
		weapon_mat.albedo_color = Color(0.85, 0.72, 0.22); weapon_mat.metallic = 0.9
	else:
		suit_mat.albedo_color = Color(0.22, 0.28, 0.18); suit_mat.roughness = 0.7
		armor_mat.albedo_color = Color(0.16, 0.22, 0.14); armor_mat.metallic = 0.4
		visor_mat.albedo_color = Color(0.18, 0.6, 0.8); visor_mat.emission_enabled = true; visor_mat.emission = Color(0.15, 0.5, 0.7); visor_mat.emission_energy_multiplier = 0.8
		weapon_mat.albedo_color = Color(0.18, 0.18, 0.18); weapon_mat.metallic = 0.8

	if is_commander:
		corpse.scale = Vector3(1.18, 1.18, 1.18)

	# Commander or Assassin Cape pooled under torso
	if is_commander or is_hunter:
		var cape = MeshInstance3D.new()
		var cpm = BoxMesh.new(); cpm.size = Vector3(0.72, 0.03, 0.95)
		cape.mesh = cpm
		var cape_mat = StandardMaterial3D.new()
		if is_beast_speaker: cape_mat.albedo_color = Color(0.24, 0.16, 0.10)
		elif is_reach: cape_mat.albedo_color = Color(0.08, 0.42, 0.65)
		elif is_scrap: cape_mat.albedo_color = Color(0.45, 0.14, 0.10)
		elif is_hunter: cape_mat.albedo_color = Color(0.08, 0.06, 0.12)
		else: cape_mat.albedo_color = Color(0.55, 0.10, 0.12)
		cape_mat.roughness = 0.9
		cape.material_override = cape_mat
		cape.position = Vector3(0, 0.03, 0.08)
		cape.rotation_degrees = Vector3(0, randf_range(-10, 10), 0)
		corpse.add_child(cape)

	# Fallen Torso lying on the ground
	var torso_mesh = MeshInstance3D.new()
	var tm = BoxMesh.new(); tm.size = Vector3(0.48, 0.24, 0.65)
	torso_mesh.mesh = tm
	torso_mesh.material_override = suit_mat
	torso_mesh.position = Vector3(0, 0.12, 0)
	torso_mesh.rotation = Vector3(deg_to_rad(randf_range(-8, 8)), deg_to_rad(randf_range(-15, 15)), deg_to_rad(randf_range(-12, 12)))
	corpse.add_child(torso_mesh)
	
	# Cracked Armor Plate
	var ap_mesh = MeshInstance3D.new()
	var apm = BoxMesh.new(); apm.size = Vector3(0.56, 0.18, 0.50) if is_armored_inf else Vector3(0.52, 0.14, 0.45)
	ap_mesh.mesh = apm
	ap_mesh.material_override = armor_mat
	ap_mesh.position = torso_mesh.position + Vector3(0, 0.1, 0)
	corpse.add_child(ap_mesh)

	# Unit-specific pauldrons / backpacks
	if is_armored_inf or is_commander or is_beast_speaker:
		for s in [-1.0, 1.0]:
			var pauldron = MeshInstance3D.new()
			var pm_box = BoxMesh.new(); pm_box.size = Vector3(0.24, 0.20, 0.26)
			pauldron.mesh = pm_box
			pauldron.material_override = armor_mat
			pauldron.position = torso_mesh.position + Vector3(s * 0.34, 0.12, -0.18)
			pauldron.rotation_degrees = Vector3(12, s * 15, s * -22)
			corpse.add_child(pauldron)
	if is_scrap and (is_armored_inf or is_commander):
		var pipe = MeshInstance3D.new()
		var pcm = CylinderMesh.new(); pcm.top_radius = 0.05; pcm.bottom_radius = 0.06; pcm.height = 0.45
		pipe.mesh = pcm; pipe.material_override = weapon_mat
		pipe.position = torso_mesh.position + Vector3(-0.18, 0.22, -0.1)
		pipe.rotation_degrees = Vector3(45, 10, 28)
		corpse.add_child(pipe)
	elif is_medic or is_repair:
		var pack = MeshInstance3D.new()
		var pkm = BoxMesh.new(); pkm.size = Vector3(0.32, 0.22, 0.36)
		pack.mesh = pkm; pack.material_override = armor_mat
		pack.position = torso_mesh.position + Vector3(-0.35, 0.08, -0.05)
		pack.rotation_degrees = Vector3(15, 35, 20)
		corpse.add_child(pack)

	# Helmet tilted on ground with cracked visor
	var head_mesh = MeshInstance3D.new()
	var hm = SphereMesh.new(); hm.radius = 0.19; hm.height = 0.36
	head_mesh.mesh = hm
	head_mesh.material_override = armor_mat
	head_mesh.position = torso_mesh.position + Vector3(0.05, 0.08, -0.48)
	head_mesh.rotation = Vector3(deg_to_rad(15), deg_to_rad(30), deg_to_rad(-25))
	corpse.add_child(head_mesh)
	
	var visor_m = MeshInstance3D.new()
	var vm = BoxMesh.new(); vm.size = Vector3(0.22, 0.06, 0.12)
	visor_m.mesh = vm
	visor_m.material_override = visor_mat
	visor_m.position = head_mesh.position + Vector3(0.04, 0.02, -0.12)
	visor_m.rotation = head_mesh.rotation
	corpse.add_child(visor_m)

	# Special Headgear: GreatBeastSpeaker skull horns, RimworlderGunner frontier hat, Commander crest
	if is_beast_speaker:
		for s in [-1.0, 1.0]:
			var horn = MeshInstance3D.new()
			var hcm = CylinderMesh.new(); hcm.top_radius = 0.015; hcm.bottom_radius = 0.055; hcm.height = 0.34
			horn.mesh = hcm; horn.material_override = armor_mat
			horn.position = head_mesh.position + Vector3(s * 0.18, 0.10, -0.04)
			horn.rotation_degrees = Vector3(-20, 0, s * -48)
			corpse.add_child(horn)
	elif "RimworlderGunner" in p_name:
		var hat = MeshInstance3D.new()
		var hbm = CylinderMesh.new(); hbm.top_radius = 0.32; hbm.bottom_radius = 0.34; hbm.height = 0.03
		hat.mesh = hbm; hat.material_override = suit_mat
		hat.position = head_mesh.position + Vector3(-0.35, -0.04, -0.15)
		hat.rotation_degrees = Vector3(12, 25, -18)
		corpse.add_child(hat)
		var crown_hat = MeshInstance3D.new()
		var chm = CylinderMesh.new(); chm.top_radius = 0.14; chm.bottom_radius = 0.17; chm.height = 0.14
		crown_hat.mesh = chm; crown_hat.material_override = suit_mat
		crown_hat.position = Vector3(0, 0.07, 0)
		hat.add_child(crown_hat)
	elif is_commander:
		var crest = MeshInstance3D.new()
		var crm = PrismMesh.new(); crm.size = Vector3(0.06, 0.16, 0.28)
		crest.mesh = crm; crest.material_override = weapon_mat
		crest.position = head_mesh.position + Vector3(0, 0.18, 0)
		crest.rotation = head_mesh.rotation
		corpse.add_child(crest)
	
	# Limp arms splayed on ground
	for s in [-1.0, 1.0]:
		var arm = MeshInstance3D.new()
		var am = CapsuleMesh.new(); am.radius = 0.08; am.height = 0.52
		arm.mesh = am
		arm.material_override = suit_mat
		arm.position = torso_mesh.position + Vector3(s * 0.38, -0.02, randf_range(-0.1, 0.1))
		arm.rotation = Vector3(deg_to_rad(randf_range(65, 85)), deg_to_rad(s * randf_range(25, 55)), deg_to_rad(s * 30))
		corpse.add_child(arm)
		if s < 0 and is_shield_inf:
			# Shattered hardlight buckler emitter frame on left arm
			var buckler = MeshInstance3D.new()
			var bkm = BoxMesh.new(); bkm.size = Vector3(0.36, 0.05, 0.44)
			buckler.mesh = bkm
			buckler.material_override = visor_mat
			buckler.position = arm.position + Vector3(-0.14, 0.06, -0.08)
			buckler.rotation_degrees = Vector3(14, -25, 22)
			corpse.add_child(buckler)
		
	# Legs splayed naturally on the ground
	for s in [-1.0, 1.0]:
		var leg = MeshInstance3D.new()
		var lm = CapsuleMesh.new(); lm.radius = 0.09; lm.height = 0.58
		leg.mesh = lm
		leg.material_override = suit_mat
		leg.position = torso_mesh.position + Vector3(s * 0.22, -0.02, 0.55)
		leg.rotation = Vector3(deg_to_rad(randf_range(75, 95)), deg_to_rad(s * randf_range(10, 25)), 0)
		corpse.add_child(leg)
		
		var boot = MeshInstance3D.new()
		var bm = BoxMesh.new(); bm.size = Vector3(0.16, 0.14, 0.24)
		boot.mesh = bm
		boot.material_override = weapon_mat
		boot.position = leg.position + Vector3(s * 0.04, 0.0, 0.32)
		corpse.add_child(boot)

	# Dropped unit-specific weapon lying right beside hand
	var weapon = MeshInstance3D.new()
	var w_pos = torso_mesh.position + Vector3(0.65, 0.05, -0.05)
	if is_beast_speaker:
		var staff = CylinderMesh.new(); staff.top_radius = 0.035; staff.bottom_radius = 0.045; staff.height = 1.45
		weapon.mesh = staff; weapon.material_override = weapon_mat
		weapon.position = w_pos; weapon.rotation_degrees = Vector3(88, 32, 0)
		var orb = MeshInstance3D.new()
		var obm = SphereMesh.new(); obm.radius = 0.12; obm.height = 0.22
		orb.mesh = obm; orb.material_override = visor_mat
		orb.position = Vector3(0, 0.76, 0)
		weapon.add_child(orb)
	elif "Sniper" in p_name or "ReachRanged" in p_name or "ScrapRanged" in p_name:
		var rifle = BoxMesh.new(); rifle.size = Vector3(0.08, 0.1, 1.15)
		weapon.mesh = rifle; weapon.material_override = weapon_mat
		weapon.position = w_pos; weapon.rotation = Vector3(0, deg_to_rad(randf_range(25, 45)), 0)
	elif "Rocket" in p_name:
		var tube = CylinderMesh.new(); tube.top_radius = 0.12; tube.bottom_radius = 0.12; tube.height = 1.1
		weapon.mesh = tube; weapon.material_override = weapon_mat
		weapon.position = w_pos; weapon.rotation = Vector3(0, deg_to_rad(randf_range(30, 60)), deg_to_rad(85))
	elif is_medic or is_repair:
		var tool = BoxMesh.new(); tool.size = Vector3(0.12, 0.12, 0.45)
		weapon.mesh = tool; weapon.material_override = weapon_mat
		weapon.position = w_pos; weapon.rotation = Vector3(0, deg_to_rad(randf_range(15, 45)), 0)
	elif is_commander or "Melee" in p_name or "Runner" in p_name or is_shield_inf or is_armored_inf:
		var blade = BoxMesh.new(); blade.size = Vector3(0.05, 0.16 if is_scrap else 0.12, 1.05 if is_commander else 0.88)
		weapon.mesh = blade; weapon.material_override = visor_mat if is_reach else weapon_mat
		weapon.position = w_pos; weapon.rotation = Vector3(0, deg_to_rad(randf_range(35, 75)), 0)
	elif is_hunter:
		var dagger = BoxMesh.new(); dagger.size = Vector3(0.03, 0.08, 0.48)
		weapon.mesh = dagger; weapon.material_override = weapon_mat
		weapon.position = w_pos; weapon.rotation = Vector3(0, deg_to_rad(randf_range(20, 50)), 0)
	else:
		var carbine = BoxMesh.new(); carbine.size = Vector3(0.08, 0.08, 0.75)
		weapon.mesh = carbine; weapon.material_override = weapon_mat
		weapon.position = w_pos; weapon.rotation = Vector3(0, deg_to_rad(randf_range(30, 50)), 0)
	corpse.add_child(weapon)

	# Ground blood / scorch stain
	var pool = MeshInstance3D.new()
	var pm = CylinderMesh.new(); pm.top_radius = 0.75; pm.bottom_radius = 0.8; pm.height = 0.02
	pool.mesh = pm
	var pmat = StandardMaterial3D.new()
	pmat.albedo_color = Color(0.08, 0.06, 0.06, 0.85) if not is_reach else Color(0.05, 0.2, 0.25, 0.7)
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pool.material_override = pmat
	pool.position = Vector3(0, 0.01, 0)
	corpse.add_child(pool)

func _build_broken_tank(corpse: Node3D, parent: Node3D):
	var p_name = parent.name
	var is_spider = "Spider" in p_name
	var is_reach = "Reach" in p_name
	var is_scrap = "Scrap" in p_name
	var is_plague = "Plague" in p_name
	var is_gilded = "Gilded" in p_name
	var is_shield_tank = "ShieldTank" in p_name
	var is_heavy = "Heavy" in p_name or is_shield_tank or is_plague or is_gilded
	
	var wreck_mat = StandardMaterial3D.new()
	var accent_mat = StandardMaterial3D.new()
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.10, 0.10, 0.11); dark_mat.roughness = 0.92
	
	if is_spider:
		wreck_mat.albedo_color = Color(0.18, 0.20, 0.24); wreck_mat.metallic = 0.75; wreck_mat.roughness = 0.45
		accent_mat.albedo_color = Color(0.65, 0.12, 0.12); accent_mat.emission_enabled = true; accent_mat.emission = Color(0.55, 0.08, 0.08); accent_mat.emission_energy_multiplier = 0.7
		# Collapsed octagonal/spherical spider chassis
		var pod = MeshInstance3D.new()
		var spm = SphereMesh.new(); spm.radius = 0.95; spm.height = 1.25
		pod.mesh = spm; pod.material_override = wreck_mat
		pod.position = Vector3(0, 0.45, 0)
		pod.rotation_degrees = Vector3(18, 12, -22)
		corpse.add_child(pod)
		# Cracked red SpiderOptic eye
		var optic = MeshInstance3D.new()
		var opm = SphereMesh.new(); opm.radius = 0.22; opm.height = 0.36
		optic.mesh = opm; optic.material_override = accent_mat
		optic.position = Vector3(0.1, 0.52, -0.82)
		corpse.add_child(optic)
		# 4 buckled/severed mechanical spider legs sprawled around
		for i in range(4):
			var s_leg = MeshInstance3D.new()
			var slm = BoxMesh.new(); slm.size = Vector3(0.22, 0.22, 1.65)
			s_leg.mesh = slm; s_leg.material_override = wreck_mat
			var ang = deg_to_rad(45.0 + i * 90.0)
			s_leg.position = Vector3(cos(ang) * 1.25, 0.22, sin(ang) * 1.25)
			s_leg.rotation = Vector3(deg_to_rad(randf_range(15, 38)), ang + randf_range(-0.3, 0.3), deg_to_rad(randf_range(-25, 25)))
			corpse.add_child(s_leg)
		# Snapped long sniper barrel
		var s_barrel = MeshInstance3D.new()
		var sbm = CylinderMesh.new(); sbm.top_radius = 0.09; sbm.bottom_radius = 0.13; sbm.height = 2.4
		s_barrel.mesh = sbm; s_barrel.material_override = dark_mat
		s_barrel.position = Vector3(0.35, 0.18, -1.35)
		s_barrel.rotation_degrees = Vector3(84, 24, 15)
		corpse.add_child(s_barrel)
		return

	if is_plague:
		wreck_mat.albedo_color = Color(0.32, 0.14, 0.16); wreck_mat.roughness = 0.85
		accent_mat.albedo_color = Color(0.84, 0.80, 0.68); accent_mat.roughness = 0.65 # Bone
	elif is_gilded:
		wreck_mat.albedo_color = Color(0.86, 0.84, 0.80); wreck_mat.roughness = 0.3
		accent_mat.albedo_color = Color(0.88, 0.70, 0.18); accent_mat.metallic = 0.9; accent_mat.roughness = 0.2
	elif is_reach:
		wreck_mat.albedo_color = Color(0.75, 0.80, 0.85); wreck_mat.metallic = 0.7; wreck_mat.roughness = 0.4
		accent_mat.albedo_color = Color(0.0, 0.6, 0.8); accent_mat.emission_enabled = true; accent_mat.emission = Color(0.0, 0.5, 0.7); accent_mat.emission_energy_multiplier = 0.6
	elif is_scrap:
		wreck_mat.albedo_color = Color(0.42, 0.24, 0.14); wreck_mat.metallic = 0.5; wreck_mat.roughness = 0.95
		accent_mat.albedo_color = Color(0.78, 0.58, 0.12); accent_mat.roughness = 0.85
	elif is_shield_tank:
		wreck_mat.albedo_color = Color(0.18, 0.24, 0.34); wreck_mat.metallic = 0.75; wreck_mat.roughness = 0.5
		accent_mat.albedo_color = Color(0.20, 0.65, 0.95); accent_mat.emission_enabled = true; accent_mat.emission = Color(0.15, 0.5, 0.85); accent_mat.emission_energy_multiplier = 0.7
	else:
		wreck_mat.albedo_color = Color(0.18, 0.22, 0.16); wreck_mat.metallic = 0.6; wreck_mat.roughness = 0.85
		accent_mat.albedo_color = Color(0.12, 0.14, 0.12); accent_mat.metallic = 0.8
		
	# Shattered/ruptured hull
	var hull = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(2.4, 0.7, 2.8) if is_heavy else Vector3(1.7, 0.65, 2.2)
	hull.mesh = hm
	hull.material_override = wreck_mat
	hull.position.y = 0.35
	hull.rotation = Vector3(deg_to_rad(randf_range(-10, 10)), deg_to_rad(randf_range(-20, 20)), deg_to_rad(randf_range(-8, 8)))
	corpse.add_child(hull)

	# Blown-off side treads / hover skirts
	for s in [-1.0, 1.0]:
		var tread = MeshInstance3D.new()
		var trm = BoxMesh.new(); trm.size = Vector3(0.42, 0.45, 2.5 if is_heavy else 2.0)
		tread.mesh = trm
		tread.material_override = accent_mat if is_reach else dark_mat
		tread.position = hull.position + Vector3(s * (1.35 if is_heavy else 1.05), -0.08, randf_range(-0.15, 0.15))
		tread.rotation_degrees = Vector3(randf_range(-12, 12), s * randf_range(8, 22), s * 18)
		corpse.add_child(tread)
	
	# Dislodged turret
	var turret = MeshInstance3D.new()
	var tm = BoxMesh.new()
	tm.size = Vector3(1.3, 0.6, 1.3) if is_heavy else Vector3(0.9, 0.5, 0.9)
	turret.mesh = tm
	turret.material_override = accent_mat if not is_plague else wreck_mat
	turret.position = hull.position + Vector3(0.35, 0.45, -0.2)
	turret.rotation = Vector3(deg_to_rad(32), deg_to_rad(55), deg_to_rad(18))
	corpse.add_child(turret)

	# Variant-specific tank wreckage details
	if is_scrap:
		# Twisted yellow/black hazard ScrapRam plow blade lying in front
		var ram = MeshInstance3D.new()
		var rmm = BoxMesh.new(); rmm.size = Vector3(2.2, 0.55, 0.25)
		ram.mesh = rmm; ram.material_override = accent_mat
		ram.position = hull.position + Vector3(0.2, -0.05, -1.65)
		ram.rotation_degrees = Vector3(25, -18, 14)
		corpse.add_child(ram)
	elif is_plague:
		# Shattered bleached bone ribs + dead Harmony eye on turret
		for i in range(4):
			var rib = MeshInstance3D.new()
			var rbm = CylinderMesh.new(); rbm.top_radius = 0.05; rbm.bottom_radius = 0.12; rbm.height = 1.25
			rib.mesh = rbm; rib.material_override = accent_mat
			var side = -1.0 if i % 2 == 0 else 1.0
			rib.position = hull.position + Vector3(side * 1.0, 0.45, -0.6 + (float(i) / 2.0) * 1.1)
			rib.rotation_degrees = Vector3(15, 0, side * -38)
			corpse.add_child(rib)
		var dead_eye = MeshInstance3D.new()
		var dem = SphereMesh.new(); dem.radius = 0.35; dem.height = 0.45
		dead_eye.mesh = dem; dead_eye.material_override = HarmonyHuskBuilderScript.get_gold_vein_material()
		dead_eye.position = turret.position + Vector3(0, 0.28, 0)
		corpse.add_child(dead_eye)
	elif is_gilded or is_shield_tank:
		# Shattered golden halo ring or dome shield emitter ring around turret
		var s_ring = MeshInstance3D.new()
		var srm = TorusMesh.new(); srm.inner_radius = 0.85; srm.outer_radius = 1.02
		s_ring.mesh = srm; s_ring.material_override = accent_mat
		s_ring.position = turret.position + Vector3(-0.15, 0.15, 0.1)
		s_ring.rotation_degrees = Vector3(28, 40, -22)
		corpse.add_child(s_ring)
	
	# Broken cannon barrel / railgun accelerator
	var cannon = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.12; cm.bottom_radius = 0.16; cm.height = 1.8
	cannon.mesh = cm
	cannon.material_override = accent_mat if is_gilded else wreck_mat
	cannon.position = hull.position + Vector3(-1.1, 0.12, 0.7)
	cannon.rotation = Vector3(deg_to_rad(85), deg_to_rad(28), deg_to_rad(45))
	corpse.add_child(cannon)
	
	# Blast scorch decal
	var scorch = MeshInstance3D.new()
	var sm = CylinderMesh.new(); sm.top_radius = 2.4; sm.bottom_radius = 2.5; sm.height = 0.02
	scorch.mesh = sm
	var scmat = StandardMaterial3D.new(); scmat.albedo_color = Color(0.06, 0.06, 0.06, 0.9); scmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scorch.material_override = scmat
	scorch.position = Vector3(0, 0.01, 0)
	corpse.add_child(scorch)

func _build_broken_mech(corpse: Node3D, parent: Node3D):
	var p_name = parent.name
	var is_reach = "Reach" in p_name
	var is_scrap = "Scrap" in p_name
	var is_walker = "Walker" in p_name
	
	var mech_mat = StandardMaterial3D.new()
	var accent_mat = StandardMaterial3D.new()
	
	if is_reach:
		# ReachMech is a white porcelain sphere core with a golden/cyan Halo ring and 4 floating wing fins!
		mech_mat.albedo_color = Color(0.88, 0.92, 0.96); mech_mat.metallic = 0.75; mech_mat.roughness = 0.25
		accent_mat.albedo_color = Color(0.0, 0.65, 0.85); accent_mat.emission_enabled = true; accent_mat.emission = Color(0.0, 0.5, 0.75); accent_mat.emission_energy_multiplier = 0.8
		var gold_mat = StandardMaterial3D.new()
		gold_mat.albedo_color = Color(0.85, 0.68, 0.20); gold_mat.metallic = 0.9; gold_mat.roughness = 0.25
		
		var core_sphere = MeshInstance3D.new()
		var csm = SphereMesh.new(); csm.radius = 0.95; csm.height = 1.7
		core_sphere.mesh = csm; core_sphere.material_override = mech_mat
		core_sphere.position = Vector3(0, 0.55, 0)
		core_sphere.rotation_degrees = Vector3(25, 15, -20)
		corpse.add_child(core_sphere)
		
		var halo = MeshInstance3D.new()
		var htm = TorusMesh.new(); htm.inner_radius = 1.25; htm.outer_radius = 1.45
		halo.mesh = htm; halo.material_override = gold_mat
		halo.position = Vector3(0.15, 0.35, -0.1)
		halo.rotation_degrees = Vector3(32, 20, -28)
		corpse.add_child(halo)
		
		for i in range(4):
			var fin = MeshInstance3D.new()
			var fnm = BoxMesh.new(); fnm.size = Vector3(0.28, 1.35, 0.55)
			fin.mesh = fnm; fin.material_override = accent_mat if i % 2 == 0 else mech_mat
			var ang = (TAU / 4.0) * i + 0.4
			fin.position = Vector3(cos(ang) * 1.45, 0.16, sin(ang) * 1.45)
			fin.rotation = Vector3(deg_to_rad(75), ang, deg_to_rad(25))
			corpse.add_child(fin)
		return
	elif is_scrap:
		# ScrapMech has a cylindrical welded boiler hull, hazard jaw, heavy pincer claw arm, and stub cannon
		mech_mat.albedo_color = Color(0.45, 0.25, 0.15); mech_mat.metallic = 0.55; mech_mat.roughness = 0.9
		accent_mat.albedo_color = Color(0.80, 0.55, 0.10); accent_mat.roughness = 0.85
		var boiler = MeshInstance3D.new()
		var blm = CylinderMesh.new(); blm.top_radius = 0.85; blm.bottom_radius = 0.95; blm.height = 1.75
		boiler.mesh = blm; boiler.material_override = mech_mat
		boiler.position = Vector3(0, 0.72, 0)
		boiler.rotation_degrees = Vector3(58, 18, -25)
		corpse.add_child(boiler)
		
		var jaw = MeshInstance3D.new()
		var jwm = BoxMesh.new(); jwm.size = Vector3(1.1, 0.35, 0.65)
		jaw.mesh = jwm; jaw.material_override = accent_mat
		jaw.position = Vector3(0.2, 0.35, -0.85)
		jaw.rotation_degrees = Vector3(15, 28, -12)
		corpse.add_child(jaw)
		
		# Severed heavy pincer claw arm & stub cannon
		for s in [-1.0, 1.0]:
			var s_arm = MeshInstance3D.new()
			var sam = BoxMesh.new(); sam.size = Vector3(0.48, 0.48, 1.45)
			s_arm.mesh = sam; s_arm.material_override = mech_mat
			s_arm.position = Vector3(s * 1.35, 0.24, 0.2)
			s_arm.rotation_degrees = Vector3(12, s * 38, s * 75)
			corpse.add_child(s_arm)
			
			var s_leg = MeshInstance3D.new()
			var slm = CylinderMesh.new(); slm.top_radius = 0.26; slm.bottom_radius = 0.32; slm.height = 1.1
			s_leg.mesh = slm; s_leg.material_override = mech_mat
			s_leg.position = Vector3(s * 0.65, 0.32, 0.65)
			s_leg.rotation_degrees = Vector3(72, 0, s * 35)
			corpse.add_child(s_leg)
		return
	elif is_walker:
		# BoxyWalker: boxy head cabin + amber visor + 4 long walker legs + 4 stub MGs
		mech_mat.albedo_color = Color(0.26, 0.30, 0.24); mech_mat.metallic = 0.65; mech_mat.roughness = 0.65
		accent_mat.albedo_color = Color(0.85, 0.50, 0.08); accent_mat.emission_enabled = true; accent_mat.emission = Color(0.65, 0.35, 0.05); accent_mat.emission_energy_multiplier = 0.6
		var cabin = MeshInstance3D.new()
		var cbm = BoxMesh.new(); cbm.size = Vector3(1.15, 1.05, 1.15)
		cabin.mesh = cbm; cabin.material_override = mech_mat
		cabin.position = Vector3(0, 0.58, 0)
		cabin.rotation_degrees = Vector3(28, 14, -22)
		corpse.add_child(cabin)
		
		var w_visor = MeshInstance3D.new()
		var wvm = BoxMesh.new(); wvm.size = Vector3(0.68, 0.18, 0.10)
		w_visor.mesh = wvm; w_visor.material_override = accent_mat
		w_visor.position = Vector3(0, 0.18, -0.56)
		cabin.add_child(w_visor)
		
		for i in range(4):
			var w_leg = MeshInstance3D.new()
			var wlm = BoxMesh.new(); wlm.size = Vector3(0.22, 1.45, 0.26)
			w_leg.mesh = wlm; w_leg.material_override = mech_mat
			var sx = -1.0 if i % 2 == 0 else 1.0
			var sz = -1.0 if i < 2 else 1.0
			w_leg.position = Vector3(sx * 0.85, 0.22, sz * 0.75)
			w_leg.rotation_degrees = Vector3(sz * 68, sx * 25, sx * 55)
			corpse.add_child(w_leg)
		return
	else:
		mech_mat.albedo_color = Color(0.22, 0.26, 0.28); mech_mat.metallic = 0.7; mech_mat.roughness = 0.6
		accent_mat.albedo_color = Color(0.18, 0.55, 0.85); accent_mat.emission_enabled = true; accent_mat.emission = Color(0.12, 0.45, 0.7); accent_mat.emission_energy_multiplier = 0.6
		
	# DominionMech: Collapsed upper chassis tilted forward on knee + shoulder pods + cockpit visor
	var torso = MeshInstance3D.new()
	var tm = BoxMesh.new(); tm.size = Vector3(1.8, 1.4, 1.4)
	torso.mesh = tm
	torso.material_override = mech_mat
	torso.position = Vector3(0, 0.8, 0)
	torso.rotation = Vector3(deg_to_rad(35), deg_to_rad(15), deg_to_rad(-18))
	corpse.add_child(torso)
	
	var visor = MeshInstance3D.new()
	var vsm = BoxMesh.new(); vsm.size = Vector3(0.85, 0.28, 0.14)
	visor.mesh = vsm; visor.material_override = accent_mat
	visor.position = Vector3(0, 0.25, -0.72)
	torso.add_child(visor)
	
	# Severed mech weapon arms lying on the ground
	for s in [-1.0, 1.0]:
		var arm = MeshInstance3D.new()
		var am = BoxMesh.new(); am.size = Vector3(0.4, 0.4, 1.6)
		arm.mesh = am
		arm.material_override = mech_mat
		arm.position = Vector3(s * 1.35, 0.22, 0.25 * s)
		arm.rotation = Vector3(deg_to_rad(10), deg_to_rad(s * 45), deg_to_rad(s * 80))
		corpse.add_child(arm)
	
	# Crumpled mechanical legs
	for s in [-1.0, 1.0]:
		var leg = MeshInstance3D.new()
		var lm = CylinderMesh.new(); lm.top_radius = 0.22; lm.bottom_radius = 0.28; lm.height = 1.2
		leg.mesh = lm
		leg.material_override = mech_mat
		leg.position = Vector3(s * 0.7, 0.4, 0.2)
		leg.rotation = Vector3(deg_to_rad(65), 0, deg_to_rad(s * 35))
		corpse.add_child(leg)

func _build_broken_aircraft(corpse: Node3D, parent: Node3D):
	var p_name: String = str(parent.name) if parent else ""
	var is_reach = "Reach" in p_name
	var is_scrap = "Scrap" in p_name
	
	var craft_mat = StandardMaterial3D.new()
	var accent_mat = StandardMaterial3D.new()
	if is_reach:
		craft_mat.albedo_color = Color(0.86, 0.90, 0.95); craft_mat.metallic = 0.75; craft_mat.roughness = 0.25
		accent_mat.albedo_color = Color(0.0, 0.65, 0.88); accent_mat.emission_enabled = true; accent_mat.emission = Color(0.0, 0.5, 0.75); accent_mat.emission_energy_multiplier = 0.8
	elif is_scrap:
		craft_mat.albedo_color = Color(0.42, 0.24, 0.14); craft_mat.metallic = 0.55; craft_mat.roughness = 0.9
		accent_mat.albedo_color = Color(0.78, 0.55, 0.10); accent_mat.roughness = 0.85
	else:
		craft_mat.albedo_color = Color(0.2, 0.22, 0.25); craft_mat.metallic = 0.8; craft_mat.roughness = 0.6
		accent_mat.albedo_color = Color(0.85, 0.55, 0.15); accent_mat.roughness = 0.4
	
	# Fuselage crashed nose-down into the dirt
	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new(); bm.top_radius = 0.15; bm.bottom_radius = 0.55; bm.height = 3.2
	body.mesh = bm
	body.material_override = craft_mat
	body.position = Vector3(0, 0.8, 0)
	body.rotation = Vector3(deg_to_rad(125), deg_to_rad(20), 0)
	corpse.add_child(body)

	# Cockpit canopy / nose detail
	var canopy = MeshInstance3D.new()
	var cpm = SphereMesh.new(); cpm.radius = 0.32; cpm.height = 0.85
	canopy.mesh = cpm; canopy.material_override = accent_mat
	canopy.position = Vector3(0, 0.2, 0.35)
	body.add_child(canopy)

	if is_scrap:
		# Bent nose propeller blades
		for i in range(2):
			var prop = MeshInstance3D.new()
			var prm = BoxMesh.new(); prm.size = Vector3(1.1, 0.04, 0.14)
			prop.mesh = prm; prop.material_override = accent_mat
			prop.position = Vector3(0.4 * i, 0.15, -1.2)
			prop.rotation_degrees = Vector3(15, 45 + i * 75, 20)
			corpse.add_child(prop)
	
	# One wing intact, one snapped wing lying nearby
	var wing1 = MeshInstance3D.new()
	var wm1 = BoxMesh.new(); wm1.size = Vector3(2.4, 0.08, 0.8)
	wing1.mesh = wm1
	wing1.material_override = craft_mat
	wing1.position = body.position + Vector3(1.2, 0.3, 0)
	wing1.rotation = body.rotation
	corpse.add_child(wing1)
	
	var wing2 = MeshInstance3D.new()
	var wm2 = BoxMesh.new(); wm2.size = Vector3(1.8, 0.08, 0.7)
	wing2.mesh = wm2
	wing2.material_override = accent_mat if is_reach else craft_mat
	wing2.position = Vector3(-1.8, 0.1, 0.8)
	wing2.rotation = Vector3(deg_to_rad(15), deg_to_rad(55), 0)
	corpse.add_child(wing2)
	
	# Skid trail scorch mark
	var skid = MeshInstance3D.new()
	var sm = BoxMesh.new(); sm.size = Vector3(1.2, 0.02, 4.5)
	skid.mesh = sm
	var skmat = StandardMaterial3D.new(); skmat.albedo_color = Color(0.06, 0.06, 0.06, 0.85); skmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	skid.material_override = skmat
	skid.position = Vector3(0, 0.01, 1.8)
	corpse.add_child(skid)

func _build_broken_beast(corpse: Node3D, parent: Node3D):
	var p_name = parent.name
	if parent.is_in_group("BeastOfHarmony") or "BeastOfHarmony" in p_name or "EyeOfHarmony" in p_name:
		var sclera_mat = StandardMaterial3D.new()
		sclera_mat.albedo_color = Color(0.82, 0.78, 0.68); sclera_mat.roughness = 0.65
		var gold_mat = HarmonyHuskBuilderScript.get_gold_vein_material()
		var dead_iris = StandardMaterial3D.new()
		dead_iris.albedo_color = Color(0.45, 0.12, 0.18); dead_iris.roughness = 0.5
		var main_eye = MeshInstance3D.new()
		var sm = SphereMesh.new(); sm.radius = 0.9; sm.height = 1.3
		main_eye.mesh = sm; main_eye.material_override = sclera_mat
		main_eye.position = Vector3(0, 0.45, 0); main_eye.scale = Vector3(1.15, 0.65, 1.15)
		corpse.add_child(main_eye)
		var ring_frag = MeshInstance3D.new()
		var tm = TorusMesh.new(); tm.inner_radius = 0.95; tm.outer_radius = 1.1
		ring_frag.mesh = tm; ring_frag.material_override = gold_mat
		ring_frag.position = Vector3(0.15, 0.18, -0.1); ring_frag.rotation_degrees = Vector3(18, 25, 12)
		corpse.add_child(ring_frag)
		for i in range(5):
			var sub = MeshInstance3D.new()
			var s_m = SphereMesh.new(); s_m.radius = 0.24; s_m.height = 0.42
			sub.mesh = s_m; sub.material_override = dead_iris if i % 2 == 0 else sclera_mat
			var ang = (TAU / 5.0) * float(i)
			sub.position = Vector3(cos(ang) * 1.25, 0.16, sin(ang) * 1.25)
			corpse.add_child(sub)
		return

	if parent.is_in_group("HarmonyInfector") or "HarmonyInfector" in p_name:
		var is_gilded_inf: bool = bool(parent.get_meta("is_gilded_harmony", false))
		var gold_mat = HarmonyHuskBuilderScript.get_gold_vein_material()
		var robe_mat = HarmonyHuskBuilderScript.get_gilded_dark_green_material() if is_gilded_inf else HarmonyHuskBuilderScript.get_husk_body_material()
		var orb_mat = HarmonyHuskBuilderScript.get_gilded_pale_blue_material() if is_gilded_inf else gold_mat
		var fallen_stalk = MeshInstance3D.new()
		var sc = CylinderMesh.new(); sc.top_radius = 0.38; sc.bottom_radius = 0.16; sc.height = 1.5
		fallen_stalk.mesh = sc; fallen_stalk.material_override = robe_mat
		fallen_stalk.position = Vector3(0, 0.28, 0); fallen_stalk.rotation_degrees = Vector3(78, 15, 10)
		corpse.add_child(fallen_stalk)
		var cracked_orb = MeshInstance3D.new()
		var om = SphereMesh.new(); om.radius = 0.36; om.height = 0.55
		cracked_orb.mesh = om; cracked_orb.material_override = orb_mat
		cracked_orb.position = Vector3(0.2, 0.25, 0.85)
		corpse.add_child(cracked_orb)
		var crown = MeshInstance3D.new()
		var ct = TorusMesh.new(); ct.inner_radius = 0.55; ct.outer_radius = 0.65
		crown.mesh = ct; crown.material_override = gold_mat
		crown.position = Vector3(0.2, 0.12, 0.85); crown.rotation_degrees = Vector3(12, 40, -18)
		corpse.add_child(crown)
		return

	if parent.is_in_group("GildedHarmony") or "GildedHarmony" in p_name:
		var gold_mat = HarmonyHuskBuilderScript.get_gold_vein_material()
		var pale_blue_mat = HarmonyHuskBuilderScript.get_gilded_pale_blue_material()
		var dark_green_mat = HarmonyHuskBuilderScript.get_gilded_dark_green_material()
		for i in range(4):
			var strand = MeshInstance3D.new()
			var sm = SphereMesh.new(); sm.radius = 0.26; sm.height = 0.45
			strand.mesh = sm
			strand.material_override = pale_blue_mat if i % 2 == 0 else dark_green_mat
			var ang = (TAU / 4.0) * float(i)
			strand.position = Vector3(cos(ang) * 0.55, 0.20, sin(ang) * 0.55)
			corpse.add_child(strand)
		var ring = MeshInstance3D.new()
		var tm = TorusMesh.new(); tm.inner_radius = 0.72; tm.outer_radius = 0.84
		ring.mesh = tm; ring.material_override = gold_mat
		ring.position = Vector3(0, 0.14, 0); ring.rotation_degrees = Vector3(14, 30, -10)
		corpse.add_child(ring)
		return

	var void_obs_mat = StandardMaterial3D.new()
	void_obs_mat.albedo_color = Color(0.12, 0.04, 0.20); void_obs_mat.metallic = 0.65; void_obs_mat.roughness = 0.35
	var void_glow_mat = StandardMaterial3D.new()
	void_glow_mat.albedo_color = Color(0.75, 0.12, 0.92); void_glow_mat.emission_enabled = true; void_glow_mat.emission = Color(0.65, 0.08, 0.85); void_glow_mat.emission_energy_multiplier = 1.2

	# 1. VOID OVERLORD
	if "Overlord" in p_name:
		var torso = MeshInstance3D.new()
		var tm = CapsuleMesh.new(); tm.radius = 1.1; tm.height = 2.8
		torso.mesh = tm; torso.material_override = void_obs_mat
		torso.position = Vector3(0, 0.65, 0); torso.rotation_degrees = Vector3(78, 12, 18)
		corpse.add_child(torso)
		
		var head = MeshInstance3D.new()
		var hm = SphereMesh.new(); hm.radius = 0.62; hm.height = 1.1
		head.mesh = hm; head.material_override = void_obs_mat
		head.position = Vector3(0.15, 0.55, -1.65)
		corpse.add_child(head)
		
		for s in [-1.0, 1.0]:
			var horn = MeshInstance3D.new()
			var hcm = CylinderMesh.new(); hcm.top_radius = 0.04; hcm.bottom_radius = 0.18; hcm.height = 1.15
			horn.mesh = hcm; horn.material_override = void_glow_mat
			horn.position = head.position + Vector3(s * 0.55, 0.35, -0.15)
			horn.rotation_degrees = Vector3(-25, 0, s * -42)
			corpse.add_child(horn)
			
			var limb = MeshInstance3D.new()
			var lbm = CapsuleMesh.new(); lbm.radius = 0.34; lbm.height = 1.85
			limb.mesh = lbm; limb.material_override = void_obs_mat
			limb.position = Vector3(s * 1.45, 0.28, -0.35)
			limb.rotation_degrees = Vector3(72, s * 35, s * 48)
			corpse.add_child(limb)
			
		for i in range(4):
			var crystal = MeshInstance3D.new()
			var crm = PrismMesh.new(); crm.size = Vector3(0.42, 0.95, 0.42)
			crystal.mesh = crm; crystal.material_override = void_glow_mat
			var ang = (TAU / 4.0) * i + 0.3
			crystal.position = Vector3(cos(ang) * 1.95, 0.22, sin(ang) * 1.95)
			crystal.rotation_degrees = Vector3(randf_range(35, 75), randf_range(0, 360), randf_range(-40, 40))
			corpse.add_child(crystal)
		return

	# 2. VOID CORRUPTOR & VOID CRAWLER (Arachnids)
	if "Corruptor" in p_name or "Crawler" in p_name:
		var is_corruptor = "Corruptor" in p_name
		var ceph = MeshInstance3D.new()
		var cpm = SphereMesh.new(); cpm.radius = 0.65 if is_corruptor else 0.55; cpm.height = 0.75
		ceph.mesh = cpm; ceph.material_override = void_obs_mat
		ceph.position = Vector3(0, 0.28, -0.35)
		ceph.rotation_degrees = Vector3(14, 8, 165) # Flipped/tilted arachnid carapace
		corpse.add_child(ceph)
		
		var abd = MeshInstance3D.new()
		var abm = SphereMesh.new(); abm.radius = 0.95 if is_corruptor else 0.65; abm.height = 1.35 if is_corruptor else 0.95
		abd.mesh = abm; abd.material_override = void_glow_mat if is_corruptor else void_obs_mat
		abd.position = Vector3(0.1, 0.32, 0.65)
		abd.rotation_degrees = Vector3(-18, 15, 22)
		corpse.add_child(abd)
		
		for s in [-1.0, 1.0]:
			var mand = MeshInstance3D.new()
			var mdm = BoxMesh.new(); mdm.size = Vector3(0.14, 0.14, 0.58)
			mand.mesh = mdm; mand.material_override = void_glow_mat
			mand.position = Vector3(s * 0.36, 0.18, -0.95)
			mand.rotation_degrees = Vector3(12, s * -32, 0)
			corpse.add_child(mand)
			
		for i in range(8):
			var leg = MeshInstance3D.new()
			var lgm = CylinderMesh.new(); lgm.top_radius = 0.04; lgm.bottom_radius = 0.09; lgm.height = 1.15
			leg.mesh = lgm; leg.material_override = void_obs_mat
			var side = -1.0 if i % 2 == 0 else 1.0
			var row: int = int(float(i) / 2.0)
			leg.position = Vector3(side * 0.78, 0.38, -0.55 + row * 0.38)
			leg.rotation_degrees = Vector3(randf_range(-25, 25), row * 12.0 * side, side * randf_range(35, 65))
			corpse.add_child(leg)
		return

	# 3. VOID STALKER & VOID SHIELD STALKER
	if "Stalker" in p_name:
		var s_body = MeshInstance3D.new()
		var sbm = CapsuleMesh.new(); sbm.radius = 0.45; sbm.height = 1.65
		s_body.mesh = sbm; s_body.material_override = void_obs_mat
		s_body.position = Vector3(0, 0.30, 0); s_body.rotation_degrees = Vector3(82, 15, 28)
		corpse.add_child(s_body)
		
		# 2 snapped glowing purple scythe blades
		for s in [-1.0, 1.0]:
			var scythe = MeshInstance3D.new()
			var scm = PrismMesh.new(); scm.size = Vector3(0.12, 1.25, 0.38)
			scythe.mesh = scm; scythe.material_override = void_glow_mat
			scythe.position = Vector3(s * 0.85, 0.14, -0.45 + s * 0.15)
			scythe.rotation_degrees = Vector3(78, s * 42, s * 65)
			corpse.add_child(scythe)
			
		for i in range(4):
			var s_leg = MeshInstance3D.new()
			var slm = CylinderMesh.new(); slm.top_radius = 0.05; slm.bottom_radius = 0.10; slm.height = 0.95
			s_leg.mesh = slm; s_leg.material_override = void_obs_mat
			var sx = -1.0 if i % 2 == 0 else 1.0
			var sz = -0.4 if i < 2 else 0.4
			s_leg.position = Vector3(sx * 0.65, 0.16, sz)
			s_leg.rotation_degrees = Vector3(68, sx * 25, sx * 55)
			corpse.add_child(s_leg)
			
		if "Shield" in p_name:
			var f_ring = MeshInstance3D.new()
			var frm = TorusMesh.new(); frm.inner_radius = 0.58; frm.outer_radius = 0.72
			f_ring.mesh = frm; f_ring.material_override = void_glow_mat
			f_ring.position = Vector3(0.15, 0.18, -0.25); f_ring.rotation_degrees = Vector3(22, 35, -18)
			corpse.add_child(f_ring)
		return

	# 4. VOID SPITTER
	if "Spitter" in p_name:
		var sac = MeshInstance3D.new()
		var scm = SphereMesh.new(); scm.radius = 0.85; scm.height = 0.75
		sac.mesh = scm; sac.material_override = void_glow_mat
		sac.position = Vector3(0, 0.25, 0.35)
		corpse.add_child(sac)
		
		var nozzle = MeshInstance3D.new()
		var nzm = CylinderMesh.new(); nzm.top_radius = 0.24; nzm.bottom_radius = 0.32; nzm.height = 1.05
		nozzle.mesh = nzm; nozzle.material_override = void_obs_mat
		nozzle.position = Vector3(0.12, 0.28, -0.55); nozzle.rotation_degrees = Vector3(72, 18, -22)
		corpse.add_child(nozzle)
		
		var ichor = MeshInstance3D.new()
		var icm = CylinderMesh.new(); icm.top_radius = 1.45; icm.bottom_radius = 1.55; icm.height = 0.03
		ichor.mesh = icm; ichor.material_override = void_glow_mat
		ichor.position = Vector3(0, 0.015, 0.15)
		corpse.add_child(ichor)
		
		for i in range(4):
			var sp_leg = MeshInstance3D.new()
			var splm = CylinderMesh.new(); splm.top_radius = 0.06; splm.bottom_radius = 0.11; splm.height = 0.75
			sp_leg.mesh = splm; sp_leg.material_override = void_obs_mat
			var a = (TAU / 4.0) * i + 0.5
			sp_leg.position = Vector3(cos(a) * 0.85, 0.14, sin(a) * 0.85)
			sp_leg.rotation_degrees = Vector3(70, a * 45.0, 35)
			corpse.add_child(sp_leg)
		return

	# 5. VOID GARGOYLE & VOIDLING
	if "Gargoyle" in p_name or "Voidling" in p_name:
		var is_garg = "Gargoyle" in p_name
		var g_body = MeshInstance3D.new()
		var gbm = CapsuleMesh.new(); gbm.radius = 0.42 if is_garg else 0.24; gbm.height = 1.15 if is_garg else 0.62
		g_body.mesh = gbm; g_body.material_override = void_obs_mat
		g_body.position = Vector3(0, 0.22, 0); g_body.rotation_degrees = Vector3(84, 15, 20)
		corpse.add_child(g_body)
		if is_garg:
			for s in [-1.0, 1.0]:
				var wing = MeshInstance3D.new()
				var wgm = PrismMesh.new(); wgm.size = Vector3(1.55, 0.06, 0.95)
				wing.mesh = wgm; wing.material_override = void_glow_mat
				wing.position = Vector3(s * 0.95, 0.12, 0.1)
				wing.rotation_degrees = Vector3(12, s * 28, s * -16)
				corpse.add_child(wing)
		else:
			for i in range(4):
				var v_leg = MeshInstance3D.new()
				var vlm = CylinderMesh.new(); vlm.top_radius = 0.03; vlm.bottom_radius = 0.05; vlm.height = 0.42
				v_leg.mesh = vlm; v_leg.material_override = void_glow_mat
				var a = (TAU / 4.0) * i
				v_leg.position = Vector3(cos(a) * 0.35, 0.08, sin(a) * 0.35)
				v_leg.rotation_degrees = Vector3(75, a * 50.0, 30)
				corpse.add_child(v_leg)
		return

	# 6. STONE OCTOPUS & ARMORED STONE OCTOPUS
	if "Octopus" in p_name:
		var stone_mat = StandardMaterial3D.new()
		stone_mat.albedo_color = Color(0.38, 0.40, 0.36); stone_mat.roughness = 0.95
		var basalt_mat = StandardMaterial3D.new()
		basalt_mat.albedo_color = Color(0.22, 0.24, 0.26); basalt_mat.roughness = 0.9
		
		# Cracked granite mantle dome slumped on ground
		var dome = MeshInstance3D.new()
		var dmm = SphereMesh.new(); dmm.radius = 1.05; dmm.height = 1.35
		dome.mesh = dmm; dome.material_override = stone_mat
		dome.position = Vector3(0, 0.48, 0); dome.rotation_degrees = Vector3(24, 15, -28)
		corpse.add_child(dome)
		
		# 8 limp stone tentacles sprawled radially
		for i in range(8):
			var tent = MeshInstance3D.new()
			var tnm = CylinderMesh.new(); tnm.top_radius = 0.10; tnm.bottom_radius = 0.24; tnm.height = 1.45
			tent.mesh = tnm; tent.material_override = stone_mat
			var ang = (TAU / 8.0) * i
			tent.position = Vector3(cos(ang) * 1.35, 0.14, sin(ang) * 1.35)
			tent.rotation = Vector3(deg_to_rad(82), ang, deg_to_rad(randf_range(-18, 18)))
			corpse.add_child(tent)
			
		if "Armored" in p_name:
			for i in range(4):
				var slab = MeshInstance3D.new()
				var slm = BoxMesh.new(); slm.size = Vector3(0.65, 0.22, 0.65)
				slab.mesh = slm; slab.material_override = basalt_mat
				var ang = (TAU / 4.0) * i + 0.4
				slab.position = Vector3(cos(ang) * 1.05, 0.35, sin(ang) * 1.05)
				slab.rotation_degrees = Vector3(32, i * 45.0, -25)
				corpse.add_child(slab)
		return

	# 7. GIANT SQUID
	if "Squid" in p_name:
		var squid_mat = StandardMaterial3D.new()
		squid_mat.albedo_color = Color(0.48, 0.12, 0.18); squid_mat.roughness = 0.65
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color(0.65, 0.45, 0.10); eye_mat.roughness = 0.4
		
		# Deflated elongated spear-mantle lying on its side
		var mantle = MeshInstance3D.new()
		var mnm = CylinderMesh.new(); mnm.top_radius = 0.18; mnm.bottom_radius = 0.85; mnm.height = 2.65
		mantle.mesh = mnm; mantle.material_override = squid_mat
		mantle.position = Vector3(0, 0.42, 0.35)
		mantle.rotation_degrees = Vector3(82, 12, 24)
		corpse.add_child(mantle)
		
		for s in [-1.0, 1.0]:
			var s_eye = MeshInstance3D.new()
			var sem = SphereMesh.new(); sem.radius = 0.24; sem.height = 0.38
			s_eye.mesh = sem; s_eye.material_override = eye_mat
			s_eye.position = Vector3(s * 0.65, 0.38, -0.55)
			corpse.add_child(s_eye)
			
		for i in range(6):
			var s_tent = MeshInstance3D.new()
			var stm = CylinderMesh.new(); stm.top_radius = 0.06; stm.bottom_radius = 0.16; stm.height = 1.55
			s_tent.mesh = stm; s_tent.material_override = squid_mat
			var spread_x = -0.75 + i * 0.30
			s_tent.position = Vector3(spread_x, 0.12, -1.45)
			s_tent.rotation_degrees = Vector3(86, spread_x * 22.0, randf_range(-15, 15))
			corpse.add_child(s_tent)
		return

	# 8. SKY BEETLE & ARMORED SKY BEETLE
	if "Beetle" in p_name:
		var carapace_mat = StandardMaterial3D.new()
		carapace_mat.albedo_color = Color(0.16, 0.38, 0.18); carapace_mat.metallic = 0.45; carapace_mat.roughness = 0.35
		var wing_mat = StandardMaterial3D.new()
		wing_mat.albedo_color = Color(0.65, 0.82, 0.75, 0.48); wing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var chitin_armor_mat = StandardMaterial3D.new()
		chitin_armor_mat.albedo_color = Color(0.45, 0.32, 0.16); chitin_armor_mat.metallic = 0.55; chitin_armor_mat.roughness = 0.4
		
		var shell = MeshInstance3D.new()
		var shm = SphereMesh.new(); shm.radius = 0.85; shm.height = 1.15
		shell.mesh = shm; shell.material_override = carapace_mat
		shell.position = Vector3(0, 0.38, 0)
		shell.scale = Vector3(1.1, 0.65, 1.45)
		shell.rotation_degrees = Vector3(15, 12, 145) # Rolled onto its back/side
		corpse.add_child(shell)
		
		for s in [-1.0, 1.0]:
			var b_wing = MeshInstance3D.new()
			var bwm = BoxMesh.new(); bwm.size = Vector3(1.45, 0.03, 0.75)
			b_wing.mesh = bwm; b_wing.material_override = wing_mat
			b_wing.position = Vector3(s * 1.05, 0.16, 0.15)
			b_wing.rotation_degrees = Vector3(12, s * 32, s * -18)
			corpse.add_child(b_wing)
			
		for i in range(6):
			var b_leg = MeshInstance3D.new()
			var blm = CylinderMesh.new(); blm.top_radius = 0.04; blm.bottom_radius = 0.08; blm.height = 0.85
			b_leg.mesh = blm; b_leg.material_override = chitin_armor_mat
			var side = -1.0 if i % 2 == 0 else 1.0
			var row: int = int(float(i) / 2.0)
			b_leg.position = Vector3(side * 0.68, 0.45, -0.45 + row * 0.45)
			b_leg.rotation_degrees = Vector3(randf_range(-20, 20), 0, side * 38)
			corpse.add_child(b_leg)
			
		if "Armored" in p_name:
			for i in range(3):
				var c_plate = MeshInstance3D.new()
				var cpm = BoxMesh.new(); cpm.size = Vector3(0.95, 0.18, 0.48)
				c_plate.mesh = cpm; c_plate.material_override = chitin_armor_mat
				c_plate.position = Vector3(randf_range(-0.6, 0.6), 0.18, -0.5 + i * 0.5)
				c_plate.rotation_degrees = Vector3(22, i * 35.0, -28)
				corpse.add_child(c_plate)
		return

	# 9. SKY JELLYFISH
	if "Jellyfish" in p_name:
		var bell_mat = StandardMaterial3D.new()
		bell_mat.albedo_color = Color(0.18, 0.75, 0.92, 0.55); bell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bell_mat.emission_enabled = true; bell_mat.emission = Color(0.12, 0.55, 0.75); bell_mat.emission_energy_multiplier = 0.7
		
		# Deflated translucent bell dome pooled on ground
		var bell = MeshInstance3D.new()
		var blm = SphereMesh.new(); blm.radius = 1.15; blm.height = 0.55
		bell.mesh = blm; bell.material_override = bell_mat
		bell.position = Vector3(0, 0.18, 0)
		corpse.add_child(bell)
		
		for i in range(6):
			var tendril = MeshInstance3D.new()
			var tdm = CylinderMesh.new(); tdm.top_radius = 0.04; tdm.bottom_radius = 0.08; tdm.height = 1.45
			tendril.mesh = tdm; tendril.material_override = bell_mat
			var ang = (TAU / 6.0) * i
			tendril.position = Vector3(cos(ang) * 0.95, 0.06, sin(ang) * 0.95)
			tendril.rotation = Vector3(deg_to_rad(86), ang + 0.4, 0)
			corpse.add_child(tendril)
		return

	# 10. RIMWORLDER MONSTROUS & ARMORED MONSTROUS & MUTANT
	if "Monstrous" in p_name or "Mutant" in p_name:
		var is_monstrous = "Monstrous" in p_name
		var hide_mat = StandardMaterial3D.new()
		hide_mat.albedo_color = Color(0.36, 0.28, 0.22); hide_mat.roughness = 0.85
		var bone_mat = StandardMaterial3D.new()
		bone_mat.albedo_color = Color(0.85, 0.82, 0.72); bone_mat.roughness = 0.65
		var pustule_mat = StandardMaterial3D.new()
		pustule_mat.albedo_color = Color(0.38, 0.88, 0.18); pustule_mat.emission_enabled = true; pustule_mat.emission = Color(0.3, 0.75, 0.12); pustule_mat.emission_energy_multiplier = 0.9
		
		var m_torso = MeshInstance3D.new()
		var mtm = CapsuleMesh.new()
		mtm.radius = 0.78 if is_monstrous else 0.42
		mtm.height = 1.95 if is_monstrous else 1.15
		m_torso.mesh = mtm; m_torso.material_override = hide_mat
		m_torso.position = Vector3(0, 0.42 if is_monstrous else 0.24, 0)
		m_torso.rotation_degrees = Vector3(80, 14, 26)
		corpse.add_child(m_torso)
		
		for s in [-1.0, 1.0]:
			var m_arm = MeshInstance3D.new()
			var mam = CapsuleMesh.new()
			var is_big_arm = is_monstrous or (s > 0)
			mam.radius = 0.34 if is_monstrous else (0.24 if is_big_arm else 0.12)
			mam.height = 1.55 if is_monstrous else (1.15 if is_big_arm else 0.75)
			m_arm.mesh = mam; m_arm.material_override = hide_mat
			m_arm.position = Vector3(s * (1.05 if is_monstrous else 0.62), 0.24, -0.25)
			m_arm.rotation_degrees = Vector3(74, s * 38, s * 52)
			corpse.add_child(m_arm)
			
			if is_big_arm:
				var claw = MeshInstance3D.new()
				var clm = PrismMesh.new(); clm.size = Vector3(0.32, 0.52, 0.32)
				claw.mesh = clm; claw.material_override = bone_mat
				claw.position = Vector3(0, -0.65, 0)
				m_arm.add_child(claw)
				
		if "Armored" in p_name:
			for i in range(4):
				var spike = MeshInstance3D.new()
				var spm = CylinderMesh.new(); spm.top_radius = 0.04; spm.bottom_radius = 0.20; spm.height = 0.85
				spike.mesh = spm; spike.material_override = bone_mat
				spike.position = Vector3(randf_range(-0.5, 0.5), 0.55, -0.6 + i * 0.42)
				spike.rotation_degrees = Vector3(32, i * 40.0, -28)
				corpse.add_child(spike)
		elif not is_monstrous:
			for i in range(3):
				var pust = MeshInstance3D.new()
				var psm = SphereMesh.new(); psm.radius = 0.16; psm.height = 0.22
				pust.mesh = psm; pust.material_override = pustule_mat
				pust.position = Vector3(-0.15 + i * 0.18, 0.32, -0.2 + i * 0.22)
				corpse.add_child(pust)
		return

	# 11. RIMWORLDER LEVIATHAN
	if "Leviathan" in p_name:
		var lev_mat = StandardMaterial3D.new()
		lev_mat.albedo_color = Color(0.28, 0.22, 0.16); lev_mat.roughness = 0.92
		var tusk_mat = StandardMaterial3D.new()
		tusk_mat.albedo_color = Color(0.85, 0.80, 0.68); tusk_mat.roughness = 0.6
		
		var l_body = MeshInstance3D.new()
		var lbm = CapsuleMesh.new(); lbm.radius = 1.45; lbm.height = 3.8
		l_body.mesh = lbm; l_body.material_override = lev_mat
		l_body.position = Vector3(0, 0.95, 0)
		l_body.rotation_degrees = Vector3(84, 10, 68) # Massive behemoth collapsed on its side
		corpse.add_child(l_body)
		
		var skull = MeshInstance3D.new()
		var skm = BoxMesh.new(); skm.size = Vector3(1.55, 1.25, 1.85)
		skull.mesh = skm; skull.material_override = tusk_mat
		skull.position = Vector3(0.25, 0.68, -2.15)
		skull.rotation_degrees = Vector3(18, 22, -32)
		corpse.add_child(skull)
		
		for s in [-1.0, 1.0]:
			var tusk = MeshInstance3D.new()
			var tkm = CylinderMesh.new(); tkm.top_radius = 0.05; tkm.bottom_radius = 0.22; tkm.height = 1.65
			tusk.mesh = tkm; tusk.material_override = tusk_mat
			tusk.position = skull.position + Vector3(s * 0.85, -0.1, -0.85)
			tusk.rotation_degrees = Vector3(55, s * 25, s * -35)
			corpse.add_child(tusk)
			
		for i in range(4):
			var l_leg = MeshInstance3D.new()
			var llm = CylinderMesh.new(); llm.top_radius = 0.42; llm.bottom_radius = 0.52; llm.height = 1.95
			l_leg.mesh = llm; l_leg.material_override = lev_mat
			var sx = -1.0 if i % 2 == 0 else 1.0
			var sz = -1.1 if i < 2 else 1.1
			l_leg.position = Vector3(sx * 1.65, 0.42, sz)
			l_leg.rotation_degrees = Vector3(12, sz * 18, sx * 75)
			corpse.add_child(l_leg)
		return

	# 12. SCORPION, SWARM ANT & BEAST DIGESTIVE CELL
	if "Digestive" in p_name:
		var pod_mat = StandardMaterial3D.new()
		pod_mat.albedo_color = Color(0.42, 0.16, 0.22); pod_mat.roughness = 0.8
		var acid_mat = StandardMaterial3D.new()
		acid_mat.albedo_color = Color(0.25, 0.92, 0.18, 0.85); acid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		acid_mat.emission_enabled = true; acid_mat.emission = Color(0.2, 0.75, 0.12); acid_mat.emission_energy_multiplier = 1.2
		var acid_pool = MeshInstance3D.new()
		var apm = CylinderMesh.new(); apm.top_radius = 1.35; apm.bottom_radius = 1.45; apm.height = 0.04
		acid_pool.mesh = apm; acid_pool.material_override = acid_mat
		acid_pool.position = Vector3(0, 0.02, 0)
		corpse.add_child(acid_pool)
		for i in range(4):
			var flap = MeshInstance3D.new()
			var flm = SphereMesh.new(); flm.radius = 0.45; flm.height = 0.35
			flap.mesh = flm; flap.material_override = pod_mat
			var a = (TAU / 4.0) * i
			flap.position = Vector3(cos(a) * 0.65, 0.16, sin(a) * 0.65)
			corpse.add_child(flap)
		return

	if "Wildlife" in p_name or parent.is_in_group("WildlifeUnits"):
		var vp = parent.get_node_or_null("VisualPivot")
		var anim_root = vp.get_node_or_null("AnimalModelRoot") if vp else null
		if anim_root:
			var dup = anim_root.duplicate()
			dup.position = Vector3(0, 0.14, 0)
			dup.rotation_degrees = Vector3(0, randf_range(-25.0, 25.0), 82.0)
			corpse.add_child(dup)
			return

	var is_ant = "Ant" in p_name
	var is_scorpion = "Scorpion" in p_name
	var is_spiker = "Spiker" in p_name
	
	var beast_mat = StandardMaterial3D.new()
	if is_spiker or "Void" in p_name:
		beast_mat.albedo_color = Color(0.18, 0.04, 0.28); beast_mat.metallic = 0.5
	elif is_scorpion:
		beast_mat.albedo_color = Color(0.32, 0.22, 0.12); beast_mat.roughness = 0.65
	elif is_ant:
		beast_mat.albedo_color = Color(0.22, 0.14, 0.10); beast_mat.roughness = 0.55
	else:
		beast_mat.albedo_color = Color(0.28, 0.22, 0.16); beast_mat.roughness = 0.9
		
	var b_scale = 0.52 if is_ant else (0.90 if is_scorpion else 1.2)
	corpse.scale = Vector3(b_scale, b_scale, b_scale)
	
	# Carcass thorax/mantle
	var carcass = MeshInstance3D.new()
	var cm = SphereMesh.new(); cm.radius = 0.7; cm.height = 0.9
	carcass.mesh = cm
	carcass.material_override = beast_mat
	carcass.position.y = 0.25
	carcass.scale = Vector3(1.3, 0.65, 1.7)
	carcass.rotation = Vector3(deg_to_rad(18), deg_to_rad(randf_range(-15, 15)), deg_to_rad(randf_range(25, 45)))
	corpse.add_child(carcass)
	
	# Broken legs / chitin fragments
	for i in range(6 if (is_ant or is_scorpion) else 4):
		var frag = MeshInstance3D.new()
		var fm = CylinderMesh.new(); fm.top_radius = 0.04; fm.bottom_radius = 0.12; fm.height = 0.85
		frag.mesh = fm
		frag.material_override = beast_mat
		var a = (TAU / float(6 if (is_ant or is_scorpion) else 4)) * i
		frag.position = Vector3(cos(a) * 0.95, 0.08, sin(a) * 0.95)
		frag.rotation = Vector3(deg_to_rad(randf_range(65, 85)), randf() * TAU, deg_to_rad(randf_range(-30, 30)))
		corpse.add_child(frag)

	if is_scorpion:
		# Broken segmented stinger tail & front pincers
		for s in [-1.0, 1.0]:
			var pincer = MeshInstance3D.new()
			var pnm = BoxMesh.new(); pnm.size = Vector3(0.32, 0.16, 0.55)
			pincer.mesh = pnm; pincer.material_override = beast_mat
			pincer.position = Vector3(s * 0.55, 0.14, -1.05)
			pincer.rotation_degrees = Vector3(10, s * -28, 0)
			corpse.add_child(pincer)
		var stinger = MeshInstance3D.new()
		var stm = CylinderMesh.new(); stm.top_radius = 0.04; stm.bottom_radius = 0.18; stm.height = 1.25
		stinger.mesh = stm; stinger.material_override = beast_mat
		stinger.position = Vector3(0.25, 0.22, 1.15)
		stinger.rotation_degrees = Vector3(72, 24, -35)
		corpse.add_child(stinger)
	elif is_ant:
		# Ant head & gaster abdomen segments
		var ant_head = MeshInstance3D.new()
		var ahm = SphereMesh.new(); ahm.radius = 0.42; ahm.height = 0.65
		ant_head.mesh = ahm; ant_head.material_override = beast_mat
		ant_head.position = Vector3(0, 0.22, -0.95)
		corpse.add_child(ant_head)
		
	if is_spiker:
		var shard_mat = StandardMaterial3D.new()
		shard_mat.albedo_color = Color(0.85, 0.15, 0.95); shard_mat.emission_enabled = true; shard_mat.emission = Color(0.7, 0.1, 0.8)
		for s in range(4):
			var shard = MeshInstance3D.new()
			var shm = PrismMesh.new(); shm.size = Vector3(0.3, 0.85, 0.3)
			shard.mesh = shm
			shard.material_override = shard_mat
			shard.position = Vector3(randf_range(-1.2, 1.2), 0.15, randf_range(-1.2, 1.2))
			shard.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
			corpse.add_child(shard)


# --- Shield & Armor Visuals and Lifecycle Management ---

func setup_shield_and_armor(p_max_shield: float, p_shield_type: String, p_max_armor: float, p_armor_style: String, p_shield_color: Color = Color(0.2, 0.75, 1.0, 0.45), p_shield_recharge_rate: float = 0.0):
	max_shield = p_max_shield
	current_shield = p_max_shield
	shield_type = p_shield_type
	shield_color = p_shield_color
	shield_recharge_rate = p_shield_recharge_rate
	max_armor = p_max_armor
	current_armor = p_max_armor
	armor_style = p_armor_style
	_setup_shield_and_armor_visuals()
	_refresh_hp_visuals()

func _refresh_shield_bar():
	if shield_bar and max_shield > 0.0:
		shield_bar.max_value = max_shield
		shield_bar.value = current_shield
		if current_shield <= 0.0:
			shield_bar.modulate = Color(1, 0.3, 0.3, 0.4)
		else:
			shield_bar.modulate = Color(1, 1, 1, 1)

func _refresh_armor_bar():
	if armor_bar and max_armor > 0.0:
		armor_bar.max_value = max_armor
		armor_bar.value = current_armor
		if current_armor <= 0.0:
			armor_bar.modulate = Color(0.5, 0.5, 0.5, 0.3)
		else:
			armor_bar.modulate = Color(1, 1, 1, 1)

func _flash_shield_hit():
	if shield_mesh_root and is_instance_valid(shield_mesh_root):
		var mesh_inst: MeshInstance3D = null
		if shield_mesh_root.has_node("ShieldBubble"):
			mesh_inst = shield_mesh_root.get_node("ShieldBubble") as MeshInstance3D
		elif shield_mesh_root.has_node("FrontalBarrier"):
			mesh_inst = shield_mesh_root.get_node("FrontalBarrier") as MeshInstance3D
		if mesh_inst and mesh_inst.material_override and mesh_inst.material_override is StandardMaterial3D:
			var mat = mesh_inst.material_override as StandardMaterial3D
			mat.emission_energy_multiplier = 4.5
			var tw = mesh_inst.create_tween()
			if tw:
				tw.tween_property(mat, "emission_energy_multiplier", 1.5, 0.14)

func _break_shield():
	emit_signal("shield_broken")
	if shield_mesh_root and is_instance_valid(shield_mesh_root):
		var tw = shield_mesh_root.create_tween()
		if tw:
			tw.tween_property(shield_mesh_root, "scale", Vector3(0.05, 0.05, 0.05), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_callback(func(): shield_mesh_root.visible = false)
		else:
			shield_mesh_root.visible = false
	var parent_u = get_parent()
	if parent_u and is_instance_valid(parent_u):
		for s_node_name in ["HardlightBuckler", "VoidFocusRing", "GoldShieldRing"]:
			var found_s = parent_u.find_child(s_node_name, true, false)
			if found_s is Node3D:
				found_s.visible = false
		var attach_t = shield_mesh_root.get_parent() if (shield_mesh_root and shield_mesh_root.get_parent()) else parent_u
		var broken_sh = attach_t.get_node_or_null("BrokenShieldStateRoot")
		if broken_sh == null:
			broken_sh = Node3D.new()
			broken_sh.name = "BrokenShieldStateRoot"
			var arc_sparks = CPUParticles3D.new()
			arc_sparks.name = "BrokenShieldSparks"
			arc_sparks.amount = 6
			arc_sparks.lifetime = 0.35
			arc_sparks.spread = 180.0
			arc_sparks.gravity = Vector3(0, -1.5, 0)
			arc_sparks.initial_velocity_min = 1.2
			arc_sparks.initial_velocity_max = 2.6
			var sp_box = BoxMesh.new(); sp_box.size = Vector3(0.05, 0.05, 0.14)
			var sp_mat = StandardMaterial3D.new()
			sp_mat.albedo_color = Color(shield_color.r, shield_color.g, shield_color.b)
			sp_mat.emission_enabled = true
			sp_mat.emission = Color(shield_color.r, shield_color.g, shield_color.b)
			sp_mat.emission_energy_multiplier = 3.5
			arc_sparks.mesh = sp_box
			arc_sparks.material_override = sp_mat
			arc_sparks.position = Vector3(0, 1.35, 0)
			broken_sh.add_child(arc_sparks)
			attach_t.add_child(broken_sh)
		broken_sh.visible = true

func _restore_shield():
	emit_signal("shield_recharged")
	if shield_mesh_root and is_instance_valid(shield_mesh_root):
		shield_mesh_root.visible = true
		shield_mesh_root.scale = Vector3(0.2, 0.2, 0.2)
		var tw = shield_mesh_root.create_tween()
		if tw:
			tw.tween_property(shield_mesh_root, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			shield_mesh_root.scale = Vector3.ONE
	var parent_u = get_parent()
	if parent_u and is_instance_valid(parent_u):
		for s_node_name in ["HardlightBuckler", "VoidFocusRing", "GoldShieldRing"]:
			var found_s = parent_u.find_child(s_node_name, true, false)
			if found_s is Node3D:
				found_s.visible = true
		var broken_sh = parent_u.find_child("BrokenShieldStateRoot", true, false)
		if broken_sh is Node3D:
			broken_sh.visible = false

func _flash_armor_hit():
	var p = get_parent()
	if p is Node3D and is_inside_tree():
		var tree = get_tree()
		var root_s = tree.current_scene if (tree and tree.current_scene) else p
		if root_s:
			var spark = MeshInstance3D.new()
			var sm = SphereMesh.new()
			sm.radius = 0.2
			sm.height = 0.2
			spark.mesh = sm
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.8, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.8, 0.2)
			mat.emission_energy_multiplier = 4.0
			spark.material_override = mat
			root_s.add_child(spark)
			spark.global_position = p.global_position + Vector3(randf_range(-0.4, 0.4), 1.2, randf_range(-0.4, 0.4))
			var tw = spark.create_tween()
			if tw:
				tw.tween_property(spark, "scale", Vector3(0.01, 0.01, 0.01), 0.12)
				tw.tween_callback(spark.queue_free)
			else:
				spark.queue_free()

func _break_armor():
	if is_armor_broken: return
	is_armor_broken = true
	emit_signal("armor_broken")
	
	var plates_to_shatter: Array[MeshInstance3D] = []
	if armor_plates_root and is_instance_valid(armor_plates_root):
		for plate in armor_plates_root.get_children():
			if plate is MeshInstance3D and plate.visible:
				plates_to_shatter.append(plate)
	var parent_u = get_parent()
	if parent_u and is_instance_valid(parent_u):
		var extra_armor_names = ["BoneArmorShell", "CarapaceLeft", "CarapaceRight", "BoneCrest", "LeftArmorPlate", "RightArmorPlate", "FrontPlowPlate", "TopCageArmor", "ShoulderArmorL", "ShoulderArmorR", "HardenedCarapace", "StonePlating", "BoneArmorRibs"]
		for a_name in extra_armor_names:
			var found = parent_u.find_child(a_name, true, false)
			if found is MeshInstance3D and found.visible:
				plates_to_shatter.append(found)

	if plates_to_shatter.size() > 0:
		var tree: SceneTree = null
		if is_inside_tree():
			tree = get_tree()
		var root_s = tree.current_scene if (tree and tree.current_scene) else parent_u
		for plate in plates_to_shatter:
			if root_s and is_inside_tree():
				var debris = MeshInstance3D.new()
				debris.mesh = plate.mesh
				debris.material_override = plate.material_override if plate.material_override else plate.get_surface_override_material(0)
				debris.transform = plate.global_transform
				root_s.add_child(debris)
				
				var tw = debris.create_tween()
				if tw:
					var fly_dir = Vector3(randf_range(-3.0, 3.0), randf_range(2.0, 4.5), randf_range(-3.0, 3.0))
					tw.parallel().tween_property(debris, "global_position", debris.global_position + fly_dir, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					tw.parallel().tween_property(debris, "rotation_degrees", debris.rotation_degrees + Vector3(randf_range(-120, 120), randf_range(-180, 180), randf_range(-120, 120)), 0.5)
					tw.parallel().tween_property(debris, "scale", Vector3(0.01, 0.01, 0.01), 0.25).set_delay(0.25)
					tw.tween_callback(debris.queue_free)
				else:
					debris.queue_free()
			plate.visible = false

	# Leave jagged broken-armor remnants / scorched impact scars on the unit so it visibly looks broken-armored
	if parent_u and is_instance_valid(parent_u):
		var attach_t = parent_u.get_node_or_null("VisualPivot")
		if not attach_t: attach_t = parent_u.get_node_or_null("Visuals")
		if not attach_t: attach_t = parent_u.get_node_or_null("MeshInstance3D")
		if not attach_t: attach_t = parent_u
		if attach_t.get_node_or_null("BrokenArmorRemnants") == null:
			var rem_root = Node3D.new()
			rem_root.name = "BrokenArmorRemnants"
			var scar_mat = StandardMaterial3D.new()
			scar_mat.albedo_color = Color(0.16, 0.14, 0.12) if armor_style != "BONE" else Color(0.55, 0.50, 0.42)
			scar_mat.roughness = 0.92
			for i in range(4):
				var stub = MeshInstance3D.new()
				var sbm = PrismMesh.new(); sbm.size = Vector3(0.24, 0.28, 0.18)
				stub.mesh = sbm
				stub.material_override = scar_mat
				var side = -1.0 if i % 2 == 0 else 1.0
				stub.position = Vector3(side * 0.45, 1.15 + (float(i) / 2.0) * 0.35, -0.25 + (i % 2) * 0.35)
				stub.rotation_degrees = Vector3(25 * side, i * 45.0, side * -32)
				rem_root.add_child(stub)
			attach_t.add_child(rem_root)

func _setup_shield_and_armor_visuals():
	var parent = get_parent()
	if not parent or not is_instance_valid(parent): return
	
	var attach_target = parent.get_node_or_null("VisualPivot")
	if not attach_target: attach_target = parent.get_node_or_null("Visuals")
	if not attach_target: attach_target = parent.get_node_or_null("MeshInstance3D")
	if not attach_target: attach_target = parent

	# 1. SHIELD VISUALS
	if (max_shield > 0.0 or shield_type != "NONE") and shield_mesh_root == null:
		shield_mesh_root = Node3D.new()
		shield_mesh_root.name = "ShieldVisualRoot"
		attach_target.add_child(shield_mesh_root)
		
		var rad = 1.6
		if "Tank" in parent.name or "Mech" in parent.name: rad = 2.8
		elif "Overlord" in parent.name or "Monstrous" in parent.name or "Octopus" in parent.name: rad = 3.6
		elif "Base" in parent.name: rad = 6.5
		elif "Tower" in parent.name: rad = 3.8
		
		var center_y = 1.4
		if "Tank" in parent.name: center_y = 1.5
		elif "Overlord" in parent.name: center_y = 4.0
		elif "Octopus" in parent.name: center_y = 1.6
		
		if shield_type == "360":
			var bubble = MeshInstance3D.new()
			bubble.name = "ShieldBubble"
			var s_mesh = SphereMesh.new()
			s_mesh.radius = rad
			s_mesh.height = rad * 2.0
			bubble.mesh = s_mesh
			bubble.position = Vector3(0, center_y, 0)
			
			var s_mat = StandardMaterial3D.new()
			s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			s_mat.albedo_color = Color(shield_color.r, shield_color.g, shield_color.b, 0.22)
			s_mat.emission_enabled = true
			s_mat.emission = Color(shield_color.r, shield_color.g, shield_color.b)
			s_mat.emission_energy_multiplier = 1.5
			s_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			s_mat.roughness = 0.1
			s_mat.metallic = 0.1
			bubble.material_override = s_mat
			shield_mesh_root.add_child(bubble)
			
			shield_ring_node = MeshInstance3D.new()
			shield_ring_node.name = "ShieldEquatorRing"
			var t_mesh = TorusMesh.new()
			t_mesh.outer_radius = rad * 1.04
			t_mesh.inner_radius = rad * 0.96
			shield_ring_node.mesh = t_mesh
			shield_ring_node.position = Vector3(0, center_y, 0)
			var r_mat = StandardMaterial3D.new()
			r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			r_mat.albedo_color = Color(shield_color.r, shield_color.g, shield_color.b, 0.7)
			r_mat.emission_enabled = true
			r_mat.emission = Color(shield_color.r, shield_color.g, shield_color.b)
			r_mat.emission_energy_multiplier = 2.5
			shield_ring_node.material_override = r_mat
			shield_mesh_root.add_child(shield_ring_node)
			
		elif shield_type == "FRONT":
			var barrier = MeshInstance3D.new()
			barrier.name = "FrontalBarrier"
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(1.7, 1.8, 0.12)
			barrier.mesh = b_mesh
			barrier.position = Vector3(0, center_y, -rad * 0.75)
			
			var b_mat = StandardMaterial3D.new()
			b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			b_mat.albedo_color = Color(shield_color.r, shield_color.g, shield_color.b, 0.5)
			b_mat.emission_enabled = true
			b_mat.emission = Color(shield_color.r, shield_color.g, shield_color.b)
			b_mat.emission_energy_multiplier = 2.8
			b_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			barrier.material_override = b_mat
			shield_mesh_root.add_child(barrier)
			
			for side in [-1.0, 1.0]:
				var emitter = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.08
				cyl.bottom_radius = 0.08
				cyl.height = 1.8
				emitter.mesh = cyl
				var em_mat = StandardMaterial3D.new()
				em_mat.albedo_color = Color(0.2, 0.25, 0.3)
				em_mat.metallic = 0.9
				emitter.material_override = em_mat
				emitter.position = Vector3(side * 0.88, center_y, -rad * 0.75)
				shield_mesh_root.add_child(emitter)

	# 2. BREAKABLE ARMOR VISUALS
	if (max_armor > 0.0 or armor_style != "NONE") and armor_plates_root == null:
		armor_plates_root = Node3D.new()
		armor_plates_root.name = "ArmorPlatesRoot"
		attach_target.add_child(armor_plates_root)
		_populate_armor_plates(armor_plates_root, parent)

func _populate_armor_plates(root_node: Node3D, _parent: Node):
	if armor_style == "SCRAP":
		var scrap_mat = StandardMaterial3D.new()
		scrap_mat.albedo_color = Color(0.48, 0.35, 0.24)
		scrap_mat.metallic = 0.8
		scrap_mat.roughness = 0.65
		
		var chest = MeshInstance3D.new()
		chest.name = "ScrapChestPlate"
		var c_mesh = BoxMesh.new(); c_mesh.size = Vector3(1.1, 0.95, 0.22)
		chest.mesh = c_mesh
		chest.material_override = scrap_mat
		chest.position = Vector3(0, 1.5, -0.42)
		root_node.add_child(chest)
		
		for side in [-1.0, 1.0]:
			var pauldron = MeshInstance3D.new()
			pauldron.name = "ScrapPauldron_" + ("L" if side < 0 else "R")
			var p_mesh = BoxMesh.new(); p_mesh.size = Vector3(0.55, 0.42, 0.55)
			pauldron.mesh = p_mesh
			pauldron.material_override = scrap_mat
			pauldron.position = Vector3(side * 0.85, 2.1, 0)
			pauldron.rotation_degrees = Vector3(0, 0, side * -20)
			root_node.add_child(pauldron)
			
			var greave = MeshInstance3D.new()
			greave.name = "ScrapGreave_" + ("L" if side < 0 else "R")
			var g_mesh = BoxMesh.new(); g_mesh.size = Vector3(0.35, 0.65, 0.2)
			greave.mesh = g_mesh
			greave.material_override = scrap_mat
			greave.position = Vector3(side * 0.35, 0.65, -0.28)
			root_node.add_child(greave)

	elif armor_style == "STONE":
		var stone_mat = StandardMaterial3D.new()
		stone_mat.albedo_color = Color(0.30, 0.32, 0.33)
		stone_mat.roughness = 0.95
		
		for i in range(3):
			var plate = MeshInstance3D.new()
			plate.name = "BasaltPlate_" + str(i)
			var s_mesh = BoxMesh.new(); s_mesh.size = Vector3(1.1 - i * 0.2, 0.3, 1.1 - i * 0.2)
			plate.mesh = s_mesh
			plate.material_override = stone_mat
			plate.position = Vector3(0, 1.6 + i * 0.25, 0)
			root_node.add_child(plate)
			
		for angle in [0, 90, 180, 270]:
			var cuff = MeshInstance3D.new()
			cuff.name = "StoneCuff_" + str(angle)
			var b = BoxMesh.new(); b.size = Vector3(0.45, 0.45, 0.45)
			cuff.mesh = b
			cuff.material_override = stone_mat
			var rad_a = deg_to_rad(angle)
			cuff.position = Vector3(cos(rad_a) * 0.95, 0.7, sin(rad_a) * 0.95)
			root_node.add_child(cuff)

	elif armor_style == "CHITIN":
		var chitin_mat = StandardMaterial3D.new()
		chitin_mat.albedo_color = Color(0.32, 0.22, 0.14)
		chitin_mat.roughness = 0.35
		chitin_mat.metallic = 0.3
		
		for i in range(4):
			var c_plate = MeshInstance3D.new()
			c_plate.name = "ChitinPlate_" + str(i)
			var b = BoxMesh.new(); b.size = Vector3(1.4 - i * 0.15, 0.28, 0.6)
			c_plate.mesh = b
			c_plate.material_override = chitin_mat
			c_plate.position = Vector3(0, 1.2 + i * 0.15, -0.6 + i * 0.5)
			root_node.add_child(c_plate)

	elif armor_style == "BONE":
		var bone_mat = StandardMaterial3D.new()
		bone_mat.albedo_color = Color(0.85, 0.82, 0.72)
		bone_mat.roughness = 0.75
		
		for i in range(5):
			var spike = MeshInstance3D.new()
			spike.name = "BoneSpike_" + str(i)
			var c = CylinderMesh.new(); c.top_radius = 0.04; c.bottom_radius = 0.22; c.height = 0.85
			spike.mesh = c
			spike.material_override = bone_mat
			spike.position = Vector3(0, 1.8 + i * 0.1, -1.0 + i * 0.55)
			spike.rotation_degrees = Vector3(25.0, 0, 0)
			root_node.add_child(spike)

	elif armor_style == "REACTIVE":
		var react_mat = StandardMaterial3D.new()
		react_mat.albedo_color = Color(0.24, 0.30, 0.38)
		react_mat.metallic = 0.85
		react_mat.roughness = 0.4
		for side in [-1.0, 1.0]:
			var r_block = MeshInstance3D.new()
			r_block.name = "ReactiveBlock_" + ("L" if side < 0 else "R")
			var b = BoxMesh.new(); b.size = Vector3(0.5, 0.7, 0.2)
			r_block.mesh = b
			r_block.material_override = react_mat
			r_block.position = Vector3(side * 0.45, 1.6, -0.4)
			root_node.add_child(r_block)

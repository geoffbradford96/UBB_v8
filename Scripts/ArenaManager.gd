extends Node3D
class_name ArenaManager

@export var max_requisition: float = 100.0
var requisition_rate: float = 0.5

var active_biome: String = "SUNNY_PLAINS"
var solar_beam_timer: float = 15.0
var current_solar_beam: Node3D = null

var match_timer: float = 600.0
var sudden_death_active: bool = false
var _last_displayed_second: int = -1
var _cached_timer_str: String = ""
var beast_timer: float = 0.0
var beast_spawn_interval: float = 5.0
var beast_tentacle_scene = preload("res://Scenes/BeastTentacle.tscn")
var beast_mouth_scene = preload("res://Scenes/BeastMouth.tscn")
const StealthBrushScript = preload("res://Scripts/StealthBrush.gd")
const TerritorialCreatureScript = preload("res://Scripts/TerritorialCreature.gd")
const SolarBeamHazardScript = preload("res://Scripts/SolarBeamHazard.gd")
const BeastOfHarmonyScript = preload("res://Scripts/BeastOfHarmony.gd")
const HarmonyHuskBuilderScript = preload("res://Scripts/HarmonyHuskBuilder.gd")
const HarmonyInfectorScript = preload("res://Scripts/HarmonyInfector.gd")
const GildedMitosisScript = preload("res://Scripts/GildedMitosisComponent.gd")
const MapLayoutBuilderScript = preload("res://Scripts/MapLayoutBuilder.gd")
const GpuAcceleratorScript = preload("res://Scripts/GpuAccelerator.gd")
const EnvironmentPreRendererScript = preload("res://Scripts/EnvironmentPreRenderer.gd")
const LoadingScreenScript = preload("res://Scripts/LoadingScreen.gd")
var placed_feature_records: Array = []


var initial_towers_per_team = {}
var koth_points = {
    "SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0, "SideE": 0,
    "SideF": 0, "SideG": 0, "SideH": 0, "SideI": 0, "SideJ": 0,
    "SideK": 0, "SideL": 0, "SideM": 0, "SideN": 0, "SideO": 0,
    "SideP": 0, "SideQ": 0, "SideR": 0, "SideS": 0, "SideT": 0,
    "SideU": 0, "SideV": 0, "SideW": 0, "SideX": 0, "SideY": 0
}

class LocalPlayerState:
    var p_id: int
    var profile: String
    var team: String
    var req: float = 0.0
    var active_commander: Node3D = null
    var selected_card_ui = null
    var ui: Control = null
    var cam: Camera3D = null
    var visuals: Array = []

var players: Array = []

func _ready():
    add_to_group("ArenaManager")
    print("Initializing Arena in Mode: ", GameState.current_mode)

    if "sudden_death_timer" in GameState:
        match_timer = float(GameState.sudden_death_timer)

    
    var original_ui = get_node_or_null("InGameUI")
    var original_cam = get_node_or_null("ArenaCamera")
    if not original_cam:
        original_cam = get_node_or_null("Camera3D")
    
    if GameState.current_mode == "LOCAL_SPLIT_2P" or GameState.current_mode == "LOCAL_SPLIT_4P":
        var h_box = HBoxContainer.new()
        h_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        add_child(h_box)
        
        var is_4p = (GameState.current_mode == "LOCAL_SPLIT_4P" or GameState.map_selected == "Arena_4P.tscn")
        var is_6p = (GameState.map_selected == "Arena_6P.tscn")
        var p_count = 6 if is_6p else (4 if is_4p else 2)
        var profiles = ["Player1", "Guest1", "Guest2", "Guest3", "Guest4", "Guest5"]
        
        if original_ui: original_ui.get_parent().remove_child(original_ui)
        if original_cam: original_cam.get_parent().remove_child(original_cam)
        
        var left_vbox = VBoxContainer.new()
        left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        h_box.add_child(left_vbox)
        
        var right_vbox: VBoxContainer = null
        if is_4p or is_6p:
            right_vbox = VBoxContainer.new()
            right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            h_box.add_child(right_vbox)
            
        for i in range(p_count):
            var pstate = LocalPlayerState.new()
            pstate.p_id = i + 1
            pstate.profile = profiles[i]
            if is_6p: pstate.team = "SideB" if i >= 3 else "SideA"
            elif is_4p: pstate.team = "SideB" if i >= 2 else "SideA"
            else: pstate.team = "SideB" if i == 1 else "SideA"
            
            var sub_c = SubViewportContainer.new()
            sub_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
            if not (is_4p or is_6p): sub_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            sub_c.stretch = true
            
            if is_4p or is_6p:
                if i % 2 == 0: left_vbox.add_child(sub_c)
                else: right_vbox.add_child(sub_c)
            else:
                h_box.add_child(sub_c)
                
            var vp = SubViewport.new()
            vp.use_3d_2d = true
            sub_c.add_child(vp)
            
            var cam = original_cam.duplicate()
            cam.player_id = pstate.p_id
            cam.assigned_team = pstate.team
            vp.add_child(cam)
            pstate.cam = cam
            
            var ui = original_ui.duplicate()
            ui.device_id = -1 if i == 0 else i - 1 # P1 is kb+joy0, P2 is joy0(if 1 controller) or joy1
            ui.player_profile = pstate.profile
            ui.player_id = pstate.p_id
            ui.connect("ui_card_selected", Callable(self, "_on_ui_card_selected"))
            vp.add_child(ui)
            pstate.ui = ui
            
            players.append(pstate)
            
        if original_ui: original_ui.queue_free()
        if original_cam: original_cam.queue_free()
        
    else:
        var pstate = LocalPlayerState.new()
        pstate.p_id = 1
        pstate.profile = "Player1"
        var is_srv = multiplayer.is_server() if multiplayer.has_multiplayer_peer() else true
        pstate.team = "SideA" if is_srv else "SideB"
        if GameState.current_mode == "AI_VS_AI":
            pstate.team = "Spectator"
            pstate.profile = "Spectator"
        pstate.ui = original_ui
        pstate.cam = original_cam
        if not pstate.cam:
            pstate.cam = get_viewport().get_camera_3d()
            if not pstate.cam:
                pstate.cam = find_child("Camera3D", true, false)
        if pstate.cam and GameState.current_mode == "AI_VS_AI":
            pstate.cam.is_spectator = true
            pstate.cam.assigned_team = "Spectator"
            if pstate.cam.has_method("snap_to_overview"):
                pstate.cam.snap_to_overview()
        if pstate.ui: pstate.ui.connect("ui_card_selected", Callable(self, "_on_ui_card_selected"))
        players.append(pstate)
        
    if players.size() > 0:
        GameState.local_player_team = players[0].team
        
    setup_match()
    
    if multiplayer.has_multiplayer_peer():
        if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
            multiplayer.peer_disconnected.connect(_on_peer_disconnected)
        if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
            multiplayer.server_disconnected.connect(_on_server_disconnected)

func _exit_tree():
    if multiplayer.has_multiplayer_peer():
        if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
            multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
        if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
            multiplayer.server_disconnected.disconnect(_on_server_disconnected)

func _on_peer_disconnected(id: int):
    print("Multiplayer peer disconnected: ", id)
    if GameState.current_mode.begins_with("ONLINE"):
        var peers = multiplayer.get_peers()
        if peers.is_empty():
            _end_match("OPPONENT DISCONNECTED! Victory by forfeit.")
        else:
            print("Peer %d disconnected; %d peers remaining." % [id, peers.size()])

func _on_server_disconnected():
    print("Multiplayer server disconnected.")
    if GameState.current_mode.begins_with("ONLINE"):
        _end_match("HOST DISCONNECTED FROM SERVER.")

func setup_match():
    var req_layout: String = String(GameState.map_layout_id) if ("map_layout_id" in GameState) else ""
    var req_players: int = int(GameState.match_player_count) if ("match_player_count" in GameState) else 2
    if GameState.map_selected == "Arena_6P.tscn" and req_players < 6 and (req_layout == "" or req_layout == "CLASSIC_1V1"):
        req_layout = "HEX_STAR_6P"
        req_players = 6
    elif GameState.map_selected == "Arena_4P.tscn" and req_players < 4 and (req_layout == "" or req_layout == "CLASSIC_1V1"):
        req_layout = "QUAD_4LANE_2V2"
        req_players = 4

    var layout_info: Dictionary = MapLayoutBuilderScript.build_map_layout(
        self,
        req_layout,
        req_players,
        GameState.team_comp if ("team_comp" in GameState) else "2_TEAMS"
    )
    var total_slots: int = int(layout_info["total_slots"])
    var teams_for_ai: Array = layout_info["teams_for_slots"]
    var slot_defs: Array = layout_info["slot_defs"]

    koth_points.clear()
    for t_name in GameState.ALL_TEAMS:
        koth_points[t_name] = 0

    var local_players = players.size()
    var start_bot_idx = local_players
    
    if GameState.current_mode == "AI_VS_AI":
        start_bot_idx = 0
        if players.size() > 0 and players[0].ui:
            players[0].ui.visible = true # Keep spectator match UI visible!
    else:
        for p_idx in range(players.size()):
            if p_idx < teams_for_ai.size():
                players[p_idx].team = teams_for_ai[p_idx]
                if players[p_idx].cam:
                    players[p_idx].cam.assigned_team = teams_for_ai[p_idx]
                    if p_idx < slot_defs.size() and players[p_idx].cam.has_method("snap_to"):
                        players[p_idx].cam.snap_to(slot_defs[p_idx]["base_pos"] * 0.75)
        if players.size() > 0:
            GameState.local_player_team = players[0].team
    
    if GameState.current_mode.begins_with("ONLINE"):
        return # Do not spawn AIs in online PvP matches!
        
    var profiles_for_slots = ["Player1", "Guest1", "Guest2", "Guest3", "Guest4", "Guest5"]
    var ai_pool = ["Dominion", "The Reach", "Pirates", "Rimworlders", "Void", "Plague of Harmony", "Gilded Harmony", "Planetary Primitives", "Galactic Wildlife", "The Nightmare Court", "The Winter Court", "The Magma Born", "Chaos"]
    var interval_scale: float = 1.0 + maxf(0.0, float(total_slots - 6) * 0.055)
    for i in range(start_bot_idx, total_slots):
        var bot = BotAI.new()
        bot.my_team = teams_for_ai[i]
        bot.profile = profiles_for_slots[i] if i < profiles_for_slots.size() else ("BotSlot_" + str(i))
        bot.slot_index = i
        
        # Unified AI Pool: Dice roll per bot slot (or user override from MatchSetup)
        var chosen_archetype = ""
        if GameState.ai_faction_override != "RANDOM" and GameState.ai_faction_override != "":
            chosen_archetype = GameState.ai_faction_override
        else:
            chosen_archetype = ai_pool[randi() % ai_pool.size()]
        bot.archetype = chosen_archetype
        print("🎲 AI Slot %d rolled faction dice: %s (Chaos included in pool)" % [i, chosen_archetype])
        
        # Pick primary enemy team (different from bot.my_team)
        bot.enemy_team = "SideB" if bot.my_team == "SideA" else "SideA"
        for cand_t in GameState.active_match_teams:
            if cand_t != bot.my_team:
                bot.enemy_team = cand_t
                break
        bot.difficulty = GameState.ai_difficulty
        
        # Base requisition rate matches player's base (0.5), balanced by difficulty
        if GameState.ai_difficulty == "EASY":
            bot.requisition_rate = 0.4
            bot.think_interval = 1.3 * interval_scale
        elif GameState.ai_difficulty == "MEDIUM":
            bot.requisition_rate = 0.5
            bot.think_interval = 1.0 * interval_scale
        elif GameState.ai_difficulty == "HARD":
            bot.requisition_rate = 0.6
            bot.think_interval = 0.7 * interval_scale
        elif GameState.ai_difficulty == "NIGHTMARE":
            bot.requisition_rate = 0.75
            bot.think_interval = 0.45 * interval_scale
        
        add_child(bot)
        print("Spawned BotAI for ", bot.my_team, " [Slot ", i, "] Archetype: ", bot.archetype, " with profile ", bot.profile)

    var is_koth := GameState.is_koth_mode()
    for kz in get_tree().get_nodes_in_group("KotHZones"):
        if kz is Node3D:
            kz.visible = is_koth

    if is_koth:
        var timer = Timer.new()
        timer.wait_time = 1.0
        timer.autostart = true
        timer.connect("timeout", Callable(self, "_on_koth_tick"))
        add_child(timer)
    _apply_faction_visuals()
    
    for t in GameState.ALL_TEAMS:
        var count = 0
        for z in get_tree().get_nodes_in_group(t):
            if "Tower" in z.name: count += 1
        initial_towers_per_team[t] = max(count, 2)
        
    var chosen_biome = GameState.map_biome if ("map_biome" in GameState and GameState.map_biome != "") else "SUNNY_PLAINS"
    if chosen_biome == "RANDOM":
        var biome_pool = ["SUNNY_PLAINS", "SCORCHING_DUNES", "REALM_OF_HARMONY", "FROZEN_TUNDRA", "VOLCANIC_BRIMSTONE", "SPACE_VACUUM", "DEEP_JUNGLE", "HAUNTED_HALLOW", "FROZEN_WONDERLAND"]
        chosen_biome = biome_pool[randi() % biome_pool.size()]
    var map_seed = randi()
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if multiplayer.is_server():
            rpc("sync_map_environment", chosen_biome, map_seed)
    else:
        _apply_map_environment(chosen_biome, map_seed)
        
var _tower_count_cache_timer: float = 0.0
var _cached_tower_counts: Dictionary = {}

func _process(delta):
    if get_tree().paused: return

    if not sudden_death_active:
        match_timer -= delta
        if match_timer <= 0:
            match_timer = 0
            if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
                if multiplayer.is_server():
                    rpc("sync_start_sudden_death")
            else:
                sync_start_sudden_death()
    else:
        beast_timer -= delta
        if beast_timer <= 0:
            beast_timer = beast_spawn_interval
            beast_spawn_interval = max(0.5, beast_spawn_interval - 0.2)
            var hazard_count = get_tree().get_nodes_in_group("Beast").size()
            if hazard_count > 60: return # Cap beast entities to avoid lag
            var map_size = maxf(40.0, GameState.current_map_radius * 0.58)
            var h_pos = _get_clear_hazard_pos(map_size)
            var rx = h_pos.x
            var rz = h_pos.z
            var hazard_name = "BeastHazard_" + str(Time.get_ticks_usec())
            if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
                if multiplayer.is_server():
                    rpc("sync_spawn_hazard", rx, rz, randi() % 3 == 0, hazard_name)
            else:
                sync_spawn_hazard(rx, rz, randi() % 3 == 0, hazard_name)
                
    var b_root = get_node_or_null("BeastOfNothingness")
    if b_root and is_instance_valid(b_root):
        b_root.rotation.y += delta * 0.025
        var t_anim = Time.get_ticks_msec() / 1000.0
        for child in b_root.get_children():
            if child.has_meta("is_lower_jaw"):
                var base_ly = float(child.get_meta("base_y")) if child.has_meta("base_y") else -4.0
                child.position.y = base_ly + sin(t_anim * 1.1) * 1.2
                var jaw_pulse = 1.0 + sin(t_anim * 1.1) * 0.02
                child.scale = Vector3(jaw_pulse, 1.0, jaw_pulse)
            elif child.has_meta("is_upper_jaw"):
                var base_uy = float(child.get_meta("base_y")) if child.has_meta("base_y") else 85.0
                child.position.y = base_uy - sin(t_anim * 1.1) * 3.5
                child.rotation.y = -b_root.rotation.y * 1.6 + sin(t_anim * 0.4) * 0.12
            elif child.has_meta("is_uvula"):
                var pulse = 1.0 + abs(sin(t_anim * 2.4)) * 0.22
                child.position.y = -72.0 + sin(t_anim * 1.8) * 2.5
                child.scale = Vector3(pulse, 1.0 + cos(t_anim * 2.4) * 0.15, pulse)
            elif child.has_meta("seg_phase"):
                var phase = float(child.get_meta("seg_phase")) if child.has_meta("seg_phase") else 0.0
                var base_y = float(child.get_meta("base_y")) if child.has_meta("base_y") else 0.0
                child.position.y = base_y + sin(t_anim * 1.5 + phase) * 3.5
                var base_rx = float(child.get_meta("base_rx")) if child.has_meta("base_rx") else 0.0
                var base_rz = float(child.get_meta("base_rz")) if child.has_meta("base_rz") else 0.0
                child.rotation.x = base_rx + sin(t_anim * 1.8 + phase) * 0.14
                child.rotation.z = base_rz + cos(t_anim * 1.6 + phase) * 0.14
                
    _update_timer_ui()
    _animate_faction_structures(delta)
    _update_stealth_visibility()

    if active_biome == "SCORCHING_DUNES":
        if current_solar_beam == null or not is_instance_valid(current_solar_beam):
            current_solar_beam = null
            solar_beam_timer -= delta
            if solar_beam_timer <= 0.0:
                var is_host = not (multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and not multiplayer.is_server())
                if is_host:
                    var beam_dur = randf_range(20.0, 50.0)
                    var spawn_x = randf_range(-55.0, 55.0)
                    var spawn_z = randf_range(-55.0, 55.0)
                    var beam_id = "SolarBeam_" + str(Time.get_ticks_usec())
                    solar_beam_timer = randf_range(10.0, 30.0)
                    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
                        rpc("sync_spawn_solar_beam", spawn_x, spawn_z, beam_dur, beam_id)
                    else:
                        sync_spawn_solar_beam(spawn_x, spawn_z, beam_dur, beam_id)
    elif active_biome == "REALM_OF_HARMONY":
        _update_realm_of_harmony(delta)
    elif active_biome == "SPACE_VACUUM":
        _update_space_vacuum(delta)

    if GameState.current_mode == "AI_VS_AI" and players.size() > 0 and players[0].ui:
        var bot_a: BotAI = null
        var bot_b: BotAI = null
        for b in get_children():
            if b is BotAI:
                if b.my_team == "SideA" and bot_a == null: bot_a = b
                elif b.my_team != "SideA" and bot_b == null: bot_b = b
        var max_e = bot_a.max_requisition if bot_a else 100.0
        var a_e = bot_a.current_requisition if bot_a else 0.0
        var b_e = bot_b.current_requisition if bot_b else 0.0
        if players[0].ui.has_method("update_spectator_energy"):
            players[0].ui.update_spectator_energy(a_e, b_e, max_e)
        else:
            if bot_a: players[0].ui.update_requisition(bot_a.current_requisition, bot_a.max_requisition)
            if bot_b: players[0].ui.update_enemy_requisition(bot_b.current_requisition, bot_b.max_requisition, bot_b.my_team)
    else:
        _tower_count_cache_timer -= delta
        if _tower_count_cache_timer <= 0.0 or _cached_tower_counts.is_empty():
            _tower_count_cache_timer = 0.5
            for p in players:
                if p.team == "Spectator": continue
                var t_cnt := 0
                for z in get_tree().get_nodes_in_group(p.team):
                    if is_instance_valid(z) and "Tower" in z.name:
                        var zhc = z.get_node_or_null("HealthComponent")
                        if zhc and zhc.is_dead:
                            continue
                        t_cnt += 1
                _cached_tower_counts[p.team] = t_cnt

        for p in players:
            if p.team == "Spectator": continue
            var player_towers: int = int(_cached_tower_counts.get(p.team, 2))
            var initial = initial_towers_per_team.get(p.team, 2)
            var dynamic_rate = requisition_rate + ((initial - player_towers) * (1.0 / max(1.0, float(initial))))
            dynamic_rate *= GameState.get_team_energy_multiplier(p.team)
            if sudden_death_active:
                dynamic_rate *= 0.5
            if p.req < max_requisition:
                p.req += dynamic_rate * delta
                if p.req > max_requisition: p.req = max_requisition
                
            if p.ui:
                p.ui.update_requisition(p.req, max_requisition)
                if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
                    # Synchronize requisition across network for live enemy meter
                    rpc("sync_requisition", p.team, p.req)
                else:
                    # Find opposing bot to update enemy requisition display
                    var enemy_req = 0.0
                    var enemy_name = "Enemy AI"
                    for b in get_children():
                        if b is BotAI and b.my_team != p.team:
                            enemy_req = b.current_requisition
                            enemy_name = b.my_team + " AI"
                            break
                    p.ui.update_enemy_requisition(enemy_req, max_requisition, enemy_name)


@rpc("authority", "call_local", "reliable")
func sync_start_sudden_death():
    sudden_death_active = true
    match_timer = 0.0
    _start_beast_of_nothingness()

@rpc("any_peer", "unreliable")
func sync_requisition(team: String, req_val: float):
    if is_nan(req_val) or is_inf(req_val): return
    req_val = clampf(req_val, 0.0, max_requisition)
    for p in players:
        if p.ui and p.team != team:
            p.ui.update_enemy_requisition(req_val, max_requisition, "Opponent (" + team + ")")

func _on_ui_card_selected(card_ui, ui_instance):
    var p = _get_player_by_ui(ui_instance)
    if not p: return
    
    if p.selected_card_ui:
        p.selected_card_ui.set_selected(false)
        
    if p.selected_card_ui == card_ui:
        p.selected_card_ui = null
        if ui_instance and "selected_card_idx" in ui_instance:
            ui_instance.selected_card_idx = -1
        toggle_deployment_visuals(p, false)
        return
        
    p.selected_card_ui = card_ui
    p.selected_card_ui.set_selected(true)
    toggle_deployment_visuals(p, true, card_ui.card_data.is_spell)

func _get_player_by_ui(ui_instance) -> LocalPlayerState:
    for p in players:
        if p.ui == ui_instance: return p
    return null

func _get_player_by_device(device: int) -> LocalPlayerState:
    for p in players:
        if p.ui and p.ui.device_id == device: return p
    # Fallback to player 1
    if players.size() > 0: return players[0]
    return null

func _unhandled_input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F8:
            print("DEBUG: Triggering Endgame Sudden Death collapse in 2 seconds!")
            match_timer = 2.0

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        var p0: LocalPlayerState = null
        if players.size() > 0:
            p0 = players[0]
        if p0 and p0.selected_card_ui:
            p0.selected_card_ui.set_selected(false)
            p0.selected_card_ui = null
            if p0.ui and "selected_card_idx" in p0.ui:
                p0.ui.selected_card_idx = -1
            toggle_deployment_visuals(p0, false)
            return


    var is_mouse_click = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
    
    var acted_player = null
    var screen_pos = Vector2.ZERO
    
    if is_mouse_click:
        acted_player = players[0] # Mouse always drives P1
        screen_pos = event.position
        if acted_player.cam and acted_player.cam.get_viewport() != get_viewport():
            # Adjust mouse coordinates if cam is in a subviewport
            var vp = acted_player.cam.get_viewport()
            var win_size = get_viewport().get_visible_rect().size
            var vp_size = vp.get_visible_rect().size
            if win_size.x > 0.0 and win_size.y > 0.0:
                screen_pos.x = (screen_pos.x / win_size.x) * vp_size.x
                screen_pos.y = (screen_pos.y / win_size.y) * vp_size.y

    elif event is InputEventJoypadButton and event.pressed:
        # We need to map standard UI accept or custom action to deployment
        for p in players:
            var prefix = "p" + str(p.p_id) + "_"
            if event.is_action_pressed(prefix + "action"):
                acted_player = p
                if p.cam and p.cam.get_viewport():
                    screen_pos = p.cam.get_viewport().get_visible_rect().size / 2.0
                break
                
    if acted_player and acted_player.selected_card_ui and acted_player.selected_card_ui.card_data:
        var camera = acted_player.cam
        if not camera:
            camera = get_viewport().get_camera_3d()
            if not camera:
                camera = find_child("Camera3D", true, false)
        if not camera: return
        var from = camera.project_ray_origin(screen_pos)
        var to = from + camera.project_ray_normal(screen_pos) * 1000.0
        
        var space_state = camera.get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(from, to)
        var result = space_state.intersect_ray(query)
        
        var hit_pos = Vector3.ZERO
        var hit_found = false
        if result:
            hit_pos = result.position
            hit_found = true
        else:
            var ground_plane = Plane(Vector3.UP, 0.0)
            var plane_hit = ground_plane.intersects_ray(from, camera.project_ray_normal(screen_pos))
            if plane_hit != null:
                hit_pos = plane_hit
                hit_found = true
        
        if hit_found:
            if attempt_to_play_card(acted_player, acted_player.selected_card_ui.card_data, hit_pos):
                var played_ui = acted_player.selected_card_ui
                played_ui.set_selected(false)
                acted_player.selected_card_ui = null
                toggle_deployment_visuals(acted_player, false)
                
                if acted_player.ui:
                    var raw_card = played_ui.card_data.resource_path.get_file().trim_suffix(".tres").trim_suffix(".remap")
                    acted_player.ui.discard.append(raw_card)
                    acted_player.ui.draw_card(played_ui)

func toggle_deployment_visuals(p: LocalPlayerState, should_show: bool, is_spell: bool = false):
    for v in p.visuals:
        if is_instance_valid(v): v.queue_free()
    p.visuals.clear()
    
    if not should_show or is_spell: return
    
    for s in get_tree().get_nodes_in_group(p.team):
        if "Base" in s.name or "Tower" in s.name or "CommandBay" in s.name:
            var ring = MeshInstance3D.new()
            var torus = TorusMesh.new()
            torus.outer_radius = 32.0
            torus.inner_radius = 31.4
            ring.mesh = torus
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color(0.2, 0.8, 1.0, 0.5)
            mat.emission_enabled = true
            mat.emission = Color(0.2, 0.8, 1.0)
            mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
            ring.material_override = mat
            
            var root_node = get_tree().current_scene if (get_tree() and get_tree().current_scene) else self
            root_node.add_child(ring)
            ring.global_position = s.global_position + Vector3(0, 0.1, 0)
            p.visuals.append(ring)

func can_deploy_at(team: String, target_pos: Vector3, is_spell: bool) -> bool:
    if is_spell: return true
    if not is_inside_tree() or not get_tree(): return false
    for z in get_tree().get_nodes_in_group(team):
        if is_instance_valid(z) and ("Base" in z.name or "Tower" in z.name or "CommandBay" in z.name):
            var d = Vector2(target_pos.x, target_pos.z).distance_to(Vector2(z.global_position.x, z.global_position.z))
            if d <= 32.0:
                return true
    return false

func attempt_to_play_card(p: LocalPlayerState, data: Resource, target_position: Vector3) -> bool:
    if p.team == "Spectator":
        return false
    if p.req < data.cost:
        print(p.team, " Not enough Requisition! Need ", data.cost, " but have ", snapped(p.req, 0.1))
        if p.ui and p.ui.has_method("show_placement_warning"):
            p.ui.show_placement_warning("Need " + str(data.cost) + " Requisition (Have " + str(floor(p.req)) + ")")
        return false
        
    if data.card_type == "Commander":
        var has_commander = false
        if get_tree():
            for u in get_tree().get_nodes_in_group(p.team):
                if not is_instance_valid(u) or u.is_queued_for_deletion():
                    continue
                var hc = u.get_node_or_null("HealthComponent")
                if hc and hc.is_dead:
                    continue
                if u.is_in_group("CommanderUnit") or "Commander" in u.name or "Overlord" in u.name or "GreatBeastSpeaker" in u.name:
                    has_commander = true
                    break
        if has_commander:
            print(p.team, " Cannot deploy! You already have an active Commander.")
            if p.ui and p.ui.has_method("show_placement_warning"):
                p.ui.show_placement_warning("Commander already active!")
            return false
                
    if not can_deploy_at(p.team, target_position, data.is_spell):
        print(p.team, " Cannot deploy! Must place units near a Tower or Command Bay.")
        if p.ui and p.ui.has_method("show_placement_warning"):
            p.ui.show_placement_warning("Must deploy within friendly tower or base zone!")
        return false
            
    p.req -= data.cost
    
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        var unique_id = str(randi())
        rpc("sync_spawn_card", data.resource_path, target_position, p.team, unique_id)
    else:
        sync_spawn_card(data.resource_path, target_position, p.team, str(randi()))
        
    return true

@rpc("any_peer", "call_local", "reliable")
func sync_spawn_card(card_path: String, pos: Vector3, team: String, unique_id: String):
    # Security: Strict validation of card path and directory traversal prevention
    if not card_path.begins_with("res://Data/Cards/") or not (card_path.ends_with(".tres") or card_path.ends_with(".tres.remap")) or ".." in card_path:
        push_warning("Security: Rejected unauthorized card path or traversal in RPC: " + str(card_path))
        return
    unique_id = unique_id.replace("/", "_").replace("@", "_").replace(":", "_").replace("\\", "_")
        
    # Security: Validate position coordinates (finite, non-NaN, within arena bounds)
    if is_nan(pos.x) or is_nan(pos.y) or is_nan(pos.z) or is_inf(pos.x) or is_inf(pos.y) or is_inf(pos.z):
        push_warning("Security: Rejected NaN/Inf position in sync_spawn_card")
        return
    var max_spawn_bound: float = maxf(250.0, GameState.current_map_radius + 60.0)
    if abs(pos.x) > max_spawn_bound or abs(pos.z) > max_spawn_bound:
        push_warning("Security: Rejected out-of-bounds spawn position: " + str(pos))
        return
        
    # Security: Validate caller authority to prevent team spoofing
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        var sender_id = multiplayer.get_remote_sender_id()
        if sender_id != 0 and sender_id != 1: # Sent by client peer
            if team == "SideA":
                push_warning("Security: Client attempted to spawn unit for SideA (Host). Overriding to SideB.")
                team = "SideB"

    var data = load(card_path)
    if data == null or not "unit_scene" in data or data.unit_scene == null: return
    
    var count = 1
    if "spawn_count" in data: count = data.spawn_count
    
    var c_name_clean: String = data.card_name.replace(" ", "")
    var random_husk_cat: String = ""
    var is_random_husk_card: bool = false
    var is_gilded_husk_card: bool = false
    
    if c_name_clean == "PlagueEnlightenedMelee":
        is_random_husk_card = true; random_husk_cat = "MELEE"; count = 4
    elif c_name_clean == "PlagueEnlightenedRanged":
        is_random_husk_card = true; random_husk_cat = "RANGED"; count = 2
    elif c_name_clean == "PlagueEnlightenedTank":
        is_random_husk_card = true; random_husk_cat = "TANK"; count = 1
    elif c_name_clean == "PlagueEnlightenedPlane":
        is_random_husk_card = true; random_husk_cat = "PLANE"; count = 1
    elif c_name_clean == "PlagueEnlightenedBig":
        is_random_husk_card = true; random_husk_cat = "BIG"; count = 1
    elif c_name_clean == "GildedSavedHorde":
        is_random_husk_card = true; is_gilded_husk_card = true; random_husk_cat = "ANY"; count = 6
    elif c_name_clean == "GildedHuskMelee":
        is_random_husk_card = true; is_gilded_husk_card = true; random_husk_cat = "MELEE"; count = 1
    elif c_name_clean == "GildedHuskRanged":
        is_random_husk_card = true; is_gilded_husk_card = true; random_husk_cat = "RANGED"; count = 1
    
    for i in range(count):
        var scene_to_spawn: PackedScene = data.unit_scene
        var rolled_scene_path: String = ""
        if is_random_husk_card:
            rolled_scene_path = HarmonyHuskBuilderScript.get_random_husk_scene_for_category(random_husk_cat)
            var loaded_scn = load(rolled_scene_path)
            if loaded_scn is PackedScene:
                scene_to_spawn = loaded_scn
                
        var unit = scene_to_spawn.instantiate()
        var base_u_name: String = c_name_clean
        if is_random_husk_card and rolled_scene_path != "":
            base_u_name = rolled_scene_path.get_file().get_basename() + "_Husk"
        unit.name = base_u_name + "_" + unique_id + "_" + str(i)
        
        if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
            var sync = MultiplayerSynchronizer.new()
            var config = SceneReplicationConfig.new()
            config.add_property(NodePath(":position"))
            config.add_property(NodePath(":rotation"))
            sync.replication_config = config
            unit.add_child(sync)
            
        unit.add_to_group(team)
        add_child(unit)
        if data.is_spell: unit.global_position = pos
        else: unit.global_position = pos + Vector3(randf_range(-2.2, 2.2), 2.0, randf_range(-2.2, 2.2))
        
        var hc = unit.get_node_or_null("HealthComponent")
        if hc and not is_random_husk_card and "max_hp" in data:
            if hc.has_method("set_max_health") and (data.max_hp != 100.0 or hc.max_health == 100.0):
                hc.set_max_health(data.max_hp)
                
        if is_random_husk_card:
            HarmonyHuskBuilderScript.transform_into_husk(unit, is_gilded_husk_card, team)
            if is_gilded_husk_card:
                var mitosis = GildedMitosisScript.new()
                mitosis.name = "GildedMitosisComponent"
                mitosis.source_scene_path = rolled_scene_path
                unit.add_child(mitosis)
        elif hc and hc.has_method("update_health_bar_colors"):
            hc.update_health_bar_colors()
                
        if "card_type" in data and data.card_type == "Commander":
            unit.add_to_group("CommanderUnit")
        if "CommandBay" in unit.name:
            var faction = _get_team_faction(team)
            _build_structure_mesh(unit, faction, false)

func _on_koth_tick():
    if get_tree().paused: return
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if not multiplayer.is_server():
            return
            
    var zones: Array = get_tree().get_nodes_in_group("KotHZones")
    if zones.is_empty():
        var single_kz = get_node_or_null("KotH_Zone")
        if single_kz:
            zones.append(single_kz)
    if zones.is_empty():
        return

    var mobile_units: Array[Node3D] = []
    for b in get_tree().get_nodes_in_group("Targetable"):
        if not is_instance_valid(b) or not (b is Node3D):
            continue
        if "Base" in b.name or "Tower" in b.name or "CommandBay" in b.name:
            continue
        if b.is_in_group("NeutralCreature") or b.is_in_group("NeutralStructure") or b.is_in_group("SideHarmony") or "BeastTentacle" in b.name or "BeastMouth" in b.name:
            continue
        var hc = b.get_node_or_null("HealthComponent")
        if hc and hc.is_dead:
            continue
        mobile_units.append(b as Node3D)

    for kz in zones:
        if not is_instance_valid(kz) or not (kz is Node3D):
            continue
        var kz_node: Node3D = kz as Node3D
        var kz_rad: float = float(kz_node.get_meta("koth_radius")) if kz_node.has_meta("koth_radius") else 16.0
        var kz_pos2 := Vector2(kz_node.global_position.x, kz_node.global_position.z)

        var team_counts := {}
        for u: Node3D in mobile_units:
            var u_pos2 := Vector2(u.global_position.x, u.global_position.z)
            if u_pos2.distance_to(kz_pos2) <= kz_rad:
                for g in u.get_groups():
                    if g.begins_with("Side") and g != "SideHarmony":
                        team_counts[g] = int(team_counts.get(g, 0)) + 1
                        break

        var dominant_team: String = ""
        var max_count: int = 0
        var tied: bool = false
        for team_key in team_counts.keys():
            var c_val: int = int(team_counts[team_key])
            if c_val > max_count:
                max_count = c_val
                dominant_team = String(team_key)
                tied = false
            elif c_val == max_count and max_count > 0:
                tied = true

        kz_node.set_meta("controlling_team", "CONTESTED" if tied else dominant_team)
        if not tied and dominant_team != "":
            koth_points[dominant_team] = int(koth_points.get(dominant_team, 0)) + 1
            _last_displayed_second = -1
            if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
                rpc("sync_koth_points", dominant_team, koth_points[dominant_team])
            if koth_points[dominant_team] >= 100:
                _end_match(dominant_team + " WINS THE MATCH BY KING OF THE HILL!", dominant_team)
                return

@rpc("authority", "unreliable")
func sync_koth_points(team: String, points: int):
    if team.begins_with("Side"):
        koth_points[team] = points
        _last_displayed_second = -1


func _get_slot_faction(slot: int) -> String:
    if slot < players.size() and players[slot].team != "Spectator":
        var p = players[slot]
        var deck = []
        if GameState.player_decks.has(p.profile):
            deck = GameState.player_decks[p.profile]
        return _detect_faction_from_deck(deck)
        
    for child in get_children():
        if child.get_script() and "BotAI" in child.get_script().resource_path:
            if child.get("slot_index") == slot:
                var arch = child.get("archetype")
                if arch != null and arch != "":
                    return arch
                var deck = child.get("deck")
                if deck != null and not deck.is_empty():
                    return _detect_faction_from_deck(deck)
                    
    var opts = ["Dominion", "Void", "Rimworlders", "Pirates", "The Reach", "Plague of Harmony", "Gilded Harmony", "Planetary Primitives", "Galactic Wildlife", "The Nightmare Court", "The Winter Court", "The Magma Born", "Chaos"]
    return opts[randi() % opts.size()]

func _get_team_faction(team: String) -> String:
    for p in players:
        if p.team == team:
            var deck = []
            if GameState.player_decks.has(p.profile):
                deck = GameState.player_decks[p.profile]
            return _detect_faction_from_deck(deck)
            
    for child in get_children():
        if child.get_script() and "BotAI" in child.get_script().resource_path:
            if child.get("my_team") == team:
                var arch = child.get("archetype")
                if arch != null and arch != "":
                    return arch
                var deck = child.get("deck")
                if deck != null and not deck.is_empty():
                    return _detect_faction_from_deck(deck)
                var p_name = child.get("profile")
                if p_name != null and GameState.player_decks.has(p_name):
                    return _detect_faction_from_deck(GameState.player_decks[p_name])
                    
    var opts = ["Dominion", "Void", "Rimworlders", "Pirates", "The Reach", "Plague of Harmony", "Gilded Harmony", "Planetary Primitives", "Galactic Wildlife", "The Nightmare Court", "The Winter Court", "The Magma Born", "Chaos"]
    return opts[randi() % opts.size()]

func _detect_faction_from_deck(deck: Array) -> String:
    var v = 0; var r = 0; var d = 0; var pi = 0; var reach = 0; var plague = 0; var gilded = 0; var prim = 0; var wild = 0; var night = 0; var winter = 0; var magma = 0
    for c in deck:
        if "Magma" in c or "Lava" in c: magma += 1
        elif "Nightmare" in c or "Halloween" in c: night += 1
        elif "Winter" in c or "Yuletide" in c or "Yule" in c: winter += 1
        elif "Wildlife" in c: wild += 1
        elif "Primitive" in c: prim += 1
        elif "Plague" in c: plague += 1
        elif "Gilded" in c: gilded += 1
        elif "Void" in c: v += 1
        elif "Rimworlder" in c or "Sky" in c or "Stone" in c or "Giant" in c or "Great" in c or "Monstrous" in c: r += 1
        elif "Scrap" in c: pi += 1
        elif "Reach" in c: reach += 1
        else: d += 1
    var mx = max(d, max(v, max(r, max(pi, max(reach, max(plague, max(gilded, max(prim, max(wild, max(night, max(winter, magma)))))))))))
    if mx < 3 and deck.size() >= 5: return "Chaos"
    if mx == magma and magma > 0: return "The Magma Born"
    if mx == night and night > 0: return "The Nightmare Court"
    if mx == winter and winter > 0: return "The Winter Court"
    if mx == wild and wild > 0: return "Galactic Wildlife"
    if mx == prim and prim > 0: return "Planetary Primitives"
    if mx == plague and plague > 0: return "Plague of Harmony"
    if mx == gilded and gilded > 0: return "Gilded Harmony"
    if mx == v and v > 0: return "Void"
    if mx == r and r > 0: return "Rimworlders"
    if mx == pi and pi > 0: return "Pirates"
    if mx == reach and reach > 0: return "The Reach"
    return "Dominion"

func _apply_faction_visuals():
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if not multiplayer.is_server():
            return
            
    if get_node_or_null("Base_0") != null:
        var slot_count: int = maxi(2, int(GameState.match_player_count))
        for slot in range(slot_count):
            var slot_faction = _get_slot_faction(slot)
            for child in get_children():
                if child.name == ("Base_" + str(slot)) or child.name.begins_with("Tower_" + str(slot) + "_"):
                    if "faction" in child: child.faction = slot_faction
                    _build_structure_mesh(child, slot_faction, "Tower" in child.name)
        return
            
    for team in GameState.ALL_TEAMS:
        if get_tree().get_nodes_in_group(team).is_empty():
            continue
        var faction = _get_team_faction(team)
        if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
            rpc("sync_faction", team, faction)
        else:
            apply_local_faction(team, faction)

@rpc("authority", "call_local", "reliable")
func sync_faction(team: String, faction: String):
    apply_local_faction(team, faction)

func apply_local_faction(team: String, faction: String):
    for node in get_tree().get_nodes_in_group(team):
        if "Base" in node.name or "Tower" in node.name or "CommandBay" in node.name:
            if "faction" in node: node.faction = faction
            _build_structure_mesh(node, faction, "Tower" in node.name)

func _build_structure_mesh(node, faction: String, is_tower: bool):
    if node is CSGShape3D:
        var clear_mat = StandardMaterial3D.new()
        clear_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        clear_mat.albedo_color = Color(0, 0, 0, 0)
        node.material_override = clear_mat
        
    for c in node.get_children():
        if c is MeshInstance3D or (c is CSGShape3D and c != node):
            c.queue_free()
            
    var mesh_node = Node3D.new()
    node.add_child(mesh_node)
    node.set_meta("faction_mesh", mesh_node)
    node.add_to_group("FactionStructures")
    
    var is_bay = "CommandBay" in node.name
    
    # Resolve faction type (supports substring matching, and Chaos/Random independent dice rolls per tower/base)
    var f = faction
    var f_type = "Dominion"
    if "Magma" in f or "Lava" in f:
        f_type = "The Magma Born"
    elif "Nightmare" in f or "Halloween" in f:
        f_type = "The Nightmare Court"
    elif "Winter" in f or "Yuletide" in f or "Yule" in f or "Frost" in f:
        f_type = "The Winter Court"
    elif "Wildlife" in f:
        f_type = "Galactic Wildlife"
    elif "Primitive" in f:
        f_type = "Planetary Primitives"
    elif "Plague" in f:
        f_type = "Plague of Harmony"
    elif "Gilded" in f:
        f_type = "Gilded Harmony"
    elif "Void" in f:
        f_type = "Void"
    elif "Rimworld" in f:
        f_type = "Rimworlders"
    elif "Pirate" in f or "Scrap" in f:
        f_type = "Pirates"
    elif "Reach" in f:
        f_type = "The Reach"
    elif f == "Chaos" or f == "Random":
        var all_factions = [
            "Dominion", "Void", "Rimworlders", "Pirates", "The Reach", 
            "Plague of Harmony", "Gilded Harmony", "Planetary Primitives", 
            "Galactic Wildlife", "The Nightmare Court", "The Winter Court", "The Magma Born"
        ]
        f_type = all_factions[randi() % all_factions.size()]
    node.set_meta("resolved_faction", f_type)
    
    # ==========================================
    # 1. DOMINION OF SOL (MILITARY FORTRESS)
    # ==========================================
    if f_type == "Dominion":
        var steel_mat = StandardMaterial3D.new(); steel_mat.albedo_color = Color(0.25, 0.28, 0.3); steel_mat.metallic = 0.85; steel_mat.roughness = 0.35
        var camo_mat = StandardMaterial3D.new(); camo_mat.albedo_color = Color(0.22, 0.32, 0.18); camo_mat.roughness = 0.7
        var amber_mat = StandardMaterial3D.new(); amber_mat.albedo_color = Color(1.0, 0.6, 0.1); amber_mat.emission_enabled = true; amber_mat.emission = Color(1.0, 0.5, 0.0); amber_mat.emission_energy_multiplier = 2.0
        
        if is_bay:
            # Military Supply Outpost & Communications Hub
            var bunker = MeshInstance3D.new(); bunker.mesh = BoxMesh.new(); bunker.mesh.size = Vector3(4.5, 2.2, 4.0)
            bunker.material_override = camo_mat; bunker.position.y = 1.1; mesh_node.add_child(bunker)
            var roof = MeshInstance3D.new(); roof.mesh = BoxMesh.new(); roof.mesh.size = Vector3(5.0, 0.4, 4.4)
            roof.material_override = steel_mat; roof.position.y = 2.4; mesh_node.add_child(roof)
            # Radar Dish
            var dish_pole = MeshInstance3D.new(); dish_pole.mesh = CylinderMesh.new(); dish_pole.mesh.top_radius = 0.08; dish_pole.mesh.bottom_radius = 0.08; dish_pole.mesh.height = 1.8
            dish_pole.material_override = steel_mat; dish_pole.position = Vector3(-1.5, 3.3, -1.2); mesh_node.add_child(dish_pole)
            var dish = MeshInstance3D.new(); dish.mesh = CylinderMesh.new(); dish.mesh.top_radius = 0.8; dish.mesh.bottom_radius = 0.1; dish.mesh.height = 0.3
            dish.material_override = steel_mat; dish.position = Vector3(-1.5, 4.2, -1.2); dish.rotation_degrees.x = 45; mesh_node.add_child(dish)
            mesh_node.set_meta("dominion_dish", dish)
            # Crates
            var c1 = MeshInstance3D.new(); c1.mesh = BoxMesh.new(); c1.mesh.size = Vector3(1.2, 1.0, 1.2)
            c1.material_override = steel_mat; c1.position = Vector3(1.6, 0.5, 1.8); mesh_node.add_child(c1)
        elif is_tower:
            # Heavy Military Pillbox with Twin Autocannons parented to Rotating Turret
            var base = MeshInstance3D.new(); base.mesh = CylinderMesh.new(); base.mesh.height = 3.2; base.mesh.bottom_radius = 2.2; base.mesh.top_radius = 1.8; base.mesh.radial_segments = 8
            base.material_override = camo_mat; base.position.y = 1.6; mesh_node.add_child(base)
            var ring = MeshInstance3D.new(); ring.mesh = TorusMesh.new(); ring.mesh.outer_radius = 2.0; ring.mesh.inner_radius = 1.7
            ring.material_override = steel_mat; ring.position.y = 3.2; mesh_node.add_child(ring)
            var pedestal = MeshInstance3D.new(); pedestal.mesh = CylinderMesh.new(); pedestal.mesh.height = 0.5; pedestal.mesh.bottom_radius = 1.3; pedestal.mesh.top_radius = 1.2
            pedestal.material_override = steel_mat; pedestal.position.y = 3.35; mesh_node.add_child(pedestal)
            var turret = MeshInstance3D.new(); turret.mesh = BoxMesh.new(); turret.mesh.size = Vector3(2.2, 1.2, 2.4)
            turret.material_override = steel_mat; turret.position.y = 4.0; mesh_node.add_child(turret)
            mesh_node.set_meta("dominion_turret", turret)
            var mantlet = MeshInstance3D.new(); mantlet.mesh = BoxMesh.new(); mantlet.mesh.size = Vector3(1.6, 0.65, 0.45)
            mantlet.material_override = camo_mat; mantlet.position = Vector3(0, 0.0, 1.2); turret.add_child(mantlet)
            # Twin heavy barrels parented to turret so they aim and recoil with it!
            for i in range(2):
                var barrel = MeshInstance3D.new(); barrel.mesh = CylinderMesh.new(); barrel.mesh.height = 2.5; barrel.mesh.bottom_radius = 0.22; barrel.mesh.top_radius = 0.2
                barrel.material_override = steel_mat; barrel.rotation_degrees.x = 90; barrel.position = Vector3(-0.5 + i*1.0, 0.0, 1.6)
                turret.add_child(barrel)
            # Sensor Visor parented to turret
            var visor = MeshInstance3D.new(); visor.mesh = BoxMesh.new(); visor.mesh.size = Vector3(1.6, 0.25, 0.2)
            visor.material_override = amber_mat; visor.position = Vector3(0, 0.4, 1.25); turret.add_child(visor)
        else:
            # Massive Command Citadel HQ
            var fort = MeshInstance3D.new(); fort.mesh = CylinderMesh.new(); fort.mesh.height = 4.5; fort.mesh.bottom_radius = 4.8; fort.mesh.top_radius = 4.2; fort.mesh.radial_segments = 8
            fort.material_override = camo_mat; fort.position.y = 2.25; mesh_node.add_child(fort)
            var upper = MeshInstance3D.new(); upper.mesh = BoxMesh.new(); upper.mesh.size = Vector3(5.0, 2.0, 5.0)
            upper.material_override = steel_mat; upper.position.y = 5.25; mesh_node.add_child(upper)
            var command_bridge = MeshInstance3D.new(); command_bridge.mesh = BoxMesh.new(); command_bridge.mesh.size = Vector3(4.0, 0.8, 4.0)
            command_bridge.material_override = amber_mat; command_bridge.position.y = 6.2; mesh_node.add_child(command_bridge)
            # Communications Antennae
            for i in range(4):
                var ant = MeshInstance3D.new(); ant.mesh = CylinderMesh.new(); ant.mesh.height = 4.0; ant.mesh.bottom_radius = 0.12; ant.mesh.top_radius = 0.04
                ant.material_override = steel_mat; ant.position = Vector3(cos(float(i) * PI / 2.0) * 2.2, 7.5, sin(float(i) * PI / 2.0) * 2.2); mesh_node.add_child(ant)
            # Searchlights
            for i in range(4):
                var light = MeshInstance3D.new(); light.mesh = SphereMesh.new(); light.mesh.radius = 0.35
                light.material_override = amber_mat; light.position = Vector3(cos(float(i) * PI / 2.0 + PI / 4.0) * 4.4, 4.6, sin(float(i) * PI / 2.0 + PI / 4.0) * 4.4); mesh_node.add_child(light)

    # ==========================================
    # 2. THE VOID SWARM (LIVING BIO-HORROR)
    # ==========================================
    elif f_type == "Void":
        var flesh_mat = StandardMaterial3D.new(); flesh_mat.albedo_color = Color(0.18, 0.04, 0.28); flesh_mat.roughness = 0.4
        var chitin_mat = StandardMaterial3D.new(); chitin_mat.albedo_color = Color(0.06, 0.02, 0.1); chitin_mat.roughness = 0.2; chitin_mat.metallic = 0.4
        var eye_mat = StandardMaterial3D.new(); eye_mat.albedo_color = Color(1.0, 0.05, 0.85); eye_mat.emission_enabled = true; eye_mat.emission = Color(0.9, 0.0, 0.9); eye_mat.emission_energy_multiplier = 3.0
        
        if is_bay:
            # Spore Nest Cyst
            var cyst = MeshInstance3D.new(); cyst.mesh = SphereMesh.new(); cyst.mesh.radius = 2.2; cyst.mesh.height = 2.5
            cyst.material_override = flesh_mat; cyst.position.y = 1.25; mesh_node.add_child(cyst)
            for i in range(5):
                var pustule = MeshInstance3D.new(); pustule.mesh = SphereMesh.new(); pustule.mesh.radius = 0.6
                pustule.material_override = eye_mat
                var a = i * (2.0 * PI / 5.0)
                pustule.position = Vector3(cos(a)*1.6, 1.8, sin(a)*1.6); mesh_node.add_child(pustule)
        elif is_tower:
            # Flesh Spire with Giant Pulsing Eye
            var spire = MeshInstance3D.new(); spire.mesh = CylinderMesh.new(); spire.mesh.height = 6.0; spire.mesh.bottom_radius = 1.4; spire.mesh.top_radius = 0.65
            spire.material_override = flesh_mat; spire.position.y = 3.0; mesh_node.add_child(spire)
            # Talons surrounding the top cradling the eye
            for i in range(4):
                var talon = MeshInstance3D.new(); talon.mesh = CylinderMesh.new(); talon.mesh.height = 2.5; talon.mesh.bottom_radius = 0.28; talon.mesh.top_radius = 0.05
                talon.material_override = chitin_mat; talon.position = Vector3(cos(float(i) * PI / 2.0) * 0.72, 5.5, sin(float(i) * PI / 2.0) * 0.72)
                talon.rotation_degrees.x = 25.0 * cos(float(i) * PI / 2.0); talon.rotation_degrees.z = 25.0 * sin(float(i) * PI / 2.0); mesh_node.add_child(talon)
            var eye = MeshInstance3D.new(); eye.mesh = SphereMesh.new(); eye.mesh.radius = 1.3
            eye.material_override = eye_mat; eye.position.y = 5.8; mesh_node.add_child(eye)
            mesh_node.set_meta("void_eye", eye)
        else:
            # Massive Beating Swarm Hive Heart
            var hive = MeshInstance3D.new(); hive.mesh = SphereMesh.new(); hive.mesh.radius = 3.8; hive.mesh.height = 4.5
            hive.material_override = flesh_mat; hive.position.y = 2.5; mesh_node.add_child(hive)
            var heart = MeshInstance3D.new(); heart.mesh = SphereMesh.new(); heart.mesh.radius = 2.2
            heart.material_override = eye_mat; heart.position.y = 3.2; mesh_node.add_child(heart)
            mesh_node.set_meta("void_heart", heart)
            # Outer curved chitinous mandibles
            for i in range(8):
                var fang = MeshInstance3D.new(); fang.mesh = CylinderMesh.new(); fang.mesh.height = 5.0; fang.mesh.bottom_radius = 0.6; fang.mesh.top_radius = 0.05
                fang.material_override = chitin_mat
                var a = i * (2.0 * PI / 8.0)
                fang.position = Vector3(cos(a)*3.5, 2.5, sin(a)*3.5)
                fang.rotation_degrees.x = 35 * cos(a); fang.rotation_degrees.z = 35 * sin(a); mesh_node.add_child(fang)

    # ==========================================
    # 3. THE RIMWORLDERS (PRIMITIVE BEAST CITADEL)
    # ==========================================
    elif f_type == "Rimworlders":
        var stone_mat = StandardMaterial3D.new(); stone_mat.albedo_color = Color(0.35, 0.32, 0.28); stone_mat.roughness = 0.95
        var wood_mat = StandardMaterial3D.new(); wood_mat.albedo_color = Color(0.42, 0.26, 0.14); wood_mat.roughness = 0.85
        var bone_mat = StandardMaterial3D.new(); bone_mat.albedo_color = Color(0.9, 0.88, 0.78); bone_mat.roughness = 0.5
        var fire_mat = StandardMaterial3D.new(); fire_mat.albedo_color = Color(1.0, 0.45, 0.0); fire_mat.emission_enabled = true; fire_mat.emission = Color(1.0, 0.35, 0.0); fire_mat.emission_energy_multiplier = 3.0
        
        if is_bay:
            # Beast Hide Yurt with Mammoth Horns
            var yurt = MeshInstance3D.new(); yurt.mesh = CylinderMesh.new(); yurt.mesh.bottom_radius = 2.8; yurt.mesh.top_radius = 0.2; yurt.mesh.height = 3.5
            yurt.material_override = wood_mat; yurt.position.y = 1.75; mesh_node.add_child(yurt)
            var horn1 = MeshInstance3D.new(); horn1.mesh = CylinderMesh.new(); horn1.mesh.top_radius = 0.05; horn1.mesh.bottom_radius = 0.3; horn1.mesh.height = 2.5
            horn1.material_override = bone_mat; horn1.position = Vector3(-1.2, 2.3, 1.2); horn1.rotation_degrees.z = -35; mesh_node.add_child(horn1)
            var horn2 = MeshInstance3D.new(); horn2.mesh = CylinderMesh.new(); horn2.mesh.top_radius = 0.05; horn2.mesh.bottom_radius = 0.3; horn2.mesh.height = 2.5
            horn2.material_override = bone_mat; horn2.position = Vector3(1.2, 2.3, 1.2); horn2.rotation_degrees.z = 35; mesh_node.add_child(horn2)
        elif is_tower:
            # Primitive Timber Watchtower with Cross-Braces & Spiked Skull Crest
            for i in range(4):
                var post = MeshInstance3D.new(); post.mesh = CylinderMesh.new(); post.mesh.height = 5.5; post.mesh.bottom_radius = 0.35; post.mesh.top_radius = 0.3
                post.material_override = wood_mat; post.position = Vector3(cos(float(i) * PI / 2.0 + PI / 4.0) * 1.3, 2.75, sin(float(i) * PI / 2.0 + PI / 4.0) * 1.3)
                mesh_node.add_child(post)
            var platform = MeshInstance3D.new(); platform.mesh = CylinderMesh.new(); platform.mesh.height = 0.6; platform.mesh.bottom_radius = 2.0; platform.mesh.top_radius = 2.0
            platform.material_override = wood_mat; platform.position.y = 5.3; mesh_node.add_child(platform)
            # Bone Spikes anchored into platform rim
            for i in range(6):
                var tusk = MeshInstance3D.new(); tusk.mesh = CylinderMesh.new(); tusk.mesh.height = 1.8; tusk.mesh.bottom_radius = 0.2; tusk.mesh.top_radius = 0.02
                tusk.material_override = bone_mat; var a = i * (2.0 * PI / 6.0)
                tusk.position = Vector3(cos(a)*1.75, 6.0, sin(a)*1.75); mesh_node.add_child(tusk)
        else:
            # Megalithic Beast Totem Fortress & Sacrificial Fire
            var stone_ring = MeshInstance3D.new(); stone_ring.mesh = CylinderMesh.new(); stone_ring.mesh.height = 2.0; stone_ring.mesh.bottom_radius = 4.8; stone_ring.mesh.top_radius = 4.4; stone_ring.mesh.radial_segments = 12
            stone_ring.material_override = stone_mat; stone_ring.position.y = 1.0; mesh_node.add_child(stone_ring)
            var fire = MeshInstance3D.new(); fire.mesh = SphereMesh.new(); fire.mesh.radius = 2.2
            fire.material_override = fire_mat; fire.position.y = 2.6; mesh_node.add_child(fire)
            mesh_node.set_meta("rimworld_fire", fire)
            # Gigantic Beast Tusks
            for i in range(4):
                var mammoth_tusk = MeshInstance3D.new(); mammoth_tusk.mesh = CylinderMesh.new(); mammoth_tusk.mesh.height = 6.0; mammoth_tusk.mesh.bottom_radius = 0.55; mammoth_tusk.mesh.top_radius = 0.05
                mammoth_tusk.material_override = bone_mat; var a = float(i) * (PI / 2.0) + PI / 4.0
                mammoth_tusk.position = Vector3(cos(a)*3.6, 3.5, sin(a)*3.6)
                mammoth_tusk.rotation_degrees.x = -25 * cos(a); mammoth_tusk.rotation_degrees.z = -25 * sin(a)
                mesh_node.add_child(mammoth_tusk)

    # ==========================================
    # 4. PIRATE KINGDOMS (SCRAP CITADEL)
    # ==========================================
    elif f_type == "Pirates":
        seed(node.name.hash())
        var rust_mat = StandardMaterial3D.new(); rust_mat.albedo_color = Color(0.55, 0.28, 0.12); rust_mat.metallic = 0.5; rust_mat.roughness = 0.9
        var dark_metal = StandardMaterial3D.new(); dark_metal.albedo_color = Color(0.2, 0.2, 0.2); dark_metal.metallic = 0.8
        var scrap_yellow = StandardMaterial3D.new(); scrap_yellow.albedo_color = Color(0.7, 0.55, 0.15); scrap_yellow.roughness = 0.8
        
        if is_bay:
            # Welded Cargo Container Bunker
            var crate = MeshInstance3D.new(); crate.mesh = BoxMesh.new(); crate.mesh.size = Vector3(3.5, 2.4, 3.5)
            crate.material_override = rust_mat; crate.position.y = 1.2; mesh_node.add_child(crate)
            var plate = MeshInstance3D.new(); plate.mesh = BoxMesh.new(); plate.mesh.size = Vector3(2.5, 1.2, 0.2)
            plate.material_override = scrap_yellow; plate.position = Vector3(0, 1.4, 1.80); mesh_node.add_child(plate)
            var exhaust = MeshInstance3D.new(); exhaust.mesh = CylinderMesh.new(); exhaust.mesh.height = 2.0; exhaust.mesh.top_radius = 0.2; exhaust.mesh.bottom_radius = 0.2
            exhaust.material_override = dark_metal; exhaust.position = Vector3(1.2, 2.8, -1.2); mesh_node.add_child(exhaust)
        elif is_tower:
            # Jury-Rigged Crane Turret with Centered Swivel Hub & Scrap Shielding
            var derrick = MeshInstance3D.new(); derrick.mesh = BoxMesh.new(); derrick.mesh.size = Vector3(1.6, 5.5, 1.6)
            derrick.material_override = rust_mat; derrick.position.y = 2.75; mesh_node.add_child(derrick)
            var crane_pivot = Node3D.new(); crane_pivot.position = Vector3(0, 5.6, 0); mesh_node.add_child(crane_pivot)
            var crane_hub = MeshInstance3D.new(); crane_hub.mesh = CylinderMesh.new(); crane_hub.mesh.height = 0.7; crane_hub.mesh.top_radius = 0.65; crane_hub.mesh.bottom_radius = 0.75
            crane_hub.material_override = dark_metal; crane_pivot.add_child(crane_hub)
            var crane_boom = MeshInstance3D.new(); crane_boom.mesh = BoxMesh.new(); crane_boom.mesh.size = Vector3(4.2, 0.6, 0.8)
            crane_boom.material_override = scrap_yellow; crane_boom.position = Vector3(1.4, 0.0, 0); crane_pivot.add_child(crane_boom)
            mesh_node.set_meta("pirate_crane", crane_pivot)
            var cannon = MeshInstance3D.new(); cannon.mesh = CylinderMesh.new(); cannon.mesh.height = 3.0; cannon.mesh.top_radius = 0.3; cannon.mesh.bottom_radius = 0.35
            cannon.material_override = dark_metal; cannon.rotation_degrees.x = 90; cannon.position = Vector3(0, 4.5, 1.5); mesh_node.add_child(cannon)
        else:
            # Mad-Max Scrapyard Fortress with Chimneys & Spikes
            for i in range(5):
                var box = MeshInstance3D.new(); box.mesh = BoxMesh.new(); box.mesh.size = Vector3(2.8, 2.2, 4.2)
                box.material_override = rust_mat if i % 2 == 0 else scrap_yellow
                box.rotation_degrees.y = (i * 35.0)
                box.position = Vector3((i - 2.0) * 1.4, 1.1 + (i % 2) * 1.3, 0)
                mesh_node.add_child(box)
            # Giant smoking smokestacks
            for i in range(2):
                var stack = MeshInstance3D.new(); stack.mesh = CylinderMesh.new(); stack.mesh.height = 5.0; stack.mesh.bottom_radius = 0.55; stack.mesh.top_radius = 0.55
                stack.material_override = dark_metal; stack.position = Vector3(-1.4 + i*2.8, 4.2, -0.8); mesh_node.add_child(stack)
        randomize()

    # ==========================================
    # 5. THE REACH (PRISTINE CRYSTALLINE SPIRE)
    # ==========================================
    elif f_type == "The Reach":
        var white_mat = StandardMaterial3D.new(); white_mat.albedo_color = Color(0.95, 0.97, 1.0); white_mat.roughness = 0.15; white_mat.metallic = 0.1
        var cyan_mat = StandardMaterial3D.new(); cyan_mat.albedo_color = Color(0.0, 0.88, 1.0); cyan_mat.emission_enabled = true; cyan_mat.emission = Color(0.0, 0.85, 0.1); cyan_mat.emission = Color(0.0, 0.85, 1.0); cyan_mat.emission_energy_multiplier = 3.5
        
        if is_bay:
            # Porcelain Energy Pylon & Prisms
            var dome = MeshInstance3D.new(); dome.mesh = SphereMesh.new(); dome.mesh.radius = 2.0; dome.mesh.height = 2.2
            dome.material_override = white_mat; dome.position.y = 1.1; mesh_node.add_child(dome)
            var halo = MeshInstance3D.new(); halo.mesh = TorusMesh.new(); halo.mesh.outer_radius = 2.3; halo.mesh.inner_radius = 1.95
            halo.material_override = cyan_mat; halo.position.y = 1.2; mesh_node.add_child(halo)
        elif is_tower:
            # Crystalline Obelisk with Continuous Energy Conduit Core
            var pad = MeshInstance3D.new(); pad.mesh = CylinderMesh.new(); pad.mesh.height = 0.6; pad.mesh.bottom_radius = 1.8; pad.mesh.top_radius = 1.6; pad.mesh.radial_segments = 6
            pad.material_override = white_mat; pad.position.y = 0.3; mesh_node.add_child(pad)
            var conduit = MeshInstance3D.new(); conduit.mesh = CylinderMesh.new(); conduit.mesh.height = 3.6; conduit.mesh.bottom_radius = 0.42; conduit.mesh.top_radius = 0.42
            conduit.material_override = cyan_mat; conduit.position.y = 2.1; mesh_node.add_child(conduit)
            var obelisk = MeshInstance3D.new(); obelisk.mesh = BoxMesh.new(); obelisk.mesh.size = Vector3(1.3, 4.5, 1.3)
            obelisk.material_override = white_mat; obelisk.position.y = 3.8; mesh_node.add_child(obelisk)
            var core = MeshInstance3D.new(); core.mesh = SphereMesh.new(); core.mesh.radius = 0.9
            core.material_override = cyan_mat; core.position.y = 1.6; mesh_node.add_child(core)
            mesh_node.set_meta("reach_hover", obelisk)
        else:
            # Towering Crystalline Nexus with Connected Rings
            var base_dais = MeshInstance3D.new(); base_dais.mesh = CylinderMesh.new(); base_dais.mesh.height = 1.2; base_dais.mesh.bottom_radius = 4.6; base_dais.mesh.top_radius = 4.0; base_dais.mesh.radial_segments = 6
            base_dais.material_override = white_mat; base_dais.position.y = 0.6; mesh_node.add_child(base_dais)
            var spire = MeshInstance3D.new(); spire.mesh = CylinderMesh.new(); spire.mesh.height = 7.0; spire.mesh.bottom_radius = 1.4; spire.mesh.top_radius = 0.2
            spire.material_override = cyan_mat; spire.position.y = 4.2; mesh_node.add_child(spire)
            mesh_node.set_meta("reach_pillar", spire)
            for i in range(3):
                var ring = MeshInstance3D.new(); ring.mesh = TorusMesh.new(); ring.mesh.outer_radius = 2.6 - i*0.2; ring.mesh.inner_radius = 2.2 - i*0.2
                ring.material_override = white_mat; ring.position.y = 2.4 + i*1.6; mesh_node.add_child(ring)
                var spoke = MeshInstance3D.new(); spoke.mesh = BoxMesh.new(); spoke.mesh.size = Vector3((2.4 - i*0.2)*2.0, 0.14, 0.18)
                spoke.material_override = white_mat; ring.add_child(spoke)

    # ==========================================
    # 6. THE PLAGUE OF HARMONY (GOLDEN FACE & EYE SANCTUARY)
    # ==========================================
    elif f_type == "Plague of Harmony":
        var gold_mat = HarmonyHuskBuilderScript.get_gold_vein_material()
        var marble_mat = HarmonyHuskBuilderScript.get_husk_body_material()
        var eye_iris_mat = StandardMaterial3D.new(); eye_iris_mat.albedo_color = Color(1.0, 0.22, 0.42); eye_iris_mat.emission_enabled = true; eye_iris_mat.emission = Color(1.0, 0.28, 0.48); eye_iris_mat.emission_energy_multiplier = 3.2

        if is_bay:
            var dais = MeshInstance3D.new(); dais.mesh = CylinderMesh.new(); dais.mesh.height = 1.8; dais.mesh.bottom_radius = 2.4; dais.mesh.top_radius = 2.0
            dais.material_override = marble_mat; dais.position.y = 0.9; mesh_node.add_child(dais)
            var halo = MeshInstance3D.new(); halo.mesh = TorusMesh.new(); halo.mesh.outer_radius = 2.35; halo.mesh.inner_radius = 1.95
            halo.material_override = gold_mat; halo.position.y = 1.8; mesh_node.add_child(halo)
            var face = HarmonyHuskBuilderScript._create_mini_gold_face(1.3, gold_mat)
            face.position = Vector3(0, 1.3, 1.9); mesh_node.add_child(face)
        elif is_tower:
            var pillar = MeshInstance3D.new(); pillar.mesh = CylinderMesh.new(); pillar.mesh.height = 5.4; pillar.mesh.bottom_radius = 1.8; pillar.mesh.top_radius = 1.25
            pillar.material_override = marble_mat; pillar.position.y = 2.7; mesh_node.add_child(pillar)
            var chalice = MeshInstance3D.new(); chalice.mesh = TorusMesh.new(); chalice.mesh.outer_radius = 1.45; chalice.mesh.inner_radius = 1.05
            chalice.material_override = gold_mat; chalice.position.y = 5.35; mesh_node.add_child(chalice)
            for i in range(4):
                var ang = i * (PI / 2.0)
                var f_mask = HarmonyHuskBuilderScript._create_mini_gold_face(0.95, gold_mat)
                f_mask.position = Vector3(sin(ang) * 1.45, 2.8, cos(ang) * 1.45)
                f_mask.rotation.y = ang
                mesh_node.add_child(f_mask)
            var eye_orb = MeshInstance3D.new(); eye_orb.mesh = SphereMesh.new(); eye_orb.mesh.radius = 1.15
            eye_orb.material_override = eye_iris_mat; eye_orb.position.y = 6.0; mesh_node.add_child(eye_orb)
            var eye_ring = MeshInstance3D.new(); eye_ring.mesh = TorusMesh.new(); eye_ring.mesh.outer_radius = 1.55; eye_ring.mesh.inner_radius = 1.10
            eye_ring.material_override = gold_mat; eye_ring.rotation_degrees.x = 65; eye_orb.add_child(eye_ring)
            mesh_node.set_meta("plague_eye", eye_orb)
        else:
            var citadel = MeshInstance3D.new(); citadel.mesh = CylinderMesh.new(); citadel.mesh.height = 4.6; citadel.mesh.bottom_radius = 4.8; citadel.mesh.top_radius = 3.8
            citadel.material_override = marble_mat; citadel.position.y = 2.3; mesh_node.add_child(citadel)
            for i in range(4):
                var ang = i * (PI / 2.0)
                var f_monolith = HarmonyHuskBuilderScript._create_mini_gold_face(1.65, gold_mat)
                f_monolith.position = Vector3(sin(ang) * 4.1, 2.4, cos(ang) * 4.1)
                f_monolith.rotation.y = ang
                mesh_node.add_child(f_monolith)
                var buttress = MeshInstance3D.new(); buttress.mesh = CylinderMesh.new(); buttress.mesh.height = 2.6; buttress.mesh.bottom_radius = 0.45; buttress.mesh.top_radius = 0.20
                buttress.material_override = gold_mat; buttress.position = Vector3(sin(ang) * 2.4, 5.1, cos(ang) * 2.4)
                buttress.rotation_degrees = Vector3(-22.0 * cos(ang), 0.0, 22.0 * sin(ang))
                mesh_node.add_child(buttress)
            var core_eye = MeshInstance3D.new(); core_eye.mesh = SphereMesh.new(); core_eye.mesh.radius = 2.1
            core_eye.material_override = eye_iris_mat; core_eye.position.y = 6.0; mesh_node.add_child(core_eye)
            for r_i in range(2):
                var r_halo = MeshInstance3D.new(); r_halo.mesh = TorusMesh.new()
                r_halo.mesh.outer_radius = 2.6 + r_i * 0.45; r_halo.mesh.inner_radius = 2.05 + r_i * 0.45
                r_halo.material_override = gold_mat; r_halo.rotation_degrees = Vector3(45 * (r_i + 1), 35 * r_i, 20)
                core_eye.add_child(r_halo)
            mesh_node.set_meta("plague_core", core_eye)

    # ==========================================
    # 7. GILDED HARMONY (PALE BLUE, DARK GREEN & GOLD GENETIC HELIX CITADEL)
    # ==========================================
    elif f_type == "Gilded Harmony":
        var gold_mat = HarmonyHuskBuilderScript.get_gold_vein_material()
        var pale_blue_mat = HarmonyHuskBuilderScript.get_gilded_pale_blue_material()
        var dark_green_mat = HarmonyHuskBuilderScript.get_gilded_dark_green_material()

        if is_bay:
            var vat = MeshInstance3D.new(); vat.mesh = CylinderMesh.new(); vat.mesh.height = 2.4; vat.mesh.bottom_radius = 2.2; vat.mesh.top_radius = 1.9
            vat.material_override = dark_green_mat; vat.position.y = 1.2; mesh_node.add_child(vat)
            var bio_dome = MeshInstance3D.new(); bio_dome.mesh = SphereMesh.new(); bio_dome.mesh.radius = 1.65
            bio_dome.material_override = pale_blue_mat; bio_dome.position.y = 2.2; mesh_node.add_child(bio_dome)
            var ring = MeshInstance3D.new(); ring.mesh = TorusMesh.new(); ring.mesh.outer_radius = 2.3; ring.mesh.inner_radius = 1.95
            ring.material_override = gold_mat; ring.position.y = 1.8; mesh_node.add_child(ring)
        elif is_tower:
            var base_pad = MeshInstance3D.new(); base_pad.mesh = CylinderMesh.new(); base_pad.mesh.height = 1.4; base_pad.mesh.bottom_radius = 2.1; base_pad.mesh.top_radius = 1.8
            base_pad.material_override = dark_green_mat; base_pad.position.y = 0.7; mesh_node.add_child(base_pad)
            var central_spine = MeshInstance3D.new(); central_spine.mesh = CylinderMesh.new(); central_spine.mesh.height = 4.8; central_spine.mesh.bottom_radius = 0.28; central_spine.mesh.top_radius = 0.22
            central_spine.material_override = gold_mat; central_spine.position.y = 3.4; mesh_node.add_child(central_spine)
            var helix_root = Node3D.new(); helix_root.position.y = 3.6; mesh_node.add_child(helix_root)
            for i in range(6):
                var y_o = (float(i) - 2.5) * 0.85
                var a = float(i) * 0.9
                for s in [-1.0, 1.0]:
                    var node_b = MeshInstance3D.new(); node_b.mesh = SphereMesh.new(); node_b.mesh.radius = 0.42
                    var p_c = Vector3(cos(a) * 1.1 * s, y_o, sin(a) * 1.1 * s)
                    node_b.position = p_c
                    node_b.material_override = dark_green_mat if s < 0.0 else pale_blue_mat
                    helix_root.add_child(node_b)
                    if i < 5:
                        var next_yo = (float(i + 1) - 2.5) * 0.85
                        var next_a = float(i + 1) * 0.9
                        var p_n = Vector3(cos(next_a) * 1.1 * s, next_yo, sin(next_a) * 1.1 * s)
                        var h_link = MeshInstance3D.new(); h_link.mesh = CylinderMesh.new()
                        h_link.mesh.top_radius = 0.14; h_link.mesh.bottom_radius = 0.14; h_link.mesh.height = p_c.distance_to(p_n)
                        h_link.position = (p_c + p_n) * 0.5
                        h_link.material_override = dark_green_mat if s < 0.0 else pale_blue_mat
                        helix_root.add_child(h_link)
                var bar = MeshInstance3D.new(); bar.mesh = CylinderMesh.new(); bar.mesh.top_radius = 0.10; bar.mesh.bottom_radius = 0.10; bar.mesh.height = 2.2
                bar.position = Vector3(0, y_o, 0); bar.rotation = Vector3(0, -a, PI * 0.5); bar.material_override = gold_mat
                helix_root.add_child(bar)
            mesh_node.set_meta("gilded_helix", helix_root)
        else:
            var bio_base = MeshInstance3D.new(); bio_base.mesh = CylinderMesh.new(); bio_base.mesh.height = 3.4; bio_base.mesh.bottom_radius = 4.8; bio_base.mesh.top_radius = 4.0
            bio_base.material_override = dark_green_mat; bio_base.position.y = 1.7; mesh_node.add_child(bio_base)
            var core_stalk = MeshInstance3D.new(); core_stalk.mesh = CylinderMesh.new(); core_stalk.mesh.height = 2.4; core_stalk.mesh.bottom_radius = 1.6; core_stalk.mesh.top_radius = 1.2
            core_stalk.material_override = gold_mat; core_stalk.position.y = 4.0; mesh_node.add_child(core_stalk)
            var gene_core = MeshInstance3D.new(); gene_core.mesh = SphereMesh.new(); gene_core.mesh.radius = 2.3
            gene_core.material_override = pale_blue_mat; gene_core.position.y = 5.0; mesh_node.add_child(gene_core)
            for i in range(3):
                var g_ring = MeshInstance3D.new(); g_ring.mesh = TorusMesh.new()
                g_ring.mesh.outer_radius = 2.7 + i * 0.45; g_ring.mesh.inner_radius = 2.2 + i * 0.45
                g_ring.material_override = gold_mat; g_ring.rotation_degrees = Vector3(40 * (i + 1), 50 * i, 25)
                gene_core.add_child(g_ring)
            mesh_node.set_meta("gilded_core", gene_core)

    # ==========================================
    # 8. PLANETARY PRIMITIVES: EMPIRE AGES (FEUDAL & STONE AGE)
    # ==========================================
    elif f_type == "Planetary Primitives":
        var stone_mat = StandardMaterial3D.new(); stone_mat.albedo_color = Color(0.48, 0.48, 0.50); stone_mat.roughness = 0.95
        var dark_timber_mat = StandardMaterial3D.new(); dark_timber_mat.albedo_color = Color(0.35, 0.22, 0.12); dark_timber_mat.roughness = 0.88
        var royal_cloth_mat = StandardMaterial3D.new(); royal_cloth_mat.albedo_color = Color(0.68, 0.15, 0.18); royal_cloth_mat.roughness = 0.75
        var gold_trim_mat = StandardMaterial3D.new(); gold_trim_mat.albedo_color = Color(0.88, 0.75, 0.25); gold_trim_mat.metallic = 0.85; gold_trim_mat.roughness = 0.3
        var iron_mat = StandardMaterial3D.new(); iron_mat.albedo_color = Color(0.28, 0.28, 0.30); iron_mat.metallic = 0.9; iron_mat.roughness = 0.4
        
        if is_bay:
            # Medieval Royal War Pavilion & Camp
            var platform = MeshInstance3D.new(); platform.mesh = CylinderMesh.new(); platform.mesh.height = 0.4; platform.mesh.bottom_radius = 3.6; platform.mesh.top_radius = 3.4; platform.mesh.radial_segments = 8
            platform.material_override = dark_timber_mat; platform.position.y = 0.2; mesh_node.add_child(platform)
            # Conical War Tent
            var tent_body = MeshInstance3D.new(); tent_body.mesh = CylinderMesh.new(); tent_body.mesh.height = 2.4; tent_body.mesh.bottom_radius = 2.8; tent_body.mesh.top_radius = 2.4; tent_body.mesh.radial_segments = 12
            tent_body.material_override = royal_cloth_mat; tent_body.position.y = 1.6; mesh_node.add_child(tent_body)
            var tent_roof = MeshInstance3D.new(); tent_roof.mesh = CylinderMesh.new(); tent_roof.mesh.height = 2.2; tent_roof.mesh.bottom_radius = 2.9; tent_roof.mesh.top_radius = 0.05; tent_roof.mesh.radial_segments = 12
            tent_roof.material_override = royal_cloth_mat; tent_roof.position.y = 3.8; mesh_node.add_child(tent_roof)
            # Center Flagstaff & Pennant
            var mast = MeshInstance3D.new(); mast.mesh = CylinderMesh.new(); mast.mesh.height = 2.8; mast.mesh.bottom_radius = 0.08; mast.mesh.top_radius = 0.04
            mast.material_override = dark_timber_mat; mast.position.y = 5.6; mesh_node.add_child(mast)
            var pennant = MeshInstance3D.new(); pennant.mesh = BoxMesh.new(); pennant.mesh.size = Vector3(0.04, 0.45, 1.2)
            pennant.material_override = gold_trim_mat; pennant.position = Vector3(0.0, 6.2, 0.6); mesh_node.add_child(pennant)
            # Braziers with flame
            for side in [-1.0, 1.0]:
                var brazier = MeshInstance3D.new(); brazier.mesh = CylinderMesh.new(); brazier.mesh.height = 1.1; brazier.mesh.bottom_radius = 0.35; brazier.mesh.top_radius = 0.5
                brazier.material_override = iron_mat; brazier.position = Vector3(side * 2.2, 0.55, 2.2); mesh_node.add_child(brazier)
                var flame = MeshInstance3D.new(); flame.mesh = SphereMesh.new(); flame.mesh.radius = 0.28; flame.mesh.height = 0.45
                var f_mat = StandardMaterial3D.new(); f_mat.albedo_color = Color(1.0, 0.55, 0.1); f_mat.emission_enabled = true; f_mat.emission = Color(1.0, 0.5, 0.1); f_mat.emission_energy_multiplier = 3.0
                flame.material_override = f_mat; flame.position = Vector3(side * 2.2, 1.25, 2.2); mesh_node.add_child(flame)
        elif is_tower:
            # Medieval Ashlar Stone Tower with Mounted Swiveling Ballista
            var tower_body = MeshInstance3D.new(); tower_body.mesh = CylinderMesh.new(); tower_body.mesh.height = 4.2; tower_body.mesh.bottom_radius = 2.3; tower_body.mesh.top_radius = 1.9; tower_body.mesh.radial_segments = 8
            tower_body.material_override = stone_mat; tower_body.position.y = 2.1; mesh_node.add_child(tower_body)
            # Crenellated Battlements
            var platform_deck = MeshInstance3D.new(); platform_deck.mesh = CylinderMesh.new(); platform_deck.mesh.height = 0.4; platform_deck.mesh.bottom_radius = 2.1; platform_deck.mesh.top_radius = 2.2; platform_deck.mesh.radial_segments = 8
            platform_deck.material_override = dark_timber_mat; platform_deck.position.y = 4.3; mesh_node.add_child(platform_deck)
            for i in range(8):
                var crenel = MeshInstance3D.new(); crenel.mesh = BoxMesh.new(); crenel.mesh.size = Vector3(0.55, 0.7, 0.3)
                crenel.material_override = stone_mat
                var a = i * (PI / 4.0)
                crenel.position = Vector3(cos(a) * 2.05, 4.75, sin(a) * 2.05)
                crenel.rotation.y = -a
                mesh_node.add_child(crenel)
            # Swiveling Ballista Siege Weapon
            var swivel_mount = MeshInstance3D.new(); swivel_mount.mesh = CylinderMesh.new(); swivel_mount.mesh.height = 0.45; swivel_mount.mesh.bottom_radius = 0.75; swivel_mount.mesh.top_radius = 0.65
            swivel_mount.material_override = iron_mat; swivel_mount.position.y = 4.65; mesh_node.add_child(swivel_mount)
            
            var ballista_carriage = Node3D.new()
            ballista_carriage.name = "BallistaCarriage"
            ballista_carriage.position.y = 5.0
            mesh_node.add_child(ballista_carriage)
            mesh_node.set_meta("ballista_turret", ballista_carriage)
            mesh_node.set_meta("dominion_turret", ballista_carriage)
            
            # Stock & Tiller
            var b_stock = MeshInstance3D.new(); b_stock.mesh = BoxMesh.new(); b_stock.mesh.size = Vector3(0.5, 0.45, 3.0)
            b_stock.material_override = dark_timber_mat; b_stock.position = Vector3(0, 0.1, 0.3); ballista_carriage.add_child(b_stock)
            # Composite Bow Limbs (Prods) & Iron Torsion Skein Housings
            var b_limbs = MeshInstance3D.new(); b_limbs.mesh = BoxMesh.new(); b_limbs.mesh.size = Vector3(2.6, 0.28, 0.22)
            b_limbs.material_override = dark_timber_mat; b_limbs.position = Vector3(0, 0.2, 1.4); ballista_carriage.add_child(b_limbs)
            for s_side in [-1.0, 1.0]:
                var skein = MeshInstance3D.new(); skein.mesh = CylinderMesh.new(); skein.mesh.height = 0.65; skein.mesh.bottom_radius = 0.16; skein.mesh.top_radius = 0.16
                skein.material_override = iron_mat; skein.position = Vector3(s_side * 0.42, 0.2, 1.4); ballista_carriage.add_child(skein)
                var b_str = MeshInstance3D.new(); b_str.mesh = CylinderMesh.new(); b_str.mesh.height = 2.06; b_str.mesh.bottom_radius = 0.025; b_str.mesh.top_radius = 0.025
                b_str.material_override = gold_trim_mat
                b_str.position = Vector3(s_side * 0.65, 0.22, 0.60)
                b_str.rotation_degrees = Vector3(90.0, s_side * 39.0, 0.0)
                ballista_carriage.add_child(b_str)
            # Winch Spool at rear
            var winch = MeshInstance3D.new(); winch.mesh = CylinderMesh.new(); winch.mesh.height = 0.6; winch.mesh.bottom_radius = 0.25; winch.mesh.top_radius = 0.25
            winch.material_override = iron_mat; winch.rotation_degrees.z = 90; winch.position = Vector3(0, 0.2, -0.9); ballista_carriage.add_child(winch)
            # Massive Spear Bolt loaded in flight channel ready to fire
            var bolt = MeshInstance3D.new(); bolt.mesh = CylinderMesh.new(); bolt.mesh.height = 2.2; bolt.mesh.bottom_radius = 0.08; bolt.mesh.top_radius = 0.04
            bolt.material_override = iron_mat; bolt.rotation_degrees.x = 90; bolt.position = Vector3(0, 0.4, 0.7); ballista_carriage.add_child(bolt)
            var bolt_tip = MeshInstance3D.new(); bolt_tip.mesh = CylinderMesh.new(); bolt_tip.mesh.height = 0.45; bolt_tip.mesh.bottom_radius = 0.14; bolt_tip.mesh.top_radius = 0.01
            bolt_tip.material_override = iron_mat; bolt_tip.rotation_degrees.x = -90; bolt_tip.position = Vector3(0, 0.4, 1.95); ballista_carriage.add_child(bolt_tip)
        else:
            # Massive Feudal Castle Keep Stronghold
            var keep = MeshInstance3D.new(); keep.mesh = BoxMesh.new(); keep.mesh.size = Vector3(6.4, 4.6, 6.4)
            keep.material_override = stone_mat; keep.position.y = 2.3; mesh_node.add_child(keep)
            # 4 Corner Bastions with Conical Roofs
            for x_sign in [-1.0, 1.0]:
                for z_sign in [-1.0, 1.0]:
                    var bastion = MeshInstance3D.new(); bastion.mesh = CylinderMesh.new(); bastion.mesh.height = 6.2; bastion.mesh.bottom_radius = 1.35; bastion.mesh.top_radius = 1.25
                    bastion.material_override = stone_mat; bastion.position = Vector3(x_sign * 3.2, 3.1, z_sign * 3.2); mesh_node.add_child(bastion)
                    var b_roof = MeshInstance3D.new(); b_roof.mesh = CylinderMesh.new(); b_roof.mesh.height = 1.8; b_roof.mesh.bottom_radius = 1.45; b_roof.mesh.top_radius = 0.05
                    b_roof.material_override = dark_timber_mat; b_roof.position = Vector3(x_sign * 3.2, 7.0, z_sign * 3.2); mesh_node.add_child(b_roof)
            # Castle Gate Portcullis
            var gate = MeshInstance3D.new(); gate.mesh = BoxMesh.new(); gate.mesh.size = Vector3(2.4, 3.0, 0.3)
            gate.material_override = iron_mat; gate.position = Vector3(0, 1.5, 3.25); mesh_node.add_child(gate)
            # Royal Battlements
            var battlements = MeshInstance3D.new(); battlements.mesh = BoxMesh.new(); battlements.mesh.size = Vector3(5.6, 0.8, 5.6)
            battlements.material_override = stone_mat; battlements.position.y = 5.0; mesh_node.add_child(battlements)

    # ==========================================
    # 9. GALACTIC WILDLIFE (LIVING BIOSPHERE WORLD-TREE & EAGLE EYRIE)
    # ==========================================
    elif f_type == "Galactic Wildlife":
        var bark_mat = StandardMaterial3D.new(); bark_mat.albedo_color = Color(0.36, 0.22, 0.12); bark_mat.roughness = 0.90
        var canopy_mat = StandardMaterial3D.new(); canopy_mat.albedo_color = Color(0.16, 0.56, 0.22); canopy_mat.roughness = 0.78
        var moss_rock_mat = StandardMaterial3D.new(); moss_rock_mat.albedo_color = Color(0.38, 0.44, 0.34); moss_rock_mat.roughness = 0.92
        var bio_glow_mat = StandardMaterial3D.new(); bio_glow_mat.albedo_color = Color(0.28, 0.95, 0.52); bio_glow_mat.emission_enabled = true; bio_glow_mat.emission = Color(0.22, 0.88, 0.44); bio_glow_mat.emission_energy_multiplier = 2.0

        if is_bay:
            var stump = MeshInstance3D.new(); stump.mesh = CylinderMesh.new(); stump.mesh.height = 2.6; stump.mesh.bottom_radius = 2.8; stump.mesh.top_radius = 2.2
            stump.material_override = bark_mat; stump.position.y = 1.3; mesh_node.add_child(stump)
            var moss_cap = MeshInstance3D.new(); moss_cap.mesh = SphereMesh.new(); moss_cap.mesh.radius = 2.3; moss_cap.mesh.height = 1.8
            moss_cap.material_override = canopy_mat; moss_cap.position.y = 2.6; mesh_node.add_child(moss_cap)
            var den_glow = MeshInstance3D.new(); den_glow.mesh = SphereMesh.new(); den_glow.mesh.radius = 0.75
            den_glow.material_override = bio_glow_mat; den_glow.position = Vector3(0, 1.1, 1.8); mesh_node.add_child(den_glow)
        elif is_tower:
            var trunk = MeshInstance3D.new(); trunk.mesh = CylinderMesh.new(); trunk.mesh.height = 4.6; trunk.mesh.bottom_radius = 2.1; trunk.mesh.top_radius = 1.4
            trunk.material_override = bark_mat; trunk.position.y = 2.3; mesh_node.add_child(trunk)
            var nest_rim = MeshInstance3D.new(); nest_rim.mesh = TorusMesh.new(); nest_rim.mesh.outer_radius = 2.0; nest_rim.mesh.inner_radius = 1.35
            nest_rim.material_override = bark_mat; nest_rim.position.y = 4.6; mesh_node.add_child(nest_rim)
            for b_i in range(4):
                var ang = float(b_i) * PI * 0.5
                var leaf = MeshInstance3D.new(); leaf.mesh = SphereMesh.new(); leaf.mesh.radius = 1.1; leaf.mesh.height = 1.4
                leaf.material_override = canopy_mat; leaf.position = Vector3(cos(ang) * 1.6, 4.2, sin(ang) * 1.6)
                mesh_node.add_child(leaf)
            var turret_nest = Node3D.new(); turret_nest.position.y = 4.9; mesh_node.add_child(turret_nest)
            # Sculpted Giant Guardian Eagle perched in the Eyrie Nest
            var feather_mat = StandardMaterial3D.new(); feather_mat.albedo_color = Color(0.28, 0.18, 0.10); feather_mat.roughness = 0.78
            var crest_mat = StandardMaterial3D.new(); crest_mat.albedo_color = Color(0.95, 0.94, 0.90); crest_mat.roughness = 0.65
            var beak_mat = StandardMaterial3D.new(); beak_mat.albedo_color = Color(0.95, 0.75, 0.15); beak_mat.roughness = 0.35
            var eagle_body = MeshInstance3D.new(); eagle_body.mesh = SphereMesh.new(); eagle_body.mesh.radius = 0.68; eagle_body.mesh.height = 1.45
            eagle_body.material_override = feather_mat; eagle_body.position = Vector3(0, 0.35, 0.10); eagle_body.rotation_degrees.x = -24.0; turret_nest.add_child(eagle_body)
            var eagle_head = MeshInstance3D.new(); eagle_head.mesh = SphereMesh.new(); eagle_head.mesh.radius = 0.42; eagle_head.mesh.height = 0.82
            eagle_head.material_override = crest_mat; eagle_head.position = Vector3(0, 1.05, -0.35); turret_nest.add_child(eagle_head)
            var eagle_beak = MeshInstance3D.new(); eagle_beak.mesh = CylinderMesh.new(); eagle_beak.mesh.bottom_radius = 0.20; eagle_beak.mesh.top_radius = 0.02; eagle_beak.mesh.height = 0.58
            eagle_beak.material_override = beak_mat; eagle_beak.position = Vector3(0, 0.98, -0.82); eagle_beak.rotation_degrees.x = -76.0; turret_nest.add_child(eagle_beak)
            for w_s in [-1.0, 1.0]:
                var e_wing = MeshInstance3D.new(); e_wing.mesh = BoxMesh.new(); e_wing.mesh.size = Vector3(1.35, 0.16, 0.85)
                e_wing.material_override = feather_mat; e_wing.position = Vector3(w_s * 0.95, 0.55, -0.05); e_wing.rotation_degrees = Vector3(15.0, w_s * -12.0, w_s * 22.0)
                turret_nest.add_child(e_wing)
            mesh_node.set_meta("dominion_turret", turret_nest)
        else:
            var world_trunk = MeshInstance3D.new(); world_trunk.mesh = CylinderMesh.new(); world_trunk.mesh.height = 5.4; world_trunk.mesh.bottom_radius = 4.6; world_trunk.mesh.top_radius = 3.1
            world_trunk.material_override = bark_mat; world_trunk.position.y = 2.7; mesh_node.add_child(world_trunk)
            for r_i in range(6):
                var ang = float(r_i) * (TAU / 6.0)
                var root_buttress = MeshInstance3D.new(); root_buttress.mesh = BoxMesh.new(); root_buttress.mesh.size = Vector3(1.2, 1.8, 2.8)
                root_buttress.material_override = bark_mat
                root_buttress.position = Vector3(cos(ang) * 4.2, 0.9, sin(ang) * 4.2)
                root_buttress.rotation.y = -ang
                mesh_node.add_child(root_buttress)
            var crown_main = MeshInstance3D.new(); crown_main.mesh = SphereMesh.new(); crown_main.mesh.radius = 4.4; crown_main.mesh.height = 4.6
            crown_main.material_override = canopy_mat; crown_main.position.y = 6.2; mesh_node.add_child(crown_main)
            var heart_bloom = MeshInstance3D.new(); heart_bloom.mesh = SphereMesh.new(); heart_bloom.mesh.radius = 1.2
            heart_bloom.material_override = bio_glow_mat; heart_bloom.position = Vector3(0, 3.2, 3.3); mesh_node.add_child(heart_bloom)

    # ==========================================
    # 10. THE NIGHTMARE COURT (GOTHIC CRYPT & GARGOYLE SPIRE)
    # ==========================================
    elif f_type == "The Nightmare Court":
        var stone_mat = StandardMaterial3D.new(); stone_mat.albedo_color = Color(0.18, 0.16, 0.20); stone_mat.roughness = 0.92
        var slate_mat = StandardMaterial3D.new(); slate_mat.albedo_color = Color(0.10, 0.08, 0.12); slate_mat.roughness = 0.85
        var iron_mat = StandardMaterial3D.new(); iron_mat.albedo_color = Color(0.24, 0.24, 0.26); iron_mat.metallic = 0.85; iron_mat.roughness = 0.35
        var soul_mat = StandardMaterial3D.new(); soul_mat.albedo_color = Color(0.25, 0.95, 0.45); soul_mat.emission_enabled = true; soul_mat.emission = Color(0.20, 0.90, 0.40); soul_mat.emission_energy_multiplier = 3.5
        var blood_mat = StandardMaterial3D.new(); blood_mat.albedo_color = Color(0.95, 0.12, 0.22); blood_mat.emission_enabled = true; blood_mat.emission = Color(0.90, 0.08, 0.15); blood_mat.emission_energy_multiplier = 3.0
        var pumpkin_mat = StandardMaterial3D.new(); pumpkin_mat.albedo_color = Color(1.0, 0.52, 0.10); pumpkin_mat.emission_enabled = true; pumpkin_mat.emission = Color(1.0, 0.48, 0.08); pumpkin_mat.emission_energy_multiplier = 3.2

        if is_bay:
            # Graveyard Crypt Pavilion with Jack-o'-Lantern Lantern
            var crypt = MeshInstance3D.new(); crypt.mesh = BoxMesh.new(); crypt.mesh.size = Vector3(3.8, 2.4, 3.8)
            crypt.material_override = stone_mat; crypt.position.y = 1.2; mesh_node.add_child(crypt)
            var roof = MeshInstance3D.new(); roof.mesh = BoxMesh.new(); roof.mesh.size = Vector3(4.2, 0.6, 4.2)
            roof.material_override = slate_mat; roof.position.y = 2.6; mesh_node.add_child(roof)
            # Iron Gate
            var gate = MeshInstance3D.new(); gate.mesh = BoxMesh.new(); gate.mesh.size = Vector3(1.6, 2.0, 0.15)
            gate.material_override = iron_mat; gate.position = Vector3(0, 1.0, 1.92); mesh_node.add_child(gate)
            # Hanging Jack-o'-Lantern
            var lantern = MeshInstance3D.new(); lantern.mesh = SphereMesh.new(); lantern.mesh.radius = 0.32; lantern.mesh.height = 0.58
            lantern.material_override = pumpkin_mat; lantern.position = Vector3(1.4, 2.0, 1.95); mesh_node.add_child(lantern)
        elif is_tower:
            # Gothic Gargoyle Spire with Swiveling Gargoyle Aim Turret
            var column = MeshInstance3D.new(); column.mesh = CylinderMesh.new(); column.mesh.height = 4.8; column.mesh.bottom_radius = 1.9; column.mesh.top_radius = 1.5; column.mesh.radial_segments = 8
            column.material_override = stone_mat; column.position.y = 2.4; mesh_node.add_child(column)
            # Spiked Iron Parapet Platform
            var platform = MeshInstance3D.new(); platform.mesh = CylinderMesh.new(); platform.mesh.height = 0.5; platform.mesh.bottom_radius = 2.1; platform.mesh.top_radius = 2.1; platform.mesh.radial_segments = 8
            platform.material_override = slate_mat; platform.position.y = 4.9; mesh_node.add_child(platform)
            for i in range(8):
                var spike = MeshInstance3D.new(); spike.mesh = CylinderMesh.new(); spike.mesh.height = 0.9; spike.mesh.bottom_radius = 0.08; spike.mesh.top_radius = 0.01
                spike.material_override = iron_mat
                var a = i * (TAU / 8.0)
                spike.position = Vector3(cos(a) * 2.0, 5.5, sin(a) * 2.0); mesh_node.add_child(spike)
            # Swiveling Gargoyle Turret
            var gargoyle_turret = Node3D.new(); gargoyle_turret.position.y = 5.2; mesh_node.add_child(gargoyle_turret)
            var g_body = MeshInstance3D.new(); g_body.mesh = BoxMesh.new(); g_body.mesh.size = Vector3(0.85, 0.95, 1.2)
            g_body.material_override = stone_mat; g_body.position = Vector3(0, 0.45, 0.1); gargoyle_turret.add_child(g_body)
            var g_head = MeshInstance3D.new(); g_head.mesh = BoxMesh.new(); g_head.mesh.size = Vector3(0.55, 0.55, 0.65)
            g_head.material_override = stone_mat; g_head.position = Vector3(0, 0.95, 0.65); gargoyle_turret.add_child(g_head)
            for s in [-1.0, 1.0]:
                var g_eye = MeshInstance3D.new(); g_eye.mesh = SphereMesh.new(); g_eye.mesh.radius = 0.08
                g_eye.material_override = soul_mat; g_eye.position = Vector3(s * 0.18, 1.05, 0.96); gargoyle_turret.add_child(g_eye)
                var g_wing = MeshInstance3D.new(); g_wing.mesh = BoxMesh.new(); g_wing.mesh.size = Vector3(1.1, 0.15, 0.75)
                g_wing.material_override = stone_mat; g_wing.position = Vector3(s * 0.85, 0.75, -0.15); g_wing.rotation_degrees = Vector3(20, s * -15, s * 25); gargoyle_turret.add_child(g_wing)
            mesh_node.set_meta("dominion_turret", gargoyle_turret)
        else:
            # Massive Gothic Mausoleum / Vampire Cathedral HQ
            var keep = MeshInstance3D.new(); keep.mesh = BoxMesh.new(); keep.mesh.size = Vector3(6.5, 4.8, 6.5)
            keep.material_override = stone_mat; keep.position.y = 2.4; mesh_node.add_child(keep)
            var roof = MeshInstance3D.new(); roof.mesh = BoxMesh.new(); roof.mesh.size = Vector3(5.8, 2.2, 5.8)
            roof.material_override = slate_mat; roof.position.y = 5.6; mesh_node.add_child(roof)
            # 4 Ribbed Corner Spires with Gargoyle Perches
            for xs in [-1.0, 1.0]:
                for zs in [-1.0, 1.0]:
                    var spire = MeshInstance3D.new(); spire.mesh = CylinderMesh.new(); spire.mesh.height = 7.0; spire.mesh.bottom_radius = 0.95; spire.mesh.top_radius = 0.15
                    spire.material_override = slate_mat; spire.position = Vector3(xs * 3.2, 5.5, zs * 3.2); mesh_node.add_child(spire)
            # Glowing Stained Glass Windows (Blood & Soul)
            var blood_win = MeshInstance3D.new(); blood_win.mesh = BoxMesh.new(); blood_win.mesh.size = Vector3(1.4, 2.4, 0.15)
            blood_win.material_override = blood_mat; blood_win.position = Vector3(0, 3.4, 3.3); mesh_node.add_child(blood_win)
            for s in [-1.0, 1.0]:
                var soul_win = MeshInstance3D.new(); soul_win.mesh = BoxMesh.new(); soul_win.mesh.size = Vector3(0.15, 2.0, 1.2)
                soul_win.material_override = soul_mat; soul_win.position = Vector3(s * 3.3, 3.2, 0); mesh_node.add_child(soul_win)
                # Flanking Soul Fire Braziers
                var brazier = MeshInstance3D.new(); brazier.mesh = SphereMesh.new(); brazier.mesh.radius = 0.45
                brazier.material_override = soul_mat; brazier.position = Vector3(s * 2.2, 1.2, 3.4); mesh_node.add_child(brazier)

    # ==========================================
    # 11. THE WINTER COURT (FROST PALACE & TOY CITADEL)
    # ==========================================
    elif f_type == "The Winter Court":
        var stone_mat = StandardMaterial3D.new(); stone_mat.albedo_color = Color(0.42, 0.48, 0.58); stone_mat.roughness = 0.80
        var slate_mat = StandardMaterial3D.new(); slate_mat.albedo_color = Color(0.15, 0.25, 0.48); slate_mat.roughness = 0.70
        var snow_mat = StandardMaterial3D.new(); snow_mat.albedo_color = Color(0.94, 0.96, 1.0); snow_mat.roughness = 0.60
        var amber_mat = StandardMaterial3D.new(); amber_mat.albedo_color = Color(1.0, 0.80, 0.25); amber_mat.emission_enabled = true; amber_mat.emission = Color(1.0, 0.72, 0.18); amber_mat.emission_energy_multiplier = 3.0
        var ice_mat = StandardMaterial3D.new(); ice_mat.albedo_color = Color(0.55, 0.90, 1.0, 0.85); ice_mat.metallic = 0.2; ice_mat.roughness = 0.15; ice_mat.emission_enabled = true; ice_mat.emission = Color(0.45, 0.85, 1.0); ice_mat.emission_energy_multiplier = 2.5
        var gold_mat = StandardMaterial3D.new(); gold_mat.albedo_color = Color(1.0, 0.85, 0.20); gold_mat.metallic = 0.85; gold_mat.roughness = 0.25; gold_mat.emission_enabled = true; gold_mat.emission = Color(1.0, 0.80, 0.15); gold_mat.emission_energy_multiplier = 3.5

        if is_bay:
            # Toymaker's Workshop Outpost with Brick Chimney
            var cabin = MeshInstance3D.new(); cabin.mesh = BoxMesh.new(); cabin.mesh.size = Vector3(3.8, 2.2, 3.6)
            cabin.material_override = stone_mat; cabin.position.y = 1.1; mesh_node.add_child(cabin)
            var roof = MeshInstance3D.new(); roof.mesh = BoxMesh.new(); roof.mesh.size = Vector3(4.2, 0.6, 4.0)
            roof.material_override = slate_mat; roof.position.y = 2.4; mesh_node.add_child(roof)
            var snow_roof = MeshInstance3D.new(); snow_roof.mesh = BoxMesh.new(); snow_roof.mesh.size = Vector3(4.3, 0.25, 4.1)
            snow_roof.material_override = snow_mat; snow_roof.position.y = 2.8; mesh_node.add_child(snow_roof)
            # Brick Chimney
            var chim = MeshInstance3D.new(); chim.mesh = BoxMesh.new(); chim.mesh.size = Vector3(0.65, 1.8, 0.65)
            chim.material_override = slate_mat; chim.position = Vector3(1.2, 3.0, -1.0); mesh_node.add_child(chim)
            # Warm glowing window
            var win = MeshInstance3D.new(); win.mesh = BoxMesh.new(); win.mesh.size = Vector3(1.2, 0.9, 0.15)
            win.material_override = amber_mat; win.position = Vector3(0, 1.2, 1.85); mesh_node.add_child(win)
        elif is_tower:
            # Glacial Ice Watchtower Spire with Swiveling Snow-Cannon Turret
            var spire = MeshInstance3D.new(); spire.mesh = CylinderMesh.new(); spire.mesh.height = 4.8; spire.mesh.bottom_radius = 1.8; spire.mesh.top_radius = 1.3; spire.mesh.radial_segments = 8
            spire.material_override = ice_mat; spire.position.y = 2.4; mesh_node.add_child(spire)
            var platform = MeshInstance3D.new(); platform.mesh = CylinderMesh.new(); platform.mesh.height = 0.5; platform.mesh.bottom_radius = 2.0; platform.mesh.top_radius = 2.0
            platform.material_override = stone_mat; platform.position.y = 4.9; mesh_node.add_child(platform)
            var snow_rim = MeshInstance3D.new(); snow_rim.mesh = TorusMesh.new(); snow_rim.mesh.inner_radius = 1.7; snow_rim.mesh.outer_radius = 2.1
            snow_rim.material_override = snow_mat; snow_rim.position.y = 5.2; mesh_node.add_child(snow_rim)
            # Swiveling Snow Cannon Turret
            var cannon_turret = Node3D.new(); cannon_turret.position.y = 5.3; mesh_node.add_child(cannon_turret)
            var c_base = MeshInstance3D.new(); c_base.mesh = BoxMesh.new(); c_base.mesh.size = Vector3(1.0, 0.8, 1.2)
            c_base.material_override = stone_mat; c_base.position.y = 0.4; cannon_turret.add_child(c_base)
            for s in [-1.0, 1.0]:
                var barrel = MeshInstance3D.new(); barrel.mesh = CylinderMesh.new(); barrel.mesh.height = 2.2; barrel.mesh.bottom_radius = 0.16; barrel.mesh.top_radius = 0.14
                barrel.material_override = gold_mat; barrel.position = Vector3(s * 0.32, 0.45, 1.2); barrel.rotation_degrees.x = 90
                cannon_turret.add_child(barrel)
            mesh_node.set_meta("dominion_turret", cannon_turret)
        else:
            # Majestic Winter Ice Palace / Santa's Grand Fortress HQ
            var palace = MeshInstance3D.new(); palace.mesh = BoxMesh.new(); palace.mesh.size = Vector3(6.6, 4.6, 6.6)
            palace.material_override = stone_mat; palace.position.y = 2.3; mesh_node.add_child(palace)
            var palace_roof = MeshInstance3D.new(); palace_roof.mesh = BoxMesh.new(); palace_roof.mesh.size = Vector3(6.0, 1.8, 6.0)
            palace_roof.material_override = slate_mat; palace_roof.position.y = 5.4; mesh_node.add_child(palace_roof)
            var snow_cover = MeshInstance3D.new(); snow_cover.mesh = BoxMesh.new(); snow_cover.mesh.size = Vector3(6.2, 0.35, 6.2)
            snow_cover.material_override = snow_mat; snow_cover.position.y = 6.4; mesh_node.add_child(snow_cover)
            # 4 Corner Towers
            for xs in [-1.0, 1.0]:
                for zs in [-1.0, 1.0]:
                    var tower = MeshInstance3D.new(); tower.mesh = CylinderMesh.new(); tower.mesh.height = 6.8; tower.mesh.bottom_radius = 1.2; tower.mesh.top_radius = 0.85
                    tower.material_override = stone_mat; tower.position = Vector3(xs * 3.3, 3.4, zs * 3.3); mesh_node.add_child(tower)
                    var t_cone = MeshInstance3D.new(); t_cone.mesh = CylinderMesh.new(); t_cone.mesh.height = 2.2; t_cone.mesh.bottom_radius = 1.0; t_cone.mesh.top_radius = 0.05
                    t_cone.material_override = ice_mat; t_cone.position = Vector3(xs * 3.3, 7.8, zs * 3.3); mesh_node.add_child(t_cone)
            # Radiant Golden Holiday Star atop Central Peak
            var star = MeshInstance3D.new(); star.mesh = SphereMesh.new(); star.mesh.radius = 0.65; star.mesh.height = 1.3
            star.material_override = gold_mat; star.position.y = 8.2; mesh_node.add_child(star)
            mesh_node.set_meta("winter_star", star)
            # Warm Glowing Amber Windows
            var win_front = MeshInstance3D.new(); win_front.mesh = BoxMesh.new(); win_front.mesh.size = Vector3(2.4, 1.8, 0.15)
            win_front.material_override = amber_mat; win_front.position = Vector3(0, 2.5, 3.35); mesh_node.add_child(win_front)

    # ==========================================
    # 12. THE MAGMA BORN (VOLCANIC CITADEL & CRUCIBLE FOUNDRY)
    # ==========================================
    elif f_type == "The Magma Born":
        var basalt_mat = StandardMaterial3D.new(); basalt_mat.albedo_color = Color(0.14, 0.11, 0.12); basalt_mat.roughness = 0.92
        var obsidian_mat = StandardMaterial3D.new(); obsidian_mat.albedo_color = Color(0.06, 0.05, 0.07); obsidian_mat.roughness = 0.35; obsidian_mat.metallic = 0.7
        var magma_mat = StandardMaterial3D.new(); magma_mat.albedo_color = Color(1.0, 0.42, 0.05); magma_mat.emission_enabled = true; magma_mat.emission = Color(1.0, 0.42, 0.05); magma_mat.emission_energy_multiplier = 3.8

        if is_bay:
            # Volcanic Magma Foundry Outpost
            var foundry = MeshInstance3D.new(); foundry.mesh = BoxMesh.new(); foundry.mesh.size = Vector3(4.0, 2.4, 3.8)
            foundry.material_override = basalt_mat; foundry.position.y = 1.2; mesh_node.add_child(foundry)
            var crucible = MeshInstance3D.new(); crucible.mesh = CylinderMesh.new(); crucible.mesh.height = 1.2; crucible.mesh.bottom_radius = 1.5; crucible.mesh.top_radius = 1.6
            crucible.material_override = magma_mat; crucible.position = Vector3(0, 2.0, 0); mesh_node.add_child(crucible)
        elif is_tower:
            # Molten Basalt Citadel Spire with Magma Cannon
            var spire = MeshInstance3D.new(); spire.mesh = CylinderMesh.new(); spire.mesh.height = 5.2; spire.mesh.bottom_radius = 2.0; spire.mesh.top_radius = 1.4; spire.mesh.radial_segments = 8
            spire.material_override = basalt_mat; spire.position.y = 2.6; mesh_node.add_child(spire)
            var m_core = MeshInstance3D.new(); m_core.mesh = CylinderMesh.new(); m_core.mesh.height = 0.4; m_core.mesh.bottom_radius = 1.6; m_core.mesh.top_radius = 1.6
            m_core.material_override = magma_mat; m_core.position.y = 5.3; mesh_node.add_child(m_core)
            var cannon = Node3D.new(); cannon.position.y = 5.6; mesh_node.add_child(cannon)
            var c_barrel = MeshInstance3D.new(); c_barrel.mesh = CylinderMesh.new(); c_barrel.mesh.height = 2.2; c_barrel.mesh.bottom_radius = 0.22; c_barrel.mesh.top_radius = 0.18
            c_barrel.material_override = obsidian_mat; c_barrel.position = Vector3(0, 0, -1.0); c_barrel.rotation_degrees = Vector3(90, 0, 0)
            cannon.add_child(c_barrel)
            mesh_node.set_meta("magma_turret", cannon)
        else:
            # Grand Obsidian Caldera Fortress with Pulsing Magma Heart
            var caldera = MeshInstance3D.new(); caldera.mesh = CylinderMesh.new(); caldera.mesh.height = 3.6; caldera.mesh.bottom_radius = 5.2; caldera.mesh.top_radius = 4.2; caldera.mesh.radial_segments = 10
            caldera.material_override = basalt_mat; caldera.position.y = 1.8; mesh_node.add_child(caldera)
            var heart = MeshInstance3D.new(); heart.mesh = SphereMesh.new(); heart.mesh.radius = 1.8; heart.mesh.height = 3.2
            heart.material_override = magma_mat; heart.position.y = 3.8; mesh_node.add_child(heart)
            mesh_node.set_meta("magma_heart", heart)

func _update_timer_ui():
    for p in players:
        var ui = p.ui
        if not ui: continue
        var label = ui.get_node_or_null("TimerLabel")
        if not label: continue
        
        if not sudden_death_active:
            var s_int = int(match_timer)
            if s_int != _last_displayed_second:
                _last_displayed_second = s_int
                var m = int(floor(match_timer / 60.0))
                var s = s_int % 60
                var time_str = str(m) + ":" + ("0" if s < 10 else "") + str(s)
                if GameState.is_koth_mode():
                    var active_t: Array = GameState.active_match_teams.duplicate()
                    if active_t.is_empty():
                        active_t = ["SideA", "SideB"]
                    active_t.sort_custom(func(a, b): return koth_points.get(a, 0) > koth_points.get(b, 0))
                    var parts: Array[String] = []
                    for idx in range(min(3, active_t.size())):
                        var t_name: String = active_t[idx]
                        parts.append(t_name.trim_prefix("Side") + ":" + str(koth_points.get(t_name, 0)))
                    time_str += " | Hill [" + " ".join(parts) + "]"
                elif GameState.is_domination_mode():
                    var mode_tag := "FFA Domination" if GameState.is_ffa_mode() else "Domination"
                    time_str += " | " + mode_tag
                _cached_timer_str = time_str
            label.text = _cached_timer_str
            label.modulate = Color(1, 1, 1)
            label.scale = Vector2(1.0, 1.0)
        else:
            label.text = "SUDDEN DEATH!"
            label.modulate = Color(1, 0, 0)
            label.scale = Vector2(1.2 + sin(Time.get_ticks_msec()*0.01)*0.1, 1.2 + sin(Time.get_ticks_msec()*0.01)*0.1)

func _start_beast_of_nothingness():
    print("THE BEAST OF NOTHINGNESS AWAKENS! The entire battlefield is inside its colossal Lovecraftian maw!")
    var old_beast = get_node_or_null("BeastOfNothingness")
    if old_beast:
        old_beast.name = "BeastOfNothingness_Old"
        remove_child(old_beast)
        old_beast.queue_free()

    var beast_root = Node3D.new()
    beast_root.name = "BeastOfNothingness"
    beast_root.position.y = -26.0
    add_child(beast_root)

    var arena_rad = maxf(125.0, GameState.current_map_radius)

    # Shift the sky and directional light into an abyssal Lovecraftian cosmic gullet
    var dir_light = get_node_or_null("DirectionalLight3D")
    if dir_light:
        dir_light.light_color = Color(0.85, 0.35, 0.95)
        dir_light.light_energy = 0.95
    var world_env = get_node_or_null("WorldEnvironment")
    if world_env and world_env.environment and world_env.environment.sky:
        var sky_mat = world_env.environment.sky.sky_material
        if sky_mat is ProceduralSkyMaterial:
            sky_mat.sky_top_color = Color(0.03, 0.01, 0.06)
            sky_mat.sky_horizon_color = Color(0.32, 0.03, 0.22)
            sky_mat.ground_bottom_color = Color(0.01, 0.0, 0.02)
            sky_mat.ground_horizon_color = Color(0.24, 0.02, 0.16)

    # Shared Lovecraftian Maw Materials
    var maw_flesh_mat = StandardMaterial3D.new()
    maw_flesh_mat.albedo_color = Color(0.09, 0.02, 0.13)
    maw_flesh_mat.roughness = 0.32
    maw_flesh_mat.metallic = 0.65
    maw_flesh_mat.emission_enabled = true
    maw_flesh_mat.emission = Color(0.52, 0.08, 0.78)
    maw_flesh_mat.emission_energy_multiplier = 1.65
    maw_flesh_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

    var gullet_mat = StandardMaterial3D.new()
    gullet_mat.albedo_color = Color(0.04, 0.0, 0.07)
    gullet_mat.roughness = 0.25
    gullet_mat.emission_enabled = true
    gullet_mat.emission = Color(0.38, 0.04, 0.55)
    gullet_mat.emission_energy_multiplier = 1.25
    gullet_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

    var fang_mat = StandardMaterial3D.new()
    fang_mat.albedo_color = Color(0.88, 0.84, 0.92)
    fang_mat.roughness = 0.22
    fang_mat.metallic = 0.15
    fang_mat.emission_enabled = true
    fang_mat.emission = Color(0.45, 0.12, 0.65)
    fang_mat.emission_energy_multiplier = 0.55

    # =========================================================================
    # 1. LOWER ABYSSAL MANDIBLE, ESOPHAGEAL GULLET & CONCENTRIC FANG RINGS
    # =========================================================================
    var lower_jaw = Node3D.new()
    lower_jaw.name = "LowerJawRoot"
    lower_jaw.set_meta("is_lower_jaw", true)
    lower_jaw.set_meta("base_y", -4.0)
    beast_root.add_child(lower_jaw)

    # Deep Hollow Esophageal Throat Funnel (open hollow tube - NO solid cap blocking battlefield)
    var gullet_funnel = MeshInstance3D.new()
    gullet_funnel.name = "AbyssalGulletFunnel"
    var g_cyl = CylinderMesh.new()
    g_cyl.cap_top = false
    g_cyl.cap_bottom = false
    g_cyl.top_radius = arena_rad * 1.30
    g_cyl.bottom_radius = arena_rad * 0.68
    g_cyl.height = 95.0
    gullet_funnel.mesh = g_cyl
    gullet_funnel.material_override = gullet_mat
    gullet_funnel.position.y = -58.0
    lower_jaw.add_child(gullet_funnel)

    # Colossal Fleshy Lower Jaw Gum Rim encircling outside the battlefield perimeter
    var gum_rim = MeshInstance3D.new()
    gum_rim.name = "LowerMawGumRim"
    var gum_torus = TorusMesh.new()
    gum_torus.inner_radius = arena_rad * 1.12
    gum_torus.outer_radius = arena_rad * 1.38
    gum_rim.mesh = gum_torus
    gum_rim.material_override = maw_flesh_mat
    gum_rim.position.y = -6.0
    lower_jaw.add_child(gum_rim)

    # Pulsing Abyssal Uvula / Esophageal Heart deep in the abyss (never clips through floor)
    var uvula_core = MeshInstance3D.new()
    uvula_core.name = "AbyssalUvulaCore"
    var uv_sph = SphereMesh.new()
    uv_sph.radius = arena_rad * 0.16
    uv_sph.height = arena_rad * 0.32
    uvula_core.mesh = uv_sph
    uvula_core.material_override = maw_flesh_mat
    uvula_core.position = Vector3(0.0, -72.0, 0.0)
    uvula_core.set_meta("is_uvula", true)
    beast_root.add_child(uvula_core)

    # GPU Batch 1: 96 Titanic Outer Lower Jaw Fangs surrounding the outer perimeter
    var outer_fang_count: int = 96
    var outer_fang_mm := MultiMesh.new()
    outer_fang_mm.transform_format = MultiMesh.TRANSFORM_3D
    var outer_fang_cyl := CylinderMesh.new()
    outer_fang_cyl.top_radius = 0.0
    outer_fang_cyl.bottom_radius = 4.2
    outer_fang_cyl.height = 38.0
    outer_fang_mm.mesh = outer_fang_cyl
    outer_fang_mm.instance_count = outer_fang_count

    for fi in range(outer_fang_count):
        var ang: float = (float(fi) / float(outer_fang_count)) * TAU
        var r_f: float = arena_rad * 1.16 + sin(ang * 6.0) * 3.5
        var h_scale: float = 0.85 + 0.35 * abs(sin(ang * 4.0 + float(fi) * 0.7))
        var pos := Vector3(cos(ang) * r_f, 9.0 * h_scale, sin(ang) * r_f)
        # Orient fang so it curves/tilts inward toward the center of the maw
        var inward_dir := Vector3(-cos(ang), 0.0, -sin(ang))
        var tilt_axis := inward_dir.cross(Vector3.UP).normalized()
        var b := Basis(tilt_axis, -0.34).scaled(Vector3(1.0, h_scale, 1.0))
        outer_fang_mm.set_instance_transform(fi, Transform3D(b, pos))

    var outer_fangs_mmi := MultiMeshInstance3D.new()
    outer_fangs_mmi.name = "OuterMawFangsMMI"
    outer_fangs_mmi.multimesh = outer_fang_mm
    outer_fangs_mmi.material_override = fang_mat
    lower_jaw.add_child(outer_fangs_mmi)

    # GPU Batch 2: 72 Inner Pharyngeal Hooked Gullet Teeth (Second Concentric Ring)
    var inner_tooth_count: int = 72
    var inner_tooth_mm := MultiMesh.new()
    inner_tooth_mm.transform_format = MultiMesh.TRANSFORM_3D
    var inner_tooth_cyl := CylinderMesh.new()
    inner_tooth_cyl.top_radius = 0.0
    inner_tooth_cyl.bottom_radius = 2.6
    inner_tooth_cyl.height = 22.0
    inner_tooth_mm.mesh = inner_tooth_cyl
    inner_tooth_mm.instance_count = inner_tooth_count

    for ti in range(inner_tooth_count):
        var ang: float = (float(ti) + 0.5) / float(inner_tooth_count) * TAU
        var r_t: float = arena_rad * 1.08
        var h_sc: float = 0.8 + 0.3 * abs(cos(ang * 5.0))
        var pos := Vector3(cos(ang) * r_t, 4.0 * h_sc, sin(ang) * r_t)
        var inward_dir := Vector3(-cos(ang), 0.0, -sin(ang))
        var tilt_axis := inward_dir.cross(Vector3.UP).normalized()
        var b := Basis(tilt_axis, -0.58).scaled(Vector3(1.0, h_sc, 1.0))
        inner_tooth_mm.set_instance_transform(ti, Transform3D(b, pos))

    var inner_teeth_mmi := MultiMeshInstance3D.new()
    inner_teeth_mmi.name = "InnerGulletTeethMMI"
    inner_teeth_mmi.multimesh = inner_tooth_mm
    inner_teeth_mmi.material_override = fang_mat
    lower_jaw.add_child(inner_teeth_mmi)

    # =========================================================================
    # 2. UPPER OVERARCHING PALATE JAW, CRANIAL RIBS & HANGING FANGS
    # =========================================================================
    var upper_jaw = Node3D.new()
    upper_jaw.name = "UpperPalateRoot"
    upper_jaw.position.y = 85.0
    upper_jaw.set_meta("is_upper_jaw", true)
    upper_jaw.set_meta("base_y", 85.0)
    beast_root.add_child(upper_jaw)

    var upper_rim = MeshInstance3D.new()
    upper_rim.name = "UpperMawArchRim"
    var u_torus = TorusMesh.new()
    u_torus.inner_radius = arena_rad * 1.10
    u_torus.outer_radius = arena_rad * 1.36
    upper_rim.mesh = u_torus
    upper_rim.material_override = maw_flesh_mat
    upper_jaw.add_child(upper_rim)

    # GPU Batch 3: 64 Hanging Upper Palate Fangs pointing down from high above
    var upper_fang_count: int = 64
    var upper_fang_mm := MultiMesh.new()
    upper_fang_mm.transform_format = MultiMesh.TRANSFORM_3D
    var upper_fang_cyl := CylinderMesh.new()
    upper_fang_cyl.top_radius = 3.6
    upper_fang_cyl.bottom_radius = 0.0
    upper_fang_cyl.height = 34.0
    upper_fang_mm.mesh = upper_fang_cyl
    upper_fang_mm.instance_count = upper_fang_count

    for ufi in range(upper_fang_count):
        var ang: float = (float(ufi) / float(upper_fang_count)) * TAU
        var r_u: float = arena_rad * 1.16 + cos(ang * 4.0) * 3.0
        var h_sc: float = 0.82 + 0.35 * abs(sin(ang * 3.0))
        var pos := Vector3(cos(ang) * r_u, -10.0 * h_sc, sin(ang) * r_u)
        var inward_dir := Vector3(-cos(ang), 0.0, -sin(ang))
        var tilt_axis := inward_dir.cross(Vector3.UP).normalized()
        var b := Basis(tilt_axis, 0.28).scaled(Vector3(1.0, h_sc, 1.0))
        upper_fang_mm.set_instance_transform(ufi, Transform3D(b, pos))

    var upper_fangs_mmi := MultiMeshInstance3D.new()
    upper_fangs_mmi.name = "UpperPalateFangsMMI"
    upper_fangs_mmi.multimesh = upper_fang_mm
    upper_fangs_mmi.material_override = fang_mat
    upper_jaw.add_child(upper_fangs_mmi)

    # GPU Batch 4: 16 Overarching Cranial Palate Ribs curving high above the outer rim
    var rib_count: int = 16
    var rib_mm := MultiMesh.new()
    rib_mm.transform_format = MultiMesh.TRANSFORM_3D
    var rib_box := BoxMesh.new()
    rib_box.size = Vector3(5.5, 8.0, arena_rad * 0.45)
    rib_mm.mesh = rib_box
    rib_mm.instance_count = rib_count
    for ri in range(rib_count):
        var ang: float = (float(ri) / float(rib_count)) * TAU
        var r_mid: float = arena_rad * 1.20
        var pos := Vector3(cos(ang) * r_mid, 14.0, sin(ang) * r_mid)
        var b := Basis(Vector3.UP, -ang + PI * 0.5) * Basis(Vector3.RIGHT, 0.42)
        rib_mm.set_instance_transform(ri, Transform3D(b, pos))

    var ribs_mmi := MultiMeshInstance3D.new()
    ribs_mmi.name = "PalateRibsMMI"
    ribs_mmi.multimesh = rib_mm
    ribs_mmi.material_override = maw_flesh_mat
    upper_jaw.add_child(ribs_mmi)

    # =========================================================================
    # 3. 80 STARING LOVECRAFTIAN COSMIC EYES & SLIT PUPILS (GPU BATCHED)
    # =========================================================================
    var eye_count: int = 80
    var eye_mat := StandardMaterial3D.new()
    eye_mat.vertex_color_use_as_albedo = true
    eye_mat.emission_enabled = true
    eye_mat.emission = Color(0.95, 0.22, 0.45)
    eye_mat.emission_energy_multiplier = 2.8

    var pupil_mat := StandardMaterial3D.new()
    pupil_mat.albedo_color = Color(0.02, 0.0, 0.04)
    pupil_mat.roughness = 0.1

    var eye_mm := MultiMesh.new()
    eye_mm.transform_format = MultiMesh.TRANSFORM_3D
    eye_mm.use_colors = true
    var eye_sph := SphereMesh.new()
    eye_sph.radius = 1.0
    eye_sph.height = 2.0
    eye_mm.mesh = eye_sph
    eye_mm.instance_count = eye_count

    var pupil_mm := MultiMesh.new()
    pupil_mm.transform_format = MultiMesh.TRANSFORM_3D
    var pupil_box := BoxMesh.new()
    pupil_box.size = Vector3(0.28, 1.65, 0.35)
    pupil_mm.mesh = pupil_box
    pupil_mm.instance_count = eye_count

    var eye_palette: Array[Color] = [
        Color(1.0, 0.12, 0.28), # Eldritch Crimson
        Color(1.0, 0.78, 0.14), # Madness Amber-Gold
        Color(0.82, 0.16, 1.0), # Cosmic Void Violet
        Color(0.25, 0.95, 0.68)  # Abyssal Bioluminescent Teal
    ]

    for ei in range(eye_count):
        var ang: float = (float(ei) / float(eye_count)) * TAU + sin(float(ei) * 1.7) * 0.04
        var tier: int = ei % 3
        var e_rad: float = arena_rad * (1.06 if tier == 0 else (1.11 if tier == 1 else 0.98))
        var e_y: float = (7.5 + sin(float(ei) * 2.3) * 4.5) if tier == 0 else ((24.0 + cos(float(ei) * 1.9) * 8.0) if tier == 1 else (52.0 + sin(float(ei) * 3.1) * 6.0))
        var sc: float = 2.2 + float(ei % 5) * 0.65
        var e_pos := Vector3(cos(ang) * e_rad, e_y, sin(ang) * e_rad)
        var look_tf := Transform3D(Basis.IDENTITY, e_pos).looking_at(Vector3(0.0, 2.0, 0.0), Vector3.UP)
        var scaled_tf := Transform3D(look_tf.basis.scaled(Vector3(sc, sc, sc * 0.65)), e_pos)
        eye_mm.set_instance_transform(ei, scaled_tf)
        eye_mm.set_instance_color(ei, eye_palette[ei % eye_palette.size()])

        var p_pos := e_pos + (-look_tf.basis.z) * (sc * 0.58)
        var pupil_tf := Transform3D(look_tf.basis.scaled(Vector3(sc, sc, sc * 0.5)), p_pos)
        pupil_mm.set_instance_transform(ei, pupil_tf)

    var eyes_mmi := MultiMeshInstance3D.new()
    eyes_mmi.name = "EldritchMawEyesMMI"
    eyes_mmi.multimesh = eye_mm
    eyes_mmi.material_override = eye_mat
    beast_root.add_child(eyes_mmi)

    var pupils_mmi := MultiMeshInstance3D.new()
    pupils_mmi.name = "EldritchPupilsMMI"
    pupils_mmi.multimesh = pupil_mm
    pupils_mmi.material_override = pupil_mat
    beast_root.add_child(pupils_mmi)

    # =========================================================================
    # 4. 8 COLOSSAL WRITHING VOID TENTACLES ARCHING INWARD FROM THE MAW RIM
    # =========================================================================
    var tentacle_count: int = 8
    for t_i in range(tentacle_count):
        var ang: float = (float(t_i) / float(tentacle_count)) * TAU
        var t_root := Node3D.new()
        t_root.name = "MawTentacle_" + str(t_i)
        var r_base: float = arena_rad * 1.22
        var base_ty: float = 6.0
        t_root.position = Vector3(cos(ang) * r_base, base_ty, sin(ang) * r_base)
        var base_rx: float = -sin(ang) * 0.42
        var base_rz: float = cos(ang) * 0.42
        t_root.rotation.x = base_rx
        t_root.rotation.z = base_rz
        t_root.set_meta("base_y", base_ty)
        t_root.set_meta("base_rx", base_rx)
        t_root.set_meta("base_rz", base_rz)
        t_root.set_meta("seg_phase", float(t_i) * 0.85)

        # Connected base collar, lower trunk, mid coil, and tapered tip
        var lower_seg := MeshInstance3D.new()
        var l_cyl := CylinderMesh.new()
        l_cyl.bottom_radius = 5.2
        l_cyl.top_radius = 3.2
        l_cyl.height = 28.0
        lower_seg.mesh = l_cyl
        lower_seg.material_override = maw_flesh_mat
        lower_seg.position.y = 12.0
        t_root.add_child(lower_seg)

        var joint_knuckle := MeshInstance3D.new()
        var j_sph := SphereMesh.new()
        j_sph.radius = 3.4
        j_sph.height = 6.8
        joint_knuckle.mesh = j_sph
        joint_knuckle.material_override = maw_flesh_mat
        joint_knuckle.position.y = 26.0
        t_root.add_child(joint_knuckle)

        var upper_seg := MeshInstance3D.new()
        var u_cyl := CylinderMesh.new()
        u_cyl.bottom_radius = 3.1
        u_cyl.top_radius = 0.4
        u_cyl.height = 30.0
        upper_seg.mesh = u_cyl
        upper_seg.material_override = maw_flesh_mat
        var inward := Vector3(-cos(ang), 0.0, -sin(ang))
        upper_seg.position = Vector3(inward.x * 6.5, 38.0, inward.z * 6.5)
        var t_axis := inward.cross(Vector3.UP).normalized()
        upper_seg.transform.basis = Basis(t_axis, -0.48)
        t_root.add_child(upper_seg)

        beast_root.add_child(t_root)

    var tw = create_tween()
    if tw:
        tw.tween_property(beast_root, "position:y", 0.0, 10.0)
    else:
        beast_root.position.y = 0.0


@rpc("authority", "call_local", "reliable")
func sync_spawn_hazard(rx: float, rz: float, is_mouth: bool, unique_name: String):
    var scn = beast_mouth_scene if is_mouth else beast_tentacle_scene
    if not scn: return
    var t = scn.instantiate()
    t.name = unique_name
    add_child(t)
    t.global_position = Vector3(rx, -5, rz)
    var tw = t.create_tween()
    if tw:
        tw.tween_property(t, "position:y", 0.0, 1.0)
    else:
        t.position.y = 0.0
    
    # Ground eruption shockwave burst
    var burst = MeshInstance3D.new()
    var tm = TorusMesh.new()
    tm.inner_radius = 1.0; tm.outer_radius = 2.4
    burst.mesh = tm
    var bmat = StandardMaterial3D.new()
    bmat.albedo_color = Color(0.35, 0.08, 0.45, 0.8)
    bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    bmat.emission_enabled = true
    bmat.emission = Color(0.4, 0.05, 0.5)
    bmat.emission_energy_multiplier = 2.0
    burst.material_override = bmat
    add_child(burst)
    burst.global_position = Vector3(rx, 0.05, rz)
    var btw = burst.create_tween()
    if btw:
        btw.tween_property(burst, "scale", Vector3(2.2, 1.0, 2.2), 0.6)
        btw.parallel().tween_property(bmat, "albedo_color:a", 0.0, 0.6)
        btw.tween_callback(burst.queue_free)
    else:
        burst.queue_free()

func _end_match(message: String, winning_team: String = ""):
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if multiplayer.is_server():
            rpc("sync_end_match", message, winning_team)
        else:
            if "DISCONNECTED" in message:
                sync_end_match(message, winning_team)
    else:
        sync_end_match(message, winning_team)

@rpc("authority", "call_local", "reliable")
func sync_end_match(message: String, winning_team: String = ""):
    if not is_inside_tree() or not get_tree() or get_tree().paused: return
    get_tree().paused = true
    
    var my_team = "SideA"
    if players.size() == 1:
        my_team = players[0].team
    elif GameState.local_player_team != "":
        my_team = GameState.local_player_team
        
    var final_message = message
    if winning_team != "" and GameState.current_mode != "AI_VS_AI":
        if players.size() == 1 or GameState.current_mode.begins_with("ONLINE"):
            if winning_team == my_team:
                final_message = "VICTORY! " + (message if not message.begins_with("DEFEAT") else "All opposing bases destroyed.")
            else:
                final_message = "DEFEAT! " + GameState.get_team_display_name(winning_team) + " is victorious."
        else:
            final_message = "VICTORY FOR " + GameState.get_team_display_name(winning_team) + "!"
            
    print(final_message)
    var ui = get_node_or_null("InGameUI")
    if not ui and players.size() > 0: ui = players[0].ui
    
    if ui and is_instance_valid(ui):
        var lbl = Label.new()
        lbl.text = final_message
        lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        lbl.add_theme_font_size_override("font_size", 48)
        lbl.add_theme_color_override("font_color", Color(1, 0.8, 0))
        lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
        lbl.add_theme_constant_override("outline_size", 8)
        ui.add_child(lbl)
        
    await get_tree().create_timer(4.0, true, false, true).timeout
    if not is_inside_tree() or not get_tree(): return
    get_tree().paused = false
    GameState.disconnect_multiplayer()
    get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _animate_faction_structures(delta):
    var t = Time.get_ticks_msec() * 0.001
    for s in get_tree().get_nodes_in_group("FactionStructures"):
        if not is_instance_valid(s) or s.is_queued_for_deletion() or not s.has_meta("faction_mesh"):
            continue
        var f_mesh = s.get_meta("faction_mesh", null)
        if not f_mesh or not is_instance_valid(f_mesh):
            continue
        if f_mesh and is_instance_valid(f_mesh):
            if f_mesh.has_meta("reach_hover"):
                var node = f_mesh.get_meta("reach_hover")
                if is_instance_valid(node): node.position.y = 3.8 + sin(t * 2.5) * 0.35
            if f_mesh.has_meta("reach_pillar"):
                var node = f_mesh.get_meta("reach_pillar")
                if is_instance_valid(node): node.rotation.y += delta * 0.6
            if f_mesh.has_meta("void_heart"):
                var node = f_mesh.get_meta("void_heart")
                if is_instance_valid(node):
                    var beat = 1.0 + abs(sin(t * 3.5)) * 0.18
                    node.scale = Vector3(beat, beat, beat)
            if f_mesh.has_meta("void_eye"):
                var node = f_mesh.get_meta("void_eye")
                if is_instance_valid(node):
                    node.rotation.y = sin(t * 1.5) * 0.8
                    node.rotation.x = cos(t * 1.2) * 0.3
            if f_mesh.has_meta("dominion_dish"):
                var node = f_mesh.get_meta("dominion_dish")
                if is_instance_valid(node): node.rotation.y += delta * 1.5
            if f_mesh.has_meta("dominion_turret"):
                var node = f_mesh.get_meta("dominion_turret")
                if is_instance_valid(node): node.rotation.y = sin(t * 0.8) * 0.35
            if f_mesh.has_meta("rimworld_fire"):
                var node = f_mesh.get_meta("rimworld_fire")
                if is_instance_valid(node):
                    var fl = 1.0 + sin(t * 7.0) * 0.12
                    node.scale = Vector3(fl, 1.0 + cos(t * 9.0) * 0.15, fl)
            if f_mesh.has_meta("pirate_crane"):
                var node = f_mesh.get_meta("pirate_crane")
                if is_instance_valid(node): node.rotation.y = sin(t * 0.5) * 0.4
            if f_mesh.has_meta("plague_eye"):
                var node = f_mesh.get_meta("plague_eye")
                if is_instance_valid(node):
                    node.rotation.y = sin(t * 1.4) * 0.65
                    node.rotation.x = cos(t * 1.1) * 0.25
            if f_mesh.has_meta("plague_core"):
                var node = f_mesh.get_meta("plague_core")
                if is_instance_valid(node):
                    node.rotation.y += delta * 1.2
            if f_mesh.has_meta("gilded_helix"):
                var node = f_mesh.get_meta("gilded_helix")
                if is_instance_valid(node):
                    node.rotation.y += delta * 1.5
            if f_mesh.has_meta("gilded_core"):
                var node = f_mesh.get_meta("gilded_core")
                if is_instance_valid(node):
                    var pulse = 1.0 + sin(t * 2.8) * 0.08
                    node.scale = Vector3(pulse, pulse, pulse)
                    node.rotation.y -= delta * 0.9
            if f_mesh.has_meta("winter_star"):
                var node = f_mesh.get_meta("winter_star")
                if is_instance_valid(node):
                    node.rotation.y += delta * 1.8
                    var scale_star = 1.0 + sin(t * 3.0) * 0.12
                    node.scale = Vector3(scale_star, scale_star, scale_star)
            if f_mesh.has_meta("magma_heart"):
                var node = f_mesh.get_meta("magma_heart")
                if is_instance_valid(node):
                    var beat = 1.0 + abs(sin(t * 3.0)) * 0.16
                    node.scale = Vector3(beat, beat, beat)
            if f_mesh.has_meta("magma_turret"):
                var node = f_mesh.get_meta("magma_turret")
                if is_instance_valid(node):
                    node.rotation.y = sin(t * 0.7) * 0.4

# =========================================================================
# MAP BIOME & PROCEDURAL ENVIRONMENT GENERATION
# =========================================================================

@rpc("authority", "call_local", "reliable")
func sync_map_environment(biome_name: String, seed_val: int):
    _apply_map_environment(biome_name, seed_val)

func _apply_map_environment(biome_name: String, seed_val: int):
    active_biome = biome_name
    seed(seed_val)
    print("Applying Map Biome: ", active_biome, " with seed: ", seed_val)
    
    _apply_biome_visuals(active_biome)
    
    var old_env = get_node_or_null("EnvironmentFeatures")
    if old_env:
        old_env.name = "EnvironmentFeatures_Old"
        remove_child(old_env)
        old_env.queue_free()
    
    var env_root = Node3D.new()
    env_root.name = "EnvironmentFeatures"
    add_child(env_root)
    
    if active_biome == "SUNNY_PLAINS":
        _generate_sunny_plains(env_root)
    elif active_biome == "SCORCHING_DUNES":
        _generate_scorching_dunes(env_root)
    elif active_biome == "REALM_OF_HARMONY":
        _generate_realm_of_harmony(env_root)
    elif active_biome == "FROZEN_TUNDRA":
        _generate_frozen_tundra(env_root)
    elif active_biome == "VOLCANIC_BRIMSTONE":
        _generate_volcanic_brimstone(env_root)
    elif active_biome == "SPACE_VACUUM":
        _generate_space_vacuum(env_root)
    elif active_biome == "DEEP_JUNGLE" or active_biome == "JUNGLE":
        _generate_jungle(env_root)
    elif active_biome == "HAUNTED_HALLOW" or active_biome == "HALLOWEEN":
        _generate_haunted_hallow(env_root)
    elif active_biome == "FROZEN_WONDERLAND" or active_biome == "WINTER" or active_biome == "YULETIDE":
        _generate_frozen_wonderland(env_root)

    # Pre-render and bake static environment (GPU MultiMesh LODs, UPDATE_ONCE ReflectionProbe, static prop freeze)
    var bake_stats: Dictionary = EnvironmentPreRendererScript.pre_render_and_bake_environment(self, env_root, active_biome)
    _trigger_loading_pre_render_screen(active_biome, bake_stats)

func _trigger_loading_pre_render_screen(biome_name: String, bake_stats: Dictionary) -> void:
    var ls = get_node_or_null("LoadingScreen")
    if ls == null:
        ls = LoadingScreenScript.new()
        ls.name = "LoadingScreen"
        add_child(ls)
    if ls.has_method("run_arena_pre_render_sequence"):
        ls.run_arena_pre_render_sequence(self, biome_name, bake_stats)

func _apply_biome_visuals(biome_name: String):
    var ground = get_node_or_null("Ground")
    var dir_light = get_node_or_null("DirectionalLight3D")
    var world_env = get_node_or_null("WorldEnvironment")
    
    if biome_name == "SUNNY_PLAINS":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.24, 0.54, 0.16)
                g_mat.roughness = 0.85
                g_mesh.material_override = g_mat
            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_color = Color(0.40, 0.28, 0.16)
                    p_mat.roughness = 0.9
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(1.0, 0.98, 0.90)
            dir_light.light_energy = 1.15
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.18, 0.35, 0.70)
                sky_mat.sky_horizon_color = Color(0.65, 0.75, 0.88)
                sky_mat.ground_bottom_color = Color(0.15, 0.15, 0.15)
                sky_mat.ground_horizon_color = Color(0.65, 0.75, 0.88)
                
    elif biome_name == "SCORCHING_DUNES":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.88, 0.72, 0.44) # Desert golden sand
                g_mat.roughness = 0.95
                g_mesh.material_override = g_mat
            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_color = Color(0.78, 0.62, 0.48) # Sandstone path
                    p_mat.roughness = 0.82
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(1.0, 0.94, 0.80)
            dir_light.light_energy = 1.45
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.25, 0.45, 0.75)
                sky_mat.sky_horizon_color = Color(0.95, 0.72, 0.45) # Amber heat haze
                sky_mat.ground_bottom_color = Color(0.35, 0.22, 0.10)
                sky_mat.ground_horizon_color = Color(0.85, 0.62, 0.38)
        solar_beam_timer = randf_range(10.0, 25.0)

    elif biome_name == "REALM_OF_HARMONY":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.08, 0.06, 0.14) # Deep surreal canvas for multicolored lines
                g_mat.roughness = 0.35
                g_mat.metallic = 0.25
                g_mesh.material_override = g_mat
            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_color = Color(1.0, 0.82, 0.18) # Gleaming Golden Path
                    p_mat.metallic = 0.92
                    p_mat.roughness = 0.18
                    p_mat.emission_enabled = true
                    p_mat.emission = Color(1.0, 0.76, 0.14)
                    p_mat.emission_energy_multiplier = 0.65
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(1.0, 0.95, 0.82)
            dir_light.light_energy = 1.30
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.22, 0.12, 0.44)
                sky_mat.sky_horizon_color = Color(1.0, 0.82, 0.32)
                sky_mat.ground_bottom_color = Color(0.08, 0.05, 0.14)
                sky_mat.ground_horizon_color = Color(0.92, 0.72, 0.28)

    elif biome_name == "FROZEN_TUNDRA":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.88, 0.94, 0.99) # Sub-zero snow terrain
                g_mat.roughness = 0.88
                g_mesh.material_override = g_mat
            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_color = Color(0.95, 0.98, 1.0) # Snow path
                    p_mat.roughness = 0.50
                    p_mat.metallic = 0.10
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(0.86, 0.93, 1.0)
            dir_light.light_energy = 1.25
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.18, 0.42, 0.72)
                sky_mat.sky_horizon_color = Color(0.78, 0.90, 0.98)
                sky_mat.ground_bottom_color = Color(0.18, 0.22, 0.28)
                sky_mat.ground_horizon_color = Color(0.72, 0.84, 0.92)

    elif biome_name == "VOLCANIC_BRIMSTONE":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.35, 0.08, 0.06) # Dark red volcanic sand / ash
                g_mat.roughness = 0.92
                g_mesh.material_override = g_mat
            
            # Cached GPU Orange/Obsidian Chequered Stone Path Texture
            var chk_tex = EnvironmentPreRendererScript.get_cached_biome_texture("VOLCANIC_BRIMSTONE")

            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_texture = chk_tex
                    p_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
                    p_mat.roughness = 0.55
                    p_mat.emission_enabled = true
                    p_mat.emission_texture = chk_tex
                    p_mat.emission_energy_multiplier = 0.45
                    p_mat.uv1_scale = Vector3(12.0, 12.0, 12.0)
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(1.0, 0.68, 0.38)
            dir_light.light_energy = 1.35
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.25, 0.05, 0.04)
                sky_mat.sky_horizon_color = Color(0.95, 0.38, 0.12)
                sky_mat.ground_bottom_color = Color(0.18, 0.04, 0.03)
                sky_mat.ground_horizon_color = Color(0.85, 0.30, 0.08)

    elif biome_name == "SPACE_VACUUM":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.12, 0.13, 0.17) # Dark airless asteroid regolith
                g_mat.roughness = 0.88
                g_mat.metallic = 0.22
                g_mesh.material_override = g_mat
            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_color = Color(0.18, 0.26, 0.38) # Orbital deck plating
                    p_mat.metallic = 0.78
                    p_mat.roughness = 0.25
                    p_mat.emission_enabled = true
                    p_mat.emission = Color(0.12, 0.48, 0.85)
                    p_mat.emission_energy_multiplier = 0.45
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(0.82, 0.88, 1.0)
            dir_light.light_energy = 1.25
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.01, 0.01, 0.03)
                sky_mat.sky_horizon_color = Color(0.06, 0.10, 0.22)
                sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.02)
                sky_mat.ground_horizon_color = Color(0.05, 0.08, 0.18)

    elif biome_name == "DEEP_JUNGLE" or biome_name == "JUNGLE":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.12, 0.34, 0.10) # Lush rainforest turf / mossy jungle soil
                g_mat.roughness = 0.90
                g_mesh.material_override = g_mat

            # Cached GPU Wooden Boards / Planks Path Texture
            var wood_tex = EnvironmentPreRendererScript.get_cached_biome_texture("DEEP_JUNGLE")

            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_texture = wood_tex
                    p_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
                    p_mat.roughness = 0.78
                    p_mat.uv1_scale = Vector3(14.0, 14.0, 14.0)
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(1.0, 0.96, 0.82)
            dir_light.light_energy = 1.25
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.12, 0.40, 0.65)
                sky_mat.sky_horizon_color = Color(0.70, 0.85, 0.74)
                sky_mat.ground_bottom_color = Color(0.08, 0.20, 0.06)
                sky_mat.ground_horizon_color = Color(0.45, 0.65, 0.38)

    elif biome_name == "HAUNTED_HALLOW" or biome_name == "HALLOWEEN":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.12, 0.10, 0.13) # Dark graveyard loam & decayed soil
                g_mat.roughness = 0.95
                g_mesh.material_override = g_mat

            # Cached GPU Decrepit Cracked Stone Path Texture
            var stone_tex = EnvironmentPreRendererScript.get_cached_biome_texture("HAUNTED_HALLOW")

            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_texture = stone_tex
                    p_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
                    p_mat.roughness = 0.85
                    p_mat.uv1_scale = Vector3(14.0, 14.0, 14.0)
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(0.85, 0.72, 0.96) # Eerie harvest moonlight
            dir_light.light_energy = 1.15
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.06, 0.03, 0.12) # Deep night purple
                sky_mat.sky_horizon_color = Color(0.72, 0.30, 0.06) # Pumpkin orange horizon
                sky_mat.ground_bottom_color = Color(0.08, 0.06, 0.09)
                sky_mat.ground_horizon_color = Color(0.35, 0.15, 0.04)

    elif biome_name == "FROZEN_WONDERLAND" or biome_name == "WINTER" or biome_name == "YULETIDE":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.92, 0.95, 1.0) # Sparkling icy snow
                g_mat.roughness = 0.55
                g_mat.metallic = 0.15
                g_mesh.material_override = g_mat

            # Cached GPU Frosted Stone & Snow Path Texture
            var snow_tex = EnvironmentPreRendererScript.get_cached_biome_texture("FROZEN_WONDERLAND")

            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_texture = snow_tex
                    p_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
                    p_mat.roughness = 0.70
                    p_mat.uv1_scale = Vector3(14.0, 14.0, 14.0)
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(0.85, 0.92, 1.0) # Crisp winter twilight
            dir_light.light_energy = 1.25
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.04, 0.08, 0.20) # Deep Arctic night navy
                sky_mat.sky_horizon_color = Color(0.25, 0.75, 0.85) # Shimmering cyan aurora borealis
                sky_mat.ground_bottom_color = Color(0.08, 0.14, 0.22)
                sky_mat.ground_horizon_color = Color(0.20, 0.55, 0.70)

func _get_clear_hazard_pos(map_size: float) -> Vector3:
    var attempts = 0
    while attempts < 35:
        attempts += 1
        var candidate = Vector3(randf_range(-map_size, map_size), 0.0, randf_range(-map_size, map_size))
        
        var obstructed = false
        for s in get_tree().get_nodes_in_group("Targetable"):
            if not is_instance_valid(s): continue
            if ("Base" in s.name or "Tower" in s.name or "CommandBay" in s.name) and candidate.distance_to(s.global_position) < 8.0:
                obstructed = true
                break
        if obstructed: continue
        
        for feat in placed_feature_records:
            if feat.get("type", "") == "dune" and candidate.distance_to(feat["pos"]) < feat["radius"] * 0.95:
                obstructed = true
                break
            elif (feat.get("type", "") in ["pit", "hill", "gorilla_den", "monkey_burrow", "sinkhole"]) and candidate.distance_to(feat["pos"]) < 7.5:
                obstructed = true
                break
            elif (feat.get("type", "") in ["tree", "jungle_tree"]) and candidate.distance_to(feat["pos"]) < 2.5:
                obstructed = true
                break
        if not obstructed:
            return candidate
            
    return Vector3(randf_range(-map_size * 0.6, map_size * 0.6), 0.0, randf_range(-map_size * 0.6, map_size * 0.6))

func _is_pos_clear(pos: Vector3, min_path_dist: float, min_struct_dist: float, self_radius: float = 3.0) -> bool:
    var max_extent = maxf(82.0, GameState.current_map_radius * 0.72)
    if abs(pos.x) > max_extent or abs(pos.z) > max_extent: return false
    
    var tree = get_tree()
    if tree:
        for node in tree.get_nodes_in_group("Targetable"):
            if not is_instance_valid(node): continue
            if "Base" in node.name or "Tower" in node.name or "CommandBay" in node.name or "Structure" in node.name or "Nest" in node.name or "Hill" in node.name or "Den" in node.name or "Burrow" in node.name:
                if pos.distance_to(node.global_position) < min_struct_dist + self_radius + 2.0:
                    return false
                
    if GameState.is_koth_mode() or get_node_or_null("KotH_Zone") != null:
        if pos.distance_to(Vector3.ZERO) < 22.0 + self_radius:
            return false

    var min_center_clearance = 20.0
    if pos.length() < (min_center_clearance + self_radius):
        return false

    var dist_to_lane = GameState.get_distance_to_nearest_lane(pos)
    if dist_to_lane < (14.0 + min_path_dist + self_radius):
        return false

    for feat in placed_feature_records:
        var min_sep = feat.get("radius", 3.0) + self_radius + 2.0
        if pos.distance_to(feat.get("pos", Vector3.ZERO)) < min_sep:
            return false
                
    return true

# --- Sunny Plains Generation (GPU MultiMesh Batched) ---
var _pending_tree_trunk_tfs: Array[Transform3D] = []
var _pending_tree_trunk_cols: Array[Color] = []
var _pending_tree_foliage_tfs: Array[Transform3D] = []
var _pending_tree_foliage_cols: Array[Color] = []
var _pending_pine_cone_tfs: Array[Transform3D] = []

func _generate_sunny_plains(parent: Node3D):
    placed_feature_records.clear()
    _pending_tree_trunk_tfs.clear()
    _pending_tree_trunk_cols.clear()
    _pending_tree_foliage_tfs.clear()
    _pending_tree_foliage_cols.clear()
    _pending_pine_cone_tfs.clear()
    var span = maxf(75.0, GameState.current_map_radius * 0.65)
    
    var tree_count = randi_range(26, 36)
    var attempts = 0
    var placed_trees = 0
    while placed_trees < tree_count and attempts < 300:
        attempts += 1
        var candidate = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
        if _is_pos_clear(candidate, 5.0, 14.0, 3.2):
            _create_procedural_tree(parent, candidate)
            placed_feature_records.append({"pos": candidate, "radius": 3.2, "type": "tree"})
            placed_trees += 1

    # Flush batched GPU MultiMeshInstance3D nodes for all placed trees
    if _pending_tree_trunk_tfs.size() > 0:
        var bark_mat := StandardMaterial3D.new()
        bark_mat.vertex_color_use_as_albedo = true
        bark_mat.roughness = 0.85
        var trunk_cyl := CylinderMesh.new()
        trunk_cyl.top_radius = 0.28
        trunk_cyl.bottom_radius = 0.42
        trunk_cyl.height = 3.2
        var trunk_mm := MultiMesh.new()
        trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
        trunk_mm.use_colors = true
        trunk_mm.mesh = trunk_cyl
        trunk_mm.instance_count = _pending_tree_trunk_tfs.size()
        for idx in range(_pending_tree_trunk_tfs.size()):
            trunk_mm.set_instance_transform(idx, _pending_tree_trunk_tfs[idx])
            trunk_mm.set_instance_color(idx, _pending_tree_trunk_cols[idx])
        var trunks_mmi := MultiMeshInstance3D.new()
        trunks_mmi.name = "TreeTrunksMMI"
        trunks_mmi.multimesh = trunk_mm
        trunks_mmi.material_override = bark_mat
        parent.add_child(trunks_mmi)

    if _pending_tree_foliage_tfs.size() > 0:
        var leaf_mat := StandardMaterial3D.new()
        leaf_mat.vertex_color_use_as_albedo = true
        leaf_mat.roughness = 0.75
        var leaf_sph := SphereMesh.new()
        leaf_sph.radius = 1.3
        leaf_sph.height = 2.4
        var leaf_mm := MultiMesh.new()
        leaf_mm.transform_format = MultiMesh.TRANSFORM_3D
        leaf_mm.use_colors = true
        leaf_mm.mesh = leaf_sph
        leaf_mm.instance_count = _pending_tree_foliage_tfs.size()
        for idx in range(_pending_tree_foliage_tfs.size()):
            leaf_mm.set_instance_transform(idx, _pending_tree_foliage_tfs[idx])
            leaf_mm.set_instance_color(idx, _pending_tree_foliage_cols[idx])
        var foliage_mmi := MultiMeshInstance3D.new()
        foliage_mmi.name = "TreeFoliageSpheresMMI"
        foliage_mmi.multimesh = leaf_mm
        foliage_mmi.material_override = leaf_mat
        parent.add_child(foliage_mmi)

    if _pending_pine_cone_tfs.size() > 0:
        var pine_mat := StandardMaterial3D.new()
        pine_mat.albedo_color = Color(0.14, 0.42, 0.18)
        pine_mat.roughness = 0.8
        var cone_cyl := CylinderMesh.new()
        cone_cyl.top_radius = 0.04
        cone_cyl.bottom_radius = 1.0
        cone_cyl.height = 1.0
        var pine_mm := MultiMesh.new()
        pine_mm.transform_format = MultiMesh.TRANSFORM_3D
        pine_mm.mesh = cone_cyl
        pine_mm.instance_count = _pending_pine_cone_tfs.size()
        for idx in range(_pending_pine_cone_tfs.size()):
            pine_mm.set_instance_transform(idx, _pending_pine_cone_tfs[idx])
        var pine_mmi := MultiMeshInstance3D.new()
        pine_mmi.name = "PineConesMMI"
        pine_mmi.multimesh = pine_mm
        pine_mmi.material_override = pine_mat
        parent.add_child(pine_mmi)
            
    var brush_count = randi_range(8, 14)
    attempts = 0
    var placed_brush = 0
    while placed_brush < brush_count and attempts < 250:
        attempts += 1
        var side = -1.0 if randf() < 0.5 else 1.0
        var candidate = Vector3(side * randf_range(18.0, span * 0.78), 0.0, randf_range(-span * 0.8, span * 0.8))
        if _is_pos_clear(candidate, 3.0, 12.0, 6.0):
            var brush = StealthBrushScript.new()
            brush.position = candidate
            brush.setup_visuals(randf_range(4.5, 6.2))
            parent.add_child(brush)
            placed_feature_records.append({"pos": candidate, "radius": 6.0, "type": "brush"})
            placed_brush += 1

func _create_procedural_tree(parent: Node3D, pos: Vector3):
    var tree_root = StaticBody3D.new()
    tree_root.position = pos
    tree_root.collision_layer = 1
    tree_root.collision_mask = 0
    
    var col = CollisionShape3D.new()
    var cyl = CylinderShape3D.new()
    cyl.radius = 0.5
    cyl.height = 3.5
    col.shape = cyl
    col.position.y = 1.75
    tree_root.add_child(col)
    
    var style = randi() % 3
    var scale_var = randf_range(0.85, 1.3)
    var rot_y = randf() * TAU
    tree_root.scale = Vector3(scale_var, scale_var, scale_var)
    tree_root.rotation.y = rot_y
    parent.add_child(tree_root)

    var tree_basis := Basis(Vector3.UP, rot_y).scaled(Vector3(scale_var, scale_var, scale_var))
    var tree_tf := Transform3D(tree_basis, pos)

    var bark_col: Color = Color(0.36, 0.22, 0.12) if style != 2 else Color(0.82, 0.82, 0.78)
    _pending_tree_trunk_tfs.append(tree_tf * Transform3D(Basis.IDENTITY, Vector3(0.0, 1.6, 0.0)))
    _pending_tree_trunk_cols.append(bark_col)

    if style == 0:
        var oak_col := Color(0.20, 0.56, 0.16)
        for f_pos in [Vector3(0, 3.4, 0), Vector3(0.6, 3.8, 0.4), Vector3(-0.5, 3.6, -0.4)]:
            _pending_tree_foliage_tfs.append(tree_tf * Transform3D(Basis.IDENTITY, f_pos))
            _pending_tree_foliage_cols.append(oak_col)
    elif style == 1:
        var tiers = [
            {"r": 1.6, "y": 2.6, "h": 1.4},
            {"r": 1.2, "y": 3.6, "h": 1.3},
            {"r": 0.8, "y": 4.5, "h": 1.2}
        ]
        for t in tiers:
            var c_basis := Basis.IDENTITY.scaled(Vector3(float(t["r"]), float(t["h"]), float(t["r"])))
            _pending_pine_cone_tfs.append(tree_tf * Transform3D(c_basis, Vector3(0.0, float(t["y"]), 0.0)))
    else:
        var birch_col := Color(0.32, 0.66, 0.22)
        var crown_basis := Basis.IDENTITY.scaled(Vector3(1.15, 1.08, 1.15))
        _pending_tree_foliage_tfs.append(tree_tf * Transform3D(crown_basis, Vector3(0.0, 3.8, 0.0)))
        _pending_tree_foliage_cols.append(birch_col)

# --- Scorching Sand Dunes Generation (GPU MultiMesh Batched) ---
var _pending_sand_dune_tfs: Array[Transform3D] = []
var _pending_pit_rock_tfs: Array[Transform3D] = []

func _generate_scorching_dunes(parent: Node3D):
    placed_feature_records.clear()
    _pending_sand_dune_tfs.clear()
    _pending_pit_rock_tfs.clear()
    var attempts = 0
    
    # 1. Scorpion Pits (2 territorial pits, each with 15 scorpions) - GUARANTEED PLACEMENT
    var pit_angles = [deg_to_rad(0.0), deg_to_rad(180.0)] if GameState.map_selected == "Arena_6P.tscn" else ([deg_to_rad(45.0), deg_to_rad(225.0)] if GameState.map_selected == "Arena_4P.tscn" else [0.0, PI])
    for i in range(2):
        var placed = false
        attempts = 0
        while not placed and attempts < 120:
            attempts += 1
            var candidate = Vector3.ZERO
            if GameState.map_selected == "Arena_6P.tscn":
                var base_ang = pit_angles[i] + randf_range(-0.15, 0.15)
                var r = randf_range(58.0, 88.0)
                candidate = Vector3(cos(base_ang) * r, 0.0, sin(base_ang) * r)
            elif GameState.map_selected == "Arena_4P.tscn":
                var base_ang = pit_angles[i] + randf_range(-0.18, 0.18)
                var r = randf_range(48.0, 75.0)
                candidate = Vector3(cos(base_ang) * r, 0.0, sin(base_ang) * r)
            else: # 1v1 Arena
                var side_x = -1.0 if i == 0 else 1.0
                candidate = Vector3(side_x * randf_range(40.0, 68.0), 0.0, randf_range(-55.0, 55.0))
                
            if _is_pos_clear(candidate, 4.0, 10.0, 7.5):
                _create_scorpion_pit(parent, candidate)
                placed_feature_records.append({"pos": candidate, "radius": 7.5, "type": "pit"})
                placed = true
        if not placed:
            # Deterministic guaranteed fallback position
            var fallback = Vector3.ZERO
            if GameState.map_selected == "Arena_6P.tscn":
                var ang = pit_angles[i]
                fallback = Vector3(cos(ang) * 70.0, 0.0, sin(ang) * 70.0)
            elif GameState.map_selected == "Arena_4P.tscn":
                var ang = pit_angles[i]
                fallback = Vector3(cos(ang) * 58.0, 0.0, sin(ang) * 58.0)
            else:
                var side_x = -1.0 if i == 0 else 1.0
                fallback = Vector3(side_x * 52.0, 0.0, 22.0 if i == 0 else -22.0)
            _create_scorpion_pit(parent, fallback)
            placed_feature_records.append({"pos": fallback, "radius": 7.5, "type": "pit"})

    # 2. Ant Hills (2 territorial ant hills, each with 50 swarm ants) - GUARANTEED PLACEMENT
    var hill_angles = [deg_to_rad(120.0), deg_to_rad(300.0)] if GameState.map_selected == "Arena_6P.tscn" else ([deg_to_rad(135.0), deg_to_rad(315.0)] if GameState.map_selected == "Arena_4P.tscn" else [0.0, PI])
    for i in range(2):
        var placed = false
        attempts = 0
        while not placed and attempts < 120:
            attempts += 1
            var candidate = Vector3.ZERO
            if GameState.map_selected == "Arena_6P.tscn":
                var base_ang = hill_angles[i] + randf_range(-0.15, 0.15)
                var r = randf_range(58.0, 88.0)
                candidate = Vector3(cos(base_ang) * r, 0.0, sin(base_ang) * r)
            elif GameState.map_selected == "Arena_4P.tscn":
                var base_ang = hill_angles[i] + randf_range(-0.18, 0.18)
                var r = randf_range(48.0, 75.0)
                candidate = Vector3(cos(base_ang) * r, 0.0, sin(base_ang) * r)
            else: # 1v1 Arena
                var side_x = 1.0 if i == 0 else -1.0
                candidate = Vector3(side_x * randf_range(42.0, 70.0), 0.0, randf_range(-55.0, 55.0))
                
            if _is_pos_clear(candidate, 4.0, 10.0, 6.5):
                _create_ant_hill(parent, candidate)
                placed_feature_records.append({"pos": candidate, "radius": 6.5, "type": "hill"})
                placed = true
        if not placed:
            # Deterministic guaranteed fallback position
            var fallback = Vector3.ZERO
            if GameState.map_selected == "Arena_6P.tscn":
                var ang = hill_angles[i]
                fallback = Vector3(cos(ang) * 72.0, 0.0, sin(ang) * 72.0)
            elif GameState.map_selected == "Arena_4P.tscn":
                var ang = hill_angles[i]
                fallback = Vector3(cos(ang) * 60.0, 0.0, sin(ang) * 60.0)
            else:
                var side_x = 1.0 if i == 0 else -1.0
                fallback = Vector3(side_x * 54.0, 0.0, -26.0 if i == 0 else 26.0)
            _create_ant_hill(parent, fallback)
            placed_feature_records.append({"pos": fallback, "radius": 6.5, "type": "hill"})

    # 3. Higher Sand Dunes (14 to 18 obstacle dunes in open desert)
    var dune_count = randi_range(14, 18)
    attempts = 0
    var placed_dunes = 0
    var max_extent = maxf(75.0, GameState.current_map_radius * 0.65)
    while placed_dunes < dune_count and attempts < 400:
        attempts += 1
        var candidate = Vector3(randf_range(-max_extent, max_extent), 0.0, randf_range(-max_extent, max_extent))
        if _is_pos_clear(candidate, 5.0, 14.0, 8.5):
            _create_sand_dune_blocker(parent, candidate)
            placed_feature_records.append({"pos": candidate, "radius": 8.5, "type": "dune"})
            placed_dunes += 1

    # Flush batched GPU MultiMeshInstance3D nodes for sand dunes and scorpion pit rocks
    if _pending_sand_dune_tfs.size() > 0:
        var dune_mat := StandardMaterial3D.new()
        dune_mat.albedo_color = Color(0.86, 0.70, 0.42)
        dune_mat.roughness = 0.95
        var c_mesh := CylinderMesh.new()
        c_mesh.top_radius = 0.25
        c_mesh.bottom_radius = 1.0
        c_mesh.height = 1.0
        var dune_mm := MultiMesh.new()
        dune_mm.transform_format = MultiMesh.TRANSFORM_3D
        dune_mm.mesh = c_mesh
        dune_mm.instance_count = _pending_sand_dune_tfs.size()
        for idx in range(_pending_sand_dune_tfs.size()):
            dune_mm.set_instance_transform(idx, _pending_sand_dune_tfs[idx])
        var dunes_mmi := MultiMeshInstance3D.new()
        dunes_mmi.name = "SandDunesMMI"
        dunes_mmi.multimesh = dune_mm
        dunes_mmi.material_override = dune_mat
        parent.add_child(dunes_mmi)

    if _pending_pit_rock_tfs.size() > 0:
        var rock_mat := StandardMaterial3D.new()
        rock_mat.albedo_color = Color(0.72, 0.55, 0.40)
        rock_mat.roughness = 0.8
        var r_box := BoxMesh.new()
        r_box.size = Vector3(1.0, 1.0, 1.0)
        var rock_mm := MultiMesh.new()
        rock_mm.transform_format = MultiMesh.TRANSFORM_3D
        rock_mm.mesh = r_box
        rock_mm.instance_count = _pending_pit_rock_tfs.size()
        for idx in range(_pending_pit_rock_tfs.size()):
            rock_mm.set_instance_transform(idx, _pending_pit_rock_tfs[idx])
        var rocks_mmi := MultiMeshInstance3D.new()
        rocks_mmi.name = "PitRocksMMI"
        rocks_mmi.multimesh = rock_mm
        rocks_mmi.material_override = rock_mat
        parent.add_child(rocks_mmi)

func _create_sand_dune_blocker(parent: Node3D, pos: Vector3):
    var dune = StaticBody3D.new()
    dune.position = pos
    dune.collision_layer = 1
    dune.collision_mask = 0
    
    var r_base = randf_range(6.5, 9.5)
    var h = randf_range(3.2, 4.2)
    
    var col = CollisionShape3D.new()
    var cyl = CylinderShape3D.new()
    cyl.radius = r_base * 0.85
    cyl.height = h
    col.shape = cyl
    col.position.y = h * 0.5
    dune.add_child(col)
    
    var sx = randf_range(1.1, 1.6)
    var sz = randf_range(0.8, 1.2)
    dune.scale = Vector3(sx, 1.0, sz)
    parent.add_child(dune)

    var rot_y = randf() * TAU
    var dune_basis := Basis(Vector3.UP, rot_y).scaled(Vector3(r_base * sx, h, r_base * sz))
    _pending_sand_dune_tfs.append(Transform3D(dune_basis, pos + Vector3(0.0, h * 0.5, 0.0)))

func _create_scorpion_pit(parent: Node3D, pos: Vector3):
    var pit_body = StaticBody3D.new()
    pit_body.name = "ScorpionNest_" + str(Time.get_ticks_usec())
    pit_body.position = pos
    pit_body.add_to_group("Targetable")
    pit_body.add_to_group("NeutralStructure")
    pit_body.add_to_group("Structure")
    parent.add_child(pit_body)
    
    var col = CollisionShape3D.new()
    var col_cyl = CylinderShape3D.new()
    col_cyl.radius = 4.5
    col_cyl.height = 1.6
    col.shape = col_cyl
    col.position.y = 0.8
    pit_body.add_child(col)
    
    var hc = HealthComponent.new()
    hc.name = "HealthComponent"
    pit_body.add_child(hc)
    hc.set_max_health(650.0)
    
    var pit_floor = MeshInstance3D.new()
    var pf_cyl = CylinderMesh.new()
    pf_cyl.top_radius = 6.2
    pf_cyl.bottom_radius = 6.8
    pf_cyl.height = 0.12
    var pf_mat = StandardMaterial3D.new()
    pf_mat.albedo_color = Color(0.64, 0.42, 0.26)
    pf_mat.roughness = 0.95
    pit_floor.mesh = pf_cyl
    pit_floor.material_override = pf_mat
    pit_floor.position.y = 0.06
    pit_body.add_child(pit_floor)
    
    for r in range(8):
        var ang = (TAU / 8.0) * r + randf_range(-0.15, 0.15)
        var r_sz = randf_range(1.0, 1.8)
        var r_h = randf_range(0.6, 1.2)
        var r_pos = pos + Vector3(cos(ang) * 5.8, 0.4, sin(ang) * 5.8)
        var r_basis = Basis.from_euler(Vector3(randf() * 0.4, randf() * TAU, randf() * 0.4)).scaled(Vector3(r_sz, r_h, r_sz))
        _pending_pit_rock_tfs.append(Transform3D(r_basis, r_pos))
        
    # Initial scorpions (15 scorpions)
    for s in range(15):
        var ang = (TAU / 15.0) * s + randf_range(-0.15, 0.15)
        var dist = randf_range(1.0, 4.2)
        var scorp = TerritorialCreatureScript.new()
        scorp.configure_creature("Scorpion", pos)
        scorp.position = pos + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist)
        parent.add_child(scorp)
        
    # Slow spawn timer (adds 1 every 6.0s up to 15 max, stops when nest destroyed)
    var spawn_timer = Timer.new()
    spawn_timer.wait_time = 6.0
    spawn_timer.autostart = true
    spawn_timer.timeout.connect(func():
        if not is_instance_valid(pit_body) or hc.is_dead:
            spawn_timer.stop()
            spawn_timer.queue_free()
            return
        var living_scorpions = 0
        for sc in parent.get_children():
            if sc is CharacterBody3D and sc.get("creature_type") == "Scorpion":
                var shc = sc.get_node_or_null("HealthComponent")
                if shc and not shc.is_dead and sc.get("home_position") != null and sc.home_position.distance_to(pos) < 18.0:
                    living_scorpions += 1
        if living_scorpions < 15:
            var ang = randf() * TAU
            var dist = randf_range(1.0, 3.8)
            var new_scorp = TerritorialCreatureScript.new()
            new_scorp.configure_creature("Scorpion", pos)
            new_scorp.position = pos + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist)
            parent.add_child(new_scorp)
    )
    pit_body.add_child(spawn_timer)

func _create_ant_hill(parent: Node3D, pos: Vector3):
    var hill_body = StaticBody3D.new()
    hill_body.name = "AntHill_" + str(Time.get_ticks_usec())
    hill_body.position = pos
    hill_body.add_to_group("Targetable")
    hill_body.add_to_group("NeutralStructure")
    hill_body.add_to_group("Structure")
    parent.add_child(hill_body)
    
    var col = CollisionShape3D.new()
    var col_cyl = CylinderShape3D.new()
    col_cyl.radius = 3.6
    col_cyl.height = 2.0
    col.shape = col_cyl
    col.position.y = 1.0
    hill_body.add_child(col)
    
    var hc = HealthComponent.new()
    hc.name = "HealthComponent"
    hill_body.add_child(hc)
    hc.set_max_health(450.0)
    
    var hill_mesh = MeshInstance3D.new()
    var hm = CylinderMesh.new()
    hm.top_radius = 0.6
    hm.bottom_radius = 3.8
    hm.height = 1.8
    var h_mat = StandardMaterial3D.new()
    h_mat.albedo_color = Color(0.74, 0.48, 0.24)
    h_mat.roughness = 0.95
    hill_mesh.mesh = hm
    hill_mesh.material_override = h_mat
    hill_mesh.position.y = 0.9
    hill_body.add_child(hill_mesh)
    
    var hole = MeshInstance3D.new()
    var hole_c = CylinderMesh.new()
    hole_c.top_radius = 0.35
    hole_c.bottom_radius = 0.35
    hole_c.height = 0.15
    var hole_mat = StandardMaterial3D.new()
    hole_mat.albedo_color = Color(0.12, 0.08, 0.05)
    hole.mesh = hole_c
    hole.material_override = hole_mat
    hole.position.y = 1.82
    hill_body.add_child(hole)
    
    # Initial swarm ants (50 swarm ants)
    for a in range(50):
        var ang = (TAU / 50.0) * a + randf_range(-0.08, 0.08)
        var dist = randf_range(1.2, 4.5)
        var ant = TerritorialCreatureScript.new()
        ant.configure_creature("SwarmAnt", pos)
        ant.position = pos + Vector3(cos(ang) * dist, 0.1, sin(ang) * dist)
        parent.add_child(ant)
        
    # Slow spawn timer (adds 1 every 3.5s up to 50 max, stops when hill destroyed)
    var spawn_timer = Timer.new()
    spawn_timer.wait_time = 3.5
    spawn_timer.autostart = true
    spawn_timer.timeout.connect(func():
        if not is_instance_valid(hill_body) or hc.is_dead:
            spawn_timer.stop()
            spawn_timer.queue_free()
            return
        var living_ants = 0
        for an in parent.get_children():
            if an is CharacterBody3D and an.get("creature_type") == "SwarmAnt":
                var ahc = an.get_node_or_null("HealthComponent")
                if ahc and not ahc.is_dead and an.get("home_position") != null and an.home_position.distance_to(pos) < 18.0:
                    living_ants += 1
        if living_ants < 50:
            var ang = randf() * TAU
            var dist = randf_range(1.2, 4.0)
            var new_ant = TerritorialCreatureScript.new()
            new_ant.configure_creature("SwarmAnt", pos)
            new_ant.position = pos + Vector3(cos(ang) * dist, 0.1, sin(ang) * dist)
            parent.add_child(new_ant)
    )
    hill_body.add_child(spawn_timer)

# --- Solar Light Beam Hazard Management ---
@rpc("authority", "call_local", "reliable")
func sync_spawn_solar_beam(x: float, z: float, dur: float, beam_name: String):
    var beam = SolarBeamHazardScript.new()
    beam.name = beam_name
    beam.position = Vector3(x, 0.0, z)
    beam.setup_duration(dur)
    beam.beam_finished.connect(_on_solar_beam_finished)
    add_child(beam)
    current_solar_beam = beam

func _on_solar_beam_finished():
    current_solar_beam = null
    solar_beam_timer = randf_range(10.0, 30.0)

# --- Stealth Brush Detection & Visibility ---
static func is_unit_stealthed_from(target: Node3D, observer: Node3D) -> bool:
    return GameState.is_unit_stealthed_from(target, observer)

var _stealth_vis_timer: float = 0.0

func _update_stealth_visibility():
    _stealth_vis_timer -= get_process_delta_time()
    if _stealth_vis_timer > 0.0: return
    _stealth_vis_timer = 0.08
    
    var local_team = GameState.local_player_team if GameState.local_player_team != "" else (players[0].team if players.size() > 0 else "")
    var is_spectator = (GameState.current_mode == "AI_VS_AI")
    var local_allies: Array = []
    var allies_loaded := false
    
    for unit in get_tree().get_nodes_in_group("Targetable"):
        if not is_instance_valid(unit): continue
        # Fast path: the vast majority of units are not in stealth grass - skip all string/property checks
        if not (unit.has_meta("in_stealth_grass") and bool(unit.get_meta("in_stealth_grass"))):
            if not unit.visible:
                unit.visible = true
            continue
        if "Plane" in unit.name or unit.get("flight_height") != null or unit.get("is_flying") == true:
            unit.visible = true
            continue
            
        if is_spectator:
            unit.visible = true
            continue
        if unit.has_meta("stealth_revealed_timer") and float(unit.get_meta("stealth_revealed_timer")) > 0.0:
            unit.visible = true
            continue
        if local_team != "" and unit.is_in_group(local_team):
            unit.visible = true
        else:
            if not allies_loaded:
                allies_loaded = true
                local_allies = get_tree().get_nodes_in_group(local_team) if local_team != "" else []
            var revealed = false
            var u_pos = unit.global_position
            for ally in local_allies:
                if is_instance_valid(ally) and ally != unit:
                    if ally.global_position.distance_squared_to(u_pos) <= 16.0:
                        revealed = true
                        break
            unit.visible = revealed

# =========================================================================
# THE REALM OF HARMONY: GOLD FACE PATHS, MULTICOLORED LINES & OFF-PATH HUSKS
# =========================================================================

func _generate_realm_of_harmony(parent: Node3D) -> void:
    placed_feature_records.clear()

    # 1. Paths made up of sculpted 3D Gold Faces
    var faces_root := Node3D.new()
    faces_root.name = "GoldPathFaces"
    parent.add_child(faces_root)

    var gold_face_mat := StandardMaterial3D.new()
    gold_face_mat.albedo_color = Color(1.0, 0.85, 0.22)
    gold_face_mat.metallic = 0.96
    gold_face_mat.roughness = 0.14
    gold_face_mat.emission_enabled = true
    gold_face_mat.emission = Color(1.0, 0.78, 0.16)
    gold_face_mat.emission_energy_multiplier = 1.35

    var gold_feature_mat := StandardMaterial3D.new()
    gold_feature_mat.albedo_color = Color(1.0, 0.92, 0.42)
    gold_feature_mat.metallic = 0.98
    gold_feature_mat.roughness = 0.10
    gold_feature_mat.emission_enabled = true
    gold_feature_mat.emission = Color(1.0, 0.86, 0.28)
    gold_feature_mat.emission_energy_multiplier = 2.1

    var face_transforms: Array[Transform3D] = []
    if GameState.lane_segments.size() > 0:
        var step_len: float = 7.0 if GameState.lane_segments.size() <= 12 else 11.0
        for seg in GameState.lane_segments:
            var a3: Vector3 = seg.get("a", Vector3.ZERO)
            var b3: Vector3 = seg.get("b", Vector3.ZERO)
            var w_lane: float = float(seg.get("width", 20.0))
            var diff: Vector3 = b3 - a3
            var seg_len: float = diff.length()
            if seg_len < 1.0:
                continue
            var dir_z: Vector3 = diff / seg_len
            var dir_x := Vector3(-dir_z.z, 0.0, dir_z.x)
            var steps: int = maxi(2, int(floor(seg_len / step_len)))
            var cols: int = 2 if w_lane < 19.0 else 3
            for s_i in range(steps):
                var lz: float = (float(s_i) + 0.5) * (seg_len / float(steps)) + randf_range(-0.7, 0.7)
                for c_i in range(-cols + 1, cols):
                    var lx: float = float(c_i) * 4.5 + randf_range(-0.6, 0.6)
                    var world_p: Vector3 = a3 + dir_z * lz + dir_x * lx
                    var yaw: float = randf() * TAU
                    var sc: float = randf_range(1.18, 1.92)
                    var b := Basis(Vector3.UP, yaw).scaled(Vector3(sc, 1.0, sc * 1.18))
                    face_transforms.append(Transform3D(b, Vector3(world_p.x, 0.06, world_p.z)))
                    if face_transforms.size() >= 900:
                        break
                if face_transforms.size() >= 900:
                    break
            if face_transforms.size() >= 900:
                break
    else:
        for z_step in range(-72, 74, 5):
            for x_idx in range(-2, 3):
                var px: float = float(x_idx) * 4.6 + randf_range(-0.75, 0.75)
                var pz: float = float(z_step) + randf_range(-0.75, 0.75)
                var yaw: float = randf() * TAU
                var sc: float = randf_range(1.25, 2.05)
                var b := Basis(Vector3.UP, yaw).scaled(Vector3(sc, 1.0, sc * 1.2))
                face_transforms.append(Transform3D(b, Vector3(px, 0.06, pz)))

    var total_faces: int = face_transforms.size()
    if total_faces > 0:
        # MultiMesh 1: Sculpted Gold Face Plate
        var plate_mm := MultiMesh.new()
        plate_mm.transform_format = MultiMesh.TRANSFORM_3D
        var plate_cyl := CylinderMesh.new()
        plate_cyl.top_radius = 1.15
        plate_cyl.bottom_radius = 1.25
        plate_cyl.height = 0.09
        plate_mm.mesh = plate_cyl
        plate_mm.instance_count = total_faces

        # MultiMesh 2 & 3: Left and Right Gold Eyes
        var eye_l_mm := MultiMesh.new()
        eye_l_mm.transform_format = MultiMesh.TRANSFORM_3D
        var eye_sph := SphereMesh.new()
        eye_sph.radius = 0.24
        eye_sph.height = 0.18
        eye_l_mm.mesh = eye_sph
        eye_l_mm.instance_count = total_faces

        var eye_r_mm := MultiMesh.new()
        eye_r_mm.transform_format = MultiMesh.TRANSFORM_3D
        eye_r_mm.mesh = eye_sph
        eye_r_mm.instance_count = total_faces

        # MultiMesh 4: Sculpted Gold Nose Bridge
        var nose_mm := MultiMesh.new()
        nose_mm.transform_format = MultiMesh.TRANSFORM_3D
        var nose_prism := PrismMesh.new()
        nose_prism.size = Vector3(0.24, 0.16, 0.42)
        nose_mm.mesh = nose_prism
        nose_mm.instance_count = total_faces

        # MultiMesh 5: Sculpted Gold Mouth / Lips
        var mouth_mm := MultiMesh.new()
        mouth_mm.transform_format = MultiMesh.TRANSFORM_3D
        var mouth_box := BoxMesh.new()
        mouth_box.size = Vector3(0.62, 0.12, 0.20)
        mouth_mm.mesh = mouth_box
        mouth_mm.instance_count = total_faces

        for idx in range(total_faces):
            var tf: Transform3D = face_transforms[idx]
            plate_mm.set_instance_transform(idx, tf)
            eye_l_mm.set_instance_transform(idx, tf * Transform3D(Basis.IDENTITY, Vector3(-0.38, 0.06, -0.26)))
            eye_r_mm.set_instance_transform(idx, tf * Transform3D(Basis.IDENTITY, Vector3(0.38, 0.06, -0.26)))
            nose_mm.set_instance_transform(idx, tf * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.07, 0.02)))
            mouth_mm.set_instance_transform(idx, tf * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.06, 0.44)))

        var plate_mmi := MultiMeshInstance3D.new()
        plate_mmi.name = "FacePlatesMMI"
        plate_mmi.multimesh = plate_mm
        plate_mmi.material_override = gold_face_mat
        faces_root.add_child(plate_mmi)

        var eye_l_mmi := MultiMeshInstance3D.new()
        eye_l_mmi.name = "LeftEyesMMI"
        eye_l_mmi.multimesh = eye_l_mm
        eye_l_mmi.material_override = gold_feature_mat
        faces_root.add_child(eye_l_mmi)

        var eye_r_mmi := MultiMeshInstance3D.new()
        eye_r_mmi.name = "RightEyesMMI"
        eye_r_mmi.multimesh = eye_r_mm
        eye_r_mmi.material_override = gold_feature_mat
        faces_root.add_child(eye_r_mmi)

        var nose_mmi := MultiMeshInstance3D.new()
        nose_mmi.name = "NosesMMI"
        nose_mmi.multimesh = nose_mm
        nose_mmi.material_override = gold_feature_mat
        faces_root.add_child(nose_mmi)

        var mouth_mmi := MultiMeshInstance3D.new()
        mouth_mmi.name = "MouthsMMI"
        mouth_mmi.multimesh = mouth_mm
        mouth_mmi.material_override = gold_feature_mat
        faces_root.add_child(mouth_mmi)

    # 2. Surrounding off-path area: 120 multicolored lines batched into a single GPU MultiMeshInstance3D
    var lines_root := Node3D.new()
    lines_root.name = "HarmonyColoredLines"
    parent.add_child(lines_root)

    var line_palette: Array[Color] = [
        Color(1.0, 0.14, 0.32), # Crimson Red
        Color(0.08, 0.92, 1.0), # Electric Cyan
        Color(0.22, 1.0, 0.36), # Emerald Neon Green
        Color(1.0, 0.18, 0.88), # Vivid Magenta
        Color(0.28, 0.46, 1.0), # Cobalt Blue
        Color(1.0, 0.54, 0.08), # Tangerine Orange
        Color(0.68, 0.22, 1.0), # Royal Violet
        Color(0.75, 1.0, 0.12), # Chartreuse Lime
        Color(0.12, 0.96, 0.72), # Aquamarine
        Color(1.0, 0.36, 0.62), # Hot Rose
        Color(1.0, 0.92, 0.18), # Solar Yellow
        Color(0.45, 0.78, 1.0)  # Sky Azure
    ]

    var max_bound: float = maxf(88.0, GameState.current_map_radius * 0.72)
    var line_count: int = 120
    var line_tfs: Array[Transform3D] = []
    var line_cols: Array[Color] = []
    var created_lines: int = 0
    var line_attempts: int = 0
    while created_lines < line_count and line_attempts < 500:
        line_attempts += 1
        var cx: float = randf_range(-max_bound, max_bound)
        var cz: float = randf_range(-max_bound, max_bound)
        var center_pos := Vector3(cx, 0.03 + float(created_lines % 5) * 0.003, cz)
        if GameState.get_distance_to_nearest_lane(center_pos) < 16.5:
            continue

        var line_len: float = randf_range(14.0, 48.0)
        var line_width: float = randf_range(0.32, 0.72)
        var yaw_angle: float = randf() * TAU

        # Ensure endpoints also don't cross right over the center of the golden path
        var dir_vec := Vector3(sin(yaw_angle), 0.0, cos(yaw_angle))
        var end_a: Vector3 = center_pos + dir_vec * (line_len * 0.45)
        var end_b: Vector3 = center_pos - dir_vec * (line_len * 0.45)
        if GameState.get_distance_to_nearest_lane(end_a) < 13.5 or GameState.get_distance_to_nearest_lane(end_b) < 13.5:
            line_len *= 0.45

        var l_basis := Basis(Vector3.UP, yaw_angle).scaled(Vector3(line_width, 1.0, line_len))
        line_tfs.append(Transform3D(l_basis, center_pos))
        line_cols.append(line_palette[created_lines % line_palette.size()])
        created_lines += 1

    if line_tfs.size() > 0:
        var batched_line_mat := StandardMaterial3D.new()
        batched_line_mat.vertex_color_use_as_albedo = true
        batched_line_mat.roughness = 0.2
        batched_line_mat.emission_enabled = true
        batched_line_mat.emission = Color(0.65, 0.65, 0.65)
        batched_line_mat.emission_energy_multiplier = 1.65

        var unit_line_box := BoxMesh.new()
        unit_line_box.size = Vector3(1.0, 0.04, 1.0)

        var lines_mm := MultiMesh.new()
        lines_mm.transform_format = MultiMesh.TRANSFORM_3D
        lines_mm.use_colors = true
        lines_mm.mesh = unit_line_box
        lines_mm.instance_count = line_tfs.size()
        for idx in range(line_tfs.size()):
            lines_mm.set_instance_transform(idx, line_tfs[idx])
            lines_mm.set_instance_color(idx, line_cols[idx])

        var lines_mmi := MultiMeshInstance3D.new()
        lines_mmi.name = "ColoredLinesMMI"
        lines_mmi.multimesh = lines_mm
        lines_mmi.material_override = batched_line_mat
        lines_root.add_child(lines_mmi)

    # 3. Spawn 2 initial roaming Beasts of Harmony (1 Melee many-eyed eater, 1 Ranged eye-laser) in the off-path expanse
    var initial_positions: Array[Vector3] = [
        Vector3(-48.0, 0.2, -24.0),
        Vector3(48.0, 0.2, 24.0)
    ]
    var variants: Array[String] = ["MELEE", "RANGED"]
    for b_idx in range(2):
        var beast := BeastOfHarmonyScript.new()
        beast.name = "BeastOfHarmony_" + variants[b_idx] + "_Init_" + str(b_idx)
        parent.add_child(beast)
        beast.configure_beast(variants[b_idx], initial_positions[b_idx])

    # 4. Spawn 2 roaming Harmony Infectors on The Realm of Harmony map that convert units into their Husk form
    var infector_positions: Array[Vector3] = [
        Vector3(-36.0, 0.2, 28.0),
        Vector3(36.0, 0.2, -28.0)
    ]
    for inf_idx in range(2):
        var infector := HarmonyInfectorScript.new()
        infector.name = "RealmHarmonyInfector_" + str(inf_idx)
        infector.team = "SideHarmony"
        infector.is_gilded = false
        infector.position = infector_positions[inf_idx]
        parent.add_child(infector)

var _harmony_check_timer: float = 0.0

func _update_realm_of_harmony(delta: float) -> void:
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if not multiplayer.is_server():
            return

    _harmony_check_timer += delta
    if _harmony_check_timer < 0.25:
        return
    var step_dt: float = _harmony_check_timer
    _harmony_check_timer = 0.0

    var seen_ids := {}
    var candidates: Array[Node] = []
    for n in get_tree().get_nodes_in_group("Targetable"):
        if is_instance_valid(n):
            seen_ids[n.get_instance_id()] = true
            candidates.append(n)
    for extra in get_tree().get_nodes_in_group("Units"):
        if is_instance_valid(extra) and not seen_ids.has(extra.get_instance_id()):
            seen_ids[extra.get_instance_id()] = true
            candidates.append(extra)

    for node in candidates:
        if not is_instance_valid(node) or not (node is Node3D):
            continue
        var u := node as Node3D
        if u.has_meta("is_husk_of_harmony") or u.has_meta("is_beast_of_harmony"):
            continue
        if u.is_in_group("SideHarmony") or u.is_in_group("Harmony") or u.is_in_group("HuskOfHarmony") or u.is_in_group("BeastOfHarmony") or u.is_in_group("Beast"):
            continue
        if u.is_in_group("Structure") or u.is_in_group("Buildings") or "Base" in u.name or "Tower" in u.name or "CommandBay" in u.name or "Nest" in u.name or "Hill" in u.name or "Mine" in u.name:
            continue
        var hc := u.get_node_or_null("HealthComponent")
        if hc and hc.is_dead:
            continue

        var dist_to_lane: float = GameState.get_distance_to_nearest_lane(u.global_position)
        if dist_to_lane > 13.0:
            var off_timer: float = (float(u.get_meta("harmony_off_path_timer")) if u.has_meta("harmony_off_path_timer") else 0.0) + step_dt
            if off_timer >= 10.0:
                off_timer -= 10.0
                u.set_meta("harmony_off_path_timer", off_timer)
                var roll: float = randf()
                if roll < 0.01:
                    # 1% chance every 10 seconds off the path to become a Beast of Harmony!
                    transform_unit_to_beast_of_harmony(u)
                elif roll < 0.16:
                    # 15% chance every 10 seconds off the path to turn into a Husk of Harmony!
                    transform_unit_to_husk_of_harmony(u)
            else:
                u.set_meta("harmony_off_path_timer", off_timer)
        else:
            if u.has_meta("harmony_off_path_timer"):
                u.set_meta("harmony_off_path_timer", 0.0)


func transform_unit_to_husk_of_harmony(unit: Node3D) -> void:
    if unit == null or not is_instance_valid(unit):
        return
    HarmonyHuskBuilderScript.transform_into_husk(unit)

func transform_unit_to_beast_of_harmony(unit: Node3D, forced_variant: String = "") -> Node3D:
    if unit == null or not is_instance_valid(unit):
        return null
    var spawn_pos: Vector3 = unit.global_position
    var chosen_variant: String = forced_variant
    if chosen_variant == "":
        chosen_variant = "MELEE" if randf() < 0.5 else "RANGED"
    var beast := BeastOfHarmonyScript.new()
    beast.name = "BeastOfHarmony_" + chosen_variant + "_" + str(Time.get_ticks_usec())
    var parent_node: Node = get_node_or_null("EnvironmentFeatures")
    if parent_node == null:
        parent_node = self
    parent_node.add_child(beast)
    beast.configure_beast(chosen_variant, spawn_pos)
    unit.queue_free()
    return beast




# --- Frozen Tundra Generation (Breakable Ice Patches & Sea Lions) ---
func _generate_frozen_tundra(parent: Node3D):
    placed_feature_records.clear()
    var bip_script = load("res://Scripts/BreakableIcePatch.gd")
    var span = maxf(72.0, GameState.current_map_radius * 0.65)
    
    # 1. Large Breakable Ice Patches (collapses under heavy units or multiple units)
    var large_count = randi_range(6, 8)
    var attempts = 0
    var placed_large = 0
    while placed_large < large_count and attempts < 180:
        attempts += 1
        var candidate = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
        if _is_pos_clear(candidate, 5.0, 14.0, 8.8):
            var patch = bip_script.new()
            patch.patch_size = "LARGE"
            patch.position = candidate
            parent.add_child(patch)
            placed_feature_records.append({"pos": candidate, "radius": 8.8, "type": "ice_patch_large"})
            placed_large += 1

    # 2. Small Breakable Ice Patches (collapses under normal smaller units)
    var small_count = randi_range(10, 14)
    attempts = 0
    var placed_small = 0
    while placed_small < small_count and attempts < 240:
        attempts += 1
        var candidate = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
        if _is_pos_clear(candidate, 4.0, 12.0, 4.2):
            var patch = bip_script.new()
            patch.patch_size = "SMALL"
            patch.position = candidate
            parent.add_child(patch)
            placed_feature_records.append({"pos": candidate, "radius": 4.2, "type": "ice_patch_small"})
            placed_small += 1

    # 3. Arctic Frost Crystals (GPU MultiMeshInstance3D Batched)
    var frost_tfs: Array[Transform3D] = []
    for s in range(12):
        var c_pos = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
        if _is_pos_clear(c_pos, 3.0, 8.0, 2.0):
            var h_val: float = randf_range(3.0, 5.5)
            var rot_vec := Vector3(deg_to_rad(randf_range(-8.0, 8.0)), randf() * TAU, deg_to_rad(randf_range(-8.0, 8.0)))
            var m_basis := Basis.from_euler(rot_vec).scaled(Vector3(1.2, h_val, 1.2))
            frost_tfs.append(Transform3D(m_basis, c_pos + Vector3(0.0, h_val * 0.5, 0.0)))
            placed_feature_records.append({"pos": c_pos, "radius": 2.0, "type": "ice_spire"})

    if frost_tfs.size() > 0:
        var s_mat := StandardMaterial3D.new()
        s_mat.albedo_color = Color(0.72, 0.90, 1.0, 0.85)
        s_mat.roughness = 0.15
        s_mat.metallic = 0.25
        s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        var p_mesh := PrismMesh.new()
        p_mesh.size = Vector3(1.0, 1.0, 1.0)
        var frost_mm := MultiMesh.new()
        frost_mm.transform_format = MultiMesh.TRANSFORM_3D
        frost_mm.mesh = p_mesh
        frost_mm.instance_count = frost_tfs.size()
        for idx in range(frost_tfs.size()):
            frost_mm.set_instance_transform(idx, frost_tfs[idx])
        var frost_mmi := MultiMeshInstance3D.new()
        frost_mmi.name = "FrostCrystalsMMI"
        frost_mmi.multimesh = frost_mm
        frost_mmi.material_override = s_mat
        parent.add_child(frost_mmi)


# --- Volcanic Brimstone Generation (Chequered Stone, Off-path Fire Geysers) ---
func _generate_volcanic_brimstone(parent: Node3D):
    placed_feature_records.clear()
    var span = maxf(72.0, GameState.current_map_radius * 0.65)

    # 0. Active Volcanoes shooting Magma Rocks off-path (scales smoothly with map radius & player count)
    var volcano_script = load("res://Scripts/Volcano.gd")
    var volcano_count = clampi(int(round(GameState.current_map_radius / 40.0)), 2, 10)
    var v_attempts = 0
    var placed_volcanoes = 0
    var max_v_attempts = volcano_count * 50
    while placed_volcanoes < volcano_count and v_attempts < max_v_attempts:
        v_attempts += 1
        var v_cand = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
        if _is_pos_clear(v_cand, 8.0, 16.0, 7.0):
            var v_node = volcano_script.new()
            v_node.position = v_cand
            parent.add_child(v_node)
            placed_feature_records.append({"pos": v_cand, "radius": 7.0, "type": "volcano"})
            placed_volcanoes += 1

    var vfh_script = load("res://Scripts/VolcanicFireHazard.gd")
    
    # 1. Volcanic Fire Hazards popping up off-path (scales with map size)
    var hazard_count = clampi(int(round(GameState.current_map_radius * 0.16)), 16, 65)
    var attempts = 0
    var placed_hazards = 0
    var max_h_attempts = hazard_count * 20
    while placed_hazards < hazard_count and attempts < max_h_attempts:
        attempts += 1
        var candidate = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
        if _is_pos_clear(candidate, 4.0, 11.0, 3.0):
            var hazard = vfh_script.new()
            hazard.position = candidate
            parent.add_child(hazard)
            placed_feature_records.append({"pos": candidate, "radius": 3.0, "type": "fire_hazard"})
            placed_hazards += 1

    # 2. Obsidian Basalt Rock Spires (GPU MultiMeshInstance3D Batched)
    var obs_tfs: Array[Transform3D] = []
    var spire_count = clampi(int(round(GameState.current_map_radius * 0.12)), 14, 45)
    for r in range(spire_count):
        var r_pos = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
        if _is_pos_clear(r_pos, 3.0, 9.0, 2.5):
            var sx := randf_range(1.6, 2.8)
            var sy := randf_range(3.5, 6.5)
            var sz := randf_range(1.6, 2.8)
            var rot_vec := Vector3(deg_to_rad(randf_range(-10.0, 10.0)), randf() * TAU, deg_to_rad(randf_range(-10.0, 10.0)))
            var m_basis := Basis.from_euler(rot_vec).scaled(Vector3(sx, sy, sz))
            obs_tfs.append(Transform3D(m_basis, r_pos + Vector3(0.0, sy * 0.5, 0.0)))
            placed_feature_records.append({"pos": r_pos, "radius": 2.5, "type": "obsidian_spire"})

    if obs_tfs.size() > 0:
        var b_mat := StandardMaterial3D.new()
        b_mat.albedo_color = Color(0.12, 0.08, 0.08)
        b_mat.roughness = 0.92
        var p_mesh := PrismMesh.new()
        p_mesh.size = Vector3(1.0, 1.0, 1.0)
        var obs_mm := MultiMesh.new()
        obs_mm.transform_format = MultiMesh.TRANSFORM_3D
        obs_mm.mesh = p_mesh
        obs_mm.instance_count = obs_tfs.size()
        for idx in range(obs_tfs.size()):
            obs_mm.set_instance_transform(idx, obs_tfs[idx])
        var obs_mmi := MultiMeshInstance3D.new()
        obs_mmi.name = "ObsidianSpiresMMI"
        obs_mmi.multimesh = obs_mm
        obs_mmi.material_override = b_mat
        parent.add_child(obs_mmi)


# --- Biome Death Event (Volcanic Reincarnation) ---
func on_unit_died_biome_event(dead_unit: Node3D):
    if active_biome != "VOLCANIC_BRIMSTONE" or not is_instance_valid(dead_unit):
        return
    if dead_unit.is_in_group("FireMonster") or dead_unit.is_in_group("FireEntity") or dead_unit.is_in_group("NeutralCreature"):
        return
    if "Base" in dead_unit.name or "Tower" in dead_unit.name or "CommandBay" in dead_unit.name or "Structure" in dead_unit.name:
        return

    # 50/50 chance to become a fire creature on death in volcanic biome
    if randf() > 0.5:
        return

    var spawn_pos = dead_unit.global_position
    var is_big = false
    var hc = dead_unit.get_node_or_null("HealthComponent")
    if hc and hc.max_health >= 300.0:
        is_big = true
    for keyword in ["Tank", "Mech", "Leviathan", "Spiker", "Monstrous", "Octopus", "Big", "Commander"]:
        if keyword in dead_unit.name:
            is_big = true
            break

    if is_big:
        var gfm_script = load("res://Scripts/GreaterFireMonster.gd")
        if gfm_script:
            var monster = gfm_script.new()
            monster.position = spawn_pos
            add_child(monster)
            print("🔥 A towering Greater Fire Monster rises from the ashes of ", dead_unit.name, " at ", spawn_pos)
    else:
        var sprite_script = null
        if randf() < 0.5:
            sprite_script = load("res://Scripts/FireSpriteMelee.gd")
        else:
            sprite_script = load("res://Scripts/FireSpriteRanged.gd")
        if sprite_script:
            var sprite = sprite_script.new()
            sprite.position = spawn_pos
            add_child(sprite)
            print("🔥 A Fire Sprite rises from the burning embers of ", dead_unit.name, " at ", spawn_pos)


# =========================================================================
# DEEP SPACE VACUUM BIOME: ASTEROID CRATERS, FLOATING MONOLITHS & VACUUM DOT
# =========================================================================
var _space_vacuum_timer: float = 0.0

func _generate_space_vacuum(parent: Node3D) -> void:
    placed_feature_records.clear()
    var span = maxf(72.0, GameState.current_map_radius * 0.65)

    var regolith_mat = StandardMaterial3D.new()
    regolith_mat.albedo_color = Color(0.18, 0.20, 0.25)
    regolith_mat.roughness = 0.92
    regolith_mat.metallic = 0.20

    var crystal_mat = StandardMaterial3D.new()
    crystal_mat.albedo_color = Color(0.32, 0.78, 1.0, 0.88)
    crystal_mat.roughness = 0.15
    crystal_mat.metallic = 0.35
    crystal_mat.emission_enabled = true
    crystal_mat.emission = Color(0.20, 0.65, 1.0)
    crystal_mat.emission_energy_multiplier = 1.6

    # 1. Impact Craters & Meteorite Outcrops off-path (GPU MultiMeshInstance3D Batched)
    var crater_tfs: Array[Transform3D] = []
    var shard_tfs: Array[Transform3D] = []
    for c_i in range(14):
        var c_pos = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
        if _is_pos_clear(c_pos, 4.0, 11.0, 3.8):
            var r_out = randf_range(2.6, 4.2)
            var rim_basis := Basis.IDENTITY.scaled(Vector3(r_out, 0.28, r_out))
            crater_tfs.append(Transform3D(rim_basis, c_pos + Vector3(0.0, 0.08, 0.0)))

            var shard_h = randf_range(2.2, 4.0)
            var s_rot := Vector3(deg_to_rad(randf_range(-14.0, 14.0)), randf() * TAU, deg_to_rad(randf_range(-14.0, 14.0)))
            var shard_basis := Basis.from_euler(s_rot).scaled(Vector3(1.1, shard_h, 1.1))
            shard_tfs.append(Transform3D(shard_basis, c_pos + Vector3(0.0, shard_h * 0.45, 0.0)))
            placed_feature_records.append({"pos": c_pos, "radius": r_out, "type": "space_crater"})

    if crater_tfs.size() > 0:
        var tm := TorusMesh.new()
        tm.outer_radius = 1.0
        tm.inner_radius = 0.65
        var c_mm := MultiMesh.new()
        c_mm.transform_format = MultiMesh.TRANSFORM_3D
        c_mm.mesh = tm
        c_mm.instance_count = crater_tfs.size()
        for idx in range(crater_tfs.size()):
            c_mm.set_instance_transform(idx, crater_tfs[idx])
        var c_mmi := MultiMeshInstance3D.new()
        c_mmi.name = "SpaceCraterRimsMMI"
        c_mmi.multimesh = c_mm
        c_mmi.material_override = regolith_mat
        parent.add_child(c_mmi)

    if shard_tfs.size() > 0:
        var pm := PrismMesh.new()
        pm.size = Vector3(1.0, 1.0, 1.0)
        var s_mm := MultiMesh.new()
        s_mm.transform_format = MultiMesh.TRANSFORM_3D
        s_mm.mesh = pm
        s_mm.instance_count = shard_tfs.size()
        for idx in range(shard_tfs.size()):
            s_mm.set_instance_transform(idx, shard_tfs[idx])
        var s_mmi := MultiMeshInstance3D.new()
        s_mmi.name = "SpaceCrystalShardsMMI"
        s_mmi.multimesh = s_mm
        s_mmi.material_override = crystal_mat
        parent.add_child(s_mmi)

    # 2. Zero-G Floating Asteroid Boulders above the off-path regolith (GPU MultiMesh + Vertex Shader)
    var ast_tfs: Array[Transform3D] = []
    for a_i in range(18):
        var a_pos = Vector3(randf_range(-span, span), randf_range(2.8, 7.5), randf_range(-span, span))
        if _is_pos_clear(Vector3(a_pos.x, 0.0, a_pos.z), 5.0, 12.0, 2.5):
            var rad = randf_range(0.9, 2.1)
            var a_rot := Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
            var a_basis := Basis.from_euler(a_rot).scaled(Vector3(rad * 1.25, rad * 0.82, rad * 1.08))
            ast_tfs.append(Transform3D(a_basis, a_pos))

    if ast_tfs.size() > 0:
        var sm := SphereMesh.new()
        sm.radius = 1.0
        sm.height = 1.7
        var a_mm := MultiMesh.new()
        a_mm.transform_format = MultiMesh.TRANSFORM_3D
        a_mm.mesh = sm
        a_mm.instance_count = ast_tfs.size()
        for idx in range(ast_tfs.size()):
            a_mm.set_instance_transform(idx, ast_tfs[idx])
        var a_mmi := MultiMeshInstance3D.new()
        a_mmi.name = "SpaceAsteroidsMMI"
        a_mmi.multimesh = a_mm
        a_mmi.material_override = GpuAcceleratorScript.get_space_asteroid_shader()
        parent.add_child(a_mmi)

func _is_unit_organic_for_vacuum(u: Node3D) -> bool:
    if not is_instance_valid(u):
        return false
    if u.is_in_group("Structures") or u.is_in_group("Structure") or u.is_in_group("Buildings"):
        return false
    var nm = u.name
    for struct_kw in ["Base", "Tower", "CommandBay", "Nest", "Hill", "Mine", "Wall"]:
        if struct_kw in nm:
            return false
    for mech_kw in ["Tank", "Mech", "Plane", "Walker", "Spider", "Drone", "Turret", "Bot", "Droid", "Cannon", "Ballista", "Artillery", "Catapult", "Chariot", "Golem", "StoneOctopus", "FireSprite", "FireMonster", "EyeOfHarmony"]:
        if mech_kw in nm:
            return false
    if u.is_in_group("Mechanical") or u.is_in_group("FireMonster") or u.is_in_group("FireEntity"):
        return false
    return true

func _is_unit_shielded_from_vacuum(u: Node3D, hc: HealthComponent, all_units: Array) -> bool:
    if hc.current_shield > 0.0:
        return true
    if u.has_meta("vacuum_sealed") and bool(u.get_meta("vacuum_sealed")):
        return true
    var u_team = u.get("team")
    var u_pos = u.global_position
    var nearby = GpuAcceleratorScript.query_nearby_units(u_pos, 6.6, get_tree())
    var check_list: Array = nearby if not nearby.is_empty() else all_units
    for ally in check_list:
        if ally == u or not is_instance_valid(ally) or not (ally is Node3D):
            continue
        if u_team != null and ally.get("team") != u_team:
            continue
        var a_hc = ally.get_node_or_null("HealthComponent") as HealthComponent
        if a_hc and a_hc.current_shield > 0.0 and a_hc.shield_type == "360":
            if u_pos.distance_to(ally.global_position) <= 6.5:
                return true
    return false

func _update_space_vacuum(delta: float) -> void:
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if not multiplayer.is_server():
            return
    _space_vacuum_timer += delta
    if _space_vacuum_timer < 1.0:
        return
    _space_vacuum_timer -= 1.0

    var all_units = get_tree().get_nodes_in_group("Units")
    for node in all_units:
        if not is_instance_valid(node) or not (node is Node3D):
            continue
        var u := node as Node3D
        var hc := u.get_node_or_null("HealthComponent") as HealthComponent
        if not hc or hc.is_dead or hc.current_health <= 0.0:
            continue
        if not _is_unit_organic_for_vacuum(u):
            continue
        if _is_unit_shielded_from_vacuum(u, hc, all_units):
            continue
        var vac_dmg = maxf(2.0, hc.max_health * 0.025)
        hc.take_vacuum_damage(vac_dmg)

# --- Deep Jungle Generation (Wooden Board Paths, Quicksand Sinkholes, GPU MultiMesh Jungle Trees & Gorilla/Monkey Nests) ---
var _pending_jungle_trunk_tfs: Array[Transform3D] = []
var _pending_jungle_crown_tfs: Array[Transform3D] = []
var _pending_jungle_crown_cols: Array[Color] = []
var _pending_jungle_vine_tfs: Array[Transform3D] = []
var _pending_jungle_frond_tfs: Array[Transform3D] = []
var _pending_jungle_coco_tfs: Array[Transform3D] = []
var _pending_jungle_buttress_tfs: Array[Transform3D] = []

func _generate_jungle(parent: Node3D):
    placed_feature_records.clear()
    _pending_jungle_trunk_tfs.clear()
    _pending_jungle_crown_tfs.clear()
    _pending_jungle_crown_cols.clear()
    _pending_jungle_vine_tfs.clear()
    _pending_jungle_frond_tfs.clear()
    _pending_jungle_coco_tfs.clear()
    _pending_jungle_buttress_tfs.clear()
    var sinkhole_script = load("res://Scripts/QuicksandSinkhole.gd")
    var span = maxf(75.0, GameState.current_map_radius * 0.65)
    var attempts = 0
    
    # 1. Gorilla Dens (1-2 territorial primate dens with 8-10 Gorillas) - GUARANTEED OFF-PATH PLACEMENT
    var den_angles = [deg_to_rad(60.0), deg_to_rad(240.0)] if GameState.map_selected == "Arena_6P.tscn" else ([deg_to_rad(60.0), deg_to_rad(240.0)] if GameState.map_selected == "Arena_4P.tscn" else [deg_to_rad(45.0), deg_to_rad(225.0)])
    var den_count = 2 if GameState.map_selected in ["Arena_4P.tscn", "Arena_6P.tscn"] else 1
    for i in range(den_count):
        var placed = false
        attempts = 0
        while not placed and attempts < 120:
            attempts += 1
            var candidate = Vector3.ZERO
            if GameState.map_selected == "Arena_6P.tscn":
                var base_ang = den_angles[i] + randf_range(-0.15, 0.15)
                var r = randf_range(58.0, 88.0)
                candidate = Vector3(cos(base_ang) * r, 0.0, sin(base_ang) * r)
            elif GameState.map_selected == "Arena_4P.tscn":
                var base_ang = den_angles[i] + randf_range(-0.18, 0.18)
                var r = randf_range(48.0, 75.0)
                candidate = Vector3(cos(base_ang) * r, 0.0, sin(base_ang) * r)
            else: # 1v1 Arena
                var side_x = -1.0 if i == 0 else 1.0
                candidate = Vector3(side_x * randf_range(40.0, 68.0), 0.0, randf_range(-45.0, 45.0))
                
            if _is_pos_clear(candidate, 4.0, 10.0, 7.5):
                _create_gorilla_den(parent, candidate)
                placed_feature_records.append({"pos": candidate, "radius": 7.5, "type": "gorilla_den"})
                placed = true
        if not placed:
            var fallback = Vector3.ZERO
            if GameState.map_selected == "Arena_6P.tscn":
                var ang = den_angles[i]
                fallback = Vector3(cos(ang) * 70.0, 0.0, sin(ang) * 70.0)
            elif GameState.map_selected == "Arena_4P.tscn":
                var ang = den_angles[i]
                fallback = Vector3(cos(ang) * 58.0, 0.0, sin(ang) * 58.0)
            else:
                var side_x = -1.0 if i == 0 else 1.0
                fallback = Vector3(side_x * 52.0, 0.0, 24.0 if i == 0 else -24.0)
            _create_gorilla_den(parent, fallback)
            placed_feature_records.append({"pos": fallback, "radius": 7.5, "type": "gorilla_den"})

    # 2. Monkey Burrows / Nests (1-2 territorial treehouse burrows with 18-22 Monkeys) - GUARANTEED OFF-PATH PLACEMENT
    var burrow_angles = [deg_to_rad(150.0), deg_to_rad(330.0)] if GameState.map_selected == "Arena_6P.tscn" else ([deg_to_rad(150.0), deg_to_rad(330.0)] if GameState.map_selected == "Arena_4P.tscn" else [deg_to_rad(135.0), deg_to_rad(315.0)])
    var burrow_count = 2 if GameState.map_selected in ["Arena_4P.tscn", "Arena_6P.tscn"] else 1
    for i in range(burrow_count):
        var placed = false
        attempts = 0
        while not placed and attempts < 120:
            attempts += 1
            var candidate = Vector3.ZERO
            if GameState.map_selected == "Arena_6P.tscn":
                var base_ang = burrow_angles[i] + randf_range(-0.15, 0.15)
                var r = randf_range(58.0, 88.0)
                candidate = Vector3(cos(base_ang) * r, 0.0, sin(base_ang) * r)
            elif GameState.map_selected == "Arena_4P.tscn":
                var base_ang = burrow_angles[i] + randf_range(-0.18, 0.18)
                var r = randf_range(48.0, 75.0)
                candidate = Vector3(cos(base_ang) * r, 0.0, sin(base_ang) * r)
            else: # 1v1 Arena
                var side_x = 1.0 if i == 0 else -1.0
                candidate = Vector3(side_x * randf_range(42.0, 70.0), 0.0, randf_range(-45.0, 45.0))
                
            if _is_pos_clear(candidate, 4.0, 10.0, 6.5):
                _create_monkey_burrow(parent, candidate)
                placed_feature_records.append({"pos": candidate, "radius": 6.5, "type": "monkey_burrow"})
                placed = true
        if not placed:
            var fallback = Vector3.ZERO
            if GameState.map_selected == "Arena_6P.tscn":
                var ang = burrow_angles[i]
                fallback = Vector3(cos(ang) * 72.0, 0.0, sin(ang) * 72.0)
            elif GameState.map_selected == "Arena_4P.tscn":
                var ang = burrow_angles[i]
                fallback = Vector3(cos(ang) * 60.0, 0.0, sin(ang) * 60.0)
            else:
                var side_x = 1.0 if i == 0 else -1.0
                fallback = Vector3(side_x * 54.0, 0.0, -28.0 if i == 0 else 28.0)
            _create_monkey_burrow(parent, fallback)
            placed_feature_records.append({"pos": fallback, "radius": 6.5, "type": "monkey_burrow"})

    # 3. Quicksand Sinkholes (10 to 14 off-path sinkholes that slow and drown units in churning mire)
    var sinkhole_count = randi_range(10, 14)
    attempts = 0
    var placed_sinkholes = 0
    while placed_sinkholes < sinkhole_count and attempts < 250:
        attempts += 1
        var candidate = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
        if _is_pos_clear(candidate, 5.0, 12.0, 4.8):
            var sh = sinkhole_script.new()
            sh.name = "QuicksandSinkhole_%d" % placed_sinkholes
            sh.position = candidate
            parent.add_child(sh)
            placed_feature_records.append({"pos": candidate, "radius": 4.8, "type": "sinkhole"})
            placed_sinkholes += 1

    # 4. Dense Jungle Trees (28 to 36 tropical trees off-path, GPU MultiMeshInstance3D Batched)
    var tree_count = randi_range(28, 36)
    attempts = 0
    var placed_trees = 0
    while placed_trees < tree_count and attempts < 320:
        attempts += 1
        var candidate = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
        if _is_pos_clear(candidate, 4.0, 11.0, 3.2):
            _create_procedural_jungle_tree(parent, candidate)
            placed_feature_records.append({"pos": candidate, "radius": 3.2, "type": "jungle_tree"})
            placed_trees += 1

    _flush_jungle_tree_multimeshes(parent)

    # 5. Stealth Jungle Foliage & Fern Brushes (8 to 14 concealment brushes)
    var brush_count = randi_range(8, 14)
    attempts = 0
    var placed_brush = 0
    while placed_brush < brush_count and attempts < 250:
        attempts += 1
        var side = -1.0 if randf() < 0.5 else 1.0
        var candidate = Vector3(side * randf_range(18.0, span * 0.78), 0.0, randf_range(-span * 0.8, span * 0.8))
        if _is_pos_clear(candidate, 3.0, 12.0, 5.5):
            var brush = StealthBrushScript.new()
            brush.position = candidate
            brush.setup_visuals(randf_range(4.5, 6.2))
            parent.add_child(brush)
            placed_feature_records.append({"pos": candidate, "radius": 5.5, "type": "brush"})
            placed_brush += 1

func _create_gorilla_den(parent: Node3D, pos: Vector3):
    var den_body = StaticBody3D.new()
    den_body.name = "GorillaDen_" + str(Time.get_ticks_usec())
    den_body.position = pos
    den_body.add_to_group("Targetable")
    den_body.add_to_group("NeutralStructure")
    den_body.add_to_group("Structure")
    parent.add_child(den_body)
    
    var col = CollisionShape3D.new()
    var col_cyl = CylinderShape3D.new()
    col_cyl.radius = 4.6
    col_cyl.height = 2.4
    col.shape = col_cyl
    col.position.y = 1.2
    den_body.add_child(col)
    
    var hc = HealthComponent.new()
    hc.name = "HealthComponent"
    den_body.add_child(hc)
    hc.set_max_health(750.0)
    
    # 3D Visuals: Bamboo & fern bedding floor
    var bed_floor = MeshInstance3D.new()
    var bf_cyl = CylinderMesh.new()
    bf_cyl.top_radius = 5.8
    bf_cyl.bottom_radius = 6.4
    bf_cyl.height = 0.16
    var bf_mat = StandardMaterial3D.new()
    bf_mat.albedo_color = Color(0.28, 0.38, 0.14) # Lush mossy fern bedding
    bf_mat.roughness = 0.90
    bed_floor.mesh = bf_cyl
    bed_floor.material_override = bf_mat
    bed_floor.position.y = 0.08
    den_body.add_child(bed_floor)
    
    # Giant hollow fallen mossy log / timber archway
    var arch_log = MeshInstance3D.new()
    var alm = CylinderMesh.new()
    alm.top_radius = 0.9
    alm.bottom_radius = 1.15
    alm.height = 5.4
    var log_mat = StandardMaterial3D.new()
    log_mat.albedo_color = Color(0.26, 0.16, 0.09) # Weathered jungle bark
    log_mat.roughness = 0.85
    arch_log.mesh = alm
    arch_log.material_override = log_mat
    arch_log.position = Vector3(0, 1.4, -0.6)
    arch_log.rotation_degrees = Vector3(12.0, 35.0, 82.0)
    den_body.add_child(arch_log)
    
    # Surrounding mossy river boulders
    var rock_mat = StandardMaterial3D.new()
    rock_mat.albedo_color = Color(0.36, 0.32, 0.28)
    rock_mat.roughness = 0.88
    for r in range(7):
        var ang = (TAU / 7.0) * r + randf_range(-0.15, 0.15)
        var rk = MeshInstance3D.new()
        var bm = BoxMesh.new()
        bm.size = Vector3(randf_range(1.2, 1.8), randf_range(0.8, 1.4), randf_range(1.2, 1.8))
        rk.mesh = bm
        rk.material_override = rock_mat
        rk.position = Vector3(cos(ang) * 5.2, 0.55, sin(ang) * 5.2)
        rk.rotation = Vector3(randf() * 0.3, randf() * TAU, randf() * 0.3)
        den_body.add_child(rk)
        
    # Initial Gorilla Troop (8-10 Gorillas)
    var count = randi_range(8, 10)
    for g in range(count):
        var ang = (TAU / float(count)) * g + randf_range(-0.15, 0.15)
        var dist = randf_range(1.6, 4.6)
        var gorilla = TerritorialCreatureScript.new()
        gorilla.configure_creature("Gorilla", pos)
        gorilla.position = pos + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist)
        parent.add_child(gorilla)
        
    # Respawn timer (adds 1 gorilla every 7.5s up to 10 max if den survives)
    var spawn_timer = Timer.new()
    spawn_timer.wait_time = 7.5
    spawn_timer.autostart = true
    spawn_timer.timeout.connect(func():
        if not is_instance_valid(den_body) or hc.is_dead:
            spawn_timer.stop()
            spawn_timer.queue_free()
            return
        var living_gorillas = 0
        for c in parent.get_children():
            if c is CharacterBody3D and c.get("creature_type") == "Gorilla":
                var shc = c.get_node_or_null("HealthComponent")
                if shc and not shc.is_dead and c.get("home_position") != null and c.home_position.distance_to(pos) < 22.0:
                    living_gorillas += 1
        if living_gorillas < 10:
            var ang = randf() * TAU
            var dist = randf_range(1.5, 4.2)
            var new_gorilla = TerritorialCreatureScript.new()
            new_gorilla.configure_creature("Gorilla", pos)
            new_gorilla.position = pos + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist)
            parent.add_child(new_gorilla)
    )
    den_body.add_child(spawn_timer)

func _create_monkey_burrow(parent: Node3D, pos: Vector3):
    var burrow_body = StaticBody3D.new()
    burrow_body.name = "MonkeyBurrow_" + str(Time.get_ticks_usec())
    burrow_body.position = pos
    burrow_body.add_to_group("Targetable")
    burrow_body.add_to_group("NeutralStructure")
    burrow_body.add_to_group("Structure")
    parent.add_child(burrow_body)
    
    var col = CollisionShape3D.new()
    var col_cyl = CylinderShape3D.new()
    col_cyl.radius = 3.8
    col_cyl.height = 2.0
    col.shape = col_cyl
    col.position.y = 1.0
    burrow_body.add_child(col)
    
    var hc = HealthComponent.new()
    hc.name = "HealthComponent"
    burrow_body.add_child(hc)
    hc.set_max_health(550.0)
    
    # 3D Visuals: Raised earthen burrow mound
    var mound = MeshInstance3D.new()
    var mm = CylinderMesh.new()
    mm.top_radius = 2.2
    mm.bottom_radius = 4.2
    mm.height = 1.1
    var mound_mat = StandardMaterial3D.new()
    mound_mat.albedo_color = Color(0.35, 0.24, 0.14) # Rainforest soil
    mound_mat.roughness = 0.92
    mound.mesh = mm
    mound.material_override = mound_mat
    mound.position.y = 0.55
    burrow_body.add_child(mound)
    
    # Woven thatch / palm frond canopy roof
    var roof = MeshInstance3D.new()
    var rm = CylinderMesh.new()
    rm.top_radius = 0.4
    rm.bottom_radius = 2.8
    rm.height = 1.2
    var roof_mat = StandardMaterial3D.new()
    roof_mat.albedo_color = Color(0.44, 0.55, 0.22) # Dried palm thatch & vines
    roof_mat.roughness = 0.85
    roof.mesh = rm
    roof.material_override = roof_mat
    roof.position.y = 1.55
    burrow_body.add_child(roof)
    
    # Small burrow entrance hole
    var hole = MeshInstance3D.new()
    var hm = BoxMesh.new()
    hm.size = Vector3(1.1, 0.8, 1.2)
    var hole_mat = StandardMaterial3D.new()
    hole_mat.albedo_color = Color(0.12, 0.08, 0.05)
    hole.mesh = hm
    hole.material_override = hole_mat
    hole.position = Vector3(0, 0.45, 1.6)
    burrow_body.add_child(hole)
    
    # Initial Monkey Troop (18-22 agile Monkeys)
    var count = randi_range(18, 22)
    for m in range(count):
        var ang = (TAU / float(count)) * m + randf_range(-0.15, 0.15)
        var dist = randf_range(1.5, 4.4)
        var monkey = TerritorialCreatureScript.new()
        monkey.configure_creature("Monkey", pos)
        monkey.position = pos + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist)
        parent.add_child(monkey)
        
    # Respawn timer (adds 1 monkey every 4.0s up to 20 max if burrow survives)
    var spawn_timer = Timer.new()
    spawn_timer.wait_time = 4.0
    spawn_timer.autostart = true
    spawn_timer.timeout.connect(func():
        if not is_instance_valid(burrow_body) or hc.is_dead:
            spawn_timer.stop()
            spawn_timer.queue_free()
            return
        var living_monkeys = 0
        for c in parent.get_children():
            if c is CharacterBody3D and c.get("creature_type") == "Monkey":
                var shc = c.get_node_or_null("HealthComponent")
                if shc and not shc.is_dead and c.get("home_position") != null and c.home_position.distance_to(pos) < 20.0:
                    living_monkeys += 1
        if living_monkeys < 20:
            var ang = randf() * TAU
            var dist = randf_range(1.2, 4.0)
            var new_monkey = TerritorialCreatureScript.new()
            new_monkey.configure_creature("Monkey", pos)
            new_monkey.position = pos + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist)
            parent.add_child(new_monkey)
    )
    burrow_body.add_child(spawn_timer)

func _create_procedural_jungle_tree(parent: Node3D, pos: Vector3):
    var tree_root = StaticBody3D.new()
    tree_root.position = pos
    tree_root.collision_layer = 1
    tree_root.collision_mask = 0
    
    var col = CollisionShape3D.new()
    var cyl = CylinderShape3D.new()
    cyl.radius = 0.65
    cyl.height = 4.2
    col.shape = cyl
    col.position.y = 2.1
    tree_root.add_child(col)
    
    var style = randi() % 3
    var scale_var = randf_range(0.9, 1.35)
    var rot_y = randf() * TAU
    tree_root.scale = Vector3(scale_var, scale_var, scale_var)
    tree_root.rotation.y = rot_y
    parent.add_child(tree_root)
    
    var tree_basis := Basis(Vector3.UP, rot_y).scaled(Vector3(scale_var, scale_var, scale_var))
    var tree_tf := Transform3D(tree_basis, pos)
    var leaf_col := Color(0.12, 0.52, 0.16) if style == 0 else (Color(0.22, 0.62, 0.18) if style == 1 else Color(0.15, 0.44, 0.14))
    
    if style == 0:
        # Giant Tropical Canopy Tree
        var t_basis := Basis.IDENTITY.scaled(Vector3(0.55, 4.2, 0.55))
        _pending_jungle_trunk_tfs.append(tree_tf * Transform3D(t_basis, Vector3(0.0, 2.1, 0.0)))
        
        var c_basis := Basis.IDENTITY.scaled(Vector3(1.2, 0.8, 1.2))
        for f_pos in [Vector3(0, 4.4, 0), Vector3(1.2, 4.2, 0.8), Vector3(-1.1, 4.3, -0.7), Vector3(-0.8, 4.1, 1.2), Vector3(0.9, 4.3, -1.0)]:
            _pending_jungle_crown_tfs.append(tree_tf * Transform3D(c_basis, f_pos))
            _pending_jungle_crown_cols.append(leaf_col)
            
        for v in range(3):
            var ang = float(v) * (TAU / 3.0) + randf_range(-0.2, 0.2)
            var vh = randf_range(2.0, 3.2)
            var v_basis := Basis.IDENTITY.scaled(Vector3(1.0, vh, 1.0))
            _pending_jungle_vine_tfs.append(tree_tf * Transform3D(v_basis, Vector3(cos(ang) * 1.2, 2.5, sin(ang) * 1.2)))
            
    elif style == 1:
        # Jungle Palm Tree
        var p_rot := Basis.from_euler(Vector3(deg_to_rad(6.0), 0.0, deg_to_rad(-4.0))).scaled(Vector3(0.35, 4.8, 0.35))
        _pending_jungle_trunk_tfs.append(tree_tf * Transform3D(p_rot, Vector3(0.25, 2.4, 0.0)))
        
        for p in range(7):
            var p_ang = float(p) * (TAU / 7.0)
            var f_basis := Basis(Vector3.UP, p_ang) * Basis(Vector3.RIGHT, -0.35)
            _pending_jungle_frond_tfs.append(tree_tf * Transform3D(f_basis, Vector3(cos(p_ang) * 1.1 + 0.25, 4.7, sin(p_ang) * 1.1)))
            
        for c_i in range(3):
            var c_ang = float(c_i) * (TAU / 3.0)
            _pending_jungle_coco_tfs.append(tree_tf * Transform3D(Basis.IDENTITY, Vector3(cos(c_ang) * 0.22 + 0.25, 4.45, sin(c_ang) * 0.22)))
            
    else:
        # Buttress Root Banyan Tree with sprawling layered canopy & aerial roots
        var b_basis := Basis.IDENTITY.scaled(Vector3(0.70, 3.8, 0.70))
        _pending_jungle_trunk_tfs.append(tree_tf * Transform3D(b_basis, Vector3(0.0, 1.9, 0.0)))
        
        for b in range(4):
            var b_ang = float(b) * PI * 0.5
            var r_basis := Basis(Vector3.UP, b_ang)
            _pending_jungle_buttress_tfs.append(tree_tf * Transform3D(r_basis, Vector3(cos(b_ang) * 0.8, 0.6, sin(b_ang) * 0.8)))
            var aerial_h := randf_range(2.2, 3.0)
            var a_basis := Basis.IDENTITY.scaled(Vector3(1.4, aerial_h, 1.4))
            _pending_jungle_vine_tfs.append(tree_tf * Transform3D(a_basis, Vector3(cos(b_ang + 0.4) * 1.45, 2.1, sin(b_ang + 0.4) * 1.45)))
            
        var bc_basis := Basis.IDENTITY.scaled(Vector3(1.75, 0.92, 1.75))
        _pending_jungle_crown_tfs.append(tree_tf * Transform3D(bc_basis, Vector3(0.0, 3.8, 0.0)))
        _pending_jungle_crown_cols.append(leaf_col)
        var sub_basis := Basis.IDENTITY.scaled(Vector3(1.15, 0.72, 1.15))
        for b_sub in [Vector3(1.3, 3.5, 0.9), Vector3(-1.3, 3.6, -0.8), Vector3(-0.9, 3.5, 1.2)]:
            _pending_jungle_crown_tfs.append(tree_tf * Transform3D(sub_basis, b_sub))
            _pending_jungle_crown_cols.append(leaf_col.darkened(0.08))

func _flush_jungle_tree_multimeshes(parent: Node3D) -> void:
    var bark_mat := StandardMaterial3D.new()
    bark_mat.albedo_color = Color(0.28, 0.18, 0.10)
    bark_mat.roughness = 0.88

    if _pending_jungle_trunk_tfs.size() > 0:
        var tc := CylinderMesh.new()
        tc.top_radius = 0.75
        tc.bottom_radius = 1.15
        tc.height = 1.0
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = tc
        mm.instance_count = _pending_jungle_trunk_tfs.size()
        for idx in range(_pending_jungle_trunk_tfs.size()):
            mm.set_instance_transform(idx, _pending_jungle_trunk_tfs[idx])
        var mmi := MultiMeshInstance3D.new()
        mmi.name = "JungleTrunksMMI"
        mmi.multimesh = mm
        mmi.material_override = bark_mat
        parent.add_child(mmi)

    if _pending_jungle_crown_tfs.size() > 0:
        var crown_mat := StandardMaterial3D.new()
        crown_mat.vertex_color_use_as_albedo = true
        crown_mat.roughness = 0.72
        var cs := SphereMesh.new()
        cs.radius = 1.6
        cs.height = 2.6
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.use_colors = true
        mm.mesh = cs
        mm.instance_count = _pending_jungle_crown_tfs.size()
        for idx in range(_pending_jungle_crown_tfs.size()):
            mm.set_instance_transform(idx, _pending_jungle_crown_tfs[idx])
            mm.set_instance_color(idx, _pending_jungle_crown_cols[idx])
        var mmi := MultiMeshInstance3D.new()
        mmi.name = "JungleCanopyCrownsMMI"
        mmi.multimesh = mm
        mmi.material_override = crown_mat
        parent.add_child(mmi)

    if _pending_jungle_vine_tfs.size() > 0:
        var vine_mat := StandardMaterial3D.new()
        vine_mat.albedo_color = Color(0.24, 0.38, 0.14)
        var vc := CylinderMesh.new()
        vc.top_radius = 0.04
        vc.bottom_radius = 0.03
        vc.height = 1.0
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = vc
        mm.instance_count = _pending_jungle_vine_tfs.size()
        for idx in range(_pending_jungle_vine_tfs.size()):
            mm.set_instance_transform(idx, _pending_jungle_vine_tfs[idx])
        var mmi := MultiMeshInstance3D.new()
        mmi.name = "JungleVinesMMI"
        mmi.multimesh = mm
        mmi.material_override = vine_mat
        parent.add_child(mmi)

    if _pending_jungle_frond_tfs.size() > 0:
        var frond_mat := StandardMaterial3D.new()
        frond_mat.albedo_color = Color(0.22, 0.62, 0.18)
        frond_mat.roughness = 0.72
        var fm := BoxMesh.new()
        fm.size = Vector3(0.35, 0.08, 2.4)
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = fm
        mm.instance_count = _pending_jungle_frond_tfs.size()
        for idx in range(_pending_jungle_frond_tfs.size()):
            mm.set_instance_transform(idx, _pending_jungle_frond_tfs[idx])
        var mmi := MultiMeshInstance3D.new()
        mmi.name = "JunglePalmFrondsMMI"
        mmi.multimesh = mm
        mmi.material_override = frond_mat
        parent.add_child(mmi)

    if _pending_jungle_coco_tfs.size() > 0:
        var coco_mat := StandardMaterial3D.new()
        coco_mat.albedo_color = Color(0.38, 0.26, 0.14)
        var cs := SphereMesh.new()
        cs.radius = 0.14
        cs.height = 0.24
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = cs
        mm.instance_count = _pending_jungle_coco_tfs.size()
        for idx in range(_pending_jungle_coco_tfs.size()):
            mm.set_instance_transform(idx, _pending_jungle_coco_tfs[idx])
        var mmi := MultiMeshInstance3D.new()
        mmi.name = "JungleCoconutsMMI"
        mmi.multimesh = mm
        mmi.material_override = coco_mat
        parent.add_child(mmi)

    if _pending_jungle_buttress_tfs.size() > 0:
        var rm := BoxMesh.new()
        rm.size = Vector3(0.24, 1.2, 1.2)
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = rm
        mm.instance_count = _pending_jungle_buttress_tfs.size()
        for idx in range(_pending_jungle_buttress_tfs.size()):
            mm.set_instance_transform(idx, _pending_jungle_buttress_tfs[idx])
        var mmi := MultiMeshInstance3D.new()
        mmi.name = "JungleButtressRootsMMI"
        mmi.multimesh = mm
        mmi.material_override = bark_mat
        parent.add_child(mmi)

# =========================================================================
# HAUNTED HALLOW / HALLOWEEN BIOME GENERATION
# Decrepit cracked stone paths, dead twisted forests, The Hanged Man Tree & Breakable Gravestones
# =========================================================================
func _generate_haunted_hallow(parent: Node3D) -> void:
    placed_feature_records.clear()
    var map_size: float = maxf(42.0, GameState.current_map_radius * 0.62)

    var tree_script = load("res://Scripts/HangedManTree.gd")
    var grave_script = load("res://Scripts/BreakableGravestone.gd")

    # 1. Spawn The Hanged Man Tree(s)
    var num_hanged_trees: int = 2 if map_size >= 65.0 else 1
    for i in range(num_hanged_trees):
        var h_pos = _get_clear_hazard_pos(map_size * 0.75)
        if tree_script:
            var h_tree = tree_script.new()
            parent.add_child(h_tree)
            h_tree.global_position = h_pos
            placed_feature_records.append({
                "type": "tree",
                "pos": h_pos,
                "radius": 5.0
            })

    # 2. Spawn Breakable Gravestones in Graveyard Clusters
    var num_graves: int = int(clampf(map_size * 0.28, 10.0, 24.0))
    for i in range(num_graves):
        var g_pos = _get_clear_hazard_pos(map_size * 0.85)
        if grave_script:
            var grave = grave_script.new()
            parent.add_child(grave)
            grave.global_position = g_pos
            placed_feature_records.append({
                "type": "obstacle",
                "pos": g_pos,
                "radius": 1.6
            })

    # 3. Spawn Twisted Dead Forest Trees
    var dead_tree_count: int = int(clampf(map_size * 0.45, 18.0, 40.0))
    var bark_mat = StandardMaterial3D.new()
    bark_mat.albedo_color = Color(0.12, 0.10, 0.10) # Charcoal black dead bark
    bark_mat.roughness = 0.95

    for i in range(dead_tree_count):
        var t_pos = _get_clear_hazard_pos(map_size * 0.90)
        var tree_node = Node3D.new()
        tree_node.position = t_pos
        parent.add_child(tree_node)

        # Trunk
        var trunk = MeshInstance3D.new()
        var t_cyl = CylinderMesh.new()
        t_cyl.top_radius = randf_range(0.25, 0.40)
        t_cyl.bottom_radius = randf_range(0.60, 0.95)
        t_cyl.height = randf_range(3.2, 5.0)
        trunk.mesh = t_cyl
        trunk.material_override = bark_mat
        trunk.position.y = t_cyl.height * 0.5
        trunk.rotation.z = randf_range(-0.15, 0.15)
        tree_node.add_child(trunk)

        # 2-3 Crooked Bare Branches
        for b_idx in range(randi_range(2, 4)):
            var branch = MeshInstance3D.new()
            var b_cyl = CylinderMesh.new()
            b_cyl.top_radius = 0.08
            b_cyl.bottom_radius = 0.22
            b_cyl.height = randf_range(1.8, 3.2)
            branch.mesh = b_cyl
            branch.material_override = bark_mat
            branch.position = Vector3(randf_range(-0.3, 0.3), t_cyl.height * randf_range(0.6, 0.9), randf_range(-0.3, 0.3))
            branch.rotation = Vector3(randf_range(-0.8, 0.8), randf_range(0, TAU), randf_range(-0.8, 0.8))
            tree_node.add_child(branch)

        placed_feature_records.append({
            "type": "tree",
            "pos": t_pos,
            "radius": 2.2
        })

# =========================================================================
# FROZEN WONDERLAND / YULETIDE BIOME GENERATION
# Frosted paths, Evergreen Yuletide Trees with glowing fairy lights,
# Breakable Holiday Presents, Alpine Pine Forests & Slippery Ice
# =========================================================================
func _generate_frozen_wonderland(parent: Node3D) -> void:
    placed_feature_records.clear()
    var map_size: float = maxf(42.0, GameState.current_map_radius * 0.62)

    var tree_script = load("res://Scripts/EvergreenYuletideTree.gd")
    var present_script = load("res://Scripts/BreakableHolidayPresent.gd")
    var ice_patch_script = load("res://Scripts/BreakableIcePatch.gd")

    # 1. Spawn Majestic Evergreen Yuletide Tree(s)
    var num_yule_trees: int = 2 if map_size >= 65.0 else 1
    for i in range(num_yule_trees):
        var yt_pos = _get_clear_hazard_pos(map_size * 0.70)
        if tree_script:
            var y_tree = tree_script.new()
            parent.add_child(y_tree)
            y_tree.global_position = yt_pos
            placed_feature_records.append({
                "type": "tree",
                "pos": yt_pos,
                "radius": 4.5
            })
            # Place 2-3 holiday presents right under the majestic tree!
            for p_i in range(randi_range(2, 3)):
                if present_script:
                    var present = present_script.new()
                    parent.add_child(present)
                    var p_offset = Vector3(randf_range(-2.4, 2.4), 0, randf_range(-2.4, 2.4))
                    if p_offset.length() < 1.0: p_offset = p_offset.normalized() * 1.5
                    present.global_position = yt_pos + p_offset
                    placed_feature_records.append({
                        "type": "obstacle",
                        "pos": present.global_position,
                        "radius": 1.2
                    })

    # 2. Spawn Breakable Holiday Presents Scattered Across Snow
    var num_presents: int = int(clampf(map_size * 0.25, 8.0, 20.0))
    for i in range(num_presents):
        var p_pos = _get_clear_hazard_pos(map_size * 0.85)
        if present_script:
            var present = present_script.new()
            parent.add_child(present)
            present.global_position = p_pos
            placed_feature_records.append({
                "type": "obstacle",
                "pos": p_pos,
                "radius": 1.2
            })

    # 3. Spawn Slippery Ice Patches
    var num_ice_patches: int = int(clampf(map_size * 0.12, 3.0, 7.0))
    for i in range(num_ice_patches):
        var ip_pos = _get_clear_hazard_pos(map_size * 0.80)
        if ice_patch_script:
            var ip = ice_patch_script.new()
            ip.patch_size = "SMALL" if randf() < 0.6 else "LARGE"
            parent.add_child(ip)
            ip.global_position = ip_pos
            placed_feature_records.append({
                "type": "ice_patch",
                "pos": ip_pos,
                "radius": 5.0 if ip.patch_size == "LARGE" else 3.2
            })

    # 4. Spawn Alpine Snow-Covered Pine Trees
    var pine_count: int = int(clampf(map_size * 0.40, 16.0, 36.0))
    var bark_mat = StandardMaterial3D.new()
    bark_mat.albedo_color = Color(0.24, 0.16, 0.10)
    bark_mat.roughness = 0.90

    var pine_green = StandardMaterial3D.new()
    pine_green.albedo_color = Color(0.12, 0.32, 0.18)
    pine_green.roughness = 0.80

    var snow_mat = StandardMaterial3D.new()
    snow_mat.albedo_color = Color(0.92, 0.96, 1.0)
    snow_mat.roughness = 0.60

    for i in range(pine_count):
        var t_pos = _get_clear_hazard_pos(map_size * 0.90)
        var tree_node = Node3D.new()
        tree_node.position = t_pos
        parent.add_child(tree_node)

        # Trunk
        var trunk = MeshInstance3D.new()
        var t_cyl = CylinderMesh.new()
        t_cyl.top_radius = 0.22
        t_cyl.bottom_radius = 0.55
        t_cyl.height = 3.6
        trunk.mesh = t_cyl
        trunk.material_override = bark_mat
        trunk.position.y = 1.8
        tree_node.add_child(trunk)

        # Conical Pine Canopy Tiers with Snow Caps
        for tier in range(3):
            var tier_rad = 2.2 - (tier * 0.55)
            var tier_h = 2.0 - (tier * 0.3)
            var tier_y = 2.6 + (tier * 1.3)

            var pine_mesh = MeshInstance3D.new()
            var p_cone = CylinderMesh.new()
            p_cone.top_radius = 0.05
            p_cone.bottom_radius = tier_rad
            p_cone.height = tier_h
            pine_mesh.mesh = p_cone
            pine_mesh.material_override = pine_green
            pine_mesh.position.y = tier_y
            tree_node.add_child(pine_mesh)

            var snow_mesh = MeshInstance3D.new()
            var s_cone = CylinderMesh.new()
            s_cone.top_radius = 0.06
            s_cone.bottom_radius = tier_rad * 0.95
            s_cone.height = tier_h * 0.4
            snow_mesh.mesh = s_cone
            snow_mesh.material_override = snow_mat
            snow_mesh.position.y = tier_y + tier_h * 0.28
            tree_node.add_child(snow_mesh)

        placed_feature_records.append({
            "type": "tree",
            "pos": t_pos,
            "radius": 2.2
        })



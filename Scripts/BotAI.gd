extends Node
class_name BotAI

@export var max_requisition: float = 100.0
var current_requisition: float = 0.0
var requisition_rate: float = 0.5

var deck: Array = []
var hand: Array = []
var discard: Array = []

var think_timer: float = 0.0
var think_interval: float = 1.0
var active_commander: Node3D = null

@export var my_team: String = "SideB"
@export var enemy_team: String = "SideA"
@export var difficulty: String = "MEDIUM"
@export var archetype: String = "" # "Dominion", "The Reach", "Pirates", "Rimworlders", "Void", "Plague of Harmony", "Gilded Harmony", "Planetary Primitives", "Chaos"
var slot_index: int = 0

var profile: String = ""

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
	var gs = _get_game_state()
	var ai_pool = ["Dominion", "The Reach", "Pirates", "Rimworlders", "Void", "Plague of Harmony", "Gilded Harmony", "Planetary Primitives", "Galactic Wildlife", "Chaos"]
	if archetype != "":
		deck = generate_themed_deck(archetype)
		print(my_team + " BotAI generated deck for archetype: " + archetype + " -> " + str(deck))
	elif profile != "" and gs and gs.player_decks.has(profile) and gs.player_decks[profile].size() > 0:
		deck = gs.player_decks[profile].duplicate()
		archetype = _detect_faction_from_deck(deck)
		print(my_team + " BotAI initialized with deck from profile: " + profile + " (Archetype: " + archetype + ")")
	else:
		archetype = ai_pool[randi() % ai_pool.size()]
		deck = generate_themed_deck(archetype)
		print(my_team + " BotAI generated deck for archetype: " + archetype + " -> " + str(deck))
		
	deck.shuffle()
	# Draw starting hand of 3 cards (identical to player hand in HandContainer)
	draw_to_hand()
	draw_to_hand()
	draw_to_hand()

func _process(delta):
	if not is_inside_tree() or not get_tree():
		return
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			return # Let the server authority handle AI thinking in online matches!

	# Unified Requisition (Energy) generation: base rate + tower catchup bonus
	var bot_towers = 0
	for z in get_tree().get_nodes_in_group(my_team):
		if "Tower" in z.name:
			var zhc = z.get_node_or_null("HealthComponent")
			if zhc and zhc.is_dead:
				continue
			bot_towers += 1
	var am = (get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent())
	var initial = 2
	if am and am.get("initial_towers_per_team"):
		initial = am.initial_towers_per_team.get(my_team, 2)
		
	var gs = _get_game_state()
	var dynamic_rate = requisition_rate + ((initial - bot_towers) * (1.0 / max(1.0, float(initial))))
	if gs:
		dynamic_rate *= gs.get_team_energy_multiplier(my_team)
	if am and am.get("sudden_death_active"):
		dynamic_rate *= 0.5
	dynamic_rate = max(0.2, dynamic_rate)
	if current_requisition < max_requisition:
		current_requisition += dynamic_rate * delta
		if current_requisition > max_requisition:
			current_requisition = max_requisition
			
	# Dynamically accelerate thinking during Sudden Death or Heavy Defense
	var active_interval = think_interval
	var am_scene = (get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent())
	if am_scene and am_scene.get("sudden_death_active"):
		active_interval = min(active_interval, 0.55)
		
	think_timer += delta
	if think_timer >= active_interval:
		think_timer = 0.0
		evaluate_moves()

func draw_to_hand():
	if hand.size() >= 3:
		return
	if deck.is_empty():
		deck = discard.duplicate()
		discard.clear()
		deck.shuffle()
	
	if not deck.is_empty():
		var card_name = deck.pop_front()
		var data = load("res://Data/Cards/" + card_name + ".tres")
		if data:
			hand.append(data)

func _get_card_faction(card: CardData) -> String:
	if card == null:
		return "Dominion"
	var cname: String = card.card_name
	if "Wildlife" in cname:
		return "Galactic Wildlife"
	elif "Primitive" in cname:
		return "Planetary Primitives"
	elif "Plague" in cname:
		return "Plague of Harmony"
	elif "Gilded" in cname:
		return "Gilded Harmony"
	elif "Void" in cname:
		return "Void"
	elif "Rimworlder" in cname or "Sky" in cname or "Stone" in cname or "Giant" in cname or "Great" in cname or "Beast" in cname or "Monstrous" in cname:
		return "Rimworlders"
	elif "Scrap" in cname:
		return "Pirates"
	elif "Reach" in cname:
		return "The Reach"
	return "Dominion"

func _assess_team_context() -> Dictionary:
	var gs = _get_game_state()
	var my_team_players: int = 0
	if gs:
		for s_team in gs.slot_teams:
			if s_team == my_team:
				my_team_players += 1
	if my_team_players <= 0:
		my_team_players = 1

	var total_players: int = maxi(2, gs.match_player_count if gs else 2)
	var active_teams: int = maxi(2, gs.active_match_teams.size() if gs else 2)
	var energy_mult: float = gs.get_team_energy_multiplier(my_team) if gs else 1.0
	var is_asym_map: bool = gs.map_layout_id.begins_with("ASYM_") if gs else false
	var is_outnumbered_boss: bool = is_asym_map and (my_team_players * 2 < total_players) and energy_mult >= 0.99
	var is_coalition_swarm: bool = energy_mult < 0.92 or (is_asym_map and my_team_players * 2 > total_players)
	var is_ffa: bool = (gs.is_ffa_mode() if gs else false) or active_teams >= 4

	return {
		"my_team_players": my_team_players,
		"total_players": total_players,
		"active_teams": active_teams,
		"energy_mult": energy_mult,
		"is_asym_map": is_asym_map,
		"is_outnumbered_boss": is_outnumbered_boss,
		"is_coalition_swarm": is_coalition_swarm,
		"is_ffa": is_ffa
	}

func assess_threats() -> Dictionary:
	var gs = _get_game_state()
	var am = (get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent())
	var is_sudden_death: bool = am.get("sudden_death_active") if am and "sudden_death_active" in am else false
	
	var my_structures = []
	var my_base: Node3D = null
	for s in get_tree().get_nodes_in_group(my_team):
		if not is_instance_valid(s): continue
		if "Base" in s.name or "Tower" in s.name or "CommandBay" in s.name:
			my_structures.append(s)
			if "Base" in s.name and (my_base == null or s.name == "Base_" + str(slot_index)):
				my_base = s
				
	var all_hostiles = []
	var high_value_hostiles = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if node != null and is_instance_valid(node) and not node.is_in_group(my_team):
			var hc = node.get_node_or_null("HealthComponent")
			if hc and hc.is_dead: continue
			
			# Check stealth brush visibility:
			# If target is stealthed in tall grass, AI cannot target it unless an ally is within 4.5m
			if gs and gs.is_unit_stealthed_from(node, null):
				var spotted = false
				for ally in get_tree().get_nodes_in_group(my_team):
					if is_instance_valid(ally) and ally is Node3D:
						if ally.global_position.distance_squared_to(node.global_position) <= 20.25:
							spotted = true
							break
				if not spotted:
					continue # Hidden in grass from bot!
					
			# Check territorial neutral creatures (scorpions & swarm ants)
			if node.is_in_group("NeutralCreature"):
				var max_neutral_dist_sq = 100.0 if difficulty == "HARD" else (256.0 if difficulty == "MEDIUM" else 484.0)
				var threatening_structure = false
				for s in my_structures:
					if s.global_position.distance_squared_to(node.global_position) <= max_neutral_dist_sq:
						threatening_structure = true
						break
				if not threatening_structure:
					continue # Ignore neutral creatures outside of dangerous proximity
					
			all_hostiles.append(node)
			if hc and hc.max_health >= 220.0 and not ("Base" in node.name or "Tower" in node.name) and not node.is_in_group("CommanderUnit"):
				high_value_hostiles.append(node)
			
	var endangered_structure: Node3D = null
	var highest_threat_score: float = 0.0
	var closest_hostile: Node3D = null
	var hostiles_near_endangered: Array = []
	
	for s in my_structures:
		var threat_score = 0.0
		var s_health = s.get_node_or_null("HealthComponent")
		var health_pct = 1.0
		if s_health:
			health_pct = s_health.current_health / max(1.0, s_health.max_health)
			
		var is_base = "Base" in s.name
		var is_my_slot_struct = s.name.begins_with("Base_" + str(slot_index)) or s.name.begins_with("Tower_" + str(slot_index) + "_")
		var base_mult = 3.5 if is_base else 1.2
		if is_my_slot_struct:
			base_mult *= 1.25
		
		# If damaged, significantly increase threat
		if health_pct < 0.98:
			threat_score += (1.0 - health_pct) * 60.0 * base_mult
			
		var close_hostiles = []
		for h in all_hostiles:
			var d = s.global_position.distance_to(h.global_position)
			if d <= 26.0:
				close_hostiles.append(h)
				var prox_factor = (26.0 - d) / 26.0
				var is_beast = h.is_in_group("Beast")
				var beast_mult = 1.0
				if is_beast and is_sudden_death:
					if difficulty == "HARD": beast_mult = 2.4
					elif difficulty == "MEDIUM": beast_mult = 1.6
					else: beast_mult = 1.1
				threat_score += (18.0 * prox_factor * beast_mult) * base_mult
				
		if threat_score > highest_threat_score and not close_hostiles.is_empty():
			highest_threat_score = threat_score
			endangered_structure = s
			hostiles_near_endangered = close_hostiles
			var min_d = 9999.0
			for ch in close_hostiles:
				var cd = s.global_position.distance_to(ch.global_position)
				if cd < min_d:
					min_d = cd
					closest_hostile = ch
					
	return {
		"is_sudden_death": is_sudden_death,
		"threat_score": highest_threat_score,
		"endangered_structure": endangered_structure,
		"closest_hostile": closest_hostile,
		"hostiles_near_endangered": hostiles_near_endangered,
		"high_value_hostiles": high_value_hostiles,
		"my_base": my_base,
		"structures": my_structures
	}

var push_lane_toggle: bool = false

func evaluate_moves():
	var gs = _get_game_state()
	var threat_info = assess_threats()
	var team_ctx = _assess_team_context()
	
	var has_commander = false
	var mobile_unit_count = 0
	var friendly_screens = 0
	var friendly_damaged_vehicles = 0
	var my_units = get_tree().get_nodes_in_group(my_team)
	for u in my_units:
		if not is_instance_valid(u): continue
		if u.is_in_group("CommanderUnit") or "Commander" in u.name or "Overlord" in u.name or "GreatBeastSpeaker" in u.name or "EyeOfHarmony" in u.name or "GildedCommander" in u.name:
			var uhc_cmd = u.get_node_or_null("HealthComponent")
			if uhc_cmd == null or not uhc_cmd.is_dead:
				has_commander = true
		if not ("Base" in u.name or "Tower" in u.name or "CommandBay" in u.name):
			mobile_unit_count += 1
			var uhc = u.get_node_or_null("HealthComponent")
			if uhc and not uhc.is_dead:
				if uhc.max_health >= 180.0 or "Melee" in u.name or "Tank" in u.name or "Mech" in u.name or "Leviathan" in u.name:
					friendly_screens += 1
				if ("Tank" in u.name or "Mech" in u.name or "Walker" in u.name) and uhc.current_health < uhc.max_health * 0.85:
					friendly_damaged_vehicles += 1

	var active_team_count: int = maxi(2, gs.active_match_teams.size() if gs else 2)
	var max_team_units: int = clampi(int(135.0 / float(active_team_count)), 12, 55)
	if (gs.match_player_count if gs else 2) <= 4 and active_team_count <= 2:
		max_team_units = 45

	var valid_hand = []
	for c in hand:
		if c.card_type == "Commander" and has_commander:
			continue
		if not c.is_spell and mobile_unit_count >= max_team_units:
			continue
		valid_hand.append(c)
		
	if valid_hand.is_empty():
		return

	# Calculate banking modifier based on team size, FFA caution, and asymmetric energy multiplier
	var bank_scale: float = 1.0
	if team_ctx.get("is_coalition_swarm", false):
		# Energy-penalized larger team: don't sit waiting for huge banks, deploy cost-efficient waves sooner
		bank_scale = 0.78
	elif team_ctx.get("is_outnumbered_boss", false):
		# High-energy boss side: deploy assertive multi-unit waves
		bank_scale = 0.90
	if team_ctx.get("is_ffa", false):
		# In 3P-25P Free-For-All, keep a slight defensive reserve unless threatened
		bank_scale *= 1.12
	if gs and gs.is_koth_mode():
		# Contest the Hill early!
		bank_scale *= 0.85

	# If Commander died, prioritize deploying Commander from hand to lead the army
	if not has_commander:
		var has_commander_card = false
		for cc in valid_hand:
			if cc.card_type == "Commander" or "Commander" in cc.card_name or "Overlord" in cc.card_name or "GreatBeastSpeaker" in cc.card_name or "EyeOfHarmony" in cc.card_name:
				has_commander_card = true
				break
		if has_commander_card:
			valid_hand.sort_custom(func(a, b):
				var a_cmd = a.card_type == "Commander" or "Commander" in a.card_name or "Overlord" in a.card_name or "GreatBeastSpeaker" in a.card_name or "EyeOfHarmony" in a.card_name
				var b_cmd = b.card_type == "Commander" or "Commander" in b.card_name or "Overlord" in b.card_name or "GreatBeastSpeaker" in b.card_name or "EyeOfHarmony" in b.card_name
				if a_cmd != b_cmd:
					return a_cmd
				return a.cost > b.cost
			)

	# In emergency defense mode, prioritize spells, infectors (against heavy targets), and immediate affordable units!
	if threat_info.threat_score > 20.0:
		valid_hand.sort_custom(func(a, b):
			if a.is_spell and not b.is_spell: return true
			if not a.is_spell and b.is_spell: return false
			var a_afford = current_requisition >= a.cost
			var b_afford = current_requisition >= b.cost
			if a_afford and not b_afford: return true
			if not a_afford and b_afford: return false
			return a.cost > b.cost
		)
	else:
		# Faction & Mixed ("Chaos") strategic tempo and card ordering:
		if archetype == "Void":
			# Void Swarm attacks relentlessly at low energy (2.5+)
			if current_requisition < (2.5 * bank_scale) and threat_info.threat_score < 8.0:
				return
			valid_hand.sort_custom(func(a, b):
				# In KotH or multi-lane maps, prioritize Crawlers/Spikers/Gargoyles to flood lanes
				if a.is_spell != b.is_spell:
					return not a.is_spell
				return a.cost < b.cost
			)
		elif archetype == "The Reach":
			# The Reach banks to deploy 2+ cybernetic units together for the +15% to +75% network synergy
			var reach_bank = 5.5 * bank_scale if difficulty == "HARD" else 4.2 * bank_scale
			if threat_info.threat_score < 10.0 and current_requisition < reach_bank:
				return
			valid_hand.sort_custom(func(a, b):
				# Deploy ReachTank / ReachMech / ReachShieldInfantry / Commander anchor first, then Trooper/Ranged/Support cluster
				var a_anchor = "Tank" in a.card_name or "Mech" in a.card_name or "Shield" in a.card_name or a.card_type == "Commander"
				var b_anchor = "Tank" in b.card_name or "Mech" in b.card_name or "Shield" in b.card_name or b.card_type == "Commander"
				if a_anchor != b_anchor:
					return a_anchor
				return a.cost > b.cost
			)
		elif archetype == "Pirates":
			# Pirates love sudden 2-card salvage pushes (ScrapTank / ScrapMech / ScrapArmoredInfantry vanguard + ScrapRepair)
			var pirate_bank = 5.5 * bank_scale if difficulty == "HARD" else 4.0 * bank_scale
			if threat_info.threat_score < 10.0 and current_requisition < pirate_bank:
				return
			valid_hand.sort_custom(func(a, b):
				if friendly_damaged_vehicles > 0:
					if "Repair" in a.card_name and not "Repair" in b.card_name: return true
					if not "Repair" in a.card_name and "Repair" in b.card_name: return false
				var a_vanguard = "ScrapTank" in a.card_name or "ScrapMech" in a.card_name or "ScrapArmored" in a.card_name
				var b_vanguard = "ScrapTank" in b.card_name or "ScrapMech" in b.card_name or "ScrapArmored" in b.card_name
				if a_vanguard != b_vanguard:
					return a_vanguard
				return a.cost > b.cost
			)
		elif archetype == "Rimworlders":
			# Rimworlders lead with Leviathan/Monstrous/Octopus sponges, then GreatBeastSpeaker for +20% Beast Aura
			var rim_bank = 5.0 * bank_scale if difficulty == "HARD" else 3.8 * bank_scale
			if threat_info.threat_score < 10.0 and current_requisition < rim_bank:
				return
			valid_hand.sort_custom(func(a, b):
				if friendly_screens >= 2:
					if "GreatBeastSpeaker" in a.card_name and not "GreatBeastSpeaker" in b.card_name: return true
					if not "GreatBeastSpeaker" in a.card_name and "GreatBeastSpeaker" in b.card_name: return false
				var a_is_beast = "Leviathan" in a.card_name or "Monstrous" in a.card_name or "Octopus" in a.card_name or "Squid" in a.card_name or "Mutant" in a.card_name or "Beetle" in a.card_name
				var b_is_beast = "Leviathan" in b.card_name or "Monstrous" in b.card_name or "Octopus" in b.card_name or "Squid" in b.card_name or "Mutant" in b.card_name or "Beetle" in b.card_name
				if a_is_beast and not b_is_beast: return true
				if not a_is_beast and b_is_beast: return false
				return a.cost > b.cost
			)
		elif archetype == "Dominion":
			# Dominion establishes forward CommandBay, then HeavyTank/DominionShieldTank/DominionMech + RepairMan/Medic/Sniper
			var dom_bank = 5.8 * bank_scale if difficulty == "HARD" else 4.2 * bank_scale
			if threat_info.threat_score < 10.0 and current_requisition < dom_bank:
				return
			valid_hand.sort_custom(func(a, b):
				if "CommandBay" in a.card_name and not "CommandBay" in b.card_name: return true
				if not "CommandBay" in a.card_name and "CommandBay" in b.card_name: return false
				if friendly_damaged_vehicles > 0:
					if "Repair" in a.card_name and not "Repair" in b.card_name: return true
					if not "Repair" in a.card_name and "Repair" in b.card_name: return false
				return a.cost > b.cost
			)
		elif archetype == "Plague of Harmony":
			# Plague of Harmony deploys Eye Creatures, Armored Tanks & Husks first as a screen, and uses Infector when screens or high-value enemy targets exist
			var plague_bank = 5.0 * bank_scale if difficulty == "HARD" else 3.8 * bank_scale
			if threat_info.threat_score < 10.0 and current_requisition < plague_bank:
				return
			var has_hv_target: bool = threat_info["high_value_hostiles"].size() > 0
			valid_hand.sort_custom(func(a, b):
				if (has_hv_target or friendly_screens >= 1):
					if "Infector" in a.card_name and not "Infector" in b.card_name: return true
					if not "Infector" in a.card_name and "Infector" in b.card_name: return false
				var a_screen = "MeleeEye" in a.card_name or "EnlightenedMelee" in a.card_name or "PlagueArmored" in a.card_name or "PlagueCommander" in a.card_name or "EyeOfHarmony" in a.card_name
				var b_screen = "MeleeEye" in b.card_name or "EnlightenedMelee" in b.card_name or "PlagueArmored" in b.card_name or "PlagueCommander" in b.card_name or "EyeOfHarmony" in b.card_name
				if a_screen != b_screen:
					return a_screen
				return a.cost > b.cost
			)
		elif archetype == "Gilded Harmony":
			# Gilded Harmony banks for The Saved Horde (11 cost) when safe, or deploys dividing Genetic Monsters + GildedShieldTank + GildedInfector
			var has_saved_horde = false
			for hc_card in valid_hand:
				if "SavedHorde" in hc_card.card_name:
					has_saved_horde = true
					break
			if has_saved_horde and threat_info.threat_score < 14.0 and current_requisition < 11.0 and current_requisition >= (6.0 * bank_scale):
				return # Save up for the 6-unit Saved Horde!
			var gilded_bank = 5.0 * bank_scale if difficulty == "HARD" else 3.8 * bank_scale
			if threat_info.threat_score < 10.0 and current_requisition < gilded_bank:
				return
			valid_hand.sort_custom(func(a, b):
				if "SavedHorde" in a.card_name and current_requisition >= 11.0: return true
				if "SavedHorde" in b.card_name and current_requisition >= 11.0: return false
				var a_mitosis = "Genetic" in a.card_name or "GildedShield" in a.card_name
				var b_mitosis = "Genetic" in b.card_name or "GildedShield" in b.card_name
				if a_mitosis != b_mitosis:
					return a_mitosis
				return a.cost > b.cost
			)
		elif archetype == "Planetary Primitives":
			# Planetary Primitives: aggressive low-cost tempo, deploys PrimitiveWoodTower & Builders early, then infantry swarms backed by Knights & Crossbowmen
			var prim_bank = 2.5 * bank_scale
			if threat_info.threat_score < 8.0 and current_requisition < prim_bank:
				return
			valid_hand.sort_custom(func(a, b):
				var a_prio = 0
				var b_prio = 0
				if "WoodTower" in a.card_name or "Builder" in a.card_name: a_prio += 25
				elif a.card_type == "Commander": a_prio += 20
				elif "Knight" in a.card_name: a_prio += 18
				elif "Crossbowman" in a.card_name or "ShortBow" in a.card_name: a_prio += 15
				elif "Clubber" in a.card_name or "Spearman" in a.card_name or "Squire" in a.card_name: a_prio += 12
				
				if "WoodTower" in b.card_name or "Builder" in b.card_name: b_prio += 25
				elif b.card_type == "Commander": b_prio += 20
				elif "Knight" in b.card_name: b_prio += 18
				elif "Crossbowman" in b.card_name or "ShortBow" in b.card_name: b_prio += 15
				elif "Clubber" in b.card_name or "Spearman" in b.card_name or "Squire" in b.card_name: b_prio += 12
				
				if a_prio != b_prio:
					return a_prio > b_prio
				return a.cost < b.cost # Prefer quick cheap deployments
			)
		elif archetype == "Galactic Wildlife":
			# Galactic Wildlife: nature's primal swarm, apex predators, and aerial harassment
			var wild_bank = 3.2 * bank_scale
			if threat_info.threat_score < 8.0 and current_requisition < wild_bank:
				return
			valid_hand.sort_custom(func(a, b):
				var a_prio = 0
				var b_prio = 0
				if a.card_type == "Commander": a_prio += 30
				elif "Mammoth" in a.card_name or "Megalodon" in a.card_name or "Croc" in a.card_name or "Grizzly" in a.card_name or "Gorilla" in a.card_name or "Elephant" in a.card_name or "Hippo" in a.card_name or "Rhino" in a.card_name:
					a_prio += 24 # Apex frontline vanguard
				elif "Eagle" in a.card_name or "Condor" in a.card_name or "Raven" in a.card_name or "Owl" in a.card_name or "Hornet" in a.card_name or "Bat" in a.card_name:
					a_prio += 20 # Aerial harassment along flanks
				elif "Archerfish" in a.card_name or "PistolShrimp" in a.card_name or "Bombardier" in a.card_name or "SpittingCobra" in a.card_name or "Monkey" in a.card_name:
					a_prio += (18 if friendly_screens >= 1 else 10) # Ranged artillery/spitters behind screens
				elif "Snake" in a.card_name or "Scorpion" in a.card_name or "Spider" in a.card_name or "Centipede" in a.card_name:
					a_prio += 15 # Venomous skirmishers
				else:
					a_prio += 12 # Swarm pack

				if b.card_type == "Commander": b_prio += 30
				elif "Mammoth" in b.card_name or "Megalodon" in b.card_name or "Croc" in b.card_name or "Grizzly" in b.card_name or "Gorilla" in b.card_name or "Elephant" in b.card_name or "Hippo" in b.card_name or "Rhino" in b.card_name:
					b_prio += 24
				elif "Eagle" in b.card_name or "Condor" in b.card_name or "Raven" in b.card_name or "Owl" in b.card_name or "Hornet" in b.card_name or "Bat" in b.card_name:
					b_prio += 20
				elif "Archerfish" in b.card_name or "PistolShrimp" in b.card_name or "Bombardier" in b.card_name or "SpittingCobra" in b.card_name or "Monkey" in b.card_name:
					b_prio += (18 if friendly_screens >= 1 else 10)
				elif "Snake" in b.card_name or "Scorpion" in b.card_name or "Spider" in b.card_name or "Centipede" in b.card_name:
					b_prio += 15
				else:
					b_prio += 12

				if a_prio != b_prio:
					return a_prio > b_prio
				return a.cost < b.cost
			)
		else:
			# "Chaos" (Mixed Faction) or Custom Hybrid Deck:
			# Dynamically adapts to cross-faction cards in hand!
			var has_saved_horde_chaos = false
			var min_cost: float = 99.0
			for hc_card in valid_hand:
				if "SavedHorde" in hc_card.card_name:
					has_saved_horde_chaos = true
				if hc_card.cost < min_cost:
					min_cost = hc_card.cost
			if has_saved_horde_chaos and threat_info.threat_score < 13.0 and current_requisition < 11.0 and current_requisition >= 6.8:
				return
			var chaos_bank: float = clampf((min_cost + 1.5) * bank_scale, 3.0, 6.0)
			if difficulty == "EASY":
				chaos_bank = minf(chaos_bank, 3.5)
			if threat_info.threat_score < 9.0 and current_requisition < chaos_bank:
				return
			valid_hand.sort_custom(func(a, b):
				# Cross-faction synergy ordering:
				# 1. If we already have frontline screens or a high-value enemy is near, deploy Infector/Support/Repair/Aura
				if friendly_damaged_vehicles > 0:
					if "Repair" in a.card_name and not "Repair" in b.card_name: return true
					if not "Repair" in a.card_name and "Repair" in b.card_name: return false
				if friendly_screens >= 1:
					var a_syn = "Infector" in a.card_name or "Medic" in a.card_name or "Support" in a.card_name or "GreatBeastSpeaker" in a.card_name
					var b_syn = "Infector" in b.card_name or "Medic" in b.card_name or "Support" in b.card_name or "GreatBeastSpeaker" in b.card_name
					if a_syn != b_syn:
						return a_syn
				else:
					# No frontline screen yet -> deploy Tank/Mech/Leviathan/Genetic/Eye frontline first!
					var a_front = a.is_melee or a.card_type == "Vehicle" or "Tank" in a.card_name or "Mech" in a.card_name or "Leviathan" in a.card_name or "Genetic" in a.card_name
					var b_front = b.is_melee or b.card_type == "Vehicle" or "Tank" in b.card_name or "Mech" in b.card_name or "Leviathan" in b.card_name or "Genetic" in b.card_name
					if a_front != b_front:
						return a_front
				return a.cost > b.cost
			)
	
	for c in valid_hand:
		if current_requisition >= c.cost:
			var spawn_pos = calculate_optimal_spawn(c, threat_info, team_ctx)
			if spawn_pos != null:
				play_card(c, spawn_pos)
				# If under heavy attack or executing a 2-card synergy push, allow immediate follow-up card!
				if (threat_info.threat_score > 22.0 or archetype in ["The Reach", "Pirates", "Void", "Chaos"]) and current_requisition >= 3.0:
					continue
				if current_requisition < 15.0:
					break

func _compute_strategic_objective_and_lane(spawn_anchor: Node3D, team_ctx: Dictionary) -> Dictionary:
	var gs = _get_game_state()
	var anchor_pos: Vector3 = spawn_anchor.global_position
	var objective_pos: Vector3 = Vector3.ZERO
	var found_objective: bool = false
	var am = (get_tree().current_scene if get_tree().current_scene else get_parent())

	# 1. King of the Hill (Team KotH or FFA KotH): prioritize contested, enemy-held, or nearest Hill
	if gs and gs.is_koth_mode():
		var best_hill_score: float = -999999.0
		for hz in get_tree().get_nodes_in_group("KotHZones"):
			if is_instance_valid(hz) and hz is Node3D:
				var h_pos: Vector3 = hz.global_position
				var dist: float = anchor_pos.distance_to(h_pos)
				var score: float = -dist * 0.45
				var owner_t: String = str(hz.get_meta("controlling_team", "")) if hz.has_meta("controlling_team") else ""
				if owner_t == "" or owner_t == "CONTESTED":
					score += 35.0
				elif owner_t != my_team:
					score += 45.0
					if am and "koth_points" in am and am.koth_points.has(owner_t):
						score += float(am.koth_points[owner_t]) * 0.35
				else:
					score += 10.0 # Reinforce our own hill if nearby
				if score > best_hill_score:
					best_hill_score = score
					objective_pos = h_pos
					found_objective = true

	# 2. Domination / Asymmetric / FFA Base & Tower targeting
	if not found_objective:
		var best_target_score: float = -999999.0
		for node in get_tree().get_nodes_in_group("Targetable"):
			if not is_instance_valid(node) or not (node is Node3D) or node.is_in_group(my_team):
				continue
			if not ("Base" in node.name or "Tower" in node.name):
				continue
			var hc = node.get_node_or_null("HealthComponent")
			if hc and hc.is_dead:
				continue
			var d: float = anchor_pos.distance_to(node.global_position)
			var hp_pct: float = (hc.current_health / max(1.0, hc.max_health)) if hc else 1.0
			var score: float = -d
			if "Tower" in node.name:
				score += 18.0 # Clear forward towers along the lane
			if hp_pct < 0.65:
				score += (1.0 - hp_pct) * 75.0 # Finish off weakened structures!
			if team_ctx.get("is_ffa", false) and d < 95.0:
				score += 30.0 # Focus immediate neighbors in 3P-25P FFA
			if score > best_target_score:
				best_target_score = score
				objective_pos = node.global_position
				found_objective = true

	# 3. Determine push_dir using map layout and GameState.lane_segments
	var push_dir: Vector3 = (objective_pos - anchor_pos)
	push_dir.y = 0.0
	if push_dir.length() > 0.2:
		push_dir = push_dir.normalized()
	else:
		push_dir = Vector3(0.0, 0.0, -1.0 if anchor_pos.z > 0.0 else 1.0)

	if gs and gs.map_layout_id == "QUAD_4LANE_2V2" and not gs.is_ffa_mode():
		var z_dir = -1.0 if anchor_pos.z > 0.0 else 1.0
		push_dir = Vector3(0.0, 0.0, z_dir)
	elif gs and gs.lane_segments.size() > 0:
		# Find the lane segment connected near spawn_anchor that best aligns with objective_pos
		var best_lane_dir: Vector3 = Vector3.ZERO
		var best_align: float = 0.15
		for seg in gs.lane_segments:
			var p_from: Vector3 = seg.get("a", seg.get("from", Vector3.ZERO))
			var p_to: Vector3 = seg.get("b", seg.get("to", Vector3.ZERO))
			if anchor_pos.distance_to(p_from) <= 34.0:
				var l_dir = (p_to - p_from)
				l_dir.y = 0.0
				if l_dir.length() > 0.1:
					l_dir = l_dir.normalized()
					var align = l_dir.dot(push_dir)
					if align > best_align:
						best_align = align
						best_lane_dir = l_dir
			elif anchor_pos.distance_to(p_to) <= 34.0:
				var l_dir2 = (p_from - p_to)
				l_dir2.y = 0.0
				if l_dir2.length() > 0.1:
					l_dir2 = l_dir2.normalized()
					var align2 = l_dir2.dot(push_dir)
					if align2 > best_align:
						best_align = align2
						best_lane_dir = l_dir2
		if best_lane_dir.length() > 0.1:
			push_dir = (push_dir * 0.45 + best_lane_dir * 0.55).normalized()

	return {
		"objective_pos": objective_pos,
		"push_dir": push_dir
	}

func calculate_optimal_spawn(card: CardData, threat_info: Dictionary, team_ctx: Dictionary = {}):
	var gs = _get_game_state()
	if team_ctx.is_empty():
		team_ctx = _assess_team_context()
	var card_faction: String = _get_card_faction(card)

	# 1. Spell Targeting (CallArtillery, VoidMeteor, etc.)
	if card.is_spell:
		# A. If under attack, drop spell on the cluster attacking our endangered structure!
		if threat_info.threat_score > 10.0 and threat_info.hostiles_near_endangered.size() > 0:
			var best_spell_target = null
			var max_cluster = -1
			for h in threat_info.hostiles_near_endangered:
				if not is_instance_valid(h): continue
				var count = 0
				for other in threat_info.hostiles_near_endangered:
					if is_instance_valid(other) and h.global_position.distance_to(other.global_position) < 10.0:
						count += 1
				if count > max_cluster:
					max_cluster = count
					best_spell_target = h
			if best_spell_target and is_instance_valid(best_spell_target):
				return best_spell_target.global_position

		# B. In KotH mode, check if enemies are clustered on a KotH Hill!
		if gs and gs.is_koth_mode():
			for hz in get_tree().get_nodes_in_group("KotHZones"):
				if is_instance_valid(hz) and hz is Node3D:
					var hill_enemies = []
					for u in get_tree().get_nodes_in_group("Targetable"):
						if is_instance_valid(u) and not u.is_in_group(my_team) and not ("Base" in u.name or "Tower" in u.name):
							if u.global_position.distance_to(hz.global_position) <= 12.0:
								hill_enemies.append(u)
					if hill_enemies.size() >= 2:
						return hill_enemies[0].global_position

		# C. Otherwise, find densest enemy cluster anywhere on the field
		var all_targets = []
		for u in get_tree().get_nodes_in_group("Targetable"):
			if not u.is_in_group(my_team) and not "Base" in u.name and not "Tower" in u.name and is_instance_valid(u):
				var hp = u.get_node_or_null("HealthComponent")
				if hp and hp.is_dead: continue
				if gs and gs.is_unit_stealthed_from(u, null): continue
				all_targets.append(u)
				
		if all_targets.size() > 0:
			var best_t = all_targets[0]
			var max_c = 0
			for u in all_targets:
				var c = 0
				for other in all_targets:
					if u.global_position.distance_to(other.global_position) < 10.0:
						c += 1
				if c > max_c:
					max_c = c
					best_t = u
			if best_t and is_instance_valid(best_t):
				return best_t.global_position
		return null
		
	var my_structures = []
	for s in threat_info.structures:
		if is_instance_valid(s):
			my_structures.append(s)
	if my_structures.is_empty():
		return null
		
	var am = (get_tree().current_scene if get_tree().current_scene else get_parent())
	var anchor: Node3D = null
	var target_pos: Vector3 = Vector3.ZERO
		
	# 2. Defensive Interception Deployment when under threat
	if threat_info.threat_score > 12.0 and threat_info.endangered_structure != null and is_instance_valid(threat_info.endangered_structure):
		anchor = threat_info.endangered_structure
		target_pos = anchor.global_position
		
		if threat_info.closest_hostile != null and is_instance_valid(threat_info.closest_hostile):
			var to_threat = (threat_info.closest_hostile.global_position - anchor.global_position)
			to_threat.y = 0
			var threat_dist = to_threat.length()
			var threat_dir = to_threat.normalized() if threat_dist > 0.1 else Vector3(0, 0, 1)
			var side_dir = threat_dir.cross(Vector3.UP).normalized()
			
			# Ranged / Artillery / Sniper / Acid spitters / Infectors / Animal spitters deploy slightly offset / behind anchor
			if card.card_name in ["Sniper", "VoidSpitter", "VoidCorruptor", "SpiderTank", "ReachRanged", "RimworlderGunner", "BeastDigestiveCell", "PlagueRangedEye", "PlagueEnlightenedRanged", "PlagueInfector", "GildedInfector", "GildedGeneticRanged", "GildedHuskRanged", "SupportingFire", "ScrapRanged", "RocketInfantry", "WildlifeArcherfish", "WildlifePistolShrimp", "WildlifeBombardierBeetle", "WildlifeSpittingCobra", "WildlifeMonkey", "WildlifeChameleon", "PrimitiveShortBow", "PrimitiveCrossbowman", "PrimitiveRockThrower"]:
				var offset_dist = clamp(threat_dist * 0.35, 4.0, 14.0)
				target_pos = anchor.global_position + (side_dir * (8.0 if randf() > 0.5 else -8.0)) + (threat_dir * offset_dist)
			else:
				# Melee / Tanks / Mechs / Interceptors deploy directly in front of the attacker to intercept!
				var intercept_dist = clamp(threat_dist * 0.65, 5.0, 22.0)
				target_pos = anchor.global_position + (threat_dir * intercept_dist) + (side_dir * randf_range(-3.0, 3.0))
		else:
			target_pos += Vector3(randf_range(-6.0, 6.0), 0, randf_range(-6.0, 6.0))
		
	else:
		# 3. Offense / Pushing Deployment (Map-aware, Team-aware, Faction/Chaos-aware)
		push_lane_toggle = not push_lane_toggle
		var slot_towers: Array = []
		var forward_bays: Array = []
		var slot_base: Node3D = null
		var slot_prefix_t = "Tower_" + str(slot_index) + "_"
		var slot_base_name = "Base_" + str(slot_index)
		for s in my_structures:
			if "CommandBay" in s.name:
				forward_bays.append(s)
			elif s.name.begins_with(slot_prefix_t) or (slot_index == 0 and s.name.begins_with("TowerA")) or (slot_index == 1 and s.name.begins_with("TowerB")):
				slot_towers.append(s)
			elif s.name == slot_base_name or (slot_index == 0 and s.name == "BaseA") or (slot_index == 1 and s.name == "BaseB"):
				slot_base = s
				
		var spawn_anchor = my_structures[0]
		if forward_bays.size() > 0 and randf() < 0.75:
			spawn_anchor = forward_bays.pick_random()
		elif slot_towers.size() > 0:
			var preferred_suffix = "_Left" if push_lane_toggle else "_Right"
			spawn_anchor = slot_towers[0]
			for st in slot_towers:
				if st.name.ends_with(preferred_suffix):
					spawn_anchor = st
					break
		elif slot_base != null and is_instance_valid(slot_base):
			spawn_anchor = slot_base
		else:
			spawn_anchor = my_structures.pick_random()
		anchor = spawn_anchor

		var nav_info: Dictionary = _compute_strategic_objective_and_lane(spawn_anchor, team_ctx)
		var push_dir: Vector3 = nav_info["push_dir"]
		var right_dir: Vector3 = push_dir.cross(Vector3.UP).normalized()
		if right_dir.length() < 0.1:
			right_dir = Vector3(1, 0, 0)
		target_pos = spawn_anchor.global_position

		# Team Coordination: check if an allied wave (friendly Tank, Mech, Commander, or Beast sponge) is already advancing near spawn_anchor
		var allied_vanguard: Node3D = null
		if team_ctx.get("my_team_players", 1) > 1 or archetype in ["Chaos", "Dominion", "The Reach", "Plague of Harmony", "Gilded Harmony"]:
			for ally in get_tree().get_nodes_in_group(my_team):
				if is_instance_valid(ally) and ally is Node3D and not ("Base" in ally.name or "Tower" in ally.name or "CommandBay" in ally.name):
					var ahc = ally.get_node_or_null("HealthComponent")
					if ahc and not ahc.is_dead and ahc.max_health >= 160.0:
						var d_anchor = ally.global_position.distance_to(spawn_anchor.global_position)
						if d_anchor >= 4.0 and d_anchor <= 24.0:
							allied_vanguard = ally
							break

		# Tactical Stealth Ambush for long-range and flanking units
		var is_ambusher = card.card_name in ["Sniper", "VoidSpitter", "SpiderTank", "ReachRanged", "RimworlderGunner", "Assassin", "VoidStalker", "VoidShieldStalker", "ReachHunter", "SupportingFire"]
		var ambush_chance = 0.65 if difficulty == "HARD" else (0.30 if difficulty == "MEDIUM" else 0.0)
		var ambushed = false
		if is_ambusher and randf() < ambush_chance and am and "placed_feature_records" in am:
			var candidate_brushes = []
			for feat in am.placed_feature_records:
				if feat.get("type", "") == "brush":
					var b_pos = feat.get("pos", Vector3.ZERO)
					if b_pos.distance_to(spawn_anchor.global_position) <= 24.0:
						candidate_brushes.append(b_pos)
			if candidate_brushes.size() > 0:
				var b_chosen = candidate_brushes.pick_random()
				target_pos = b_chosen + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
				ambushed = true
				
		if not ambushed:
			# Per-Card & Per-Faction / Chaos Hybrid Placement Intelligence:
			if card_faction == "The Reach" or "Reach" in card.card_name:
				# Reach Cybernetic Network Synergy: deploy within 2.0-4.2m of friendly Reach units (up to +75% buff)
				var friendly_reach = []
				for ally in get_tree().get_nodes_in_group(my_team):
					if is_instance_valid(ally) and ally is Node3D and "Reach" in ally.name:
						var ahc = ally.get_node_or_null("HealthComponent")
						if ahc and ahc.is_dead: continue
						if ally.global_position.distance_to(spawn_anchor.global_position) <= 24.0:
							friendly_reach.append(ally)
				if friendly_reach.size() > 0:
					var cluster_ally = friendly_reach.pick_random()
					var cluster_offset = (push_dir * randf_range(1.8, 3.8)) + (right_dir * randf_range(-2.2, 2.2))
					target_pos = cluster_ally.global_position + cluster_offset
				else:
					target_pos += (push_dir * randf_range(8.0, 15.0)) + (right_dir * randf_range(-3.5, 3.5))
			elif "ScrapTank" in card.card_name or "LandMine" in card.card_name:
				# Pirate Volatile Vanguard / LandMine Sappers: deep frontline deployment
				target_pos += (push_dir * randf_range(17.0, 25.0)) + (right_dir * randf_range(-3.0, 3.0))
			elif "Repair" in card.card_name:
				# Dominion RepairMan / Pirate ScrapRepair: attach behind any friendly Vehicle across any faction!
				var damaged_veh = null
				var min_hp = 1.05
				for ally in get_tree().get_nodes_in_group(my_team):
					if is_instance_valid(ally) and ally is Node3D and ("Tank" in ally.name or "Mech" in ally.name or "Walker" in ally.name):
						var ahc = ally.get_node_or_null("HealthComponent")
						if ahc and not ahc.is_dead and (ahc.current_health / max(1.0, ahc.max_health)) < min_hp:
							if ally.global_position.distance_to(spawn_anchor.global_position) <= 23.0:
								min_hp = ahc.current_health / max(1.0, ahc.max_health)
								damaged_veh = ally
				if damaged_veh:
					target_pos = damaged_veh.global_position - (push_dir * 3.5) + (right_dir * randf_range(-1.5, 1.5))
				else:
					target_pos += (push_dir * randf_range(6.0, 11.0))
			elif "Medic" in card.card_name or "ReachSupport" in card.card_name or "VoidCorruptor" in card.card_name:
				# Attach behind friendly vanguard or Commander (or damaged Void ally for VoidCorruptor)
				if allied_vanguard != null and is_instance_valid(allied_vanguard):
					target_pos = allied_vanguard.global_position - (push_dir * 4.0) + (right_dir * randf_range(-2.0, 2.0))
				else:
					target_pos += (push_dir * randf_range(6.0, 11.0)) + (right_dir * randf_range(-3.0, 3.0))
			elif "GreatBeastSpeaker" in card.card_name:
				# Position directly behind friendly Beast/Mutant pack to grant +20% Beast Master Aura
				var beast_ally: Node3D = null
				for ally in get_tree().get_nodes_in_group(my_team):
					if is_instance_valid(ally) and ally is Node3D and (ally.is_in_group("Beast") or "Leviathan" in ally.name or "Monstrous" in ally.name or "Mutant" in ally.name or "Octopus" in ally.name or "Squid" in ally.name):
						if ally.global_position.distance_to(spawn_anchor.global_position) <= 23.0:
							beast_ally = ally
							break
				if beast_ally:
					target_pos = beast_ally.global_position - (push_dir * 3.8)
				else:
					target_pos += (push_dir * randf_range(9.0, 14.0))
			elif "Infector" in card.card_name:
				# PlagueInfector & GildedInfector: deploy 5m behind an allied frontline screen so its 4s conversion beam completes safely!
				if allied_vanguard != null and is_instance_valid(allied_vanguard):
					target_pos = allied_vanguard.global_position - (push_dir * 5.0) + (right_dir * randf_range(-2.5, 2.5))
				else:
					target_pos += (push_dir * randf_range(7.0, 12.0)) + (right_dir * randf_range(-4.0, 4.0))
			elif "Genetic" in card.card_name or "SavedHorde" in card.card_name:
				# Gilded Harmony Mitosis Spacing: stagger deployments so wounded monsters regenerate to full HP and divide!
				target_pos += (push_dir * randf_range(11.0, 19.0)) + (right_dir * randf_range(-6.5, 6.5))
			elif "Beetle" in card.card_name or "Jellyfish" in card.card_name or "Plane" in card.card_name or "Flyer" in card.card_name or "Gargoyle" in card.card_name or "Eagle" in card.card_name or "Condor" in card.card_name or "Raven" in card.card_name or "Owl" in card.card_name or "Bird" in card.card_name or "Goose" in card.card_name or "Hawk" in card.card_name or "Falcon" in card.card_name or "Bat" in card.card_name or "Vulture" in card.card_name or "Pelican" in card.card_name or "Hornet" in card.card_name or "Wasp" in card.card_name or "Mosquito" in card.card_name or "Dragonfly" in card.card_name or "Bee" in card.card_name:
				# Flying Beasts & Aircraft: bypass ground obstacles along wide aerial flanks
				var flank_offset = right_dir * (16.0 if randf() > 0.5 else -16.0)
				target_pos += (push_dir * randf_range(13.0, 22.0)) + flank_offset
			elif "Leviathan" in card.card_name or "Monstrous" in card.card_name or "Mutant" in card.card_name or "Octopus" in card.card_name or "Squid" in card.card_name or "MeleeEye" in card.card_name or "Tank" in card.card_name or "Mech" in card.card_name or "EnlightenedBig" in card.card_name or "ShieldInfantry" in card.card_name or "ArmoredInfantry" in card.card_name or "Mammoth" in card.card_name or "Megalodon" in card.card_name or "Whale" in card.card_name or "Shark" in card.card_name or "Elephant" in card.card_name or "Hippo" in card.card_name or "Rhino" in card.card_name or "Bear" in card.card_name or "Croc" in card.card_name or "Alligator" in card.card_name or "Gorilla" in card.card_name or "Tiger" in card.card_name or "Lion" in card.card_name or "Bison" in card.card_name or "Buffalo" in card.card_name or "Walrus" in card.card_name or "Knight" in card.card_name or "Clubber" in card.card_name:
				# Frontline Armor / Shielded Vanguards / Bio-Titan / Apex Beasts march down the primary push vector
				target_pos += (push_dir * randf_range(13.0, 21.0)) + (right_dir * randf_range(-3.0, 3.0))
			elif "CommandBay" in card.card_name:
				# Deploy near perimeter edge toward objective/hill to expand forward deployment zone
				target_pos += (push_dir * 20.0) + (right_dir * (7.0 if randf() > 0.5 else -7.0))
			elif card.card_name in ["Sniper", "VoidSpitter", "SpiderTank", "ReachRanged", "RimworlderGunner", "PlagueRangedEye", "PlagueEnlightenedRanged", "GildedGeneticRanged", "GildedHuskRanged", "SupportingFire", "ScrapRanged", "RocketInfantry", "WildlifeArcherfish", "WildlifePistolShrimp", "WildlifeBombardierBeetle", "WildlifeSpittingCobra", "WildlifeMonkey", "WildlifeChameleon", "PrimitiveShortBow", "PrimitiveCrossbowman", "PrimitiveRockThrower"]:
				if allied_vanguard != null and is_instance_valid(allied_vanguard):
					target_pos = allied_vanguard.global_position - (push_dir * 5.5) + (right_dir * randf_range(-4.5, 4.5))
				else:
					var side_offset = right_dir * (14.0 if randf() > 0.5 else -14.0)
					target_pos += (push_dir * randf_range(4.0, 9.0)) + side_offset
			elif card.card_name in ["Assassin", "VoidStalker", "VoidShieldStalker", "ReachHunter", "HeroHunter", "ScrapHunter"]:
				var side_offset = right_dir * (14.0 if randf() > 0.5 else -14.0)
				target_pos += (push_dir * randf_range(10.0, 18.0)) + side_offset
			else:
				var side_offset = right_dir * randf_range(-5.0, 5.0)
				target_pos += (push_dir * randf_range(9.0, 18.0)) + side_offset
				
			# In KotH Mode: pull deployment vector toward the prioritized Hill
			if gs and gs.is_koth_mode():
				var to_obj = (nav_info["objective_pos"] - target_pos)
				to_obj.y = 0.0
				if to_obj.length() > 0.2:
					target_pos += to_obj.normalized() * 4.5
				
			# In Sudden Death: push further forward if territory is secure
			if threat_info.is_sudden_death:
				target_pos += push_dir * 4.0

	# 4. Scorching Dunes: Solar Flare Light Beam Avoidance
	if am and "current_solar_beam" in am and am.current_solar_beam != null and is_instance_valid(am.current_solar_beam):
		var beam_pos = am.current_solar_beam.global_position
		if target_pos.distance_to(beam_pos) < 7.5:
			var avoid_chance = 1.0 if difficulty == "HARD" else (0.70 if difficulty == "MEDIUM" else 0.20)
			if randf() < avoid_chance:
				var away_dir = (target_pos - beam_pos).normalized()
				if away_dir.length() < 0.1: away_dir = Vector3(1, 0, 0)
				target_pos = beam_pos + (away_dir * 8.5)

	# 5. Biome Hazard & Obstacle Avoidance (Dunes, Quicksand Sinkholes, Volcanic Fire, and Broken Ice)
	if am and "placed_feature_records" in am:
		for feat in am.placed_feature_records:
			var f_type = feat.get("type", "")
			if f_type == "dune":
				var d_pos = feat.get("pos", Vector3.ZERO)
				var d_rad = feat.get("radius", 9.5)
				if target_pos.distance_to(d_pos) < d_rad:
					var shift_dir = (target_pos - d_pos).normalized()
					if shift_dir.length() < 0.1: shift_dir = Vector3(0, 0, 1)
					target_pos = d_pos + (shift_dir * (d_rad + 2.0))
			elif f_type == "sinkhole":
				var is_flying_c = "Plane" in card.card_name or "Flyer" in card.card_name or "Beetle" in card.card_name or "Jellyfish" in card.card_name or "Gargoyle" in card.card_name or "Eagle" in card.card_name or "Condor" in card.card_name or "Raven" in card.card_name or "Owl" in card.card_name or "Hornet" in card.card_name or "Bat" in card.card_name or "Bird" in card.card_name or "Goose" in card.card_name or "Hawk" in card.card_name or "Falcon" in card.card_name
				if not is_flying_c:
					var sh_pos = feat.get("pos", Vector3.ZERO)
					var sh_rad = feat.get("radius", 4.8)
					if target_pos.distance_to(sh_pos) < (sh_rad + 1.2):
						var shift_dir = (target_pos - sh_pos).normalized()
						if shift_dir.length() < 0.1: shift_dir = Vector3(1, 0, 0)
						target_pos = sh_pos + (shift_dir * (sh_rad + 2.0))
			elif f_type == "fire_hazard":
				var fh_pos = feat.get("pos", Vector3.ZERO)
				var fh_rad = feat.get("radius", 4.5)
				if target_pos.distance_to(fh_pos) < (fh_rad + 1.0):
					var shift_dir = (target_pos - fh_pos).normalized()
					if shift_dir.length() < 0.1: shift_dir = Vector3(0, 0, 1)
					target_pos = fh_pos + (shift_dir * (fh_rad + 2.0))
			elif f_type == "ice_patch":
				var ip_pos = feat.get("pos", Vector3.ZERO)
				var ip_rad = feat.get("radius", 6.5)
				if target_pos.distance_to(ip_pos) < (ip_rad + 1.0):
					var shift_dir = (target_pos - ip_pos).normalized()
					if shift_dir.length() < 0.1: shift_dir = Vector3(0, 0, 1)
					target_pos = ip_pos + (shift_dir * (ip_rad + 2.0))

	# 6. Clamp to valid deployment range (max 28.0m from anchor, identical to player)
	target_pos.y = 0.0
	if anchor and target_pos.distance_to(anchor.global_position) > 28.0:
		var flat_anchor = Vector3(anchor.global_position.x, 0.0, anchor.global_position.z)
		target_pos = flat_anchor + (target_pos - flat_anchor).normalized() * 27.5
		
	return target_pos

func play_card(card: CardData, target_position: Vector3):
	var am = (get_tree().current_scene if get_tree().current_scene else get_parent())
	if am and am.has_method("can_deploy_at"):
		if not am.can_deploy_at(my_team, target_position, card.is_spell):
			# Fallback: pull target_position back towards friendly anchor structure to guarantee valid deployment
			var fallback_pos = target_position
			var anchor_node: Node3D = null
			for s in get_tree().get_nodes_in_group(my_team):
				if is_instance_valid(s) and ("Base" in s.name or "Tower" in s.name or "CommandBay" in s.name):
					var shc = s.get_node_or_null("HealthComponent")
					if shc == null or not shc.is_dead:
						anchor_node = s
						break
			if anchor_node:
				var flat_a = Vector3(anchor_node.global_position.x, 0.0, anchor_node.global_position.z)
				fallback_pos = flat_a + (target_position - flat_a).normalized() * 12.0
				if am.can_deploy_at(my_team, fallback_pos, card.is_spell):
					target_position = fallback_pos
				else:
					target_position = flat_a + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
			if not am.can_deploy_at(my_team, target_position, card.is_spell):
				print(my_team, " AI cannot deploy outside friendly deployment zone at: ", target_position)
				return

	current_requisition -= card.cost
	
	hand.erase(card)
	var file_name = card.resource_path.get_file().trim_suffix(".tres").trim_suffix(".remap")
	discard.append(file_name)
	
	print(my_team, " AI spent ", card.cost, " energy on ", card.card_name, " | Energy remaining: ", snapped(current_requisition, 0.1))
	
	if am and am.has_method("sync_spawn_card"):
		if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			am.rpc("sync_spawn_card", card.resource_path, target_position, my_team, str(randi()))
		else:
			am.sync_spawn_card(card.resource_path, target_position, my_team, str(randi()))
			
	draw_to_hand()


func _detect_faction_from_deck(deck_list: Array) -> String:
	var v = 0; var r = 0; var d = 0; var pi = 0; var reach = 0; var plague = 0; var gilded = 0; var prim = 0; var wild = 0
	for c in deck_list:
		if "Wildlife" in c: wild += 1
		elif "Primitive" in c: prim += 1
		elif "Plague" in c: plague += 1
		elif "Gilded" in c: gilded += 1
		elif "Void" in c: v += 1
		elif "Rimworlder" in c or "Sky" in c or "Stone" in c or "Giant" in c or "Great" in c or "Monstrous" in c: r += 1
		elif "Scrap" in c: pi += 1
		elif "Reach" in c: reach += 1
		else: d += 1
	var mx = max(d, max(v, max(r, max(pi, max(reach, max(plague, max(gilded, max(prim, wild))))))))
	if mx < 3 and deck_list.size() >= 5: return "Chaos"
	if mx == wild and wild > 0: return "Galactic Wildlife"
	if mx == prim and prim > 0: return "Planetary Primitives"
	if mx == plague and plague > 0: return "Plague of Harmony"
	if mx == gilded and gilded > 0: return "Gilded Harmony"
	if mx == v and v > 0: return "Void"
	if mx == r and r > 0: return "Rimworlders"
	if mx == pi and pi > 0: return "Pirates"
	if mx == reach and reach > 0: return "The Reach"
	return "Dominion"

func generate_chaos_deck() -> Array:
	var dir = DirAccess.open("res://Data/Cards/")
	var all_commanders = []
	var units_by_faction: Dictionary = {}
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
				var clean_name = file_name.trim_suffix(".remap")
				var res = load("res://Data/Cards/" + clean_name)
				if res != null:
					var raw_name = clean_name.replace(".tres", "")
					if "card_type" in res and res.card_type == "Commander":
						all_commanders.append(raw_name)
					else:
						var f_bucket = _detect_faction_from_deck([raw_name])
						if not units_by_faction.has(f_bucket):
							units_by_faction[f_bucket] = []
						units_by_faction[f_bucket].append(raw_name)
			file_name = dir.get_next()
			
	var chaos_deck = []
	if all_commanders.size() > 0:
		chaos_deck.append(all_commanders.pick_random())
		
	var f_keys = units_by_faction.keys()
	f_keys.shuffle()
	for i in range(min(5, f_keys.size())):
		var bucket: Array = units_by_faction[f_keys[i]]
		if bucket.size() > 0:
			chaos_deck.append(bucket.pick_random())
		
	return chaos_deck

func generate_themed_deck(theme: String) -> Array:
	if theme == "Chaos" or theme == "Random":
		return generate_chaos_deck()
		
	var dir = DirAccess.open("res://Data/Cards/")
	var pool_commanders = []
	var pool_units = []
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
				var clean_name = file_name.trim_suffix(".remap")
				var is_wildlife = "Wildlife" in clean_name
				var is_void = not is_wildlife and ("Void" in clean_name)
				var is_rimworlder = not is_wildlife and ("Rimworlder" in clean_name or "Sky" in clean_name or "Stone" in clean_name or "Giant" in clean_name or "Great" in clean_name or "Monstrous" in clean_name)
				var is_pirate = not is_wildlife and ("Scrap" in clean_name)
				var is_reach = not is_wildlife and ("Reach" in clean_name)
				var is_plague = not is_wildlife and ("Plague" in clean_name)
				var is_gilded = not is_wildlife and ("Gilded" in clean_name)
				var is_primitive = not is_wildlife and ("Primitive" in clean_name)
				var is_dominion = not is_void and not is_rimworlder and not is_pirate and not is_reach and not is_plague and not is_gilded and not is_primitive and not is_wildlife
				
				var valid = false
				if theme == "Void" and is_void: valid = true
				elif theme == "Dominion" and is_dominion: valid = true
				elif (theme == "Rimworlders" or theme == "Rimworld") and is_rimworlder: valid = true
				elif (theme == "Pirates" or theme == "Scrap") and is_pirate: valid = true
				elif (theme == "The Reach" or theme == "Reach") and is_reach: valid = true
				elif (theme == "Plague of Harmony" or theme == "Plague") and is_plague: valid = true
				elif (theme == "Gilded Harmony" or theme == "Gilded") and is_gilded: valid = true
				elif (theme == "Planetary Primitives" or theme == "Primitives") and is_primitive: valid = true
				elif (theme == "Galactic Wildlife" or theme == "Wildlife") and is_wildlife: valid = true
				
				if valid:
					var res = load("res://Data/Cards/" + clean_name)
					if res != null:
						var raw_name = clean_name.replace(".tres", "")
						if "card_type" in res and res.card_type == "Commander":
							pool_commanders.append(raw_name)
						else:
							pool_units.append(raw_name)
			file_name = dir.get_next()
			
	var new_deck = []
	if pool_commanders.size() > 0:
		new_deck.append(pool_commanders.pick_random())
	
	pool_units.shuffle()
	# Pick exactly 5 units/spells to form standard 6-card deck
	for i in range(min(5, pool_units.size())):
		new_deck.append(pool_units[i])
		
	return new_deck

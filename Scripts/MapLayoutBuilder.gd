extends RefCounted
class_name MapLayoutBuilder

const TowerScene = preload("res://Scenes/Tower.tscn")
const TowerScript = preload("res://Scripts/Tower.gd")
const ProjectileScene = preload("res://Scenes/Projectile.tscn")
const HealthComponentScript = preload("res://Scripts/HealthComponent.gd")

const MAP_CATALOG: Array[Dictionary] = [
	{
		"id": "CLASSIC_1V1",
		"title": "1v1: Classic Twin-Spire Corridor (2P)",
		"default_players": 2,
		"arena_radius": 125.0,
		"ground_size": 220.0,
		"comps": [
			{"label": "2 Players — 1v1 (2 Teams)", "players": 2, "comp": "2_TEAMS"},
			{"label": "2 Players — Free For All", "players": 2, "comp": "FFA"}
		]
	},
	{
		"id": "CANYON_1V1",
		"title": "1v1: Twin-Bridge Abyssal Canyon (2P)",
		"default_players": 2,
		"arena_radius": 135.0,
		"ground_size": 240.0,
		"comps": [
			{"label": "2 Players — 1v1 (2 Teams)", "players": 2, "comp": "2_TEAMS"},
			{"label": "2 Players — Free For All", "players": 2, "comp": "FFA"}
		]
	},
	{
		"id": "TRISKELION_3P",
		"title": "3-Player: Triskelion 3-Wing Spiral (3P)",
		"default_players": 3,
		"arena_radius": 150.0,
		"ground_size": 270.0,
		"comps": [
			{"label": "3 Players — Free For All (1v1v1)", "players": 3, "comp": "FFA"},
			{"label": "3 Players — 2v1 Asymmetric (2 Teams)", "players": 3, "comp": "2_TEAMS"}
		]
	},
	{
		"id": "DELTA_GRID_3P",
		"title": "3-Player: Delta Tri-Grid Citadel (3P)",
		"default_players": 3,
		"arena_radius": 155.0,
		"ground_size": 280.0,
		"comps": [
			{"label": "3 Players — Free For All (1v1v1)", "players": 3, "comp": "FFA"},
			{"label": "3 Players — 2v1 Asymmetric (2 Teams)", "players": 3, "comp": "2_TEAMS"}
		]
	},
	{
		"id": "QUAD_4LANE_2V2",
		"title": "2v2 / 4P: 4-Lane Quad Parallel Bastion (4P - 4 Lanes)",
		"default_players": 4,
		"arena_radius": 165.0,
		"ground_size": 300.0,
		"comps": [
			{"label": "4 Players — 2v2 (2 Teams, 4 Lanes)", "players": 4, "comp": "2_TEAMS"},
			{"label": "4 Players — Free For All (4-Way)", "players": 4, "comp": "FFA"},
			{"label": "3 Players — Free For All (3-Way)", "players": 3, "comp": "FFA"}
		]
	},
	{
		"id": "X_CROSSROADS_4P",
		"title": "2v2 / 4P: Crimson X-Blade Crossroads (4P)",
		"default_players": 4,
		"arena_radius": 165.0,
		"ground_size": 300.0,
		"comps": [
			{"label": "4 Players — 2v2 (2 Teams)", "players": 4, "comp": "2_TEAMS"},
			{"label": "4 Players — Free For All (4-Way)", "players": 4, "comp": "FFA"},
			{"label": "3 Players — Free For All (3-Way)", "players": 3, "comp": "FFA"}
		]
	},
	{
		"id": "PENTAGON_5P",
		"title": "5-Player: Pentagram 5-Star Citadel (5P)",
		"default_players": 5,
		"arena_radius": 180.0,
		"ground_size": 320.0,
		"comps": [
			{"label": "5 Players — Free For All (5-Way)", "players": 5, "comp": "FFA"},
			{"label": "5 Players — 3v2 Alliance (2 Teams)", "players": 5, "comp": "2_TEAMS"}
		]
	},
	{
		"id": "CROWN_RIDGE_5P",
		"title": "5-Player: 5-Spire Crown Canyon (5P)",
		"default_players": 5,
		"arena_radius": 185.0,
		"ground_size": 330.0,
		"comps": [
			{"label": "5 Players — Free For All (5-Way)", "players": 5, "comp": "FFA"},
			{"label": "5 Players — 3v2 Alliance (2 Teams)", "players": 5, "comp": "2_TEAMS"}
		]
	},
	{
		"id": "HEX_STAR_6P",
		"title": "3v3 / 6P: Hexagonal Star Nexus (6P)",
		"default_players": 6,
		"arena_radius": 205.0,
		"ground_size": 340.0,
		"comps": [
			{"label": "6 Players — 3v3 (2 Teams)", "players": 6, "comp": "2_TEAMS"},
			{"label": "6 Players — 2v2v2 (3 Teams)", "players": 6, "comp": "3_TEAMS"},
			{"label": "6 Players — Free For All (6-Way)", "players": 6, "comp": "FFA"}
		]
	},
	{
		"id": "SERPENT_RIVER_6P",
		"title": "3v3 / 6P: Serpentine S-Curve Delta (6P)",
		"default_players": 6,
		"arena_radius": 210.0,
		"ground_size": 350.0,
		"comps": [
			{"label": "6 Players — 3v3 (2 Teams)", "players": 6, "comp": "2_TEAMS"},
			{"label": "6 Players — 2v2v2 (3 Teams)", "players": 6, "comp": "3_TEAMS"},
			{"label": "6 Players — Free For All (6-Way)", "players": 6, "comp": "FFA"}
		]
	},
	{
		"id": "OCTA_WEB_8P",
		"title": "4v4 / 8P: Octagonal Spider-Web Wheel (8P)",
		"default_players": 8,
		"arena_radius": 225.0,
		"ground_size": 380.0,
		"comps": [
			{"label": "8 Players — 4v4 (2 Teams)", "players": 8, "comp": "2_TEAMS"},
			{"label": "8 Players — 2v2v2v2 (4 Teams)", "players": 8, "comp": "4_TEAMS"},
			{"label": "8 Players — Free For All (8-Way)", "players": 8, "comp": "FFA"},
			{"label": "7 Players — Free For All (7-Way)", "players": 7, "comp": "FFA"}
		]
	},
	{
		"id": "TWIN_SQUARE_8P",
		"title": "4v4 / 8P: Twin-Square Grid Fortress (8P)",
		"default_players": 8,
		"arena_radius": 230.0,
		"ground_size": 390.0,
		"comps": [
			{"label": "8 Players — 4v4 (2 Teams)", "players": 8, "comp": "2_TEAMS"},
			{"label": "8 Players — 2v2v2v2 (4 Teams)", "players": 8, "comp": "4_TEAMS"},
			{"label": "8 Players — Free For All (8-Way)", "players": 8, "comp": "FFA"},
			{"label": "7 Players — Free For All (7-Way)", "players": 7, "comp": "FFA"}
		]
	},
	{
		"id": "TRI_FORTRESS_9P",
		"title": "3v3v3 / 9P: Three-Wing Tri-Fortress (9P)",
		"default_players": 9,
		"arena_radius": 240.0,
		"ground_size": 410.0,
		"comps": [
			{"label": "9 Players — 3v3v3 (3 Teams)", "players": 9, "comp": "3_TEAMS"},
			{"label": "9 Players — Free For All (9-Way)", "players": 9, "comp": "FFA"}
		]
	},
	{
		"id": "HOURGLASS_10P",
		"title": "5v5 / 10P: Twin-Vortex Hourglass (10P)",
		"default_players": 10,
		"arena_radius": 250.0,
		"ground_size": 430.0,
		"comps": [
			{"label": "10 Players — 5v5 (2 Teams)", "players": 10, "comp": "2_TEAMS"},
			{"label": "10 Players — 2x5 Squads (5 Teams)", "players": 10, "comp": "5_TEAMS"},
			{"label": "10 Players — Free For All (10-Way)", "players": 10, "comp": "FFA"}
		]
	},
	{
		"id": "CLOVER_CROSS_12P",
		"title": "6v6 / 12P: 4-Leaf Clover Maltese Cross (12P)",
		"default_players": 12,
		"arena_radius": 275.0,
		"ground_size": 470.0,
		"comps": [
			{"label": "12 Players — 6v6 (2 Teams)", "players": 12, "comp": "2_TEAMS"},
			{"label": "12 Players — 3v3v3v3 (4 Teams)", "players": 12, "comp": "4_TEAMS"},
			{"label": "12 Players — 4v4v4 (3 Teams)", "players": 12, "comp": "3_TEAMS"},
			{"label": "12 Players — 2x6 Duo Squads (6 Teams)", "players": 12, "comp": "6_TEAMS"},
			{"label": "12 Players — Free For All (12-Way)", "players": 12, "comp": "FFA"},
			{"label": "11 Players — Free For All (11-Way)", "players": 11, "comp": "FFA"}
		]
	},
	{
		"id": "LABYRINTH_16P",
		"title": "8v8 / 16P: Double-Ring Spiral Labyrinth (16P)",
		"default_players": 16,
		"arena_radius": 310.0,
		"ground_size": 540.0,
		"comps": [
			{"label": "16 Players — 8v8 (2 Teams)", "players": 16, "comp": "2_TEAMS"},
			{"label": "16 Players — 4v4v4v4 (4 Teams)", "players": 16, "comp": "4_TEAMS"},
			{"label": "16 Players — 2x8 Duo Squads (8 Teams)", "players": 16, "comp": "8_TEAMS"},
			{"label": "16 Players — Free For All (16-Way)", "players": 16, "comp": "FFA"},
			{"label": "14 Players — 7v7 (2 Teams)", "players": 14, "comp": "2_TEAMS"},
			{"label": "14 Players — Free For All (14-Way)", "players": 14, "comp": "FFA"},
			{"label": "13 Players — Free For All (13-Way)", "players": 13, "comp": "FFA"}
		]
	},
	{
		"id": "PENTAGRAM_RING_20P",
		"title": "10v10 / 20P: Pentagram 5-Bastion Ring (20P)",
		"default_players": 20,
		"arena_radius": 350.0,
		"ground_size": 600.0,
		"comps": [
			{"label": "20 Players — 10v10 (2 Teams)", "players": 20, "comp": "2_TEAMS"},
			{"label": "20 Players — 4x5 Bastions (5 Teams of 4)", "players": 20, "comp": "5_TEAMS"},
			{"label": "20 Players — 5x4 Alliances (4 Teams of 5)", "players": 20, "comp": "4_TEAMS"},
			{"label": "20 Players — Free For All (20-Way)", "players": 20, "comp": "FFA"},
			{"label": "19 Players — Free For All (19-Way)", "players": 19, "comp": "FFA"},
			{"label": "18 Players — 9v9 (2 Teams)", "players": 18, "comp": "2_TEAMS"},
			{"label": "18 Players — Free For All (18-Way)", "players": 18, "comp": "FFA"},
			{"label": "17 Players — Free For All (17-Way)", "players": 17, "comp": "FFA"}
		]
	},
	{
		"id": "MEGA_MANDALA_25P",
		"title": "5x5 / 25P: 25-Player Grand Mandala Colosseum (25P)",
		"default_players": 25,
		"arena_radius": 410.0,
		"ground_size": 700.0,
		"comps": [
			{"label": "25 Players — 5x5 Grand Alliance (5 Teams of 5)", "players": 25, "comp": "5_TEAMS"},
			{"label": "25 Players — 13v12 Mega War (2 Teams)", "players": 25, "comp": "2_TEAMS"},
			{"label": "25 Players — Free For All (25-Way Battle Royale)", "players": 25, "comp": "FFA"},
			{"label": "24 Players — 12v12 Grand War (2 Teams)", "players": 24, "comp": "2_TEAMS"},
			{"label": "24 Players — 6x4 Alliances (6 Teams of 4)", "players": 24, "comp": "6_TEAMS"},
			{"label": "23 Players — Free For All (23-Way)", "players": 23, "comp": "FFA"},
			{"label": "22 Players — 11v11 (2 Teams)", "players": 22, "comp": "2_TEAMS"},
			{"label": "21 Players — 7v7v7 (3 Teams of 7)", "players": 21, "comp": "3_TEAMS"},
			{"label": "15 Players — 5v5v5 Lotus War (3 Teams of 5)", "players": 15, "comp": "3_TEAMS"}
		]
	},
	{
		"id": "GRID_NEXUS_25P",
		"title": "25P FFA / Grid: 25-Player Hyper-Grid Lattice (Paths Everywhere)",
		"default_players": 25,
		"arena_radius": 420.0,
		"ground_size": 720.0,
		"comps": [
			{"label": "25 Players — Free For All (25-Way Grid Battle Royale)", "players": 25, "comp": "FFA"},
			{"label": "25 Players — 5x5 Grid Alliances (5 Teams of 5)", "players": 25, "comp": "5_TEAMS"},
			{"label": "25 Players — 13v12 Grid Mega War (2 Teams)", "players": 25, "comp": "2_TEAMS"},
			{"label": "24 Players — Free For All (24-Way Grid)", "players": 24, "comp": "FFA"},
			{"label": "22 Players — Free For All (22-Way Grid)", "players": 22, "comp": "FFA"},
			{"label": "20 Players — Free For All (20-Way Grid)", "players": 20, "comp": "FFA"},
			{"label": "16 Players — Free For All (16-Way Grid)", "players": 16, "comp": "FFA"},
			{"label": "12 Players — Free For All (12-Way Grid)", "players": 12, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_SIEGE_3P",
		"title": "Asymmetric 1v2: Lone Bastion vs Twin Raiders (3P)",
		"default_players": 3,
		"asym_small_count": 1,
		"arena_radius": 155.0,
		"ground_size": 280.0,
		"comps": [
			{"label": "3 Players — 1v2 Asymmetric Siege (P1 Lone Bastion, 2-Base Side -Energy)", "players": 3, "comp": "ASYM_1V2"},
			{"label": "3 Players — 2v1 Asymmetric Raiders (P1 on 2-Base Side -Energy)", "players": 3, "comp": "ASYM_2V1"},
			{"label": "3 Players — Free For All (3-Way Asymmetric)", "players": 3, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_TRIDENT_4P",
		"title": "Asymmetric 1v3: Trident Siege Citadel (4P)",
		"default_players": 4,
		"asym_small_count": 1,
		"arena_radius": 165.0,
		"ground_size": 300.0,
		"comps": [
			{"label": "4 Players — 1v3 Trident Siege (P1 Lone Citadel, 3-Base Side -Energy)", "players": 4, "comp": "ASYM_1V3"},
			{"label": "4 Players — 3v1 Trident Horde (P1 on 3-Base Side -Energy)", "players": 4, "comp": "ASYM_3V1"},
			{"label": "4 Players — Free For All (4-Way Asymmetric)", "players": 4, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_FRONTLINE_5P",
		"title": "Asymmetric 2v3: Twin Fortresses vs 3-Lane Vanguard (5P)",
		"default_players": 5,
		"asym_small_count": 2,
		"arena_radius": 180.0,
		"ground_size": 320.0,
		"comps": [
			{"label": "5 Players — 2v3 Asymmetric Frontline (P1 on 2-Base Side, 3-Base Side -Energy)", "players": 5, "comp": "ASYM_2V3"},
			{"label": "5 Players — 3v2 Asymmetric Vanguard (P1 on 3-Base Side -Energy)", "players": 5, "comp": "ASYM_3V2"},
			{"label": "5 Players — 1v4 Lone Bastion vs 4 Raiders", "players": 5, "comp": "ASYM_1V4"},
			{"label": "5 Players — Free For All (5-Way Asymmetric)", "players": 5, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_CITADEL_6P",
		"title": "Asymmetric 2v4: Twin Spires vs Quad Invaders (6P)",
		"default_players": 6,
		"asym_small_count": 2,
		"arena_radius": 205.0,
		"ground_size": 350.0,
		"comps": [
			{"label": "6 Players — 2v4 Asymmetric Siege (P1 on 2-Base Side, 4-Base Side -Energy)", "players": 6, "comp": "ASYM_2V4"},
			{"label": "6 Players — 4v2 Asymmetric Horde (P1 on 4-Base Side -Energy)", "players": 6, "comp": "ASYM_4V2"},
			{"label": "6 Players — 1v5 Lone Spire vs 5 Invaders", "players": 6, "comp": "ASYM_1V5"},
			{"label": "6 Players — 1v2v3 Asymmetric 3-Team War", "players": 6, "comp": "ASYM_1V2V3"},
			{"label": "6 Players — Free For All (6-Way Asymmetric)", "players": 6, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_WEDGE_8P",
		"title": "Asymmetric 2v6: Iron Wedge Crescent (8P)",
		"default_players": 8,
		"asym_small_count": 2,
		"arena_radius": 230.0,
		"ground_size": 390.0,
		"comps": [
			{"label": "8 Players — 2v6 Iron Wedge (P1 on 2-Base Side, 6-Base Side -Energy)", "players": 8, "comp": "ASYM_2V6"},
			{"label": "8 Players — 6v2 Crescent Horde (P1 on 6-Base Side -Energy)", "players": 8, "comp": "ASYM_6V2"},
			{"label": "8 Players — 3v5 Asymmetric Bastion", "players": 8, "comp": "ASYM_3V5"},
			{"label": "8 Players — 1v7 Lone Bastion vs 7 Raiders", "players": 8, "comp": "ASYM_1V7"},
			{"label": "8 Players — Free For All (8-Way Asymmetric)", "players": 8, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_GRID_10P",
		"title": "Asymmetric 3v7: Tri-Bastion vs 7-Grid Outposts (10P)",
		"default_players": 10,
		"asym_small_count": 3,
		"arena_radius": 255.0,
		"ground_size": 440.0,
		"comps": [
			{"label": "10 Players — 3v7 Asymmetric Grid (P1 on 3-Base Side, 7-Base Side -Energy)", "players": 10, "comp": "ASYM_3V7"},
			{"label": "10 Players — 7v3 Grid Horde (P1 on 7-Base Side -Energy)", "players": 10, "comp": "ASYM_7V3"},
			{"label": "10 Players — 2v8 Asymmetric Siege", "players": 10, "comp": "ASYM_2V8"},
			{"label": "10 Players — 2v3v5 Asymmetric 3-Team War", "players": 10, "comp": "ASYM_2V3V5"},
			{"label": "10 Players — Free For All (10-Way Asymmetric)", "players": 10, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_CRESCENT_12P",
		"title": "Asymmetric 4v8: Quad Keep vs 8-Star Armada (12P)",
		"default_players": 12,
		"asym_small_count": 4,
		"arena_radius": 275.0,
		"ground_size": 470.0,
		"comps": [
			{"label": "12 Players — 4v8 Quad Keep vs Armada (P1 on 4-Base Side, 8-Base Side -Energy)", "players": 12, "comp": "ASYM_4V8"},
			{"label": "12 Players — 8v4 Armada Invasion (P1 on 8-Base Side -Energy)", "players": 12, "comp": "ASYM_8V4"},
			{"label": "12 Players — 3v9 Asymmetric Siege", "players": 12, "comp": "ASYM_3V9"},
			{"label": "12 Players — 2v4v6 Asymmetric 3-Team War", "players": 12, "comp": "ASYM_2V4V6"},
			{"label": "12 Players — Free For All (12-Way Asymmetric)", "players": 12, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_FORTRESS_16P",
		"title": "Asymmetric 5v11: 5-Bastion Wall vs 11-Raider Swarm (16P)",
		"default_players": 16,
		"asym_small_count": 5,
		"arena_radius": 315.0,
		"ground_size": 540.0,
		"comps": [
			{"label": "16 Players — 5v11 Bastion Wall vs Swarm (P1 on 5-Base Side, 11-Base Side -Energy)", "players": 16, "comp": "ASYM_5V11"},
			{"label": "16 Players — 11v5 Swarm Invasion (P1 on 11-Base Side -Energy)", "players": 16, "comp": "ASYM_11V5"},
			{"label": "16 Players — 4v12 Asymmetric Siege", "players": 16, "comp": "ASYM_4V12"},
			{"label": "16 Players — 2v5v9 Asymmetric 3-Team War", "players": 16, "comp": "ASYM_2V5V9"},
			{"label": "16 Players — Free For All (16-Way Asymmetric)", "players": 16, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_SANCTUARY_20P",
		"title": "Asymmetric 5v15: 5-Star Sanctuary vs 15-Outpost Siege Ring (20P)",
		"default_players": 20,
		"asym_small_count": 5,
		"arena_radius": 355.0,
		"ground_size": 610.0,
		"comps": [
			{"label": "20 Players — 5v15 Sanctuary vs Siege Ring (P1 on 5-Base Side, 15-Base Side -Energy)", "players": 20, "comp": "ASYM_5V15"},
			{"label": "20 Players — 15v5 Siege Ring Horde (P1 on 15-Base Side -Energy)", "players": 20, "comp": "ASYM_15V5"},
			{"label": "20 Players — 6v14 Asymmetric War", "players": 20, "comp": "ASYM_6V14"},
			{"label": "20 Players — 2v6v12 Asymmetric 3-Team War", "players": 20, "comp": "ASYM_2V6V12"},
			{"label": "20 Players — Free For All (20-Way Asymmetric)", "players": 20, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_SIEGE_25P",
		"title": "25P Asymmetric Siege Lanes: 5 Citadels vs 20 Invaders (25P)",
		"default_players": 25,
		"asym_small_count": 5,
		"arena_radius": 420.0,
		"ground_size": 720.0,
		"comps": [
			{"label": "25 Players — 5v20 Citadel Siege (P1 on 5-Base Side, 20-Base Side -Energy)", "players": 25, "comp": "ASYM_5V20"},
			{"label": "25 Players — 20v5 Grand Invasion (P1 on 20-Base Side -Energy)", "players": 25, "comp": "ASYM_20V5"},
			{"label": "25 Players — 1v24 Lone Overlord vs 24 Raiders", "players": 25, "comp": "ASYM_1V24"},
			{"label": "25 Players — 8v17 Asymmetric Frontline", "players": 25, "comp": "ASYM_8V17"},
			{"label": "25 Players — 3v7v15 Asymmetric 3-Team Mega War", "players": 25, "comp": "ASYM_3V7V15"},
			{"label": "25 Players — Free For All (25-Way Asymmetric Siege)", "players": 25, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_MANDALA_25P",
		"title": "25P Asymmetric Mandala Raid: 5 Inner Sanctum vs 20 Crescent Raiders (25P)",
		"default_players": 25,
		"asym_small_count": 5,
		"arena_radius": 420.0,
		"ground_size": 720.0,
		"comps": [
			{"label": "25 Players — 5v20 Sanctum vs Crescent Horde (P1 on 5-Base Side, 20-Base Side -Energy)", "players": 25, "comp": "ASYM_5V20"},
			{"label": "25 Players — 20v5 Crescent Horde Raid (P1 on 20-Base Side -Energy)", "players": 25, "comp": "ASYM_20V5"},
			{"label": "25 Players — 1v24 Apex Overlord Boss Raid", "players": 25, "comp": "ASYM_1V24"},
			{"label": "25 Players — 24v1 Raider Swarm vs Apex Overlord (P1 on 24-Base Side -Energy)", "players": 25, "comp": "ASYM_24V1"},
			{"label": "25 Players — 1v4v20 Overlord + Wardens vs Horde (3 Teams)", "players": 25, "comp": "ASYM_1V4V20"},
			{"label": "25 Players — Free For All (25-Way Asymmetric Mandala)", "players": 25, "comp": "FFA"}
		]
	},
	{
		"id": "ASYM_GRID_25P",
		"title": "25P Asymmetric Hyper-Grid: 7 West Citadels vs 18 East Grid Raiders (Paths Everywhere)",
		"default_players": 25,
		"asym_small_count": 7,
		"arena_radius": 420.0,
		"ground_size": 720.0,
		"comps": [
			{"label": "25 Players — 7v18 Asymmetric Hyper-Grid (P1 on 7-Base Side, 18-Base Side -Energy)", "players": 25, "comp": "ASYM_7V18"},
			{"label": "25 Players — 18v7 Urban Grid Horde (P1 on 18-Base Side -Energy)", "players": 25, "comp": "ASYM_18V7"},
			{"label": "25 Players — 5v20 Asymmetric Grid Siege", "players": 25, "comp": "ASYM_5V20"},
			{"label": "25 Players — 1v24 Lone Grid Citadel vs 24 Raiders", "players": 25, "comp": "ASYM_1V24"},
			{"label": "25 Players — 3v7v15 Asymmetric Grid 3-Team War", "players": 25, "comp": "ASYM_3V7V15"},
			{"label": "25 Players — Free For All (25-Way Asymmetric Hyper-Grid)", "players": 25, "comp": "FFA"}
		]
	}
]

static func get_map_entry(layout_id: String) -> Dictionary:
	for entry: Dictionary in MAP_CATALOG:
		if String(entry["id"]) == layout_id:
			return entry
	return MAP_CATALOG[0]

static func build_map_layout(arena: Node3D, requested_layout_id: String, requested_players: int, requested_comp: String) -> Dictionary:
	var layout_id: String = requested_layout_id
	if layout_id == "" or layout_id == "DEFAULT":
		if GameState.map_selected == "Arena_6P.tscn":
			layout_id = "HEX_STAR_6P"
		elif GameState.map_selected == "Arena_4P.tscn":
			layout_id = "QUAD_4LANE_2V2"
		else:
			layout_id = "CLASSIC_1V1"
	elif layout_id == "RANDOM_MAP":
		var pick: Dictionary = MAP_CATALOG[randi() % MAP_CATALOG.size()]
		layout_id = String(pick["id"])
		var comps: Array = pick["comps"]
		var rand_comp: Dictionary = comps[randi() % comps.size()]
		requested_players = int(rand_comp["players"])
		requested_comp = String(rand_comp["comp"])

	var entry: Dictionary = get_map_entry(layout_id)
	var def_players: int = int(entry["default_players"])
	var total_slots: int = clampi(requested_players if requested_players >= 2 else def_players, 2, 25)
	var arena_radius: float = float(entry["arena_radius"])
	var ground_size: float = float(entry["ground_size"])

	GameState.map_layout_id = layout_id
	GameState.current_map_radius = arena_radius
	GameState.lane_segments.clear()

	# Resize Ground & Shadow Distance
	var ground: Node3D = arena.get_node_or_null("Ground") as Node3D
	if ground:
		var g_mesh: MeshInstance3D = ground.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if g_mesh:
			var pm := PlaneMesh.new()
			pm.size = Vector2(ground_size, ground_size)
			g_mesh.mesh = pm
		var g_col: CollisionShape3D = ground.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if g_col:
			var bs := BoxShape3D.new()
			bs.size = Vector3(ground_size, 0.1, ground_size)
			g_col.shape = bs
		for child in ground.get_children():
			if (child is MeshInstance3D and child.name.begins_with("Path")) or child.name == "MapArchitecture":
				ground.remove_child(child)
				child.queue_free()

	var dir_light: DirectionalLight3D = arena.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if dir_light:
		dir_light.directional_shadow_max_distance = maxf(240.0, ground_size * 0.85)

	# Remove existing bases, towers, and old KotH zones so we can build the exact layout cleanly
	var to_remove: Array[Node] = []
	for child in arena.get_children():
		var cn: String = child.name
		if "Base" in cn or "Tower" in cn or cn.begins_with("KotH_Zone"):
			to_remove.append(child)
	for rem: Node in to_remove:
		arena.remove_child(rem)
		rem.queue_free()

	var arch_root := Node3D.new()
	arch_root.name = "MapArchitecture"
	if ground:
		ground.add_child(arch_root)
	else:
		arena.add_child(arch_root)

	var slot_defs: Array[Dictionary] = []
	var koth_positions: Array[Dictionary] = [{"pos": Vector3.ZERO, "radius": 16.0}]

	match layout_id:
		"CLASSIC_1V1":
			slot_defs = _build_classic_1v1(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 15.0}]
		"CANYON_1V1":
			slot_defs = _build_canyon_1v1(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 15.0}]
		"TRISKELION_3P":
			slot_defs = _build_triskelion_3p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 17.0}]
		"DELTA_GRID_3P":
			slot_defs = _build_delta_grid_3p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 17.0}]
		"QUAD_4LANE_2V2", "QUAD_2V2":
			slot_defs = _build_quad_4lane_2v2(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3(0.0, 0.0, 0.0), "radius": 16.0},
				{"pos": Vector3(-50.0, 0.0, 0.0), "radius": 11.0},
				{"pos": Vector3(50.0, 0.0, 0.0), "radius": 11.0}
			]
		"X_CROSSROADS_4P":
			slot_defs = _build_x_crossroads_4p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 18.0}]
		"PENTAGON_5P":
			slot_defs = _build_pentagon_5p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 18.0}]
		"CROWN_RIDGE_5P":
			slot_defs = _build_crown_ridge_5p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 18.0}]
		"HEX_STAR_6P", "HEX_3V3":
			slot_defs = _build_hex_star_6p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 20.0}]
		"SERPENT_RIVER_6P":
			slot_defs = _build_serpent_river_6p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3(0.0, 0.0, 0.0), "radius": 18.0},
				{"pos": Vector3(0.0, 0.0, 56.0), "radius": 12.0},
				{"pos": Vector3(0.0, 0.0, -56.0), "radius": 12.0}
			]
		"OCTA_WEB_8P":
			slot_defs = _build_octa_web_8p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 21.0}]
		"TWIN_SQUARE_8P":
			slot_defs = _build_twin_square_8p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 19.0},
				{"pos": Vector3(-62.0, 0.0, 0.0), "radius": 11.0},
				{"pos": Vector3(62.0, 0.0, 0.0), "radius": 11.0}
			]
		"TRI_FORTRESS_9P":
			slot_defs = _build_tri_fortress_9p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 22.0}]
		"HOURGLASS_10P":
			slot_defs = _build_hourglass_10p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 20.0},
				{"pos": Vector3(-126.0, 0.0, 0.0), "radius": 13.0},
				{"pos": Vector3(126.0, 0.0, 0.0), "radius": 13.0}
			]
		"CLOVER_CROSS_12P":
			slot_defs = _build_clover_cross_12p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 22.0},
				{"pos": Vector3(0.0, 0.0, 74.0), "radius": 12.0},
				{"pos": Vector3(0.0, 0.0, -74.0), "radius": 12.0},
				{"pos": Vector3(74.0, 0.0, 0.0), "radius": 12.0},
				{"pos": Vector3(-74.0, 0.0, 0.0), "radius": 12.0}
			]
		"LABYRINTH_16P":
			slot_defs = _build_labyrinth_16p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 22.0},
				{"pos": Vector3(98.0, 0.0, 0.0), "radius": 12.0},
				{"pos": Vector3(-98.0, 0.0, 0.0), "radius": 12.0},
				{"pos": Vector3(0.0, 0.0, 98.0), "radius": 12.0},
				{"pos": Vector3(0.0, 0.0, -98.0), "radius": 12.0}
			]
		"PENTAGRAM_RING_20P":
			slot_defs = _build_pentagram_ring_20p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 24.0}]
			for p_i in range(5):
				var ang: float = deg_to_rad(float(p_i) * 72.0 - 90.0)
				koth_positions.append({"pos": Vector3(cos(ang) * 95.0, 0.0, sin(ang) * 95.0), "radius": 13.0})
		"MEGA_MANDALA_25P":
			slot_defs = _build_mega_mandala_25p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 26.0}]
			for p_i in range(5):
				var ang: float = deg_to_rad(float(p_i) * 72.0 - 90.0)
				koth_positions.append({"pos": Vector3(cos(ang) * 145.0, 0.0, sin(ang) * 145.0), "radius": 14.0})
		"GRID_NEXUS_25P":
			slot_defs = _build_grid_nexus_25p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 22.0},
				{"pos": Vector3(-60.0, 0.0, -60.0), "radius": 12.0},
				{"pos": Vector3(60.0, 0.0, -60.0), "radius": 12.0},
				{"pos": Vector3(-60.0, 0.0, 60.0), "radius": 12.0},
				{"pos": Vector3(60.0, 0.0, 60.0), "radius": 12.0}
			]
		"ASYM_SIEGE_3P":
			slot_defs = _build_asym_siege_3p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 16.0}]
		"ASYM_TRIDENT_4P":
			slot_defs = _build_asym_trident_4p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 17.0}]
		"ASYM_FRONTLINE_5P":
			slot_defs = _build_asym_frontline_5p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 17.0}]
		"ASYM_CITADEL_6P":
			slot_defs = _build_asym_citadel_6p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 18.0},
				{"pos": Vector3(0.0, 0.0, -56.0), "radius": 12.0},
				{"pos": Vector3(0.0, 0.0, 56.0), "radius": 12.0}
			]
		"ASYM_WEDGE_8P":
			slot_defs = _build_asym_wedge_8p(ground, arch_root, total_slots)
			koth_positions = [{"pos": Vector3.ZERO, "radius": 19.0}]
		"ASYM_GRID_10P":
			slot_defs = _build_asym_grid_10p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 18.0},
				{"pos": Vector3(-72.0, 0.0, 20.0), "radius": 12.0},
				{"pos": Vector3(72.0, 0.0, 20.0), "radius": 12.0}
			]
		"ASYM_CRESCENT_12P":
			slot_defs = _build_asym_crescent_12p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 20.0},
				{"pos": Vector3(-72.0, 0.0, 0.0), "radius": 12.0},
				{"pos": Vector3(72.0, 0.0, 0.0), "radius": 12.0}
			]
		"ASYM_FORTRESS_16P":
			slot_defs = _build_asym_fortress_16p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 20.0},
				{"pos": Vector3(-60.0, 0.0, -72.0), "radius": 12.0},
				{"pos": Vector3(-60.0, 0.0, 72.0), "radius": 12.0}
			]
		"ASYM_SANCTUARY_20P":
			slot_defs = _build_asym_sanctuary_20p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3(0.0, 0.0, 25.0), "radius": 20.0},
				{"pos": Vector3(-120.0, 0.0, 25.0), "radius": 13.0},
				{"pos": Vector3(120.0, 0.0, 25.0), "radius": 13.0}
			]
		"ASYM_SIEGE_25P":
			slot_defs = _build_asym_siege_25p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3(0.0, 0.0, 48.0), "radius": 22.0},
				{"pos": Vector3(-96.0, 0.0, 48.0), "radius": 13.0},
				{"pos": Vector3(96.0, 0.0, 48.0), "radius": 13.0},
				{"pos": Vector3(-192.0, 0.0, 48.0), "radius": 12.0},
				{"pos": Vector3(192.0, 0.0, 48.0), "radius": 12.0}
			]
		"ASYM_MANDALA_25P":
			slot_defs = _build_asym_mandala_25p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 24.0},
				{"pos": Vector3(-85.0, 0.0, -45.0), "radius": 13.0},
				{"pos": Vector3(85.0, 0.0, -45.0), "radius": 13.0},
				{"pos": Vector3(-85.0, 0.0, 45.0), "radius": 13.0},
				{"pos": Vector3(85.0, 0.0, 45.0), "radius": 13.0}
			]
		"ASYM_GRID_25P":
			slot_defs = _build_asym_grid_25p(ground, arch_root, total_slots)
			koth_positions = [
				{"pos": Vector3.ZERO, "radius": 22.0},
				{"pos": Vector3(-60.0, 0.0, -60.0), "radius": 12.0},
				{"pos": Vector3(-60.0, 0.0, 60.0), "radius": 12.0},
				{"pos": Vector3(0.0, 0.0, -120.0), "radius": 12.0},
				{"pos": Vector3(0.0, 0.0, 120.0), "radius": 12.0}
			]
		_:
			slot_defs = _build_classic_1v1(ground, arch_root, total_slots)

	total_slots = mini(total_slots, slot_defs.size())
	var asym_small: int = int(entry.get("asym_small_count", 0))
	var eff_req_comp: String = requested_comp
	if asym_small > 0 and asym_small < total_slots:
		var comp_up: String = eff_req_comp.to_upper()
		if (comp_up == "2_TEAMS" or comp_up == "" or comp_up == "AUTO") and not GameState.is_ffa_mode():
			eff_req_comp = "ASYM_" + str(asym_small) + "V" + str(total_slots - asym_small)
			GameState.team_comp = eff_req_comp
		elif comp_up.begins_with("ASYM_"):
			var sp_parts: PackedStringArray = comp_up.trim_prefix("ASYM_").split("V")
			if sp_parts.size() == 2:
				var n0: int = sp_parts[0].to_int()
				var n1: int = sp_parts[1].to_int()
				# If player chose the larger side first (e.g. ASYM_20V5 on a 5v20 map),
				# rotate slot_defs so SideA gets the larger side's bases and SideB gets the smaller side's bases!
				if n0 > n1 and n1 > 0 and n1 < slot_defs.size():
					var reordered: Array[Dictionary] = []
					for idx in range(n1, slot_defs.size()):
						reordered.append(slot_defs[idx])
					for idx in range(0, n1):
						reordered.append(slot_defs[idx])
					slot_defs = reordered

	GameState.match_player_count = total_slots
	var teams_for_slots: Array[String] = GameState.get_teams_for_slots(total_slots, eff_req_comp)
	var unique_teams: Array[String] = []
	for t: String in teams_for_slots:
		if not unique_teams.has(t):
			unique_teams.append(t)
	GameState.active_match_teams = unique_teams

	# Spawn Bases and Towers for each slot
	for i in range(total_slots):
		var sdef: Dictionary = slot_defs[i]
		var slot_team: String = teams_for_slots[i]
		_spawn_slot_citadel(arena, i, slot_team, sdef, false)

	# Spawn KotH Zones
	for k_idx in range(koth_positions.size()):
		var k_info: Dictionary = koth_positions[k_idx]
		var k_name: String = "KotH_Zone" if k_idx == 0 else ("KotH_Zone_" + str(k_idx))
		var k_pos: Vector3 = k_info["pos"]
		_spawn_koth_zone(arena, k_name, k_pos, float(k_info["radius"]), GameState.is_koth_mode())

	# Pre-bake the 2D spatial lane grid so units & environments don't loop over lane segments every frame
	GameState.bake_lane_spatial_grid()

	return {
		"layout_id": layout_id,
		"total_slots": total_slots,
		"teams_for_slots": teams_for_slots,
		"slot_defs": slot_defs,
		"arena_radius": arena_radius,
		"ground_size": ground_size
	}


static func _add_lane_segment(ground: Node3D, a: Vector3, b: Vector3, width: float = 22.0, idx_hint: int = -1) -> void:
	var seg_a := Vector3(a.x, 0.0, a.z)
	var seg_b := Vector3(b.x, 0.0, b.z)
	GameState.lane_segments.append({"a": seg_a, "b": seg_b, "width": width})

	if ground == null:
		return
	var diff: Vector3 = seg_b - seg_a
	var len_val: float = diff.length()
	if len_val < 0.5:
		return

	var mid: Vector3 = (seg_a + seg_b) * 0.5
	var yaw: float = atan2(diff.x, diff.z)
	var p_inst := MeshInstance3D.new()
	var seg_id: int = idx_hint if idx_hint >= 0 else GameState.lane_segments.size()
	p_inst.name = "Path_" + str(seg_id)
	var pm := PlaneMesh.new()
	pm.size = Vector2(width, len_val + width * 0.25)
	var p_mat := StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.38, 0.27, 0.16)
	p_mat.roughness = 0.88
	pm.material = p_mat
	p_inst.mesh = pm
	p_inst.position = Vector3(mid.x, 0.04 + float(seg_id % 5) * 0.002, mid.z)
	p_inst.rotation.y = yaw
	ground.add_child(p_inst)

static func _add_ring_lanes(ground: Node3D, center: Vector3, radius: float, sides: int, width: float = 18.0, start_angle: float = 0.0) -> void:
	if sides < 3: return
	for i in range(sides):
		var a1: float = start_angle + (TAU / float(sides)) * float(i)
		var a2: float = start_angle + (TAU / float(sides)) * float(i + 1)
		var p1: Vector3 = center + Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
		var p2: Vector3 = center + Vector3(cos(a2) * radius, 0.0, sin(a2) * radius)
		_add_lane_segment(ground, p1, p2, width)

static func _create_barrier_wall(arch_root: Node3D, pos: Vector3, size: Vector3, yaw: float, col: Color, emissive: bool = false) -> void:
	var body := StaticBody3D.new()
	body.name = "BarrierWall_" + str(arch_root.get_child_count())
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	body.rotation.y = yaw

	var cshape := CollisionShape3D.new()
	var box_s := BoxShape3D.new()
	box_s.size = size
	cshape.shape = box_s
	cshape.position.y = size.y * 0.5
	body.add_child(cshape)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.55
	mat.metallic = 0.35
	if emissive:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.2
	mi.material_override = mat
	mi.position.y = size.y * 0.5
	body.add_child(mi)
	arch_root.add_child(body)

static func _create_decorative_trench_or_plinth(arch_root: Node3D, pos: Vector3, radius_or_w: float, length_z: float, height_y: float, col: Color, is_cylinder: bool = true, is_glowing: bool = false) -> void:
	var mi := MeshInstance3D.new()
	mi.position = pos
	if is_cylinder:
		var cm := CylinderMesh.new()
		cm.top_radius = radius_or_w
		cm.bottom_radius = radius_or_w * 1.04
		cm.height = height_y
		mi.mesh = cm
	else:
		var bm := BoxMesh.new()
		bm.size = Vector3(radius_or_w, height_y, length_z)
		mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.4
	if is_glowing:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.6
	mi.material_override = mat
	arch_root.add_child(mi)

static func _spawn_slot_citadel(arena: Node3D, slot_idx: int, slot_team: String, sdef: Dictionary, use_legacy_1v1_names: bool = false) -> void:
	var base_pos: Vector3 = sdef["base_pos"]
	var fwd: Vector3 = sdef["fwd"]
	var right: Vector3 = Vector3(-fwd.z, 0.0, fwd.x).normalized()
	var yaw: float = atan2(fwd.x, fwd.z)

	var base_node := CSGBox3D.new()
	if use_legacy_1v1_names:
		base_node.name = "PlayerBase" if slot_idx == 0 else "EnemyBase"
	else:
		base_node.name = "Base_" + str(slot_idx)
	base_node.use_collision = true
	base_node.size = Vector3(10.0, 5.0, 10.0)
	base_node.position = Vector3(base_pos.x, 2.5, base_pos.z)
	base_node.rotation.y = yaw
	base_node.set_meta("slot_index", slot_idx)
	base_node.add_to_group(slot_team)
	base_node.add_to_group("Targetable")
	arena.add_child(base_node)

	var hc := HealthComponentScript.new()
	hc.name = "HealthComponent"
	hc.max_health = 2000.0
	base_node.add_child(hc)

	var t_left_pos: Vector3 = sdef.get("tower_left_pos", base_pos + fwd * 30.0 - right * 14.0)
	var t_right_pos: Vector3 = sdef.get("tower_right_pos", base_pos + fwd * 30.0 + right * 14.0)
	var t_positions: Array[Vector3] = [t_left_pos, t_right_pos]
	var t_suffixes: Array[String] = ["Left", "Right"]

	for t_i in range(2):
		var tower: Node3D = TowerScene.instantiate() as Node3D
		if use_legacy_1v1_names:
			tower.name = ("PlayerTower" if slot_idx == 0 else "EnemyTower") + t_suffixes[t_i]
		else:
			tower.name = "Tower_" + str(slot_idx) + "_" + t_suffixes[t_i]
		if tower.get_script() == null:
			tower.set_script(TowerScript)
		tower.set("projectile_scene", ProjectileScene)
		tower.set("team", slot_team)
		tower.position = Vector3(t_positions[t_i].x, 0.0, t_positions[t_i].z)
		tower.rotation.y = yaw
		tower.set_meta("slot_index", slot_idx)
		tower.add_to_group(slot_team)
		arena.add_child(tower)

static func _spawn_koth_zone(arena: Node3D, zone_name: String, pos: Vector3, radius: float, is_vis: bool) -> void:
	var zone := Area3D.new()
	zone.name = zone_name
	zone.position = pos
	zone.visible = is_vis
	zone.set_meta("koth_radius", radius)
	zone.add_to_group("KotHZones")
	arena.add_child(zone)

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cyl_s := CylinderShape3D.new()
	cyl_s.radius = radius
	cyl_s.height = 10.0
	col.shape = cyl_s
	col.position = Vector3(0.0, 2.5, 0.0)
	zone.add_child(col)

	var csg := CSGCylinder3D.new()
	csg.name = "CSGCylinder3D"
	csg.radius = radius
	csg.height = 0.2
	csg.sides = 32
	csg.position = Vector3(0.0, 0.1, 0.0)
	var k_mat := StandardMaterial3D.new()
	k_mat.albedo_color = Color(1.0, 0.82, 0.05, 0.32)
	k_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	k_mat.emission_enabled = true
	k_mat.emission = Color(1.0, 0.80, 0.08)
	k_mat.emission_energy_multiplier = 0.65
	csg.material = k_mat
	zone.add_child(csg)

# =============================================================================
# 19 MAP LAYOUTS & FUNKY / GRID VARIATIONS (2 PLAYERS UP TO 25 PLAYERS)
# =============================================================================

static func _build_classic_1v1(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	_add_lane_segment(ground, Vector3(0.0, 0.0, -82.0), Vector3(0.0, 0.0, 82.0), 26.0)
	return [
		{
			"base_pos": Vector3(0.0, 0.0, 80.0),
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(-15.0, 0.0, 40.0),
			"tower_right_pos": Vector3(15.0, 0.0, 40.0)
		},
		{
			"base_pos": Vector3(0.0, 0.0, -80.0),
			"fwd": Vector3(0.0, 0.0, 1.0),
			"tower_left_pos": Vector3(-15.0, 0.0, -40.0),
			"tower_right_pos": Vector3(15.0, 0.0, -40.0)
		}
	]

static func _build_canyon_1v1(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# Twin-Bridge Abyssal Canyon: 2 parallel bridge highways at X = -36 and X = +36 + diagonal catwalks to central KotH island
	_add_lane_segment(ground, Vector3(-36.0, 0.0, -76.0), Vector3(-36.0, 0.0, 76.0), 20.0)
	_add_lane_segment(ground, Vector3(36.0, 0.0, -76.0), Vector3(36.0, 0.0, 76.0), 20.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, 84.0), Vector3(-36.0, 0.0, 62.0), 18.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, 84.0), Vector3(36.0, 0.0, 62.0), 18.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, -84.0), Vector3(-36.0, 0.0, -62.0), 18.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, -84.0), Vector3(36.0, 0.0, -62.0), 18.0)
	_add_lane_segment(ground, Vector3(-36.0, 0.0, 0.0), Vector3(36.0, 0.0, 0.0), 18.0)

	# Abyssal Chasm visual trenches & bridge blockers between the bridges and center island
	_create_barrier_wall(arch_root, Vector3(-18.0, 0.0, 18.0), Vector3(14.0, 2.8, 8.0), 0.0, Color(0.14, 0.08, 0.22), true)
	_create_barrier_wall(arch_root, Vector3(18.0, 0.0, 18.0), Vector3(14.0, 2.8, 8.0), 0.0, Color(0.14, 0.08, 0.22), true)
	_create_barrier_wall(arch_root, Vector3(-18.0, 0.0, -18.0), Vector3(14.0, 2.8, 8.0), 0.0, Color(0.14, 0.08, 0.22), true)
	_create_barrier_wall(arch_root, Vector3(18.0, 0.0, -18.0), Vector3(14.0, 2.8, 8.0), 0.0, Color(0.14, 0.08, 0.22), true)

	return [
		{
			"base_pos": Vector3(0.0, 0.0, 86.0),
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(-36.0, 0.0, 48.0),
			"tower_right_pos": Vector3(36.0, 0.0, 48.0)
		},
		{
			"base_pos": Vector3(0.0, 0.0, -86.0),
			"fwd": Vector3(0.0, 0.0, 1.0),
			"tower_left_pos": Vector3(-36.0, 0.0, -48.0),
			"tower_right_pos": Vector3(36.0, 0.0, -48.0)
		}
	]

static func _build_triskelion_3p(ground: Node3D, arch_root: Node3D, total_slots: int) -> Array[Dictionary]:
	# 3-Wing Triskelion Spiral: 3 radial/spiral arms + outer triangular ring highway
	var slots: Array[Dictionary] = []
	var count: int = maxi(3, total_slots)
	var base_r: float = 98.0
	for i in range(count):
		var ang: float = deg_to_rad(float(i) * (360.0 / float(count)) + 90.0)
		var b_pos := Vector3(cos(ang) * base_r, 0.0, sin(ang) * base_r)
		var fwd: Vector3 = (-b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		var elbow := Vector3(cos(ang + 0.26) * 46.0, 0.0, sin(ang + 0.26) * 46.0)
		_add_lane_segment(ground, b_pos, elbow, 20.0)
		_add_lane_segment(ground, elbow, Vector3.ZERO, 20.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 28.0 - right * 13.0,
			"tower_right_pos": b_pos + fwd * 28.0 + right * 13.0
		})
	_add_ring_lanes(ground, Vector3.ZERO, 66.0, count, 16.0, deg_to_rad(90.0))
	_create_decorative_trench_or_plinth(arch_root, Vector3(0.0, 0.02, 0.0), 22.0, 22.0, 0.06, Color(0.28, 0.22, 0.36), true, false)
	return slots

static func _build_delta_grid_3p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 3-Player Delta Tri-Grid Citadel: Outer triangle + inner inverted triangle + 6 grid-like cross connectors
	var slots: Array[Dictionary] = []
	var base_r: float = 104.0
	var outer_pts: Array[Vector3] = []
	var mid_pts: Array[Vector3] = []
	for i in range(3):
		var ang: float = deg_to_rad(float(i) * 120.0 - 90.0)
		var b_pos := Vector3(cos(ang) * base_r, 0.0, sin(ang) * base_r)
		outer_pts.append(b_pos)
		var fwd: Vector3 = (-b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, b_pos, Vector3.ZERO, 20.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 28.0 - right * 14.0,
			"tower_right_pos": b_pos + fwd * 28.0 + right * 14.0
		})
	for i in range(3):
		var p1: Vector3 = outer_pts[i]
		var p2: Vector3 = outer_pts[(i + 1) % 3]
		_add_lane_segment(ground, p1, p2, 16.0)
		mid_pts.append((p1 + p2) * 0.5)
	for i in range(3):
		_add_lane_segment(ground, mid_pts[i], mid_pts[(i + 1) % 3], 16.0)
		var wall_ang: float = deg_to_rad(float(i) * 120.0 + 30.0)
		_create_barrier_wall(arch_root, Vector3(cos(wall_ang) * 34.0, 0.0, sin(wall_ang) * 34.0), Vector3(10.0, 3.0, 6.0), wall_ang, Color(0.24, 0.30, 0.38), true)
	return slots

static func _build_quad_4lane_2v2(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 2v2 / 4P 4-Lane Quad Parallel Bastion:
	# 4 distinct parallel North-South lanes at X = -75, -25, +25, +75
	# Plus North & South deployment boulevards and 3 horizontal cross-connectors!
	var lane_xs: Array[float] = [-75.0, -25.0, 25.0, 75.0]
	for lx: float in lane_xs:
		_add_lane_segment(ground, Vector3(lx, 0.0, -96.0), Vector3(lx, 0.0, 96.0), 20.0)

	# Horizontal cross-lanes connecting the 4 lanes
	_add_lane_segment(ground, Vector3(-75.0, 0.0, 92.0), Vector3(75.0, 0.0, 92.0), 18.0)
	_add_lane_segment(ground, Vector3(-75.0, 0.0, -92.0), Vector3(75.0, 0.0, -92.0), 18.0)
	_add_lane_segment(ground, Vector3(-75.0, 0.0, 0.0), Vector3(75.0, 0.0, 0.0), 20.0)
	_add_lane_segment(ground, Vector3(-75.0, 0.0, 36.0), Vector3(75.0, 0.0, 36.0), 14.0)
	_add_lane_segment(ground, Vector3(-75.0, 0.0, -36.0), Vector3(75.0, 0.0, -36.0), 14.0)

	# Raised canyon lane dividers between the 4 lanes (leaving cross-avenues open)
	var div_xs: Array[float] = [-50.0, 0.0, 50.0]
	var div_zs: Array[float] = [-64.0, -18.0, 18.0, 64.0]
	for div_x: float in div_xs:
		for div_z: float in div_zs:
			if absf(div_x) < 1.0 and absf(div_z) < 25.0:
				continue # Keep central KotH plaza open
			_create_barrier_wall(arch_root, Vector3(div_x, 0.0, div_z), Vector3(6.0, 2.6, 16.0), 0.0, Color(0.24, 0.26, 0.32), false)

	return [
		{
			"base_pos": Vector3(-50.0, 0.0, 95.0),
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(-75.0, 0.0, 58.0),
			"tower_right_pos": Vector3(-25.0, 0.0, 58.0)
		},
		{
			"base_pos": Vector3(50.0, 0.0, 95.0),
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(25.0, 0.0, 58.0),
			"tower_right_pos": Vector3(75.0, 0.0, 58.0)
		},
		{
			"base_pos": Vector3(-50.0, 0.0, -95.0),
			"fwd": Vector3(0.0, 0.0, 1.0),
			"tower_left_pos": Vector3(-75.0, 0.0, -58.0),
			"tower_right_pos": Vector3(-25.0, 0.0, -58.0)
		},
		{
			"base_pos": Vector3(50.0, 0.0, -95.0),
			"fwd": Vector3(0.0, 0.0, 1.0),
			"tower_left_pos": Vector3(25.0, 0.0, -58.0),
			"tower_right_pos": Vector3(75.0, 0.0, -58.0)
		}
	]

static func _build_x_crossroads_4p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# Diagonal X-Blade Crossroads with Diamond perimeter ring
	var angles: Array[float] = [deg_to_rad(45.0), deg_to_rad(135.0), deg_to_rad(225.0), deg_to_rad(315.0)]
	var slots: Array[Dictionary] = []
	var rad: float = 112.0
	for ang: float in angles:
		var b_pos := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		var fwd: Vector3 = (-b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, b_pos, Vector3.ZERO, 22.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 30.0 - right * 14.0,
			"tower_right_pos": b_pos + fwd * 30.0 + right * 14.0
		})
	_add_ring_lanes(ground, Vector3.ZERO, 76.0, 4, 16.0, deg_to_rad(45.0))
	var cardinals: Array[float] = [0.0, PI * 0.5, PI, PI * 1.5]
	for cardinal: float in cardinals:
		var p_wall := Vector3(cos(cardinal) * 44.0, 0.0, sin(cardinal) * 44.0)
		_create_barrier_wall(arch_root, p_wall, Vector3(10.0, 3.2, 10.0), cardinal, Color(0.32, 0.14, 0.22), true)
	return slots

static func _build_pentagon_5p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var rad: float = 118.0
	var pts: Array[Vector3] = []
	for i in range(5):
		var ang: float = deg_to_rad(float(i) * 72.0 - 90.0)
		var b_pos := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		pts.append(b_pos)
		var fwd: Vector3 = (-b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, b_pos, Vector3.ZERO, 20.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 30.0 - right * 14.0,
			"tower_right_pos": b_pos + fwd * 30.0 + right * 14.0
		})
	# Pentagram star chords + inner pentagon ring
	for i in range(5):
		_add_lane_segment(ground, pts[i] * 0.72, pts[(i + 2) % 5] * 0.72, 14.0)
	_add_ring_lanes(ground, Vector3.ZERO, 68.0, 5, 16.0, deg_to_rad(-90.0))
	return slots

static func _build_crown_ridge_5p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 5-Player 5-Spire Crown Canyon: 3 North Crown Citadels + 2 South Canyon Citadels with grid-like cross bridges
	var slots: Array[Dictionary] = []
	var crown_positions: Array[Vector3] = [
		Vector3(-96.0, 0.0, 102.0),
		Vector3(0.0, 0.0, 118.0),
		Vector3(96.0, 0.0, 102.0),
		Vector3(-76.0, 0.0, -106.0),
		Vector3(76.0, 0.0, -106.0)
	]
	for b_pos: Vector3 in crown_positions:
		var fwd: Vector3 = (-b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, b_pos, Vector3.ZERO, 20.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 28.0 - right * 13.5,
			"tower_right_pos": b_pos + fwd * 28.0 + right * 13.5
		})
	_add_lane_segment(ground, Vector3(-96.0, 0.0, 62.0), Vector3(96.0, 0.0, 62.0), 18.0)
	_add_lane_segment(ground, Vector3(-76.0, 0.0, -62.0), Vector3(76.0, 0.0, -62.0), 18.0)
	_add_lane_segment(ground, Vector3(-86.0, 0.0, -62.0), Vector3(-86.0, 0.0, 62.0), 16.0)
	_add_lane_segment(ground, Vector3(86.0, 0.0, -62.0), Vector3(86.0, 0.0, 62.0), 16.0)
	_create_barrier_wall(arch_root, Vector3(-42.0, 0.0, 18.0), Vector3(14.0, 3.2, 8.0), 0.3, Color(0.32, 0.24, 0.18), true)
	_create_barrier_wall(arch_root, Vector3(42.0, 0.0, 18.0), Vector3(14.0, 3.2, 8.0), -0.3, Color(0.32, 0.24, 0.18), true)
	return slots

static func _build_hex_star_6p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var rad: float = 120.0
	for i in range(6):
		var ang: float = deg_to_rad(float(i) * 60.0 + 90.0)
		var b_pos := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		var fwd: Vector3 = (-b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, b_pos, Vector3.ZERO, 22.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 30.0 - right * 15.0,
			"tower_right_pos": b_pos + fwd * 30.0 + right * 15.0
		})
	_add_ring_lanes(ground, Vector3.ZERO, 68.0, 6, 16.0, deg_to_rad(90.0))
	return slots

static func _build_serpent_river_6p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 3v3 / 6P Serpentine S-Curve Delta: 3 West citadels & 3 East citadels connected by winding S-curve lanes
	var west_zs: Array[float] = [-78.0, 0.0, 78.0]
	var east_zs: Array[float] = [-78.0, 0.0, 78.0]
	var slots: Array[Dictionary] = []

	for wz: float in west_zs:
		var b_pos := Vector3(-124.0, 0.0, wz)
		var fwd := Vector3(1.0, 0.0, 0.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": Vector3(-92.0, 0.0, wz - 13.0),
			"tower_right_pos": Vector3(-92.0, 0.0, wz + 13.0)
		})
	for ez: float in east_zs:
		var b_pos := Vector3(124.0, 0.0, ez)
		var fwd := Vector3(-1.0, 0.0, 0.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": Vector3(92.0, 0.0, ez - 13.0),
			"tower_right_pos": Vector3(92.0, 0.0, ez + 13.0)
		})

	# 3 Serpentine S-Curve highways weaving across the delta
	var row_zs: Array[float] = [-78.0, 0.0, 78.0]
	for row_z: float in row_zs:
		var p0 := Vector3(-124.0, 0.0, row_z)
		var p1 := Vector3(-62.0, 0.0, row_z + 24.0)
		var p2 := Vector3(0.0, 0.0, row_z * 0.72)
		var p3 := Vector3(62.0, 0.0, row_z - 24.0)
		var p4 := Vector3(124.0, 0.0, row_z)
		_add_lane_segment(ground, p0, p1, 20.0)
		_add_lane_segment(ground, p1, p2, 20.0)
		_add_lane_segment(ground, p2, p3, 20.0)
		_add_lane_segment(ground, p3, p4, 20.0)

	# North-South cross bridges connecting the 3 island hubs
	_add_lane_segment(ground, Vector3(0.0, 0.0, -68.0), Vector3(0.0, 0.0, 68.0), 18.0)
	_add_lane_segment(ground, Vector3(-95.0, 0.0, -78.0), Vector3(-95.0, 0.0, 78.0), 16.0)
	_add_lane_segment(ground, Vector3(95.0, 0.0, -78.0), Vector3(95.0, 0.0, 78.0), 16.0)

	_create_barrier_wall(arch_root, Vector3(-34.0, 0.0, -34.0), Vector3(12.0, 2.8, 12.0), 0.4, Color(0.16, 0.34, 0.42), true)
	_create_barrier_wall(arch_root, Vector3(34.0, 0.0, 34.0), Vector3(12.0, 2.8, 12.0), -0.4, Color(0.16, 0.34, 0.42), true)
	return slots

static func _build_octa_web_8p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var rad: float = 138.0
	for i in range(8):
		var ang: float = deg_to_rad(float(i) * 45.0 + 22.5)
		var b_pos := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		var fwd: Vector3 = (-b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, b_pos, Vector3.ZERO, 20.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 30.0 - right * 14.0,
			"tower_right_pos": b_pos + fwd * 30.0 + right * 14.0
		})
	_add_ring_lanes(ground, Vector3.ZERO, 54.0, 8, 16.0, deg_to_rad(22.5))
	_add_ring_lanes(ground, Vector3.ZERO, 102.0, 8, 16.0, deg_to_rad(22.5))
	for i in range(8):
		var pillar_ang: float = deg_to_rad(float(i) * 45.0)
		var p_pos := Vector3(cos(pillar_ang) * 76.0, 0.0, sin(pillar_ang) * 76.0)
		_create_barrier_wall(arch_root, p_pos, Vector3(6.5, 3.5, 6.5), pillar_ang, Color(0.28, 0.24, 0.34), false)
	return slots

static func _build_twin_square_8p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 4v4 / 8P Twin-Square Grid Fortress: 4 North & 4 South citadels on a 4x4 orthogonal + diagonal grid
	var slots: Array[Dictionary] = []
	var grid_lines: Array[float] = [-124.0, -42.0, 42.0, 124.0]
	for g_coord: float in grid_lines:
		_add_lane_segment(ground, Vector3(g_coord, 0.0, -138.0), Vector3(g_coord, 0.0, 138.0), 18.0)
		_add_lane_segment(ground, Vector3(-138.0, 0.0, g_coord), Vector3(138.0, 0.0, g_coord), 18.0)
	_add_lane_segment(ground, Vector3(-124.0, 0.0, -124.0), Vector3(124.0, 0.0, 124.0), 16.0)
	_add_lane_segment(ground, Vector3(-124.0, 0.0, 124.0), Vector3(124.0, 0.0, -124.0), 16.0)

	for gx: float in grid_lines:
		var b_north := Vector3(gx, 0.0, 132.0)
		slots.append({
			"base_pos": b_north,
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(gx - 12.0, 0.0, 98.0),
			"tower_right_pos": Vector3(gx + 12.0, 0.0, 98.0)
		})
	for gx: float in grid_lines:
		var b_south := Vector3(gx, 0.0, -132.0)
		slots.append({
			"base_pos": b_south,
			"fwd": Vector3(0.0, 0.0, 1.0),
			"tower_left_pos": Vector3(gx - 12.0, 0.0, -98.0),
			"tower_right_pos": Vector3(gx + 12.0, 0.0, -98.0)
		})

	_create_barrier_wall(arch_root, Vector3(0.0, 0.0, 68.0), Vector3(16.0, 3.0, 8.0), 0.0, Color(0.22, 0.28, 0.36), true)
	_create_barrier_wall(arch_root, Vector3(0.0, 0.0, -68.0), Vector3(16.0, 3.0, 8.0), 0.0, Color(0.22, 0.28, 0.36), true)
	return slots

static func _build_tri_fortress_9p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 9-Player Three-Wing Tri-Fortress: 3 massive wings (3 citadels per wing = 9 citadels)
	var slots: Array[Dictionary] = []
	for wing in range(3):
		var wing_ang: float = deg_to_rad(float(wing) * 120.0 + 90.0)
		var wing_dir := Vector3(cos(wing_ang), 0.0, sin(wing_ang))
		var wing_perp := Vector3(-wing_dir.z, 0.0, wing_dir.x)
		var wing_hub: Vector3 = wing_dir * 78.0
		_add_lane_segment(ground, wing_hub, Vector3.ZERO, 24.0)

		var sub_offsets: Array[Vector3] = [
			wing_dir * 150.0,
			wing_dir * 132.0 - wing_perp * 44.0,
			wing_dir * 132.0 + wing_perp * 44.0
		]
		for b_pos: Vector3 in sub_offsets:
			var fwd: Vector3 = (wing_hub - b_pos).normalized()
			var right := Vector3(-fwd.z, 0.0, fwd.x)
			_add_lane_segment(ground, b_pos, wing_hub, 18.0)
			slots.append({
				"base_pos": b_pos,
				"fwd": fwd,
				"tower_left_pos": b_pos + fwd * 28.0 - right * 13.0,
				"tower_right_pos": b_pos + fwd * 28.0 + right * 13.0
			})
	_add_ring_lanes(ground, Vector3.ZERO, 78.0, 3, 18.0, deg_to_rad(90.0))
	return slots

static func _build_hourglass_10p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 10-Player Twin-Vortex Hourglass:
	# 5 North Crescent Citadels + 5 South Crescent Citadels
	# Pinched central hourglass throat + 2 wide outer curved bypass highways!
	var slots: Array[Dictionary] = []
	var xs: Array[float] = [-108.0, -54.0, 0.0, 54.0, 108.0]
	var north_hub := Vector3(0.0, 0.0, 58.0)
	var south_hub := Vector3(0.0, 0.0, -58.0)

	# Central hourglass throat + outer bypass arcs
	_add_lane_segment(ground, south_hub, north_hub, 26.0)
	_add_lane_segment(ground, Vector3(-108.0, 0.0, 96.0), Vector3(-128.0, 0.0, 0.0), 18.0)
	_add_lane_segment(ground, Vector3(-128.0, 0.0, 0.0), Vector3(-108.0, 0.0, -96.0), 18.0)
	_add_lane_segment(ground, Vector3(108.0, 0.0, 96.0), Vector3(128.0, 0.0, 0.0), 18.0)
	_add_lane_segment(ground, Vector3(128.0, 0.0, 0.0), Vector3(108.0, 0.0, -96.0), 18.0)
	_add_lane_segment(ground, Vector3(-128.0, 0.0, 0.0), Vector3(128.0, 0.0, 0.0), 16.0)

	# Hourglass pinch canyon wedges on either side of the central throat
	_create_barrier_wall(arch_root, Vector3(-56.0, 0.0, 22.0), Vector3(36.0, 3.8, 12.0), 0.35, Color(0.28, 0.18, 0.22), false)
	_create_barrier_wall(arch_root, Vector3(-56.0, 0.0, -22.0), Vector3(36.0, 3.8, 12.0), -0.35, Color(0.28, 0.18, 0.22), false)
	_create_barrier_wall(arch_root, Vector3(56.0, 0.0, 22.0), Vector3(36.0, 3.8, 12.0), -0.35, Color(0.28, 0.18, 0.22), false)
	_create_barrier_wall(arch_root, Vector3(56.0, 0.0, -22.0), Vector3(36.0, 3.8, 12.0), 0.35, Color(0.28, 0.18, 0.22), false)

	# North 5 Citadels
	for x_val: float in xs:
		var z_curve: float = 136.0 - absf(x_val) * 0.22
		var b_pos := Vector3(x_val, 0.0, z_curve)
		var target_pt := Vector3(x_val * 0.45, 0.0, 58.0)
		var fwd: Vector3 = (target_pt - b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, b_pos, target_pt, 18.0)
		_add_lane_segment(ground, target_pt, north_hub, 18.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 28.0 - right * 12.5,
			"tower_right_pos": b_pos + fwd * 28.0 + right * 12.5
		})

	# South 5 Citadels
	for x_val: float in xs:
		var z_curve: float = -136.0 + absf(x_val) * 0.22
		var b_pos := Vector3(x_val, 0.0, z_curve)
		var target_pt := Vector3(x_val * 0.45, 0.0, -58.0)
		var fwd: Vector3 = (target_pt - b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, b_pos, target_pt, 18.0)
		_add_lane_segment(ground, target_pt, south_hub, 18.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 28.0 - right * 12.5,
			"tower_right_pos": b_pos + fwd * 28.0 + right * 12.5
		})

	return slots

static func _build_clover_cross_12p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 12-Player 4-Leaf Clover Maltese Cross: 4 giant lobes (3 citadels per lobe = 12 citadels)
	var slots: Array[Dictionary] = []
	for lobe in range(4):
		var lobe_ang: float = deg_to_rad(float(lobe) * 90.0)
		var dir := Vector3(cos(lobe_ang), 0.0, sin(lobe_ang))
		var perp := Vector3(-dir.z, 0.0, dir.x)
		var lobe_hub: Vector3 = dir * 74.0
		_add_lane_segment(ground, lobe_hub, Vector3.ZERO, 24.0)

		var fan_positions: Array[Vector3] = [
			dir * 162.0,
			dir * 144.0 - perp * 48.0,
			dir * 144.0 + perp * 48.0
		]
		for b_pos: Vector3 in fan_positions:
			var fwd: Vector3 = (lobe_hub - b_pos).normalized()
			var right := Vector3(-fwd.z, 0.0, fwd.x)
			_add_lane_segment(ground, b_pos, lobe_hub, 18.0)
			slots.append({
				"base_pos": b_pos,
				"fwd": fwd,
				"tower_left_pos": b_pos + fwd * 28.0 - right * 12.5,
				"tower_right_pos": b_pos + fwd * 28.0 + right * 12.5
			})

	# Diagonal inter-lobe bridges & corner void/water bay dividers
	_add_ring_lanes(ground, Vector3.ZERO, 74.0, 4, 18.0, 0.0)
	_add_ring_lanes(ground, Vector3.ZERO, 132.0, 8, 15.0, deg_to_rad(22.5))
	for c_i in range(4):
		var c_ang: float = deg_to_rad(float(c_i) * 90.0 + 45.0)
		var c_pos := Vector3(cos(c_ang) * 98.0, 0.0, sin(c_ang) * 98.0)
		_create_barrier_wall(arch_root, c_pos, Vector3(18.0, 3.2, 18.0), c_ang, Color(0.14, 0.24, 0.36), true)
	return slots

static func _build_labyrinth_16p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 16-Player Double-Ring Spiral Labyrinth:
	# Outer ring of 12 citadels (R = 192) + Inner vanguard ring of 4 citadels (R = 98 at 45, 135, 225, 315 deg) = 16 citadels!
	var slots: Array[Dictionary] = []
	var outer_r: float = 192.0
	var inner_r: float = 98.0

	for i in range(12):
		var ang: float = deg_to_rad(float(i) * 30.0)
		var b_pos := Vector3(cos(ang) * outer_r, 0.0, sin(ang) * outer_r)
		var mid_pt := Vector3(cos(ang + 0.18) * inner_r, 0.0, sin(ang + 0.18) * inner_r)
		var fwd: Vector3 = (mid_pt - b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, b_pos, mid_pt, 18.0)
		if i % 2 == 0:
			_add_lane_segment(ground, mid_pt, Vector3.ZERO, 18.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 28.0 - right * 12.0,
			"tower_right_pos": b_pos + fwd * 28.0 + right * 12.0
		})

	for j in range(4):
		var ang: float = deg_to_rad(float(j) * 90.0 + 45.0)
		var b_pos := Vector3(cos(ang) * inner_r, 0.0, sin(ang) * inner_r)
		var fwd: Vector3 = (-b_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, b_pos, Vector3.ZERO, 20.0)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 26.0 - right * 12.0,
			"tower_right_pos": b_pos + fwd * 26.0 + right * 12.0
		})

	_add_ring_lanes(ground, Vector3.ZERO, inner_r, 12, 18.0, 0.0)
	_add_ring_lanes(ground, Vector3.ZERO, 152.0, 12, 16.0, deg_to_rad(15.0))

	for w_i in range(6):
		var w_ang: float = deg_to_rad(float(w_i) * 60.0 + 15.0)
		var w_pos := Vector3(cos(w_ang) * 126.0, 0.0, sin(w_ang) * 126.0)
		_create_barrier_wall(arch_root, w_pos, Vector3(16.0, 3.4, 5.0), w_ang + PI * 0.5, Color(0.26, 0.22, 0.34), false)
	return slots

static func _build_pentagram_ring_20p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 20-Player Pentagram 5-Bastion Ring:
	# 5 massive star bastions (4 citadels per bastion = 20 citadels)
	var slots: Array[Dictionary] = []
	var hub_pts: Array[Vector3] = []

	for p_i in range(5):
		var ang: float = deg_to_rad(float(p_i) * 72.0 - 90.0)
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		var perp := Vector3(-dir.z, 0.0, dir.x)
		var bastion_hub: Vector3 = dir * 95.0
		hub_pts.append(bastion_hub)
		_add_lane_segment(ground, bastion_hub, Vector3.ZERO, 22.0)

		var cluster_positions: Array[Vector3] = [
			dir * 228.0 - perp * 28.0,
			dir * 228.0 + perp * 28.0,
			dir * 176.0 - perp * 62.0,
			dir * 176.0 + perp * 62.0
		]
		for b_pos: Vector3 in cluster_positions:
			var fwd: Vector3 = (bastion_hub - b_pos).normalized()
			var right := Vector3(-fwd.z, 0.0, fwd.x)
			_add_lane_segment(ground, b_pos, bastion_hub, 16.0)
			slots.append({
				"base_pos": b_pos,
				"fwd": fwd,
				"tower_left_pos": b_pos + fwd * 26.0 - right * 11.5,
				"tower_right_pos": b_pos + fwd * 26.0 + right * 11.5
			})

	# Pentagram star chords connecting non-adjacent bastion hubs + concentric rings
	for i in range(5):
		_add_lane_segment(ground, hub_pts[i], hub_pts[(i + 2) % 5], 16.0)
	_add_ring_lanes(ground, Vector3.ZERO, 95.0, 5, 18.0, deg_to_rad(-90.0))
	_add_ring_lanes(ground, Vector3.ZERO, 192.0, 10, 16.0, deg_to_rad(-90.0))
	return slots

static func _build_mega_mandala_25p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 25-Player Grand Mandala Colosseum:
	# 5 Lotus Petals, each containing 5 Citadels (3 Outer Petal Citadels + 2 Mid-Ring Bastion Citadels = 5 per petal * 5 = 25 Citadels!)
	var slots: Array[Dictionary] = []

	for petal in range(5):
		var p_ang: float = deg_to_rad(float(petal) * 72.0 - 90.0)
		var dir := Vector3(cos(p_ang), 0.0, sin(p_ang))
		var perp := Vector3(-dir.z, 0.0, dir.x)
		var petal_hub: Vector3 = dir * 145.0
		var inner_hub: Vector3 = dir * 76.0

		_add_lane_segment(ground, petal_hub, inner_hub, 24.0)
		_add_lane_segment(ground, inner_hub, Vector3.ZERO, 24.0)

		var petal_citadels: Array[Vector3] = [
			dir * 276.0,
			dir * 256.0 - perp * 64.0,
			dir * 256.0 + perp * 64.0,
			dir * 182.0 - perp * 52.0,
			dir * 182.0 + perp * 52.0
		]
		for c_idx in range(petal_citadels.size()):
			var b_pos: Vector3 = petal_citadels[c_idx]
			var target_hub: Vector3 = petal_hub if c_idx < 3 else inner_hub
			var fwd: Vector3 = (target_hub - b_pos).normalized()
			var right := Vector3(-fwd.z, 0.0, fwd.x)
			_add_lane_segment(ground, b_pos, target_hub, 16.0)
			slots.append({
				"base_pos": b_pos,
				"fwd": fwd,
				"tower_left_pos": b_pos + fwd * 25.0 - right * 11.0,
				"tower_right_pos": b_pos + fwd * 25.0 + right * 11.0
			})

	# 3 Concentric Mandala Ring Highways + 5 Inter-Petal Bridges
	_add_ring_lanes(ground, Vector3.ZERO, 76.0, 10, 18.0, deg_to_rad(-90.0))
	_add_ring_lanes(ground, Vector3.ZERO, 145.0, 10, 18.0, deg_to_rad(-90.0))
	_add_ring_lanes(ground, Vector3.ZERO, 232.0, 15, 16.0, deg_to_rad(-90.0))

	for m_i in range(5):
		var m_ang: float = deg_to_rad(float(m_i) * 72.0 - 54.0)
		var m_pos := Vector3(cos(m_ang) * 112.0, 0.0, sin(m_ang) * 112.0)
		_create_barrier_wall(arch_root, m_pos, Vector3(14.0, 4.0, 14.0), m_ang, Color(0.32, 0.24, 0.14), true)

	return slots

static func _build_grid_nexus_25p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 25-Player Hyper-Grid Lattice (Paths Everywhere!):
	# A 9x9 orthogonal + diagonal city grid where 9 North-South avenues,
	# 9 East-West avenues, and 6 diagonal avenues crisscross the entire battlefield!
	# 16 Outer Perimeter Grid Citadels + 9 Inner Grid Citadels = 25 Citadels!
	var slots: Array[Dictionary] = []

	var grid_coords: Array[float] = [-240.0, -180.0, -120.0, -60.0, 0.0, 60.0, 120.0, 180.0, 240.0]

	# 9 North-South Grid Highways & 9 East-West Grid Highways (18 full-span grid highways!)
	for gx: float in grid_coords:
		var w_ns: float = 20.0 if (int(round(absf(gx))) % 120 == 0) else 15.0
		_add_lane_segment(ground, Vector3(gx, 0.0, -252.0), Vector3(gx, 0.0, 252.0), w_ns)
	for gz: float in grid_coords:
		var w_ew: float = 20.0 if (int(round(absf(gz))) % 120 == 0) else 15.0
		_add_lane_segment(ground, Vector3(-252.0, 0.0, gz), Vector3(252.0, 0.0, gz), w_ew)

	# 6 Diagonal Cross-Grid Expressways (2 main corner-to-corner + 4 diamond diagonals)
	_add_lane_segment(ground, Vector3(-240.0, 0.0, -240.0), Vector3(240.0, 0.0, 240.0), 16.0)
	_add_lane_segment(ground, Vector3(-240.0, 0.0, 240.0), Vector3(240.0, 0.0, -240.0), 16.0)
	_add_lane_segment(ground, Vector3(-180.0, 0.0, 0.0), Vector3(0.0, 0.0, 180.0), 14.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, 180.0), Vector3(180.0, 0.0, 0.0), 14.0)
	_add_lane_segment(ground, Vector3(180.0, 0.0, 0.0), Vector3(0.0, 0.0, -180.0), 14.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, -180.0), Vector3(-180.0, 0.0, 0.0), 14.0)

	# 25 Grid Node Citadel Positions (all on grid intersections, leaving (0,0) and (±60,±60) clear for KotH Hills):
	# 1) 16 Outer Square Ring Grid Stations at |X|==240 or |Z|==240 (step 120):
	var outer_5: Array[float] = [-240.0, -120.0, 0.0, 120.0, 240.0]
	var citadel_positions: Array[Vector3] = []
	for ox: float in outer_5:
		citadel_positions.append(Vector3(ox, 0.0, 240.0))
	for ox: float in outer_5:
		citadel_positions.append(Vector3(ox, 0.0, -240.0))
	var mid_3: Array[float] = [-120.0, 0.0, 120.0]
	for oz: float in mid_3:
		citadel_positions.append(Vector3(-240.0, 0.0, oz))
	for oz: float in mid_3:
		citadel_positions.append(Vector3(240.0, 0.0, oz))

	# 2) 9 Inner Grid Stations on the (-120, 0, +120) & (0, +180) intersections:
	var inner_9: Array[Vector3] = [
		Vector3(-120.0, 0.0, 120.0),
		Vector3(0.0, 0.0, 120.0),
		Vector3(120.0, 0.0, 120.0),
		Vector3(-120.0, 0.0, 0.0),
		Vector3(120.0, 0.0, 0.0),
		Vector3(-120.0, 0.0, -120.0),
		Vector3(0.0, 0.0, -120.0),
		Vector3(120.0, 0.0, -120.0),
		Vector3(0.0, 0.0, 180.0)
	]
	for ip: Vector3 in inner_9:
		citadel_positions.append(ip)

	for b_pos: Vector3 in citadel_positions:
		var fwd: Vector3 = (-b_pos).normalized()
		if fwd.length_squared() < 0.01:
			fwd = Vector3(0.0, 0.0, -1.0)
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		slots.append({
			"base_pos": b_pos,
			"fwd": fwd,
			"tower_left_pos": b_pos + fwd * 22.0 - right * 11.0,
			"tower_right_pos": b_pos + fwd * 22.0 + right * 11.0
		})

	# Low tactical cyber-plinths at the outer quadrant centers (±150, ±150), well clear of all citadels and streets
	var block_centers: Array[float] = [-150.0, 150.0]
	for bx: float in block_centers:
		for bz: float in block_centers:
			_create_barrier_wall(arch_root, Vector3(bx, 0.0, bz), Vector3(12.0, 2.8, 12.0), 0.0, Color(0.20, 0.28, 0.38), true)

	return slots

# =========================================================================
# ASYMMETRICAL MAPS (3P TO 25P ACROSS SIEGE LANES, MANDALA & HYPER-GRID)
# =========================================================================

static func _build_asym_siege_3p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 1v2 Asymmetric Siege (3P): 1 Fortified South Bastion vs 2 North Raider Bases
	var slots: Array[Dictionary] = []
	var south_base := Vector3(0.0, 0.0, 96.0)
	var north_left := Vector3(-58.0, 0.0, -92.0)
	var north_right := Vector3(58.0, 0.0, -92.0)

	_add_lane_segment(ground, south_base, Vector3(0.0, 0.0, -92.0), 22.0)
	_add_lane_segment(ground, north_left, Vector3.ZERO, 20.0)
	_add_lane_segment(ground, north_right, Vector3.ZERO, 20.0)
	_add_lane_segment(ground, north_left, south_base, 18.0)
	_add_lane_segment(ground, north_right, south_base, 18.0)
	_add_lane_segment(ground, north_left, north_right, 18.0)

	slots.append({
		"base_pos": south_base,
		"fwd": Vector3(0.0, 0.0, -1.0),
		"tower_left_pos": Vector3(-16.0, 0.0, 62.0),
		"tower_right_pos": Vector3(16.0, 0.0, 62.0)
	})
	for n_pos: Vector3 in [north_left, north_right]:
		var fwd: Vector3 = (Vector3.ZERO - n_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		slots.append({
			"base_pos": n_pos,
			"fwd": fwd,
			"tower_left_pos": n_pos + fwd * 30.0 - right * 12.0,
			"tower_right_pos": n_pos + fwd * 30.0 + right * 12.0
		})

	_create_barrier_wall(arch_root, Vector3(-42.0, 0.0, 26.0), Vector3(14.0, 3.2, 6.0), 0.35, Color(0.28, 0.22, 0.20), false)
	_create_barrier_wall(arch_root, Vector3(42.0, 0.0, 26.0), Vector3(14.0, 3.2, 6.0), -0.35, Color(0.28, 0.22, 0.20), false)
	return slots

static func _build_asym_trident_4p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 1v3 Asymmetric Trident Siege (4P): 1 South Citadel vs 3 North Prong Invaders
	var slots: Array[Dictionary] = []
	var south_base := Vector3(0.0, 0.0, 106.0)
	var north_bases: Array[Vector3] = [
		Vector3(-76.0, 0.0, -98.0),
		Vector3(0.0, 0.0, -106.0),
		Vector3(76.0, 0.0, -98.0)
	]

	_add_lane_segment(ground, south_base, Vector3(0.0, 0.0, -106.0), 24.0)
	_add_lane_segment(ground, north_bases[0], Vector3.ZERO, 18.0)
	_add_lane_segment(ground, north_bases[2], Vector3.ZERO, 18.0)
	_add_lane_segment(ground, north_bases[0], Vector3(-48.0, 0.0, 38.0), 18.0)
	_add_lane_segment(ground, Vector3(-48.0, 0.0, 38.0), south_base, 18.0)
	_add_lane_segment(ground, north_bases[2], Vector3(48.0, 0.0, 38.0), 18.0)
	_add_lane_segment(ground, Vector3(48.0, 0.0, 38.0), south_base, 18.0)
	_add_lane_segment(ground, north_bases[0], north_bases[2], 16.0)

	slots.append({
		"base_pos": south_base,
		"fwd": Vector3(0.0, 0.0, -1.0),
		"tower_left_pos": Vector3(-16.0, 0.0, 72.0),
		"tower_right_pos": Vector3(16.0, 0.0, 72.0)
	})
	for n_pos: Vector3 in north_bases:
		var fwd: Vector3 = (Vector3.ZERO - n_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		slots.append({
			"base_pos": n_pos,
			"fwd": fwd,
			"tower_left_pos": n_pos + fwd * 30.0 - right * 12.0,
			"tower_right_pos": n_pos + fwd * 30.0 + right * 12.0
		})

	_create_barrier_wall(arch_root, Vector3(-36.0, 0.0, -34.0), Vector3(12.0, 3.4, 8.0), 0.25, Color(0.24, 0.26, 0.34), true)
	_create_barrier_wall(arch_root, Vector3(36.0, 0.0, -34.0), Vector3(12.0, 3.4, 8.0), -0.25, Color(0.24, 0.26, 0.34), true)
	return slots

static func _build_asym_frontline_5p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 2v3 Asymmetric Frontline (5P): 2 South Fortresses vs 3 North Vanguard Bases
	var slots: Array[Dictionary] = []
	var south_xs: Array[float] = [-48.0, 48.0]
	var north_xs: Array[float] = [-78.0, 0.0, 78.0]

	_add_lane_segment(ground, Vector3(-56.0, 0.0, 108.0), Vector3(56.0, 0.0, 108.0), 20.0)
	_add_lane_segment(ground, Vector3(-84.0, 0.0, -108.0), Vector3(84.0, 0.0, -108.0), 20.0)
	_add_lane_segment(ground, Vector3(-84.0, 0.0, 0.0), Vector3(84.0, 0.0, 0.0), 20.0)

	for sx: float in south_xs:
		var s_pos := Vector3(sx, 0.0, 108.0)
		_add_lane_segment(ground, s_pos, Vector3(sx, 0.0, 0.0), 20.0)
		_add_lane_segment(ground, s_pos, Vector3.ZERO, 18.0)
		slots.append({
			"base_pos": s_pos,
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(sx - 13.0, 0.0, 74.0),
			"tower_right_pos": Vector3(sx + 13.0, 0.0, 74.0)
		})

	for nx: float in north_xs:
		var n_pos := Vector3(nx, 0.0, -108.0)
		_add_lane_segment(ground, n_pos, Vector3(nx, 0.0, 0.0), 18.0)
		_add_lane_segment(ground, n_pos, Vector3.ZERO, 18.0)
		slots.append({
			"base_pos": n_pos,
			"fwd": Vector3(0.0, 0.0, 1.0),
			"tower_left_pos": Vector3(nx - 12.0, 0.0, -74.0),
			"tower_right_pos": Vector3(nx + 12.0, 0.0, -74.0)
		})
	return slots

static func _build_asym_citadel_6p(ground: Node3D, arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 2v4 Asymmetric Citadel (6P): 2 West Twin Spires vs 4 East Invader Outposts
	var slots: Array[Dictionary] = []
	var west_zs: Array[float] = [-48.0, 48.0]
	var east_zs: Array[float] = [-90.0, -30.0, 30.0, 90.0]

	_add_lane_segment(ground, Vector3(-124.0, 0.0, -64.0), Vector3(-124.0, 0.0, 64.0), 20.0)
	_add_lane_segment(ground, Vector3(124.0, 0.0, -98.0), Vector3(124.0, 0.0, 98.0), 20.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, -98.0), Vector3(0.0, 0.0, 98.0), 22.0)

	for wz: float in west_zs:
		var w_pos := Vector3(-124.0, 0.0, wz)
		_add_lane_segment(ground, w_pos, Vector3(0.0, 0.0, wz), 20.0)
		_add_lane_segment(ground, w_pos, Vector3.ZERO, 18.0)
		slots.append({
			"base_pos": w_pos,
			"fwd": Vector3(1.0, 0.0, 0.0),
			"tower_left_pos": Vector3(-90.0, 0.0, wz - 13.0),
			"tower_right_pos": Vector3(-90.0, 0.0, wz + 13.0)
		})

	for ez: float in east_zs:
		var e_pos := Vector3(124.0, 0.0, ez)
		var mid_z: float = -48.0 if ez < 0.0 else 48.0
		_add_lane_segment(ground, e_pos, Vector3(0.0, 0.0, mid_z), 18.0)
		_add_lane_segment(ground, e_pos, Vector3.ZERO, 16.0)
		slots.append({
			"base_pos": e_pos,
			"fwd": Vector3(-1.0, 0.0, 0.0),
			"tower_left_pos": Vector3(92.0, 0.0, ez - 11.5),
			"tower_right_pos": Vector3(92.0, 0.0, ez + 11.5)
		})

	_create_barrier_wall(arch_root, Vector3(54.0, 0.0, 0.0), Vector3(10.0, 3.4, 22.0), 0.0, Color(0.22, 0.28, 0.36), true)
	return slots

static func _build_asym_wedge_8p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 2v6 Asymmetric Iron Wedge Crescent (8P):
	# 2 South Bastion Citadels vs 6 Sweeping North Crescent Bases
	var slots: Array[Dictionary] = []
	var south_xs: Array[float] = [-52.0, 52.0]
	_add_lane_segment(ground, Vector3(-58.0, 0.0, 134.0), Vector3(58.0, 0.0, 134.0), 20.0)

	for sx: float in south_xs:
		var s_pos := Vector3(sx, 0.0, 134.0)
		_add_lane_segment(ground, s_pos, Vector3.ZERO, 22.0)
		_add_lane_segment(ground, s_pos, Vector3(sx, 0.0, 56.0), 20.0)
		slots.append({
			"base_pos": s_pos,
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(sx - 13.0, 0.0, 98.0),
			"tower_right_pos": Vector3(sx + 13.0, 0.0, 98.0)
		})

	var crescent_r: float = 152.0
	var prev_pt := Vector3.ZERO
	for i in range(6):
		var ang: float = deg_to_rad(-165.0 + float(i) * 30.0)
		var c_pos := Vector3(cos(ang) * crescent_r, 0.0, sin(ang) * crescent_r)
		var fwd: Vector3 = (Vector3.ZERO - c_pos).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, c_pos, Vector3.ZERO, 18.0)
		if i > 0:
			_add_lane_segment(ground, prev_pt, c_pos, 16.0)
		prev_pt = c_pos
		slots.append({
			"base_pos": c_pos,
			"fwd": fwd,
			"tower_left_pos": c_pos + fwd * 28.0 - right * 12.0,
			"tower_right_pos": c_pos + fwd * 28.0 + right * 12.0
		})

	_add_ring_lanes(ground, Vector3.ZERO, 72.0, 8, 18.0, 0.0)
	return slots

static func _build_asym_grid_10p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 3v7 Asymmetric Grid (10P): 3 South Citadels vs 7 North 2-Rank Grid Outposts
	var slots: Array[Dictionary] = []
	var south_xs: Array[float] = [-96.0, 0.0, 96.0]
	var rank1_xs: Array[float] = [-108.0, -36.0, 36.0, 108.0]
	var rank2_xs: Array[float] = [-96.0, 0.0, 96.0]

	for gz: float in [-152.0, -72.0, 0.0, 72.0, 144.0]:
		_add_lane_segment(ground, Vector3(-120.0, 0.0, gz), Vector3(120.0, 0.0, gz), 18.0)
	for gx: float in [-96.0, -36.0, 0.0, 36.0, 96.0]:
		_add_lane_segment(ground, Vector3(gx, 0.0, -158.0), Vector3(gx, 0.0, 152.0), 18.0)
	_add_lane_segment(ground, Vector3(-108.0, 0.0, -72.0), Vector3(-96.0, 0.0, 144.0), 16.0)
	_add_lane_segment(ground, Vector3(108.0, 0.0, -72.0), Vector3(96.0, 0.0, 144.0), 16.0)

	# 3 South Defender Citadels
	for sx: float in south_xs:
		var s_pos := Vector3(sx, 0.0, 144.0)
		slots.append({
			"base_pos": s_pos,
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(sx - 13.0, 0.0, 110.0),
			"tower_right_pos": Vector3(sx + 13.0, 0.0, 110.0)
		})

	# 7 North Invader Grid Bases (4 Front + 3 Rear)
	for r1x: float in rank1_xs:
		var n1_pos := Vector3(r1x, 0.0, -72.0)
		slots.append({
			"base_pos": n1_pos,
			"fwd": Vector3(0.0, 0.0, 1.0),
			"tower_left_pos": Vector3(r1x - 11.5, 0.0, -44.0),
			"tower_right_pos": Vector3(r1x + 11.5, 0.0, -44.0)
		})
	for r2x: float in rank2_xs:
		var n2_pos := Vector3(r2x, 0.0, -152.0)
		slots.append({
			"base_pos": n2_pos,
			"fwd": Vector3(0.0, 0.0, 1.0),
			"tower_left_pos": Vector3(r2x - 11.5, 0.0, -124.0),
			"tower_right_pos": Vector3(r2x + 11.5, 0.0, -124.0)
		})
	return slots

static func _build_asym_crescent_12p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 4v8 Asymmetric Armada (12P): 4 South Keep Citadels vs 8 North 2-Wave Armada Bases
	var slots: Array[Dictionary] = []
	var col_xs: Array[float] = [-108.0, -36.0, 36.0, 108.0]

	for gx: float in col_xs:
		_add_lane_segment(ground, Vector3(gx, 0.0, -176.0), Vector3(gx, 0.0, 168.0), 18.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, -176.0), Vector3(0.0, 0.0, 168.0), 20.0)
	for gz: float in [-168.0, -84.0, 0.0, 84.0, 160.0]:
		_add_lane_segment(ground, Vector3(-120.0, 0.0, gz), Vector3(120.0, 0.0, gz), 18.0)
	_add_lane_segment(ground, Vector3(-108.0, 0.0, -168.0), Vector3(108.0, 0.0, 160.0), 16.0)
	_add_lane_segment(ground, Vector3(108.0, 0.0, -168.0), Vector3(-108.0, 0.0, 160.0), 16.0)

	# 4 South Keep Citadels
	for sx: float in col_xs:
		var s_pos := Vector3(sx, 0.0, 160.0)
		slots.append({
			"base_pos": s_pos,
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(sx - 12.0, 0.0, 126.0),
			"tower_right_pos": Vector3(sx + 12.0, 0.0, 126.0)
		})

	# 8 North Armada Bases (2 echelon waves of 4)
	for nz: float in [-84.0, -168.0]:
		for nx: float in col_xs:
			var n_pos := Vector3(nx, 0.0, nz)
			slots.append({
				"base_pos": n_pos,
				"fwd": Vector3(0.0, 0.0, 1.0),
				"tower_left_pos": Vector3(nx - 11.5, 0.0, nz + 28.0),
				"tower_right_pos": Vector3(nx + 11.5, 0.0, nz + 28.0)
			})
	return slots

static func _build_asym_fortress_16p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 5v11 Asymmetric Bastion Wall vs Raider Swarm (16P):
	# 5 West Wall Citadels (X = -192) vs 11 East 2-Tier Swarm Bases (6 at X = +108, 5 at X = +198)
	var slots: Array[Dictionary] = []
	var west_zs: Array[float] = [-144.0, -72.0, 0.0, 72.0, 144.0]
	var tier1_zs: Array[float] = [-150.0, -90.0, -30.0, 30.0, 90.0, 150.0]

	for gx: float in [-192.0, -96.0, 0.0, 108.0, 198.0]:
		_add_lane_segment(ground, Vector3(gx, 0.0, -162.0), Vector3(gx, 0.0, 162.0), 18.0)
	for gz: float in west_zs:
		_add_lane_segment(ground, Vector3(-204.0, 0.0, gz), Vector3(210.0, 0.0, gz), 18.0)
	for t1z: float in tier1_zs:
		_add_lane_segment(ground, Vector3(0.0, 0.0, t1z), Vector3(198.0, 0.0, t1z), 16.0)

	# 5 West Defender Citadels
	for wz: float in west_zs:
		var w_pos := Vector3(-192.0, 0.0, wz)
		slots.append({
			"base_pos": w_pos,
			"fwd": Vector3(1.0, 0.0, 0.0),
			"tower_left_pos": Vector3(-160.0, 0.0, wz - 12.0),
			"tower_right_pos": Vector3(-160.0, 0.0, wz + 12.0)
		})

	# 6 East Tier-1 Vanguard Bases (X = 108)
	for ez1: float in tier1_zs:
		var e1_pos := Vector3(108.0, 0.0, ez1)
		slots.append({
			"base_pos": e1_pos,
			"fwd": Vector3(-1.0, 0.0, 0.0),
			"tower_left_pos": Vector3(80.0, 0.0, ez1 - 11.0),
			"tower_right_pos": Vector3(80.0, 0.0, ez1 + 11.0)
		})

	# 5 East Tier-2 Rear Bases (X = 198)
	for ez2: float in west_zs:
		var e2_pos := Vector3(198.0, 0.0, ez2)
		slots.append({
			"base_pos": e2_pos,
			"fwd": Vector3(-1.0, 0.0, 0.0),
			"tower_left_pos": Vector3(170.0, 0.0, ez2 - 11.0),
			"tower_right_pos": Vector3(170.0, 0.0, ez2 + 11.0)
		})
	return slots

static func _build_asym_sanctuary_20p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 5v15 Asymmetric Sanctuary vs 3-Wave Siege Ring (20P):
	# 5 South Sanctuary Citadels vs 15 North Siege Outposts (3 waves of 5)
	var slots: Array[Dictionary] = []
	var col_xs: Array[float] = [-160.0, -80.0, 0.0, 80.0, 160.0]
	var wave_zs: Array[float] = [-65.0, -140.0, -215.0]

	for gx: float in col_xs:
		_add_lane_segment(ground, Vector3(gx, 0.0, -225.0), Vector3(gx, 0.0, 205.0), 18.0)
	for gz: float in [-215.0, -140.0, -65.0, 25.0, 110.0, 195.0]:
		_add_lane_segment(ground, Vector3(-172.0, 0.0, gz), Vector3(172.0, 0.0, gz), 18.0)
	_add_lane_segment(ground, Vector3(-160.0, 0.0, -215.0), Vector3(160.0, 0.0, 195.0), 16.0)
	_add_lane_segment(ground, Vector3(160.0, 0.0, -215.0), Vector3(-160.0, 0.0, 195.0), 16.0)

	# 5 South Sanctuary Citadels
	for sx: float in col_xs:
		var s_pos := Vector3(sx, 0.0, 195.0)
		slots.append({
			"base_pos": s_pos,
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(sx - 12.0, 0.0, 162.0),
			"tower_right_pos": Vector3(sx + 12.0, 0.0, 162.0)
		})

	# 15 North Siege Outposts (3 waves of 5)
	for wz: float in wave_zs:
		for nx: float in col_xs:
			var n_pos := Vector3(nx, 0.0, wz)
			slots.append({
				"base_pos": n_pos,
				"fwd": Vector3(0.0, 0.0, 1.0),
				"tower_left_pos": Vector3(nx - 11.0, 0.0, wz + 25.0),
				"tower_right_pos": Vector3(nx + 11.0, 0.0, wz + 25.0)
			})
	return slots

static func _build_asym_siege_25p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 25-Player Asymmetric Siege Lanes (5 South Citadels vs 20 North Invaders — Map Kind 1: Corridor/Siege Lanes)
	var slots: Array[Dictionary] = []
	var col_xs: Array[float] = [-192.0, -96.0, 0.0, 96.0, 192.0]
	var north_ranks: Array[float] = [-60.0, -124.0, -188.0, -252.0]

	for gx: float in col_xs:
		_add_lane_segment(ground, Vector3(gx, 0.0, -264.0), Vector3(gx, 0.0, 228.0), 20.0)
	for gz: float in [-252.0, -188.0, -124.0, -60.0, 48.0, 132.0, 216.0]:
		_add_lane_segment(ground, Vector3(-206.0, 0.0, gz), Vector3(206.0, 0.0, gz), 18.0)

	# 4 Diagonal Assault Highways across the central battlefield
	_add_lane_segment(ground, Vector3(-192.0, 0.0, -60.0), Vector3(0.0, 0.0, 216.0), 16.0)
	_add_lane_segment(ground, Vector3(192.0, 0.0, -60.0), Vector3(0.0, 0.0, 216.0), 16.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, -60.0), Vector3(-192.0, 0.0, 216.0), 16.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, -60.0), Vector3(192.0, 0.0, 216.0), 16.0)

	# 5 South Defender Citadels
	for sx: float in col_xs:
		var s_pos := Vector3(sx, 0.0, 216.0)
		slots.append({
			"base_pos": s_pos,
			"fwd": Vector3(0.0, 0.0, -1.0),
			"tower_left_pos": Vector3(sx - 12.0, 0.0, 184.0),
			"tower_right_pos": Vector3(sx + 12.0, 0.0, 184.0)
		})

	# 20 North Invader Bases (4 ranks of 5)
	for rz: float in north_ranks:
		for nx: float in col_xs:
			var n_pos := Vector3(nx, 0.0, rz)
			slots.append({
				"base_pos": n_pos,
				"fwd": Vector3(0.0, 0.0, 1.0),
				"tower_left_pos": Vector3(nx - 11.0, 0.0, rz + 23.0),
				"tower_right_pos": Vector3(nx + 11.0, 0.0, rz + 23.0)
			})
	return slots

static func _build_asym_mandala_25p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 25-Player Asymmetric Mandala Raid (5 South Sanctum / 1 Apex Overlord vs 20 North Crescent Mandala — Map Kind 2: Radial/Mandala Ring)
	var slots: Array[Dictionary] = []

	# Side 1: 5 South Sanctum Citadels (Slot 0 is the central Apex Overlord Citadel)
	var sanctum_positions: Array[Vector3] = [
		Vector3(0.0, 0.0, 185.0),
		Vector3(-125.0, 0.0, 215.0),
		Vector3(-64.0, 0.0, 128.0),
		Vector3(64.0, 0.0, 128.0),
		Vector3(125.0, 0.0, 215.0)
	]
	for sp: Vector3 in sanctum_positions:
		var fwd: Vector3 = (Vector3.ZERO - sp).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		_add_lane_segment(ground, sp, Vector3.ZERO, 20.0)
		slots.append({
			"base_pos": sp,
			"fwd": fwd,
			"tower_left_pos": sp + fwd * 25.0 - right * 11.5,
			"tower_right_pos": sp + fwd * 25.0 + right * 11.5
		})
	_add_lane_segment(ground, sanctum_positions[1], sanctum_positions[0], 18.0)
	_add_lane_segment(ground, sanctum_positions[4], sanctum_positions[0], 18.0)
	_add_lane_segment(ground, sanctum_positions[2], sanctum_positions[3], 18.0)

	# Side 2: 20 North Crescent Mandala Raiders (10 on Mid Arc R=168, 10 on Outer Arc R=258)
	for ring_r: float in [168.0, 258.0]:
		var prev_c := Vector3.ZERO
		for i in range(10):
			var ang: float = deg_to_rad(-171.0 + float(i) * 18.0)
			var c_pos := Vector3(cos(ang) * ring_r, 0.0, sin(ang) * ring_r)
			var fwd: Vector3 = (Vector3.ZERO - c_pos).normalized()
			var right := Vector3(-fwd.z, 0.0, fwd.x)
			if ring_r > 200.0:
				_add_lane_segment(ground, c_pos, Vector3.ZERO, 16.0)
			if i > 0:
				_add_lane_segment(ground, prev_c, c_pos, 16.0)
			prev_c = c_pos
			slots.append({
				"base_pos": c_pos,
				"fwd": fwd,
				"tower_left_pos": c_pos + fwd * 24.0 - right * 11.0,
				"tower_right_pos": c_pos + fwd * 24.0 + right * 11.0
			})

	_add_ring_lanes(ground, Vector3.ZERO, 88.0, 10, 18.0, 0.0)
	return slots

static func _build_asym_grid_25p(ground: Node3D, _arch_root: Node3D, _total_slots: int) -> Array[Dictionary]:
	# 25-Player Asymmetric Hyper-Grid (7 West Fortified Citadels vs 18 East Urban Grid Raiders — Map Kind 3: Hyper-Grid "Paths Everywhere")
	var slots: Array[Dictionary] = []
	var grid_coords: Array[float] = [-240.0, -180.0, -120.0, -60.0, 0.0, 60.0, 120.0, 180.0, 240.0]

	# 18 Full-Span Orthogonal Grid Highways + 6 Diagonal Expressways = 24 Highways!
	for gx: float in grid_coords:
		var w_ns: float = 20.0 if (int(round(absf(gx))) % 120 == 0) else 15.0
		_add_lane_segment(ground, Vector3(gx, 0.0, -252.0), Vector3(gx, 0.0, 252.0), w_ns)
	for gz: float in grid_coords:
		var w_ew: float = 20.0 if (int(round(absf(gz))) % 120 == 0) else 15.0
		_add_lane_segment(ground, Vector3(-252.0, 0.0, gz), Vector3(252.0, 0.0, gz), w_ew)

	_add_lane_segment(ground, Vector3(-240.0, 0.0, -240.0), Vector3(240.0, 0.0, 240.0), 16.0)
	_add_lane_segment(ground, Vector3(-240.0, 0.0, 240.0), Vector3(240.0, 0.0, -240.0), 16.0)
	_add_lane_segment(ground, Vector3(-180.0, 0.0, 0.0), Vector3(0.0, 0.0, 180.0), 14.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, 180.0), Vector3(180.0, 0.0, 0.0), 14.0)
	_add_lane_segment(ground, Vector3(180.0, 0.0, 0.0), Vector3(0.0, 0.0, -180.0), 14.0)
	_add_lane_segment(ground, Vector3(0.0, 0.0, -180.0), Vector3(-180.0, 0.0, 0.0), 14.0)

	# Side 1: 7 West Fortified Citadels (4 at X=-240, 3 at X=-120)
	var west_positions: Array[Vector3] = [
		Vector3(-120.0, 0.0, 0.0),
		Vector3(-120.0, 0.0, -120.0),
		Vector3(-120.0, 0.0, 120.0),
		Vector3(-240.0, 0.0, -60.0),
		Vector3(-240.0, 0.0, 60.0),
		Vector3(-240.0, 0.0, -180.0),
		Vector3(-240.0, 0.0, 180.0)
	]
	for wp: Vector3 in west_positions:
		slots.append({
			"base_pos": wp,
			"fwd": Vector3(1.0, 0.0, 0.0),
			"tower_left_pos": wp + Vector3(22.0, 0.0, -11.0),
			"tower_right_pos": wp + Vector3(22.0, 0.0, 11.0)
		})

	# Side 2: 18 East Urban Grid Raiders (3 columns X=[60, 180, 240] x 6 rows Z=[-240, -120, -60, 60, 120, 240])
	var east_xs: Array[float] = [60.0, 180.0, 240.0]
	var east_zs: Array[float] = [-240.0, -120.0, -60.0, 60.0, 120.0, 240.0]
	for ex: float in east_xs:
		for ez: float in east_zs:
			var ep := Vector3(ex, 0.0, ez)
			slots.append({
				"base_pos": ep,
				"fwd": Vector3(-1.0, 0.0, 0.0),
				"tower_left_pos": ep + Vector3(-22.0, 0.0, -11.0),
				"tower_right_pos": ep + Vector3(-22.0, 0.0, 11.0)
			})

	return slots

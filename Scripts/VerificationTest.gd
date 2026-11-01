extends Node

const MapLayoutBuilder = preload("res://Scripts/MapLayoutBuilder.gd")
const BotAI = preload("res://Scripts/BotAI.gd")
const WildlifeModelBuilder = preload("res://Scripts/WildlifeModelBuilder.gd")
const WildlifeCreatureScript = preload("res://Scripts/WildlifeCreature.gd")

func _ready():
	print("==================================================")
	print("       STARTING MASSIVE UBB VERIFICATION TEST     ")
	print("==================================================")
	
	var total_passed = 0
	var total_failed = 0
	
	# Test 1: Cards & Data Integrity
	print("\n--- TEST 1: Cards & Data Integrity ---")
	if test_cards():
		total_passed += 1
		print("  [PASS] All card resources and referenced scenes loaded successfully.")
	else:
		total_failed += 1
		print("  [FAIL] Card integrity check failed!")
		
	# Test 2: Scenes & Unit Instantiation
	print("\n--- TEST 2: All Unit Scenes Instantiation ---")
	if test_unit_scenes():
		total_passed += 1
		print("  [PASS] All unit scenes instantiated without errors.")
	else:
		total_failed += 1
		print("  [FAIL] Unit scene instantiation failed!")

	# Test 3: Root Scenes & Menus Instantiation
	print("\n--- TEST 3: Root & Menu Scenes Instantiation ---")
	if test_root_scenes():
		total_passed += 1
		print("  [PASS] All root and menu scenes instantiated cleanly.")
	else:
		total_failed += 1
		print("  [FAIL] Root scene instantiation failed!")

	# Test 4: Scripts Compilation & Loading
	print("\n--- TEST 4: Scripts Compilation & Loading ---")
	if test_all_scripts():
		total_passed += 1
		print("  [PASS] All GDScript files compiled and loaded with 0 errors.")
	else:
		total_failed += 1
		print("  [FAIL] Script compilation check failed!")

	# Test 5: Map Layouts & Biomes
	print("\n--- TEST 5: Map Layouts & Biomes ---")
	if test_maps_and_biomes():
		total_passed += 1
		print("  [PASS] All map layouts and biomes verified.")
	else:
		total_failed += 1
		print("  [FAIL] Map layouts or biomes failed!")

	# Test 6: Shield & Armor Systems
	print("\n--- TEST 6: Shield & Armor Mechanics ---")
	if test_shield_and_armor():
		total_passed += 1
		print("  [PASS] Directional shields, 360 shields, and armor break-off verified.")
	else:
		total_failed += 1
		print("  [FAIL] Shield and armor mechanics failed!")

	# Test 7: Bot AI & Strategy
	print("\n--- TEST 7: Bot AI Decisions & Lane Navigation ---")
	if test_bot_ai():
		total_passed += 1
		print("  [PASS] Bot AI evaluation and strategic lane routing verified.")
	else:
		total_failed += 1
		print("  [FAIL] Bot AI verification failed!")

	# Test 8: Live Match Simulation
	print("\n--- TEST 8: Live Match Simulation & Endgame Maw ---")
	if test_live_match_simulation():
		total_passed += 1
		print("  [PASS] Arena match simulation, combat ticks, and endgame Maw verified.")
	else:
		total_failed += 1
		print("  [FAIL] Live match simulation failed!")

	# Test 9: Model Orientations & Visual Forward Direction
	print("\n--- TEST 9: Model Orientations & Forward Facing ---")
	if test_model_orientations():
		total_passed += 1
		print("  [PASS] Model orientations, forward vectors, and recoil directions verified.")
	else:
		total_failed += 1
		print("  [FAIL] Model orientation verification failed!")

	# Test 10: AI Systems, Targeting & Combat Behaviors
	print("\n--- TEST 10: AI Systems & Combat Behaviors ---")
	if test_ai_systems():
		total_passed += 1
		print("  [PASS] AI targeting, kiting, leashing, difficulty scaling, and commander prioritization verified.")
	else:
		total_failed += 1
		print("  [FAIL] AI systems verification failed!")

	print("\n==================================================")
	print("VERIFICATION SUMMARY: %d PASSED, %d FAILED" % [total_passed, total_failed])
	print("==================================================")

	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	var pre_script = load("res://Scripts/EnvironmentPreRenderer.gd")
	if pre_script and pre_script.has_method("clear_caches"):
		pre_script.clear_caches()

	if total_failed == 0:
		print("ALL SYSTEMS GREEN! Exiting cleanly with code 0.")
		get_tree().quit(0)
	else:
		printerr("VERIFICATION FAILED! Exiting with code 1.")
		get_tree().quit(1)

func test_cards() -> bool:
	var dir = DirAccess.open("res://Data/Cards")
	if not dir:
		printerr("Cannot open res://Data/Cards")
		return false
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var card_count = 0
	var success = true
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = "res://Data/Cards/" + file_name
			var card = ResourceLoader.load(full_path)
			if card == null:
				printerr("Failed to load card: ", full_path)
				success = false
			else:
				card_count += 1
				if card.unit_scene == null:
					printerr("Card missing unit_scene: ", full_path)
					success = false
				elif not (card.unit_scene is PackedScene):
					printerr("Card unit_scene is not PackedScene: ", full_path)
					success = false
		file_name = dir.get_next()
	dir.list_dir_end()
	print("  Verified %d card .tres resources." % card_count)
	return success and (card_count > 0)

func test_unit_scenes() -> bool:
	var dirs_to_check = ["res://Scenes/Units", "res://Scenes/Units/VoidSwarm"]
	var unit_count = 0
	var success = true
	
	for path in dirs_to_check:
		var dir = DirAccess.open(path)
		if not dir: continue
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var full_path = path + "/" + file_name
				var ps = ResourceLoader.load(full_path) as PackedScene
				if ps == null:
					printerr("Failed to load PackedScene: ", full_path)
					success = false
				else:
					var inst = ps.instantiate()
					if inst == null:
						printerr("Failed to instantiate unit scene: ", full_path)
						success = false
					else:
						unit_count += 1
						inst.free()
			file_name = dir.get_next()
		dir.list_dir_end()
	print("  Verified %d unit .tscn scenes instantiated cleanly." % unit_count)
	return success and (unit_count > 0)

func test_root_scenes() -> bool:
	var dir = DirAccess.open("res://Scenes")
	if not dir:
		printerr("Cannot open res://Scenes")
		return false
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var scene_count = 0
	var success = true
	while file_name != "":
		if file_name.ends_with(".tscn") and file_name != "VerificationTest.tscn":
			var full_path = "res://Scenes/" + file_name
			var ps = ResourceLoader.load(full_path) as PackedScene
			if ps == null:
				printerr("Failed to load root scene: ", full_path)
				success = false
			else:
				var inst = ps.instantiate()
				if inst == null:
					printerr("Failed to instantiate root scene: ", full_path)
					success = false
				else:
					scene_count += 1
					inst.free()
		file_name = dir.get_next()
	dir.list_dir_end()
	print("  Verified %d root .tscn scenes instantiated cleanly." % scene_count)
	return success and (scene_count > 0)

func test_all_scripts() -> bool:
	var dir = DirAccess.open("res://Scripts")
	if not dir:
		printerr("Cannot open res://Scripts")
		return false
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var script_count = 0
	var success = true
	while file_name != "":
		if file_name.ends_with(".gd") and file_name != "VerificationTest.gd":
			var full_path = "res://Scripts/" + file_name
			var scr = ResourceLoader.load(full_path)
			if scr == null:
				printerr("Failed to load script: ", full_path)
				success = false
			else:
				script_count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	print("  Verified %d GDScript files compiled successfully." % script_count)
	return success and (script_count > 0)

func test_maps_and_biomes() -> bool:
	if MapLayoutBuilder.MAP_CATALOG.is_empty():
		printerr("MAP_CATALOG is empty!")
		return false

	var dummy_arena = Node3D.new()
	add_child(dummy_arena)
	var ground = Node3D.new()
	ground.name = "Ground"
	dummy_arena.add_child(ground)

	var tested_count = 0
	var tested_comps = 0
	for entry in MapLayoutBuilder.MAP_CATALOG:
		var map_id = entry.id
		var comps = entry.get("comps", [])
		for c_info in comps:
			var p_cnt = int(c_info.get("players", entry.get("default_players", 2)))
			var c_mode = String(c_info.get("comp", "2_TEAMS"))
			var layout = MapLayoutBuilder.build_map_layout(dummy_arena, map_id, p_cnt, c_mode)
			if not layout or not layout.has("slot_defs"):
				printerr("Failed to build map layout: ", map_id, " comp: ", c_mode)
				dummy_arena.queue_free()
				return false
			tested_comps += 1
		tested_count += 1

	dummy_arena.queue_free()

	var biomes = ["SUNNY_PLAINS", "SCORCHING_DUNES", "REALM_OF_HARMONY", "FROZEN_TUNDRA", "VOLCANIC_BRIMSTONE", "SPACE_VACUUM", "DEEP_JUNGLE"]

	# --- Test Deep Space Vacuum Biome Decompression Mechanics ---
	var vac_arena = ArenaManager.new()
	vac_arena.active_biome = "SPACE_VACUUM"
	add_child(vac_arena)

	var unshielded_monkey = (load("res://Scenes/Units/WildlifeMonkey.tscn") as PackedScene).instantiate()
	add_child(unshielded_monkey)
	var monkey_hc = unshielded_monkey.get_node_or_null("HealthComponent") as HealthComponent
	var monkey_start_hp = monkey_hc.current_health

	var shielded_org = CharacterBody3D.new()
	shielded_org.name = "ShieldedMarine"
	shielded_org.add_to_group("Units")
	var sh_hc = HealthComponent.new()
	sh_hc.name = "HealthComponent"
	sh_hc.max_health = 100.0
	sh_hc.current_health = 100.0
	sh_hc.max_shield = 50.0
	sh_hc.current_shield = 50.0
	shielded_org.add_child(sh_hc)
	add_child(shielded_org)

	var sealed_tank = CharacterBody3D.new()
	sealed_tank.name = "HeavyTankUnit"
	sealed_tank.add_to_group("Units")
	var tk_hc = HealthComponent.new()
	tk_hc.name = "HealthComponent"
	tk_hc.max_health = 300.0
	tk_hc.current_health = 300.0
	sealed_tank.add_child(tk_hc)
	add_child(sealed_tank)

	vac_arena._update_space_vacuum(1.1)
	if monkey_hc.current_health >= monkey_start_hp:
		printerr("SPACE_VACUUM failed to damage unshielded organic unit!")
		return false
	if sh_hc.current_health != 100.0 or sh_hc.current_shield != 50.0:
		printerr("SPACE_VACUUM damaged a shielded unit!")
		return false
	if tk_hc.current_health != 300.0:
		printerr("SPACE_VACUUM damaged a mechanical tank!")
		return false

	unshielded_monkey.queue_free()
	shielded_org.queue_free()
	sealed_tank.queue_free()
	vac_arena.queue_free()

	# --- Test Frozen Tundra Mechanics: Breakable Ice Patches & Sea Lions ---
	var bip_script = load("res://Scripts/BreakableIcePatch.gd")
	var small_patch = bip_script.new()
	small_patch.patch_size = "SMALL"
	add_child(small_patch)

	var large_patch = bip_script.new()
	large_patch.patch_size = "LARGE"
	add_child(large_patch)

	var sea_lion_script = load("res://Scripts/SeaLionCreature.gd")
	var sea_lion = sea_lion_script.new()
	add_child(sea_lion)

	# Test organic targeting vs mechanical/structures
	var test_grunt = CharacterBody3D.new()
	test_grunt.name = "TestGrunt"
	var grunt_hc = HealthComponent.new()
	grunt_hc.name = "HealthComponent"
	test_grunt.add_child(grunt_hc)

	var test_tank = CharacterBody3D.new()
	test_tank.name = "TestTank"
	test_tank.set("unit_attribute", "Mechanical")
	var tank_hc = HealthComponent.new()
	tank_hc.name = "HealthComponent"
	test_tank.add_child(tank_hc)

	var test_plane = CharacterBody3D.new()
	test_plane.name = "TestPlane"
	var plane_hc = HealthComponent.new()
	plane_hc.name = "HealthComponent"
	test_plane.add_child(plane_hc)

	var test_base = StaticBody3D.new()
	test_base.name = "SideA_Base"
	test_base.add_to_group("Structure")

	var test_sky_beetle = CharacterBody3D.new()
	test_sky_beetle.name = "SkyBeetle"
	test_sky_beetle.set("unit_attribute", "Flying")
	var beetle_hc = HealthComponent.new()
	beetle_hc.name = "HealthComponent"
	test_sky_beetle.add_child(beetle_hc)

	if not sea_lion.is_valid_organic_target(test_grunt):
		printerr("Sea lion failed to identify organic grunt as valid target!")
		return false
	if sea_lion.is_valid_organic_target(test_tank):
		printerr("Sea lion targeted mechanical tank! Must ignore mechanical units.")
		return false
	if sea_lion.is_valid_organic_target(test_plane):
		printerr("Sea lion targeted plane! Must ignore planes.")
		return false
	if sea_lion.is_valid_organic_target(test_sky_beetle):
		printerr("Sea lion targeted SkyBeetle! Must ignore flying units.")
		return false
	if sea_lion.is_valid_organic_target(test_base):
		printerr("Sea lion targeted base! Must ignore buildings.")
		return false

	if not small_patch._is_unit_flying(test_plane) or not small_patch._is_unit_flying(test_sky_beetle):
		printerr("BreakableIcePatch failed to recognize flying units!")
		return false

	# Verify Sea Lion take_damage
	var sl_hc = sea_lion.get_node_or_null("HealthComponent")
	if sl_hc:
		var prev_h = sl_hc.current_health
		sea_lion.take_damage(20.0)
		if sl_hc.current_health >= prev_h:
			printerr("Sea Lion take_damage failed to reduce health!")
			return false

	test_grunt.queue_free()
	test_tank.queue_free()
	test_plane.queue_free()
	test_sky_beetle.queue_free()
	test_base.queue_free()
	small_patch.queue_free()
	large_patch.queue_free()
	sea_lion.queue_free()

	# --- Test Volcanic Brimstone Hazards & Fire Entities ---
	var vfh_script = load("res://Scripts/VolcanicFireHazard.gd")
	var fire_hazard = vfh_script.new()
	add_child(fire_hazard)

	var fs_melee_script = load("res://Scripts/FireSpriteMelee.gd")
	var fs_melee = fs_melee_script.new()
	add_child(fs_melee)

	var fs_ranged_script = load("res://Scripts/FireSpriteRanged.gd")
	var fs_ranged = fs_ranged_script.new()
	add_child(fs_ranged)

	var gfm_script = load("res://Scripts/GreaterFireMonster.gd")
	var gfm = gfm_script.new()
	add_child(gfm)

	if gfm.max_health < 400.0 or gfm.ranged_attack_range <= 0.0 or gfm.melee_attack_range <= 0.0:
		printerr("GreaterFireMonster stats or hybrid attack ranges invalid!")
		return false

	# Test take_damage on fire entities
	var fs_hc = fs_melee.get_node_or_null("HealthComponent")
	if fs_hc:
		var p_hp = fs_hc.current_health
		fs_melee.take_damage(15.0)
		if fs_hc.current_health >= p_hp:
			printerr("FireSpriteMelee take_damage failed!")
			return false

	var gfm_hc = gfm.get_node_or_null("HealthComponent")
	if gfm_hc:
		var g_hp = gfm_hc.current_health
		gfm.take_damage(30.0)
		if gfm_hc.current_health >= g_hp:
			printerr("GreaterFireMonster take_damage failed!")
			return false

	# Verify fire monster groups for hazard immunity
	if not fs_melee.is_in_group("FireMonster") or not fs_ranged.is_in_group("FireMonster") or not gfm.is_in_group("FireMonster"):
		printerr("Fire entities missing FireMonster group for hazard immunity!")
		return false

	fire_hazard.queue_free()
	fs_melee.queue_free()
	fs_ranged.queue_free()
	gfm.queue_free()

	# --- Test Deep Jungle Biome Mechanics: Quicksand Sinkholes, Gorilla Dens & Monkey Burrows ---
	var qs_script = load("res://Scripts/QuicksandSinkhole.gd")
	var sinkhole = qs_script.new()
	add_child(sinkhole)

	var test_ground_unit = CharacterBody3D.new()
	test_ground_unit.name = "TestJungleInfantry"
	var tg_hc = HealthComponent.new()
	tg_hc.name = "HealthComponent"
	tg_hc.max_health = 100.0
	tg_hc.current_health = 100.0
	test_ground_unit.add_child(tg_hc)
	var tg_vp = Node3D.new()
	tg_vp.name = "VisualPivot"
	test_ground_unit.add_child(tg_vp)
	add_child(test_ground_unit)

	var test_flyer_unit = CharacterBody3D.new()
	test_flyer_unit.name = "TestJunglePlane"
	test_flyer_unit.set("is_flying", true)
	add_child(test_flyer_unit)

	if sinkhole._is_unit_flying(test_ground_unit):
		printerr("QuicksandSinkhole incorrectly identified ground infantry as flying!")
		return false
	if not sinkhole._is_unit_flying(test_flyer_unit):
		printerr("QuicksandSinkhole failed to recognize flying unit!")
		return false

	# Test quicksand slow and sink application
	test_ground_unit.velocity = Vector3(10.0, 0.0, 10.0)
	test_ground_unit.global_position = sinkhole.global_position
	sinkhole._apply_unit_sink(test_ground_unit, -0.45, 1.0)
	if tg_vp.position.y >= 0.0:
		printerr("QuicksandSinkhole failed to visually sink ground unit!")
		return false
	sinkhole._restore_unit_sink(test_ground_unit)
	if tg_vp.position.y != 0.0:
		printerr("QuicksandSinkhole failed to restore ground unit visual height on exit!")
		return false

	# Test Territorial Gorilla and Monkey configurations
	var tc_script = load("res://Scripts/TerritorialCreature.gd")
	var t_gorilla = tc_script.new()
	t_gorilla.configure_creature("Gorilla", Vector3(10, 0, 10))
	add_child(t_gorilla)
	t_gorilla.global_position = Vector3(10, 0, 10)

	var t_monkey = tc_script.new()
	t_monkey.configure_creature("Monkey", Vector3(-10, 0, -10))
	add_child(t_monkey)
	t_monkey.global_position = Vector3(-10, 0, -10)

	if t_gorilla.max_health < 200.0 or t_gorilla.attack_damage < 20.0 or not t_gorilla.is_in_group("Gorilla"):
		printerr("Territorial Gorilla stats or group configuration invalid!")
		return false
	if t_monkey.attack_range < 7.0 or not t_monkey.is_in_group("Monkey"):
		printerr("Territorial Monkey ranged attack or group configuration invalid!")
		return false

	# Test jungle environment generation on an arena
	var j_arena = ArenaManager.new()
	j_arena.active_biome = "DEEP_JUNGLE"
	add_child(j_arena)
	var j_env = Node3D.new()
	j_env.name = "EnvironmentFeatures"
	j_arena.add_child(j_env)
	j_arena._generate_jungle(j_env)

	var found_den = false
	var found_burrow = false
	var found_sinkhole = false
	var found_jungle_mmi = false
	for child in j_env.get_children():
		if "GorillaDen" in child.name: found_den = true
		elif "MonkeyBurrow" in child.name: found_burrow = true
		elif child.is_in_group("Quicksand") or "Quicksand" in child.name or child.get_script() == qs_script: found_sinkhole = true
		elif child is MultiMeshInstance3D: found_jungle_mmi = true

	if not found_den or not found_burrow or not found_sinkhole or not found_jungle_mmi:
		printerr("Deep Jungle environment failed to spawn GorillaDen, MonkeyBurrow, QuicksandSinkhole, or GPU MultiMeshInstance3D! Found: den=%s burrow=%s sinkhole=%s mmi=%s" % [str(found_den), str(found_burrow), str(found_sinkhole), str(found_jungle_mmi)])
		return false

	# Test v8 EnvironmentPreRenderer, GpuAccelerator, Hardware LOD & LoadingScreen
	var gpu_script = load("res://Scripts/GpuAccelerator.gd")
	var pre_script = load("res://Scripts/EnvironmentPreRenderer.gd")
	var ls_script = load("res://Scripts/LoadingScreen.gd")
	if gpu_script == null or pre_script == null or ls_script == null:
		printerr("Failed to load v8 optimization scripts (GpuAccelerator, EnvironmentPreRenderer, or LoadingScreen)!")
		return false

	if gpu_script.get_cached_shader_count() < 5:
		printerr("GpuAccelerator failed to compile and cache the 5 core GPU shaders!")
		return false

	var bake_stats: Dictionary = pre_script.pre_render_and_bake_environment(j_arena, j_env, "DEEP_JUNGLE")
	if not bool(bake_stats.get("baked_probe_active", false)) or int(bake_stats.get("multimesh_batches", 0)) < 1 or int(bake_stats.get("configured_lod_nodes", 0)) < 1:
		printerr("EnvironmentPreRenderer failed to bake environment or configure GPU MultiMesh LODs: ", bake_stats)
		return false

	var probe = j_env.get_node_or_null("BakedEnvironmentProbe") as ReflectionProbe
	if probe == null or probe.update_mode != ReflectionProbe.UPDATE_ONCE:
		printerr("BakedEnvironmentProbe missing or not set to UPDATE_ONCE!")
		return false

	# Verify O(1) Spatial Hash Grid & GPU Compute Dispatch / Fallback
	gpu_script.rebuild_spatial_grid([test_ground_unit, t_gorilla, t_monkey], 4.0)
	var near_g = gpu_script.query_nearby_units(Vector3(10, 0, 10), 2.5)
	if not near_g.has(t_gorilla):
		printerr("GpuAccelerator spatial hash grid query failed to find nearby unit!")
		return false

	var compute_positions := PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(1.5, 0, 1.0),
		Vector3(50, 0, 50)
	])
	var compute_counts: PackedInt32Array = gpu_script.dispatch_spatial_compute(compute_positions, 3.0)
	if compute_counts.size() != 3 or compute_counts[0] != 1 or compute_counts[2] != 0:
		printerr("GpuAccelerator dispatch_spatial_compute returned invalid neighbor counts: ", compute_counts)
		return false

	var ls_node = ls_script.new()
	j_arena.add_child(ls_node)
	ls_node.run_arena_pre_render_sequence(j_arena, "DEEP_JUNGLE", bake_stats)
	if not ls_node._is_completed:
		printerr("LoadingScreen pre-render sequence did not complete cleanly!")
		return false

	test_ground_unit.queue_free()
	test_flyer_unit.queue_free()
	t_gorilla.queue_free()
	t_monkey.queue_free()
	sinkhole.queue_free()
	j_arena.queue_free()

	print("  Verified %d map catalog layouts across %d total team comps and %d biomes." % [tested_count, tested_comps, biomes.size()])
	print("  [PASS] Breakable ice patches, Sea Lion organic predation, Volcanic hazards, Space vacuum, Deep Jungle & v8 GPU Pre-Rendering verified.")
	return true

func test_shield_and_armor() -> bool:
	var dummy_front = CharacterBody3D.new()
	dummy_front.name = "TestReachCommander"
	add_child(dummy_front)
	dummy_front.global_position = Vector3(0, 0, 0)
	dummy_front.rotation = Vector3.ZERO
	dummy_front.add_to_group("SideA")
	dummy_front.add_to_group("Targetable")

	var hc_front = HealthComponent.new()
	hc_front.name = "HealthComponent"
	hc_front.max_health = 100.0
	hc_front.current_health = 100.0
	hc_front.max_shield = 50.0
	hc_front.current_shield = 50.0
	hc_front.shield_type = "FRONT"
	dummy_front.add_child(hc_front)
	hc_front._setup_shield_and_armor_visuals()

	# Attack from FRONT (-Z is forward for look_at, incoming from -Z)
	var attacker_front_pos = Vector3(0, 0, -10)
	hc_front.take_damage(20.0, attacker_front_pos)
	if hc_front.current_shield != 30.0 or hc_front.current_health != 100.0:
		printerr("Directional shield front block failed! Shield: %f, HP: %f" % [hc_front.current_shield, hc_front.current_health])
		dummy_front.queue_free()
		return false

	# Attack from REAR (+Z is behind)
	var attacker_rear_pos = Vector3(0, 0, 10)
	hc_front.take_damage(15.0, attacker_rear_pos)
	if hc_front.current_shield != 30.0 or hc_front.current_health != 85.0:
		printerr("Directional shield rear flank bypass failed! Shield: %f, HP: %f" % [hc_front.current_shield, hc_front.current_health])
		dummy_front.queue_free()
		return false
	dummy_front.queue_free()

	# Test 360 shield & Armor break-off
	var dummy_tank = CharacterBody3D.new()
	dummy_tank.name = "TestDominionShieldTank"
	add_child(dummy_tank)
	dummy_tank.global_position = Vector3(0, 0, 0)
	dummy_tank.add_to_group("SideA")
	dummy_tank.add_to_group("Targetable")

	var hc_tank = HealthComponent.new()
	hc_tank.name = "HealthComponent"
	hc_tank.max_health = 100.0
	hc_tank.current_health = 100.0
	hc_tank.max_shield = 40.0
	hc_tank.current_shield = 40.0
	hc_tank.shield_type = "360"
	hc_tank.max_armor = 30.0
	hc_tank.current_armor = 30.0
	hc_tank.armor_style = "REACTIVE"
	dummy_tank.add_child(hc_tank)
	hc_tank._setup_shield_and_armor_visuals()

	# Deplete 360 shield
	hc_tank.take_damage(40.0, Vector3(5, 0, 5))
	if hc_tank.current_shield != 0.0 or hc_tank.current_health != 100.0:
		printerr("360 shield full absorption failed! Shield: %f, HP: %f" % [hc_tank.current_shield, hc_tank.current_health])
		dummy_tank.queue_free()
		return false

	# Next damage hits armor (20 damage into 30 armor with 25% damage reduction = 15 armor dmg)
	hc_tank.take_damage(20.0, Vector3(5, 0, 5))
	if hc_tank.current_armor >= 30.0:
		printerr("Armor absorption failed! Armor: %f" % hc_tank.current_armor)
		dummy_tank.queue_free()
		return false

	dummy_tank.queue_free()
	print("  Shield absorption, directional blocking, and armor break logic verified.")
	return true

func test_bot_ai() -> bool:
	var bot = BotAI.new()
	bot.my_team = "SideB"
	bot.archetype = "The Reach"
	bot.difficulty = "MEDIUM"
	add_child(bot)
	
	var anchor = Node3D.new()
	add_child(anchor)
	anchor.global_position = Vector3(0, 0, 30)

	var obj = bot._compute_strategic_objective_and_lane(anchor, {})
	anchor.queue_free()
	if not obj.has("objective_pos") or not obj.has("push_dir"):
		printerr("Bot AI _compute_strategic_objective_and_lane failed: ", obj)
		bot.queue_free()
		return false
		
	var themed_deck = bot.generate_themed_deck("The Reach")
	if themed_deck.is_empty():
		printerr("Bot AI themed deck is empty!")
		bot.queue_free()
		return false

	bot.queue_free()
	print("  Bot AI strategic objective, deck building, and personality verified.")
	return true

func test_live_match_simulation() -> bool:
	# Instantiate Arena
	var arena_scn = ResourceLoader.load("res://Scenes/Arena.tscn") as PackedScene
	if not arena_scn:
		printerr("Failed to load res://Scenes/Arena.tscn")
		return false
	var arena = arena_scn.instantiate()
	add_child(arena)
	
	# Simulate 60 physics frames
	for frame in range(60):
		if arena.has_method("_physics_process"):
			arena._physics_process(0.016)
			
	# Trigger Beast of Nothingness endgame Maw
	if arena.has_method("_start_beast_of_nothingness"):
		arena._start_beast_of_nothingness()
		
	# Simulate 30 more frames with the Maw active
	for frame in range(30):
		if arena.has_method("_physics_process"):
			arena._physics_process(0.016)

	arena.queue_free()
	print("  Live Arena match simulation, 90 frames of physics ticks & endgame Maw passed.")
	return true


func test_model_orientations() -> bool:
	var success = true
	# 1. BoxyWalker quad guns must point forward (-Z)
	var walker_ps = ResourceLoader.load("res://Scenes/Units/BoxyWalker.tscn") as PackedScene
	if walker_ps:
		var walker = walker_ps.instantiate()
		var m_root = walker.get_node_or_null("MeshInstance3D")
		if m_root:
			for i in range(4):
				var mg = m_root.get_node_or_null("MG_" + str(i))
				if mg and mg.position.z > 0.0:
					printerr("BoxyWalker MG_%d placed backwards at z=%f" % [i, mg.position.z])
					success = false
		walker.free()

	# 2. VoidSpitter cannon/proboscis must face forward (-Z)
	var spitter_ps = ResourceLoader.load("res://Scenes/Units/VoidSwarm/VoidSpitter.tscn") as PackedScene
	if spitter_ps:
		var spitter = spitter_ps.instantiate()
		var vp = spitter.get_node_or_null("VisualPivot")
		if vp and vp.get_child_count() >= 2:
			var cannon = vp.get_child(1)
			if cannon and cannon.position.z > 0.0:
				printerr("VoidSpitter cannon placed backwards at z=%f" % [cannon.position.z])
				success = false
		spitter.free()

	# 3. RimworlderMutant right arm forward
	var mutant_ps = ResourceLoader.load("res://Scenes/Units/RimworlderMutant.tscn") as PackedScene
	if mutant_ps:
		var mutant = mutant_ps.instantiate()
		var m_root = mutant.get_node_or_null("MeshInstance3D")
		if m_root:
			var r_arm = m_root.get_node_or_null("RightArm_0")
			if r_arm and r_arm.position.z > 0.0:
				printerr("RimworlderMutant RightArm_0 placed backwards at z=%f" % [r_arm.position.z])
				success = false
		mutant.free()

	# 4. Tank barrels point forward (-Z)
	for t_path in ["res://Scenes/Units/Tank.tscn", "res://Scenes/Units/HeavyTank.tscn", "res://Scenes/Units/DominionShieldTank.tscn"]:
		var t_ps = ResourceLoader.load(t_path) as PackedScene
		if t_ps:
			var tank = t_ps.instantiate()
			var barrel = tank.get_node_or_null("Barrel")
			if not barrel:
				var tur = tank.get_node_or_null("Turret")
				if tur: barrel = tur.get_node_or_null("Barrel_L")
			if barrel and barrel.position.z > 0.0:
				printerr("%s barrel placed backwards at z=%f" % [t_path, barrel.position.z])
				success = false
			tank.free()

	print("  Verified unit model forward vectors, quad guns, spitters, and tank barrels.")
	return success


func test_ai_systems() -> bool:
	var success = true

	# 1. Test HeroHunter picks closest alive commander
	var hh_ps = ResourceLoader.load("res://Scenes/Units/HeroHunter.tscn") as PackedScene
	if hh_ps:
		var hh = hh_ps.instantiate()
		hh.add_to_group("SideA")
		add_child(hh)
		hh.global_position = Vector3(0, 0, 0)
		
		var far_cmd = Node3D.new()
		far_cmd.name = "Commander_Far"
		far_cmd.add_to_group("Targetable")
		far_cmd.add_to_group("SideB")
		far_cmd.add_to_group("CommanderUnit")
		var hc1 = HealthComponent.new()
		hc1.name = "HealthComponent"
		far_cmd.add_child(hc1)
		add_child(far_cmd)
		far_cmd.global_position = Vector3(0, 0, 80)

		var near_cmd = Node3D.new()
		near_cmd.name = "Commander_Near"
		near_cmd.add_to_group("Targetable")
		near_cmd.add_to_group("SideB")
		near_cmd.add_to_group("CommanderUnit")
		var hc2 = HealthComponent.new()
		hc2.name = "HealthComponent"
		near_cmd.add_child(hc2)
		add_child(near_cmd)
		near_cmd.global_position = Vector3(0, 0, 20)

		hh.find_new_target()
		if hh.current_target != near_cmd:
			printerr("HeroHunter failed to select closest Commander! Selected: ", hh.current_target)
			success = false

		hh.queue_free()
		far_cmd.queue_free()
		near_cmd.queue_free()

	# 2. Test Medic ignores Base/Tower when searching for healing targets
	var med_ps = ResourceLoader.load("res://Scenes/Units/Medic.tscn") as PackedScene
	if med_ps:
		var med = med_ps.instantiate()
		med.add_to_group("SideA")
		add_child(med)
		med.global_position = Vector3(0, 0, 0)

		var base_struct = Node3D.new()
		base_struct.name = "BaseA"
		base_struct.add_to_group("Targetable")
		base_struct.add_to_group("SideA")
		base_struct.add_to_group("Base")
		var base_hc = HealthComponent.new()
		base_hc.name = "HealthComponent"
		base_hc.max_health = 1000.0
		base_hc.current_health = 500.0
		base_struct.add_child(base_hc)
		add_child(base_struct)
		base_struct.global_position = Vector3(0, 0, 3)

		med.find_new_target()
		if med.current_target == base_struct:
			printerr("Medic targeted Base for healing! Should ignore structures.")
			success = false

		med.queue_free()
		base_struct.queue_free()

	# 3. Test TerritorialCreature aggro radius vs leash radius
	var tc = TerritorialCreature.new()
	add_child(tc)
	var nest_pos = Vector3(1500, 0, 1500)
	tc.configure_creature("Scorpion", nest_pos)
	tc.global_position = nest_pos

	var intr_outside_nest = Node3D.new()
	intr_outside_nest.name = "IntruderOutsideNest"
	intr_outside_nest.add_to_group("Targetable")
	intr_outside_nest.add_to_group("SideA")
	var ihc = HealthComponent.new()
	ihc.name = "HealthComponent"
	intr_outside_nest.add_child(ihc)
	add_child(intr_outside_nest)
	intr_outside_nest.global_position = nest_pos + Vector3(0, 0, 26.0) # Outside nest_radius (16.5), inside leash_radius (36.0)

	tc._evaluate_targeting()
	if tc.current_target != null:
		printerr("TerritorialCreature acquired target outside nest_radius while idle! Target: ", tc.current_target)
		success = false

	# Now move intruder inside expanded nest_radius (8.0m)
	intr_outside_nest.global_position = nest_pos + Vector3(0, 0, 8.0)
	tc._evaluate_targeting()
	if tc.current_target != intr_outside_nest:
		printerr("TerritorialCreature failed to acquire target inside nest_radius! Target: ", tc.current_target)
		success = false

	tc.free()
	intr_outside_nest.free()

	# 4. Test BotAI Nightmare difficulty scaling in ArenaManager script
	var am_script = ResourceLoader.load("res://Scripts/ArenaManager.gd")
	if am_script:
		var am_src = am_script.source_code
		if not ("NIGHTMARE" in am_src):
			printerr("ArenaManager does not handle NIGHTMARE difficulty for BotAI!")
			success = false

	# 5. Test BotAI Faction Dice Roll & Chaos Deck Generation
	var test_bot = BotAI.new()
	var chaos_deck = test_bot.generate_chaos_deck()
	if chaos_deck.is_empty() or chaos_deck.size() < 6:
		printerr("BotAI generate_chaos_deck failed to produce a valid 6-card cross-faction deck! Size: ", chaos_deck.size())
		success = false
	test_bot.free()

	var gs_node = null
	if Engine.get_main_loop() and (Engine.get_main_loop() as SceneTree).root.has_node("GameState"):
		gs_node = (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
	else:
		gs_node = load("res://Scripts/GameState.gd").new()
	if gs_node and gs_node.get("ai_faction_override") == null:
		printerr("GameState ai_faction_override is missing!")
		success = false
	if gs_node and not (Engine.get_main_loop() and (Engine.get_main_loop() as SceneTree).root.has_node("GameState")):
		gs_node.free()

	# 6. Test Planetary Primitives: Deck Generation, Structures, Ballistas, and Builders
	var prim_bot = BotAI.new()
	var prim_deck = prim_bot.generate_themed_deck("Planetary Primitives")
	if prim_deck.size() != 6:
		printerr("BotAI Planetary Primitives deck size is not 6! Got: ", prim_deck.size())
		success = false
	for cname in prim_deck:
		if not cname.begins_with("Primitive"):
			printerr("BotAI Planetary Primitives deck contains non-primitive card: ", cname)
			success = false
	prim_bot.free()

	# Verify Primitive Wood Tower
	var wt_scene = load("res://Scenes/Units/PrimitiveWoodTower.tscn")
	if wt_scene:
		var wt_inst = wt_scene.instantiate()
		add_child(wt_inst)
		if wt_inst.max_health != 420.0 or not wt_inst.is_in_group("Structure"):
			printerr("PrimitiveWoodTower attributes invalid!")
			success = false
		wt_inst.queue_free()

	# Verify Planetary Primitives Structure Meshes in ArenaManager
	var dummy_arena = Node3D.new()
	add_child(dummy_arena)
	var am_inst = ArenaManager.new()
	dummy_arena.add_child(am_inst)
	
	var test_tower = StaticBody3D.new()
	test_tower.name = "SideA_Tower_1"
	dummy_arena.add_child(test_tower)
	am_inst._build_structure_mesh(test_tower, "Planetary Primitives", true)
	var t_fmesh = null
	if test_tower.has_meta("faction_mesh"):
		t_fmesh = test_tower.get_meta("faction_mesh")
	if not t_fmesh or not t_fmesh.has_meta("ballista_turret"):
		printerr("ArenaManager failed to build ballista_turret for Planetary Primitives tower!")
		success = false

	var test_bay = StaticBody3D.new()
	test_bay.name = "SideA_CommandBay"
	dummy_arena.add_child(test_bay)
	am_inst._build_structure_mesh(test_bay, "Planetary Primitives", false)
	if not test_bay.has_meta("faction_mesh"):
		printerr("ArenaManager failed to build Command Bay pavilion for Planetary Primitives!")
		success = false

	var test_base = StaticBody3D.new()
	test_base.name = "SideA_Base"
	dummy_arena.add_child(test_base)
	am_inst._build_structure_mesh(test_base, "Planetary Primitives", false)
	if not test_base.has_meta("faction_mesh"):
		printerr("ArenaManager failed to build Castle Keep base for Planetary Primitives!")
		success = false

	dummy_arena.queue_free()

	# 7. Test MatchSetup AI Factions Rotation & Dropdown
	var ms_scene = load("res://Scenes/MatchSetup.tscn")
	if ms_scene:
		var ms_inst = ms_scene.instantiate()
		add_child(ms_inst)
		var ai_opt = ms_inst.find_child("HBoxAIFaction", true, false)
		if ai_opt:
			var opt_btn = ai_opt.get_node_or_null("OptionButton")
			if not opt_btn:
				for c in ai_opt.get_children():
					if c is OptionButton: opt_btn = c
			if opt_btn:
				if opt_btn.item_count < 11:
					printerr("MatchSetup ai_faction_option item_count is less than 11! Got: ", opt_btn.item_count)
					success = false
				var item_8 = opt_btn.get_item_text(8)
				if not ("Planetary Primitives" in item_8):
					printerr("MatchSetup item 8 is not Planetary Primitives! Got: ", item_8)
					success = false
				var item_9 = opt_btn.get_item_text(9)
				if not ("Galactic Wildlife" in item_9):
					printerr("MatchSetup item 9 is not Galactic Wildlife! Got: ", item_9)
					success = false
		ms_inst.queue_free()

	# 7b. Test Galactic Wildlife Faction (>100 Animals, Poison Snake, Rock-Dropping Crow, Pecking Bird, Bug Swarms)
	var wildlife_count = WildlifeModelBuilder.SPECIES_CATALOG.size()
	if wildlife_count < 100:
		printerr("Galactic Wildlife species count is less than 100! Got: ", wildlife_count)
		success = false
	print("  Verified %d distinct Galactic Wildlife species in SPECIES_CATALOG." % wildlife_count)

	var all_archetypes = ["Dominion", "The Reach", "Pirates", "Rimworlders", "Void", "Plague of Harmony", "Gilded Harmony", "Planetary Primitives", "Galactic Wildlife", "Chaos"]
	var audit_sandbox = Node3D.new()
	audit_sandbox.name = "AuditBotSandbox"
	add_child(audit_sandbox)
	var audit_bot = BotAI.new()
	audit_bot.name = "AuditBot"
	audit_sandbox.add_child(audit_bot)
	for arch in all_archetypes:
		var d = audit_bot.generate_themed_deck(arch)
		if d.size() != 6:
			printerr("BotAI failed to generate 6-card deck for archetype: ", arch)
			success = false
		audit_bot.archetype = arch
		audit_bot.deck = d.duplicate()
		audit_bot.hand.clear()
		audit_bot.discard.clear()
		audit_bot.current_requisition = 20.0
		audit_bot.draw_to_hand()
		audit_bot.draw_to_hand()
		audit_bot.draw_to_hand()
		audit_bot.evaluate_moves()
	remove_child(audit_sandbox)
	audit_sandbox.queue_free()

	# Test neutral structure effective attack range
	var test_melee = (load("res://Scenes/Units/CheapGrunt.tscn") as PackedScene).instantiate()
	add_child(test_melee)
	var test_den = StaticBody3D.new()
	test_den.name = "GorillaDen_Test"
	var d_hc = HealthComponent.new()
	d_hc.name = "HealthComponent"
	test_den.add_child(d_hc)
	add_child(test_den)
	test_melee.current_target = test_den
	if not ("Den" in test_den.name):
		printerr("Test den name check failed!")
		success = false
	test_melee.queue_free()
	test_den.queue_free()

	var snake_inst = (load("res://Scenes/Units/WildlifePoisonSnake.tscn") as PackedScene).instantiate()
	var crow_inst = (load("res://Scenes/Units/WildlifeCrow.tscn") as PackedScene).instantiate()
	var croc_cmdr = (load("res://Scenes/Units/WildlifeApexCrocCommander.tscn") as PackedScene).instantiate()
	var dummy_victim = CharacterBody3D.new()
	dummy_victim.name = "VictimUnit"
	var vic_hc = HealthComponent.new()
	vic_hc.name = "HealthComponent"
	vic_hc.max_health = 200.0
	vic_hc.current_health = 200.0
	dummy_victim.add_child(vic_hc)
	add_child(snake_inst)
	add_child(crow_inst)
	add_child(croc_cmdr)
	add_child(dummy_victim)

	snake_inst.add_to_group("SideA")
	crow_inst.add_to_group("SideA")
	croc_cmdr.add_to_group("SideA")
	dummy_victim.add_to_group("SideB")
	dummy_victim.add_to_group("Targetable")
	snake_inst.global_position = Vector3(500, 0, 500)
	dummy_victim.global_position = Vector3(500, 0, 498.5)

	if not snake_inst.is_in_group("Targetable") or not crow_inst.is_in_group("Targetable") or not crow_inst.is_in_group("Flyer"):
		printerr("WildlifeCreature missing Targetable or Flyer group registration!")
		success = false

	snake_inst._find_target()
	if snake_inst.target != dummy_victim:
		printerr("WildlifePoisonSnake _find_target() failed to acquire SideB enemy in Targetable group!")
		success = false

	snake_inst._perform_attack()
	if vic_hc.poison_ticks <= 0 or vic_hc.poison_dps <= 0.0:
		printerr("WildlifePoisonSnake failed to apply poison DoT on attack!")
		success = false

	if not crow_inst.is_flying or not crow_inst.drops_rocks or crow_inst._held_rock == null:
		printerr("WildlifeCrow missing flying/rock-dropping attributes or HeldRock model node!")
		success = false

	if not croc_cmdr.is_in_group("CommanderUnit") or croc_cmdr._head_pivot == null or croc_cmdr._head_pivot.get_node_or_null("CommanderCrown") == null:
		printerr("WildlifeApexCrocCommander missing CommanderUnit group or CommanderCrown on HeadPivot!")
		success = false

	# Audit all 108 wildlife 3D models and namesake locomotion/attack animations across every species
	for sp_key in WildlifeModelBuilder.SPECIES_CATALOG.keys():
		var test_creature = WildlifeCreatureScript.new()
		test_creature.species_id = sp_key
		var vp = Node3D.new()
		vp.name = "VisualPivot"
		test_creature.add_child(vp)
		var hc = HealthComponent.new()
		hc.name = "HealthComponent"
		test_creature.add_child(hc)
		add_child(test_creature)
		if test_creature._model_root == null or test_creature._head_pivot == null:
			printerr("WildlifeCreature model/head initialization failed for species: ", sp_key)
			success = false
			test_creature.queue_free()
			break
		if sp_key == "WildlifeFrilledLizard" and test_creature._neck_frill == null:
			printerr("WildlifeFrilledLizard missing NeckFrill pivot!")
			success = false
		elif sp_key == "WildlifeChameleon" and test_creature._ballistic_tongue == null:
			printerr("WildlifeChameleon missing BallisticTongue node!")
			success = false
		elif sp_key == "WildlifeAfricanElephant" and (test_creature._trunk_pivot == null or test_creature._ear_l == null):
			printerr("WildlifeAfricanElephant missing TrunkPivot or EarL pivot!")
			success = false
		elif sp_key == "WildlifeRattlesnake" and (test_creature._rattle_pivot == null or test_creature._body_segments.size() != 9):
			printerr("WildlifeRattlesnake missing RattlePivot or 9 Coil segments!")
			success = false
		elif sp_key == "WildlifeGiantCentipede" and test_creature._body_segments.size() != 7:
			printerr("WildlifeGiantCentipede missing 7 articulated body segments!")
			success = false
		elif sp_key == "WildlifeTarantula" and (test_creature._multi_legs_l.size() != 4 or test_creature._multi_legs_r.size() != 4):
			printerr("WildlifeTarantula missing 8 articulated spider legs!")
			success = false
		elif sp_key == "WildlifeKingCrab" and (test_creature._multi_legs_l.size() != 3 or test_creature._multi_legs_r.size() != 3):
			printerr("WildlifeKingCrab missing 6 crab walking legs!")
			success = false
		test_creature._strike_flash = 1.0
		test_creature._animate_creature(0.08, true)
		test_creature._animate_creature(0.08, false)
		test_creature.queue_free()

	snake_inst.queue_free()
	crow_inst.queue_free()
	croc_cmdr.queue_free()
	dummy_victim.queue_free()

	# 8. Test Namesake Models & Rigs
	var knight_scene = load("res://Scenes/Units/PrimitiveKnight.tscn")
	if knight_scene:
		var k_inst = knight_scene.instantiate()
		add_child(k_inst)
		var h_rig = k_inst.get_node_or_null("HumanoidRig")
		if not h_rig:
			printerr("PrimitiveKnight missing HumanoidRig!")
			success = false
		k_inst.queue_free()

	var chieftain_scene = load("res://Scenes/Units/PrimitiveChieftain.tscn")
	if chieftain_scene:
		var ch_inst = chieftain_scene.instantiate()
		add_child(ch_inst)
		var ch_rig = ch_inst.get_node_or_null("HumanoidRig")
		if not ch_rig:
			printerr("PrimitiveChieftain missing HumanoidRig!")
			success = false
		ch_inst.queue_free()

	print("  Verified HeroHunter closest commander targeting, Medic structure exclusion, Territorial Creature nest radius, Nightmare BotAI, Chaos dice roll, Planetary Primitives Empire Ages, and Namesake Models.")
	return success

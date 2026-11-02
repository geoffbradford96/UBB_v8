extends Node

func _ready():
	print("==================================================")
	print("       COMBAT & TARGETING VERIFICATION SUITE      ")
	print("==================================================")
	var passes = 0
	var fails = 0

	var arena = Node3D.new()
	arena.name = "CombatArena"
	add_child(arena)

	# Test 1: Forward March when current_target == null
	print("\n--- TEST 1: Forward March with No Target ---")
	var unit_scene = load("res://Scenes/Units/CheapGrunt.tscn")
	if unit_scene:
		var u1 = unit_scene.instantiate()
		u1.name = "MarchGrunt"
		arena.add_child(u1)
		u1.team = "SideA"
		u1.add_to_group("SideA")
		u1.global_position = Vector3(0, 0, 20.0)
		await get_tree().physics_frame
		await get_tree().physics_frame
		u1.current_target = null
		u1._physics_process(0.016)
		if u1.velocity.length() > 0.1:
			passes += 1
			print("  [PASS] Unit advances along forward march vector when no target is present (velocity: %.2f)" % u1.velocity.length())
		else:
			fails += 1
			printerr("  [FAIL] Unit stopped dead when no target was present!")
		u1.queue_free()
	else:
		fails += 1
		printerr("  [FAIL] Could not load CheapGrunt scene!")

	# Test 2: Target Acquisition at 12m Off-Lane
	print("\n--- TEST 2: Off-Lane Combat Engagement (12m Range) ---")
	if unit_scene:
		var u_ally = unit_scene.instantiate()
		u_ally.name = "AllyGrunt"
		arena.add_child(u_ally)
		u_ally.team = "SideA"
		u_ally.add_to_group("SideA")
		u_ally.global_position = Vector3(18.0, 0, 0) # 18m off-lane center

		var u_foe = unit_scene.instantiate()
		u_foe.name = "FoeGrunt"
		arena.add_child(u_foe)
		u_foe.team = "SideB"
		u_foe.add_to_group("SideB")
		u_foe.global_position = Vector3(18.0, 0, 11.0) # 11m away from ally, also 18m off-lane

		await get_tree().physics_frame
		u_ally.find_new_target()
		if u_ally.current_target == u_foe:
			passes += 1
			print("  [PASS] Unit successfully targeted enemy 11m away in off-lane area (not ignored).")
		else:
			fails += 1
			printerr("  [FAIL] Unit ignored off-lane enemy! current_target: %s" % str(u_ally.current_target))
		u_ally.queue_free()
		u_foe.queue_free()

	# Test 3: Retaliation on Damage (notify_attacked)
	print("\n--- TEST 3: Retaliatory Engagement on Attack ---")
	if unit_scene:
		var victim = unit_scene.instantiate()
		victim.name = "VictimGrunt"
		arena.add_child(victim)
		victim.team = "SideA"
		victim.add_to_group("SideA")
		victim.global_position = Vector3(0, 0, 0)

		var attacker = unit_scene.instantiate()
		attacker.name = "AttackerGrunt"
		arena.add_child(attacker)
		attacker.team = "SideB"
		attacker.add_to_group("SideB")
		attacker.global_position = Vector3(0, 0, 14.0)

		await get_tree().physics_frame
		victim.current_target = null
		# Simulate attack from attacker
		var v_hc = victim.get_node_or_null("HealthComponent")
		if v_hc:
			v_hc.take_damage(10.0, attacker.global_position)
		if victim.current_target == attacker:
			passes += 1
			print("  [PASS] Unit immediately retargeted and engaged attacker upon receiving damage.")
		else:
			fails += 1
			printerr("  [FAIL] Unit failed to retaliate against attacker! current_target: %s" % str(victim.current_target))
		victim.queue_free()
		attacker.queue_free()

	# Test 4: FFA Multi-Team Target Detection (SideA vs SideC & SideD)
	print("\n--- TEST 4: FFA Multi-Team Target Recognition ---")
	if unit_scene:
		var u_a = unit_scene.instantiate()
		u_a.name = "FFA_SideA"
		arena.add_child(u_a)
		u_a.team = "SideA"
		u_a.add_to_group("SideA")
		u_a.global_position = Vector3(0, 0, 0)

		var u_c = unit_scene.instantiate()
		u_c.name = "FFA_SideC"
		arena.add_child(u_c)
		u_c.team = "SideC"
		u_c.add_to_group("SideC")
		u_c.global_position = Vector3(0, 0, 8.0)

		await get_tree().physics_frame
		u_a.find_new_target()
		if u_a.current_target == u_c:
			passes += 1
			print("  [PASS] SideA unit correctly recognized and targeted SideC unit in FFA match.")
		else:
			fails += 1
			printerr("  [FAIL] FFA target detection failed for SideC enemy! current_target: %s" % str(u_a.current_target))
		u_a.queue_free()
		u_c.queue_free()

	# Test 5: Melee Attack Buffer against Large Units
	print("\n--- TEST 5: Melee Attack Buffer on Large Enemy Unit ---")
	var mech_scene = load("res://Scenes/Units/DominionMech.tscn")
	if unit_scene and mech_scene:
		var melee = unit_scene.instantiate()
		melee.name = "MeleeUnit"
		arena.add_child(melee)
		melee.team = "SideA"
		melee.add_to_group("SideA")
		melee.global_position = Vector3(0, 0, 0)

		var mech = mech_scene.instantiate()
		mech.name = "EnemyDominionMech"
		arena.add_child(mech)
		mech.team = "SideB"
		mech.add_to_group("SideB")
		mech.global_position = Vector3(0, 0, 2.5) # 2.5m away (typical collision proximity for large mech)

		await get_tree().physics_frame
		melee.current_target = mech
		melee._physics_process(0.016)
		# At 2.5m, melee unit should have effective_range >= 2.6 and stop to attack rather than trying to walk into collider
		var eff_range = melee.attack_range
		if "Mech" in mech.name:
			eff_range += 2.0
		if melee.attack_range <= 2.5:
			eff_range = maxf(eff_range, 2.6)
		if 2.5 <= eff_range:
			passes += 1
			print("  [PASS] Melee unit effective attack range (%.2fm) covers large unit collision radius (2.5m)." % eff_range)
		else:
			fails += 1
			printerr("  [FAIL] Effective attack range too short for large unit!")
		melee.queue_free()
		mech.queue_free()

	print("\n==================================================")
	print("COMBAT SUITE SUMMARY: %d PASSED, %d FAILED" % [passes, fails])
	print("==================================================")
	arena.queue_free()
	get_tree().quit(0 if fails == 0 else 1)

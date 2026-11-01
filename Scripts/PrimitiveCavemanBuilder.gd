class_name PrimitiveCavemanBuilder
extends CharacterBody3D

@export var speed: float = 4.4
@export var attack_damage: float = 15.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.0
@export var max_health: float = 110.0
@export var build_cooldown: float = 16.0
@export var unit_attribute: String = "Organic"

var current_target: Node3D = null
var current_repair_target: Node3D = null
var action_timer: float = 0.0
var build_timer: float = 2.0 # Ready to build shortly after spawning
var is_building: bool = false
var build_progress: float = 0.0
var humanoid_rig: HumanoidRig = null

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
	add_to_group("Targetable")
	
	_setup_collision()
	_setup_health_component()
	_setup_rig()

func _setup_collision():
	var col = get_node_or_null("CollisionShape3D")
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap = CapsuleShape3D.new()
		cap.radius = 0.42
		cap.height = 1.7
		col.shape = cap
		col.position.y = 0.85
		add_child(col)

func _setup_health_component():
	var hc = get_node_or_null("HealthComponent")
	if not hc:
		var health_script = load("res://Scripts/HealthComponent.gd")
		if health_script:
			hc = health_script.new()
			hc.name = "HealthComponent"
			add_child(hc)
	if hc:
		hc.set_max_health(max_health)
		if not hc.died.is_connected(_on_died):
			hc.died.connect(_on_died)

func _setup_rig():
	var rig_script = load("res://Scripts/HumanoidRig.gd")
	if rig_script:
		humanoid_rig = rig_script.new()
		humanoid_rig.name = "HumanoidRig"
		add_child(humanoid_rig)
		humanoid_rig.setup(self)

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	action_timer -= delta
	build_timer = max(0.0, build_timer - delta)

	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"):
			my_team = g
			break

	# 1. Building in progress
	if is_building:
		velocity = Vector3.ZERO
		build_progress += delta
		if humanoid_rig:
			humanoid_rig.animate(delta, false, false, speed)
			if int(build_progress * 5.0) % 2 == 0:
				humanoid_rig.trigger_attack(0.3)
		if build_progress >= 2.6:
			_complete_wood_tower_construction()
		move_and_slide()
		return

	# 2. Check if we should start constructing a new Wood Watchtower
	if build_timer <= 0.0 and _can_build_tower_here():
		_start_wood_tower_construction()
		return

	# 3. Combat & Movement evaluation
	_evaluate_targets()

	var is_moving = false

	# Attack hostile enemy if in range
	if is_instance_valid(current_target):
		var t_pos = current_target.global_position
		var dist = global_position.distance_to(t_pos)

		if dist > attack_range:
			var dir = (t_pos - global_position).normalized()
			dir.y = 0
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			is_moving = true

			var look_pos = Vector3(t_pos.x, global_position.y, t_pos.z)
			if global_position.distance_to(look_pos) > 0.1:
				var s_before = scale
				look_at(look_pos, Vector3.UP)
				scale = s_before
		else:
			# Stone mallet strike
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

			if action_timer <= 0.0:
				action_timer = 1.0 / max(0.01, attack_speed)
				_perform_mallet_strike(current_target)

	# Or repair damaged nearby wood tower / structure
	elif is_instance_valid(current_repair_target):
		var r_pos = current_repair_target.global_position
		var dist = global_position.distance_to(r_pos)
		if dist > 3.5:
			var dir = (r_pos - global_position).normalized()
			dir.y = 0
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			is_moving = true
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			if action_timer <= 0.0:
				action_timer = 1.0
				_perform_repair(current_repair_target)
	else:
		# March forward along lane
		var gs = _get_game_state()
		if gs:
			var lane_fwd = gs.get_lane_forward_vector(global_position, my_team)
			velocity.x = lane_fwd.x * speed
			velocity.z = lane_fwd.z * speed
			is_moving = true

			var look_pos = global_position + Vector3(lane_fwd.x, 0, lane_fwd.z)
			if global_position.distance_to(look_pos) > 0.1:
				var s_before = scale
				look_at(look_pos, Vector3.UP)
				scale = s_before
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	if humanoid_rig:
		humanoid_rig.animate(delta, is_moving, false, speed)

func _can_build_tower_here() -> bool:
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"):
			my_team = g
			break

	# Check distance to other friendly towers/structures (avoid stacking towers on top of each other)
	for s in get_tree().get_nodes_in_group("Structure"):
		if is_instance_valid(s) and s.is_in_group(my_team):
			if global_position.distance_to(s.global_position) < 14.0:
				return false

	# Must be on or near the field
	return true

func _start_wood_tower_construction():
	is_building = true
	build_progress = 0.0
	velocity = Vector3.ZERO
	print("Primitive Crafter started constructing Wood Watchtower at: ", global_position)

func _complete_wood_tower_construction():
	is_building = false
	build_timer = build_cooldown

	var tower_scene = preload("res://Scenes/Units/PrimitiveWoodTower.tscn")
	var scene_root = get_tree().current_scene if (is_inside_tree() and get_tree() and get_tree().current_scene) else get_parent()
	if tower_scene and scene_root:
		var tower = tower_scene.instantiate()
		var my_team = ""
		for g in get_groups():
			if g.begins_with("Side"):
				my_team = g
				break
		if my_team != "":
			tower.team = my_team
		tower.name = "ConstructedWoodTower_" + str(Time.get_ticks_usec())
		scene_root.add_child(tower)
		tower.global_position = global_position + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
		print("Primitive Crafter erected new Wood Watchtower for ", my_team)

func _evaluate_targets():
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"):
			my_team = g
			break

	# Check current target validity
	if is_instance_valid(current_target):
		var hc = current_target.get_node_or_null("HealthComponent")
		if hc == null or hc.is_dead or current_target.is_in_group(my_team):
			current_target = null

	# Find closest hostile
	if current_target == null and my_team != "":
		var best: Node3D = null
		var best_dist = 18.0
		for enemy in get_tree().get_nodes_in_group("Targetable"):
			if enemy == self or not is_instance_valid(enemy): continue
			if enemy.is_in_group(my_team) or enemy.is_in_group("NeutralCreature"): continue
			var hc = enemy.get_node_or_null("HealthComponent")
			if hc and not hc.is_dead:
				var d = global_position.distance_to(enemy.global_position)
				if d < best_dist:
					best_dist = d
					best = enemy
		current_target = best

	# Find nearby damaged friendly tower to repair
	if current_repair_target == null and my_team != "":
		for s in get_tree().get_nodes_in_group("Structure"):
			if is_instance_valid(s) and s.is_in_group(my_team):
				var hc = s.get_node_or_null("HealthComponent")
				if hc and not hc.is_dead and hc.current_health < hc.max_health:
					if global_position.distance_to(s.global_position) < 12.0:
						current_repair_target = s
						break

func _perform_mallet_strike(target: Node3D):
	if not is_instance_valid(target): return
	var hc = target.get_node_or_null("HealthComponent")
	if hc and not hc.is_dead:
		hc.take_damage(attack_damage, global_position)
	elif target.has_method("take_damage"):
		target.take_damage(attack_damage, global_position)
	if humanoid_rig:
		humanoid_rig.trigger_attack(0.3)

func _perform_repair(target: Node3D):
	if not is_instance_valid(target): return
	var hc = target.get_node_or_null("HealthComponent")
	if hc and not hc.is_dead:
		hc.current_health = min(hc.max_health, hc.current_health + 24.0)
		if hc.has_method("_refresh_hp_visuals"):
			hc._refresh_hp_visuals()
		if humanoid_rig:
			humanoid_rig.trigger_attack(0.3)

func _on_died():
	set_physics_process(false)

func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO):
	var hc = get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.take_damage(amount, source_pos)

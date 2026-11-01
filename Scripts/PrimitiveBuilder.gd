class_name PrimitiveBuilder
extends CharacterBody3D

@export var speed: float = 4.2
@export var repair_range: float = 3.6
@export var repair_amount: float = 28.0
@export var repair_rate: float = 1.0
@export var attack_damage: float = 14.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.2
@export var max_health: float = 85.0
@export var unit_attribute: String = "Organic"

var current_target: Node3D = null
var current_repair_target: Node3D = null
var action_timer: float = 0.0
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
		cap.radius = 0.4
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

	# Check repair targets or hostile targets
	_evaluate_targets()

	var is_moving = false
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"):
			my_team = g
			break

	# 1. Prioritize repairing damaged friendly structures / allies within reach
	if is_instance_valid(current_repair_target):
		var r_pos = current_repair_target.global_position
		var dist = global_position.distance_to(r_pos)
		var eff_range = repair_range
		if "Base" in current_repair_target.name:
			eff_range += 4.5
		elif "Tower" in current_repair_target.name or "CommandBay" in current_repair_target.name:
			eff_range += 2.2

		if dist > eff_range:
			var dir = (r_pos - global_position).normalized()
			dir.y = 0
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			is_moving = true

			var look_pos = Vector3(r_pos.x, global_position.y, r_pos.z)
			if global_position.distance_to(look_pos) > 0.1:
				var s_before = scale
				look_at(look_pos, Vector3.UP)
				scale = s_before
		else:
			# Within repair range: fix it!
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

			if action_timer <= 0.0:
				action_timer = repair_rate
				_perform_repair(current_repair_target)

	# 2. Or attack nearby enemies with utility knives
	elif is_instance_valid(current_target):
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
			# Slash with knife
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

			if action_timer <= 0.0:
				action_timer = 1.0 / max(0.01, attack_speed)
				_perform_knife_slash(current_target)
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

func _evaluate_targets():
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"):
			my_team = g
			break

	# Check current repair target validity
	if is_instance_valid(current_repair_target):
		var rhc = current_repair_target.get_node_or_null("HealthComponent")
		if rhc == null or rhc.is_dead or rhc.current_health >= rhc.max_health:
			current_repair_target = null

	# Find nearby damaged friendly structure or unit
	if current_repair_target == null and my_team != "":
		var best_rep: Node3D = null
		var best_rep_dist = 16.0
		for ally in get_tree().get_nodes_in_group(my_team):
			if ally == self or not is_instance_valid(ally): continue
			var hc = ally.get_node_or_null("HealthComponent")
			if hc and not hc.is_dead and hc.current_health < hc.max_health:
				var d = global_position.distance_to(ally.global_position)
				if d < best_rep_dist:
					best_rep_dist = d
					best_rep = ally
		current_repair_target = best_rep

	# Check hostile target validity
	if is_instance_valid(current_target):
		var hc = current_target.get_node_or_null("HealthComponent")
		if hc == null or hc.is_dead or current_target.is_in_group(my_team):
			current_target = null

	# Find hostile enemy
	if current_target == null and my_team != "":
		var best_enemy: Node3D = null
		var best_dist = 18.0
		for enemy in get_tree().get_nodes_in_group("Targetable"):
			if enemy == self or not is_instance_valid(enemy): continue
			if enemy.is_in_group(my_team) or enemy.is_in_group("NeutralCreature"): continue
			var hc = enemy.get_node_or_null("HealthComponent")
			if hc and not hc.is_dead:
				var d = global_position.distance_to(enemy.global_position)
				if d < best_dist:
					best_dist = d
					best_enemy = enemy
		current_target = best_enemy

func _perform_repair(target: Node3D):
	if not is_instance_valid(target): return
	var hc = target.get_node_or_null("HealthComponent")
	if hc and not hc.is_dead:
		hc.current_health = min(hc.max_health, hc.current_health + repair_amount)
		if hc.has_method("_refresh_hp_visuals"):
			hc._refresh_hp_visuals()
		if humanoid_rig:
			humanoid_rig.trigger_attack(0.35)
		_spawn_repair_sparks(target.global_position)

func _perform_knife_slash(target: Node3D):
	if not is_instance_valid(target): return
	var hc = target.get_node_or_null("HealthComponent")
	if hc and not hc.is_dead:
		hc.take_damage(attack_damage, global_position)
	elif target.has_method("take_damage"):
		target.take_damage(attack_damage, global_position)
	if humanoid_rig:
		humanoid_rig.trigger_attack(0.28)

func _spawn_repair_sparks(pos: Vector3):
	var spark = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 0.25
	sph.height = 0.5
	spark.mesh = sph
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.75, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.3)
	mat.emission_energy_multiplier = 4.0
	spark.material_override = mat
	spark.position = pos + Vector3(0, 1.0, 0)
	get_parent().add_child(spark)

	var tw = spark.create_tween()
	tw.tween_property(spark, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
	tw.finished.connect(Callable(spark, "queue_free"))

func _on_died():
	set_physics_process(false)

func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO):
	var hc = get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.take_damage(amount, source_pos)

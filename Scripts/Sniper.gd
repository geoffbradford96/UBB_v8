extends CharacterBody3D

@export var unit_attribute: String = "Organic"
@export var max_health: float = 100.0

@export var speed: float = 4.0
@export var attack_range: float = 35.0 # Must be >30 to reach the center lane from the flank!
@export var damage: float = 40.0
@export var attack_rate: float = 2.0


var current_target: Node3D = null
var attack_timer: float = 0.0
var flank_x: float = 30.0

var base_speed: float
var base_attack_speed: float

var humanoid_rig = null

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
	base_speed = speed
	if "attack_speed" in self:
		base_attack_speed = self.get("attack_speed")
	var health = get_node_or_null("HealthComponent")
	if health:
		if max_health != 100.0:
			health.max_health = max_health
			health.current_health = max_health
		else:
			max_health = health.max_health
			health.current_health = health.max_health
	# Decide whether to snipe from the left or right off-lane
	if randf() > 0.5:
		flank_x = -30.0

	var rig_script = load("res://Scripts/HumanoidRig.gd")
	if rig_script:
		humanoid_rig = rig_script.new()
		humanoid_rig.name = "HumanoidRig"
		add_child(humanoid_rig)
		humanoid_rig.setup(self)




func _physics_process(delta):
	_apply_reach_synergy()

	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	if has_meta("stealth_revealed_timer"):
		var __s_timer = get_meta("stealth_revealed_timer", 0.0)
		if __s_timer > 0.0:
			set_meta("stealth_revealed_timer", max(0.0, __s_timer - delta))
		
	if not has_meta("target_recheck"):
		set_meta("target_recheck", randf_range(0.8, 1.2))
	var __target_timer = get_meta("target_recheck") - delta
	set_meta("target_recheck", __target_timer)
	
	var target_is_dead = false
	if is_instance_valid(current_target):
		var target_hc = current_target.get_node_or_null("HealthComponent")
		if (target_hc and target_hc.is_dead) or not current_target.is_in_group("Targetable"):
			target_is_dead = true
	else:
		current_target = null
			
	if current_target == null or target_is_dead or __target_timer <= 0.0:
		if __target_timer <= 0.0 or target_is_dead: set_meta("target_recheck", randf_range(0.8, 1.2))
		find_new_target()
		
	var is_moving = false
	if is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		if dist > attack_range:
			# Move towards target, flanking along perpendicular line
			var to_target = current_target.global_position - global_position
			to_target.y = 0
			var perp = Vector3(-to_target.z, 0, to_target.x).normalized() if to_target.length() > 0.1 else Vector3.RIGHT
			var flank_offset = 20.0 * (1.0 if flank_x > 0 else -1.0)
			var target_pos = current_target.global_position + (perp * flank_offset)
			
			var next_path_pos = target_pos
			var new_velocity = global_position.direction_to(next_path_pos) * speed
			new_velocity.y = velocity.y
			velocity = new_velocity
			is_moving = true
		elif dist < 9.5 and not ("Base" in current_target.name or "Tower" in current_target.name):
			# Kite backward away from encroaching enemy while shooting!
			var away_dir = (global_position - current_target.global_position)
			away_dir.y = 0.0
			if away_dir.length_squared() > 0.01:
				away_dir = away_dir.normalized()
			else:
				away_dir = -global_transform.basis.z
			var kite_vel = away_dir * speed * 0.85
			velocity.x = kite_vel.x
			velocity.z = kite_vel.z
			is_moving = true
			
			attack_timer += delta
			if attack_timer >= attack_rate:
				attack_timer = 0.0
				set_meta("stealth_revealed_timer", 2.0)
				shoot()
		else:
			# Stop and Attack from afar
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			attack_timer += delta
			if attack_timer >= attack_rate:
				attack_timer = 0.0
				set_meta("stealth_revealed_timer", 2.0)
				shoot()

	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	var horiz_vel = Vector3(velocity.x, 0, velocity.z)
	var anim_mesh = get_node_or_null("MeshInstance3D")
	if not anim_mesh: anim_mesh = get_node_or_null("VisualPivot")
	if horiz_vel.length() > 0.1:
		var look_target = global_position + horiz_vel
		if global_position.distance_to(look_target) > 0.1:
			var s_before = scale
			look_at(look_target, Vector3.UP)
			scale = Vector3.ONE * float(get_meta('gilded_gen_scale')) if has_meta('gilded_gen_scale') else s_before
			if has_meta("gilded_gen_scale"):
				scale = Vector3.ONE * float(get_meta("gilded_gen_scale"))
		if anim_mesh and humanoid_rig == null:
			var t = Time.get_ticks_msec() / 1000.0 * speed * 2.0
			anim_mesh.rotation.z = sin(t) * 0.1
			anim_mesh.rotation.x = cos(t) * 0.1
		elif anim_mesh:
			anim_mesh.rotation.z = 0.0
			anim_mesh.rotation.x = 0.0
	else:
		if current_target != null and is_instance_valid(current_target):
			var look_target = current_target.global_position
			look_target.y = global_position.y
			if global_position.distance_to(look_target) > 0.1:
				var s_before = scale
				look_at(look_target, Vector3.UP)
				scale = Vector3.ONE * float(get_meta('gilded_gen_scale')) if has_meta('gilded_gen_scale') else s_before
				if has_meta("gilded_gen_scale"):
					scale = Vector3.ONE * float(get_meta("gilded_gen_scale"))
		if anim_mesh:
			anim_mesh.rotation.z = lerp(anim_mesh.rotation.z, 0.0, 10.0 * delta)
			anim_mesh.rotation.x = lerp(anim_mesh.rotation.x, 0.0, 10.0 * delta)
			
	if anim_mesh:
		anim_mesh.position.z = lerp(anim_mesh.position.z, 0.0, 10.0 * delta)
	# Anti-stuck wall sliding
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.length() < 0.1: wall_normal = Vector3.UP
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < speed * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * speed * 1.5
	
	move_and_slide()
	
	if humanoid_rig:
		var wounded = false
		var hc = get_node_or_null("HealthComponent")
		if hc and hc.has_method("is_critically_wounded"):
			wounded = hc.is_critically_wounded()
		humanoid_rig.animate(delta, is_moving, wounded, speed)
	else:
		var ap = get_node_or_null("AnimationPlayer")
		if ap:
			if ap.current_animation == "attack" and ap.is_playing():
				pass
			elif is_moving:
				if ap.has_animation("walk") and ap.current_animation != "walk":
					ap.play("walk", 0.2, speed * 0.5)
			else:
				if ap.has_animation("idle") and ap.current_animation != "idle":
					ap.play("idle", 0.2)


var projectile_scene = preload("res://Scenes/Projectile.tscn")

func shoot():
	if not is_instance_valid(current_target): return
	if humanoid_rig and humanoid_rig.has_method("trigger_attack"):
		humanoid_rig.trigger_attack(0.32)
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		var scene_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if scene_root:
			scene_root.add_child(proj)
			proj.global_position = global_position + Vector3(0, 1.5, 0)
			proj.target = current_target
			proj.set("damage", damage)
			proj.set("speed", 40.0) # Sniper bullets are fast!

		
		# Sniper rifle recoil kick
		var anim_mesh = get_node_or_null("MeshInstance3D")
		if not anim_mesh: anim_mesh = get_node_or_null("VisualPivot")
		if anim_mesh:
			anim_mesh.position.z += 0.25
		
		# Visual Polish: Blue laser trace
		var mesh = proj.get_node_or_null("MeshInstance3D")
		if mesh and mesh.mesh:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0, 0.5, 1)
			mat.emission_enabled = true
			mat.emission = Color(0, 0.5, 1)
			mat.emission_energy_multiplier = 4.0
			mesh.material_override = mat

func find_new_target():
	current_target = null
	if not is_inside_tree() or not get_tree():
		return
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"):
			my_team = g
			break
	if my_team == "":
		return
	var closest_dist = 99999.0
	var my_pos = global_position
	var gs = _get_game_state()

	for node in get_tree().get_nodes_in_group("Targetable"):
		if node == self or not is_instance_valid(node) or node.is_in_group(my_team):
			continue
		var d = my_pos.distance_to(node.global_position)
		if d >= closest_dist:
			continue
		if (node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure")) and d > 12.0:
			continue
		var target_hc = node.get_node_or_null("HealthComponent")
		if target_hc and target_hc.is_dead:
			continue
		if gs and gs.is_unit_stealthed_from(node, self):
			continue
		closest_dist = d
		current_target = node

# --- Reach faction synergy: faster move/attack + bigger model when clustered with other Reach units ---
var _reach_base_speed: float = -1.0
var _reach_base_atk: float = -1.0

func _apply_reach_synergy():
	if not "Reach" in name:
		return
	if not is_inside_tree() or not get_tree():
		return
	if _reach_base_speed < 0.0:
		_reach_base_speed = get("speed") if "speed" in self else 0.0
		if "attack_speed" in self: _reach_base_atk = get("attack_speed")
		elif "attack_rate" in self: _reach_base_atk = get("attack_rate")
	var my_team := ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
	if my_team == "":
		return
	var reach_count := 0
	for node in get_tree().get_nodes_in_group(my_team):
		if node != self and node is Node3D and "Reach" in node.name and global_position.distance_to(node.global_position) < 6.0:
			reach_count += 1
	var synergy: float = min(reach_count, 5) * 0.15
	if "speed" in self: set("speed", _reach_base_speed * (1.0 + synergy))
	if _reach_base_atk > 0.0:
		if "attack_speed" in self: set("attack_speed", _reach_base_atk * (1.0 + synergy))
		elif "attack_rate" in self: set("attack_rate", _reach_base_atk / (1.0 + synergy))
	var r_mesh = get_node_or_null("MeshInstance3D")
	if not r_mesh: r_mesh = get_node_or_null("VisualPivot")
	if r_mesh: r_mesh.scale = r_mesh.scale.lerp(Vector3.ONE * (1.0 + synergy * 0.6), 0.1)

func can_wander_off_path() -> bool:
	return true

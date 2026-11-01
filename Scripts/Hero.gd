extends CharacterBody3D

@export var unit_attribute: String = "Organic"
@export var max_health: float = 100.0
@export var max_shield: float = 0.0
@export var shield_type: String = "NONE" # "NONE", "360", "FRONT"
@export var shield_color: Color = Color(0.2, 0.75, 1.0, 0.45)
@export var shield_recharge_rate: float = 0.0
@export var max_armor: float = 0.0
@export var armor_style: String = "NONE" # "NONE", "SCRAP", "CHITIN", "STONE", "BONE", "REACTIVE", "GOLD"
@export var armor_color: Color = Color(0.7, 0.65, 0.55, 1.0)

@export var speed: float = 5.0
const ATTACK_RANGE = 2.0

@export var is_player_controlled: bool = false
@export var attack_damage: float = 25.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.0

var current_target: Node3D = null
var attack_timer: float = 0.0
var attack_anim_timer: float = 0.0

var mesh: Node3D

var walk_time: float = 0.0
var base_mesh_pos: Vector3 = Vector3.ZERO

var humanoid_rig = null

func is_humanoid() -> bool:
	var n = name
	for k in ["Overlord", "Spitter", "Stalker", "Crawler", "Spiker", "Tank", "Mech", "Plane", "Walker", "Spider", "Squid", "Beetle", "Jellyfish", "Octopus", "Leviathan"]:
		if k in n: return false
	return true

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
	mesh = get_node_or_null("VisualPivot")
	if not mesh: mesh = get_node_or_null("MeshInstance3D")
	if not mesh: mesh = get_node_or_null("Visuals")
	if not mesh: mesh = self # fallback
	add_to_group("Targetable")
		# Dynamically assign attribute based on name if not set manually
	if "Tank" in name or "Walker" in name or "Plane" in name or "Tower" in name or "Base" in name or "CommandBay" in name or "Mech" in name or "Leviathan" in name or "Spiker" in name:
		unit_attribute = "Mechanical"
	elif "Jellyfish" in name or "Beetle" in name or "Octopus" in name or "Squid" in name or "GreatBeastSpeaker" in name:
		unit_attribute = "Beast"

	var health = get_node_or_null("HealthComponent")
	if health:
		if max_health != 100.0:
			health.max_health = max_health
			health.current_health = max_health
		else:
			max_health = health.max_health
			health.current_health = health.max_health
			
		if max_shield > 0.0:
			health.max_shield = max_shield
			health.current_shield = max_shield
			health.shield_type = shield_type
			health.shield_color = shield_color
			health.shield_recharge_rate = shield_recharge_rate
		if max_armor > 0.0:
			health.max_armor = max_armor
			health.current_armor = max_armor
			health.armor_style = armor_style
			health.armor_color = armor_color
		if max_shield > 0.0 or max_armor > 0.0:
			health._setup_shield_and_armor_visuals()
			health._refresh_hp_visuals()

	if mesh:
		base_mesh_pos = mesh.position

	if is_humanoid():
		var rig_script = load("res://Scripts/HumanoidRig.gd")
		if rig_script:
			humanoid_rig = rig_script.new()
			humanoid_rig.name = "HumanoidRig"
			add_child(humanoid_rig)
			humanoid_rig.setup(self)
	elif "Overlord" in name and mesh and mesh != self:
		mesh.rotation.y = PI
		if mesh.get_node_or_null("OverlordCrown") == null:
			var horn_mat = StandardMaterial3D.new()
			horn_mat.albedo_color = Color(0.85, 0.1, 0.95)
			horn_mat.emission_enabled = true
			horn_mat.emission = Color(0.85, 0.1, 0.95)
			horn_mat.emission_energy_multiplier = 2.8
			var chitin_mat = StandardMaterial3D.new()
			chitin_mat.albedo_color = Color(0.16, 0.04, 0.24)
			chitin_mat.roughness = 0.25
			chitin_mat.metallic = 0.4
			var crown = Node3D.new()
			crown.name = "OverlordCrown"
			mesh.add_child(crown)
			for side in [-1.0, 1.0]:
				var horn = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.06
				cyl.bottom_radius = 0.38
				cyl.height = 2.4
				horn.mesh = cyl
				horn.material_override = horn_mat
				horn.position = Vector3(side * 1.15, 6.75, 0.4)
				horn.rotation_degrees = Vector3(22.0, 0.0, side * -28.0)
				crown.add_child(horn)
				# Shoulder sockets connecting carapace (r=2.0) to side wing blades (x=+-2.5)
				var w_sock = MeshInstance3D.new()
				var ws_sph = SphereMesh.new()
				ws_sph.radius = 0.65
				w_sock.mesh = ws_sph
				w_sock.material_override = chitin_mat
				w_sock.position = Vector3(side * 1.85, 4.1, 0.0)
				crown.add_child(w_sock)
				# 4 Lower Void Tendril Pillars anchoring the capsule bottom (y=1.0) to the ground
				for fb in [-1.0, 1.0]:
					var t_leg = MeshInstance3D.new()
					var tl_cyl = CylinderMesh.new()
					tl_cyl.top_radius = 0.55
					tl_cyl.bottom_radius = 0.22
					tl_cyl.height = 2.1
					t_leg.mesh = tl_cyl
					t_leg.material_override = chitin_mat
					t_leg.position = Vector3(side * 1.1, 0.95, fb * 0.95)
					t_leg.rotation_degrees = Vector3(fb * -16.0, 0.0, side * 16.0)
					crown.add_child(t_leg)




func _physics_process(delta):
	_apply_reach_synergy()

	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	if has_meta("stealth_revealed_timer"):
		var __s_timer = get_meta("stealth_revealed_timer", 0.0)
		if __s_timer > 0.0:
			set_meta("stealth_revealed_timer", max(0.0, __s_timer - delta))
		
	var is_moving = false
		
	if is_player_controlled:
		# Movement (Player Controlled)
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
		
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			is_moving = true
			# Rotate to face direction
			var look_target = global_position + direction
			if global_position.distance_to(look_target) > 0.1:
				var s_before = scale
				look_at(look_target, Vector3.UP)
				scale = s_before
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	else:
		# Movement (AI Controlled)
		if is_instance_valid(current_target):
			var dist = global_position.distance_to(current_target.global_position)
			var effective_range = attack_range
			if "Base" in current_target.name:
				effective_range += 5.5
			elif "Tower" in current_target.name or "CommandBay" in current_target.name:
				effective_range += 2.5
			if dist > effective_range:
				var next_path_pos = current_target.global_position
				var desired_dir = (next_path_pos - global_position)
				desired_dir.y = 0
				if desired_dir.length_squared() > 0.001: desired_dir = desired_dir.normalized()
				
				# Obstacle whisker avoidance
				var space_state = get_world_3d().direct_space_state
				if space_state and desired_dir.length_squared() > 0.1:
					var r_start = global_position + Vector3(0, 0.5, 0)
					var r_end = r_start + desired_dir * 3.4
					var fwd_query = PhysicsRayQueryParameters3D.create(r_start, r_end, 1, [get_rid()])
					var fwd_hit = space_state.intersect_ray(fwd_query)
					if not fwd_hit.is_empty() and fwd_hit.collider is StaticBody3D:
						var l_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(45.0))
						var r_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(-45.0))
						var l_hit = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(r_start, r_start + l_dir * 3.2, 1, [get_rid()]))
						var r_hit = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(r_start, r_start + r_dir * 3.2, 1, [get_rid()]))
						if r_hit.is_empty() and not l_hit.is_empty():
							desired_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(-55.0))
						elif l_hit.is_empty() and not r_hit.is_empty():
							desired_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(55.0))

				var new_velocity = desired_dir * speed
				new_velocity.y = velocity.y
				velocity = new_velocity
				
				# Ground lane confinement
				if not can_wander_off_path():
					var gs = _get_game_state()
					if gs:
						var dist_to_lane = gs.get_distance_to_nearest_lane(global_position)
						if dist_to_lane > 10.5:
							var lane_pull = gs.get_vector_towards_nearest_lane(global_position)
							var pull_strength = clamp((dist_to_lane - 10.5) * 1.5, 0.6, 2.8)
							velocity += lane_pull * speed * pull_strength
				is_moving = true
				
				# Rotate to face direction
				var look_target = Vector3(next_path_pos.x, global_position.y, next_path_pos.z)
				if global_position.distance_to(look_target) > 0.1:
					var s_before = scale
					look_at(look_target, Vector3.UP)
					scale = Vector3.ONE * float(get_meta("gilded_gen_scale")) if has_meta("gilded_gen_scale") else s_before
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
				
				# Face target while attacking
				var look_target = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
				if global_position.distance_to(look_target) > 0.1:
					var s_before = scale
					look_at(look_target, Vector3.UP)
					scale = Vector3.ONE * float(get_meta("gilded_gen_scale")) if has_meta("gilded_gen_scale") else s_before
		else:
			current_target = null
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
				
	# Anti-stuck wall sliding
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.length() < 0.1: wall_normal = Vector3.UP
		wall_normal.y = 0
		if wall_normal.length_squared() > 0.01:
			wall_normal = wall_normal.normalized()
			var desired_fwd = velocity
			desired_fwd.y = 0
			if desired_fwd.length_squared() < 0.1 and is_instance_valid(current_target):
				desired_fwd = current_target.global_position - global_position
				desired_fwd.y = 0
			var slide_t = desired_fwd.slide(wall_normal).normalized()
			if slide_t.length_squared() < 0.1:
				slide_t = Vector3(-wall_normal.z, 0, wall_normal.x)
			velocity.x = slide_t.x * speed * 1.2
			velocity.z = slide_t.z * speed * 1.2
	
	move_and_slide()
	
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
	
	if humanoid_rig:
		var wounded = false
		var hc = get_node_or_null("HealthComponent")
		if hc and hc.has_method("is_critically_wounded"):
			wounded = hc.is_critically_wounded()
		humanoid_rig.animate(delta, is_moving, wounded, speed)
	elif mesh:
		if attack_anim_timer > 0.0:
			attack_anim_timer = max(0.0, attack_anim_timer - delta)
		var atk_swing: float = sin((1.0 - (attack_anim_timer / 0.35)) * PI) if attack_anim_timer > 0.0 else 0.0
		if is_moving:
			walk_time += delta * speed * 2.0
			mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * 0.3
			mesh.rotation.z = sin(walk_time * 0.5) * 0.1
		else:
			walk_time += delta * 2.2
			mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y + sin(walk_time) * 0.14, 10.0 * delta)
			mesh.rotation.z = lerp(mesh.rotation.z, 0.0, 10.0 * delta)
		if "Overlord" in name and mesh.get_child_count() >= 4:
			var wing_r = mesh.get_child(2)
			var wing_l = mesh.get_child(3)
			var flap: float = sin(walk_time * 1.5) * 18.0 + atk_swing * 42.0
			if wing_r is Node3D:
				wing_r.rotation_degrees.z = 45.0 - flap
				wing_r.rotation_degrees.y = atk_swing * 35.0
			if wing_l is Node3D:
				wing_l.rotation_degrees.z = -45.0 + flap
				wing_l.rotation_degrees.y = -atk_swing * 35.0
			
		# Recover from attack lunge
		mesh.position.z = lerp(mesh.position.z, base_mesh_pos.z, 15.0 * delta)

	
	# Auto-Attack (AI Controlled)
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
		
	if is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = attack_range
		if "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist <= effective_range:
			attack_timer -= delta
			if attack_timer <= 0:
				attack_timer = 1.0 / max(0.01, attack_speed)
				var target_health = current_target.get_node_or_null("HealthComponent")
				if target_health:
					set_meta("stealth_revealed_timer", 2.0)
					target_health.take_damage(attack_damage, global_position)
					attack_anim_timer = 0.35
					if humanoid_rig and humanoid_rig.has_method("trigger_attack"):
						humanoid_rig.trigger_attack(0.35)
					var ap2 = get_node_or_null("AnimationPlayer")
					if ap2 and ap2.has_animation("attack"):
						ap2.play("attack", -1, attack_speed)
					# Attack lunge animation
					if mesh:
						mesh.position.z -= 0.5


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
	var gs = _get_game_state()
	var closest_dist = 99999.0
	var wander = can_wander_off_path()
	var my_pos = global_position

	for node in get_tree().get_nodes_in_group("Targetable"):
		if node == self or not is_instance_valid(node) or node.is_in_group(my_team):
			continue
		var d = my_pos.distance_to(node.global_position)
		if d >= closest_dist:
			continue
		if (node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure")) and d > 7.5:
			continue
		if not wander and gs and gs.get_distance_to_nearest_lane(node.global_position) > 14.5 and d > 7.5:
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
	if "Assassin" in name or "Hunter" in name or "Stalker" in name or "Sniper" in name or "Flyer" in name or unit_attribute == "Flying":
		return true
	return false

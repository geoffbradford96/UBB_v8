extends CharacterBody3D

@export var unit_attribute: String = "Organic"
@export var max_health: float = 100.0

@export var speed: float = 3.5
@export var attack_range: float = 18.0 
@export var damage: float = 15.0
@export var attack_rate: float = 1.2

var current_target: Node3D = null
var attack_timer: float = 0.0
var attack_anim_timer: float = 0.0

var projectile_scene = preload("res://Scenes/Projectile.tscn")

var humanoid_rig = null
var _spitter_legs: Array[Node3D] = []

func is_humanoid() -> bool:
	var n = name
	for k in ["Spitter", "Overlord", "Stalker", "Crawler", "Spiker", "Tank", "Mech", "Plane", "Walker", "Spider", "Squid", "Beetle", "Jellyfish", "Octopus"]:
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
	add_to_group("Targetable")
	var health = get_node_or_null("HealthComponent")
	if health:
		if max_health != 100.0:
			health.max_health = max_health
			health.current_health = max_health
		else:
			max_health = health.max_health
			health.current_health = health.max_health

	if is_humanoid():
		var rig_script = load("res://Scripts/HumanoidRig.gd")
		if rig_script:
			humanoid_rig = rig_script.new()
			humanoid_rig.name = "HumanoidRig"
			add_child(humanoid_rig)
			humanoid_rig.setup(self)
	elif "Spitter" in name:
		var vp = get_node_or_null("VisualPivot")
		if vp:
			vp.rotation.y = PI
			var chitin_mat = StandardMaterial3D.new()
			chitin_mat.albedo_color = Color(0.14, 0.03, 0.20)
			chitin_mat.roughness = 0.25
			chitin_mat.metallic = 0.45
			var collar = MeshInstance3D.new()
			var c_tor = TorusMesh.new()
			c_tor.inner_radius = 0.34
			c_tor.outer_radius = 0.56
			collar.mesh = c_tor
			collar.material_override = chitin_mat
			collar.rotation_degrees.x = 90.0
			collar.position = Vector3(0, 1.5, 1.08)
			vp.add_child(collar)
			for i in range(4):
				var side: float = -1.0 if (i % 2 == 0) else 1.0
				var fb: float = -0.6 if i < 2 else 0.6
				var coxa = MeshInstance3D.new()
				var cx_sph = SphereMesh.new()
				cx_sph.radius = 0.24
				coxa.mesh = cx_sph
				coxa.material_override = chitin_mat
				coxa.position = Vector3(side * 0.95, 1.05, fb)
				vp.add_child(coxa)
				var leg = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.14
				cyl.bottom_radius = 0.05
				cyl.height = 1.6
				leg.mesh = cyl
				leg.material_override = chitin_mat
				leg.position = Vector3(side * 1.12, 0.65, fb)
				leg.rotation_degrees.z = side * 32.0
				vp.add_child(leg)
				_spitter_legs.append(leg)



func _physics_process(delta):

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
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			attack_timer += delta
			if attack_timer >= attack_rate:
				attack_timer = 0.0
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
	
	if humanoid_rig:
		var wounded = false
		var hc = get_node_or_null("HealthComponent")
		if hc and hc.has_method("is_critically_wounded"):
			wounded = hc.is_critically_wounded()
		humanoid_rig.animate(delta, is_moving, wounded, speed)
	else:
		if attack_anim_timer > 0.0:
			attack_anim_timer = max(0.0, attack_anim_timer - delta)
		var atk_swing: float = sin((1.0 - (attack_anim_timer / 0.32)) * PI) if attack_anim_timer > 0.0 else 0.0
		var vp = get_node_or_null("VisualPivot")
		if vp and "Spitter" in name:
			var t_spit = Time.get_ticks_msec() * 0.006
			if vp.get_child_count() >= 2:
				var sac = vp.get_child(0)
				var cannon = vp.get_child(1)
				if sac is Node3D:
					var pulse: float = 1.0 + sin(t_spit) * 0.06 + atk_swing * 0.18
					sac.scale = Vector3(pulse, 1.0 / pulse, pulse)
				if cannon is Node3D:
					cannon.position.z = -1.5 + atk_swing * 0.45
			for i in range(_spitter_legs.size()):
				if is_instance_valid(_spitter_legs[i]):
					_spitter_legs[i].rotation.x = (sin(t_spit * 2.2 + float(i) * 1.57) * 0.35) if is_moving else 0.0
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


func shoot():
	set_meta("stealth_revealed_timer", 2.0)
	if not is_instance_valid(current_target): return
	attack_anim_timer = 0.32
	if humanoid_rig and humanoid_rig.has_method("trigger_attack"):
		humanoid_rig.trigger_attack(0.28)
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		var scene_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if scene_root:
			scene_root.add_child(proj)
			proj.global_position = global_position + Vector3(0, 1.0, 0)
			proj.target = current_target
			proj.set("damage", damage)
		
		# Make it look like a glowing bullet (or Void acid glob for VoidSpitter)
		var mesh = proj.get_node_or_null("MeshInstance3D")
		if mesh and mesh.mesh:
			var mat = StandardMaterial3D.new()
			var p_col = Color(0.85, 0.15, 0.95) if "Spitter" in name else Color(1, 0.8, 0)
			mat.albedo_color = p_col
			mat.emission_enabled = true
			mat.emission = p_col
			mat.emission_energy_multiplier = 2.4 if "Spitter" in name else 1.5
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
		var target_hc = node.get_node_or_null("HealthComponent")
		if target_hc and target_hc.is_dead:
			continue
		if gs and gs.is_unit_stealthed_from(node, self):
			continue
		closest_dist = d
		current_target = node

func can_wander_off_path() -> bool:
	return false




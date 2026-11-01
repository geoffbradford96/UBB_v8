extends CharacterBody3D

@export var team: String = "":
	set(v):
		team = v
		if team != "":
			for g in get_groups():
				if g.begins_with("Side"):
					remove_from_group(g)
			add_to_group(team)
@export var unit_attribute: String = "Mechanical"
@export var max_health: float = 100.0
@export var max_shield: float = 0.0
@export var shield_type: String = "NONE" # "NONE", "360", "FRONT"
@export var shield_color: Color = Color(0.2, 0.75, 1.0, 0.45)
@export var shield_recharge_rate: float = 0.0
@export var max_armor: float = 0.0
@export var armor_style: String = "NONE" # "NONE", "SCRAP", "CHITIN", "STONE", "BONE", "REACTIVE", "GOLD"
@export var armor_color: Color = Color(0.7, 0.65, 0.55, 1.0)

@export var speed: float = 3.0
@export var attack_range: float = 20.0
@export var damage: float = 30.0
@export var attack_rate: float = 1.5


var current_target: Node3D = null
var attack_timer: float = 0.0

var base_speed: float
var base_attack_speed: float

var _separation_query: PhysicsShapeQueryParameters3D = null
var _separation_shape: SphereShape3D = null

func _ready():
	add_to_group("Targetable")
	base_speed = speed
	if "attack_speed" in self:
		base_attack_speed = self.get("attack_speed")
	var vp_init = get_node_or_null("VisualPivot")
	if vp_init == null:
		vp_init = Node3D.new()
		vp_init.name = "VisualPivot"
		add_child(vp_init)
		for ch in get_children():
			if ch != vp_init and ch is MeshInstance3D and ch.name != "UnitGroundMarker":
				remove_child(ch)
				vp_init.add_child(ch)
	var health = get_node_or_null("HealthComponent")
	if health:
		if max_health != 100.0:
			health.max_health = max_health
			health.current_health = max_health
		else:
			max_health = health.max_health
			if health.current_health <= 0.0 or health.current_health == 100.0:
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
	_augment_tank_model()

func _augment_tank_model():
	var vp = get_node_or_null("VisualPivot")
	if not vp:
		return
	var metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.18, 0.20, 0.22)
	metal_mat.metallic = 0.85
	metal_mat.roughness = 0.35
	if vp.get_node_or_null("TurretRingCollar") == null:
		var collar = MeshInstance3D.new()
		collar.name = "TurretRingCollar"
		var c_cyl = CylinderMesh.new()
		c_cyl.top_radius = 0.82
		c_cyl.bottom_radius = 0.92
		c_cyl.height = 0.38
		collar.mesh = c_cyl
		collar.material_override = metal_mat
		collar.position = Vector3(0, 0.95, 0)
		vp.add_child(collar)
	var tur = vp.get_node_or_null("Turret")
	if tur and tur.get_node_or_null("GunMantlet") == null:
		var mantlet = MeshInstance3D.new()
		mantlet.name = "GunMantlet"
		var m_box = BoxMesh.new()
		m_box.size = Vector3(0.68, 0.44, 0.38)
		mantlet.mesh = m_box
		mantlet.material_override = metal_mat
		mantlet.position = Vector3(0, 0.0, -0.82)
		tur.add_child(mantlet)
	if "Scrap" in name and vp.get_node_or_null("ScrapRam") == null:
		var haz_mat = StandardMaterial3D.new()
		haz_mat.albedo_color = Color(0.82, 0.62, 0.14)
		haz_mat.roughness = 0.75
		var iron_mat = StandardMaterial3D.new()
		iron_mat.albedo_color = Color(0.18, 0.18, 0.20)
		iron_mat.metallic = 0.8
		var ram = MeshInstance3D.new()
		ram.name = "ScrapRam"
		var rbox = BoxMesh.new()
		rbox.size = Vector3(3.4, 0.75, 0.45)
		ram.mesh = rbox
		ram.material_override = haz_mat
		ram.position = Vector3(0, 0.45, -2.25)
		ram.rotation_degrees.x = -20.0
		vp.add_child(ram)
		for side in [-1.0, 1.0]:
			var strut = MeshInstance3D.new()
			var s_box = BoxMesh.new()
			s_box.size = Vector3(0.24, 0.24, 0.85)
			strut.mesh = s_box
			strut.material_override = iron_mat
			strut.position = Vector3(side * 0.85, 0.45, -1.82)
			vp.add_child(strut)
		var stack = MeshInstance3D.new()
		var scyl = CylinderMesh.new()
		scyl.top_radius = 0.20
		scyl.bottom_radius = 0.25
		scyl.height = 1.4
		stack.mesh = scyl
		stack.material_override = iron_mat
		stack.position = Vector3(1.0, 1.4, 1.35)
		stack.rotation_degrees.z = -12.0
		vp.add_child(stack)
	elif "Reach" in name and vp.get_node_or_null("ReachCore") == null:
		var cyan_mat = StandardMaterial3D.new()
		cyan_mat.albedo_color = Color(0.0, 0.9, 1.0)
		cyan_mat.emission_enabled = true
		cyan_mat.emission = Color(0.0, 0.9, 1.0)
		cyan_mat.emission_energy_multiplier = 3.2
		var white_mat = StandardMaterial3D.new()
		white_mat.albedo_color = Color(0.92, 0.95, 1.0)
		white_mat.roughness = 0.2
		var core = MeshInstance3D.new()
		core.name = "ReachCore"
		var csph = SphereMesh.new()
		csph.radius = 0.45
		core.mesh = csph
		core.material_override = cyan_mat
		core.position = Vector3(0, 1.45, -0.85)
		vp.add_child(core)
		for side in [-1.0, 1.0]:
			var strip = MeshInstance3D.new()
			var sbox = BoxMesh.new()
			sbox.size = Vector3(0.14, 0.25, 4.2)
			strip.mesh = sbox
			strip.material_override = cyan_mat
			strip.position = Vector3(side * 1.9, 0.5, 0.0)
			vp.add_child(strip)
			for z_off in [-1.1, 1.1]:
				var outrigger = MeshInstance3D.new()
				var o_box = BoxMesh.new()
				o_box.size = Vector3(0.75, 0.18, 0.28)
				outrigger.mesh = o_box
				outrigger.material_override = white_mat
				outrigger.position = Vector3(side * 1.52, 0.5, z_off)
				vp.add_child(outrigger)



func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var r = (loop as SceneTree).root
		if r and r.has_node("GameState"):
			return r.get_node("GameState")
	return null

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
		var effective_range = attack_range
		if "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist > effective_range:
			var next_path_pos = current_target.global_position
			var move_dir = (next_path_pos - global_position)
			move_dir.y = 0
			if move_dir.length_squared() > 0.001:
				move_dir = move_dir.normalized()
			
			# Obstacle whisker avoidance (detect dunes, trees, rocks, structures ahead)
			var space_state = get_world_3d().direct_space_state
			if space_state and move_dir.length_squared() > 0.1:
				var r_start = global_position + Vector3(0, 0.6, 0)
				var r_end = r_start + move_dir * 4.0
				var fwd_query = PhysicsRayQueryParameters3D.create(r_start, r_end, 1)
				fwd_query.exclude = [get_rid()]
				var fwd_hit = space_state.intersect_ray(fwd_query)
				if not fwd_hit.is_empty() and fwd_hit.collider is StaticBody3D:
					var l_dir = move_dir.rotated(Vector3.UP, deg_to_rad(45.0))
					var r_dir = move_dir.rotated(Vector3.UP, deg_to_rad(-45.0))
					var l_hit = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(r_start, r_start + l_dir * 3.6, 1, [get_rid()]))
					var r_hit = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(r_start, r_start + r_dir * 3.6, 1, [get_rid()]))
					if r_hit.is_empty() and not l_hit.is_empty():
						move_dir = move_dir.rotated(Vector3.UP, deg_to_rad(-55.0))
					elif l_hit.is_empty() and not r_hit.is_empty():
						move_dir = move_dir.rotated(Vector3.UP, deg_to_rad(55.0))
					else:
						var norm = fwd_hit.normal
						norm.y = 0
						if norm.length_squared() > 0.01:
							var tangent = move_dir.slide(norm.normalized()).normalized()
							if tangent.length_squared() > 0.1:
								move_dir = tangent

			var new_velocity = move_dir * speed
			new_velocity.y = velocity.y
			velocity = new_velocity
			
			# --- Separation / Collision Avoidance ---
			var my_team = ""
			for g in get_groups():
				if g.begins_with("Side"):
					my_team = g
					break
			if _separation_query == null:
				_separation_shape = SphereShape3D.new()
				_separation_shape.radius = 1.2
				_separation_query = PhysicsShapeQueryParameters3D.new()
				_separation_query.shape = _separation_shape
			_separation_query.transform = global_transform
			var results = space_state.intersect_shape(_separation_query)
			var separation = Vector3.ZERO
			var reach_count = 0
			for res in results:
				var col = res.collider
				if col != self and col.is_in_group(my_team):
					if "Reach" in self.name and "Reach" in col.name: reach_count += 1
					var push = global_position - col.global_position
					push.y = 0
					var dist_to_col = push.length()
					if dist_to_col < 1.2 and dist_to_col > 0.01:
						separation += push.normalized() * (1.2 - dist_to_col)
			# Apply lateral separation without reversing forward motion
			if move_dir.length_squared() > 0.01:
				var forward_dot = separation.dot(move_dir)
				var lateral = separation - move_dir * forward_dot
				velocity += lateral * speed * 1.2
				if forward_dot > 0: # forward push is okay, never reverse
					velocity += move_dir * forward_dot * speed * 0.5
			else:
				velocity += separation * speed * 1.2
			
			var gs = _get_game_state()
			if gs and not can_wander_off_path():
				var dist_to_lane = gs.get_distance_to_nearest_lane(global_position)
				if dist_to_lane > 10.5:
					var lane_pull = gs.get_vector_towards_nearest_lane(global_position)
					var pull_strength = clamp((dist_to_lane - 10.5) * 1.5, 0.6, 2.5)
					if move_dir.length_squared() > 0.01:
						var lane_dot = lane_pull.dot(move_dir)
						var lat_lane = lane_pull - move_dir * lane_dot
						velocity += lat_lane * speed * pull_strength
						if lane_dot > 0:
							velocity += move_dir * (lane_dot * speed * 0.4)
					else:
						velocity += lane_pull * speed * pull_strength

			
			if "Reach" in self.name:
				var synergy = min(reach_count, 5) * 0.15 # Up to +75% speed and attack speed
				speed = base_speed * (1.0 + synergy)
				if "attack_speed" in self:
					self.set("attack_speed", base_attack_speed * (1.0 + synergy))
				var r_mesh = get_node_or_null("MeshInstance3D")
				if not r_mesh: r_mesh = get_node_or_null("VisualPivot")
				if not r_mesh: r_mesh = get_node_or_null("Body")
				if r_mesh:
					var target_scale = 1.0 + (synergy * 0.6)
					r_mesh.scale = r_mesh.scale.lerp(Vector3(target_scale, target_scale, target_scale), 0.1)
			is_moving = true
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			attack_timer += delta
			var effective_rate = max(0.1, attack_rate)
			if attack_timer >= effective_rate:
				attack_timer = 0.0
				shoot()
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Tank facing orientation: always face forward towards target or movement vector
	var anim_mesh = get_node_or_null("VisualPivot")
	if not anim_mesh: anim_mesh = get_node_or_null("MeshInstance3D")
	if not anim_mesh: anim_mesh = get_node_or_null("Body")
	
	var facing_dir = Vector3.ZERO
	if current_target != null and is_instance_valid(current_target):
		facing_dir = (current_target.global_position - global_position)
		facing_dir.y = 0
	elif is_moving:
		facing_dir = Vector3(velocity.x, 0, velocity.z)
		
	if facing_dir.length() > 0.1:
		var look_target = global_position + facing_dir.normalized() * 5.0
		var s_before = scale
		look_at(look_target, Vector3.UP)
		scale = Vector3.ONE * float(get_meta('gilded_gen_scale')) if has_meta('gilded_gen_scale') else s_before
		if has_meta("gilded_gen_scale"):
			scale = Vector3.ONE * float(get_meta("gilded_gen_scale"))
		if anim_mesh and is_moving:
			var t = Time.get_ticks_msec() / 1000.0 * speed * 2.0
			anim_mesh.rotation.z = sin(t * 1.5) * 0.015
			anim_mesh.rotation.x = cos(t * 2.5) * 0.02
	else:
		if anim_mesh:
			anim_mesh.rotation.z = lerp(anim_mesh.rotation.z, 0.0, 10.0 * delta)
			anim_mesh.rotation.x = lerp(anim_mesh.rotation.x, 0.0, 10.0 * delta)
			
	if anim_mesh:
		anim_mesh.position.z = lerp(anim_mesh.position.z, 0.0, 10.0 * delta)
		var hc = get_node_or_null("HealthComponent")
		if hc and hc.has_method("is_vehicle_damaged") and hc.is_vehicle_damaged():
			anim_mesh.position.x = (randf() - 0.5) * 0.035
			anim_mesh.position.y = (randf() - 0.5) * 0.025
		else:
			anim_mesh.position.x = lerp(anim_mesh.position.x, 0.0, 10.0 * delta)
			anim_mesh.position.y = lerp(anim_mesh.position.y, 0.0, 10.0 * delta)

	# Anti-stuck wall sliding around obstacles (dunes, trees, rocks, structures)
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

var projectile_scene = preload("res://Scenes/Projectile.tscn")

func shoot():
	set_meta("stealth_revealed_timer", 2.0)
	if not is_instance_valid(current_target): return
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		var scene_root = get_tree().current_scene if (is_inside_tree() and get_tree() and get_tree().current_scene) else get_parent()
		if scene_root:
			scene_root.add_child(proj)
			proj.global_position = global_position + Vector3(0, 2.0, 0)
			proj.target = current_target
			proj.set("damage", damage)
			proj.set("speed", 25.0)
		
		# Cannon recoil kick
		var anim_mesh = get_node_or_null("VisualPivot")
		if not anim_mesh: anim_mesh = get_node_or_null("MeshInstance3D")
		if not anim_mesh: anim_mesh = get_node_or_null("Body")
		if anim_mesh:
			anim_mesh.position.z += 0.35

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

		var is_structure = "Base" in node.name or "Tower" in node.name or "CommandBay" in node.name
		if (node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure")) and d > 7.5:
			continue
		if not is_structure and gs and not wander and gs.get_distance_to_nearest_lane(node.global_position) > 14.5 and d > 7.5:
			continue

		var target_hc = node.get_node_or_null("HealthComponent")
		if target_hc and target_hc.is_dead:
			continue
		if gs and gs.is_unit_stealthed_from(node, self):
			continue

		closest_dist = d
		current_target = node

func can_wander_off_path() -> bool:
	if is_in_group("SideHarmony"):
		return true
	return false




extends CharacterBody3D

@export var unit_attribute: String = "Mechanical"
@export var max_health: float = 100.0
@export var max_shield: float = 0.0
@export var shield_type: String = "NONE" # "NONE", "360", "FRONT"
@export var shield_color: Color = Color(0.2, 0.75, 1.0, 0.45)
@export var shield_recharge_rate: float = 0.0
@export var max_armor: float = 0.0
@export var armor_style: String = "NONE" # "NONE", "SCRAP", "CHITIN", "STONE", "BONE", "REACTIVE", "GOLD"
@export var armor_color: Color = Color(0.7, 0.65, 0.55, 1.0)

@export var speed: float = 8.0
@export var attack_range: float = 15.0
@export var damage: float = 15.0
@export var attack_rate: float = 0.5


var current_target: Node3D = null
var attack_timer: float = 0.0
var flight_height: float = 8.0
var _propeller_node: Node3D = null

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
		health._setup_shield_and_armor_visuals()
		health._refresh_hp_visuals()

	var vp = get_node_or_null("VisualPivot")
	if vp:
		# Orient VisualPivot so the propeller (+Z in scene) faces forward (-Z in look_at) and tail (-Z in scene) is at rear!
		vp.rotation.y = PI
		for child in vp.get_children():
			if child is MeshInstance3D and child.mesh is BoxMesh:
				var sz: Vector3 = (child.mesh as BoxMesh).size
				if sz.x >= 1.4 and sz.y <= 0.25 and sz.z <= 0.25:
					_propeller_node = child
		if vp.get_node_or_null("PropSpinnerHub") == null:
			var hub_mat = StandardMaterial3D.new()
			hub_mat.albedo_color = Color(0.18, 0.20, 0.22)
			hub_mat.metallic = 0.85
			hub_mat.roughness = 0.3
			var hub = MeshInstance3D.new()
			hub.name = "PropSpinnerHub"
			var h_cyl = CylinderMesh.new()
			h_cyl.top_radius = 0.10
			h_cyl.bottom_radius = 0.28
			h_cyl.height = 0.42
			hub.mesh = h_cyl
			hub.material_override = hub_mat
			hub.rotation_degrees.x = 90.0
			hub.position = Vector3(0, 5.0, 1.58)
			vp.add_child(hub)
		if vp.get_node_or_null("Canopy") == null:
			var can_mat = StandardMaterial3D.new()
			var can_col = Color(0.0, 0.9, 1.0) if "Reach" in name else (Color(1.0, 0.45, 0.1) if "Scrap" in name else Color(1.0, 0.65, 0.1))
			can_mat.albedo_color = can_col
			can_mat.emission_enabled = true
			can_mat.emission = can_col
			can_mat.emission_energy_multiplier = 2.0
			var canopy = MeshInstance3D.new()
			canopy.name = "Canopy"
			var c_box = BoxMesh.new()
			c_box.size = Vector3(0.6, 0.4, 1.0)
			canopy.mesh = c_box
			canopy.material_override = can_mat
			canopy.position = Vector3(0, 5.5, -0.2)
			vp.add_child(canopy)
		if "Reach" in name and vp.get_node_or_null("ReachThruster") == null:
			var cyan_mat = StandardMaterial3D.new()
			cyan_mat.albedo_color = Color(0.0, 0.9, 1.0)
			cyan_mat.emission_enabled = true
			cyan_mat.emission = Color(0.0, 0.9, 1.0)
			cyan_mat.emission_energy_multiplier = 3.2
			var thrust = MeshInstance3D.new()
			thrust.name = "ReachThruster"
			var tsph = SphereMesh.new()
			tsph.radius = 0.38
			thrust.mesh = tsph
			thrust.material_override = cyan_mat
			thrust.position = Vector3(0, 5.0, -1.52)
			vp.add_child(thrust)

func _physics_process(delta):
	_apply_reach_synergy()

	# Planes fly! No gravity.
	global_position.y = flight_height
	if is_instance_valid(_propeller_node):
		_propeller_node.rotation.z += delta * 28.0
	
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
			# Move towards target
			var next_path_pos = current_target.global_position
			# Ignore Y direction changes for flying!
			next_path_pos.y = global_position.y
			var new_velocity = global_position.direction_to(next_path_pos) * speed
			velocity = new_velocity
			is_moving = true
		else:
			# Aircraft strafe/circle around target while in attack range!
			var to_target = current_target.global_position - global_position
			to_target.y = 0.0
			var tangent = Vector3(-to_target.z, 0, to_target.x).normalized() if to_target.length_squared() > 0.01 else Vector3.RIGHT
			var orbit_vel = tangent * speed * 0.72
			velocity.x = orbit_vel.x
			velocity.z = orbit_vel.z
			is_moving = true
			
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
		if anim_mesh:
			var t = Time.get_ticks_msec() / 1000.0 * speed * 2.0
			anim_mesh.rotation.z = lerp(anim_mesh.rotation.z, sin(t) * 0.05, 8.0 * delta)
			anim_mesh.rotation.x = lerp(anim_mesh.rotation.x, sin(t * 1.5) * 0.02, 8.0 * delta)
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
			anim_mesh.rotation.z = lerp(anim_mesh.rotation.z, 0.0, 8.0 * delta)
			anim_mesh.rotation.x = lerp(anim_mesh.rotation.x, 0.0, 8.0 * delta)
	# Anti-stuck wall sliding
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.length() < 0.1: wall_normal = Vector3.UP
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < speed * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * speed * 1.5
	
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
	if not is_instance_valid(current_target): return
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		var scene_root = get_tree().current_scene if (is_inside_tree() and get_tree() and get_tree().current_scene) else get_parent()
		if scene_root:
			scene_root.add_child(proj)
			var spawn_pos = global_position
			var vp = get_node_or_null("VisualPivot")
			if vp: spawn_pos.y += 5.0
			proj.global_position = spawn_pos
			proj.target = current_target
			proj.set("damage", damage)
			proj.set("speed", 30.0)


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
		var gs = _get_game_state()
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

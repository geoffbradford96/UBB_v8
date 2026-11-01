extends CharacterBody3D

@export var unit_attribute: String = "Organic"
@export var max_health: float = 100.0
@export var max_shield: float = 0.0
@export var shield_type: String = "NONE" # "NONE", "360", "FRONT"
@export var shield_color: Color = Color(0.2, 0.75, 1.0, 0.45)
@export var shield_recharge_rate: float = 0.0
@export var max_armor: float = 0.0
@export var armor_style: String = "NONE"
@export var armor_color: Color = Color(0.7, 0.65, 0.55, 1.0)

@export var speed: float = 6.0
@export var attack_range: float = 2.0
@export var damage: float = 15.0
@export var attack_rate: float = 0.5 # attacks fast!

var mesh: Node3D

var current_target: Node3D = null
var attack_timer: float = 0.0
var attack_anim_timer: float = 0.0
var is_invisible: bool = true

var base_speed: float
var base_attack_speed: float

var humanoid_rig = null
var _stalker_scythes: Array[Node3D] = []
var _stalker_legs: Array[Node3D] = []

func is_humanoid() -> bool:
	var n = name
	for k in ["Stalker", "Overlord", "Spitter", "Crawler", "Spiker", "Tank", "Mech", "Plane", "Walker", "Spider", "Squid", "Beetle", "Jellyfish", "Octopus"]:
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
	mesh = get_node_or_null("VisualPivot")
	if not mesh: mesh = get_node_or_null("MeshInstance3D")
	if not mesh: mesh = get_node_or_null("Visuals")
	if not mesh: mesh = self # fallback
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

	# Make Assassin partially transparent
	if mesh is MeshInstance3D and mesh.mesh:
		var active_mat = mesh.material_override
		if not active_mat and mesh.mesh.get_surface_count() > 0:
			active_mat = mesh.mesh.surface_get_material(0)
		if active_mat:
			var mat = active_mat.duplicate()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.3
			mesh.material_override = mat

	if is_humanoid():
		var rig_script = load("res://Scripts/HumanoidRig.gd")
		if rig_script:
			humanoid_rig = rig_script.new()
			humanoid_rig.name = "HumanoidRig"
			add_child(humanoid_rig)
			humanoid_rig.setup(self)
	elif "Stalker" in name and mesh and mesh != self:
		mesh.rotation.y = PI
		var scythe_mat = StandardMaterial3D.new()
		scythe_mat.albedo_color = Color(0.85, 0.12, 0.95, 0.78)
		scythe_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		scythe_mat.emission_enabled = true
		scythe_mat.emission = Color(0.85, 0.12, 0.95)
		scythe_mat.emission_energy_multiplier = 2.6
		var leg_mat = StandardMaterial3D.new()
		leg_mat.albedo_color = Color(0.14, 0.03, 0.22, 0.78)
		leg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		for side in [-1.0, 1.0]:
			var forearm = MeshInstance3D.new()
			var fa_cyl = CylinderMesh.new()
			fa_cyl.top_radius = 0.11
			fa_cyl.bottom_radius = 0.13
			fa_cyl.height = 0.72
			forearm.mesh = fa_cyl
			forearm.material_override = leg_mat
			forearm.position = Vector3(side * 0.48, 1.85, 0.52)
			forearm.rotation_degrees = Vector3(70.0, side * 32.0, 0.0)
			mesh.add_child(forearm)

			var scythe = MeshInstance3D.new()
			var pry = PrismMesh.new()
			pry.size = Vector3(0.18, 1.45, 0.55)
			scythe.mesh = pry
			scythe.material_override = scythe_mat
			scythe.position = Vector3(side * 0.68, 1.85, 0.82)
			scythe.rotation_degrees = Vector3(65.0, side * 15.0, side * -20.0)
			mesh.add_child(scythe)
			_stalker_scythes.append(scythe)
		for i in range(4):
			var side: float = -1.0 if (i % 2 == 0) else 1.0
			var fb: float = -0.45 if i < 2 else 0.45

			var coxa = MeshInstance3D.new()
			var c_sph = SphereMesh.new()
			c_sph.radius = 0.16
			coxa.mesh = c_sph
			coxa.material_override = leg_mat
			coxa.position = Vector3(side * 0.44, 1.05, fb)
			mesh.add_child(coxa)

			var leg = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.10
			cyl.bottom_radius = 0.04
			cyl.height = 1.45
			leg.mesh = cyl
			leg.material_override = leg_mat
			leg.position = Vector3(side * 0.62, 0.65, fb)
			leg.rotation_degrees.z = side * 26.0
			mesh.add_child(leg)
			_stalker_legs.append(leg)




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
		var effective_range = attack_range
		if "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist > effective_range:
			# Move
			var next_path_pos = current_target.global_position
			var new_velocity = global_position.direction_to(next_path_pos) * speed
			new_velocity.y = velocity.y
			velocity = new_velocity
			is_moving = true
		else:
			# Stop and Attack
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			attack_timer += delta
			if attack_timer >= attack_rate:
				attack_timer = 0.0
				print("Assassin slices ", current_target.name, "!")
				set_meta("stealth_revealed_timer", 2.0)
				var target_health = current_target.get_node_or_null("HealthComponent")
				if target_health:
					target_health.take_damage(damage, global_position)
					attack_anim_timer = 0.28
					if humanoid_rig and humanoid_rig.has_method("trigger_attack"):
						humanoid_rig.trigger_attack(0.26)
					var ap_action = get_node_or_null("AnimationPlayer")
					if ap_action and ap_action.has_animation("attack"):
						ap_action.play("attack")

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
			anim_mesh.rotation.z = sin(t) * 0.1
			anim_mesh.rotation.x = cos(t) * 0.1
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
		if attack_anim_timer > 0.0:
			attack_anim_timer = max(0.0, attack_anim_timer - delta)
		var atk_swing: float = sin((1.0 - (attack_anim_timer / 0.28)) * PI) if attack_anim_timer > 0.0 else 0.0
		var t_stalk = Time.get_ticks_msec() * 0.012
		for i in range(_stalker_scythes.size()):
			if is_instance_valid(_stalker_scythes[i]):
				var side: float = -1.0 if i == 0 else 1.0
				_stalker_scythes[i].rotation_degrees.x = 65.0 + atk_swing * 55.0
				_stalker_scythes[i].rotation_degrees.y = side * (15.0 - atk_swing * 40.0)
		for i in range(_stalker_legs.size()):
			if is_instance_valid(_stalker_legs[i]):
				_stalker_legs[i].rotation.x = (sin(t_stalk + float(i) * 1.57) * 0.42) if is_moving else 0.0
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
	var closest_off_lane_dist = 99999.0
	var closest_normal_dist = 99999.0
	var off_lane_target: Node3D = null
	var normal_target: Node3D = null
	var my_pos = global_position
	var gs = _get_game_state()

	for node in get_tree().get_nodes_in_group("Targetable"):
		if node == self or not is_instance_valid(node) or node.is_in_group(my_team):
			continue
		var target_hc = node.get_node_or_null("HealthComponent")
		if target_hc and target_hc.is_dead:
			continue
		if gs and gs.is_unit_stealthed_from(node, self):
			continue
		var d = my_pos.distance_to(node.global_position)
		if (node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure")) and d > 12.0:
			continue
		# Is the enemy a high-value backline target or off-lane flanker?
		var is_off_lane = (gs.get_distance_to_nearest_lane(node.global_position) > 12.0) if gs else (abs(node.global_position.x) > 18.0)
		var is_priority = "Sniper" in node.name or "Ranged" in node.name or "Hunter" in node.name or "Spitter" in node.name or "Medic" in node.name or "CommandBay" in node.name or is_off_lane
		if is_priority:
			if d < closest_off_lane_dist:
				closest_off_lane_dist = d
				off_lane_target = node
		else:
			if d < closest_normal_dist:
				closest_normal_dist = d
				normal_target = node
					
	# Prioritize off-lane target! If none, just go forward.
	if off_lane_target != null:
		current_target = off_lane_target
	elif normal_target != null:
		current_target = normal_target

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

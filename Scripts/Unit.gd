extends CharacterBody3D
class_name Unit

@export var team: String = "":
	set(v):
		team = v
		if team != "":
			for g in get_groups():
				if g.begins_with("Side"):
					remove_from_group(g)
			add_to_group(team)
@export var unit_attribute: String = "Organic"

var mesh: Node3D

@export var max_health: float = 100.0
@export var max_shield: float = 0.0
@export var shield_type: String = "NONE" # "NONE", "360", "FRONT"
@export var shield_color: Color = Color(0.2, 0.75, 1.0, 0.45)
@export var shield_recharge_rate: float = 0.0
@export var max_armor: float = 0.0
@export var armor_style: String = "NONE" # "NONE", "SCRAP", "CHITIN", "STONE", "BONE", "REACTIVE", "GOLD"
@export var armor_color: Color = Color(0.7, 0.65, 0.55, 1.0)

@export var speed: float = 4.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.0

var current_target: Node3D = null
var attack_timer: float = 0.0

# Procedural Animation vars
var walk_time: float = 0.0
var idle_anim_time: float = 0.0
var attack_anim_timer: float = 0.0
var base_mesh_pos: Vector3

var base_speed: float
var base_attack_speed: float
var humanoid_rig = null

var _separation_query: PhysicsShapeQueryParameters3D = null
var _separation_shape: SphereShape3D = null
var _lane_check_timer: float = 0.0
var _cached_lane_dist: float = 0.0
var _cached_lane_pull: Vector3 = Vector3.ZERO
const GpuAcceleratorScript = preload("res://Scripts/GpuAccelerator.gd")

func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var r = (loop as SceneTree).root
		if r and r.has_node("GameState"):
			return r.get_node("GameState")
	return null

func is_humanoid() -> bool:
	var n = name
	if "GreatBeastSpeaker" in n:
		return true
	if unit_attribute == "Mechanical" or unit_attribute == "Beast" or unit_attribute == "Ethereal":
		return false
	for k in ["Tank", "Mech", "Plane", "Walker", "Spider", "Tower", "Base", "CommandBay", "Squid", "Beetle", "Jellyfish", "Octopus", "Spiker", "Crawler", "Spitter", "Corruptor", "Overlord", "Stalker", "Gargoyle", "Voidling", "Scorpion", "Ant", "Digestive", "EyeOfHarmony", "BeastOfHarmony", "HarmonyInfector", "GildedHarmony", "Meteor", "Hazard", "Monstrous", "Mutant", "Leviathan"]:
		if k in n: return false
	return true

func _ready():
	mesh = get_node_or_null("VisualPivot")
	if not mesh: mesh = get_node_or_null("MeshInstance3D")
	if not mesh: mesh = get_node_or_null("Visuals")
	if not mesh: mesh = self # fallback
	base_speed = speed
	if self.get("attack_speed") != null:
		base_attack_speed = float(self.get("attack_speed"))
	else:
		base_attack_speed = 1.0

	add_to_group("Targetable")
	add_to_group("Units")

		# Dynamically assign attribute based on name if not set manually
	if "Tank" in name or "Walker" in name or "Plane" in name or "Tower" in name or "Base" in name or "CommandBay" in name or "Mech" in name or "Leviathan" in name or "Spiker" in name:
		unit_attribute = "Mechanical"
	elif "Jellyfish" in name or "Beetle" in name or "Octopus" in name or "Squid" in name or "GreatBeastSpeaker" in name:
		unit_attribute = "Beast"

	base_mesh_pos = mesh.position
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


	if "Nightmare" in name or "Halloween" in name:
		var n_builder = load("res://Scripts/NightmareModelBuilder.gd")
		if n_builder:
			n_builder.build_model(self, name)
	elif "Winter" in name or "Yuletide" in name or "Yule" in name:
		var w_builder = load("res://Scripts/WinterModelBuilder.gd")
		if w_builder:
			w_builder.build_model(self, name)
	elif "Magma" in name:
		var m_builder = load("res://Scripts/MagmaBornModelBuilder.gd")
		if m_builder:
			m_builder.build_model(self, name)
	elif is_humanoid():
		var rig_script = load("res://Scripts/HumanoidRig.gd")
		if rig_script:
			humanoid_rig = rig_script.new()
			humanoid_rig.name = "HumanoidRig"
			add_child(humanoid_rig)
			humanoid_rig.setup(self)
	else:
		_augment_non_humanoid_model()



func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Supreme Necromancer: Passive Soul Harvest / Raise Dead
	if "SupremeNecromancer" in name:
		if not has_meta("necro_summon_timer"):
			set_meta("necro_summon_timer", 6.5)
		var n_timer = (float(get_meta("necro_summon_timer")) if has_meta("necro_summon_timer") else 6.5) - delta
		if n_timer <= 0.0:
			set_meta("necro_summon_timer", 8.5)
			var sk_scene = load("res://Scenes/Units/NightmareSkeletonSwordsman.tscn")
			if sk_scene and is_inside_tree() and get_tree():
				var sk = sk_scene.instantiate()
				var my_team = ""
				for g in get_groups():
					if g.begins_with("Side"):
						my_team = g
						break
				sk.team = my_team
				var am_scene = get_tree().current_scene if get_tree().current_scene else get_parent()
				if am_scene:
					am_scene.add_child(sk)
				sk.global_position = global_position + Vector3(randf_range(-1.8, 1.8), 0.2, randf_range(-1.8, 1.8))
		else:
			set_meta("necro_summon_timer", n_timer)

	# Winter Yuletide King: Festive Bounty Passive Aura (+20% resilience / armor replenishment)
	if "YuletideKing" in name:
		if not has_meta("yuletide_bounty_timer"):
			set_meta("yuletide_bounty_timer", 2.0)
		var y_timer = (float(get_meta("yuletide_bounty_timer")) if has_meta("yuletide_bounty_timer") else 2.0) - delta
		if y_timer <= 0.0:
			set_meta("yuletide_bounty_timer", 2.5)
			var my_team = ""
			for g in get_groups():
				if g.begins_with("Side"): my_team = g; break
			if is_inside_tree() and get_tree():
				for ally in get_tree().get_nodes_in_group(my_team):
					if is_instance_valid(ally) and ally != self and ally is CharacterBody3D:
						if global_position.distance_to(ally.global_position) <= 12.0:
							var ahc = ally.get_node_or_null("HealthComponent")
							if ahc and not ahc.is_dead and ahc.max_armor > 0.0:
								ahc.current_armor = min(ahc.max_armor, ahc.current_armor + 15.0)
								ahc._refresh_hp_visuals()
		else:
			set_meta("yuletide_bounty_timer", y_timer)

	# Winter Krampus Lord: Terror of Yule Passive Aura (25% slow + 10 DPS frostburn)
	if "KrampusLord" in name:
		if not has_meta("krampus_terror_timer"):
			set_meta("krampus_terror_timer", 1.0)
		var k_timer = (float(get_meta("krampus_terror_timer")) if has_meta("krampus_terror_timer") else 1.0) - delta
		if k_timer <= 0.0:
			set_meta("krampus_terror_timer", 1.0)
			var my_team = ""
			for g in get_groups():
				if g.begins_with("Side"): my_team = g; break
			if is_inside_tree() and get_tree():
				for enemy in get_tree().get_nodes_in_group("Targetable"):
					if is_instance_valid(enemy) and not enemy.is_in_group(my_team) and enemy is CharacterBody3D:
						if global_position.distance_to(enemy.global_position) <= 10.0:
							var ehc = enemy.get_node_or_null("HealthComponent")
							if ehc and not ehc.is_dead:
								ehc.take_damage(10.0, global_position)
							enemy.velocity *= 0.75
		else:
			set_meta("krampus_terror_timer", k_timer)

	# Winter Yule Log: Charging Festive Munition Detonation
	if "YuleLog" in name:
		var should_detonate = false
		if is_instance_valid(current_target) and global_position.distance_to(current_target.global_position) <= 2.2:
			should_detonate = true
		if should_detonate:
			var my_team = ""
			for g in get_groups():
				if g.begins_with("Side"): my_team = g; break
			if is_inside_tree() and get_tree():
				for node in get_tree().get_nodes_in_group("Targetable"):
					if is_instance_valid(node) and not node.is_in_group(my_team) and node is CharacterBody3D:
						var d = global_position.distance_to(node.global_position)
						if d <= 4.8:
							var hc = node.get_node_or_null("HealthComponent")
							if hc and not hc.is_dead:
								hc.take_damage(attack_damage, global_position)
							var push_dir = (node.global_position - global_position).normalized()
							push_dir.y = 0.3
							node.velocity += push_dir * 10.0
			queue_free()
			return
		
	if has_meta("stealth_revealed_timer"):
		var __s_timer = float(get_meta("stealth_revealed_timer")) if has_meta("stealth_revealed_timer") else 0.0
		if __s_timer > 0.0:
			set_meta("stealth_revealed_timer", max(0.0, __s_timer - delta))
		
	# Basic AI: Find nearest enemy, move to it, attack.
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
		elif "Den" in current_target.name or "Burrow" in current_target.name or "Hill" in current_target.name or "Pit" in current_target.name:
			effective_range += 4.5
			
		if dist > effective_range:
			# Move towards target
			var next_path_pos = current_target.global_position
			var desired_dir = (next_path_pos - global_position)
			desired_dir.y = 0
			if desired_dir.length_squared() > 0.001:
				desired_dir = desired_dir.normalized()
			
			# Obstacle whisker avoidance (detect dunes, trees, rocks, structures ahead)
			var space_state = get_world_3d().direct_space_state
			if space_state and desired_dir.length_squared() > 0.1:
				var r_start = global_position + Vector3(0, 0.5, 0)
				var r_end = r_start + desired_dir * 3.6
				var fwd_query = PhysicsRayQueryParameters3D.create(r_start, r_end, 1)
				fwd_query.exclude = [get_rid()]
				var fwd_hit = space_state.intersect_ray(fwd_query)
				if not fwd_hit.is_empty() and fwd_hit.collider is StaticBody3D:
					var l_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(45.0))
					var r_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(-45.0))
					var l_hit = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(r_start, r_start + l_dir * 3.4, 1, [get_rid()]))
					var r_hit = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(r_start, r_start + r_dir * 3.4, 1, [get_rid()]))
					if r_hit.is_empty() and not l_hit.is_empty():
						desired_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(-55.0))
					elif l_hit.is_empty() and not r_hit.is_empty():
						desired_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(55.0))
					else:
						var norm = fwd_hit.normal
						norm.y = 0
						if norm.length_squared() > 0.01:
							var tangent = desired_dir.slide(norm.normalized()).normalized()
							if tangent.length_squared() > 0.1:
								desired_dir = tangent

			var new_velocity = desired_dir * speed
			new_velocity.y = velocity.y # Preserve gravity
			velocity = new_velocity
			
			# --- Separation / Friendly Unit Avoidance (O(1) Spatial Hash Grid via GpuAccelerator) ---
			var my_team = ""
			for g in get_groups():
				if g.begins_with("Side") or g == "Beast":
					my_team = g
					break
			var separation = Vector3.ZERO
			var reach_count = 0
			if unit_attribute != "Ethereal":
				var nearby = GpuAcceleratorScript.query_nearby_units(global_position, 1.25, get_tree())
				if not nearby.is_empty():
					for col in nearby:
						if col != self and is_instance_valid(col) and col.is_in_group(my_team):
							if "Reach" in self.name and "Reach" in col.name: reach_count += 1
							if col.get("unit_attribute") == "Ethereal": continue
							var push = global_position - col.global_position
							push.y = 0
							var dist_to_col = push.length()
							if dist_to_col < 1.2 and dist_to_col > 0.01:
								separation += push.normalized() * (1.2 - dist_to_col)
				elif space_state:
					if _separation_query == null:
						_separation_shape = SphereShape3D.new()
						_separation_shape.radius = 1.2
						_separation_query = PhysicsShapeQueryParameters3D.new()
						_separation_query.shape = _separation_shape
					_separation_query.transform = global_transform
					var results = space_state.intersect_shape(_separation_query)
					for res in results:
						var col = res.collider
						if col != self and col.is_in_group(my_team):
							if "Reach" in self.name and "Reach" in col.name: reach_count += 1
							if col.get("unit_attribute") == "Ethereal": continue
							var push = global_position - col.global_position
							push.y = 0
							var dist_to_col = push.length()
							if dist_to_col < 1.2 and dist_to_col > 0.01:
								separation += push.normalized() * (1.2 - dist_to_col)
			# Lateral separation to prevent clumping
			if desired_dir.length_squared() > 0.01:
				var f_dot = separation.dot(desired_dir)
				var lat = separation - desired_dir * f_dot
				velocity += lat * speed * 1.2
				if f_dot > 0: velocity += desired_dir * f_dot * speed * 0.5
			else:
				velocity += separation * speed * 1.2
			
			# Ground lane confinement: keep non-flanker units on the path across all maps
			var gs = _get_game_state()
			if gs and not can_wander_off_path():
				_lane_check_timer -= delta
				if _lane_check_timer <= 0.0:
					_lane_check_timer = 0.15
					var dist_to_lane = gs.get_distance_to_nearest_lane(global_position)
					if dist_to_lane > 10.5:
						_cached_lane_pull = gs.get_vector_towards_nearest_lane(global_position)
						_cached_lane_dist = dist_to_lane
					else:
						_cached_lane_dist = 0.0
				
				if _cached_lane_dist > 10.5:
					var lane_pull = _cached_lane_pull
					var pull_strength = clamp((_cached_lane_dist - 10.5) * 1.5, 0.6, 2.5)
					if desired_dir.length_squared() > 0.01:
						var lane_dot = lane_pull.dot(desired_dir)
						var lat_lane = lane_pull - desired_dir * lane_dot
						velocity += lat_lane * speed * pull_strength
						if lane_dot > 0:
							velocity += desired_dir * lane_dot * speed * 0.4
					else:
						velocity += lane_pull * speed * pull_strength

			
			if "Reach" in self.name:
				var synergy = min(reach_count, 5) * 0.15 # Up to +75% speed and attack speed
				speed = base_speed * (1.0 + synergy)
				if "attack_speed" in self:
					self.set("attack_speed", base_attack_speed * (1.0 + synergy))
				var r_mesh = get_node_or_null("MeshInstance3D")
				if not r_mesh: r_mesh = get_node_or_null("VisualPivot")
				if r_mesh:
					var target_scale = 1.0 + (synergy * 0.6)
					r_mesh.scale = r_mesh.scale.lerp(Vector3(target_scale, target_scale, target_scale), 0.1)
			is_moving = true
			
			# Rotate to face movement direction
			var look_target = Vector3(next_path_pos.x, global_position.y, next_path_pos.z)
			if global_position.distance_to(look_target) > 0.1:
				var s_before = scale
				look_at(look_target, Vector3.UP)
				scale = Vector3.ONE * float(get_meta("gilded_gen_scale")) if has_meta("gilded_gen_scale") else s_before
		else:
			# Stop and Attack
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			if is_instance_valid(current_target):
				# Rotate to face target while attacking
				var look_target = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
				if global_position.distance_to(look_target) > 0.1:
					var s_before = scale
					look_at(look_target, Vector3.UP)
					scale = Vector3.ONE * float(get_meta("gilded_gen_scale")) if has_meta("gilded_gen_scale") else s_before
					
				attack_timer -= delta
				if attack_timer <= 0:
					attack_timer = 1.0 / max(0.01, attack_speed)
					set_meta("stealth_revealed_timer", 2.0)
					var target_health = current_target.get_node_or_null("HealthComponent")
					if target_health:
						if "SkyJellyfish" in self.name or "StoneOctopus" in self.name or "DemonKnight" in self.name or "BoneGiant" in self.name or "ToyGolem" in self.name or "AbominableYeti" in self.name:
							var m_team = ""
							for g in get_groups():
								if g.begins_with("Side"): m_team = g
							if is_inside_tree() and get_tree():
								for node in get_tree().get_nodes_in_group("Targetable"):
									if not node.is_in_group(m_team) and is_instance_valid(node):
										if self.global_position.distance_to(node.global_position) <= attack_range + 2.0:
											var hp = node.get_node_or_null("HealthComponent")
											if hp: hp.take_damage(attack_damage, global_position)
						else:
							target_health.take_damage(attack_damage, global_position)

						# Frost Queen Freezing Slow on Hit
						if "FrostQueen" in self.name and current_target is CharacterBody3D:
							current_target.velocity *= 0.60

						# Vampiric Lifesteal for Grand Vampire and Vampire Duelist
						if "GrandVampire" in self.name or "VampireDuelist" in self.name:
							var my_hc = get_node_or_null("HealthComponent")
							if my_hc and not my_hc.is_dead:
								var lifesteal_pct = 0.30 if "GrandVampire" in self.name else 0.20
								my_hc.heal(attack_damage * lifesteal_pct)
							
						if attack_range > 3.5 and is_instance_valid(current_target):
							_spawn_ranged_attack_fx(current_target)
						attack_anim_timer = 0.35
						if humanoid_rig and humanoid_rig.has_method("trigger_attack"):
							humanoid_rig.trigger_attack(clampf(0.8 / max(0.5, attack_speed), 0.18, 0.45))
						var ap_attack = get_node_or_null("AnimationPlayer")
						if ap_attack and ap_attack.has_animation("attack"):
							ap_attack.play("attack", -1, attack_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

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
				pass # Let attack finish
			elif is_moving:
				if ap.has_animation("walk") and ap.current_animation != "walk":
					ap.play("walk", 0.2, speed * 0.5)
			else:
				if ap.has_animation("idle") and ap.current_animation != "idle":
					ap.play("idle", 0.2)
		if mesh:
			_animate_mesh(delta, is_moving)


func _augment_non_humanoid_model():
	var u_name = name
	var m_root = get_node_or_null("MeshInstance3D")
	var v_piv = get_node_or_null("VisualPivot")
	if "Monstrous" in u_name and m_root:
		if m_root.get_node_or_null("MonstrousArmL") == null:
			var hide_mat = StandardMaterial3D.new()
			hide_mat.albedo_color = Color(0.36, 0.25, 0.16)
			hide_mat.roughness = 0.85
			var bone_mat = StandardMaterial3D.new()
			bone_mat.albedo_color = Color(0.88, 0.84, 0.72)
			bone_mat.roughness = 0.5
			var eye_mat = StandardMaterial3D.new()
			eye_mat.albedo_color = Color(0.2, 1.0, 0.35)
			eye_mat.emission_enabled = true
			eye_mat.emission = Color(0.2, 1.0, 0.35)
			eye_mat.emission_energy_multiplier = 3.0
			# Thick muscular neck trapezius connecting torso (y=2.4) to head (y=2.6)
			var neck = MeshInstance3D.new()
			var n_cyl = CylinderMesh.new()
			n_cyl.top_radius = 0.28
			n_cyl.bottom_radius = 0.48
			n_cyl.height = 0.45
			neck.mesh = n_cyl
			neck.material_override = hide_mat
			neck.position = Vector3(0, 2.32, 0)
			m_root.add_child(neck)
			for side_idx in range(2):
				var side: float = -1.0 if side_idx == 0 else 1.0
				# Muscular deltoid shoulder socket connecting torso (r=0.8) to arm
				var deltoid = MeshInstance3D.new()
				var d_sph = SphereMesh.new()
				d_sph.radius = 0.42
				d_sph.height = 0.84
				deltoid.mesh = d_sph
				deltoid.material_override = hide_mat
				deltoid.position = Vector3(side * 0.74, 1.82, -0.15)
				m_root.add_child(deltoid)

				var arm = MeshInstance3D.new()
				arm.name = "MonstrousArmL" if side < 0 else "MonstrousArmR"
				var cap = CapsuleMesh.new()
				cap.radius = 0.34
				cap.height = 1.65
				arm.mesh = cap
				arm.material_override = hide_mat
				arm.position = Vector3(side * 0.92, 1.45, -0.32)
				arm.rotation_degrees = Vector3(35.0, 0.0, side * -18.0)
				m_root.add_child(arm)

				var claw = MeshInstance3D.new()
				var pry = PrismMesh.new()
				pry.size = Vector3(0.35, 0.55, 0.35)
				claw.mesh = pry
				claw.material_override = bone_mat
				claw.position = Vector3(0, -0.75, -0.15)
				claw.rotation_degrees.x = -135.0
				arm.add_child(claw)

				# Hunched beast leg anchoring lower torso to ground
				var leg = MeshInstance3D.new()
				var l_cap = CapsuleMesh.new()
				l_cap.radius = 0.28
				l_cap.height = 1.05
				leg.mesh = l_cap
				leg.material_override = hide_mat
				leg.position = Vector3(side * 0.44, 0.52, 0.05)
				m_root.add_child(leg)

				var eye = MeshInstance3D.new()
				var sph = SphereMesh.new()
				sph.radius = 0.11
				eye.mesh = sph
				eye.material_override = eye_mat
				eye.position = Vector3(side * 0.15, 2.65, -0.26)
				m_root.add_child(eye)
	elif "RimworlderMutant" in u_name and m_root:
		if m_root.get_node_or_null("MutantArmL") == null:
			var hide_mat = StandardMaterial3D.new()
			hide_mat.albedo_color = Color(0.36, 0.28, 0.22)
			hide_mat.roughness = 0.85
			var pustule_mat = StandardMaterial3D.new()
			pustule_mat.albedo_color = Color(0.45, 0.95, 0.2)
			pustule_mat.emission_enabled = true
			pustule_mat.emission = Color(0.35, 0.9, 0.15)
			pustule_mat.emission_energy_multiplier = 2.5
			# Pull RightArm_0 slightly inward and add mutated shoulder knots so both arms socket into torso
			var r_arm = m_root.get_node_or_null("RightArm_0")
			if r_arm:
				r_arm.position = Vector3(0.48, 1.05, -0.35)
			for side in [-1.0, 1.0]:
				var s_knot = MeshInstance3D.new()
				var sk_sph = SphereMesh.new()
				sk_sph.radius = 0.22 if side > 0 else 0.18
				s_knot.mesh = sk_sph
				s_knot.material_override = hide_mat
				s_knot.position = Vector3(side * 0.36, 1.35, -0.14)
				m_root.add_child(s_knot)

				var m_leg = MeshInstance3D.new()
				var ml_cap = CapsuleMesh.new()
				ml_cap.radius = 0.15
				ml_cap.height = 0.75
				m_leg.mesh = ml_cap
				m_leg.material_override = hide_mat
				m_leg.position = Vector3(side * 0.22, 0.38, 0.0)
				m_root.add_child(m_leg)

			var arm_l = MeshInstance3D.new()
			arm_l.name = "MutantArmL"
			var cap = CapsuleMesh.new()
			cap.radius = 0.14
			cap.height = 0.95
			arm_l.mesh = cap
			arm_l.material_override = hide_mat
			arm_l.position = Vector3(-0.44, 1.15, -0.22)
			arm_l.rotation_degrees = Vector3(30.0, 0.0, 15.0)
			m_root.add_child(arm_l)
			for i in range(3):
				var orb = MeshInstance3D.new()
				var sph = SphereMesh.new()
				sph.radius = 0.14 - i * 0.02
				orb.mesh = sph
				orb.material_override = pustule_mat
				orb.position = Vector3(0.22 - i * 0.14, 1.25 + i * 0.16, 0.24)
				m_root.add_child(orb)
	elif "BoxyWalker" in u_name and m_root:
		if m_root.get_node_or_null("WalkerVisor") == null:
			var visor_mat = StandardMaterial3D.new()
			visor_mat.albedo_color = Color(1.0, 0.65, 0.1)
			visor_mat.emission_enabled = true
			visor_mat.emission = Color(1.0, 0.65, 0.1)
			visor_mat.emission_energy_multiplier = 2.4
			var visor = MeshInstance3D.new()
			visor.name = "WalkerVisor"
			var vbox = BoxMesh.new()
			vbox.size = Vector3(0.68, 0.18, 0.08)
			visor.mesh = vbox
			visor.material_override = visor_mat
			visor.position = Vector3(0, 0.18, -0.52)
			m_root.add_child(visor)
			# Add weapon mount brackets & leg hip joints so MGs and legs connect solidly to hull
			var gun_mat = StandardMaterial3D.new()
			gun_mat.albedo_color = Color(0.16, 0.18, 0.20)
			gun_mat.metallic = 0.85
			for side in [-1.0, 1.0]:
				var sponson = MeshInstance3D.new()
				var sp_box = BoxMesh.new()
				sp_box.size = Vector3(0.16, 0.18, 0.78)
				sponson.mesh = sp_box
				sponson.material_override = gun_mat
				sponson.position = Vector3(side * 0.50, 0.20, 0.0)
				m_root.add_child(sponson)
	elif "SpiderTank" in u_name and m_root:
		if m_root.get_node_or_null("SpiderOptic") == null:
			var optic_mat = StandardMaterial3D.new()
			optic_mat.albedo_color = Color(1.0, 0.18, 0.18)
			optic_mat.emission_enabled = true
			optic_mat.emission = Color(1.0, 0.15, 0.15)
			optic_mat.emission_energy_multiplier = 3.0
			var optic = MeshInstance3D.new()
			optic.name = "SpiderOptic"
			var osph = SphereMesh.new()
			osph.radius = 0.22
			optic.mesh = osph
			optic.material_override = optic_mat
			optic.position = Vector3(0, 0.25, -0.72)
			m_root.add_child(optic)
			# Gun mantlet collar + 4 spider hip ball-joints
			var joint_mat = StandardMaterial3D.new()
			joint_mat.albedo_color = Color(0.16, 0.18, 0.20)
			joint_mat.metallic = 0.8
			var mantlet = MeshInstance3D.new()
			var m_cyl = CylinderMesh.new()
			m_cyl.top_radius = 0.20
			m_cyl.bottom_radius = 0.26
			m_cyl.height = 0.35
			mantlet.mesh = m_cyl
			mantlet.material_override = joint_mat
			mantlet.rotation_degrees.x = 90.0
			mantlet.position = Vector3(0, 0, -0.78)
			m_root.add_child(mantlet)
			for lx in [-0.52, 0.52]:
				for lz in [-0.52, 0.52]:
					var h_joint = MeshInstance3D.new()
					var hj_sph = SphereMesh.new()
					hj_sph.radius = 0.18
					h_joint.mesh = hj_sph
					h_joint.material_override = joint_mat
					h_joint.position = Vector3(lx, -0.32, lz)
					m_root.add_child(h_joint)
	elif "VoidCrawler" in u_name and v_piv:
		if v_piv.get_node_or_null("MandibleL") == null:
			var mand_mat = StandardMaterial3D.new()
			mand_mat.albedo_color = Color(0.85, 0.1, 0.9)
			mand_mat.emission_enabled = true
			mand_mat.emission = Color(0.85, 0.1, 0.9)
			mand_mat.emission_energy_multiplier = 2.2
			var chitin_mat = StandardMaterial3D.new()
			chitin_mat.albedo_color = Color(0.12, 0.02, 0.18)
			chitin_mat.roughness = 0.25
			chitin_mat.metallic = 0.4
			for side in [-1.0, 1.0]:
				var mand = MeshInstance3D.new()
				mand.name = "MandibleL" if side < 0 else "MandibleR"
				var mbox = BoxMesh.new()
				mbox.size = Vector3(0.14, 0.14, 0.65)
				mand.mesh = mbox
				mand.material_override = mand_mat
				mand.position = Vector3(side * 0.42, 0.45, -1.12)
				mand.rotation_degrees.y = side * -22.0
				v_piv.add_child(mand)
				for z_leg in [-0.8, 0.0, 0.8]:
					var coxa = MeshInstance3D.new()
					var c_sph = SphereMesh.new()
					c_sph.radius = 0.18
					coxa.mesh = c_sph
					coxa.material_override = chitin_mat
					coxa.position = Vector3(side * 0.74, 0.52, z_leg)
					v_piv.add_child(coxa)
	elif "SkyBeetle" in u_name:
		if v_piv and v_piv.get_node_or_null("BeetleThoraxBridge") == null:
			var carapace_mat = StandardMaterial3D.new()
			carapace_mat.albedo_color = Color(0.22, 0.28, 0.15)
			carapace_mat.roughness = 0.55
			# Thorax saddle bridging lower abdomen (y=2.0) to upper elytra shell (y=4.0)
			var bridge = MeshInstance3D.new()
			bridge.name = "BeetleThoraxBridge"
			var b_cyl = CylinderMesh.new()
			b_cyl.top_radius = 1.15
			b_cyl.bottom_radius = 0.95
			b_cyl.height = 1.6
			bridge.mesh = b_cyl
			bridge.material_override = carapace_mat
			bridge.position = Vector3(0, 2.9, 0)
			v_piv.add_child(bridge)
			# Wing-hinge sockets & 6 tucked beetle legs
			for side in [-1.0, 1.0]:
				var hinge = MeshInstance3D.new()
				var h_sph = SphereMesh.new()
				h_sph.radius = 0.24
				hinge.mesh = h_sph
				hinge.material_override = carapace_mat
				hinge.position = Vector3(side * 0.95, 4.45, 0.0)
				v_piv.add_child(hinge)
				for l_z in [-0.55, 0.0, 0.55]:
					var b_leg = MeshInstance3D.new()
					var bl_cyl = CylinderMesh.new()
					bl_cyl.top_radius = 0.08
					bl_cyl.bottom_radius = 0.04
					bl_cyl.height = 0.85
					b_leg.mesh = bl_cyl
					b_leg.material_override = carapace_mat
					b_leg.position = Vector3(side * 0.85, 1.55, l_z)
					b_leg.rotation_degrees.z = side * 28.0
					v_piv.add_child(b_leg)
	elif "SkyJellyfish" in u_name and v_piv:
		if v_piv.get_node_or_null("JellyOralCollar") == null:
			var collar_mat = StandardMaterial3D.new()
			collar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			collar_mat.albedo_color = Color(0.35, 0.52, 0.26, 0.78)
			var collar = MeshInstance3D.new()
			collar.name = "JellyOralCollar"
			var c_tor = TorusMesh.new()
			c_tor.inner_radius = 0.72
			c_tor.outer_radius = 1.25
			collar.mesh = c_tor
			collar.material_override = collar_mat
			collar.position = Vector3(0, 3.35, 0)
			v_piv.add_child(collar)
	elif "StoneOctopus" in u_name:
		var octo_root = v_piv if v_piv else m_root
		if octo_root and octo_root.get_node_or_null("OctoMantleCollar") == null:
			var stone_mat = StandardMaterial3D.new()
			stone_mat.albedo_color = Color(0.36, 0.38, 0.34)
			stone_mat.roughness = 0.92
			var collar = MeshInstance3D.new()
			collar.name = "OctoMantleCollar"
			var c_tor = TorusMesh.new()
			c_tor.inner_radius = 0.48
			c_tor.outer_radius = 0.86
			collar.mesh = c_tor
			collar.material_override = stone_mat
			collar.position = Vector3(0, 0.58, 0)
			octo_root.add_child(collar)
			var eye_mat = StandardMaterial3D.new()
			eye_mat.albedo_color = Color(1.0, 0.68, 0.15)
			eye_mat.emission_enabled = true
			eye_mat.emission = Color(1.0, 0.65, 0.1)
			eye_mat.emission_energy_multiplier = 2.4
			for side in [-1.0, 1.0]:
				var eye = MeshInstance3D.new()
				eye.name = "OctoEyeL" if side < 0 else "OctoEyeR"
				var e_sph = SphereMesh.new()
				e_sph.radius = 0.14
				eye.mesh = e_sph
				eye.material_override = eye_mat
				eye.position = Vector3(side * 0.38, 1.12, -0.72)
				octo_root.add_child(eye)
	elif "GiantSquid" in u_name and m_root:
		if m_root.get_node_or_null("SquidEyeL") == null:
			var hide_mat = StandardMaterial3D.new()
			hide_mat.albedo_color = Color(0.30, 0.24, 0.18)
			hide_mat.roughness = 0.85
			var collar = MeshInstance3D.new()
			collar.name = "SquidMantleCollar"
			var c_tor = TorusMesh.new()
			c_tor.inner_radius = 0.75
			c_tor.outer_radius = 1.38
			collar.mesh = c_tor
			collar.material_override = hide_mat
			collar.position = Vector3(0, 1.65, 0)
			m_root.add_child(collar)
			var eye_mat = StandardMaterial3D.new()
			eye_mat.albedo_color = Color(1.0, 0.75, 0.15)
			eye_mat.emission_enabled = true
			eye_mat.emission = Color(1.0, 0.75, 0.15)
			eye_mat.emission_energy_multiplier = 2.6
			for side in [-1.0, 1.0]:
				var eye = MeshInstance3D.new()
				eye.name = "SquidEyeL" if side < 0 else "SquidEyeR"
				var esph = SphereMesh.new()
				esph.radius = 0.26
				eye.mesh = esph
				eye.material_override = eye_mat
				eye.position = Vector3(side * 0.88, 2.2, -0.78)
				m_root.add_child(eye)


func _animate_mesh(delta: float, moving: bool):
	idle_anim_time += delta * 2.6
	if attack_anim_timer > 0.0:
		attack_anim_timer = max(0.0, attack_anim_timer - delta)
	var atk_swing: float = sin((1.0 - (attack_anim_timer / 0.35)) * PI) if attack_anim_timer > 0.0 else 0.0
	var hc = get_node_or_null("HealthComponent")
	var is_wounded: bool = hc != null and (hc.is_critically_wounded() or hc.is_vehicle_damaged())
	var wound_tilt: float = 0.14 if is_wounded else 0.0

	if moving:
		walk_time += delta * max(2.0, speed) * (2.6 if is_wounded else 3.5)
		mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * (0.11 if is_wounded else 0.15) - (0.08 if is_wounded else 0.0)
		mesh.rotation.z = wound_tilt + sin(walk_time) * (0.12 if is_wounded else 0.06)
	else:
		mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y - (0.06 if is_wounded else 0.0) + sin(idle_anim_time * (1.8 if is_wounded else 1.0)) * 0.04, 10.0 * delta)
		mesh.rotation.z = lerp(mesh.rotation.z, wound_tilt, 10.0 * delta)

	var u_name = name
	var m_root = get_node_or_null("MeshInstance3D")
	var v_piv = get_node_or_null("VisualPivot")
	var phase: float = walk_time if moving else idle_anim_time

	if "BoxyWalker" in u_name and m_root:
		var stride_amp: float = 0.48 if moving else 0.04
		var l0 = m_root.get_node_or_null("LeftLeg_0")
		var r1 = m_root.get_node_or_null("RightLeg_1")
		var l2 = m_root.get_node_or_null("LeftLeg_2")
		var r3 = m_root.get_node_or_null("RightLeg_3")
		if l0: l0.rotation.x = sin(phase) * stride_amp
		if r3: r3.rotation.x = sin(phase) * stride_amp
		if r1: r1.rotation.x = -sin(phase) * stride_amp
		if l2: l2.rotation.x = -sin(phase) * stride_amp
		for i in range(4):
			var mg = m_root.get_node_or_null("MG_" + str(i))
			if mg:
				var recoil: float = (0.14 * abs(sin(idle_anim_time * 12.0 + i * 1.5))) if attack_anim_timer > 0.0 else 0.0
				var base_z: float = -0.35
				mg.position.z = base_z + recoil
	elif "SpiderTank" in u_name and m_root:
		var leg_names = ["LeftLeg_0", "RightLeg_1", "LeftLeg_2", "RightLeg_3"]
		var scuttle_amp: float = 0.25 if moving else 0.03
		for i in range(leg_names.size()):
			var leg = m_root.get_node_or_null(leg_names[i])
			if leg:
				var sign_dir: float = 1.0 if (i % 2 == 0) else -1.0
				leg.position.y = -0.5 + max(0.0, sin(phase * 1.4 + i * 1.57)) * (0.18 if moving else 0.02)
				leg.rotation.y = sign_dir * 0.785 + sin(phase * 1.4 + i * 1.57) * scuttle_amp
		var barrel = m_root.get_node_or_null("SniperBarrel")
		if barrel:
			barrel.position.z = -1.5 + atk_swing * 0.42
	elif "VoidCrawler" in u_name and v_piv:
		var idx: int = 0
		for child in v_piv.get_children():
			if child is MeshInstance3D and not ("Eye" in child.name) and not ("Mandible" in child.name) and idx > 0:
				var side_sign: float = 1.0 if child.position.x > 0 else -1.0
				var wave: float = sin(phase * 1.8 + float(idx) * 1.1) * (0.35 if moving else 0.06)
				child.rotation.y = wave * side_sign
				child.position.y = 0.5 + max(0.0, cos(phase * 1.8 + float(idx) * 1.1)) * (0.14 if moving else 0.02)
			idx += 1
		var mand_l = v_piv.get_node_or_null("MandibleL")
		var mand_r = v_piv.get_node_or_null("MandibleR")
		if mand_l: mand_l.rotation.y = deg_to_rad(22.0 - atk_swing * 32.0)
		if mand_r: mand_r.rotation.y = deg_to_rad(-22.0 + atk_swing * 32.0)
		v_piv.position.z = -atk_swing * 0.35
	elif "SkyBeetle" in u_name:
		var buzz: float = Time.get_ticks_msec() * 0.035
		var hover_y: float = sin(idle_anim_time * 1.6) * 0.32
		if v_piv:
			v_piv.position.y = hover_y
			v_piv.position.z = -atk_swing * 0.45
			var ch_count = v_piv.get_child_count()
			if ch_count >= 3:
				var wing_r = v_piv.get_child(1)
				var wing_l = v_piv.get_child(2)
				if wing_r is Node3D: wing_r.rotation.z = sin(buzz) * 0.55
				if wing_l is Node3D: wing_l.rotation.z = -sin(buzz) * 0.55
		if m_root:
			m_root.position.y = hover_y
	elif "SkyJellyfish" in u_name:
		var pulse: float = sin(idle_anim_time * 1.4)
		var hover_y: float = pulse * 0.38
		if v_piv:
			v_piv.position.y = hover_y
			var ch_count = v_piv.get_child_count()
			if ch_count >= 1:
				var bell = v_piv.get_child(0)
				if bell is Node3D:
					var bell_w: float = 1.0 + pulse * 0.14 + atk_swing * 0.25
					var bell_h: float = 1.0 - pulse * 0.12
					bell.scale = Vector3(bell_w, bell_h, bell_w)
			for i in range(1, ch_count):
				var tent = v_piv.get_child(i)
				if tent is Node3D:
					tent.rotation.x = sin(idle_anim_time * 1.8 + float(i) * 1.3) * (0.28 + atk_swing * 0.35)
					tent.rotation.z = cos(idle_anim_time * 1.8 + float(i) * 1.3) * (0.28 + atk_swing * 0.35)
		if m_root:
			m_root.position.y = hover_y
	elif "StoneOctopus" in u_name:
		for container in [m_root, v_piv]:
			if container == null: continue
			var ch_count = container.get_child_count()
			for i in range(1, ch_count):
				var tent = container.get_child(i)
				if tent is Node3D and tent.name != "ArmorPlatesRoot" and tent.name != "ShieldVisualRoot" and tent.name != "StonePlating":
					var wave: float = sin(phase * 1.2 + float(i) * 0.85) * (0.26 if moving else 0.08)
					tent.position.y = 0.5 + max(0.0, wave) * 0.45 + atk_swing * 0.35
	elif "GiantSquid" in u_name and m_root:
		var ch_count = m_root.get_child_count()
		for i in range(1, ch_count):
			var tent = m_root.get_child(i)
			if tent is Node3D and not ("SquidEye" in tent.name):
				tent.rotation.x = sin(phase * 1.3 + float(i) * 0.7) * (0.32 if moving else 0.12) - atk_swing * 0.45
				tent.rotation.z = cos(phase * 1.3 + float(i) * 0.7) * (0.24 if moving else 0.08)
		m_root.position.z = -atk_swing * 0.55
	elif "Monstrous" in u_name and m_root:
		var arm_l = m_root.get_node_or_null("MonstrousArmL")
		var arm_r = m_root.get_node_or_null("MonstrousArmR")
		var stride_swing: float = sin(phase) * (0.55 if moving else 0.08)
		if arm_l: arm_l.rotation.x = deg_to_rad(35.0) + stride_swing + atk_swing * 1.15
		if arm_r: arm_r.rotation.x = deg_to_rad(35.0) - stride_swing + atk_swing * 1.15
		m_root.position.z = -atk_swing * 0.4
	elif "RimworlderMutant" in u_name and m_root:
		var arm_r = m_root.get_node_or_null("RightArm_0")
		var arm_l = m_root.get_node_or_null("MutantArmL")
		var stride_swing: float = sin(phase) * (0.5 if moving else 0.08)
		if arm_r: arm_r.rotation.x = deg_to_rad(30.0) + stride_swing + atk_swing * 1.15
		if arm_l: arm_l.rotation.x = deg_to_rad(30.0) - stride_swing + atk_swing * 1.15
		m_root.position.z = -atk_swing * 0.35

	# Holiday Faction Procedural Rig Articulation (Nightmare Court & Winter Court)
	var n_root = v_piv.get_node_or_null("NightmareRigRoot") if v_piv else null
	if n_root:
		_animate_nightmare_court(n_root, u_name, phase, atk_swing, moving, delta)

	var w_root = v_piv.get_node_or_null("WinterRigRoot") if v_piv else null
	if w_root:
		_animate_winter_court(w_root, u_name, phase, atk_swing, moving, delta)

	var mb_root = v_piv.get_node_or_null("MagmaBornRigRoot") if v_piv else null
	if mb_root:
		_animate_magma_born(mb_root, u_name, phase, atk_swing, moving, delta)


func _animate_nightmare_court(root: Node3D, u_name: String, phase: float, atk_swing: float, moving: bool, _delta: float) -> void:
	var leg_l = root.get_node_or_null("LeftLeg")
	var leg_r = root.get_node_or_null("RightLeg")
	var arm_l = root.get_node_or_null("LeftArm")
	var arm_r = root.get_node_or_null("RightArm")
	var weap = root.get_node_or_null("Weapon")
	var weap_l = root.get_node_or_null("WeaponL")
	var weap_r = root.get_node_or_null("WeaponR")
	var shield = root.get_node_or_null("Shield")
	var staff = root.get_node_or_null("Staff")
	var cape = root.get_node_or_null("Cape")
	var tail = root.get_node_or_null("Tail")
	var head = root.get_node_or_null("Head")
	var wing_l = root.get_node_or_null("WingL")
	var wing_r = root.get_node_or_null("WingR")

	var stride: float = (0.45 if moving else 0.04) * sin(phase)

	if "SupremeNecromancer" in u_name:
		root.position.y = sin(phase * 1.5) * 0.18
		if head: head.rotation.x = sin(phase * 0.8) * 0.06
		if staff:
			staff.rotation.x = -deg_to_rad(15.0) - atk_swing * 0.85
			var flame = staff.get_node_or_null("StaffFlame")
			if flame:
				flame.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.25 + atk_swing * 0.6)
		if arm_l: arm_l.rotation.x = deg_to_rad(20.0) + sin(phase * 1.5) * 0.2 + atk_swing * 0.75
		if arm_r: arm_r.rotation.x = -deg_to_rad(15.0) - atk_swing * 0.85
		if cape: cape.rotation.x = deg_to_rad(10.0) + sin(phase * 2.0) * 0.1
	elif "GrandVampire" in u_name:
		if leg_l: leg_l.rotation.x = stride
		if leg_r: leg_r.rotation.x = -stride
		if weap_l: weap_l.rotation.x = deg_to_rad(15.0) - atk_swing * 1.15
		if weap_r: weap_r.rotation.x = deg_to_rad(15.0) - atk_swing * 1.15
		if cape: cape.rotation.x = deg_to_rad(15.0) + (sin(phase * 1.5) * 0.22 if moving else sin(phase) * 0.05)
	elif "DemonKnight" in u_name:
		var heavy_stride = (0.38 if moving else 0.03) * sin(phase * 0.85)
		if leg_l: leg_l.rotation.x = heavy_stride
		if leg_r: leg_r.rotation.x = -heavy_stride
		if weap: weap.rotation.x = deg_to_rad(20.0) - atk_swing * 1.6
		if shield: shield.rotation.y = deg_to_rad(15.0) + atk_swing * 0.35
	elif "SkeletonSwordsman" in u_name:
		var skel_stride = (0.50 if moving else 0.04) * sin(phase * 1.3)
		if leg_l: leg_l.rotation.x = skel_stride
		if leg_r: leg_r.rotation.x = -skel_stride
		if weap: weap.rotation.x = deg_to_rad(25.0) - atk_swing * 1.45
		if shield: shield.position.z = -0.35 - atk_swing * 0.15
	elif "SkeletonArcher" in u_name:
		var arch_stride = (0.42 if moving else 0.03) * sin(phase * 1.1)
		if leg_l: leg_l.rotation.x = arch_stride
		if leg_r: leg_r.rotation.x = -arch_stride
		if weap:
			weap.position.z = -0.38 - atk_swing * 0.22
			weap.rotation.y = deg_to_rad(15.0) - atk_swing * 0.4
	elif "Zombie" in u_name:
		# Asymmetric limp & outstretched reaching arms
		if leg_l: leg_l.rotation.x = sin(phase * 0.75) * (0.45 if moving else 0.04)
		if leg_r: leg_r.rotation.x = -cos(phase * 0.75) * (0.24 if moving else 0.02)
		root.rotation.z = sin(phase * 0.75) * 0.10
		if arm_l: arm_l.rotation.x = deg_to_rad(75.0) + sin(phase * 1.4) * 0.15 + atk_swing * 0.55
		if arm_r: arm_r.rotation.x = deg_to_rad(80.0) - cos(phase * 1.4) * 0.15 + atk_swing * 0.55
	elif "BoneGiant" in u_name:
		var giant_stride = (0.35 if moving else 0.03) * sin(phase * 0.6)
		if leg_l: leg_l.rotation.x = giant_stride
		if leg_r: leg_r.rotation.x = -giant_stride
		if weap: weap.rotation.x = deg_to_rad(30.0) - atk_swing * 1.8
		root.position.y = -atk_swing * 0.22
	elif "VampireDuelist" in u_name:
		if leg_l: leg_l.rotation.x = stride
		if leg_r: leg_r.rotation.x = -stride
		if weap:
			weap.position.z = -0.35 - atk_swing * 0.70
			weap.rotation.x = -atk_swing * 0.30
		if cape: cape.rotation.x = deg_to_rad(12.0) + sin(phase * 1.5) * 0.15
	elif "BatSwarm" in u_name:
		var flap: float = sin(Time.get_ticks_msec() * 0.035) * 0.65
		root.position.z = -atk_swing * 0.60
		root.position.y = sin(phase * 2.0) * 0.25
		for b_idx in range(3):
			var bat = root.get_node_or_null("Bat_" + str(b_idx))
			if bat:
				var wl = bat.get_node_or_null("WingL")
				var wr = bat.get_node_or_null("WingR")
				if wl: wl.rotation.z = flap
				if wr: wr.rotation.z = -flap
	elif "Werewolf" in u_name:
		var wolf_stride = (0.55 if moving else 0.05) * sin(phase * 1.2)
		if leg_l: leg_l.rotation.x = wolf_stride
		if leg_r: leg_r.rotation.x = -wolf_stride
		if tail: tail.rotation.y = sin(phase * 1.5) * 0.35
		if arm_l: arm_l.rotation.x = deg_to_rad(45.0) + sin(phase) * 0.25 - atk_swing * 1.2
		if arm_r: arm_r.rotation.x = deg_to_rad(45.0) - sin(phase) * 0.25 - atk_swing * 1.2
	elif "DireWolf" in u_name:
		var q_stride = (0.60 if moving else 0.04) * sin(phase * 1.4)
		var fl = root.get_node_or_null("Leg_FL")
		var fr = root.get_node_or_null("Leg_FR")
		var bl = root.get_node_or_null("Leg_BL")
		var br = root.get_node_or_null("Leg_BR")
		if fl: fl.rotation.x = q_stride
		if br: br.rotation.x = q_stride
		if fr: fr.rotation.x = -q_stride
		if bl: bl.rotation.x = -q_stride
		if tail: tail.rotation.y = sin(phase * 2.0) * 0.40
		if head: head.rotation.x = atk_swing * 0.45
	elif "FireImp" in u_name:
		root.position.y = sin(phase * 2.0) * 0.22
		if wing_l: wing_l.rotation.y = sin(Time.get_ticks_msec() * 0.03) * 0.55
		if wing_r: wing_r.rotation.y = -sin(Time.get_ticks_msec() * 0.03) * 0.55
		var fb = root.get_node_or_null("Fireball")
		if fb:
			fb.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.015) * 0.25 + atk_swing * 0.5)
			fb.position.z = -0.45 - atk_swing * 0.60
	elif "HornedDemon" in u_name:
		if leg_l: leg_l.rotation.x = stride
		if leg_r: leg_r.rotation.x = -stride
		if wing_l: wing_l.rotation.y = deg_to_rad(25.0) + sin(phase * 0.8) * 0.25
		if wing_r: wing_r.rotation.y = -deg_to_rad(25.0) - sin(phase * 0.8) * 0.25
		if weap: weap.rotation.y = deg_to_rad(-20.0) + atk_swing * 1.50
	elif "Hellhound" in u_name:
		var hound_stride = (0.58 if moving else 0.04) * sin(phase * 1.4)
		var fl = root.get_node_or_null("Leg_FL")
		var fr = root.get_node_or_null("Leg_FR")
		var bl = root.get_node_or_null("Leg_BL")
		var br = root.get_node_or_null("Leg_BR")
		if fl: fl.rotation.x = hound_stride
		if br: br.rotation.x = hound_stride
		if fr: fr.rotation.x = -hound_stride
		if bl: bl.rotation.x = -hound_stride
		if tail: tail.rotation.y = sin(phase * 2.0) * 0.35
		var crest = root.get_node_or_null("Crest")
		if crest: crest.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.012) * 0.20)
		if head: head.rotation.x = atk_swing * 0.50
	elif "JackOLantern" in u_name:
		root.position.y = abs(sin(phase * 1.6)) * (0.28 if moving else 0.05)
		root.rotation.z = sin(phase * 1.6) * 0.15
		if weap: weap.rotation.x = deg_to_rad(15.0) - atk_swing * 1.30
		var mouth = root.get_node_or_null("Mouth")
		if mouth: mouth.scale.y = 1.0 + atk_swing * 1.20


func _animate_winter_court(root: Node3D, u_name: String, phase: float, atk_swing: float, moving: bool, delta: float) -> void:
	var leg_l = root.get_node_or_null("LeftLeg")
	var leg_r = root.get_node_or_null("RightLeg")
	var weap = root.get_node_or_null("Weapon")
	var shield = root.get_node_or_null("Shield")
	var head = root.get_node_or_null("Head")
	var tail = root.get_node_or_null("Tail")
	var wing_l = root.get_node_or_null("WingL")
	var wing_r = root.get_node_or_null("WingR")

	var stride: float = (0.45 if moving else 0.04) * sin(phase)

	if "YuletideKing" in u_name:
		var king_stride = (0.38 if moving else 0.03) * sin(phase * 0.85)
		if leg_l: leg_l.rotation.x = king_stride
		if leg_r: leg_r.rotation.x = -king_stride
		var beard = root.get_node_or_null("Beard")
		if beard: beard.rotation.x = sin(phase * 1.2) * 0.12
		if weap: weap.rotation.x = -deg_to_rad(15.0) - atk_swing * 0.90
	elif "KrampusLord" in u_name:
		if leg_l: leg_l.rotation.x = stride
		if leg_r: leg_r.rotation.x = -stride
		if weap: weap.rotation.x = deg_to_rad(20.0) - atk_swing * 1.50
		var hook = root.get_node_or_null("WeaponHook")
		if hook: hook.position.z = -0.45 - atk_swing * 0.50
		var chain = root.get_node_or_null("Chain")
		if chain: chain.rotation.z = sin(phase * 2.0) * 0.35
	elif "FrostQueen" in u_name:
		root.position.y = sin(phase * 1.2) * 0.15
		if weap: weap.position.z = -0.40 - atk_swing * 0.65
		var orb = root.get_node_or_null("IceOrb")
		if orb:
			orb.rotation.y += delta * 4.0
			orb.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.18 + atk_swing * 0.40)
	elif "ToySoldier" in u_name:
		var clock_stride = (0.48 if moving else 0.0) * sin(phase * 1.5)
		if leg_l: leg_l.rotation.x = clock_stride
		if leg_r: leg_r.rotation.x = -clock_stride
		var key = root.get_node_or_null("WindupKey")
		if key: key.rotation.y += delta * (8.0 if moving else 2.0)
		if weap: weap.position.z = -0.45 - atk_swing * 0.50
	elif "Nutcracker" in u_name:
		var nut_stride = (0.45 if moving else 0.0) * sin(phase * 1.4)
		if leg_l: leg_l.rotation.x = nut_stride
		if leg_r: leg_r.rotation.x = -nut_stride
		var jaw = root.get_node_or_null("Jaw")
		if jaw: jaw.position.y = -0.15 - abs(sin(phase * 2.0 + atk_swing * 6.0)) * 0.14
		if weap: weap.rotation.x = deg_to_rad(20.0) - atk_swing * 1.50
	elif "ToyGolem" in u_name:
		var golem_stride = (0.35 if moving else 0.02) * sin(phase * 0.75)
		if leg_l: leg_l.rotation.x = golem_stride
		if leg_r: leg_r.rotation.x = -golem_stride
		var gear = root.get_node_or_null("WindupKey")
		if gear: gear.rotation.z += delta * 3.5
		var fist_l = root.get_node_or_null("LeftFist")
		var fist_r = root.get_node_or_null("RightFist")
		if fist_l: fist_l.position.z = -0.45 - (atk_swing * 0.80 if atk_swing > 0.0 else sin(phase * 0.75) * 0.20)
		if fist_r: fist_r.position.z = -0.45 - (atk_swing * 0.80 if atk_swing > 0.0 else -sin(phase * 0.75) * 0.20)
	elif "GingerbreadBrawler" in u_name:
		var brawler_stride = (0.48 if moving else 0.04) * sin(phase * 1.3)
		if leg_l: leg_l.rotation.x = brawler_stride
		if leg_r: leg_r.rotation.x = -brawler_stride
		if weap: weap.rotation.x = deg_to_rad(25.0) - atk_swing * 1.40
		if shield: shield.rotation.y = deg_to_rad(15.0) + atk_swing * 0.40
	elif "WarReindeer" in u_name:
		var deer_stride = (0.55 if moving else 0.04) * sin(phase * 1.4)
		var fl = root.get_node_or_null("Leg_FL")
		var fr = root.get_node_or_null("Leg_FR")
		var bl = root.get_node_or_null("Leg_BL")
		var br = root.get_node_or_null("Leg_BR")
		if fl: fl.rotation.x = deer_stride
		if br: br.rotation.x = deer_stride
		if fr: fr.rotation.x = -deer_stride
		if bl: bl.rotation.x = -deer_stride
		if head: head.rotation.x = deg_to_rad(15.0) + atk_swing * 0.50
	elif "AbominableYeti" in u_name:
		var yeti_stride = (0.45 if moving else 0.03) * sin(phase * 0.9)
		if leg_l: leg_l.rotation.x = yeti_stride
		if leg_r: leg_r.rotation.x = -yeti_stride
		var arm_l = root.get_node_or_null("LeftArm")
		var arm_r = root.get_node_or_null("RightArm")
		if arm_l: arm_l.rotation.x = deg_to_rad(40.0) + sin(phase * 0.9) * 0.30 - atk_swing * 1.30
		if arm_r: arm_r.rotation.x = deg_to_rad(40.0) - sin(phase * 0.9) * 0.30 - atk_swing * 1.30
	elif "FrostWolf" in u_name:
		var fwolf_stride = (0.60 if moving else 0.04) * sin(phase * 1.4)
		var fl = root.get_node_or_null("Leg_FL")
		var fr = root.get_node_or_null("Leg_FR")
		var bl = root.get_node_or_null("Leg_BL")
		var br = root.get_node_or_null("Leg_BR")
		if fl: fl.rotation.x = fwolf_stride
		if br: br.rotation.x = fwolf_stride
		if fr: fr.rotation.x = -fwolf_stride
		if bl: bl.rotation.x = -fwolf_stride
		if tail: tail.rotation.y = sin(phase * 2.0) * 0.35
		if head: head.rotation.x = atk_swing * 0.45
	elif "SnowSprite" in u_name:
		root.position.y = sin(phase * 2.2) * 0.25
		root.position.z = -atk_swing * 0.50
		if wing_l: wing_l.rotation.y = sin(Time.get_ticks_msec() * 0.04) * 0.55
		if wing_r: wing_r.rotation.y = -sin(Time.get_ticks_msec() * 0.04) * 0.55
	elif "FrostElf" in u_name:
		var elf_stride = (0.45 if moving else 0.03) * sin(phase * 1.2)
		if leg_l: leg_l.rotation.x = elf_stride
		if leg_r: leg_r.rotation.x = -elf_stride
		if weap:
			weap.position.z = -0.35 - atk_swing * 0.20
			weap.rotation.y = deg_to_rad(15.0) - atk_swing * 0.35
	elif "BlizzardWitch" in u_name:
		root.position.y = sin(phase * 1.3) * 0.16
		if weap: weap.rotation.x = -deg_to_rad(20.0) - atk_swing * 0.85
		var orb = root.get_node_or_null("IceOrb")
		if orb:
			orb.rotation.y += delta * 5.0
			orb.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.20 + atk_swing * 0.50)
	elif "SnowballCatapult" in u_name:
		root.rotation.z = (sin(phase * 1.8) * 0.04) if moving else 0.0
		var arm = root.get_node_or_null("CatapultArm")
		if arm: arm.rotation.x = -deg_to_rad(35.0) + atk_swing * 1.60
		var ball = root.get_node_or_null("Snowball")
		if ball: ball.visible = (atk_swing < 0.70)
	elif "YuleLog" in u_name:
		var yule_log = root.get_node_or_null("Log")
		if yule_log and moving: yule_log.rotation.x += delta * 8.0
		for f_idx in range(3):
			var flame = root.get_node_or_null("Flame_" + str(f_idx))
			if flame:
				flame.scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.015 + f_idx * 2.0) * 0.35 + atk_swing * 0.50


func can_wander_off_path() -> bool:
	if is_in_group("SideHarmony"):
		return true
	if is_in_group("Flyer") or "Plane" in name or "Flyer" in name or "Beetle" in name or "Jellyfish" in name or unit_attribute == "Flying":
		return true
	if "Assassin" in name or "Hunter" in name or "Stalker" in name or "Sniper" in name:
		return true
	return false

func find_new_target():
	current_target = null
	if not is_inside_tree() or not get_tree():
		return
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"):
			my_team = g
			break
	var gs = _get_game_state()
	var closest_dist = 99999.0
	var wander = can_wander_off_path()
	var my_pos = global_position

	for node in get_tree().get_nodes_in_group("Targetable"):
		if node == self or not is_instance_valid(node): continue
		if my_team != "" and node.is_in_group(my_team): continue
		if my_team == "" and node.is_in_group("Beast"): continue

		var d = my_pos.distance_to(node.global_position)
		if d >= closest_dist: continue

		var is_structure = "Base" in node.name or "Tower" in node.name or "CommandBay" in node.name
		if not wander and (node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure")):
			if d > 7.5: continue
		if not is_structure and gs and not wander and gs.get_distance_to_nearest_lane(node.global_position) > 14.5:
			if d > 7.5: continue

		var hc = node.get_node_or_null("HealthComponent")
		if hc and hc.is_dead: continue
		if gs and gs.is_unit_stealthed_from(node, self): continue

		closest_dist = d
		current_target = node




func _spawn_ranged_attack_fx(p_target: Node3D):
	if not is_instance_valid(p_target): return
	var u_name = self.name
	if not ("Crossbowman" in u_name or "ShortBow" in u_name or "RockThrower" in u_name):
		return # Only primitive ranged units need custom procedural projectile FX here
	var scene_root = get_tree().current_scene if (is_inside_tree() and get_tree() and get_tree().current_scene) else get_parent()
	if not scene_root: return
	
	var start_pos = global_position + Vector3(0, 1.2, 0)
	var end_pos = p_target.global_position + Vector3(0, 0.9, 0)
	var dist = start_pos.distance_to(end_pos)
	
	var proj_mesh = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	var flight_duration = 0.25
	
	if "Crossbowman" in u_name:
		var bolt_cyl = CylinderMesh.new()
		bolt_cyl.top_radius = 0.025; bolt_cyl.bottom_radius = 0.025; bolt_cyl.height = 0.55
		proj_mesh.mesh = bolt_cyl
		mat.albedo_color = Color(0.75, 0.75, 0.78)
		mat.metallic = 0.8; mat.roughness = 0.3
		flight_duration = clampf(dist / 35.0, 0.08, 0.40)
	elif "ShortBow" in u_name:
		var arrow_cyl = CylinderMesh.new()
		arrow_cyl.top_radius = 0.02; arrow_cyl.bottom_radius = 0.02; arrow_cyl.height = 0.75
		proj_mesh.mesh = arrow_cyl
		mat.albedo_color = Color(0.85, 0.78, 0.55)
		mat.roughness = 0.8
		flight_duration = clampf(dist / 26.0, 0.10, 0.50)
	elif "RockThrower" in u_name:
		var rock_sph = SphereMesh.new()
		rock_sph.radius = 0.18; rock_sph.height = 0.32; rock_sph.radial_segments = 6; rock_sph.rings = 4
		proj_mesh.mesh = rock_sph
		mat.albedo_color = Color(0.48, 0.44, 0.40)
		mat.roughness = 0.95
		flight_duration = clampf(dist / 20.0, 0.12, 0.60)
		
	proj_mesh.material_override = mat
	scene_root.add_child(proj_mesh)
	proj_mesh.global_position = start_pos
	
	var dir = (end_pos - start_pos).normalized()
	if dir != Vector3.ZERO:
		var up = Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
		proj_mesh.look_at(start_pos + dir, up)
		if not ("RockThrower" in u_name):
			proj_mesh.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))
			
	var tw = proj_mesh.create_tween()
	if tw:
		tw.set_parallel(true)
		tw.tween_property(proj_mesh, "global_position", end_pos, flight_duration)
		if "RockThrower" in u_name:
			tw.tween_property(proj_mesh, "rotation:x", 12.0, flight_duration)
		tw.chain().tween_callback(proj_mesh.queue_free)
	else:
		proj_mesh.queue_free()


func _animate_magma_born(root: Node3D, u_name: String, phase: float, atk_swing: float, moving: bool, delta: float) -> void:
	var leg_l = root.get_node_or_null("LeftLeg")
	var leg_r = root.get_node_or_null("RightLeg")
	var arm_l = root.get_node_or_null("LeftArm")
	var arm_r = root.get_node_or_null("RightArm")
	var weap = root.get_node_or_null("Weapon")
	var head = root.get_node_or_null("Head")
	var tail = root.get_node_or_null("Tail")
	var wing_l = root.get_node_or_null("WingL")
	var wing_r = root.get_node_or_null("WingR")

	var stride: float = (0.42 if moving else 0.03) * sin(phase)

	if "MagmaOverlord" in u_name:
		if leg_l: leg_l.rotation.x = stride
		if leg_r: leg_r.rotation.x = -stride
		if weap:
			weap.rotation_degrees.x = 65.0 - atk_swing * 110.0
		var vent = root.get_node_or_null("Torso/MoltenCore")
		if vent:
			vent.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.18 + atk_swing * 0.45)
	elif "MagmaLavaGrunt" in u_name:
		var squat_stride = (0.55 if moving else 0.04) * sin(phase * 1.35)
		if leg_l: leg_l.rotation.x = squat_stride
		if leg_r: leg_r.rotation.x = -squat_stride
		if weap:
			weap.rotation_degrees.x = 45.0 - atk_swing * 95.0
	elif "MagmaTentacleLavaDog" in u_name:
		var gallop = (0.60 if moving else 0.04) * sin(phase * 1.45)
		var fl = root.get_node_or_null("Leg_FL")
		var fr = root.get_node_or_null("Leg_FR")
		var bl = root.get_node_or_null("Leg_BL")
		var br = root.get_node_or_null("Leg_BR")
		if fl: fl.rotation.x = gallop
		if br: br.rotation.x = gallop
		if fr: fr.rotation.x = -gallop
		if bl: bl.rotation.x = -gallop
		if head: head.rotation.x = atk_swing * 0.45
		if tail: tail.rotation.y = sin(phase * 2.0) * 0.40
		var t0 = root.get_node_or_null("Torso/Tentacle_0")
		var t1 = root.get_node_or_null("Torso/Tentacle_1")
		var t_wave = sin(Time.get_ticks_msec() * 0.012) * 0.4
		if t0: t0.rotation.z = deg_to_rad(35.0) + t_wave + atk_swing * 0.8
		if t1: t1.rotation.z = -deg_to_rad(35.0) - t_wave - atk_swing * 0.8
	elif "MagmaSpitter" in u_name:
		for i in range(4):
			var leg = root.get_node_or_null("Leg_" + str(i))
			if leg:
				leg.rotation.z = deg_to_rad(35.0) + sin(phase * 1.5 + float(i) * 1.57) * (0.22 if moving else 0.03)
		root.position.z = atk_swing * 0.28
	elif "MagmaGolem" in u_name:
		var golem_stride = (0.35 if moving else 0.02) * sin(phase * 0.75)
		if leg_l: leg_l.rotation.x = golem_stride
		if leg_r: leg_r.rotation.x = -golem_stride
		var fist_l = root.get_node_or_null("LeftFist")
		var fist_r = root.get_node_or_null("RightFist")
		if fist_l: fist_l.position.z = -0.25 - atk_swing * 0.75
		if fist_r: fist_r.position.z = -0.25 - atk_swing * 0.75
	elif "MagmaPyrodactyl" in u_name:
		root.position.y = sin(phase * 2.0) * 0.22
		root.position.z = -atk_swing * 0.55
		var flap = sin(Time.get_ticks_msec() * 0.008) * 0.35
		if wing_l: wing_l.rotation.z = flap
		if wing_r: wing_r.rotation.z = -flap
	elif "MagmaTurretSpire" in u_name:
		var core = root.get_node_or_null("Torso/LavaCore")
		if core: core.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.15 + atk_swing * 0.3)
		var tur = root.get_node_or_null("Torso/Turret")
		if tur: tur.position.z = -0.35 + atk_swing * 0.22
	elif "MagmaColossalDragon" in u_name:
		root.position.y = sin(phase * 1.1) * 0.18
		var wing_sweep = sin(Time.get_ticks_msec() * 0.005) * 0.45
		if wing_l: wing_l.rotation.z = deg_to_rad(-20.0) + wing_sweep
		if wing_r: wing_r.rotation.z = deg_to_rad(20.0) - wing_sweep
		if tail: tail.rotation.y = sin(phase * 1.4) * 0.35
		if head: head.rotation.x = -atk_swing * 0.35
		var mouth = root.get_node_or_null("Torso/Head/Mouth")
		if mouth: mouth.scale.y = 1.0 + atk_swing * 1.5

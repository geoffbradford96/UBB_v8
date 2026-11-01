extends CharacterBody3D
class_name TerritorialCreature

@export var creature_type: String = "Scorpion" # "Scorpion", "SwarmAnt", "Gorilla", "Monkey"
@export var nest_radius: float = 16.5
@export var leash_radius: float = 36.0
@export var home_position: Vector3 = Vector3.ZERO

@export var max_health: float = 120.0
@export var speed: float = 5.0
@export var attack_damage: float = 14.0
@export var attack_range: float = 1.8
@export var attack_speed: float = 1.2

var current_target: Node3D = null
var attack_timer: float = 0.0
var recheck_timer: float = 0.0
var idle_patrol_timer: float = 0.0
var idle_patrol_offset: Vector3 = Vector3.ZERO
var visual_mesh: Node3D = null
var anim_time: float = 0.0

func _ready():
	add_to_group("Targetable")
	add_to_group("NeutralCreature")
	if creature_type == "Scorpion":
		add_to_group("Scorpion")
	elif creature_type == "SwarmAnt":
		add_to_group("SwarmAnt")
	elif creature_type == "Gorilla":
		add_to_group("Gorilla")
	elif creature_type == "Monkey":
		add_to_group("Monkey")
		
	# Setup HealthComponent
	var hc = get_node_or_null("HealthComponent")
	if not hc:
		hc = HealthComponent.new()
		hc.name = "HealthComponent"
		add_child(hc)
	hc.set_max_health(max_health)
	if not hc.died.is_connected(_on_died):
		hc.died.connect(_on_died)
	if not hc.health_changed.is_connected(_on_health_changed):
		hc.health_changed.connect(_on_health_changed)
		
	if home_position == Vector3.ZERO:
		home_position = global_position
		
	recheck_timer = randf_range(0.1, 0.4)
	idle_patrol_timer = randf_range(0.5, 3.0)
	
	_setup_collision()
	_setup_model()

func configure_creature(type: String, home: Vector3):
	creature_type = type
	home_position = home
	if creature_type == "Scorpion":
		max_health = 130.0
		speed = 5.0
		attack_damage = 15.0
		attack_range = 2.0
		attack_speed = 1.1
		nest_radius = 16.5
		leash_radius = 36.0
	elif creature_type == "SwarmAnt":
		max_health = 28.0
		speed = 5.6
		attack_damage = 4.5
		attack_range = 10.0
		attack_speed = 1.4
		nest_radius = 18.5
		leash_radius = 38.0
	elif creature_type == "Gorilla":
		max_health = 260.0
		speed = 5.2
		attack_damage = 26.0
		attack_range = 2.4
		attack_speed = 1.15
		nest_radius = 19.5
		leash_radius = 40.0
	elif creature_type == "Monkey":
		max_health = 58.0
		speed = 6.0
		attack_damage = 9.0
		attack_range = 8.5
		attack_speed = 1.45
		nest_radius = 18.0
		leash_radius = 38.0
		
	var hc = get_node_or_null("HealthComponent")
	if hc:
		hc.set_max_health(max_health)
	if visual_mesh:
		for c in visual_mesh.get_children(): c.queue_free()
		if creature_type == "Scorpion":
			_build_scorpion_mesh()
		elif creature_type == "SwarmAnt":
			_build_ant_mesh()
		elif creature_type == "Gorilla":
			_build_gorilla_mesh()
		elif creature_type == "Monkey":
			_build_monkey_mesh()

func _setup_collision():
	var col = get_node_or_null("CollisionShape3D")
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var shape = SphereShape3D.new()
		if creature_type == "Gorilla":
			shape.radius = 0.8
			col.position.y = 0.5
		elif creature_type == "Scorpion":
			shape.radius = 0.6
			col.position.y = 0.3
		elif creature_type == "Monkey":
			shape.radius = 0.38
			col.position.y = 0.22
		else: # SwarmAnt
			shape.radius = 0.3
			col.position.y = 0.15
		col.shape = shape
		add_child(col)

func _setup_model():
	visual_mesh = Node3D.new()
	visual_mesh.name = "CreatureVisuals"
	add_child(visual_mesh)
	
	if creature_type == "Scorpion":
		_build_scorpion_mesh()
	elif creature_type == "SwarmAnt":
		_build_ant_mesh()
	elif creature_type == "Gorilla":
		_build_gorilla_mesh()
	elif creature_type == "Monkey":
		_build_monkey_mesh()

func _build_scorpion_mesh():
	var chitin_mat = StandardMaterial3D.new()
	chitin_mat.albedo_color = Color(0.38, 0.22, 0.10) # Dark desert amber chitin
	chitin_mat.roughness = 0.65
	
	var accent_mat = StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.24, 0.14, 0.06)
	accent_mat.roughness = 0.5
	
	var stinger_mat = StandardMaterial3D.new()
	stinger_mat.albedo_color = Color(0.85, 0.25, 0.12) # Venomous red-orange stinger
	stinger_mat.emission_enabled = true
	stinger_mat.emission = Color(0.7, 0.2, 0.05)
	stinger_mat.emission_energy_multiplier = 0.8
	
	# Thorax / Body
	var body_m = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(0.7, 0.25, 1.0)
	body_m.mesh = body_box
	body_m.material_override = chitin_mat
	body_m.position.y = 0.25
	visual_mesh.add_child(body_m)
	
	# Head
	var head_m = MeshInstance3D.new()
	var head_box = BoxMesh.new()
	head_box.size = Vector3(0.5, 0.2, 0.4)
	head_m.mesh = head_box
	head_m.material_override = accent_mat
	head_m.position = Vector3(0, 0.24, -0.6)
	visual_mesh.add_child(head_m)
	
	# Pincers Left and Right + Shoulder Sockets + 6 Chitinous Legs
	for side in [-1.0, 1.0]:
		var shoulder = MeshInstance3D.new()
		var sh_sph = SphereMesh.new()
		sh_sph.radius = 0.11
		shoulder.mesh = sh_sph
		shoulder.material_override = accent_mat
		shoulder.position = Vector3(side * 0.34, 0.22, -0.52)
		visual_mesh.add_child(shoulder)

		var claw_arm = MeshInstance3D.new()
		var arm_box = BoxMesh.new()
		arm_box.size = Vector3(0.12, 0.12, 0.45)
		claw_arm.mesh = arm_box
		claw_arm.material_override = chitin_mat
		claw_arm.position = Vector3(side * 0.44, 0.22, -0.7)
		claw_arm.rotation.y = side * 0.4
		visual_mesh.add_child(claw_arm)
		
		var pincer = MeshInstance3D.new()
		var pincer_box = BoxMesh.new()
		pincer_box.size = Vector3(0.2, 0.12, 0.32)
		pincer.mesh = pincer_box
		pincer.material_override = accent_mat
		pincer.position = Vector3(side * 0.56, 0.22, -0.92)
		visual_mesh.add_child(pincer)

		for l_z in [-0.32, 0.0, 0.32]:
			var s_leg = MeshInstance3D.new()
			var sl_cyl = CylinderMesh.new()
			sl_cyl.top_radius = 0.045
			sl_cyl.bottom_radius = 0.025
			sl_cyl.height = 0.38
			s_leg.mesh = sl_cyl
			s_leg.material_override = accent_mat
			s_leg.position = Vector3(side * 0.42, 0.14, l_z)
			s_leg.rotation_degrees.z = side * 42.0
			visual_mesh.add_child(s_leg)
		
	# Arched Stinger Tail (4 segments curved up and forward)
	var tail_segs = [
		Vector3(0, 0.35, 0.52),
		Vector3(0, 0.60, 0.64),
		Vector3(0, 0.85, 0.48),
		Vector3(0, 1.00, 0.22)
	]
	for pos in tail_segs:
		var seg = MeshInstance3D.new()
		var seg_box = BoxMesh.new()
		seg_box.size = Vector3(0.22, 0.24, 0.28)
		seg.mesh = seg_box
		seg.material_override = chitin_mat
		seg.position = pos
		visual_mesh.add_child(seg)
		
	# Venom Stinger Bulb & Spike
	var stinger = MeshInstance3D.new()
	var stinger_cone = CylinderMesh.new()
	stinger_cone.top_radius = 0.02
	stinger_cone.bottom_radius = 0.12
	stinger_cone.height = 0.32
	stinger.mesh = stinger_cone
	stinger.material_override = stinger_mat
	stinger.position = Vector3(0, 1.02, 0.02)
	stinger.rotation.x = -1.2 # Curved pointing forward
	visual_mesh.add_child(stinger)

func _build_ant_mesh():
	var ant_mat = StandardMaterial3D.new()
	ant_mat.albedo_color = Color(0.22, 0.12, 0.08) # Reddish-black desert swarm ant
	ant_mat.roughness = 0.7
	
	# Scale whole visual small
	visual_mesh.scale = Vector3(0.55, 0.55, 0.55)
	
	# Head
	var head = MeshInstance3D.new()
	var head_sph = SphereMesh.new()
	head_sph.radius = 0.18
	head_sph.height = 0.32
	head.mesh = head_sph
	head.material_override = ant_mat
	head.position = Vector3(0, 0.25, -0.34)
	visual_mesh.add_child(head)
	
	# Thorax + Petiole Waist Node connecting Head, Thorax, and Abdomen
	var thorax = MeshInstance3D.new()
	var th_sph = SphereMesh.new()
	th_sph.radius = 0.15
	th_sph.height = 0.32
	thorax.mesh = th_sph
	thorax.material_override = ant_mat
	thorax.position = Vector3(0, 0.24, 0.0)
	visual_mesh.add_child(thorax)

	var petiole = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.08
	p_cyl.bottom_radius = 0.08
	p_cyl.height = 0.65
	petiole.mesh = p_cyl
	petiole.material_override = ant_mat
	petiole.rotation_degrees.x = 90.0
	petiole.position = Vector3(0, 0.25, 0.04)
	visual_mesh.add_child(petiole)
	
	# Abdomen / Gaster
	var abdomen = MeshInstance3D.new()
	var ab_sph = SphereMesh.new()
	ab_sph.radius = 0.22
	ab_sph.height = 0.42
	abdomen.mesh = ab_sph
	abdomen.material_override = ant_mat
	abdomen.position = Vector3(0, 0.28, 0.38)
	visual_mesh.add_child(abdomen)
	
	# Tiny mandibles + 6 Chitinous Ant Legs
	for side in [-1.0, 1.0]:
		var mand = MeshInstance3D.new()
		var mand_box = BoxMesh.new()
		mand_box.size = Vector3(0.06, 0.04, 0.16)
		mand.mesh = mand_box
		mand.material_override = ant_mat
		mand.position = Vector3(side * 0.09, 0.20, -0.48)
		mand.rotation.y = side * -0.3
		visual_mesh.add_child(mand)
		for l_z in [-0.14, 0.0, 0.14]:
			var a_leg = MeshInstance3D.new()
			var al_cyl = CylinderMesh.new()
			al_cyl.top_radius = 0.03
			al_cyl.bottom_radius = 0.015
			al_cyl.height = 0.32
			a_leg.mesh = al_cyl
			a_leg.material_override = ant_mat
			a_leg.position = Vector3(side * 0.18, 0.14, l_z)
			a_leg.rotation_degrees.z = side * 38.0
			visual_mesh.add_child(a_leg)

func _build_gorilla_mesh():
	var fur_mat = StandardMaterial3D.new()
	fur_mat.albedo_color = Color(0.12, 0.12, 0.14) # Deep slate black gorilla coat
	fur_mat.roughness = 0.8
	
	var chest_mat = StandardMaterial3D.new()
	chest_mat.albedo_color = Color(0.24, 0.22, 0.24) # Leathery chest skin
	chest_mat.roughness = 0.65
	
	var saddle_mat = StandardMaterial3D.new()
	saddle_mat.albedo_color = Color(0.68, 0.68, 0.72) # Silverback dorsal saddle
	saddle_mat.roughness = 0.75
	
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.95, 0.75, 0.15)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(0.95, 0.75, 0.15)
	eye_mat.emission_energy_multiplier = 0.8
	
	# Scale whole visual
	visual_mesh.scale = Vector3(1.22, 1.22, 1.22)
	
	# Heavy Barrel Torso
	var torso = MeshInstance3D.new()
	var t_sph = SphereMesh.new()
	t_sph.radius = 0.38
	t_sph.height = 0.82
	torso.mesh = t_sph
	torso.material_override = fur_mat
	torso.position = Vector3(0, 0.62, 0.04)
	torso.scale = Vector3(1.15, 1.0, 1.15)
	visual_mesh.add_child(torso)
	
	# Chest Pecs
	var chest = MeshInstance3D.new()
	var c_sph = SphereMesh.new()
	c_sph.radius = 0.26
	c_sph.height = 0.55
	chest.mesh = c_sph
	chest.material_override = chest_mat
	chest.position = Vector3(0, 0.64, -0.16)
	chest.scale = Vector3(0.95, 0.9, 0.75)
	visual_mesh.add_child(chest)
	
	# Silverback Saddle
	var saddle = MeshInstance3D.new()
	var s_sph = SphereMesh.new()
	s_sph.radius = 0.34
	s_sph.height = 0.68
	saddle.mesh = s_sph
	saddle.material_override = saddle_mat
	saddle.position = Vector3(0, 0.70, 0.16)
	saddle.scale = Vector3(1.12, 0.95, 1.05)
	visual_mesh.add_child(saddle)
	
	# Head with heavy brow ridge
	var head = MeshInstance3D.new()
	var h_sph = SphereMesh.new()
	h_sph.radius = 0.24
	h_sph.height = 0.48
	head.mesh = h_sph
	head.material_override = fur_mat
	head.position = Vector3(0, 1.04, -0.28)
	visual_mesh.add_child(head)
	
	var brow = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.32, 0.09, 0.16)
	brow.mesh = b_box
	brow.material_override = fur_mat
	brow.position = Vector3(0, 1.15, -0.46)
	visual_mesh.add_child(brow)
	
	var muzzle = MeshInstance3D.new()
	var m_box = BoxMesh.new()
	m_box.size = Vector3(0.24, 0.18, 0.18)
	muzzle.mesh = m_box
	muzzle.material_override = chest_mat
	muzzle.position = Vector3(0, 0.98, -0.48)
	visual_mesh.add_child(muzzle)
	
	for s in [-1.0, 1.0]:
		var eye = MeshInstance3D.new()
		var e_sph = SphereMesh.new()
		e_sph.radius = 0.038
		e_sph.height = 0.076
		eye.mesh = e_sph
		eye.material_override = eye_mat
		eye.position = Vector3(s * 0.09, 1.09, -0.47)
		visual_mesh.add_child(eye)
		
		var ear = MeshInstance3D.new()
		var er_sph = SphereMesh.new()
		er_sph.radius = 0.075
		er_sph.height = 0.14
		ear.mesh = er_sph
		ear.material_override = chest_mat
		ear.position = Vector3(s * 0.24, 1.06, -0.30)
		ear.scale = Vector3(0.45, 1.0, 0.85)
		visual_mesh.add_child(ear)
		
		# Muscular Knuckle-walking Arms
		var arm = MeshInstance3D.new()
		var a_cyl = CylinderMesh.new()
		a_cyl.top_radius = 0.12
		a_cyl.bottom_radius = 0.10
		a_cyl.height = 0.58
		arm.mesh = a_cyl
		arm.material_override = fur_mat
		arm.position = Vector3(s * 0.44, 0.46, -0.24)
		arm.rotation_degrees = Vector3(18.0, 0, s * -12.0)
		visual_mesh.add_child(arm)
		
		# Knuckle Fist on ground
		var fist = MeshInstance3D.new()
		var f_sph = SphereMesh.new()
		f_sph.radius = 0.12
		f_sph.height = 0.20
		fist.mesh = f_sph
		fist.material_override = chest_mat
		fist.position = Vector3(s * 0.48, 0.12, -0.32)
		visual_mesh.add_child(fist)
		
		# Hind Legs
		var leg = MeshInstance3D.new()
		var l_cyl = CylinderMesh.new()
		l_cyl.top_radius = 0.11
		l_cyl.bottom_radius = 0.09
		l_cyl.height = 0.44
		leg.mesh = l_cyl
		leg.material_override = fur_mat
		leg.position = Vector3(s * 0.28, 0.30, 0.22)
		visual_mesh.add_child(leg)

func _build_monkey_mesh():
	var fur_mat = StandardMaterial3D.new()
	fur_mat.albedo_color = Color(0.56, 0.38, 0.22) # Golden brown fur
	fur_mat.roughness = 0.75
	
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.85, 0.76, 0.62) # Pale face mask and belly
	skin_mat.roughness = 0.6
	
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.10, 0.08, 0.08)
	
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.48, 0.44, 0.40)
	rock_mat.roughness = 0.9
	
	visual_mesh.scale = Vector3(0.68, 0.68, 0.68)
	
	# Torso
	var torso = MeshInstance3D.new()
	var t_sph = SphereMesh.new()
	t_sph.radius = 0.24
	t_sph.height = 0.54
	torso.mesh = t_sph
	torso.material_override = fur_mat
	torso.position = Vector3(0, 0.55, 0.02)
	visual_mesh.add_child(torso)
	
	# Pale Chest
	var chest = MeshInstance3D.new()
	var c_sph = SphereMesh.new()
	c_sph.radius = 0.17
	c_sph.height = 0.38
	chest.mesh = c_sph
	chest.material_override = skin_mat
	chest.position = Vector3(0, 0.54, -0.12)
	chest.scale = Vector3(0.9, 0.9, 0.7)
	visual_mesh.add_child(chest)
	
	# Head
	var head = MeshInstance3D.new()
	var h_sph = SphereMesh.new()
	h_sph.radius = 0.17
	h_sph.height = 0.34
	head.mesh = h_sph
	head.material_override = fur_mat
	head.position = Vector3(0, 0.85, -0.18)
	visual_mesh.add_child(head)
	
	# Face Mask & Muzzle
	var face = MeshInstance3D.new()
	var f_sph = SphereMesh.new()
	f_sph.radius = 0.13
	f_sph.height = 0.26
	face.mesh = f_sph
	face.material_override = skin_mat
	face.position = Vector3(0, 0.84, -0.26)
	face.scale = Vector3(0.9, 0.85, 0.6)
	visual_mesh.add_child(face)
	
	for s in [-1.0, 1.0]:
		var eye = MeshInstance3D.new()
		var e_sph = SphereMesh.new()
		e_sph.radius = 0.03
		e_sph.height = 0.06
		eye.mesh = e_sph
		eye.material_override = eye_mat
		eye.position = Vector3(s * 0.07, 0.89, -0.32)
		visual_mesh.add_child(eye)
		
		var ear = MeshInstance3D.new()
		var er_sph = SphereMesh.new()
		er_sph.radius = 0.06
		er_sph.height = 0.12
		ear.mesh = er_sph
		ear.material_override = skin_mat
		ear.position = Vector3(s * 0.18, 0.87, -0.16)
		ear.scale = Vector3(0.4, 1.0, 0.8)
		visual_mesh.add_child(ear)
		
		# Limbs
		var arm = MeshInstance3D.new()
		var a_cyl = CylinderMesh.new()
		a_cyl.top_radius = 0.06
		a_cyl.bottom_radius = 0.05
		a_cyl.height = 0.38
		arm.mesh = a_cyl
		arm.material_override = fur_mat
		arm.position = Vector3(s * 0.22, 0.42, -0.12)
		arm.rotation_degrees = Vector3(14.0, 0, s * -14.0)
		visual_mesh.add_child(arm)
		
		var leg = MeshInstance3D.new()
		var l_cyl = CylinderMesh.new()
		l_cyl.top_radius = 0.065
		l_cyl.bottom_radius = 0.05
		l_cyl.height = 0.34
		leg.mesh = l_cyl
		leg.material_override = fur_mat
		leg.position = Vector3(s * 0.17, 0.28, 0.16)
		visual_mesh.add_child(leg)
		
	# Held Rock in Hand
	var rock = MeshInstance3D.new()
	var r_sph = SphereMesh.new()
	r_sph.radius = 0.11
	r_sph.height = 0.19
	rock.mesh = r_sph
	rock.material_override = rock_mat
	rock.position = Vector3(0.24, 0.24, -0.22)
	rock.scale = Vector3(1.1, 0.85, 1.0)
	visual_mesh.add_child(rock)
	
	# Long Arching Prehensile Tail
	for t_i in range(5):
		var t_seg = MeshInstance3D.new()
		var t_cyl = CylinderMesh.new()
		t_cyl.top_radius = 0.035
		t_cyl.bottom_radius = 0.04
		t_cyl.height = 0.18
		t_seg.mesh = t_cyl
		t_seg.material_override = fur_mat
		var t_ang = -28.0 + float(t_i) * 18.0
		t_seg.position = Vector3(0, 0.58 + float(t_i) * 0.12, 0.26 + float(t_i) * 0.08)
		t_seg.rotation_degrees = Vector3(t_ang, 0, 0)
		visual_mesh.add_child(t_seg)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	if has_meta("stealth_revealed_timer"):
		var __s_timer = get_meta("stealth_revealed_timer", 0.0)
		if __s_timer > 0.0:
			set_meta("stealth_revealed_timer", max(0.0, __s_timer - delta))
		
	# Retargeting check
	recheck_timer -= delta
	if recheck_timer <= 0.0:
		recheck_timer = randf_range(0.25, 0.45)
		_evaluate_targeting()
		
	var is_moving = false
	
	if current_target != null and is_instance_valid(current_target):
		var dist_to_target = global_position.distance_to(current_target.global_position)
		var dist_from_home = home_position.distance_to(current_target.global_position)
		
		# Leash break check
		if dist_from_home > leash_radius:
			current_target = null
		elif dist_to_target > attack_range:
			# Chase target
			var move_dir = (current_target.global_position - global_position).normalized()
			velocity.x = move_dir.x * speed
			velocity.z = move_dir.z * speed
			is_moving = true
			
			var look_pos = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
			if global_position.distance_to(look_pos) > 0.1:
				var s_before = scale
				look_at(look_pos, Vector3.UP)
				scale = Vector3.ONE * float(get_meta('gilded_gen_scale')) if has_meta('gilded_gen_scale') else s_before
		else:
			# Attack target
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			var look_pos = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
			if global_position.distance_to(look_pos) > 0.1:
				var s_before = scale
				look_at(look_pos, Vector3.UP)
				scale = Vector3.ONE * float(get_meta('gilded_gen_scale')) if has_meta('gilded_gen_scale') else s_before
				
			attack_timer -= delta
			if attack_timer <= 0.0:
				attack_timer = 1.0 / max(0.01, attack_speed)
				var th = current_target.get_node_or_null("HealthComponent")
				if th and not th.is_dead:
					set_meta("stealth_revealed_timer", 2.0)
					if creature_type == "SwarmAnt":
						_shoot_acid_spit(current_target)
					elif creature_type == "Monkey":
						_throw_rock(current_target)
					else:
						th.take_damage(attack_damage, global_position)
						if visual_mesh:
							visual_mesh.position.z -= 0.35 if creature_type == "Gorilla" else 0.2
	else:
		# Return to home nest or idle wander
		var dist_to_home = global_position.distance_to(home_position)
		if dist_to_home > nest_radius * 0.7:
			var home_dir = (home_position + idle_patrol_offset - global_position).normalized()
			velocity.x = home_dir.x * (speed * 0.75)
			velocity.z = home_dir.z * (speed * 0.75)
			is_moving = true
			
			var look_pos = global_position + Vector3(home_dir.x, 0, home_dir.z)
			if global_position.distance_to(look_pos) > 0.1:
				var s_before = scale
				look_at(look_pos, Vector3.UP)
				scale = Vector3.ONE * float(get_meta('gilded_gen_scale')) if has_meta('gilded_gen_scale') else s_before
		else:
			# Active territorial patrol around nest and dunes
			idle_patrol_timer -= delta
			if idle_patrol_timer <= 0.0:
				idle_patrol_timer = randf_range(2.5, 5.5)
				var angle = randf() * TAU
				var r = randf_range(2.0, nest_radius * 0.65)
				idle_patrol_offset = Vector3(cos(angle) * r, 0, sin(angle) * r)
				
			var patrol_target = home_position + idle_patrol_offset
			if global_position.distance_to(patrol_target) > 0.6:
				var p_dir = (patrol_target - global_position).normalized()
				velocity.x = p_dir.x * (speed * 0.45)
				velocity.z = p_dir.z * (speed * 0.45)
				is_moving = true
				
				var look_pos = global_position + Vector3(p_dir.x, 0, p_dir.z)
				if global_position.distance_to(look_pos) > 0.1:
					var s_before = scale
					look_at(look_pos, Vector3.UP)
					scale = Vector3.ONE * float(get_meta('gilded_gen_scale')) if has_meta('gilded_gen_scale') else s_before
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
				
	# Anti-stuck wall sliding against rocks and dunes
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.length() < 0.1: wall_normal = Vector3.UP
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < speed * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * speed * 1.5
				
	move_and_slide()
	
	# Procedural walk wobble
	if visual_mesh:
		if is_moving:
			anim_time += delta * (speed * 4.0 if creature_type in ["SwarmAnt", "Monkey"] else speed * 3.2)
			if creature_type == "Gorilla":
				visual_mesh.rotation.z = sin(anim_time) * 0.09
				visual_mesh.position.y = abs(sin(anim_time)) * 0.08
				visual_mesh.position.z = lerp(visual_mesh.position.z, 0.0, 10.0 * delta)
			elif creature_type == "Monkey":
				visual_mesh.position.y = abs(sin(anim_time * 1.4)) * 0.12
				visual_mesh.rotation.y = sin(anim_time * 0.8) * 0.14
				visual_mesh.position.z = lerp(visual_mesh.position.z, 0.0, 10.0 * delta)
			else:
				visual_mesh.rotation.y = sin(anim_time) * 0.12
				visual_mesh.position.y = abs(sin(anim_time * 2.0)) * 0.05
				visual_mesh.position.z = lerp(visual_mesh.position.z, 0.0, 10.0 * delta)
		else:
			visual_mesh.rotation.y = lerp(visual_mesh.rotation.y, 0.0, 10.0 * delta)
			visual_mesh.rotation.z = lerp(visual_mesh.rotation.z, 0.0, 10.0 * delta)
			visual_mesh.position.y = lerp(visual_mesh.position.y, 0.0, 10.0 * delta)
			visual_mesh.position.z = lerp(visual_mesh.position.z, 0.0, 10.0 * delta)

func _throw_rock(target_node: Node3D):
	if not is_instance_valid(target_node): return
	var proj_scene = preload("res://Scenes/Projectile.tscn")
	if proj_scene:
		var proj = proj_scene.instantiate()
		var scene_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if scene_root:
			scene_root.add_child(proj)
			proj.global_position = global_position + Vector3(0, 0.45, 0)
			proj.target = target_node
			proj.set("damage", attack_damage)
			proj.set("speed", 20.0)
			var p_mesh = proj.get_node_or_null("MeshInstance3D")
			if p_mesh:
				var r_mat = StandardMaterial3D.new()
				r_mat.albedo_color = Color(0.48, 0.44, 0.40)
				r_mat.roughness = 0.9
				p_mesh.material_override = r_mat
				var sm = SphereMesh.new()
				sm.radius = 0.15
				sm.height = 0.26
				p_mesh.mesh = sm

func _shoot_acid_spit(target_node: Node3D):
	if not is_instance_valid(target_node): return
	var proj_scene = preload("res://Scenes/Projectile.tscn")
	if proj_scene:
		var proj = proj_scene.instantiate()
		var scene_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if scene_root:
			scene_root.add_child(proj)
			proj.global_position = global_position + Vector3(0, 0.25, 0)
			proj.target = target_node
			proj.set("damage", attack_damage)
			proj.set("speed", 22.0)
			var p_mesh = proj.get_node_or_null("MeshInstance3D")
			if p_mesh:
				var a_mat = StandardMaterial3D.new()
				a_mat.albedo_color = Color(0.72, 0.88, 0.18)
				a_mat.emission_enabled = true
				a_mat.emission = Color(0.72, 0.88, 0.18)
				a_mat.emission_energy_multiplier = 2.0
				p_mesh.material_override = a_mat

func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var r = (loop as SceneTree).root
		if r and r.has_node("GameState"):
			return r.get_node("GameState")
	return null

func _evaluate_targeting():
	if not is_instance_valid(current_target):
		current_target = null
	else:
		var hc = current_target.get_node_or_null("HealthComponent")
		if hc and hc.is_dead:
			current_target = null
				
	if current_target == null:
		var closest_dist = nest_radius # Only aggro new targets entering nest territory
		var best_target = null
		var gs = _get_game_state()
		
		if is_inside_tree() and get_tree():
			var my_group = creature_type
			for node in get_tree().get_nodes_in_group("Targetable"):
				if node == self or not is_instance_valid(node): continue
				if node.is_in_group(my_group) or node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure"): continue
				
				var hc = node.get_node_or_null("HealthComponent")
				if hc and hc.is_dead: continue
				
				# Check stealth in grass
				if gs and gs.is_unit_stealthed_from(node, self):
					continue
					
				var dist_from_nest = home_position.distance_to(node.global_position)
				var dist_from_creature = global_position.distance_to(node.global_position)
				var in_territory = (dist_from_nest <= nest_radius) or (dist_from_creature <= (nest_radius * 0.75) and dist_from_nest <= leash_radius * 0.85)
				if in_territory and dist_from_nest < closest_dist:
					closest_dist = dist_from_nest
					best_target = node
				
		current_target = best_target

func _on_health_changed(new_h: float, max_h: float):
	if current_target == null and new_h < max_h:
		_evaluate_retaliation()

func _evaluate_retaliation():
	var closest_d: float = leash_radius
	var best: Node3D = null
	var my_group = creature_type
	if not is_inside_tree() or not get_tree(): return
	for node in get_tree().get_nodes_in_group("Targetable"):
		if node == self or not is_instance_valid(node): continue
		if node.is_in_group(my_group) or node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure"): continue
		var hc = node.get_node_or_null("HealthComponent")
		if hc and hc.is_dead: continue
		var d = global_position.distance_to(node.global_position)
		if d < closest_d:
			closest_d = d
			best = node
	if best != null:
		current_target = best

func _on_died():
	set_physics_process(false)

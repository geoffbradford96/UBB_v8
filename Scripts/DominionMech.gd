extends "res://Scripts/Unit.gd"

var _mech_legs: Array[Node3D] = []
var _mech_feet: Array[Node3D] = []
var _mech_cannons: Array[Node3D] = []

func _ready():
    super._ready()
    # Procedural mesh generation for DominionMech
    var mesh_node = Node3D.new()
    mesh_node.name = "VisualPivot"
    add_child(mesh_node)
    self.mesh = mesh_node
    self.base_mesh_pos = Vector3.ZERO
    

    var mat_armor = StandardMaterial3D.new()
    mat_armor.albedo_color = Color(0.24, 0.34, 0.18)
    mat_armor.roughness = 0.55
    mat_armor.metallic = 0.35

    var mat_metal = StandardMaterial3D.new()
    mat_metal.albedo_color = Color(0.16, 0.18, 0.20)
    mat_metal.metallic = 0.85
    mat_metal.roughness = 0.35

    var mat_amber = StandardMaterial3D.new()
    mat_amber.albedo_color = Color(1.0, 0.65, 0.1)
    mat_amber.emission_enabled = true
    mat_amber.emission = Color(1.0, 0.65, 0.1)
    mat_amber.emission_energy_multiplier = 2.0

    # Armored Chassis & Torso
    var body = MeshInstance3D.new()
    body.mesh = BoxMesh.new()
    body.mesh.size = Vector3(2.2, 2.2, 2.0)
    body.material_override = mat_armor
    body.position.y = 2.6
    mesh_node.add_child(body)

    # Armored Cockpit Slit / Amber Optics
    var visor = MeshInstance3D.new()
    visor.mesh = BoxMesh.new()
    visor.mesh.size = Vector3(1.4, 0.35, 0.1)
    visor.material_override = mat_amber
    visor.position = Vector3(0, 2.8, -1.05)
    mesh_node.add_child(visor)

    # Heavy Shoulder Armor Pods + Connecting Shoulder Collars
    for side in [-1.0, 1.0]:
        var s_collar = MeshInstance3D.new()
        var sc_cyl = CylinderMesh.new()
        sc_cyl.top_radius = 0.28
        sc_cyl.bottom_radius = 0.28
        sc_cyl.height = 0.5
        s_collar.mesh = sc_cyl
        s_collar.material_override = mat_metal
        s_collar.rotation_degrees.z = 90
        s_collar.position = Vector3(side * 1.15, 3.0, 0)
        mesh_node.add_child(s_collar)

        var shoulder = MeshInstance3D.new()
        shoulder.mesh = BoxMesh.new()
        shoulder.mesh.size = Vector3(0.8, 1.0, 1.6)
        shoulder.material_override = mat_armor
        shoulder.position = Vector3(side * 1.5, 3.1, 0)
        mesh_node.add_child(shoulder)

        var cannon = MeshInstance3D.new()
        cannon.mesh = CylinderMesh.new()
        cannon.mesh.top_radius = 0.2
        cannon.mesh.bottom_radius = 0.25
        cannon.mesh.height = 2.4
        cannon.material_override = mat_metal
        cannon.rotation_degrees.x = -90.0
        cannon.position = Vector3(side * 1.5, 3.1, -1.2)
        mesh_node.add_child(cannon)
        _mech_cannons.append(cannon)

    # Central Pelvis / Waist Block connecting torso to hip joints
    var pelvis = MeshInstance3D.new()
    var p_box = BoxMesh.new()
    p_box.size = Vector3(1.9, 0.45, 1.3)
    pelvis.mesh = p_box
    pelvis.material_override = mat_metal
    pelvis.position = Vector3(0, 1.55, 0)
    mesh_node.add_child(pelvis)

    # Hydraulic Walker Legs
    for side in [-1.0, 1.0]:
        var hip = MeshInstance3D.new()
        hip.mesh = SphereMesh.new()
        hip.mesh.radius = 0.4
        hip.mesh.height = 0.8
        hip.material_override = mat_metal
        hip.position = Vector3(side * 0.9, 1.6, 0)
        mesh_node.add_child(hip)

        var leg = MeshInstance3D.new()
        leg.mesh = CylinderMesh.new()
        leg.mesh.top_radius = 0.3
        leg.mesh.bottom_radius = 0.35
        leg.mesh.height = 1.6
        leg.material_override = mat_metal
        leg.position = Vector3(side * 0.9, 0.8, 0)
        mesh_node.add_child(leg)
        _mech_legs.append(leg)

        var foot = MeshInstance3D.new()
        foot.mesh = BoxMesh.new()
        foot.mesh.size = Vector3(0.8, 0.3, 1.2)
        foot.material_override = mat_armor
        foot.position = Vector3(side * 0.9, 0.15, -0.2)
        mesh_node.add_child(foot)
        _mech_feet.append(foot)

func _animate_mesh(delta: float, moving: bool):
    if attack_anim_timer > 0.0:
        attack_anim_timer = max(0.0, attack_anim_timer - delta)
    var atk_swing: float = sin((1.0 - (attack_anim_timer / 0.35)) * PI) if attack_anim_timer > 0.0 else 0.0
    if moving and mesh:
        walk_time += delta * speed * 3.5
        mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * 0.35
        mesh.rotation.z = sin(walk_time) * 0.05
        for i in range(_mech_legs.size()):
            var sign_dir: float = 1.0 if i == 0 else -1.0
            var stride: float = sin(walk_time) * sign_dir
            if is_instance_valid(_mech_legs[i]):
                _mech_legs[i].rotation.x = stride * 0.45
                _mech_legs[i].position.z = -stride * 0.35
            if i < _mech_feet.size() and is_instance_valid(_mech_feet[i]):
                _mech_feet[i].position.z = -0.2 - stride * 0.55
                _mech_feet[i].position.y = 0.15 + max(0.0, stride) * 0.25
    elif mesh:
        mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y, 10.0 * delta)
        mesh.rotation.z = lerp(mesh.rotation.z, 0.0, 10.0 * delta)
        for i in range(_mech_legs.size()):
            if is_instance_valid(_mech_legs[i]):
                _mech_legs[i].rotation.x = lerp(_mech_legs[i].rotation.x, 0.0, 10.0 * delta)
                _mech_legs[i].position.z = lerp(_mech_legs[i].position.z, 0.0, 10.0 * delta)
            if i < _mech_feet.size() and is_instance_valid(_mech_feet[i]):
                _mech_feet[i].position.z = lerp(_mech_feet[i].position.z, -0.2, 10.0 * delta)
                _mech_feet[i].position.y = lerp(_mech_feet[i].position.y, 0.15, 10.0 * delta)
    for i in range(_mech_cannons.size()):
        if is_instance_valid(_mech_cannons[i]):
            _mech_cannons[i].position.z = -1.2 + atk_swing * 0.42


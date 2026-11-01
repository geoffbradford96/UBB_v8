extends "res://Scripts/Unit.gd"

var _leviathan_legs: Array[Node3D] = []
var _leviathan_head: Node3D = null
var _leviathan_tusks: Array[Node3D] = []

func _ready():
    super._ready()
    # Procedural mesh generation for RimworlderLeviathan
    var mesh_node = Node3D.new()
    mesh_node.name = "VisualPivot"
    add_child(mesh_node)
    self.mesh = mesh_node
    self.base_mesh_pos = Vector3.ZERO
    

    var mat_hide = StandardMaterial3D.new()
    mat_hide.albedo_color = Color(0.38, 0.28, 0.18)
    mat_hide.roughness = 0.9

    var mat_scales = StandardMaterial3D.new()
    mat_scales.albedo_color = Color(0.25, 0.32, 0.18)
    mat_scales.roughness = 0.85

    var mat_bone = StandardMaterial3D.new()
    mat_bone.albedo_color = Color(0.88, 0.84, 0.72)
    mat_bone.roughness = 0.6

    var mat_eyes = StandardMaterial3D.new()
    mat_eyes.albedo_color = Color(1.0, 0.6, 0.1)
    mat_eyes.emission_enabled = true
    mat_eyes.emission = Color(1.0, 0.6, 0.1)
    mat_eyes.emission_energy_multiplier = 2.0

    # Massive Beast Torso
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 2.5
    body.mesh.height = 4.8
    body.material_override = mat_hide
    body.position.y = 2.8
    body.rotation_degrees.x = 90
    mesh_node.add_child(body)

    # Dorsal Mossy Bone Ridge Plates
    for i in range(4):
        var spine = MeshInstance3D.new()
        spine.mesh = PrismMesh.new()
        spine.mesh.size = Vector3(0.6, 1.4 - i*0.2, 1.0)
        spine.material_override = mat_scales
        spine.position = Vector3(0, 4.4 - i*0.2, (i - 1.5) * 1.0)
        mesh_node.add_child(spine)

    # Thick Muscular Neck Bridge connecting torso to head
    var neck = MeshInstance3D.new()
    var n_cyl = CylinderMesh.new()
    n_cyl.top_radius = 1.45
    n_cyl.bottom_radius = 1.85
    n_cyl.height = 1.6
    neck.mesh = n_cyl
    neck.material_override = mat_hide
    neck.rotation_degrees.x = 75
    neck.position = Vector3(0, 3.0, -1.75)
    mesh_node.add_child(neck)

    # Colossal Horned Head
    var head = MeshInstance3D.new()
    head.mesh = SphereMesh.new()
    head.mesh.radius = 1.6
    head.mesh.height = 2.4
    head.material_override = mat_hide
    head.position = Vector3(0, 3.2, -2.6)
    mesh_node.add_child(head)
    _leviathan_head = head

    # Feral Glowing Amber Eyes
    for side in [-1.0, 1.0]:
        var eye = MeshInstance3D.new()
        eye.mesh = SphereMesh.new()
        eye.mesh.radius = 0.25
        eye.material_override = mat_eyes
        eye.position = Vector3(side * 0.9, 3.6, -3.2)
        mesh_node.add_child(eye)

    # Giant Curved Ivory Tusks + Jaw Root Sockets
    for side in [-1.0, 1.0]:
        var jaw_socket = MeshInstance3D.new()
        var js_sph = SphereMesh.new()
        js_sph.radius = 0.48
        jaw_socket.mesh = js_sph
        jaw_socket.material_override = mat_hide
        jaw_socket.position = Vector3(side * 1.1, 2.75, -3.05)
        mesh_node.add_child(jaw_socket)

        var tusk = MeshInstance3D.new()
        tusk.mesh = CylinderMesh.new()
        tusk.mesh.top_radius = 0.05
        tusk.mesh.bottom_radius = 0.35
        tusk.mesh.height = 2.6
        tusk.material_override = mat_bone
        tusk.position = Vector3(side * 1.25, 2.8, -3.5)
        tusk.rotation_degrees.x = 55
        tusk.rotation_degrees.y = side * -20
        mesh_node.add_child(tusk)
        _leviathan_tusks.append(tusk)

    # Pillar Quadruped Legs + Muscular Shoulder/Hip Haunches
    for i in range(4):
        var x = (float(i % 2) - 0.5) * 3.6
        var z = (float(int(i / 2.0)) - 0.5) * 3.0

        var haunch = MeshInstance3D.new()
        var h_sph = SphereMesh.new()
        h_sph.radius = 0.95
        h_sph.height = 1.9
        haunch.mesh = h_sph
        haunch.material_override = mat_hide
        haunch.position = Vector3(x * 0.82, 2.15, z)
        mesh_node.add_child(haunch)

        var leg = MeshInstance3D.new()
        leg.mesh = CylinderMesh.new()
        leg.mesh.top_radius = 0.7
        leg.mesh.bottom_radius = 0.8
        leg.mesh.height = 2.6
        leg.material_override = mat_hide
        leg.position = Vector3(x, 1.3, z)
        leg.rotation_degrees.z = 12 if x < 0 else -12
        mesh_node.add_child(leg)
        _leviathan_legs.append(leg)

func _animate_mesh(delta: float, moving: bool):
    if attack_anim_timer > 0.0:
        attack_anim_timer = max(0.0, attack_anim_timer - delta)
    var atk_swing: float = sin((1.0 - (attack_anim_timer / 0.35)) * PI) if attack_anim_timer > 0.0 else 0.0
    if moving and mesh:
        walk_time += delta * speed * 2.8
        mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * 0.35
        mesh.rotation.z = sin(walk_time) * 0.04
        for i in range(_leviathan_legs.size()):
            if is_instance_valid(_leviathan_legs[i]):
                var diag_sign: float = 1.0 if (i == 0 or i == 3) else -1.0
                _leviathan_legs[i].rotation.x = sin(walk_time) * diag_sign * 0.38
    elif mesh:
        mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y, 10.0 * delta)
        mesh.rotation.z = lerp(mesh.rotation.z, 0.0, 10.0 * delta)
        for i in range(_leviathan_legs.size()):
            if is_instance_valid(_leviathan_legs[i]):
                _leviathan_legs[i].rotation.x = lerp(_leviathan_legs[i].rotation.x, 0.0, 10.0 * delta)
    if is_instance_valid(_leviathan_head):
        _leviathan_head.position.z = -2.6 - atk_swing * 0.65
        _leviathan_head.position.y = 3.2 + atk_swing * 0.45
    for i in range(_leviathan_tusks.size()):
        if is_instance_valid(_leviathan_tusks[i]):
            _leviathan_tusks[i].position.z = -3.6 - atk_swing * 0.75
            _leviathan_tusks[i].rotation_degrees.x = 55.0 + atk_swing * 28.0


extends "res://Scripts/Unit.gd"

var _scrap_legs: Array[Node3D] = []
var _scrap_feet: Array[Node3D] = []
var _claw_arm: Node3D = null
var _pincer_top: Node3D = null
var _pincer_bot: Node3D = null
var _cannon: Node3D = null

func _ready():
    super._ready()
    # Procedural mesh generation for ScrapMech
    var mesh_node = Node3D.new()
    mesh_node.name = "VisualPivot"
    add_child(mesh_node)
    self.mesh = mesh_node
    self.base_mesh_pos = Vector3.ZERO
    

    var mat_rust = StandardMaterial3D.new()
    mat_rust.albedo_color = Color(0.55, 0.28, 0.12)
    mat_rust.metallic = 0.5
    mat_rust.roughness = 0.9

    var mat_iron = StandardMaterial3D.new()
    mat_iron.albedo_color = Color(0.18, 0.18, 0.20)
    mat_iron.metallic = 0.85
    mat_iron.roughness = 0.4

    var mat_hazard = StandardMaterial3D.new()
    mat_hazard.albedo_color = Color(0.75, 0.60, 0.15)
    mat_hazard.roughness = 0.8

    # Welded Boiler Hull
    var body = MeshInstance3D.new()
    body.mesh = CylinderMesh.new()
    body.mesh.top_radius = 1.3
    body.mesh.bottom_radius = 1.3
    body.mesh.height = 2.2
    body.material_override = mat_rust
    body.position.y = 2.6
    body.rotation_degrees.x = 90
    mesh_node.add_child(body)

    # Scavenged Front Hazard Shield Plate
    var plate = MeshInstance3D.new()
    plate.mesh = BoxMesh.new()
    plate.mesh.size = Vector3(1.8, 1.4, 0.2)
    plate.material_override = mat_hazard
    plate.position = Vector3(0, 2.7, -1.25)
    mesh_node.add_child(plate)

    # Angled Smokestack Exhaust
    var stack = MeshInstance3D.new()
    stack.mesh = CylinderMesh.new()
    stack.mesh.top_radius = 0.25
    stack.mesh.bottom_radius = 0.3
    stack.mesh.height = 1.8
    stack.material_override = mat_iron
    stack.position = Vector3(0.9, 3.8, 0.6)
    stack.rotation_degrees.z = -15
    mesh_node.add_child(stack)

    # Left Heavy Scrap Pincer Claw
    # Left & Right Shoulder Axle Mounts connecting boiler (r=1.3) to arms (x=+-1.6)
    for side in [-1.0, 1.0]:
        var s_axle = MeshInstance3D.new()
        var sa_cyl = CylinderMesh.new()
        sa_cyl.top_radius = 0.28
        sa_cyl.bottom_radius = 0.28
        sa_cyl.height = 0.75
        s_axle.mesh = sa_cyl
        s_axle.material_override = mat_iron
        s_axle.rotation_degrees.z = 90
        s_axle.position = Vector3(side * 1.32, 2.6, -0.2)
        mesh_node.add_child(s_axle)

    var claw_arm = MeshInstance3D.new()
    claw_arm.mesh = BoxMesh.new()
    claw_arm.mesh.size = Vector3(0.4, 0.4, 1.8)
    claw_arm.material_override = mat_iron
    claw_arm.position = Vector3(-1.6, 2.6, -0.6)
    mesh_node.add_child(claw_arm)
    _claw_arm = claw_arm

    var wrist_hub = MeshInstance3D.new()
    var wh_cyl = CylinderMesh.new()
    wh_cyl.top_radius = 0.24
    wh_cyl.bottom_radius = 0.24
    wh_cyl.height = 0.55
    wrist_hub.mesh = wh_cyl
    wrist_hub.material_override = mat_iron
    wrist_hub.rotation_degrees.z = 90
    wrist_hub.position = Vector3(-1.6, 2.6, -1.45)
    mesh_node.add_child(wrist_hub)

    var pincer1 = MeshInstance3D.new()
    pincer1.mesh = BoxMesh.new()
    pincer1.mesh.size = Vector3(0.2, 0.8, 0.8)
    pincer1.material_override = mat_hazard
    pincer1.position = Vector3(-1.6, 2.9, -1.6)
    pincer1.rotation_degrees.z = 25
    mesh_node.add_child(pincer1)
    _pincer_top = pincer1

    var pincer2 = MeshInstance3D.new()
    pincer2.mesh = BoxMesh.new()
    pincer2.mesh.size = Vector3(0.2, 0.8, 0.8)
    pincer2.material_override = mat_hazard
    pincer2.position = Vector3(-1.6, 2.3, -1.6)
    pincer2.rotation_degrees.z = -25
    mesh_node.add_child(pincer2)
    _pincer_bot = pincer2

    # Right Scrap Cannon / Riveted Flak Barrel
    var cannon = MeshInstance3D.new()
    cannon.mesh = CylinderMesh.new()
    cannon.mesh.top_radius = 0.3
    cannon.mesh.bottom_radius = 0.35
    cannon.mesh.height = 2.4
    cannon.material_override = mat_iron
    cannon.rotation_degrees.x = -90.0
    cannon.position = Vector3(1.6, 2.6, -1.0)
    mesh_node.add_child(cannon)
    _cannon = cannon

    # Heavy Scrap Pelvis / Hip Axle Block connecting boiler bottom to girder legs
    var hip_block = MeshInstance3D.new()
    var hb_box = BoxMesh.new()
    hb_box.size = Vector3(2.2, 0.48, 1.1)
    hip_block.mesh = hb_box
    hip_block.material_override = mat_iron
    hip_block.position = Vector3(0, 1.65, 0)
    mesh_node.add_child(hip_block)

    # Heavy Welded Girder Legs
    for side in [-1.0, 1.0]:
        var leg = MeshInstance3D.new()
        leg.mesh = BoxMesh.new()
        leg.mesh.size = Vector3(0.5, 2.0, 0.5)
        leg.material_override = mat_rust
        leg.position = Vector3(side * 1.1, 1.1, 0)
        leg.rotation_degrees.z = side * -12.0
        mesh_node.add_child(leg)
        _scrap_legs.append(leg)

        var foot = MeshInstance3D.new()
        foot.mesh = BoxMesh.new()
        foot.mesh.size = Vector3(0.9, 0.3, 1.3)
        foot.material_override = mat_iron
        foot.position = Vector3(side * 1.25, 0.15, -0.1)
        mesh_node.add_child(foot)
        _scrap_feet.append(foot)

func _animate_mesh(delta: float, moving: bool):
    if attack_anim_timer > 0.0:
        attack_anim_timer = max(0.0, attack_anim_timer - delta)
    var atk_swing: float = sin((1.0 - (attack_anim_timer / 0.35)) * PI) if attack_anim_timer > 0.0 else 0.0
    if moving and mesh:
        walk_time += delta * speed * 3.2
        mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * 0.4
        mesh.rotation.z = sin(walk_time) * 0.08
        for i in range(_scrap_legs.size()):
            var sign_dir: float = 1.0 if i == 0 else -1.0
            var stride: float = sin(walk_time) * sign_dir
            if is_instance_valid(_scrap_legs[i]):
                _scrap_legs[i].rotation.x = stride * 0.48
                _scrap_legs[i].position.z = -stride * 0.35
            if i < _scrap_feet.size() and is_instance_valid(_scrap_feet[i]):
                _scrap_feet[i].position.z = -0.1 - stride * 0.55
                _scrap_feet[i].position.y = 0.15 + max(0.0, stride) * 0.28
    elif mesh:
        mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y, 10.0 * delta)
        mesh.rotation.z = lerp(mesh.rotation.z, 0.0, 10.0 * delta)
        for i in range(_scrap_legs.size()):
            if is_instance_valid(_scrap_legs[i]):
                _scrap_legs[i].rotation.x = lerp(_scrap_legs[i].rotation.x, 0.0, 10.0 * delta)
                _scrap_legs[i].position.z = lerp(_scrap_legs[i].position.z, 0.0, 10.0 * delta)
            if i < _scrap_feet.size() and is_instance_valid(_scrap_feet[i]):
                _scrap_feet[i].position.z = lerp(_scrap_feet[i].position.z, -0.1, 10.0 * delta)
                _scrap_feet[i].position.y = lerp(_scrap_feet[i].position.y, 0.15, 10.0 * delta)
    if is_instance_valid(_claw_arm):
        _claw_arm.position.z = -0.6 - atk_swing * 0.65
    if is_instance_valid(_pincer_top):
        _pincer_top.position.z = -1.6 - atk_swing * 0.65
        _pincer_top.rotation_degrees.x = -atk_swing * 35.0
    if is_instance_valid(_pincer_bot):
        _pincer_bot.position.z = -1.6 - atk_swing * 0.65
        _pincer_bot.rotation_degrees.x = atk_swing * 35.0
    if is_instance_valid(_cannon):
        _cannon.position.z = -1.0 + atk_swing * 0.35


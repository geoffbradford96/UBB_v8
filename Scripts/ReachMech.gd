extends "res://Scripts/Unit.gd"

var _reach_ring: Node3D = null
var _reach_core: Node3D = null
var _reach_wings: Array[Node3D] = []

func _ready():
    super._ready()
    # Procedural mesh generation for ReachMech
    var mesh_node = Node3D.new()
    mesh_node.name = "VisualPivot"
    add_child(mesh_node)
    self.mesh = mesh_node
    self.base_mesh_pos = Vector3.ZERO
    

    var mat_white = StandardMaterial3D.new()
    mat_white.albedo_color = Color(0.95, 0.97, 1.0)
    mat_white.roughness = 0.15
    mat_white.metallic = 0.15

    var mat_chrome = StandardMaterial3D.new()
    mat_chrome.albedo_color = Color(0.85, 0.88, 0.95)
    mat_chrome.metallic = 0.9
    mat_chrome.roughness = 0.2

    var mat_cyan = StandardMaterial3D.new()
    mat_cyan.albedo_color = Color(0.0, 0.88, 1.0)
    mat_cyan.emission_enabled = true
    mat_cyan.emission = Color(0.0, 0.88, 1.0)
    mat_cyan.emission_energy_multiplier = 3.5

    # Sleek Porcelain Torso Core
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 1.3
    body.mesh.height = 2.2
    body.material_override = mat_white
    body.position.y = 2.8
    mesh_node.add_child(body)

    # Radiant Cyan Energy Core
    var core = MeshInstance3D.new()
    core.mesh = SphereMesh.new()
    core.mesh.radius = 0.7
    core.material_override = mat_cyan
    core.position = Vector3(0, 2.8, -0.7)
    mesh_node.add_child(core)
    _reach_core = core

    # Levitating Anti-Gravity Drive Ring + Connecting Spokes
    var ring = MeshInstance3D.new()
    ring.mesh = TorusMesh.new()
    ring.mesh.outer_radius = 1.8
    ring.mesh.inner_radius = 1.55
    ring.material_override = mat_cyan
    ring.position.y = 2.2
    mesh_node.add_child(ring)
    _reach_ring = ring

    for r_s in [-1.0, 1.0]:
        var spoke = MeshInstance3D.new()
        var sp_box = BoxMesh.new()
        sp_box.size = Vector3(3.3, 0.10, 0.14)
        spoke.mesh = sp_box
        spoke.material_override = mat_chrome
        spoke.rotation_degrees.y = 45.0 if r_s < 0.0 else -45.0
        ring.add_child(spoke)

    # Swept Porcelain Wing Fins + Connecting Chrome Struts
    for side in [-1.0, 1.0]:
        var strut = MeshInstance3D.new()
        var s_cyl = CylinderMesh.new()
        s_cyl.top_radius = 0.12
        s_cyl.bottom_radius = 0.16
        s_cyl.height = 2.6
        strut.mesh = s_cyl
        strut.material_override = mat_chrome
        strut.position = Vector3(side * 2.1, 3.3, 0.2)
        strut.rotation_degrees = Vector3(0.0, side * 15.0, side * -68.0)
        mesh_node.add_child(strut)

        var wing = MeshInstance3D.new()
        wing.mesh = PrismMesh.new()
        wing.mesh.size = Vector3(2.8, 0.25, 1.4)
        wing.material_override = mat_white
        wing.position = Vector3(side * 2.0, 3.2, 0.2)
        wing.rotation_degrees.z = side * -20.0
        wing.rotation_degrees.y = side * 15.0
        mesh_node.add_child(wing)
        _reach_wings.append(wing)

        var wing_tip = MeshInstance3D.new()
        wing_tip.mesh = SphereMesh.new()
        wing_tip.mesh.radius = 0.24
        wing_tip.material_override = mat_cyan
        wing_tip.position = Vector3(side * 3.25, 3.65, 0.2)
        mesh_node.add_child(wing_tip)

    # Levitating Stabilizer Spire bridging core to lower ring
    var pylon = MeshInstance3D.new()
    pylon.mesh = CylinderMesh.new()
    pylon.mesh.top_radius = 0.28
    pylon.mesh.bottom_radius = 0.42
    pylon.mesh.height = 1.9
    pylon.material_override = mat_chrome
    pylon.position.y = 1.55
    mesh_node.add_child(pylon)

func _animate_mesh(delta: float, moving: bool):
    if attack_anim_timer > 0.0:
        attack_anim_timer = max(0.0, attack_anim_timer - delta)
    var atk_swing: float = sin((1.0 - (attack_anim_timer / 0.35)) * PI) if attack_anim_timer > 0.0 else 0.0
    if mesh:
        var t = Time.get_ticks_msec() * 0.003
        var hover = sin(t) * 0.35 + 0.35
        mesh.position.y = base_mesh_pos.y + hover
        if moving:
            mesh.rotation.z = lerp(mesh.rotation.z, sin(t * 2.2) * 0.04, delta * 5.0)
            mesh.rotation.x = lerp(mesh.rotation.x, -0.08, delta * 5.0)
        else:
            mesh.rotation.z = lerp(mesh.rotation.z, 0.0, delta * 5.0)
            mesh.rotation.x = lerp(mesh.rotation.x, 0.0, delta * 5.0)
        if is_instance_valid(_reach_ring):
            _reach_ring.rotation.y += delta * (3.2 if moving else 1.6)
            _reach_ring.rotation.x = sin(t * 1.4) * 0.18
        if is_instance_valid(_reach_core):
            var s = 1.0 + sin(t * 2.5) * 0.08 + atk_swing * 0.35
            _reach_core.scale = Vector3(s, s, s)
        for i in range(_reach_wings.size()):
            if is_instance_valid(_reach_wings[i]):
                var side: float = -1.0 if i == 0 else 1.0
                _reach_wings[i].rotation_degrees.z = side * (-20.0 + sin(t * 2.0) * 6.0 - atk_swing * 14.0)


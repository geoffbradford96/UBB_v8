extends "res://Scripts/Unit.gd"

var _spiker_legs: Array[Node3D] = []
var _spiker_spines: Array[Node3D] = []

func _ready():
    super._ready()
    # Procedural mesh generation for VoidSpiker
    var mesh_node = Node3D.new()
    mesh_node.name = "VisualPivot"
    add_child(mesh_node)
    self.mesh = mesh_node
    self.base_mesh_pos = Vector3.ZERO
    

    var mat_chitin = StandardMaterial3D.new()
    mat_chitin.albedo_color = Color(0.12, 0.02, 0.18)
    mat_chitin.metallic = 0.75
    mat_chitin.roughness = 0.2

    var mat_spikes = StandardMaterial3D.new()
    mat_spikes.albedo_color = Color(0.85, 0.1, 0.85)
    mat_spikes.emission_enabled = true
    mat_spikes.emission = Color(0.85, 0.1, 0.85)
    mat_spikes.emission_energy_multiplier = 3.5

    var mat_eyes = StandardMaterial3D.new()
    mat_eyes.albedo_color = Color(0.95, 0.0, 0.85)
    mat_eyes.emission_enabled = true
    mat_eyes.emission = Color(0.95, 0.0, 0.85)
    mat_eyes.emission_energy_multiplier = 2.5

    # Segmented Obsidian Carapace
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.radius = 1.2
    body.mesh.height = 3.8
    body.material_override = mat_chitin
    body.position.y = 1.4
    body.rotation_degrees.x = 90
    mesh_node.add_child(body)

    # Dorsal Crystalline Spines (2 Rows of 4 Razor Spines)
    for i in range(8):
        var side = -1.0 if (i % 2 == 0) else 1.0
        var row = float(int(i / 2.0))
        var spike = MeshInstance3D.new()
        spike.mesh = CylinderMesh.new()
        spike.mesh.top_radius = 0.02
        spike.mesh.bottom_radius = 0.22
        spike.mesh.height = 1.8 + (1.5 - abs(row - 1.5)) * 0.4
        spike.material_override = mat_spikes
        spike.position = Vector3(side * 0.6, 2.2, (row - 1.5) * 0.9)
        spike.rotation_degrees.x = -25 + (row * 10)
        spike.rotation_degrees.z = side * 20
        mesh_node.add_child(spike)
        _spiker_spines.append(spike)

    # Bioluminescent Cluster Eyes
    for i in range(4):
        var eye = MeshInstance3D.new()
        eye.mesh = SphereMesh.new()
        eye.mesh.radius = 0.15
        eye.material_override = mat_eyes
        var side = -1.0 if (i % 2 == 0) else 1.0
        var row_offset = float(int(i / 2.0))
        eye.position = Vector3(side * (0.3 + row_offset * 0.25), 1.6 + row_offset * 0.2, -1.8)
        mesh_node.add_child(eye)

    # Scuttling Chitin Legs (6 Spider-like Needle Legs with Coxa Hip Sockets)
    for i in range(6):
        var side = -1.0 if (i % 2 == 0) else 1.0
        var row = float(int(i / 2.0))

        var coxa = MeshInstance3D.new()
        var c_sph = SphereMesh.new()
        c_sph.radius = 0.26
        c_sph.height = 0.52
        coxa.mesh = c_sph
        coxa.material_override = mat_chitin
        coxa.position = Vector3(side * 1.05, 1.15, (row - 1.0) * 1.1)
        mesh_node.add_child(coxa)

        var leg = MeshInstance3D.new()
        leg.mesh = CylinderMesh.new()
        leg.mesh.top_radius = 0.12
        leg.mesh.bottom_radius = 0.04
        leg.mesh.height = 2.2
        leg.material_override = mat_chitin
        leg.position = Vector3(side * 1.32, 0.7, (row - 1.0) * 1.1)
        leg.rotation_degrees.z = side * 35.0
        mesh_node.add_child(leg)
        _spiker_legs.append(leg)

func _animate_mesh(delta: float, moving: bool):
    if attack_anim_timer > 0.0:
        attack_anim_timer = max(0.0, attack_anim_timer - delta)
    var atk_swing: float = sin((1.0 - (attack_anim_timer / 0.35)) * PI) if attack_anim_timer > 0.0 else 0.0
    if moving and mesh:
        walk_time += delta * speed * 6.0
        mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * 0.15
        mesh.rotation.y = sin(walk_time * 0.5) * 0.08
        for i in range(_spiker_legs.size()):
            if is_instance_valid(_spiker_legs[i]):
                var side: float = -1.0 if (i % 2 == 0) else 1.0
                _spiker_legs[i].rotation.x = sin(walk_time + float(i) * 1.1) * 0.38
                _spiker_legs[i].rotation_degrees.z = side * 35.0 + cos(walk_time + float(i) * 1.1) * 10.0
    elif mesh:
        mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y, 12.0 * delta)
        mesh.rotation.y = lerp(mesh.rotation.y, 0.0, 12.0 * delta)
        for i in range(_spiker_legs.size()):
            if is_instance_valid(_spiker_legs[i]):
                _spiker_legs[i].rotation.x = lerp(_spiker_legs[i].rotation.x, 0.0, 12.0 * delta)
    for i in range(_spiker_spines.size()):
        if is_instance_valid(_spiker_spines[i]):
            var row: float = float(int(i / 2.0))
            _spiker_spines[i].rotation_degrees.x = -25.0 + (row * 10.0) - atk_swing * 38.0
            _spiker_spines[i].position.y = 2.2 + atk_swing * 0.32


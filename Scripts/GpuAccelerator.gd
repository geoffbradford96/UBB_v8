class_name GpuAccelerator
extends RefCounted

# =============================================================================
# UBB v8 GPU ACCELERATOR & SPATIAL HASH ENGINE
# Offloads per-frame environment animations to GPU vertex/fragment shaders,
# configures hardware 3D LOD & distance culling, provides GPU RenderingDevice
# compute dispatch (with automatic headless fallback), and maintains an O(1)
# spatial hash grid for unit separation and proximity queries.
# =============================================================================

static var _shader_cache: Dictionary = {}
static var _spatial_grid: Dictionary = {}
static var _spatial_cell_size: float = 4.0
static var _last_grid_frame: int = -1

static var _rd: RenderingDevice = null
static var _rd_checked: bool = false
static var _rd_supported: bool = false
static var _compute_shader_rid: RID = RID()
static var _compute_pipeline_rid: RID = RID()

# -----------------------------------------------------------------------------
# 1. CACHED GPU SHADER MATERIALS (OFFLOAD CPU ANIMATIONS TO GPU VERTEX/FRAG)
# -----------------------------------------------------------------------------
static func get_quicksand_vortex_shader() -> ShaderMaterial:
	if _shader_cache.has("quicksand_vortex"):
		return _shader_cache["quicksand_vortex"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 mire_light : source_color = vec4(0.48, 0.36, 0.20, 1.0);
uniform vec4 mire_dark : source_color = vec4(0.32, 0.22, 0.12, 1.0);
uniform float swirl_speed = 0.65;

void vertex() {
	float ang = TIME * swirl_speed;
	float c = cos(ang);
	float s = sin(ang);
	vec2 rxz = vec2(VERTEX.x * c - VERTEX.z * s, VERTEX.x * s + VERTEX.z * c);
	VERTEX.x = rxz.x;
	VERTEX.z = rxz.y;
	VERTEX.y += sin(TIME * 2.2 + length(VERTEX.xz) * 3.0) * 0.012;
}

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float r = length(centered);
	float theta = atan(centered.y, centered.x) + r * 5.0 - TIME * 1.4;
	float spiral = 0.5 + 0.5 * sin(theta * 3.0);
	ALBEDO = mix(mire_dark.rgb, mire_light.rgb, spiral);
	ROUGHNESS = 0.90;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_shader_cache["quicksand_vortex"] = mat
	return mat

static func get_quicksand_bubble_shader() -> ShaderMaterial:
	if _shader_cache.has("quicksand_bubble"):
		return _shader_cache["quicksand_bubble"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 bubble_color : source_color = vec4(0.42, 0.30, 0.16, 1.0);

void vertex() {
	vec3 world_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float phase = TIME * 3.5 + (world_origin.x * 1.7 + world_origin.z * 2.3);
	float pulse = 0.65 + abs(sin(phase)) * 0.65;
	VERTEX *= pulse;
	VERTEX.y += abs(sin(phase)) * 0.09;
}

void fragment() {
	ALBEDO = bubble_color.rgb;
	ROUGHNESS = 0.88;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_shader_cache["quicksand_bubble"] = mat
	return mat

static func get_volcanic_molten_shader() -> ShaderMaterial:
	if _shader_cache.has("volcanic_molten"):
		return _shader_cache["volcanic_molten"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 core_color : source_color = vec4(1.0, 0.36, 0.06, 1.0);
uniform float base_energy = 3.5;

void fragment() {
	float pulse = base_energy + sin(TIME * 4.5 + UV.x * 6.28) * 1.1;
	ALBEDO = core_color.rgb;
	EMISSION = core_color.rgb * pulse;
	ROUGHNESS = 0.45;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_shader_cache["volcanic_molten"] = mat
	return mat

static func get_volcanic_flame_shader() -> ShaderMaterial:
	if _shader_cache.has("volcanic_flame"):
		return _shader_cache["volcanic_flame"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 flame_color : source_color = vec4(1.0, 0.58, 0.12, 0.86);

void vertex() {
	float wave = sin(TIME * 18.0 + VERTEX.y * 2.8) * 0.12;
	float scale_xz = 1.0 + wave;
	VERTEX.x *= scale_xz;
	VERTEX.z *= scale_xz;
	VERTEX.y *= 1.0 + sin(TIME * 14.0) * 0.08;
}

void fragment() {
	float glow = 1.35 + sin(TIME * 20.0 + UV.y * 8.0) * 0.35;
	ALBEDO = flame_color.rgb * glow;
	ALPHA = flame_color.a;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_shader_cache["volcanic_flame"] = mat
	return mat

static func get_space_asteroid_shader() -> ShaderMaterial:
	if _shader_cache.has("space_asteroid"):
		return _shader_cache["space_asteroid"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 regolith_color : source_color = vec4(0.18, 0.20, 0.25, 1.0);

void vertex() {
	vec3 w_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float phase = w_pos.x * 0.37 + w_pos.z * 0.53;
	float ang = TIME * 0.28 + phase;
	float c = cos(ang);
	float s = sin(ang);
	vec2 rxz = vec2(VERTEX.x * c - VERTEX.z * s, VERTEX.x * s + VERTEX.z * c);
	VERTEX.x = rxz.x;
	VERTEX.z = rxz.y;
	VERTEX.y += sin(TIME * 1.1 + phase) * 0.35;
}

void fragment() {
	ALBEDO = regolith_color.rgb;
	ROUGHNESS = 0.90;
	METALLIC = 0.20;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_shader_cache["space_asteroid"] = mat
	return mat

static func get_cached_shader_count() -> int:
	# Ensure all core shaders are compiled and cached
	get_quicksand_vortex_shader()
	get_quicksand_bubble_shader()
	get_volcanic_molten_shader()
	get_volcanic_flame_shader()
	get_space_asteroid_shader()
	return _shader_cache.size()

static func clear_caches() -> void:
	_shader_cache.clear()
	_spatial_grid.clear()
	if _rd != null:
		if _compute_pipeline_rid.is_valid():
			_rd.free_rid(_compute_pipeline_rid)
			_compute_pipeline_rid = RID()
		if _compute_shader_rid.is_valid():
			_rd.free_rid(_compute_shader_rid)
			_compute_shader_rid = RID()
		_rd.free()
		_rd = null
	_rd_supported = false
	_rd_checked = false

# -----------------------------------------------------------------------------
# 2. HARDWARE 3D LOD & GPU VISIBILITY RANGE CULLING
# -----------------------------------------------------------------------------
static func apply_gpu_lod_and_culling(root: Node, max_dist: float = 220.0) -> Dictionary:
	var stats := {
		"configured_nodes": 0,
		"multimesh_batches": 0,
		"shadow_culled": 0
	}
	if root == null or not is_instance_valid(root):
		return stats
	_apply_lod_recursive(root, max_dist, stats)
	return stats

static func _apply_lod_recursive(node: Node, max_dist: float, stats: Dictionary) -> void:
	if node is GeometryInstance3D:
		var geom := node as GeometryInstance3D
		geom.gi_mode = GeometryInstance3D.GI_MODE_STATIC
		var nm := geom.name
		var is_ground_or_path := (nm == "MeshInstance3D" and geom.get_parent() and geom.get_parent().name == "Ground") or nm.begins_with("Path")
		if not is_ground_or_path:
			geom.visibility_range_end = max_dist
			geom.visibility_range_end_margin = 18.0
			geom.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			geom.lod_bias = 1.25

		if geom is MultiMeshInstance3D:
			stats["multimesh_batches"] = int(stats["multimesh_batches"]) + 1
			# Disable shadow casting on flat ground decals / tiny facial detail batches
			if "Eyes" in nm or "Noses" in nm or "Mouths" in nm or "ColoredLines" in nm or "FacePlates" in nm or "Coconuts" in nm or "Vines" in nm:
				geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				stats["shadow_culled"] = int(stats["shadow_culled"]) + 1
		elif geom is MeshInstance3D:
			var mi := geom as MeshInstance3D
			if mi.mesh:
				var aabb := mi.mesh.get_aabb()
				var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
				if max_dim < 0.85 and not is_ground_or_path:
					mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					mi.visibility_range_end = max_dist * 0.65
					stats["shadow_culled"] = int(stats["shadow_culled"]) + 1

		stats["configured_nodes"] = int(stats["configured_nodes"]) + 1

	for child in node.get_children():
		# Do not mark dynamic combat units or neutral creatures as static GI
		if child is CharacterBody3D:
			continue
		_apply_lod_recursive(child, max_dist, stats)

# -----------------------------------------------------------------------------
# 3. O(1) 2D SPATIAL HASH GRID FOR FAST UNIT SEPARATION & PROXIMITY QUERIES
# -----------------------------------------------------------------------------
static func rebuild_spatial_grid(units: Array, cell_size: float = 4.0) -> void:
	_spatial_cell_size = maxf(1.0, cell_size)
	_spatial_grid.clear()
	for u in units:
		if not is_instance_valid(u) or not (u is Node3D) or u.is_queued_for_deletion():
			continue
		var pos: Vector3 = (u as Node3D).global_position
		var cx: int = int(floor(pos.x / _spatial_cell_size))
		var cz: int = int(floor(pos.z / _spatial_cell_size))
		var key := Vector2i(cx, cz)
		if not _spatial_grid.has(key):
			_spatial_grid[key] = [u]
		else:
			(_spatial_grid[key] as Array).append(u)

static func ensure_spatial_grid_current(tree: SceneTree) -> void:
	if tree == null:
		return
	var frame := Engine.get_physics_frames()
	if frame != _last_grid_frame or _spatial_grid.is_empty():
		_last_grid_frame = frame
		rebuild_spatial_grid(tree.get_nodes_in_group("Units"), 4.0)

static func query_nearby_units(pos: Vector3, radius: float, tree: SceneTree = null) -> Array:
	if tree != null:
		ensure_spatial_grid_current(tree)
	var results: Array = []
	if _spatial_grid.is_empty():
		return results
	var cell_span: int = maxi(1, int(ceil(radius / _spatial_cell_size)))
	var center_cx: int = int(floor(pos.x / _spatial_cell_size))
	var center_cz: int = int(floor(pos.z / _spatial_cell_size))
	var r_sq: float = radius * radius

	for dx in range(-cell_span, cell_span + 1):
		for dz in range(-cell_span, cell_span + 1):
			var key := Vector2i(center_cx + dx, center_cz + dz)
			if _spatial_grid.has(key):
				var bucket: Array = _spatial_grid[key]
				for u in bucket:
					if is_instance_valid(u) and u is Node3D:
						var u_pos: Vector3 = (u as Node3D).global_position
						var dist_sq := (u_pos.x - pos.x) * (u_pos.x - pos.x) + (u_pos.z - pos.z) * (u_pos.z - pos.z)
						if dist_sq <= r_sq:
							results.append(u)
	return results

# -----------------------------------------------------------------------------
# 4. GPU COMPUTE SHADER DISPATCH (WITH SAFE HEADLESS FALLBACK)
# -----------------------------------------------------------------------------
static func _init_compute_device() -> void:
	if _rd_checked:
		return
	_rd_checked = true
	if DisplayServer.get_name() == "headless":
		_rd_supported = false
		return
	_rd = RenderingServer.create_local_rendering_device()
	if _rd == null:
		_rd_supported = false
		return

	var src := RDShaderSource.new()
	src.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	src.source_compute = """#version 450
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict readonly buffer PosBuffer {
	vec4 positions[];
} pos_buf;

layout(set = 0, binding = 1, std430) restrict writeonly buffer OutBuffer {
	int neighbor_counts[];
} out_buf;

layout(push_constant, std430) uniform Params {
	int count;
	float radius_sq;
	float pad0;
	float pad1;
} params;

void main() {
	uint idx = gl_GlobalInvocationID.x;
	if (idx >= uint(params.count)) {
		return;
	}
	vec2 my_xz = pos_buf.positions[idx].xz;
	int neighbors = 0;
	for (int i = 0; i < params.count; i++) {
		if (uint(i) == idx) continue;
		vec2 d = pos_buf.positions[i].xz - my_xz;
		if (dot(d, d) <= params.radius_sq) {
			neighbors++;
		}
	}
	out_buf.neighbor_counts[idx] = neighbors;
}
"""
	var spirv := _rd.shader_compile_spirv_from_source(src)
	if spirv == null or spirv.compile_error_compute != "":
		_rd_supported = false
		return
	_compute_shader_rid = _rd.shader_create_from_spirv(spirv)
	if not _compute_shader_rid.is_valid():
		_rd_supported = false
		return
	_compute_pipeline_rid = _rd.compute_pipeline_create(_compute_shader_rid)
	_rd_supported = _compute_pipeline_rid.is_valid()

static func dispatch_spatial_compute(positions: PackedVector3Array, query_radius: float) -> PackedInt32Array:
	var count := positions.size()
	var result := PackedInt32Array()
	result.resize(count)
	if count == 0:
		return result

	_init_compute_device()
	var r_sq := query_radius * query_radius

	if _rd_supported and _rd != null and count >= 16:
		var pos_floats := PackedFloat32Array()
		pos_floats.resize(count * 4)
		for i in range(count):
			var p := positions[i]
			pos_floats[i * 4 + 0] = p.x
			pos_floats[i * 4 + 1] = p.y
			pos_floats[i * 4 + 2] = p.z
			pos_floats[i * 4 + 3] = 0.0
		var pos_bytes := pos_floats.to_byte_array()
		var out_bytes := PackedByteArray()
		out_bytes.resize(count * 4)

		var pos_buf := _rd.storage_buffer_create(pos_bytes.size(), pos_bytes)
		var out_buf := _rd.storage_buffer_create(out_bytes.size(), out_bytes)

		var u_pos := RDUniform.new()
		u_pos.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		u_pos.binding = 0
		u_pos.add_id(pos_buf)

		var u_out := RDUniform.new()
		u_out.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		u_out.binding = 1
		u_out.add_id(out_buf)

		var u_set := _rd.uniform_set_create([u_pos, u_out], _compute_shader_rid, 0)

		var push := PackedByteArray()
		push.resize(16)
		push.encode_s32(0, count)
		push.encode_float(4, r_sq)
		push.encode_float(8, 0.0)
		push.encode_float(12, 0.0)

		var cl := _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(cl, _compute_pipeline_rid)
		_rd.compute_list_bind_uniform_set(cl, u_set, 0)
		_rd.compute_list_set_push_constant(cl, push, push.size())
		var groups_x := int(ceil(float(count) / 64.0))
		_rd.compute_list_dispatch(cl, groups_x, 1, 1)
		_rd.compute_list_end()

		_rd.submit()
		_rd.sync()

		var read_bytes := _rd.buffer_get_data(out_buf)
		result = read_bytes.to_int32_array()

		_rd.free_rid(u_set)
		_rd.free_rid(pos_buf)
		_rd.free_rid(out_buf)
		return result

	# Fast CPU fallback (used in headless mode or small counts)
	for i in range(count):
		var p_i := positions[i]
		var neighbors := 0
		for j in range(count):
			if i == j:
				continue
			var p_j := positions[j]
			var dx := p_j.x - p_i.x
			var dz := p_j.z - p_i.z
			if (dx * dx + dz * dz) <= r_sq:
				neighbors += 1
		result[i] = neighbors
	return result

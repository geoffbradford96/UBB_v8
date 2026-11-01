class_name EnvironmentPreRenderer
extends RefCounted

# =============================================================================
# UBB v8 ENVIRONMENT PRE-RENDERER & STATIC BAKER
# Pre-renders and bakes static biome environments when entering a match so
# scenery does not consume ongoing per-frame CPU or redundant GPU power.
# =============================================================================

const GpuAcceleratorScript = preload("res://Scripts/GpuAccelerator.gd")
const WildlifeModelBuilderScript = preload("res://Scripts/WildlifeModelBuilder.gd")

static var _texture_cache: Dictionary = {}

static func clear_caches() -> void:
	_texture_cache.clear()
	GpuAcceleratorScript.clear_caches()
	WildlifeModelBuilderScript.clear_caches()

static func get_cached_biome_texture(biome_name: String) -> ImageTexture:
	var key := biome_name.to_upper()
	if key == "JUNGLE":
		key = "DEEP_JUNGLE"
	if _texture_cache.has(key):
		return _texture_cache[key]

	if key == "VOLCANIC_BRIMSTONE":
		var chk_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for py in range(16):
			for px in range(16):
				var is_orange := (int(float(px) / 4.0) + int(float(py) / 4.0)) % 2 == 0
				if is_orange:
					chk_img.set_pixel(px, py, Color(1.0, 0.48, 0.05))
				else:
					chk_img.set_pixel(px, py, Color(0.14, 0.08, 0.08))
		var chk_tex := ImageTexture.create_from_image(chk_img)
		_texture_cache[key] = chk_tex
		return chk_tex

	elif key == "DEEP_JUNGLE":
		var wood_img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for py in range(32):
			var plank_idx := int(float(py) / 8.0)
			var is_seam := (py % 8 == 0) or (py % 8 == 7)
			for px in range(32):
				if is_seam:
					wood_img.set_pixel(px, py, Color(0.18, 0.10, 0.05))
				else:
					var base_col := Color(0.54, 0.35, 0.18) if plank_idx % 2 == 0 else Color(0.46, 0.28, 0.14)
					var grain := sin(float(px) * 1.2 + float(py) * 0.4) * 0.035
					var is_nail := (px == 3 or px == 28) and (py % 8 == 3 or py % 8 == 4)
					if is_nail:
						wood_img.set_pixel(px, py, Color(0.14, 0.12, 0.10))
					else:
						wood_img.set_pixel(
							px,
							py,
							Color(
								clampf(base_col.r + grain, 0.0, 1.0),
								clampf(base_col.g + grain * 0.8, 0.0, 1.0),
								clampf(base_col.b + grain * 0.6, 0.0, 1.0)
							)
						)
		var wood_tex := ImageTexture.create_from_image(wood_img)
		_texture_cache[key] = wood_tex
		return wood_tex

	elif key == "HAUNTED_HALLOW" or key == "HALLOWEEN":
		var stone_img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for py in range(32):
			for px in range(32):
				# Cobblestone tile grid with irregular broken edges
				var tile_x := px % 8
				var tile_y := py % 8
				var is_crack := (tile_x == 0 or tile_y == 0 or (tile_x + tile_y == 7 and (px + py) % 4 == 0))
				if is_crack:
					# Eerie glowing pumpkin / necrotic fissure in cracks
					var is_glow := ((px * 3 + py * 7) % 11 == 0)
					if is_glow:
						stone_img.set_pixel(px, py, Color(0.95, 0.45, 0.08)) # Orange soul ember
					else:
						stone_img.set_pixel(px, py, Color(0.12, 0.10, 0.14)) # Deep shadow crevice
				else:
					# Weathered decrepit stone with moss patches
					var is_moss := ((px * 5 + py * 9) % 7 == 0)
					if is_moss:
						stone_img.set_pixel(px, py, Color(0.24, 0.36, 0.18)) # Graveyard moss
					else:
						var noise_val := sin(float(px) * 0.8 + float(py) * 1.2) * 0.04
						var stone_col := Color(0.32 + noise_val, 0.30 + noise_val, 0.34 + noise_val)
						stone_img.set_pixel(px, py, stone_col)
		var stone_tex := ImageTexture.create_from_image(stone_img)
		_texture_cache[key] = stone_tex
		return stone_tex

	return null

static func pre_render_and_bake_environment(arena: Node3D, env_root: Node3D, biome_name: String) -> Dictionary:
	var stats := {
		"biome": biome_name,
		"frozen_static_nodes": 0,
		"configured_lod_nodes": 0,
		"multimesh_batches": 0,
		"shadow_culled": 0,
		"compiled_gpu_shaders": 0,
		"baked_probe_active": false
	}
	if arena == null or not is_instance_valid(arena):
		return stats

	# 1. Warm up and cache all GPU shaders & procedural biome textures in VRAM
	get_cached_biome_texture("VOLCANIC_BRIMSTONE")
	get_cached_biome_texture("DEEP_JUNGLE")
	get_cached_biome_texture("HAUNTED_HALLOW")
	stats["compiled_gpu_shaders"] = GpuAcceleratorScript.get_cached_shader_count()

	# 2. Apply Hardware 3D LOD & GPU distance culling to Ground and EnvironmentFeatures
	var ground := arena.get_node_or_null("Ground")
	if ground:
		var g_stats := GpuAcceleratorScript.apply_gpu_lod_and_culling(ground, 280.0)
		stats["configured_lod_nodes"] = int(stats["configured_lod_nodes"]) + int(g_stats["configured_nodes"])

	if env_root and is_instance_valid(env_root):
		var e_stats := GpuAcceleratorScript.apply_gpu_lod_and_culling(env_root, 220.0)
		stats["configured_lod_nodes"] = int(stats["configured_lod_nodes"]) + int(e_stats["configured_nodes"])
		stats["multimesh_batches"] = int(e_stats["multimesh_batches"])
		stats["shadow_culled"] = int(e_stats["shadow_culled"])

		# 3. Freeze pure static environment props so they consume zero per-frame CPU
		stats["frozen_static_nodes"] = _freeze_static_props_recursive(env_root)

		# 4. Create UPDATE_ONCE Baked Environment Reflection Probe so ambient/specular
		# environment lighting is rendered once when entering the match and cached on GPU
		var probe := env_root.get_node_or_null("BakedEnvironmentProbe") as ReflectionProbe
		if probe == null:
			probe = ReflectionProbe.new()
			probe.name = "BakedEnvironmentProbe"
			probe.update_mode = ReflectionProbe.UPDATE_ONCE
			probe.size = Vector3(320.0, 95.0, 320.0)
			probe.position = Vector3(0.0, 18.0, 0.0)
			probe.max_distance = 250.0
			probe.intensity = 0.55
			probe.ambient_mode = ReflectionProbe.AMBIENT_ENVIRONMENT
			probe.set_process(false)
			probe.set_physics_process(false)
			env_root.add_child(probe)
		stats["baked_probe_active"] = true

		# 5. Create GPU Shader Warmup Quad inside StaticEnvironmentBakeCache (renders once at tiny scale)
		var bake_cache := env_root.get_node_or_null("StaticEnvironmentBakeCache") as Node3D
		if bake_cache == null:
			bake_cache = Node3D.new()
			bake_cache.name = "StaticEnvironmentBakeCache"
			bake_cache.position = Vector3(0.0, -35.0, 0.0)
			bake_cache.set_process(false)
			bake_cache.set_physics_process(false)
			env_root.add_child(bake_cache)

			var warmup_shaders: Array[ShaderMaterial] = [
				GpuAcceleratorScript.get_quicksand_vortex_shader(),
				GpuAcceleratorScript.get_quicksand_bubble_shader(),
				GpuAcceleratorScript.get_volcanic_molten_shader(),
				GpuAcceleratorScript.get_volcanic_flame_shader(),
				GpuAcceleratorScript.get_space_asteroid_shader()
			]
			var q_mesh := QuadMesh.new()
			q_mesh.size = Vector2(0.05, 0.05)
			for s_i in range(warmup_shaders.size()):
				var mi := MeshInstance3D.new()
				mi.name = "WarmupShaderQuad_%d" % s_i
				mi.mesh = q_mesh
				mi.material_override = warmup_shaders[s_i]
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mi.set_process(false)
				mi.set_physics_process(false)
				bake_cache.add_child(mi)

	arena.set_meta("environment_pre_rendered", true)
	arena.set_meta("pre_render_stats", stats)
	return stats

static func _freeze_static_props_recursive(node: Node) -> int:
	var count := 0
	# Do not freeze interactive hazards, combat units, or neutral spawner timers
	if node is CharacterBody3D or node is Area3D or node is Timer:
		return 0
	if node.get_script() == null and (node is MeshInstance3D or node is MultiMeshInstance3D or node is StaticBody3D or node is CollisionShape3D):
		node.set_process(false)
		node.set_physics_process(false)
		node.set_process_input(false)
		node.set_process_unhandled_input(false)
		count += 1

	for child in node.get_children():
		count += _freeze_static_props_recursive(child)
	return count

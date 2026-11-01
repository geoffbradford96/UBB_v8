extends Node
class_name GildedMitosisComponent

const HarmonyHuskBuilderScript = preload("res://Scripts/HarmonyHuskBuilder.gd")

@export var split_generation: int = 0 # 0 -> 1 -> 2 (splits 2 times!)
@export var max_splits: int = 2
@export var regen_per_second: float = 5.5
@export var divide_full_hp_seconds: float = 11.0
var full_hp_divide_duration: float = 11.0:
	set(v):
		full_hp_divide_duration = v
		divide_full_hp_seconds = v
	get:
		return divide_full_hp_seconds

var full_hp_timer: float = 0.0
var has_split_on_death: bool = false
var source_scene_path: String = ""

func _ready() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return

	if source_scene_path == "" and parent.scene_file_path != "":
		source_scene_path = parent.scene_file_path

	var hc := parent.get_node_or_null("HealthComponent")
	if hc and not hc.died.is_connected(_on_parent_died):
		hc.died.connect(_on_parent_died)

func _process(delta: float) -> void:
	var parent := get_parent() as Node3D
	if parent == null or not is_instance_valid(parent):
		return
	var hc := parent.get_node_or_null("HealthComponent")
	if hc == null or hc.is_dead:
		return

	# 1. Slow HP Regeneration
	if hc.current_health > 0.0 and hc.current_health < hc.max_health:
		hc.current_health = minf(hc.max_health, hc.current_health + regen_per_second * delta)
		if hc.has_method("_refresh_hp_visuals"):
			hc._refresh_hp_visuals()
		full_hp_timer = 0.0
	elif hc.current_health >= hc.max_health:
		# 2. If at full HP for too long, divide (mitosis) making a second copy of itself!
		full_hp_timer += delta
		if full_hp_timer >= divide_full_hp_seconds:
			full_hp_timer = 0.0
			_perform_mitosis_division(parent)

func _get_parent_team(parent: Node) -> String:
	for g in parent.get_groups():
		if g.begins_with("Side"):
			return g
	if "team" in parent and str(parent.get("team")).begins_with("Side"):
		return str(parent.get("team"))
	return "SideA"

func _perform_mitosis_division(parent: Node3D) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	var team: String = _get_parent_team(parent)
	# Cap active team units so mitosis never lags the game
	if not parent.get_tree() or parent.get_tree().get_nodes_in_group(team).size() > 55:
		return
	var offset := Vector3(randf_range(-1.8, 1.8), 0.0, randf_range(-1.8, 1.8))
	if offset.length_squared() < 0.25:
		offset = Vector3(1.4, 0.0, 0.0)
	_spawn_clone(parent, split_generation, parent.global_position + offset, "_Mitosis_Gen" + str(split_generation))

func _on_parent_died() -> void:
	if has_split_on_death:
		return
	has_split_on_death = true
	if split_generation >= max_splits:
		return
	var parent := get_parent() as Node3D
	if parent == null or not is_instance_valid(parent):
		return

	var next_gen: int = split_generation + 1
	var base_pos: Vector3 = parent.global_position if parent.is_inside_tree() else parent.position
	# Split into 2 smaller, weaker copies immediately before parent.queue_free() runs!
	for i in range(2):
		var side_sign: float = -1.0 if i == 0 else 1.0
		var spawn_pos: Vector3 = base_pos + Vector3(side_sign * 1.35, 0.1, randf_range(-0.8, 0.8))
		_spawn_clone(parent, next_gen, spawn_pos, "_Split" + str(next_gen) + "_Gen" + str(next_gen) + "_" + str(i))

func _spawn_clone(template_unit: Node3D, target_gen: int, world_pos: Vector3, tag_suffix: String = "") -> Node3D:
	if not is_instance_valid(template_unit):
		return null
	var tree: SceneTree = null
	if template_unit.is_inside_tree():
		tree = template_unit.get_tree()
	elif is_inside_tree():
		tree = get_tree()
	if tree == null:
		return null
	var scene_root: Node = null
	if tree.current_scene:
		scene_root = tree.current_scene
	else:
		scene_root = template_unit.get_parent()
	if scene_root == null:
		return null

	var team: String = _get_parent_team(template_unit)
	var clone: Node3D = null

	if template_unit.get_script() != null and "monster_role" in template_unit:
		var monster_script: Script = template_unit.get_script()
		clone = monster_script.new()
		clone.set("monster_role", template_unit.get("monster_role"))
		clone.set("split_generation", target_gen)
		clone.set("team", team)
	elif source_scene_path != "" and ResourceLoader.exists(source_scene_path):
		var packed: PackedScene = load(source_scene_path)
		if packed:
			clone = packed.instantiate()

	if clone == null:
		return null

	var base_prefix: String = template_unit.name.split("_Split")[0].split("_Mitosis")[0].split("_Gen")[0]
	var suffix: String = tag_suffix if tag_suffix != "" else ("_Gen" + str(target_gen))
	clone.name = base_prefix + suffix + "_" + str(Time.get_ticks_usec() % 100000)
	clone.add_to_group(team)
	clone.add_to_group("GildedHarmony")
	scene_root.add_child(clone)
	clone.global_position = world_pos

	# Apply generation scaling (smaller and weaker each split: Gen 1 = 0.68x scale / 0.55x stats, Gen 2 = 0.46x scale / 0.30x stats)
	var gen_scale: float = pow(0.68, float(target_gen))
	var stat_mult: float = pow(0.55, float(target_gen))
	clone.set_meta("gilded_gen_scale", gen_scale)

	if "monster_role" in clone and clone.has_method("configure_monster"):
		clone.call("configure_monster", clone.get("monster_role"), target_gen, team)
	else:
		clone.scale = Vector3.ONE * gen_scale
		HarmonyHuskBuilderScript.transform_into_husk(clone, true, team)
		var hc := clone.get_node_or_null("HealthComponent")
		if hc:
			var base_hp: float = float(clone.get_meta("base_gilded_hp", hc.max_health))
			clone.set_meta("base_gilded_hp", base_hp)
			var new_max: float = maxf(18.0, base_hp * stat_mult)
			hc.max_health = new_max
			hc.current_health = new_max
			if hc.has_method("_refresh_hp_visuals"):
				hc._refresh_hp_visuals()
		if "attack_damage" in clone:
			var base_dmg: float = float(clone.get_meta("base_gilded_dmg", clone.get("attack_damage")))
			clone.set_meta("base_gilded_dmg", base_dmg)
			clone.set("attack_damage", maxf(4.0, base_dmg * stat_mult))
		elif "damage" in clone:
			var base_tdmg: float = float(clone.get_meta("base_gilded_dmg", clone.get("damage")))
			clone.set_meta("base_gilded_dmg", base_tdmg)
			clone.set("damage", maxf(4.0, base_tdmg * stat_mult))

		var comp = clone.get_node_or_null("GildedMitosisComponent")
		if comp == null:
			comp = load("res://Scripts/GildedMitosisComponent.gd").new()
			comp.name = "GildedMitosisComponent"
			clone.add_child(comp)
		comp.split_generation = target_gen
		comp.source_scene_path = source_scene_path

	return clone

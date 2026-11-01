extends Area3D

@export var damage: float = 100.0
var friendly_group: String = ""
var _detonated: bool = false

func _ready():
	for g in get_groups():
		if g.begins_with("Side"): friendly_group = g
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if _detonated: return
	if body.get("unit_attribute") == "Ethereal": return
	if friendly_group == "":
		for g in get_groups():
			if g.begins_with("Side"): friendly_group = g
	if friendly_group != "" and body.is_in_group(friendly_group):
		return # Do not trigger on allies!
	if body.is_in_group("Targetable"):
		var hp = body.get_node_or_null("HealthComponent")
		if hp:
			_detonated = true
			hp.take_damage(damage, global_position)
			queue_free()

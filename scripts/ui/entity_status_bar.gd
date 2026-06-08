class_name EntityStatusBar
extends Control

## EntityStatusBar
## Displays HP via a ProgressBar and AP via dynamic ColorRect pips.

var _lerp_speed: float = 10.0
var _target_hp: float = 0.0

@onready var hp_bar: ProgressBar = %HPBar
@onready var ap_container: HBoxContainer = %APContainer


func _ready() -> void:
	_load_config()


func _load_config() -> void:
	var loader: _ConfigLoader = AutoloadHelper.config_loader()
	if loader:
		var feedback: Dictionary = loader.getValue("health_bar", "", {})
		if feedback:
			_lerp_speed = feedback.get("lerp_speed", 10.0)


func _process(delta: float) -> void:
	if abs(hp_bar.value - _target_hp) > 0.1:
		hp_bar.value = lerpf(hp_bar.value, _target_hp, _lerp_speed * delta)
	else:
		hp_bar.value = _target_hp


func updateHp(current: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	_target_hp = float(current)


func updateAp(current: int, max_ap: int) -> void:
	# Update or add pips
	var current_child_count: int = ap_container.get_child_count()

	if max_ap > current_child_count:
		for i: int in range(max_ap - current_child_count):
			var pip: ColorRect = ColorRect.new()
			pip.custom_minimum_size = Vector2(4, 8)
			ap_container.add_child(pip)
	elif max_ap < current_child_count:
		for i: int in range(current_child_count - 1, max_ap - 1, -1):
			var child: Node = ap_container.get_child(i)
			ap_container.remove_child(child)
			child.queue_free()

	# Re-color based on current AP
	for i: int in range(max_ap):
		var pip: ColorRect = ap_container.get_child(i) as ColorRect
		if pip:
			pip.color = Color.YELLOW if i < current else Color(0.2, 0.2, 0.2)

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
	if DeterministicMath.absf(hp_bar.value - _target_hp) > 0.1:
		hp_bar.value = lerpf(hp_bar.value, _target_hp, _lerp_speed * delta)
	else:
		hp_bar.value = _target_hp


func updateHp(current: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	_target_hp = float(current)


## Backward-compatible snake_case alias for updateHp
func update_hp(p_current_hp: int, p_max_hp: int) -> void:
	updateHp(p_current_hp, p_max_hp)


## Update AP pips to show current AP out of max
func updateAp(current: int, max_ap: int) -> void:
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

	for i: int in range(max_ap):
		var pip: ColorRect = ap_container.get_child(i) as ColorRect
		if pip:
			pip.color = Color.YELLOW if i < current else Color(0.2, 0.2, 0.2)


## Backward-compatible snake_case alias for updateAp (ignores extra arg)
func update_ap(p_current_ap: int, _p_max_ap: int = 0) -> void:
	var ap_max: int = _get_ap_max()
	updateAp(p_current_ap, ap_max)


func _get_ap_max() -> int:
	var config: _ConfigLoader = AutoloadHelper.config_loader()
	return (
		config.getValue("ap_bar", "segment_count", GameConstants.AP_MAX)
		if config
		else GameConstants.AP_MAX
	)

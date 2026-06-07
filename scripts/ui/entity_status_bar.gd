class_name EntityStatusBar
extends Control

## EntityStatusBar
## Displays HP via a ProgressBar and AP via dynamic ColorRect pips.

@onready var hpBar: ProgressBar = %HPBar
@onready var apContainer: HBoxContainer = %APContainer

var _pip_scene: PackedScene
var _lerp_speed: float = 10.0
var _target_hp: float = 0.0


func _ready() -> void:
	_load_config()
	_setup_ap_pips()


func _load_config() -> void:
	var loader: _ConfigLoader = AutoloadHelper.config_loader()
	if loader:
		var feedback: Dictionary = loader.getValue("health_bar", "", {})
		if feedback:
			_lerp_speed = feedback.get("lerp_speed", 10.0)


func _process(delta: float) -> void:
	if abs(hpBar.value - _target_hp) > 0.1:
		hpBar.value = lerpf(hpBar.value, _target_hp, _lerp_speed * delta)
	else:
		hpBar.value = _target_hp


func updateHp(current: int, max_hp: int) -> void:
	hpBar.max_value = max_hp
	_target_hp = float(current)


func updateAp(current: int, max_ap: int) -> void:
	# Clear existing
	for child in apContainer.get_children():
		child.queue_free()

	for i in range(max_ap):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(4, 8)
		pip.color = Color.YELLOW if i < current else Color(0.2, 0.2, 0.2)
		apContainer.add_child(pip)


func _setup_ap_pips() -> void:
	# Initial setup if needed
	pass

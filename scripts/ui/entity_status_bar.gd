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


## Update HP bar
func update_hp(p_current: int, p_max_hp: int) -> void:
	hp_bar.max_value = p_max_hp
	_target_hp = float(p_current)


## Deprecated: Use update_hp
func updateHp(p_current: int, p_max_hp: int) -> void:
	update_hp(p_current, p_max_hp)


## Update AP pips to show current AP out of max
func update_ap(p_current: int, p_max_ap: int = -1) -> void:
	var actual_max_ap: int = p_max_ap
	if actual_max_ap < 0:
		actual_max_ap = _get_ap_max()

	var current_child_count: int = ap_container.get_child_count()

	if actual_max_ap > current_child_count:
		for i: int in range(actual_max_ap - current_child_count):
			var pip: TextureRect = TextureRect.new()
			pip.custom_minimum_size = Vector2(12, 12)
			pip.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			ap_container.add_child(pip)
	elif actual_max_ap < current_child_count:
		for i: int in range(current_child_count - 1, actual_max_ap - 1, -1):
			var child: Node = ap_container.get_child(i)
			ap_container.remove_child(child)
			child.queue_free()

	var tex_full: Texture2D = load("res://assets/sprites/ap_gem.png") as Texture2D
	var tex_empty: Texture2D = load("res://assets/sprites/ap_gem_empty.png") as Texture2D

	for i: int in range(actual_max_ap):
		var pip: TextureRect = ap_container.get_child(i) as TextureRect
		if pip:
			pip.texture = tex_full if i < p_current else tex_empty


## Deprecated: Use update_ap
func updateAp(p_current: int, p_max_ap: int) -> void:
	update_ap(p_current, p_max_ap)


func _get_ap_max() -> int:
	var config: _ConfigLoader = AutoloadHelper.config_loader()
	return (
		config.getValue("ap_bar", "segment_count", GameConstants.AP_MAX)
		if config
		else GameConstants.AP_MAX
	)

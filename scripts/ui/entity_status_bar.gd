class_name EntityStatusBar
extends Control

## EntityStatusBar
## Displays HP via a ProgressBar and AP via dynamic Panel pips.

var _lerp_speed: float = 10.0
var _ghost_lerp_speed: float = 2.0
var _target_hp: float = 0.0
var _actual_hp: float = 0.0
var _offset: Vector2 = Vector2(-50, -60)  # Centered offset (width is 100)

@onready var hp_bar: ProgressBar = %HPBar
@onready var ghost_bar: ProgressBar = %GhostBar
@onready var ap_container: HBoxContainer = %APContainer


func _ready() -> void:
	top_level = true
	_load_config()
	if hp_bar:
		_target_hp = hp_bar.value
		_actual_hp = hp_bar.value


func _load_config() -> void:
	var loader: _ConfigLoader = AutoloadHelper.config_loader()
	if loader:
		var feedback: Dictionary = loader.getValue("health_bar", "", {})
		if feedback:
			_lerp_speed = feedback.get("lerp_speed", 10.0)
			_ghost_lerp_speed = feedback.get("ghost_lerp_speed", 2.0)


func _process(delta: float) -> void:
	_update_position()
	_update_bars(delta)
	_sync_modulate()


func _update_position() -> void:
	var parent := get_parent()
	if parent is Node2D:
		global_position = parent.global_position + _offset


func _sync_modulate() -> void:
	var parent := get_parent()
	if parent is CanvasItem:
		modulate.a = parent.modulate.a


func _update_bars(delta: float) -> void:
	# Lerp main HP bar
	if hp_bar and DeterministicMath.absf(hp_bar.value - _target_hp) > 0.01:
		hp_bar.value = lerpf(hp_bar.value, _target_hp, _lerp_speed * delta)
	else:
		hp_bar.value = _target_hp

	# Lerp ghost bar (slower catch-up)
	if ghost_bar and DeterministicMath.absf(ghost_bar.value - _target_hp) > 0.01:
		ghost_bar.value = lerpf(ghost_bar.value, _target_hp, _ghost_lerp_speed * delta)
	else:
		ghost_bar.value = _target_hp


func updateHp(current: int, max_hp: int) -> void:
	_actual_hp = float(current)
	hp_bar.max_value = max_hp
	ghost_bar.max_value = max_hp
	_target_hp = _actual_hp


## Deprecated: Use update_hp
func updateHp(p_current: int, p_max_hp: int) -> void:
	update_hp(p_current, p_max_hp)


## Update AP pips to show current AP out of max
func update_ap(p_current: int, p_max_ap: int = -1) -> void:
	var actual_max_ap: int = p_max_ap
	if actual_max_ap < 0:
		actual_max_ap = _get_ap_max()

	var current_child_count: int = ap_container.get_child_count()

	if max_ap > current_child_count:
		for i: int in range(max_ap - current_child_count):
			var pip: Panel = Panel.new()
			pip.custom_minimum_size = Vector2(8, 8)
			pip.theme_type_variation = &"APOff"
			ap_container.add_child(pip)
	elif actual_max_ap < current_child_count:
		for i: int in range(current_child_count - 1, actual_max_ap - 1, -1):
			var child: Node = ap_container.get_child(i)
			ap_container.remove_child(child)
			child.queue_free()

	for i: int in range(max_ap):
		var pip: Panel = ap_container.get_child(i) as Panel
		if pip:
			pip.theme_type_variation = "APOn" if i < current else "APOff"


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


func flash() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func set_preview_damage(amount: int) -> void:
	_target_hp = _actual_hp - amount
	hp_bar.value = _target_hp
	# Note: ghost_bar will naturally lerp towards _target_hp,
	# showing the 'damage' area in red until it catches up.

class_name EntityStatusBar
extends Control

## EntityStatusBar
## Displays HP via a ProgressBar and AP via dynamic ColorRect pips.

@onready var hpBar: ProgressBar = %HPBar
@onready var apContainer: HBoxContainer = %APContainer

var _lerp_speed: float = 10.0
var _target_hp: float = 0.0


func _ready() -> void:
	_load_config()


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
	# Update or add pips
	var current_child_count: int = apContainer.get_child_count()

	if max_ap > current_child_count:
		for i in range(max_ap - current_child_count):
			var pip: ColorRect = ColorRect.new()
			pip.custom_minimum_size = Vector2(4, 8)
			apContainer.add_child(pip)
	elif max_ap < current_child_count:
		for i in range(current_child_count - 1, max_ap - 1, -1):
			var child: Node = apContainer.get_child(i)
			child.queue_free()

	# Re-color based on current AP
	for i in range(max_ap):
		if i < apContainer.get_child_count():
			var pip: ColorRect = apContainer.get_child(i) as ColorRect
			if pip:
				pip.color = Color.YELLOW if i < current else Color(0.2, 0.2, 0.2)
## EntityStatusBar (DON-186)
## Displays HP bar and AP pips in world space above entities.

var _entity: Entity

@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var ap_container: HBoxContainer = $VBoxContainer/APContainer


func setup(p_entity: Entity) -> void:
	_entity = p_entity
	if _entity:
		_entity.hp_changed.connect(_on_hp_changed)
		_entity.ap_changed.connect(_on_ap_changed)
		update_visuals()


func update_visuals() -> void:
	if not _entity:
		return

	update_hp(_entity.hp, _entity.hp_max)
	update_ap(_entity.ap)


func update_hp(p_current_hp: int, p_max_hp: int) -> void:
	hp_bar.max_value = p_max_hp
	hp_bar.value = p_current_hp


func update_ap(p_current_ap: int) -> void:
	var ap_max: int = _get_ap_max()
	_ensure_pips(ap_max)

	for i: int in range(ap_max):
		var pip: ColorRect = ap_container.get_child(i) as ColorRect
		if i < p_current_ap:
			pip.color = Color.YELLOW
		else:
			pip.color = Color(0.3, 0.3, 0.1, 0.5)


func _get_ap_max() -> int:
	var config: _ConfigLoader = AutoloadHelper.config_loader()
	return (
		config.getValue("ap_bar", "segment_count", GameConstants.AP_MAX)
		if config
		else GameConstants.AP_MAX
	)


func _ensure_pips(p_count: int) -> void:
	if ap_container.get_child_count() == p_count:
		return

	# Clear mismatching count
	for child: Node in ap_container.get_children():
		child.queue_free()

	for i: int in range(p_count):
		var pip: ColorRect = ColorRect.new()
		pip.custom_minimum_size = Vector2(8, 8)
		ap_container.add_child(pip)


func _on_hp_changed(p_new_hp: int, _old_hp: int) -> void:
	update_hp(p_new_hp, _entity.hp_max)


func _on_ap_changed(p_new_ap: int, _old_ap: int) -> void:
	update_ap(p_new_ap)

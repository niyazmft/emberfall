class_name EntityStatusBar
extends Control
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


## Backward-compatible camelCase alias for update_hp
func updateHp(p_current_hp: int, p_max_hp: int) -> void:
	update_hp(p_current_hp, p_max_hp)


func update_hp(p_current_hp: int, p_max_hp: int) -> void:
	hp_bar.max_value = p_max_hp
	hp_bar.value = p_current_hp


## Backward-compatible camelCase alias for update_ap (accepts 1 or 2 args)
func updateAp(p_current_ap: int, _p_max_ap: int = 0) -> void:
	update_ap(p_current_ap)


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

class_name EntityStatusBar
extends Control
## EntityStatusBar (DON-186)
## Displays HP bar and AP pips in world space above entities.

var _entity: Entity

@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var ap_container: HBoxContainer = $VBoxContainer/APContainer


func setup(entity: Entity) -> void:
	_entity = entity
	if _entity:
		_entity.hp_changed.connect(_on_hp_changed)
		_entity.ap_changed.connect(_on_ap_changed)
		update_visuals()


func update_visuals() -> void:
	if not _entity:
		return

	update_hp(_entity.hp, _entity.hp_max)
	update_ap(_entity.ap)


func update_hp(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp


func update_ap(current_ap: int) -> void:
	# Clear existing pips
	for child in ap_container.get_children():
		child.queue_free()

	var config: Node = AutoloadHelper.config_loader()
	var ap_max: int = (
		config.getValue("ap_bar", "segment_count", GameConstants.AP_MAX)
		if config
		else GameConstants.AP_MAX
	)

	for i in range(ap_max):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(8, 8)
		if i < current_ap:
			pip.color = Color.YELLOW
		else:
			pip.color = Color(0.3, 0.3, 0.1, 0.5)
		ap_container.add_child(pip)


func _on_hp_changed(new_hp: int, _old_hp: int) -> void:
	update_hp(new_hp, _entity.hp_max)


func _on_ap_changed(new_ap: int, _old_ap: int) -> void:
	update_ap(new_ap)

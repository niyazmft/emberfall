class_name EntityStatusBar
extends Control

## EntityStatusBar
## Displays HP bar and AP pips above entities in world space.

@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var ap_container: HBoxContainer = $VBoxContainer/APContainer

var _entity: Entity


func setup(p_entity: Entity) -> void:
	_entity = p_entity
	update_hp()
	update_ap()


func update_hp() -> void:
	if not _entity or not hp_bar:
		return
	hp_bar.max_value = _entity.hp_max
	hp_bar.value = _entity.hp


func update_ap() -> void:
	if not _entity or not ap_container:
		return

	# Clear existing pips
	for child: Node in ap_container.get_children():
		ap_container.remove_child(child)
		child.queue_free()

	# Create new pips
	var maxAp: int = GameConstants.AP_MAX
	var currentAp: int = _entity.ap

	for i: int in range(maxAp):
		var pip: ColorRect = ColorRect.new()
		pip.custom_minimum_size = Vector2(4, 4)
		pip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if i < currentAp:
			pip.color = Color.CYAN
		else:
			pip.color = Color(0.2, 0.2, 0.2, 0.5)
		ap_container.add_child(pip)

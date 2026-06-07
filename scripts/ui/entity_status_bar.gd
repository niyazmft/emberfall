class_name EntityStatusBar
extends Control

## EntityStatusBar
## Displays HP bar and AP pips above entities in world space.

@onready var hpBar: ProgressBar = $VBoxContainer/HPBar
@onready var apContainer: HBoxContainer = $VBoxContainer/APContainer

var _entityRef: Entity


func setup(p_entity: Entity) -> void:
	_entityRef = p_entity
	updateHp()
	updateAp()


func updateHp() -> void:
	if not _entityRef or not hpBar:
		return
	hpBar.max_value = _entityRef.hp_max
	hpBar.value = _entityRef.hp


func updateAp() -> void:
	if not _entityRef or not apContainer:
		return

	# Clear existing pips
	for child: Node in apContainer.get_children():
		apContainer.remove_child(child)
		child.queue_free()

	# Create new pips
	var maxAp: int = GameConstants.AP_MAX
	var currentAp: int = _entityRef.ap

	for i: int in range(maxAp):
		var pip: ColorRect = ColorRect.new()
		pip.custom_minimum_size = Vector2(4, 4)
		pip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if i < currentAp:
			pip.color = Color.CYAN
		else:
			pip.color = Color(0.2, 0.2, 0.2, 0.5)
		apContainer.add_child(pip)

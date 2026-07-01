class_name _BottomConsole
extends Control
## Unified bottom console for combat HUD.
## Encapsulates action buttons and burden display
## in a three-zone container. HP and AP are displayed via
## in-world floating bars above entities.

@onready
var move_button: Button = $MarginContainer/HBoxContainer/CenterConsole/ActionButtons/MoveButton
@onready
var attack_button: Button = $MarginContainer/HBoxContainer/CenterConsole/ActionButtons/AttackButton
@onready
var end_turn_button: Button = $MarginContainer/HBoxContainer/CenterConsole/ActionButtons/EndTurnButton
@onready var burden_label: Label = $MarginContainer/HBoxContainer/RightWing/BurdenLabel

var _player_entity: Entity


func setup(player_entity: Entity) -> void:
	_player_entity = player_entity
	var eb := AutoloadHelper.event_bus()
	if eb and not eb.entity_state_changed.is_connected(_on_entity_state_changed):
		eb.entity_state_changed.connect(_on_entity_state_changed)
	_update_burden_label()


func _update_burden_label() -> void:
	if burden_label == null:
		return
	var bm := AutoloadHelper.burden_manager()
	if bm != null:
		burden_label.text = "Burden: %d" % bm.total_sentient_kills
	else:
		burden_label.text = "Burden: --"


func _on_entity_state_changed(entity: Entity, _old: Entity.State, _new: Entity.State) -> void:
	if entity == _player_entity:
		_update_burden_label()


func _exit_tree() -> void:
	var eb := AutoloadHelper.event_bus()
	if eb and eb.entity_state_changed.is_connected(_on_entity_state_changed):
		eb.entity_state_changed.disconnect(_on_entity_state_changed)

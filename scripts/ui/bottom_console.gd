class_name _BottomConsole
extends Control
## Unified bottom console for combat HUD.
## Encapsulates HP/AP bars, action buttons, and burden display
## in a single three-zone container.

@onready var hp_bar: ProgressBar = $MarginContainer/HBoxContainer/LeftWing/HPBar
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
	_update_bars()
	_update_burden_label()


func _update_bars() -> void:
	if _player_entity == null:
		return
	if hp_bar != null:
		hp_bar.max_value = _player_entity.hp_max
		hp_bar.value = _player_entity.hp


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
		_update_bars()
		_update_burden_label()


func _exit_tree() -> void:
	var eb := AutoloadHelper.event_bus()
	if eb and eb.entity_state_changed.is_connected(_on_entity_state_changed):
		eb.entity_state_changed.disconnect(_on_entity_state_changed)

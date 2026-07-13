class_name _BottomConsole
extends Control
## Unified bottom console for combat HUD.
## Encapsulates action buttons and burden display
## in a three-zone container. HP and AP are displayed via
## in-world floating bars above entities.

## FIX #601: Action button accent colors.
const MOVE_ACCENT: Color = Color(0.2, 0.6, 0.95, 1.0)  # Blue
const ATTACK_ACCENT: Color = Color(0.95, 0.35, 0.15, 1.0)  # Red-orange
const END_TURN_ACCENT: Color = Color(0.95, 0.8, 0.15, 1.0)  # Gold

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
	_setup_button_colors()


## FIX #601: Apply accent colors to action buttons.
func _setup_button_colors() -> void:
	if move_button != null:
		move_button.add_theme_color_override("font_color", MOVE_ACCENT)
		move_button.add_theme_color_override("font_pressed_color", MOVE_ACCENT.lightened(0.3))
		move_button.tooltip_text = "Move (WASD / Arrows)"
	if attack_button != null:
		attack_button.add_theme_color_override("font_color", ATTACK_ACCENT)
		attack_button.add_theme_color_override("font_pressed_color", ATTACK_ACCENT.lightened(0.3))
		attack_button.tooltip_text = "Attack (Click target)"
	if end_turn_button != null:
		end_turn_button.add_theme_color_override("font_color", END_TURN_ACCENT)
		end_turn_button.add_theme_color_override(
			"font_pressed_color", END_TURN_ACCENT.lightened(0.3)
		)
		end_turn_button.tooltip_text = "End Turn (Space)"


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

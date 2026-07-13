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
## FIX #600: Desperation Strike accent color (crimson pulse).
const DESPERATION_ACCENT: Color = Color(0.9, 0.1, 0.1, 1.0)  # Deep red

@onready
var move_button: Button = $MarginContainer/HBoxContainer/CenterConsole/ActionButtons/MoveButton
@onready
var attack_button: Button = $MarginContainer/HBoxContainer/CenterConsole/ActionButtons/AttackButton
@onready
var end_turn_button: Button = $MarginContainer/HBoxContainer/CenterConsole/ActionButtons/EndTurnButton
@onready var burden_label: Label = $MarginContainer/HBoxContainer/RightWing/BurdenLabel

## FIX #600: Desperation Strike button (added programmatically).
var desperation_button: Button = null

var _player_entity: Entity
var _desperation_used_this_run: bool = false


func setup(player_entity: Entity) -> void:
	_player_entity = player_entity
	var eb := AutoloadHelper.event_bus()
	if eb and not eb.entity_state_changed.is_connected(_on_entity_state_changed):
		eb.entity_state_changed.connect(_on_entity_state_changed)
	_update_burden_label()
	_setup_button_colors()
	_setup_desperation_button()


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


## FIX #600: Create and wire the Desperation Strike button.
func _setup_desperation_button() -> void:
	if desperation_button != null:
		return
	var action_buttons: HBoxContainer = (
		$MarginContainer/HBoxContainer/CenterConsole/ActionButtons as HBoxContainer
	)
	if action_buttons == null:
		return

	desperation_button = Button.new()
	desperation_button.name = "DesperationButton"
	desperation_button.text = "Desperation"
	desperation_button.custom_minimum_size = Vector2(110, 36)
	desperation_button.visible = false
	desperation_button.add_theme_color_override("font_color", DESPERATION_ACCENT)
	desperation_button.tooltip_text = "Devastating strike — costs all AP"
	action_buttons.add_child(desperation_button)

	if not desperation_button.pressed.is_connected(_on_desperation_pressed):
		desperation_button.pressed.connect(_on_desperation_pressed)


## FIX #600: Update desperation button visibility based on player HP.
func update_desperation_visibility() -> void:
	if desperation_button == null or _player_entity == null:
		return
	if _desperation_used_this_run:
		desperation_button.visible = false
		return

	var hp_pct: float = float(_player_entity.hp) / float(_player_entity.hp_max)
	var should_show: bool = hp_pct <= 0.25 and _player_entity.hp > 0
	desperation_button.visible = should_show


## FIX #600: Called by CombatRoom when desperation is used.
func mark_desperation_used() -> void:
	_desperation_used_this_run = true
	if desperation_button != null:
		desperation_button.visible = false


func _on_desperation_pressed() -> void:
	## Signal emitted for CombatRoom to handle the actual strike.
	desperation_pressed.emit()


## FIX #600: Signal for CombatRoom to handle desperation strike.
signal desperation_pressed


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
		## FIX #600: Re-check desperation visibility on any player state change.
		update_desperation_visibility()


func _exit_tree() -> void:
	var eb := AutoloadHelper.event_bus()
	if eb and eb.entity_state_changed.is_connected(_on_entity_state_changed):
		eb.entity_state_changed.disconnect(_on_entity_state_changed)
	if (
		desperation_button != null
		and desperation_button.pressed.is_connected(_on_desperation_pressed)
	):
		desperation_button.pressed.disconnect(_on_desperation_pressed)

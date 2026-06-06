class_name MoralChoiceUI
extends CanvasLayer

## MoralChoiceUI
## Handles the spare vs execute choice when an enemy reaches the DYING state.

signal choice_made(spared: bool)

@onready var panel: PanelContainer = %ChoicePanel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var spare_button: Button = %SpareButton
@onready var execute_button: Button = %ExecuteButton
@onready var timeout_bar: ProgressBar = %TimeoutBar
@onready var moral_preview: Label = %MoralPreview

var _target_entity: Entity = null
var _timeout: float = 5.0
var _remaining: float = 0.0
var _choice_queue: Array[Entity] = []
var _is_showing: bool = false


func _ready() -> void:
	panel.visible = false
	var lifecycle: Node = AutoloadHelper.entity_lifecycle()
	if lifecycle and lifecycle.has_signal("entity_state_changed"):
		lifecycle.connect("entity_state_changed", _on_entity_state_changed)

	spare_button.pressed.connect(_on_spare_pressed)
	execute_button.pressed.connect(_on_execute_pressed)


func _process(delta: float) -> void:
	if _is_showing and _remaining > 0:
		_remaining -= delta
		timeout_bar.value = _remaining
		if _remaining <= 0:
			_auto_execute()


func _on_entity_state_changed(entity: Entity, _old_state: int, new_state: int) -> void:
	# Entity.State.DYING = 2
	if new_state == 2 and not entity.is_player:
		_choice_queue.append(entity)
		if not _is_showing:
			_show_next_in_queue()


func _show_next_in_queue() -> void:
	if _choice_queue.is_empty():
		_is_showing = false
		panel.visible = false
		return

	_is_showing = true
	show_choice(_choice_queue.pop_front())


func show_choice(enemy: Entity) -> void:
	_target_entity = enemy
	panel.visible = true

	enemy_name_label.text = "%s is dying..." % enemy.entity_name

	var spare_delta: int = AutoloadHelper.config_int("MORAL_DELTA_SPARE", -1)
	var kill_delta: int = AutoloadHelper.config_int("MORAL_DELTA_KILL", 1)
	moral_preview.text = "Spare: %d | Execute: +%d" % [spare_delta, kill_delta]

	spare_button.text = "Spare (Cost: 1 AP)"
	execute_button.text = "Execute"

	var player := _get_player_entity()
	if player:
		spare_button.disabled = player.ap < 1
	else:
		spare_button.disabled = true

	_remaining = _timeout
	timeout_bar.max_value = _timeout
	timeout_bar.value = _timeout

	# Focus the default choice (Execute is usually the default/free action)
	execute_button.grab_focus.call_deferred()


func _on_spare_pressed() -> void:
	var player := _get_player_entity()
	var lifecycle: Node = AutoloadHelper.entity_lifecycle()
	if player and player.ap >= 1 and lifecycle:
		lifecycle.call("spare_entity", player, _target_entity)
		choice_made.emit(true)
		_hide_choice()


func _on_execute_pressed() -> void:
	var lifecycle: Node = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.call("execute_entity", _target_entity)
		choice_made.emit(false)
		_hide_choice()


func _auto_execute() -> void:
	if _target_entity and _target_entity.state == 2:  # Entity.State.DYING
		var lifecycle: Node = AutoloadHelper.entity_lifecycle()
		if lifecycle:
			lifecycle.call("execute_entity", _target_entity)
			choice_made.emit(false)
	_hide_choice()


func _hide_choice() -> void:
	panel.visible = false
	_target_entity = null
	# Short delay before next one to avoid instant pop-up
	var timer := get_tree().create_timer(0.2)
	timer.timeout.connect(_show_next_in_queue)


func _get_player_entity() -> Entity:
	var lifecycle: Node = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		return lifecycle.get("player_entity") as Entity
	return null

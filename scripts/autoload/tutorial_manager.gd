extends Node
class_name _TutorialManager

## Autoload: TutorialManager
## Manages the initial tutorial sequence, tracking progress and triggers.

const TUTORIAL_DATA_PATH := "res://data/tutorials.json"

signal tutorial_step_started(step_id: String, text_key: String, target: String)
signal tutorial_step_completed(step_id: String)
signal tutorial_finished
signal input_lock_changed(lock_state: String)

var tutorial_enabled: bool = true
var tutorial_complete: bool = false
var current_step_index: int = -1
var tutorial_steps: Array = []
var active_input_lock: String = "none":
	set(p_value):
		if active_input_lock != p_value:
			active_input_lock = p_value
			input_lock_changed.emit(active_input_lock)

var init_time_ms: int = 0
var _last_action: String = ""


func _ready() -> void:
	var start_time: int = Time.get_ticks_msec()
	_load_tutorial_data()
	_check_persistence()
	_connect_signals()
	init_time_ms = Time.get_ticks_msec() - start_time
	_print_debug("Initialized in %d ms" % init_time_ms)


func _load_tutorial_data() -> void:
	if not FileAccess.file_exists(TUTORIAL_DATA_PATH):
		push_error("TutorialManager: Tutorial data file not found at %s" % TUTORIAL_DATA_PATH)
		tutorial_enabled = false
		return

	var file := FileAccess.open(TUTORIAL_DATA_PATH, FileAccess.READ)
	if file:
		var text := file.get_as_text()
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary and parsed.has("steps"):
			tutorial_steps = parsed["steps"] as Array
			_print_debug("Loaded %d tutorial steps" % tutorial_steps.size())
		else:
			push_error("TutorialManager: Invalid tutorial data format")
			tutorial_enabled = false
		file.close()


func _check_persistence() -> void:
	var save_manager: _SaveManager = AutoloadHelper.save_manager()
	if save_manager:
		var save_data := save_manager.load_game()
		if save_data.has("memory_state") and save_data["memory_state"].has("tutorial_complete"):
			tutorial_complete = save_data["memory_state"]["tutorial_complete"]
			if tutorial_complete:
				tutorial_enabled = false
				_print_debug("Tutorial already completed according to save data")


func _connect_signals() -> void:
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.room_entered.connect(_on_room_entered)
		eb.entity_state_changed.connect(_on_entity_state_changed)
		eb.spare_or_execute.connect(_on_spare_or_execute)


func start_tutorial() -> void:
	if not tutorial_enabled or tutorial_complete:
		return

	_print_debug("Starting tutorial")
	current_step_index = 0
	_trigger_current_step()


func _trigger_current_step() -> void:
	if current_step_index < 0 or current_step_index >= tutorial_steps.size():
		_finish_tutorial()
		return

	var step: Dictionary = tutorial_steps[current_step_index]
	_print_debug("Triggering tutorial step: %s" % step["id"])
	active_input_lock = step.get("input_lock", "none")
	tutorial_step_started.emit(step["id"], step["text_key"], step.get("highlight_target", ""))


func complete_step(step_id: String) -> void:
	if current_step_index < 0 or current_step_index >= tutorial_steps.size():
		return

	var current_step: Dictionary = tutorial_steps[current_step_index]
	if current_step["id"] == step_id:
		_print_debug("Completed tutorial step: %s" % step_id)
		tutorial_step_completed.emit(step_id)
		active_input_lock = "none"
		current_step_index += 1
		_evaluate_next_steps()


func _evaluate_next_steps() -> void:
	if current_step_index >= tutorial_steps.size():
		_finish_tutorial()
		return

	var next_step: Dictionary = tutorial_steps[current_step_index]
	var trigger: String = next_step.get("trigger", "")

	if trigger == "after_movement" and _last_action == "player_moved":
		_trigger_current_step()
	elif trigger == "" or trigger == "room_start":
		_trigger_current_step()
	# If trigger is a specific event, we wait for it.


func _finish_tutorial() -> void:
	_print_debug("Tutorial finished")
	tutorial_complete = true
	tutorial_enabled = false
	active_input_lock = "none"
	tutorial_finished.emit()
	_persist_completion()


func _persist_completion() -> void:
	var save_manager: _SaveManager = AutoloadHelper.save_manager()
	if save_manager:
		var save_data := save_manager.load_game()
		if not save_data.has("memory_state"):
			save_data["memory_state"] = {}
		save_data["memory_state"]["tutorial_complete"] = true
		save_manager.save_game(save_data)
		_print_debug("Persisted tutorial completion state")


# ── Public Queries ─────────────────────────────────────────────────────────


func is_input_locked(action: String) -> bool:
	if active_input_lock == "none":
		return false

	if active_input_lock == "movement_only":
		return not action.begins_with("move_")

	if active_input_lock == "attack_only":
		return action != "combat_confirm" and action != "combat_mode"

	return false


# ── Public Notification API ────────────────────────────────────────────────


func notify_player_moved() -> void:
	_last_action = "player_moved"
	_check_condition("player_moved")
	_check_trigger("after_movement")


func notify_attack_executed() -> void:
	_last_action = "attack_executed"
	_check_condition("attack_executed")


func notify_near_cover() -> void:
	_check_trigger("near_cover")


func notify_near_elevation() -> void:
	_check_trigger("near_elevation")


func notify_elemental_hazard() -> void:
	_check_trigger("elemental_hazard")


func notify_enemy_in_range() -> void:
	_check_trigger("enemy_in_range")


func acknowledge_step() -> void:
	_check_condition("acknowledge")


# ── Internal Logic ─────────────────────────────────────────────────────────


func _check_trigger(trigger_name: String) -> void:
	if not tutorial_enabled or tutorial_complete:
		return

	if current_step_index >= 0 and current_step_index < tutorial_steps.size():
		var step: Dictionary = tutorial_steps[current_step_index]
		if step.get("trigger") == trigger_name:
			_trigger_current_step()


func _check_condition(condition_name: String) -> void:
	if not tutorial_enabled or tutorial_complete:
		return

	if current_step_index >= 0 and current_step_index < tutorial_steps.size():
		var step: Dictionary = tutorial_steps[current_step_index]
		if step.get("completion_condition") == condition_name:
			complete_step(step["id"])


# ── Signal Handlers ────────────────────────────────────────────────────────


func _on_room_entered(_p_room_index: int, _p_room_data: Dictionary) -> void:
	if tutorial_enabled and not tutorial_complete and current_step_index == -1:
		current_step_index = 0
		_check_trigger("room_start")


func _on_entity_state_changed(
	entity: Entity, _old_state: Entity.State, new_state: Entity.State
) -> void:
	if not tutorial_enabled:
		return

	if new_state == Entity.State.DYING and not entity.is_player:
		_check_trigger("enemy_dying")


func _on_spare_or_execute(_entity: Entity, _was_spared: bool) -> void:
	if not tutorial_enabled:
		return
	_check_condition("moral_choice_made")


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("TutorialManager: %s" % msg)

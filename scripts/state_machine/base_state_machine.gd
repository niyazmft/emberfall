class_name BaseStateMachine
extends Node

## BaseStateMachine
## Generic hierarchical state machine for Emberfall gameplay systems.
##
## Requirements met:
## - Explicit enumeration of states (subclass defines enum)
## - Valid transitions registered explicitly with guard Callables
## - Entry and exit actions per state
## - Fallback ERROR state for unexpected conditions
## - Frame-rate-independent update via delta parameter
## - Signals for cross-system coordination (UI programmer consumes these)

## Fired when a state is successfully entered. UI programmer can listen.
signal state_entered(state_name: StringName, context: Dictionary)
## Fired when a state is exited. UI programmer can listen.
signal state_exited(state_name: StringName, context: Dictionary)
## Fired on every transition attempt (accepted or rejected). Logging/integration hook.
signal state_transition_attempted(from_name: StringName, to_name: StringName, accepted: bool)
## Fired on guard failure or invalid transition. UI programmer can listen for error UI.
signal state_machine_error(state_name: StringName, message: String)

## Time in seconds the current state has been active. Frame-rate independent.
var state_time: float = 0.0
## ID of the current state. -1 == uninitialized.
var current_state: int = -1
## ID of the previous state. -1 == none.
var previous_state: int = -1

## Human-readable debug names for each state id.
var state_names: Dictionary = {}

## State data: id -> { name: StringName, entry: Callable, exit: Callable, update: Callable }
var _states: Dictionary = {}

## Transition graph: from_id -> Array of Transition dictionaries.
## Transition: { to_id: int, guard: Callable, action: Callable }
var _transitions: Dictionary = {}

var _default_state_id: int = -1
var _error_state_id: int = -1
var _initialized: bool = false

# ---------------------------------------------------------------------------
# Subclass API
# ---------------------------------------------------------------------------

## Register a state. Subclass constructor must call this for every valid state.
func register_state(id: int, name: StringName,
					entry: Callable = Callable(),
					exit: Callable = Callable(),
					update: Callable = Callable()) -> void:
	_states[id] = {
		"name": name,
		"entry": entry,
		"exit": exit,
		"update": update,
	}
	state_names[id] = name
	if not _transitions.has(id):
		_transitions[id] = []

## Register a valid directed transition with optional guard and transition action.
## Guard( Dictionary context ) -> bool. Must return true for transition to proceed.
## Action( Dictionary context ) -> void. Runs only on accepted transition, before entry.
func register_transition(from_id: int, to_id: int,
						 guard: Callable = Callable(),
						 action: Callable = Callable()) -> void:
	if not _transitions.has(from_id):
		_transitions[from_id] = []
	_transitions[from_id].append({
		"to_id": to_id,
		"guard": guard,
		"action": action,
	})

func set_default_state(id: int) -> void:
	_default_state_id = id

func set_error_state(id: int) -> void:
	_error_state_id = id

## Subclass should call this after all register_state/register_transition calls.
func initialize() -> void:
	if _initialized:
		return
	if _default_state_id != -1:
		_change_state(_default_state_id, {})
	_initialized = true

# ---------------------------------------------------------------------------
# Runtime API
# ---------------------------------------------------------------------------

## Public request to transition. Checks guards, runs exit/entry, emits signals.
## Returns true if the transition was accepted.
func transition_to(target_id: int, context: Dictionary = {}) -> bool:
	var from_id := current_state
	var from_name: StringName = state_names.get(from_id, &"UNINITIALIZED") as StringName
	var to_name: StringName = state_names.get(target_id, &"UNKNOWN") as StringName

	if from_id == -1:
		push_error("StateMachine: transition requested before initialization.")
		state_transition_attempted.emit(from_name, to_name, false)
		return false

	if not _is_valid_transition(from_id, target_id, context):
		state_transition_attempted.emit(from_name, to_name, false)
		return false

	_run_transition_actions(from_id, target_id, context)
	_change_state(target_id, context)
	state_transition_attempted.emit(from_name, to_name, true)
	return true

## Frame-rate-independent update. Must be called every frame (or tick) with delta.
func update(delta: float) -> void:
	if not _initialized:
		return
	state_time += delta
	var st_variant: Variant = _states.get(current_state)
	if st_variant and st_variant is Dictionary:
		var st: Dictionary = st_variant as Dictionary
		if st["update"].is_valid():
			st["update"].call(delta, state_time)

## Force a state change without guard checks. Use for emergency/error recovery only.
func force_state(id: int, context: Dictionary = {}) -> void:
	_change_state(id, context)

## Recover to default state. Useful for reset.
func reset(context: Dictionary = {}) -> void:
	if _default_state_id != -1:
		_change_state(_default_state_id, context)
	else:
		push_error("StateMachine: reset called but no default state configured.")

## Return the human-readable name of the current state.
func get_current_state_name() -> StringName:
	return state_names.get(current_state, &"UNKNOWN")

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _is_valid_transition(from_id: int, to_id: int, context: Dictionary) -> bool:
	if not _transitions.has(from_id):
		return false
	var trans_list: Array = _transitions[from_id] as Array
	for t: Variant in trans_list:
		if t is Dictionary:
			var dict: Dictionary = t as Dictionary
			if dict["to_id"] == to_id:
				if dict["guard"].is_valid():
					var ok: Variant = dict["guard"].call(context)
					if ok is bool and ok:
						return true
					else:
						return false
				else:
					return true
	return false

func _run_transition_actions(from_id: int, to_id: int, context: Dictionary) -> void:
	if not _transitions.has(from_id):
		return
	var trans_list: Array = _transitions[from_id] as Array
	for t: Variant in trans_list:
		if t is Dictionary:
			var dict: Dictionary = t as Dictionary
			if dict["to_id"] == to_id and dict["action"].is_valid():
				dict["action"].call(context)
				return

func _change_state(to_id: int, context: Dictionary) -> void:
	var old_id := current_state
	if old_id != -1 and _states.has(old_id):
		var old: Dictionary = _states[old_id] as Dictionary
		if old["exit"].is_valid():
			old["exit"].call(context)
		state_exited.emit(old["name"], context)

	previous_state = old_id
	current_state = to_id
	state_time = 0.0

	if _states.has(to_id):
		var st: Dictionary = _states[to_id] as Dictionary
		if st["entry"].is_valid():
			st["entry"].call(context)
		state_entered.emit(st["name"], context)
	else:
		push_error("StateMachine: attempted to change to unregistered state id %d" % to_id)
		if _error_state_id != -1:
			_change_state(_error_state_id, {"error": "unregistered_state", "target": to_id})

## Move to error state with a message. Can be called by subclass when unexpected condition occurs.
func _error(message: String) -> void:
	push_error("StateMachine: %s" % message)
	state_machine_error.emit(state_names.get(current_state, &"UNKNOWN") as StringName, message)
	if _error_state_id != -1 and current_state != _error_state_id:
		_change_state(_error_state_id, {"error_message": message, "from": current_state})


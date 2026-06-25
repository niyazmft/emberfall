class_name _SecretRoomTrigger
extends Node

## SecretRoomTrigger
## Handles secret room unlock conditions and hidden exit tile spawns.
## Tracks predicates like 'all enemies spared' or 'no damage taken'.
## Architecture: Data-driven via ConfigLoader.

# Current room state tracking
var _spared_all: bool = true
var _took_no_damage: bool = true
var _turn_count: int = 0


func _ready() -> void:
	_connect_signals()


func _exit_tree() -> void:
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		if eb.room_entered.is_connected(_on_room_entered):
			eb.room_entered.disconnect(_on_room_entered)
		if eb.combat_resolved_signal.is_connected(_on_combat_resolved):
			eb.combat_resolved_signal.disconnect(_on_combat_resolved)
		if eb.spare_or_execute.is_connected(_on_spare_or_execute):
			eb.spare_or_execute.disconnect(_on_spare_or_execute)


func _connect_signals() -> void:
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.room_entered.connect(_on_room_entered)
		eb.combat_resolved_signal.connect(_on_combat_resolved)
		eb.spare_or_execute.connect(_on_spare_or_execute)
	else:
		push_error("SecretRoomTrigger: EventBus not found")


func _on_room_entered(_idx: int, _room_data: Dictionary) -> void:
	_spared_all = true
	_took_no_damage = true
	_turn_count = 0


func _on_spare_or_execute(_entity: Entity, was_spared: bool) -> void:
	if not was_spared:
		_spared_all = false


func _on_combat_resolved(_idx: int) -> void:
	_evaluate_conditions()


## Public API: Check whether secret room conditions are met based on run data.
## Returns true if any secret condition is satisfied.
func check_secret_conditions(run_data: Dictionary) -> bool:
	var conditions: Array = _load_conditions()
	if conditions.is_empty():
		return false

	var room_kills: int = int(run_data.get("room_kills", 0))
	var room_damage_taken: int = int(run_data.get("room_damage_taken", 0))
	var enemies_spared: int = int(run_data.get("enemies_spared", 0))
	var turn_count: int = int(run_data.get("turn_count", 0))

	for cond: Variant in conditions:
		if not cond is Dictionary:
			continue
		var predicate: String = str(cond.get("predicate", ""))
		var success: bool = false
		match predicate:
			"all_enemies_spared":
				success = enemies_spared > 0 and room_kills == 0
			"no_damage_taken":
				success = room_damage_taken == 0
			"specific_turn_count":
				var limit: int = int(cond.get("predicate_value", 0))
				success = turn_count <= limit
			"fast_clear":
				var fast_limit: int = int(cond.get("predicate_value", 5))
				success = turn_count <= fast_limit and room_damage_taken == 0
		if success:
			return true
	return false


## Public API: Return a secret room ID when conditions are met.
## Returns empty string if no conditions are met.
func get_secret_room_id(run_data: Dictionary) -> String:
	var conditions: Array = _load_conditions()
	if conditions.is_empty():
		return ""

	var room_kills: int = int(run_data.get("room_kills", 0))
	var room_damage_taken: int = int(run_data.get("room_damage_taken", 0))
	var enemies_spared: int = int(run_data.get("enemies_spared", 0))
	var turn_count: int = int(run_data.get("turn_count", 0))

	for cond: Variant in conditions:
		if not cond is Dictionary:
			continue
		var predicate: String = str(cond.get("predicate", ""))
		var success: bool = false
		match predicate:
			"all_enemies_spared":
				success = enemies_spared > 0 and room_kills == 0
			"no_damage_taken":
				success = room_damage_taken == 0
			"specific_turn_count":
				var limit: int = int(cond.get("predicate_value", 0))
				success = turn_count <= limit
			"fast_clear":
				var fast_limit: int = int(cond.get("predicate_value", 5))
				success = turn_count <= fast_limit and room_damage_taken == 0
		if success:
			return str(cond.get("room_id", "room_secret_01"))
	return ""


func _load_conditions() -> Array:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl == null:
		return []
	var cfg: Variant = cl.getValue("conditions")
	if cfg is Array:
		return cfg as Array
	return []


func _evaluate_conditions() -> void:
	var conditions: Array = _load_conditions()
	if conditions.is_empty():
		return

	for cond: Variant in conditions:
		if not cond is Dictionary:
			continue

		var success: bool = false
		var predicate: String = str(cond.get("predicate", ""))

		match predicate:
			"all_enemies_spared":
				success = _spared_all
			"no_damage_taken":
				success = _took_no_damage
			"specific_turn_count":
				var limit: int = int(cond.get("predicate_value", 0))
				success = _turn_count <= limit

		if success:
			_unlock_secret(cond)


func _unlock_secret(cond: Dictionary) -> void:
	var spawn_tile_id: String = cond.get("spawn_tile_id", "")
	var flavor_key: String = cond.get("flavor_key", "")

	print("SecretRoomTrigger: UNLOCKED secret with tile %s" % spawn_tile_id)

	# Interaction with GridSystem to spawn the exit
	var gs := AutoloadHelper.grid_system()
	if gs:
		gs.spawn_special_tile(spawn_tile_id)

	# Narrative feedback
	if not flavor_key.is_empty():
		var an: _AmbientNarrator = AutoloadHelper.ambient_narrator()
		if an:
			an.trigger_narrative(flavor_key)


## Public API to report player damage for 'no_damage_taken' predicate.
func report_player_damage() -> void:
	_took_no_damage = false


## Public API to increment turn count for 'specific_turn_count' predicate.
func increment_turn_count() -> void:
	_turn_count += 1

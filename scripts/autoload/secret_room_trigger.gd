extends Node
class_name _SecretRoomTrigger

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


func _evaluate_conditions() -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl == null:
		return

	var conditions: Variant = cl.getValue("conditions")
	if not conditions is Array:
		return

	for cond: Variant in conditions:
		if not cond is Dictionary:
			continue

		var success: bool = false
		var predicate: String = cond.get("predicate", "")

		match predicate:
			"all_enemies_spared":
				success = _spared_all
			"no_damage_taken":
				success = _took_no_damage
			"specific_turn_count":
				var limit: int = cond.get("predicate_value", 0)
				success = _turn_count <= limit

		if success:
			_unlock_secret(cond)


func _unlock_secret(cond: Dictionary) -> void:
	var spawn_tile_id: String = cond.get("spawn_tile_id", "")
	var flavor_key: String = cond.get("flavor_key", "")
	if spawn_tile_id.is_empty():
		push_error("SecretRoomTrigger: Missing spawn_tile_id in secret condition")
		return

	print("SecretRoomTrigger: UNLOCKED secret with tile %s" % spawn_tile_id)

	# Interaction with GridSystem to spawn the exit
	var gs: _GridSystem = AutoloadHelper.grid_system()
	if gs and gs.has_method("spawn_special_tile"):
		gs.call("spawn_special_tile", spawn_tile_id)
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

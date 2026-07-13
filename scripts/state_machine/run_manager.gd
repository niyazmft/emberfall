extends BaseStateMachine
class_name _RunManager

## RunManager
## Implements the Run Manager state machine from System Specification §5.
## Manages game-phase flow: SANCTUM → BIOME_GENERATION → ROOM → ... → RUN_RESOLUTION.

enum RunState {
	SANCTUM,
	BIOME_GENERATION,
	ROOM,
	MORAL_EVAL,
	BIOME_THRESHOLD,
	RUN_RESOLUTION,
	ERROR,
}

## Whether the moral eval is waiting for Burden Event resolution
var _moral_eval_waiting_burden: bool = false

## Reference to EntityLifecycle autoload (if present)
var _entity_lifecycle: Node = null
var run_seed: int = 0
var biome_count: int = 3
var rooms_per_biome_min: int = 8
var rooms_per_biome_max: int = 12
var total_rooms: int = 0
var room_queue: Array[Dictionary] = []
var room_index: int = -1
var memory_state_loaded: bool = false

# Context flags for guards
var _combat_resolved: bool = false
var _player_hp_zero: bool = false
var _final_encounter_won: bool = false
var _echo_triggered: bool = false
var _flags_updated: bool = false
var _topology_ready: bool = false
var _run_count: int = 0
var _requested_seed: Variant = null

# Timers (frame-rate independent)
var _biome_gen_timer: float = 0.0
var _moral_eval_timer: float = 0.0
var _dying_duration: float = 0.0

# Signals consumed by UI programmer
signal run_started(p_seed: int)
signal room_entered(p_room_index: int, p_room_data: Dictionary)
signal combat_resolved_signal(p_room_index: int)
signal moral_flags_updated(p_deltas: Array)
signal biome_echo_triggered(p_biome_index: int)
signal run_ended(p_result: StringName, p_run_context: Dictionary)


func _ready() -> void:
	setup_state_machine()

	_load_config_values()
	var el: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if el != null:
		_entity_lifecycle = el
		if _entity_lifecycle.has_signal("mwt_reached"):
			_entity_lifecycle.connect("mwt_reached", _on_mwt_reached)


func _process(delta: float) -> void:
	update(delta)


func _exit_tree() -> void:
	if _entity_lifecycle and _entity_lifecycle.is_connected("mwt_reached", _on_mwt_reached):
		_entity_lifecycle.disconnect("mwt_reached", _on_mwt_reached)


func _on_mwt_reached(_moral_flag: int, _remaining: int) -> void:
	# When MWT is reached, the Burden Event system takes over.
	_moral_eval_waiting_burden = true


func setup_state_machine() -> void:
	if _initialized:
		return
	_register_states()
	_register_transitions()
	set_default_state(RunState.SANCTUM)
	set_error_state(RunState.ERROR)
	initialize()


func _load_config_values() -> void:
	if Engine.is_editor_hint():
		return
	biome_count = AutoloadHelper.config_int("BIOME_COUNT", 3)
	rooms_per_biome_min = AutoloadHelper.config_int("ROOMS_PER_BIOME_MIN", 8)
	rooms_per_biome_max = AutoloadHelper.config_int("ROOMS_PER_BIOME_MAX", 12)
	_dying_duration = float(AutoloadHelper.config_int("DYING_DURATION_TURNS", 1))


# ---------------------------------------------------------------------------
# State Registration
# ---------------------------------------------------------------------------


func _register_states() -> void:
	register_state(
		RunState.SANCTUM, &"SANCTUM", Callable(self, "_enter_sanctum"), Callable(), Callable()
	)
	register_state(
		RunState.BIOME_GENERATION,
		&"BIOME_GENERATION",
		Callable(self, "_enter_biome_generation"),
		Callable(),
		Callable(self, "_update_biome_generation")
	)
	register_state(RunState.ROOM, &"ROOM", Callable(self, "_enter_room"), Callable(), Callable())
	register_state(
		RunState.MORAL_EVAL,
		&"MORAL_EVAL",
		Callable(self, "_enter_moral_eval"),
		Callable(),
		Callable(self, "_update_moral_eval")
	)
	register_state(
		RunState.BIOME_THRESHOLD,
		&"BIOME_THRESHOLD",
		Callable(self, "_enter_biome_threshold"),
		Callable(),
		Callable(self, "_update_biome_threshold")
	)
	register_state(
		RunState.RUN_RESOLUTION,
		&"RUN_RESOLUTION",
		Callable(self, "_enter_run_resolution"),
		Callable(),
		Callable()
	)
	register_state(RunState.ERROR, &"ERROR", Callable(self, "_enter_error"), Callable(), Callable())


# ---------------------------------------------------------------------------
# Transition Registration
# ---------------------------------------------------------------------------


func _register_transitions() -> void:
	# SANCTUM → BIOME_GENERATION (guard: always allowed for new runs)
	register_transition(
		RunState.SANCTUM, RunState.BIOME_GENERATION, Callable(), Callable(self, "_action_start_run")
	)

	# BIOME_GENERATION → ROOM (guard: topology generation done)
	register_transition(
		RunState.BIOME_GENERATION,
		RunState.ROOM,
		Callable(self, "_guard_topology_ready"),
		Callable(self, "_action_generate_rooms")
	)

	# ROOM → MORAL_EVAL (guard: combat finished)
	register_transition(
		RunState.ROOM, RunState.MORAL_EVAL, Callable(self, "_guard_combat_resolved"), Callable()
	)

	# ROOM → ROOM (progress next room) or BIOME_THRESHOLD or RUN_RESOLUTION
	register_transition(
		RunState.ROOM,
		RunState.ROOM,
		Callable(self, "_guard_next_room_normal"),
		Callable(self, "_action_increment_room")
	)
	register_transition(
		RunState.ROOM,
		RunState.BIOME_THRESHOLD,
		Callable(self, "_guard_next_room_boundary"),
		Callable(self, "_action_increment_room")
	)
	register_transition(
		RunState.ROOM, RunState.RUN_RESOLUTION, Callable(self, "_guard_run_end"), Callable()
	)

	# MORAL_EVAL → ROOM (guard: flag processing done)
	register_transition(
		RunState.MORAL_EVAL, RunState.ROOM, Callable(self, "_guard_flags_updated"), Callable()
	)

	# BIOME_THRESHOLD → ROOM (guard: echo narrative complete)
	register_transition(
		RunState.BIOME_THRESHOLD, RunState.ROOM, Callable(self, "_guard_echo_triggered"), Callable()
	)

	# RUN_RESOLUTION → SANCTUM (always valid return)
	register_transition(
		RunState.RUN_RESOLUTION, RunState.SANCTUM, Callable(), Callable(self, "_action_reset_run")
	)

	# ERROR → SANCTUM (recovery)
	register_transition(
		RunState.ERROR, RunState.SANCTUM, Callable(), Callable(self, "_action_reset_run")
	)


# ---------------------------------------------------------------------------
# Public Commands (called by gameplay systems, not UI)
# ---------------------------------------------------------------------------


## Call from gameplay when the player chooses "Start Run" in the Sanctum.
## Passing null (default) will generate a new session-deterministic seed.
func cmd_start_run(p_seed: Variant = null) -> void:
	_requested_seed = p_seed
	transition_to(RunState.BIOME_GENERATION)


## Call from Level/Topology system when room generation is complete.
func cmd_topology_ready() -> void:
	_topology_ready = true
	if current_state == RunState.BIOME_GENERATION:
		transition_to(RunState.ROOM)


## Call from combat system when all enemies are defeated.
func cmd_combat_resolved() -> void:
	_combat_resolved = true
	if current_state == RunState.ROOM:
		transition_to(RunState.MORAL_EVAL)


## Call from moral encounter system after flag deltas are applied.
func cmd_flags_updated() -> void:
	_flags_updated = true
	if current_state == RunState.MORAL_EVAL:
		transition_to(RunState.ROOM)


## Call from narrative system after biome echo is complete.
func cmd_echo_triggered() -> void:
	_echo_triggered = true
	if current_state == RunState.BIOME_THRESHOLD:
		transition_to(RunState.ROOM)


## Call when player decides to proceed to next room (or system auto-advances).
func cmd_next_room() -> void:
	if current_state == RunState.ROOM:
		# Determine target by guards
		if _guard_run_end({}):
			transition_to(RunState.RUN_RESOLUTION)
		elif _guard_next_room_boundary({}):
			transition_to(RunState.BIOME_THRESHOLD)
		elif _guard_next_room_normal({}):
			transition_to(RunState.ROOM)


## Restart the current room from the beginning.
func cmd_restart_room() -> void:
	if room_index < 0 or room_index >= room_queue.size():
		push_error("cmd_restart_room called with invalid room_index: %d" % room_index)
		return
	_combat_resolved = false
	_enter_room({})


## Call from combat/entity system when player HP reaches 0.
func cmd_player_defeated() -> void:
	_player_hp_zero = true
	if current_state == RunState.ROOM:
		transition_to(RunState.RUN_RESOLUTION)


## Call when final boss encounter is won.
func cmd_final_encounter_won() -> void:
	_final_encounter_won = true
	if current_state == RunState.ROOM:
		transition_to(RunState.RUN_RESOLUTION)


## Return to SANCTUM from any resolution/error state.
func cmd_return_to_sanctum() -> void:
	transition_to(RunState.SANCTUM)


# ---------------------------------------------------------------------------
# State Entry / Update / Guards / Actions
# ---------------------------------------------------------------------------


func _enter_sanctum(_ctx: Dictionary) -> void:
	memory_state_loaded = false
	_combat_resolved = false
	_player_hp_zero = false
	_final_encounter_won = false
	_echo_triggered = false
	_flags_updated = false
	_topology_ready = false
	room_queue.clear()
	room_index = -1
	run_seed = 0
	# Reset burden tracking for new sanctum session.
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm != null:
		bm.reset()


func _enter_biome_generation(_ctx: Dictionary) -> void:
	_biome_gen_timer = 0.0
	_topology_ready = false


func _update_biome_generation(delta: float, _elapsed: float) -> void:
	_biome_gen_timer += delta
	# Stub: generation is instantaneous for framework validation.
	if _biome_gen_timer >= 0.016:  # one frame at 60fps minimum
		cmd_topology_ready()


func _enter_room(_ctx: Dictionary) -> void:
	# Reset one-shot flags that are room-scoped
	_combat_resolved = false

	var room_data: Dictionary = get_current_room_data()
	var room_id: String = room_data.get("room_id", "room_standard_01")

	# Load room definition and augment room_data
	var room_def := RoomLoader.load_room_data(room_id)
	if not room_def.is_empty():
		for key: String in room_def:
			if not room_data.has(key):
				room_data[key] = room_def[key]

	# Apply procedural augmentation (topology + encounters)
	RoomLoader.augment_room_procedurally(room_data)

	if OS.is_debug_build():
		print(
			(
				"[RunManager] Entering room %d (id: %s)"
				% [room_index, room_data.get("room_id", "unknown")]
			)
		)

	# Emit event for UI / encounter spawner
	room_entered.emit(room_index, room_data)
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.room_entered.emit(room_index, room_data)

	# FIX #604: Auto-save at start of room (phase boundary).
	_auto_save_current_run()


func _enter_moral_eval(_ctx: Dictionary) -> void:
	_moral_eval_timer = 0.0
	_flags_updated = false
	_moral_eval_waiting_burden = false

	if _entity_lifecycle and _entity_lifecycle.player_entity:
		_entity_lifecycle.resolve_moral_queue()
	else:
		var deltas: Array = _compute_moral_deltas()
		moral_flags_updated.emit(deltas)

	# FIX #604: Auto-save after combat resolved (phase boundary).
	_auto_save_current_run()


## FIX #604: Serializes current run state and writes to auto-save slot.
func _auto_save_current_run() -> void:
	var sm: _SaveManager = AutoloadHelper.save_manager()
	if sm == null:
		return
	var run_state := save_run_state()
	if run_state.is_empty():
		return
	sm.auto_save_run(run_state)


func _update_moral_eval(delta: float, _elapsed: float) -> void:
	_moral_eval_timer += delta
	# If waiting for Burden Event resolution, do not auto-resolve.
	if _moral_eval_waiting_burden:
		return
	# Auto-resolve after a brief tick to prevent stuck state.
	if _moral_eval_timer >= 0.016:
		cmd_flags_updated()


func _enter_biome_threshold(_ctx: Dictionary) -> void:
	_echo_triggered = false
	var biome_index: int = _get_current_biome_index()
	biome_echo_triggered.emit(biome_index)


func _update_biome_threshold(delta: float, _elapsed: float) -> void:
	# Frame-rate independent echo timer.
	state_time += delta
	if state_time >= 0.016:
		cmd_echo_triggered()


func _enter_run_resolution(_ctx: Dictionary) -> void:
	var result: StringName = &"DEFEAT"
	if _final_encounter_won:
		result = &"TRIUMPH"
	(
		run_ended
		. emit(
			result,
			{
				"seed": run_seed,
				"rooms_cleared": room_index + 1,
				"player_defeated": _player_hp_zero,
				"final_encounter_won": _final_encounter_won,
			}
		)
	)


func _enter_error(_ctx: Dictionary) -> void:
	push_error("RunManager entered ERROR state — run may be unrecoverable.")


# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------


func _guard_memory_loaded(_ctx: Dictionary) -> bool:
	return memory_state_loaded


func _guard_topology_ready(_ctx: Dictionary) -> bool:
	return _topology_ready


func _guard_combat_resolved(_ctx: Dictionary) -> bool:
	return _combat_resolved


func _guard_flags_updated(_ctx: Dictionary) -> bool:
	return _flags_updated


func _guard_echo_triggered(_ctx: Dictionary) -> bool:
	return _echo_triggered


func _guard_next_room_normal(_ctx: Dictionary) -> bool:
	if room_index < 0 or room_queue.is_empty():
		return false
	if _player_hp_zero or _final_encounter_won:
		return false
	var next_idx: int = room_index + 1
	if next_idx >= room_queue.size():
		return false
	return not _is_biome_boundary(next_idx)


func _guard_next_room_boundary(_ctx: Dictionary) -> bool:
	if room_index < 0 or room_queue.is_empty():
		return false
	if _player_hp_zero or _final_encounter_won:
		return false
	var next_idx: int = room_index + 1
	if next_idx >= room_queue.size():
		return false
	return _is_biome_boundary(next_idx)


func _guard_run_end(_ctx: Dictionary) -> bool:
	if room_index < 0 or room_queue.is_empty():
		return false
	return _player_hp_zero or _final_encounter_won or (room_index + 1) >= room_queue.size()


# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------


func _action_start_run(_ctx: Dictionary) -> void:
	_run_count += 1
	if _requested_seed != null:
		run_seed = int(_requested_seed)
	else:
		var entropy: String = (
			OS.get_unique_id() + str(Time.get_unix_time_from_system()) + str(_run_count)
		)
		run_seed = SeedGovernance.hash_seed(entropy)

	_requested_seed = null
	room_queue.clear()
	room_index = -1
	run_started.emit(run_seed)


func _action_generate_rooms(_ctx: Dictionary) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = run_seed

	var config_loader := AutoloadHelper.config_loader()
	var biomes_data: Dictionary = {}
	if config_loader:
		biomes_data = config_loader.getValue("biomes", "", {}) as Dictionary

	for b: int in range(biome_count):
		var count: int = rng.randi_range(rooms_per_biome_min, rooms_per_biome_max)
		var biome_key := "biome%d" % (b + 1)
		var biome_info: Dictionary = biomes_data.get(biome_key, {}) as Dictionary

		var room_templates: Array = biome_info.get("room_templates", []) as Array

		for r: int in range(count):
			var current_room_idx: int = room_queue.size()
			var room_id := ""

			if not room_templates.is_empty():
				room_id = room_templates[rng.randi_range(0, room_templates.size() - 1)]
			else:
				room_id = "room_standard_0%d" % (rng.randi_range(1, 5))

			(
				room_queue
				. append(
					{
						"room_id": room_id,
						"biome": b,
						"room_in_biome": r,
						"topology_seed":
						SeedGovernance.hash_int(run_seed, "TOPO" + str(current_room_idx)),
						"encounter_seed":
						SeedGovernance.hash_int(run_seed, "ENC" + str(current_room_idx)),
					}
				)
			)
	total_rooms = room_queue.size()
	room_index = 0


func _action_increment_room(_ctx: Dictionary) -> void:
	room_index += 1
	_check_and_append_secret_room()


## Check if secret room conditions are met after a room is cleared.
## If met, append a secret room to the run queue.
func _check_and_append_secret_room() -> void:
	## Guard: only check after a room with actual combat data.
	## In tests, room data may be empty (all zeros), which would falsely
	## trigger "no_damage_taken" and "fast_clear" conditions.
	var room_data := get_current_room_data()
	var turn_count: int = int(room_data.get("turn_count", 0))
	var room_kills: int = int(room_data.get("room_kills", 0))
	var enemies_spared: int = int(room_data.get("enemies_spared", 0))
	if turn_count == 0 and room_kills == 0 and enemies_spared == 0:
		return

	var srt: _SecretRoomTrigger = AutoloadHelper.secret_room_trigger()
	if srt == null:
		return

	var run_data := _build_run_data_for_secret_check()
	if srt.check_secret_conditions(run_data):
		var secret_room_id: String = srt.get_secret_room_id(run_data)
		if not secret_room_id.is_empty():
			var secret_room_data: Dictionary = {
				"room_id": secret_room_id,
				"biome": _get_current_biome_index(),
				"room_in_biome": -1,
				"topology_seed": SeedGovernance.hash_int(run_seed, "SECRET" + str(room_index)),
				"encounter_seed": SeedGovernance.hash_int(run_seed, "SECRET_ENC" + str(room_index)),
				"is_secret": true,
			}
			# Insert the secret room after the current room
			if room_index + 1 < room_queue.size():
				room_queue.insert(room_index + 1, secret_room_data)
			else:
				room_queue.append(secret_room_data)
			print("RunManager: Secret room %s appended to queue" % secret_room_id)


## Build run data snapshot for secret room condition checking.
func _build_run_data_for_secret_check() -> Dictionary:
	var room_data: Dictionary = get_current_room_data()
	var room_kills: int = int(room_data.get("room_kills", 0))
	var room_damage_taken: int = int(room_data.get("room_damage_taken", 0))
	var enemies_spared: int = int(room_data.get("enemies_spared", 0))
	var turn_count: int = int(room_data.get("turn_count", 0))
	return {
		"room_kills": room_kills,
		"room_damage_taken": room_damage_taken,
		"enemies_spared": enemies_spared,
		"turn_count": turn_count,
	}


func _action_reset_run(_ctx: Dictionary) -> void:
	room_queue.clear()
	room_index = -1
	_player_hp_zero = false
	_final_encounter_won = false
	if _entity_lifecycle:
		_entity_lifecycle.reset_moral_queue()
		_entity_lifecycle.clear_timers()
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm != null:
		bm.reset()


func _compute_moral_deltas() -> Array:
	return []


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _is_biome_boundary(next_room_index: int) -> bool:
	if room_queue.is_empty():
		return false
	if next_room_index >= room_queue.size():
		return false
	var current_biome: int = int(room_queue[room_index]["biome"])
	var next_biome: int = int(room_queue[next_room_index]["biome"])
	return current_biome != next_biome


func _get_current_biome_index() -> int:
	if room_index >= 0 and room_index < room_queue.size():
		return int(room_queue[room_index]["biome"])
	return 0


func get_current_room_data() -> Dictionary:
	if room_index >= 0 and room_index < room_queue.size():
		return room_queue[room_index]
	return {}


func get_current_state_name() -> StringName:
	return state_names.get(current_state, &"UNKNOWN")


## Returns a Dictionary containing the current run's state for persistence.
## Matches save_schema.json §run_state.
func save_run_state() -> Dictionary:
	var result: Dictionary = {
		"seed": run_seed,
		"room_index": room_index,
		"room_queue": room_queue.duplicate(true),
		"biome_index": _get_current_biome_index(),
	}

	# FIX #604: Capture player entity snapshot.
	var el: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if el != null and el.player_entity != null:
		result["player_entity_snapshot"] = ActionHistory.serialize_entity(el.player_entity)

	# FIX #604: Capture burden run snapshot.
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm != null:
		result["burden_run_snapshot"] = {
			"trigger_count_this_run": bm.get_trigger_count_this_run(),
			"last_noun_index_used": bm.get_last_noun_index(),
		}

	return result


## Restores the run's state from a saved Dictionary.
func load_run_state(p_data: Dictionary) -> void:
	if p_data.has("seed"):
		run_seed = int(p_data["seed"])
	if p_data.has("room_index"):
		room_index = int(p_data["room_index"])
	if p_data.has("room_queue") and p_data["room_queue"] is Array:
		room_queue.clear()
		for item: Variant in p_data["room_queue"]:
			if item is Dictionary:
				room_queue.append(item as Dictionary)

	# biome_index is stored but biome tracking is currently derived from room_queue.
	# We ensure the room_index is valid for the loaded queue.
	if room_queue.size() > 0:
		room_index = clampi(room_index, 0, room_queue.size() - 1)

	# FIX #604: Restore player entity snapshot.
	if p_data.has("player_entity_snapshot"):
		var el: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
		if el != null and el.player_entity != null:
			ActionHistory.restore_entity(el.player_entity, p_data["player_entity_snapshot"])

	# FIX #604: Restore burden run snapshot.
	if p_data.has("burden_run_snapshot"):
		var bm: _BurdenManager = AutoloadHelper.burden_manager()
		if bm != null and p_data["burden_run_snapshot"] is Dictionary:
			var bs: Dictionary = p_data["burden_run_snapshot"] as Dictionary
			# BurdenManager stores these in private vars; we call public setters if available.
			# For now, we rely on BurdenManager's load from memory_state for the noun index,
			# and the trigger count is ephemeral per run.

	memory_state_loaded = true
	_topology_ready = true


## Convert a 64-bit seed to a 16-character hex replay code.
static func seed_to_replay_code(p_seed: int) -> String:
	return "%016X" % p_seed


## Convert a 16-character hex replay code back to a 64-bit seed.
static func replay_code_to_seed(p_code: String) -> int:
	return p_code.hex_to_int()

extends Node
class_name _BurdenManager

## BurdenManager
## Autoload that tracks sentient enemy kills and exposes the composite
## apparition lookup for the Burden Event (Memory Weight Threshold = 3).

const KILL_HISTORY_CAP: int = 3
const BURDEN_CONFIG_PATH := "res://config/burden_event_config.json"

## ── Backward Compatibility Types ────────────────────────────────
const BurdenKillRecord = preload("res://scripts/burden/burden_kill_record.gd")
const BurdenEventResult = preload("res://scripts/burden/burden_event_result.gd")

## ── Internal Components (use preload for robustness in Autoloads) ──
const BurdenEventEngine = preload("res://scripts/burden/burden_event_engine.gd")
const BurdenCaptionBridge = preload("res://scripts/burden/burden_caption_bridge.gd")

## ── Signals ──────────────────────────────────────────────────────
signal kill_history_changed(kill_queue: Array[BurdenKillRecord])
signal burden_active_changed(active: bool)
signal burden_event_triggered(result: BurdenEventResult)

## ── Existing State (backward compatible) ──────────────────────────
var burden_active: bool = false:
	set(value):
		if value != burden_active:
			burden_active = value
			burden_active_changed.emit(value)

var _kill_queue: Array[BurdenKillRecord] = []
var _atlas_cache: Dictionary = {}
var total_sentient_kills: int = 0
var current_mwt_level: int = 0

## ── Gate 2-2 State ──────────────────────────────────────────────
var _config: Dictionary = {}
var _config_loaded: bool = false

## Burden Event counters
var _burden_trigger_count: int = 0  ## Per-run trigger count (resets on new run)
var _lifetime_trigger_count: int = 0  ## Cross-run cumulative counter (persisted)
var _burden_noun_index: int = 0  ## Persisted across runs (memory_state.echo_flags)

## Internal Classes
var _event_engine: _BurdenEventEngine = null
var _caption_bridge: _BurdenCaptionBridge = null

## MWT Matrix (DON-222)
var _mwt_matrix_script := preload("res://ui/framework/mwt_caption_matrix.gd")
var _mwt_matrix: _MWTCaptionMatrix = null


func _init() -> void:
	## Initialize components in _init to ensure they are available for early calls
	_event_engine = BurdenEventEngine.new()
	_caption_bridge = BurdenCaptionBridge.new()


func _ready() -> void:
	_mwt_matrix = _mwt_matrix_script.new()
	_load_burden_config()


# ---------------------------------------------------------------------------
# Config Loading
# ---------------------------------------------------------------------------


func _load_burden_config() -> void:
	if FileAccess.file_exists(BURDEN_CONFIG_PATH):
		var file := FileAccess.open(BURDEN_CONFIG_PATH, FileAccess.READ)
		if file:
			var text := file.get_as_text()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary:
				_config = parsed
				_config_loaded = true
				_apply_config()
				_print_debug("loaded burden event config from %s" % BURDEN_CONFIG_PATH)
			else:
				push_warning("BurdenManager: config file was not a valid JSON object.")
			file.close()
	else:
		push_warning(
			(
				"BurdenManager: config file not found at %s; using hard-coded defaults."
				% BURDEN_CONFIG_PATH
			)
		)
		_apply_defaults()


func _apply_config() -> void:
	_event_engine.apply_config(_config)
	_caption_bridge.initialize(_config, _mwt_matrix)


func _apply_defaults() -> void:
	_event_engine.apply_defaults()
	_caption_bridge.initialize(_config, _mwt_matrix)


# ---------------------------------------------------------------------------
# Persistence API (Save / Load)
# ---------------------------------------------------------------------------


## Load cross-run memory state from save file.
## Expected state shape: { "echo_flags": { "burden_noun_index": int, ... } }
func load_memory_state(state: Dictionary) -> void:
	if state.has("echo_flags") and state["echo_flags"] is Dictionary:
		var flags: Dictionary = state["echo_flags"]
		if flags.has("burden_noun_index") and flags["burden_noun_index"] is int:
			_burden_noun_index = DeterministicMath.clampi(
				int(flags["burden_noun_index"]), 0, _event_engine.get_noun_pool_size() - 1
			)
		if flags.has("burden_trigger_history") and flags["burden_trigger_history"] is int:
			_lifetime_trigger_count = maxi(0, int(flags["burden_trigger_history"]))
	_print_debug(
		(
			"loaded memory_state: noun_index=%d, lifetime_triggers=%d"
			% [_burden_noun_index, _lifetime_trigger_count]
		)
	)


## Returns a Dictionary compatible with save_schema.json §memory_state.echo_flags
func save_memory_state() -> Dictionary:
	return {
		"burden_noun_index": _burden_noun_index,
		"burden_trigger_history": _lifetime_trigger_count,
	}


# ---------------------------------------------------------------------------
# Public API — Kill History (backward compatible)
# ---------------------------------------------------------------------------


func record_sentient_kill(p_enemy_id: String, p_display_name: String = "") -> void:
	var record := BurdenKillRecord.new(p_enemy_id, p_display_name, Time.get_ticks_msec())
	_kill_queue.append(record)
	if _kill_queue.size() > KILL_HISTORY_CAP:
		_kill_queue.remove_at(0)
	total_sentient_kills += 1
	kill_history_changed.emit(_kill_queue.duplicate())
	_print_debug("recorded sentient kill: %s (queue size=%d)" % [p_enemy_id, _kill_queue.size()])


func get_kill_queue() -> Array[BurdenKillRecord]:
	return _kill_queue.duplicate()


func get_last_kills(count: int) -> Array[BurdenKillRecord]:
	var out: Array[BurdenKillRecord] = []
	var start := maxi(0, _kill_queue.size() - count)
	for i in range(start, _kill_queue.size()):
		out.append(_kill_queue[i])
	return out


func get_last_enemy_ids(count: int = KILL_HISTORY_CAP) -> PackedStringArray:
	var out := PackedStringArray()
	var records := get_last_kills(count)
	for r in records:
		out.append(r.enemy_id)
	return out


func get_silhouette_texture(enemy_id: String) -> Texture2D:
	return _atlas_cache.get(enemy_id, null)


func register_silhouette(enemy_id: String, texture: Texture2D) -> void:
	_atlas_cache[enemy_id] = texture


func unregister_silhouette(enemy_id: String) -> void:
	_atlas_cache.erase(enemy_id)


## Wipe history and atlas (called on run start / sanctum return).
## NOTE: Does NOT wipe persisted memory_state (burden_noun_index, lifetime_trigger_count).
func reset() -> void:
	_kill_queue.clear()
	_atlas_cache.clear()
	total_sentient_kills = 0
	burden_active = false
	current_mwt_level = 0
	_burden_trigger_count = 0
	## Flush any pending Burden captions on reset
	var cm := _caption_node()
	if cm and cm.has_method("cancel_channel"):
		cm.call("cancel_channel", 1)  ## CaptionManager.Channel.BURDEN
	_print_debug("reset run-local state (persisted noun_index=%d)" % _burden_noun_index)


# ---------------------------------------------------------------------------
# Global parameter binding (backward compatible)
# ---------------------------------------------------------------------------


## Safe helper to access ConfigLoader autoload without static-call parse errors.
func _config_node() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		var n: Node = ml.root.get_node_or_null("ConfigLoader")
		if n:
			return n
	return get_node_or_null("/root/ConfigLoader")


func _config_int(key: String, fallback: int) -> int:
	var n := _config_node()
	if n and n.has_method("get_int"):
		return n.get_int(key, fallback)
	return fallback


func update_moral_weight(moral_flag: int) -> void:
	var threshold: int = _config_int("MWT", GameConstants.MWT)

	var old_level := current_mwt_level
	## Map moral_flag to MWT level (0-3) as a ratio of threshold.
	var new_level := clampi(floori(float(moral_flag) / float(threshold) * 3.0), 0, 3)

	if new_level != old_level:
		var is_emergency := old_level == 3 and new_level <= 1
		current_mwt_level = new_level
		_caption_bridge.schedule_mwt_transition_caption(old_level, new_level, is_emergency)
		_caption_bridge.schedule_mwt_state_caption(new_level)

	var should_be_active := moral_flag >= threshold
	if should_be_active != burden_active:
		burden_active = should_be_active
		_print_debug(
			(
				"burden_active toggled → %s (flag=%d, threshold=%d)"
				% [str(burden_active), moral_flag, threshold]
			)
		)


# ---------------------------------------------------------------------------
# Gate 2-2 — Deterministic Selection & Numbness Cap
# ---------------------------------------------------------------------------


## Returns true if the numbness cap has been reached this run.
func is_numb() -> bool:
	return _burden_trigger_count >= _event_engine.get_numbness_cap()


## Returns the localization key for the numbness-cap rule (for UI / captions).
func get_numbness_localization_key() -> String:
	return _event_engine.get_numbness_localization_key()


## Phase B timing window validation helper.
func is_within_phase_b_window(duration_ms: int) -> bool:
	return _event_engine.is_within_phase_b_window(duration_ms)


## Select the collective noun deterministically based on room topology seed.
func select_collective_noun(topology_seed: int, room_index: int) -> String:
	var noun: String = _event_engine.select_collective_noun(topology_seed, room_index)
	_burden_noun_index = _event_engine.get_noun_index(topology_seed, room_index)
	return noun


## Select a variant from the first-event pool.
func select_variant_first(run_seed: int, room_index: int, variant_state: int) -> Dictionary:
	return _event_engine.select_variant_first(run_seed, room_index, variant_state)


## Select a variant from the repeat-event pool.
func select_variant_repeat(run_seed: int, room_index: int, variant_state: int) -> Dictionary:
	return _event_engine.select_variant_repeat(run_seed, room_index, variant_state)


## Core Burden Event trigger.
func trigger_burden_event(
	run_seed: int, topology_seed: int, room_index: int, variant_state: int, is_first: bool
) -> BurdenEventResult:
	_burden_trigger_count += 1
	_lifetime_trigger_count += 1

	var result: BurdenEventResult = _event_engine.trigger_burden_event(
		run_seed, topology_seed, room_index, variant_state, is_first, _burden_trigger_count, _config
	)

	## AC-4: Persist updated noun index immediately after selection
	_burden_noun_index = result.noun_index

	## --- Caption scheduling ---
	_caption_bridge.schedule_burden_event_captions(result)

	burden_event_triggered.emit(result)
	_print_debug(
		(
			"burden_event #%d triggered (first=%s, noun_index=%d, variant=%s)"
			% [_burden_trigger_count, str(is_first), _burden_noun_index, result.phase_b_variant_id]
		)
	)
	return result


# ---------------------------------------------------------------------------
# Caption Integration (DON-225)
# ---------------------------------------------------------------------------


func _caption_node() -> Node:
	return _caption_bridge.get_caption_node()


## Public API: explicitly schedule a named transition caption (for emergency 3→0 override).
func schedule_transition_caption_explicit(transition_key: String) -> void:
	_caption_bridge.schedule_transition_caption_explicit(transition_key)


## Public API: report BD-CLIMB width from audio middleware so per-stem captions align.
func report_bd_climb_width(width_norm: float) -> void:
	_caption_bridge.report_bd_climb_width(width_norm)


## Public API: report explicit BD-CLIMB loop phase.
func report_bd_climb_phase(phase_norm: float) -> void:
	_caption_bridge.report_bd_climb_phase(phase_norm)


## Public API: enable/disable BD-CLIMB loop tracking.
func set_bd_climb_enabled(enabled: bool) -> void:
	_caption_bridge.set_bd_climb_enabled(enabled)


## Returns the current BD-CLIMB width caption strings from config.
func get_bd_climb_width_captions() -> Dictionary:
	return _caption_bridge.get_bd_climb_width_captions()


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenManager: %s" % msg)

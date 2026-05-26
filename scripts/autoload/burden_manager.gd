extends Node
class_name _BurdenManager

## BurdenManager
## Autoload that tracks sentient enemy kills and exposes the composite
## apparition lookup for the Burden Event (Memory Weight Threshold = 3).

const KILL_HISTORY_CAP: int = 3
const BURDEN_CONFIG_PATH := "res://config/burden_event_config.json"

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
var _noun_pool_size: int = 8
var _numbness_cap: int = 5

## Cached config sub-sections for fast lookup
var _phase_timing: Dictionary = {}
var _collective_nouns: Array = []
var _variants_first: Array = []
var _variants_repeat: Array = []
var _fallback_variant_id: String = "BE_B_FIRST_A"
var _template_first: String = ""
var _template_repeat: String = ""
var _count_first: String = "Three"
var _count_repeat: String = "More"
var _numbness_localization_key: String = "BE_NUMBNESS_CAP"

## Caption trigger cache (DON-225)
var _caption_transitions: Dictionary = {}
var _caption_channel_isolation: bool = true
var _caption_tolerance_sec: float = 0.2
var _bd_climb_config: Dictionary = {}

## MWT Matrix (DON-222)
var _mwt_matrix_script := preload("res://ui/framework/mwt_caption_matrix.gd")
var _mwt_matrix: Node = null


func _ready() -> void:
	_load_burden_config()
	_mwt_matrix = _mwt_matrix_script.new()


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
	_phase_timing = _config.get("phase_timing_ms", {})
	_collective_nouns = _config.get("collective_nouns", [])
	_noun_pool_size = _collective_nouns.size()
	if _noun_pool_size == 0:
		_noun_pool_size = 8  # guard against empty config

	var selection: Dictionary = _config.get("selection", {})
	_fallback_variant_id = selection.get("fallback_variant_id", "BE_B_FIRST_A")

	var numbness: Dictionary = _config.get("numbness_cap", {})
	_numbness_cap = numbness.get("trigger_count", 5)
	_numbness_localization_key = numbness.get("localization_key", "BE_NUMBNESS_CAP")

	var phases: Dictionary = _config.get("phases", {})
	var phase_b: Dictionary = phases.get("B", {})
	_variants_first = phase_b.get("variants_first", [])
	_variants_repeat = phase_b.get("variants_repeat", [])
	_template_first = (
		phase_b
		. get(
			"template_first",
			"{count} {collective_noun} of their own small truths. You hold them now. That is the burden."
		)
	)
	_template_repeat = phase_b.get(
		"template_repeat", "{count} {collective_noun}. The burden holds."
	)
	_count_first = phase_b.get("count_first", "Three")
	_count_repeat = phase_b.get("count_repeat", "More")

	## Load caption trigger metadata (DON-225)
	var caption_cfg: Dictionary = _config.get("caption_triggers", {})
	_caption_transitions = caption_cfg.get("transitions", {})
	_caption_channel_isolation = caption_cfg.get("channel_isolation", true)
	_caption_tolerance_sec = caption_cfg.get("timing_tolerance_sec", 0.2)
	_bd_climb_config = _config.get("bd_climb", {})


func _apply_defaults() -> void:
	## Hard-coded defaults mirroring burden-event-keyed.json v1.0.0
	_noun_pool_size = 8
	_numbness_cap = 5
	_collective_nouns = [
		"keepers", "bearers", "remnants", "echoes", "carriers", "vessels", "witnesses", "threads"
	]
	_fallback_variant_id = "BE_B_FIRST_A"
	_template_first = "{count} {collective_noun} of their own small truths. You hold them now. That is the burden."
	_template_repeat = "{count} {collective_noun}. The burden holds."
	_count_first = "Three"
	_count_repeat = "More"
	_numbness_localization_key = "BE_NUMBNESS_CAP"
	_variants_first = [
		{
			"id": "BE_B_FIRST_A",
			"text":
			"Three keepers of their own small truths. You hold them now. That is the burden.",
			"localization_key": "BE_B_FIRST_A"
		},
		{
			"id": "BE_B_FIRST_B",
			"text":
			"Three echoes, and the world is quieter for their leaving. You carry what remains.",
			"localization_key": "BE_B_FIRST_B"
		},
		{
			"id": "BE_B_FIRST_C",
			"text":
			"Three bearers, each walking their own uncertain path. That path ends with you.",
			"localization_key": "BE_B_FIRST_C"
		},
	]
	_variants_repeat = [
		{
			"id": "BE_B_REPEAT_R1",
			"text": "More remnants. The burden holds.",
			"localization_key": "BE_B_REPEAT_R1"
		},
		{
			"id": "BE_B_REPEAT_R2",
			"text": "More echoes. The world does not forget.",
			"localization_key": "BE_B_REPEAT_R2"
		},
	]


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
				int(flags["burden_noun_index"]), 0, _noun_pool_size - 1
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
		_schedule_mwt_transition_caption(old_level, new_level, is_emergency)
		_schedule_mwt_state_caption(new_level)

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
	return _burden_trigger_count >= _numbness_cap


## Returns the localization key for the numbness-cap rule (for UI / captions).
func get_numbness_localization_key() -> String:
	return _numbness_localization_key


## Phase B timing window validation helper.
## Returns true if the given duration (ms) falls inside the configured window [min, max].
func is_within_phase_b_window(duration_ms: int) -> bool:
	var min_ms: int = _phase_timing.get("B_window_min", 10000)
	var max_ms: int = _phase_timing.get("B_window_max", 40000)
	return duration_ms >= min_ms and duration_ms <= max_ms


## Select the collective noun deterministically based on room topology seed.
## Formula: SeedGovernance.modulo_from_seed(topology_seed, "NOUN", noun_pool_size)
## The selected noun is persisted across runs via burden_noun_index.
func select_collective_noun(topology_seed: int, room_index: int) -> String:
	var idx: int = SeedGovernance.modulo_from_seed(
		topology_seed, "NOUN" + str(room_index), _noun_pool_size
	)
	_burden_noun_index = idx
	if _collective_nouns.is_empty():
		return "keepers"  # fallback
	return str(_collective_nouns[idx])


## Select a variant from the first-event pool.
## Formula: hash(run_seed + room_index + variant_state) mod pool_size
## Falls back to the variant marked default (fallback_variant_id) if out of range.
func select_variant_first(run_seed: int, room_index: int, variant_state: int) -> Dictionary:
	var pool_size: int = _variants_first.size()
	if pool_size == 0:
		return {}
	var idx: int = SeedGovernance.modulo_from_seed(
		run_seed, str(room_index) + "VAR" + str(variant_state), pool_size
	)
	var result: Dictionary = _variants_first[idx]
	if not result.is_empty():
		return result.duplicate()
	## Fallback: scan for fallback_variant_id
	for v: Variant in _variants_first:
		if v is Dictionary and v.get("id", "") == _fallback_variant_id:
			return v.duplicate()
	return _variants_first[0].duplicate()


## Select a variant from the repeat-event pool.
func select_variant_repeat(run_seed: int, room_index: int, variant_state: int) -> Dictionary:
	var pool_size: int = _variants_repeat.size()
	if pool_size == 0:
		return {}
	var idx: int = SeedGovernance.modulo_from_seed(
		run_seed, str(room_index) + "VAR" + str(variant_state), pool_size
	)
	var result: Dictionary = _variants_repeat[idx]
	if not result.is_empty():
		return result.duplicate()
	return _variants_repeat[0].duplicate()


## Core Burden Event trigger.
## Call from RunManager / encounter system when the Burden Event fires.
##
## Parameters:
##   run_seed          — deterministic run seed (from RunManager.run_seed)
##   topology_seed     — room topology seed (from room_queue[i].topology_seed)
##   room_index        — current room index in run
##   variant_state     — caller-provided disambiguation int (e.g., 0, 1, 2...)
##   is_first          — true if this is the first Burden Event in the run
##
## Returns: BurdenEventResult with all phase data, localization keys, and silent flag.
func trigger_burden_event(
	run_seed: int, topology_seed: int, room_index: int, variant_state: int, is_first: bool
) -> BurdenEventResult:
	_burden_trigger_count += 1
	_lifetime_trigger_count += 1

	var result := BurdenEventResult.new()
	result.trigger_count = _burden_trigger_count
	result.is_first = is_first
	result.numbness_cap_reached = is_numb()
	result.localization_key_suffix = (
		_numbness_localization_key if result.numbness_cap_reached else ""
	)

	## --- Phase A (Stillness) ---
	result.phase_a_duration_ms = int(_phase_timing.get("A", 10000))
	result.phase_a_localization_key = "BE_PHASE_A"

	## --- Phase B (Witness / Silent) ---
	var noun: String = ""
	if result.numbness_cap_reached:
		## AC-3: Silent Phase B after trigger_count >= 5
		result.phase_b_text = ""
		result.phase_b_duration_ms = int(_phase_timing.get("B_repeat", 10000))
		result.phase_b_localization_key = _numbness_localization_key
		result.phase_b_variant_id = ""
		result.phase_b_cadence_ms = 0
		_print_debug("burden event #%d → SILENT (numbness cap)" % _burden_trigger_count)
	else:
		noun = select_collective_noun(topology_seed, room_index)
		var variant: Dictionary
		if is_first:
			variant = select_variant_first(run_seed, room_index, variant_state)
			result.phase_b_duration_ms = int(_phase_timing.get("B_first", 15000))
			result.phase_b_text = _expand_template(_template_first, _count_first, noun, variant)
		else:
			variant = select_variant_repeat(run_seed, room_index, variant_state)
			result.phase_b_duration_ms = int(_phase_timing.get("B_repeat", 10000))
			result.phase_b_text = _expand_template(_template_repeat, _count_repeat, noun, variant)
		result.phase_b_localization_key = str(variant.get("localization_key", ""))
		result.phase_b_variant_id = str(variant.get("id", ""))
		result.phase_b_cadence_ms = int(variant.get("cadence_ms_estimate", 0))
		result.phase_b_word_count = int(variant.get("word_count", 0))

	## AC-4: Persist updated noun index immediately after selection
	result.noun_index = _burden_noun_index

	## --- Phase C (Choiceless Choice) ---
	var phase_c: Dictionary = _config.get("phases", {}).get("C", {})
	result.phase_c_text = str(phase_c.get("text", "The memory passes into you."))
	result.phase_c_duration_ms = int(phase_c.get("C", 15000))
	result.phase_c_hold_ms = int(phase_c.get("C_hold", 5000))
	result.phase_c_mandatory_input_hold_ms = int(phase_c.get("C_mandatory_input_hold", 5000))
	result.phase_c_localization_key = str(phase_c.get("localization_key", "BE_PHASE_C"))
	result.phase_c_legend_template = str(phase_c.get("legend_line_template", ""))

	## --- Phase D (Return) ---
	var phase_d: Dictionary = _config.get("phases", {}).get("D", {})
	result.phase_d_text = str(phase_d.get("text", "You exhale. The embers cool."))
	result.phase_d_duration_ms = int(phase_d.get("D", 2000))
	result.phase_d_localization_key = str(phase_d.get("localization_key", "BE_PHASE_D"))

	## AC-1: Validate Phase B timing window
	if not result.numbness_cap_reached and not is_within_phase_b_window(result.phase_b_duration_ms):
		push_warning(
			(
				"BurdenManager: Phase B duration %d ms is outside the configured 10–40 s window."
				% result.phase_b_duration_ms
			)
		)

	## --- Caption scheduling (DON-225) ---
	_schedule_burden_event_captions(result)

	burden_event_triggered.emit(result)
	_print_debug(
		(
			"burden_event #%d triggered (first=%s, noun=%s, variant=%s)"
			% [
				_burden_trigger_count,
				str(is_first),
				noun if not result.numbness_cap_reached else "SILENT",
				result.phase_b_variant_id
			]
		)
	)
	return result


## Expand a template string with count, collective_noun, and variant text.
## If a specific variant text is provided, return that directly (production text).
## Otherwise perform basic string substitution.
func _expand_template(
	template_str: String, count: String, noun: String, variant: Dictionary
) -> String:
	if variant.has("text") and variant["text"] is String and not variant["text"].is_empty():
		return variant["text"]
	var out: String = template_str.replace("{count}", count)
	out = out.replace("{collective_noun}", noun)
	return out


# ---------------------------------------------------------------------------
# Debug
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Caption Integration (DON-225)
# ---------------------------------------------------------------------------


func _caption_node() -> Node:
	return get_node_or_null("/root/CaptionManager")


func _schedule_mwt_transition_caption(
	from_level: int, to_level: int, is_emergency: bool = false
) -> void:
	var cm: Node = _caption_node()
	if cm == null or _mwt_matrix == null:
		return

	var data: Resource = _mwt_matrix.get_transition_caption(from_level, to_level, is_emergency)
	if data == null:
		return

	if cm.has_method("schedule") and not str(data.get("text")).is_empty():
		cm.call(
			"schedule",
			data.get("text"),
			1,
			data.get("offset_sec"),
			data.get("duration_sec"),
			data.get("curve"),
			data.get("localization_key")
		)
		_print_debug(
			(
				"scheduled MWT transition caption %d->%d (emergency=%s)"
				% [from_level, to_level, str(is_emergency)]
			)
		)


func _schedule_mwt_state_caption(level: int) -> void:
	var cm: Node = _caption_node()
	if cm == null or _mwt_matrix == null:
		return

	var data: Resource = _mwt_matrix.get_state_caption(level)
	if data == null:
		return

	if cm.has_method("schedule"):
		cm.call(
			"schedule",
			data.get("text"),
			1,
			0.0,
			data.get("duration_sec"),
			data.get("curve"),
			data.get("localization_key")
		)
		_print_debug("scheduled MWT state caption for level %d" % level)


## Public API: explicitly schedule a named transition caption (for emergency 3→0 override).
func schedule_transition_caption_explicit(transition_key: String) -> void:
	var cm := _caption_node()
	if cm == null:
		return
	var data: Dictionary = _caption_transitions.get(transition_key, {})
	if data.is_empty():
		push_warning("BurdenManager: unknown caption transition key '%s'" % transition_key)
		return
	var text: String = str(data.get("text", ""))
	if text.is_empty():
		return
	var offset_sec: float = float(data.get("offset_sec", 0.0))
	var duration_sec: float = float(data.get("duration_sec", 2.0))
	var curve_str: String = str(data.get("curve", "LINEAR"))
	var loc_key: String = str(data.get("localization_key", ""))
	var curve: int = _curve_from_string(curve_str)
	if cm.has_method("schedule"):
		cm.call("schedule", text, 1, offset_sec, duration_sec, curve, loc_key)
		_print_debug("scheduled explicit transition caption %s" % transition_key)


## Schedule captions tied to a BurdenEventResult phases.
func _schedule_burden_event_captions(result: BurdenEventResult) -> void:
	var cm := _caption_node()
	if cm == null:
		return
	## Phase A: stillness caption (BURDEN channel, per DON-222 requirement)
	if not result.phase_a_localization_key.is_empty() and cm.has_method("schedule"):
		## Per DON-222: Phase A caption fires at the exact moment control is seized.
		cm.call(
			"schedule",
			"[The world stills]",
			1,
			0.0,
			result.phase_a_duration_ms / 1000.0,
			0,
			result.phase_a_localization_key + "_CAP"
		)  ## Channel.BURDEN = 1

	## Numbness cap caption
	if result.numbness_cap_reached and cm.has_method("schedule"):
		cm.call("schedule", "[The burden is silent]", 1, 0.0, 4.0, 1, "BE_CAP_NUMBNESS")

	## Phase B: the witness text (BURDEN channel)
	if not result.phase_b_text.is_empty() and cm.has_method("schedule"):
		var b_curve: int = 2 if result.is_first else 2  ## EXPONENTIAL for first, same for repeat
		cm.call(
			"schedule",
			result.phase_b_text,
			1,
			0.0,
			result.phase_b_duration_ms / 1000.0,
			b_curve,
			result.phase_b_localization_key
		)

	## Phase C: choiceless choice (BURDEN channel)
	if not result.phase_c_text.is_empty() and cm.has_method("schedule"):
		cm.call(
			"schedule",
			result.phase_c_text,
			1,
			0.0,
			result.phase_c_duration_ms / 1000.0,
			1,
			result.phase_c_localization_key
		)  ## LINEAR

	## Phase D: return (BURDEN channel, short fade)
	if not result.phase_d_text.is_empty() and cm.has_method("schedule"):
		cm.call(
			"schedule",
			result.phase_d_text,
			1,
			0.0,
			result.phase_d_duration_ms / 1000.0,
			1,
			result.phase_d_localization_key
		)


## Map curve string name to CaptionManager.CaptionCurve enum.
func _curve_from_string(curve_str: String) -> int:
	match curve_str.to_upper():
		"INSTANT":
			return 0
		"LINEAR":
			return 1
		"EXPONENTIAL":
			return 2
		"LOGARITHMIC":
			return 3
		"STEEP_EXPONENTIAL":
			return 4
		_:
			return 1  ## default LINEAR


## Public API: report BD-CLIMB width from audio middleware so per-stem captions align.
func report_bd_climb_width(width_norm: float) -> void:
	var cm := _caption_node()
	if cm and cm.has_method("report_bd_climb_width"):
		cm.call("report_bd_climb_width", width_norm)
		_print_debug("reported BD-CLIMB width=%.3f" % width_norm)


## Public API: report explicit BD-CLIMB loop phase.
func report_bd_climb_phase(phase_norm: float) -> void:
	var cm := _caption_node()
	if cm and cm.has_method("report_bd_climb_phase"):
		cm.call("report_bd_climb_phase", phase_norm)


## Public API: enable/disable BD-CLIMB loop tracking.
func set_bd_climb_enabled(enabled: bool) -> void:
	var cm := _caption_node()
	if cm and cm.has_method("set_bd_climb_enabled"):
		cm.call("set_bd_climb_enabled", enabled)


## Returns the current BD-CLIMB width caption strings from config.
func get_bd_climb_width_captions() -> Dictionary:
	return _bd_climb_config.get(
		"width_captions",
		{
			"expanding": {"text": "[The walls widen]", "localization_key": "BE_CAP_CLIMB_EXPAND"},
			"converging":
			{"text": "[Everything converges]", "localization_key": "BE_CAP_CLIMB_CONVERGE"}
		}
	)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenManager: %s" % msg)


# ---------------------------------------------------------------------------
# Data Records
# ---------------------------------------------------------------------------


class BurdenKillRecord:
	extends RefCounted
	var enemy_id: String
	var display_name: String
	var timestamp_ms: int

	func _init(p_id: String, p_name: String, p_time: int) -> void:
		enemy_id = p_id
		display_name = p_name
		timestamp_ms = p_time


## Structured result emitted when a Burden Event triggers.
class BurdenEventResult:
	extends RefCounted
	## Metadata
	var trigger_count: int = 0
	var is_first: bool = false
	var numbness_cap_reached: bool = false
	var localization_key_suffix: String = ""
	var noun_index: int = 0

	## Phase A — The Stillness
	var phase_a_duration_ms: int = 10000
	var phase_a_localization_key: String = "BE_PHASE_A"

	## Phase B — The Witness (may be silent)
	var phase_b_text: String = ""
	var phase_b_duration_ms: int = 0
	var phase_b_localization_key: String = ""
	var phase_b_variant_id: String = ""
	var phase_b_cadence_ms: int = 0
	var phase_b_word_count: int = 0

	## Phase C — The Choiceless Choice
	var phase_c_text: String = ""
	var phase_c_duration_ms: int = 15000
	var phase_c_hold_ms: int = 5000
	var phase_c_mandatory_input_hold_ms: int = 5000
	var phase_c_localization_key: String = "BE_PHASE_C"
	var phase_c_legend_template: String = ""

	## Phase D — Return to Tactical
	var phase_d_text: String = ""
	var phase_d_duration_ms: int = 2000
	var phase_d_localization_key: String = "BE_PHASE_D"

extends RefCounted
class_name _BurdenEventEngine

## BurdenEventEngine
## Handles deterministic event generation and variant selection for Burden Events.

const BurdenEventResult = preload("res://scripts/burden/burden_event_result.gd")

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
var _noun_pool_size: int = 8
var _numbness_cap: int = 5


func apply_config(config: Dictionary) -> void:
	_phase_timing = config.get("phase_timing_ms", {})
	_collective_nouns = config.get("collective_nouns", [])
	_noun_pool_size = _collective_nouns.size()
	if _noun_pool_size == 0:
		_noun_pool_size = 8  # guard against empty config

	var selection: Dictionary = config.get("selection", {})
	_fallback_variant_id = selection.get("fallback_variant_id", "BE_B_FIRST_A")

	var numbness: Dictionary = config.get("numbness_cap", {})
	_numbness_cap = numbness.get("trigger_count", 5)
	_numbness_localization_key = numbness.get("localization_key", "BE_NUMBNESS_CAP")

	var phases: Dictionary = config.get("phases", {})
	var phase_b: Dictionary = phases.get("B", {})
	_variants_first = phase_b.get("variants_first", [])
	_variants_repeat = phase_b.get("variants_repeat", [])

	# Try to fetch templates from DialogueManager first
	var dm := AutoloadHelper.get_autoload("DialogueManager")
	if dm:
		var t_first: Dictionary = dm.call("get_dialogue", "BE_B_TEMPLATE_FIRST")
		if not t_first.is_empty():
			_template_first = t_first.get("text", "")

		var t_repeat: Dictionary = dm.call("get_dialogue", "BE_B_TEMPLATE_REPEAT")
		if not t_repeat.is_empty():
			_template_repeat = t_repeat.get("text", "")

	if _template_first.is_empty():
		_template_first = (
			phase_b
			. get(
				"template_first",
				"{count} {collective_noun} of their own small truths. You hold them now. That is the burden."
			)
		)
	if _template_repeat.is_empty():
		_template_repeat = phase_b.get(
			"template_repeat", "{count} {collective_noun}. The burden holds."
		)
	_count_first = phase_b.get("count_first", "Three")
	_count_repeat = phase_b.get("count_repeat", "More")


func apply_defaults() -> void:
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


func get_numbness_cap() -> int:
	return _numbness_cap


func get_numbness_localization_key() -> String:
	return _numbness_localization_key


func get_noun_pool_size() -> int:
	return _noun_pool_size


## Phase B timing window validation helper.
func is_within_phase_b_window(duration_ms: int) -> bool:
	var min_ms: int = _phase_timing.get("B_window_min", 10000)
	var max_ms: int = _phase_timing.get("B_window_max", 40000)
	return duration_ms >= min_ms and duration_ms <= max_ms


## Select the collective noun deterministically based on room topology seed.
func select_collective_noun(topology_seed: int, room_index: int) -> String:
	var idx: int = SeedGovernance.modulo_from_seed(
		topology_seed, "NOUN" + str(room_index), _noun_pool_size
	)
	if _collective_nouns.is_empty():
		return "keepers"  # fallback
	return str(_collective_nouns[idx])


## Internal helper to get the noun index for persistence
func get_noun_index(topology_seed: int, room_index: int) -> int:
	return SeedGovernance.modulo_from_seed(topology_seed, "NOUN" + str(room_index), _noun_pool_size)


## Select a variant from the first-event pool.
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


## Core Burden Event trigger logic.
func trigger_burden_event(
	run_seed: int,
	topology_seed: int,
	room_index: int,
	variant_state: int,
	is_first: bool,
	trigger_count: int,
	config: Dictionary
) -> BurdenEventResult:
	var result := BurdenEventResult.new()
	result.trigger_count = trigger_count
	result.is_first = is_first
	result.numbness_cap_reached = trigger_count >= _numbness_cap
	result.localization_key_suffix = (
		_numbness_localization_key if result.numbness_cap_reached else ""
	)

	var dm := AutoloadHelper.get_autoload("DialogueManager")

	## --- Phase A (Stillness) ---
	result.phase_a_duration_ms = int(_phase_timing.get("A", 10000))
	result.phase_a_localization_key = "BE_PHASE_A"

	## --- Phase B (Witness / Silent) ---
	var noun: String = ""
	if result.numbness_cap_reached:
		result.phase_b_text = ""
		result.phase_b_duration_ms = int(_phase_timing.get("B_repeat", 10000))
		result.phase_b_localization_key = _numbness_localization_key
		result.phase_b_variant_id = ""
		result.phase_b_cadence_ms = 0
	else:
		noun = select_collective_noun(topology_seed, room_index)
		var variant: Dictionary
		if is_first:
			variant = select_variant_first(run_seed, room_index, variant_state)
			result.phase_b_duration_ms = int(_phase_timing.get("B_first", 15000))

			var variant_id: String = str(variant.get("id", ""))
			if dm and dm.call("has_dialogue", variant_id):
				var d: Dictionary = dm.call("get_dialogue", variant_id)
				result.phase_b_text = _expand_template(_template_first, _count_first, noun, d)
			else:
				result.phase_b_text = _expand_template(_template_first, _count_first, noun, variant)
		else:
			variant = select_variant_repeat(run_seed, room_index, variant_state)
			result.phase_b_duration_ms = int(_phase_timing.get("B_repeat", 10000))

			var variant_id: String = str(variant.get("id", ""))
			if dm and dm.call("has_dialogue", variant_id):
				var d: Dictionary = dm.call("get_dialogue", variant_id)
				result.phase_b_text = _expand_template(_template_repeat, _count_repeat, noun, d)
			else:
				result.phase_b_text = _expand_template(
					_template_repeat, _count_repeat, noun, variant
				)

		result.phase_b_localization_key = str(variant.get("localization_key", ""))
		result.phase_b_variant_id = str(variant.get("id", ""))
		result.phase_b_cadence_ms = int(variant.get("cadence_ms_estimate", 0))
		result.phase_b_word_count = int(variant.get("word_count", 0))

	result.noun_index = get_noun_index(topology_seed, room_index)

	## --- Phase C (Choiceless Choice) ---
	var phases: Dictionary = config.get("phases", {})
	var phase_c: Dictionary = phases.get("C", {})

	if dm and dm.call("has_dialogue", "BE_PHASE_C"):
		var d: Dictionary = dm.call("get_dialogue", "BE_PHASE_C")
		result.phase_c_text = d.get("text", "The memory passes into you.")
	else:
		result.phase_c_text = str(phase_c.get("text", "The memory passes into you."))
	result.phase_c_duration_ms = int(phase_c.get("C", 15000))
	result.phase_c_hold_ms = int(phase_c.get("C_hold", 5000))
	result.phase_c_mandatory_input_hold_ms = int(phase_c.get("C_mandatory_input_hold", 5000))
	result.phase_c_localization_key = str(phase_c.get("localization_key", "BE_PHASE_C"))
	result.phase_c_legend_template = str(phase_c.get("legend_line_template", ""))

	## --- Phase D (Return) ---
	var phase_d: Dictionary = phases.get("D", {})

	if dm and dm.call("has_dialogue", "BE_PHASE_D"):
		var d: Dictionary = dm.call("get_dialogue", "BE_PHASE_D")
		result.phase_d_text = d.get("text", "You exhale. The embers cool.")
	else:
		result.phase_d_text = str(phase_d.get("text", "You exhale. The embers cool."))
	result.phase_d_duration_ms = int(phase_d.get("D", 2000))
	result.phase_d_localization_key = str(phase_d.get("localization_key", "BE_PHASE_D"))

	## AC-1: Validate Phase B timing window
	if not result.numbness_cap_reached and not is_within_phase_b_window(result.phase_b_duration_ms):
		push_warning(
			(
				"BurdenEventEngine: Phase B duration %d ms is outside the configured 10–40 s window."
				% result.phase_b_duration_ms
			)
		)

	return result


func _expand_template(
	template_str: String, count: String, noun: String, variant: Dictionary
) -> String:
	if variant.has("text") and variant["text"] is String and not variant["text"].is_empty():
		return variant["text"]
	var out: String = template_str.replace("{count}", count)
	out = out.replace("{collective_noun}", noun)
	return out

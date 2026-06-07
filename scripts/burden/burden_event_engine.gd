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
	var dm: Node = AutoloadHelper.get_autoload("DialogueManager")
	if dm:
		var t_first: Dictionary = dm.call("getDialogue", "BE_B_TEMPLATE_FIRST")
		if not t_first.is_empty():
			_template_first = t_first.get("text", "")

		var t_repeat: Dictionary = dm.call("getDialogue", "BE_B_TEMPLATE_REPEAT")
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


func get_noun_pool
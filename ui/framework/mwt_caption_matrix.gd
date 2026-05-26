class_name _MWTCaptionMatrix
extends Node

## MWTCaptionMatrix
## Manages the state and transition captions for Memory Weight Thresholds (0-3).
## Reference: burden-event-captioning-spec.md §3, §4

const MWTCaptionEntry: GDScript = preload("res://ui/framework/mwt_caption_entry.gd")

var state_captions: Dictionary = {}
var transition_captions: Dictionary = {}

func _init() -> void:
	_setup_states()
	_setup_transitions()

func _setup_states() -> void:
	var states: Dictionary = {
		0: {"text": "[A low rumble spreads beneath you]", "loc": "BE_MWT_0"},
		1: {"text": "[Machinery churns in the walls]", "loc": "BE_MWT_1"},
		2: {"text": "[Pressure builds]", "loc": "BE_MWT_2"},
		3: {"text": "[The breaking point nears]", "loc": "BE_MWT_3"}
	}
	for level: int in states.keys():
		var entry: MWTCaptionEntry = MWTCaptionEntry.new()
		var d: Dictionary = states[level] as Dictionary
		entry.text = str(d["text"])
		entry.localization_key = str(d["loc"])
		entry.duration_sec = 3.0
		state_captions[level] = entry

func _setup_transitions() -> void:
	var transitions: Dictionary = {
		"0->1": {"text": "[The world stills]", "loc": "BE_CAP_0_TO_1", "curve": 3, "offset": 2.0}, # EXPONENTIAL
		"1->2": {"text": "[Machinery grinds]", "loc": "BE_CAP_1_TO_2", "curve": 1, "offset": 0.0}, # LINEAR
		"2->3": {"text": "[The weight gathers]", "loc": "BE_CAP_2_TO_3", "curve": 3, "offset": 2.5},
		"3->2": {"text": "[The pressure recedes]", "loc": "BE_CAP_3_TO_2", "curve": 1, "offset": 0.0},
		"2->1": {"text": "[The memory loosens]", "loc": "BE_CAP_2_TO_1", "curve": 1, "offset": 1.0},
		"1->0": {"text": "[The embers cool]", "loc": "BE_CAP_1_TO_0", "curve": 1, "offset": 1.0},
		"3->0": {"text": "[The burden fades slowly]", "loc": "BE_CAP_3_TO_0_NORMAL", "curve": 2, "offset": 2.5, "dur": 5.0}, # LOGARITHMIC
		"3->0_emergency": {"text": "[The burden drops]", "loc": "BE_CAP_3_TO_0_EMERGENCY", "curve": 4, "offset": 0.5, "dur": 1.5} # STEEP_EXPONENTIAL
	}
	for key: String in transitions.keys():
		var entry: MWTCaptionEntry = MWTCaptionEntry.new()
		var d: Dictionary = transitions[key] as Dictionary
		entry.text = str(d["text"])
		entry.localization_key = str(d["loc"])
		entry.curve = int(d.get("curve", 1))
		entry.offset_sec = float(d.get("offset", 0.0))
		entry.duration_sec = float(d.get("dur", 2.0))
		transition_captions[key] = entry

func get_state_caption(mwt_level: int) -> MWTCaptionEntry:
	return state_captions.get(mwt_level, null) as MWTCaptionEntry

func get_transition_caption(from_level: int, to_level: int, is_emergency: bool = false) -> MWTCaptionEntry:
	var key: String = "%d->%d" % [from_level, to_level]
	if is_emergency and from_level == 3 and to_level == 0:
		key = "3->0_emergency"
	elif to_level == 0 and from_level == 3:
		key = "3->0"
	return transition_captions.get(key, null) as MWTCaptionEntry

extends Node

## MWTCaptionMatrix
## Manages the state and transition captions for Memory Weight Thresholds (0-3).
## Reference: burden-event-captioning-spec.md §3, §4

const STATE_CAPTIONS = {
	0: {"text": "[A low rumble spreads beneath you]", "loc": "BE_MWT_0"},
	1: {"text": "[Machinery churns in the walls]", "loc": "BE_MWT_1"},
	2: {"text": "[Pressure builds]", "loc": "BE_MWT_2"},
	3: {"text": "[The breaking point nears]", "loc": "BE_MWT_3"}
}

const TRANSITION_CAPTIONS = {
	"0->1": {"text": "[The world stills]", "loc": "BE_CAP_0_TO_1", "curve": CaptionManager.CaptionCurve.EXPONENTIAL, "offset": 2.0},
	"1->2": {"text": "[Machinery grinds]", "loc": "BE_CAP_1_TO_2", "curve": CaptionManager.CaptionCurve.LINEAR, "offset": 0.0},
	"2->3": {"text": "[The weight gathers]", "loc": "BE_CAP_2_TO_3", "curve": CaptionManager.CaptionCurve.EXPONENTIAL, "offset": 2.5},
	"3->2": {"text": "[The pressure recedes]", "loc": "BE_CAP_3_TO_2", "curve": CaptionManager.CaptionCurve.LINEAR, "offset": 0.0},
	"2->1": {"text": "[The memory loosens]", "loc": "BE_CAP_2_TO_1", "curve": CaptionManager.CaptionCurve.LINEAR, "offset": 1.0},
	"1->0": {"text": "[The embers cool]", "loc": "BE_CAP_1_TO_0", "curve": CaptionManager.CaptionCurve.LINEAR, "offset": 1.0},
	"3->0": {"text": "[The burden fades slowly]", "loc": "BE_CAP_3_TO_0_NORMAL", "curve": CaptionManager.CaptionCurve.LOGARITHMIC, "offset": 2.5, "dur": 5.0}
}

func get_state_caption(mwt_level: int) -> Dictionary:
	return STATE_CAPTIONS.get(mwt_level, {})

func get_transition_caption(from_level: int, to_level: int) -> Dictionary:
	var key = "%d->%d" % [from_level, to_level]
	if to_level == 0 and from_level == 3:
		key = "3->0"
	return TRANSITION_CAPTIONS.get(key, {})

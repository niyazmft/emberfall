extends RefCounted
## BurdenCaptionBridge
## Coordinates between BurdenManager and CaptionManager for MWT and event captions.

const BurdenEventResult = preload("res://scripts/burden/burden_event_result.gd")
const MWTCaptionEntry = preload("res://ui/framework/mwt_caption_entry.gd")

var _caption_transitions: Dictionary = {}
var _caption_channel_isolation: bool = true
var _caption_tolerance_sec: float = 0.2
var _bd_climb_config: Dictionary = {}
var _mwt_matrix: _MWTCaptionMatrix = null


func initialize(config: Dictionary, mwt_matrix: _MWTCaptionMatrix) -> void:
	var caption_cfg: Dictionary = config.get("caption_triggers", {})
	_caption_transitions = caption_cfg.get("transitions", {})
	_caption_channel_isolation = caption_cfg.get("channel_isolation", true)
	_caption_tolerance_sec = caption_cfg.get("timing_tolerance_sec", 0.2)
	_bd_climb_config = config.get("bd_climb", {})
	_mwt_matrix = mwt_matrix


func get_caption_node() -> _CaptionManager:
	return AutoloadHelper.caption_manager()


func schedule_mwt_transition_caption(
	from_level: int, to_level: int, is_emergency: bool = false
) -> void:
	var cm := get_caption_node()
	if cm == null or _mwt_matrix == null:
		return

	var data: MWTCaptionEntry = _mwt_matrix.get_transition_caption(
		from_level, to_level, is_emergency
	)
	if data == null:
		return

	if not str(data.get("text")).is_empty():
		cm.schedule(
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


func schedule_mwt_state_caption(level: int) -> void:
	var cm := get_caption_node()
	if cm == null or _mwt_matrix == null:
		return

	var data: MWTCaptionEntry = _mwt_matrix.get_state_caption(level)
	if data == null:
		return

	cm.schedule(
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
	var cm := get_caption_node()
	if cm == null:
		return
	var data: Dictionary = _caption_transitions.get(transition_key, {})
	if data.is_empty():
		push_warning("BurdenCaptionBridge: unknown caption transition key '%s'" % transition_key)
		return
	var text: String = str(data.get("text", ""))
	if text.is_empty():
		return
	var offset_sec: float = float(data.get("offset_sec", 0.0))
	var duration_sec: float = float(data.get("duration_sec", 2.0))
	var curve_str: String = str(data.get("curve", "LINEAR"))
	var loc_key: String = str(data.get("localization_key", ""))
	var curve: int = _curve_from_string(curve_str)
	cm.schedule(text, 1, offset_sec, duration_sec, curve, loc_key)
	_print_debug("scheduled explicit transition caption %s" % transition_key)


## Schedule captions tied to a BurdenEventResult phases.
func schedule_burden_event_captions(result: BurdenEventResult) -> void:
	var cm := get_caption_node()
	if cm == null:
		return
	## Phase A: stillness caption (BURDEN channel, per DON-222 requirement)
	if not result.phase_a_localization_key.is_empty():
		## Per DON-222: Phase A caption fires at the exact moment control is seized.
		cm.schedule(
			"[The world stills]",
			1,
			0.0,
			result.phase_a_duration_ms / 1000.0,
			0,
			result.phase_a_localization_key + "_CAP"
		)  ## Channel.BURDEN = 1

	## Numbness cap caption
	if result.numbness_cap_reached:
		cm.schedule("[The burden is silent]", 1, 0.0, 4.0, 1, "BE_CAP_NUMBNESS")

	## Phase B: the witness text (BURDEN channel)
	if not result.phase_b_text.is_empty():
		var b_curve: int = 2  ## EXPONENTIAL for first and repeat
		cm.schedule(
			result.phase_b_text,
			1,
			0.0,
			result.phase_b_duration_ms / 1000.0,
			b_curve,
			result.phase_b_localization_key
		)

	## Phase C: choiceless choice (BURDEN channel)
	if not result.phase_c_text.is_empty():
		cm.schedule(
			result.phase_c_text,
			1,
			0.0,
			result.phase_c_duration_ms / 1000.0,
			1,
			result.phase_c_localization_key
		)  ## LINEAR

	## Phase D: return (BURDEN channel, short fade)
	if not result.phase_d_text.is_empty():
		cm.schedule(
			result.phase_d_text,
			1,
			0.0,
			result.phase_d_duration_ms / 1000.0,
			1,
			result.phase_d_localization_key
		)


## Public API: report BD-CLIMB width from audio middleware so per-stem captions align.
func report_bd_climb_width(width_norm: float) -> void:
	var cm := get_caption_node()
	if cm:
		cm.report_bd_climb_width(width_norm)
		_print_debug("reported BD-CLIMB width=%.3f" % width_norm)


## Public API: report explicit BD-CLIMB loop phase.
func report_bd_climb_phase(phase_norm: float) -> void:
	var cm := get_caption_node()
	if cm:
		cm.report_bd_climb_phase(phase_norm)


## Public API: enable/disable BD-CLIMB loop tracking.
func set_bd_climb_enabled(enabled: bool) -> void:
	var cm := get_caption_node()
	if cm:
		cm.set_bd_climb_enabled(enabled)


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


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenCaptionBridge: %s" % msg)

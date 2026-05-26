extends Node
class_name _CaptionManager

## CaptionManager
## Autoload that manages closed-caption / subtitle events across channels.
##
## Responsibilities:
##   • Maintain independent caption channels (DIALOGUE, BURDEN, AMBIENT, SFX)
##   • Priority routing: higher-priority captions pre-empt lower ones on the
##     same display surface, but BURDEN is isolated (never shares a surface
##     with DIALOGUE) per §9 channel isolation.
##   • Schedule caption events with timing offsets and fade curves.
##   • Expose BD-CLIMB loop-phase gate for per-stem width-modulation sync.
##
## Reference: burden-event-captioning-spec.md §7, §9

# ── Channel Enum ───────────────────────────────────────────────────────────
enum Channel {
	DIALOGUE = 0,  ## NPC speech, player voice-over
	BURDEN = 1,  ## Burden Event world-voice captions (isolated surface)
	AMBIENT = 2,  ## Environmental / world narration
	SFX = 3,  ## Sound-effect captions (non-spatial for accessibility)
}

## Priority mapping: higher value = higher priority for pre-emption.
const CHANNEL_PRIORITY: Dictionary = {
	Channel.DIALOGUE: 1,
	Channel.BURDEN: 2,
	Channel.AMBIENT: 2,
	Channel.SFX: 1,
}

## Which channels share a display surface. BURDEN is ALWAYS isolated.
const CHANNEL_SURFACE_GROUP: Dictionary = {
	Channel.DIALOGUE: 0,
	Channel.BURDEN: 1,  ## isolated surface
	Channel.AMBIENT: 0,  ## shares with DIALOGUE
	Channel.SFX: 0,  ## shares with DIALOGUE
}

# ── Curve Types ────────────────────────────────────────────────────────────
enum CaptionCurve {
	INSTANT,  ## No fade; appear at full opacity
	LINEAR,  ## Constant rate fade-in / fade-out
	EXPONENTIAL,  ## Exponential fade-in (perceptual midpoint focus)
	LOGARITHMIC,  ## Logarithmic tail-off (slow decay)
	STEEP_EXPONENTIAL,  ## Rapid drop for emergency transitions
}

# ── Signals ────────────────────────────────────────────────────────────────
## Emitted when a caption event should be displayed.
signal caption_display_requested(event: CaptionEvent)

## Emitted when a caption event has completed its lifetime.
signal caption_completed(event: CaptionEvent)

## Emitted when the BD-CLIMB loop-phase width changes (for per-stem caption sync).
signal bd_climb_width_changed(width_norm: float, phase_norm: float)

## Emitted when a stem-specific transient event fires.
signal stem_transient(stem_id: String, event_id: String, intensity: float)

# ── Internal State ───────────────────────────────────────────────────────────
var _event_queue: Array[CaptionEvent] = []
var _active_events: Array[CaptionEvent] = []
var _time_source_sec: float = 0.0
var _last_stem_states: Dictionary = {}
var _bd_climb_loop_phase: float = 0.0  ## 0.0 → 1.0 within one BD-CLIMB cycle
var _bd_climb_width: float = 0.0  ## Normalized width 0.0 → 1.0
var _bd_climb_enabled: bool = false

# ── Configuration ────────────────────────────────────────────────────────────
var _stem_ids: PackedStringArray = PackedStringArray(
	["BD-BASS", "BD-MECH", "BD-STRESS", "BD-CLIMB"]
)
var _caption_timing_tolerance_sec: float = 0.2  ## ±0.2 s per acceptance criteria


# ── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_print_debug("CaptionManager ready")


func _process(delta: float) -> void:
	_time_source_sec += delta
	_process_queue()
	_update_active_events(delta)
	_update_bd_climb_loop(delta)


# ── Public API: Caption Events ─────────────────────────────────────────────


## Schedule a caption event. Returns the event handle for cancellation.
func schedule(
	p_text: String,
	p_channel: Channel,
	p_offset_sec: float,
	p_duration_sec: float,
	p_curve: CaptionCurve = CaptionCurve.LINEAR,
	p_localization_key: String = ""
) -> CaptionEvent:
	var event := CaptionEvent.new()
	event.text = p_text
	event.channel = p_channel
	event.offset_sec = p_offset_sec
	event.duration_sec = p_duration_sec
	event.curve = p_curve
	event.localization_key = p_localization_key
	event.schedule_time_sec = _time_source_sec
	event.priority = CHANNEL_PRIORITY.get(p_channel, 0)
	event.surface_group = CHANNEL_SURFACE_GROUP.get(p_channel, 0)

	_event_queue.append(event)
	# Sort by trigger time so earliest events are processed first.
	_event_queue.sort_custom(
		func(a: CaptionEvent, b: CaptionEvent) -> bool:
			return a.trigger_time_sec() < b.trigger_time_sec()
	)
	_print_debug(
		(
			"scheduled caption [channel=%d, offset=%.2f, dur=%.2f]: %s"
			% [p_channel, p_offset_sec, p_duration_sec, p_text]
		)
	)
	return event


## Cancel a previously scheduled event. Returns true if found and removed.
func cancel(event: CaptionEvent) -> bool:
	var idx_queue: int = _event_queue.find(event)
	if idx_queue >= 0:
		_event_queue.remove_at(idx_queue)
		return true
	var idx_active: int = _active_events.find(event)
	if idx_active >= 0:
		_active_events.remove_at(idx_active)
		caption_completed.emit(event)
		return true
	return false


## Cancel all scheduled and active events for a specific channel.
func cancel_channel(channel: Channel) -> void:
	_event_queue = _event_queue.filter(func(e: CaptionEvent) -> bool: return e.channel != channel)
	var to_remove: Array[CaptionEvent] = []
	for e: CaptionEvent in _active_events:
		if e.channel == channel:
			to_remove.append(e)
	for e: CaptionEvent in to_remove:
		_active_events.erase(e)
		caption_completed.emit(e)


## Flush all pending and active captions.
func flush_all() -> void:
	for e: CaptionEvent in _active_events.duplicate():
		_active_events.erase(e)
		caption_completed.emit(e)
	_event_queue.clear()


# ── Public API: BD-CLIMB Loop-Phase Gate ────────────────────────────────────


## Enable or disable BD-CLIMB width-modulation tracking.
func set_bd_climb_enabled(enabled: bool) -> void:
	_bd_climb_enabled = enabled
	if not enabled:
		_bd_climb_loop_phase = 0.0
		_bd_climb_width = 0.0


## Report a real-time width value from the audio middleware (0.0 → 1.0).
## This drives the loop-phase gate and per-stem caption alignment.
func report_bd_climb_width(width_norm: float) -> void:
	_bd_climb_width = clampf(width_norm, 0.0, 1.0)
	# Map width to loop phase: narrow = early phase, wide = late phase
	# This is a heuristic; the audio middleware may supply explicit phase.
	_bd_climb_loop_phase = _bd_climb_width
	bd_climb_width_changed.emit(_bd_climb_width, _bd_climb_loop_phase)


## Report an explicit loop phase (0.0 = start of cycle, 1.0 = end).
func report_bd_climb_phase(phase_norm: float) -> void:
	_bd_climb_loop_phase = clampf(phase_norm, 0.0, 1.0)


## Returns true if the current loop phase is within the given window [from, to].
func is_phase_within(from_norm: float, to_norm: float) -> bool:
	return _bd_climb_loop_phase >= from_norm and _bd_climb_loop_phase <= to_norm


## Returns the current normalized width (0.0 → 1.0).
func get_bd_climb_width() -> float:
	return _bd_climb_width


## Returns the current loop phase (0.0 → 1.0).
func get_bd_climb_phase() -> float:
	return _bd_climb_loop_phase


# ── Public API: Stem Transients ────────────────────────────────────────────


## Register a transient event for a specific stem (e.g. BD-CLIMB peak).
## This emits `stem_transient` so per-stem captions can align.
func report_stem_transient(stem_id: String, event_id: String, intensity: float = 1.0) -> void:
	var clamped_intensity: float = clampf(intensity, 0.0, 1.0)
	_last_stem_states[stem_id] = {
		"event_id": event_id, "intensity": clamped_intensity, "time": _time_source_sec
	}
	stem_transient.emit(stem_id, event_id, clamped_intensity)
	_print_debug("stem transient %s/%s intensity=%.2f" % [stem_id, event_id, clamped_intensity])


## Check whether a stem fired a specific transient within the last `window_sec`.
func was_stem_transient_recent(stem_id: String, event_id: String, window_sec: float) -> bool:
	var rec: Dictionary = _last_stem_states.get(stem_id, {})
	if rec.is_empty():
		return false
	if rec.get("event_id", "") != event_id:
		return false
	return (_time_source_sec - rec.get("time", 0.0)) <= window_sec


# ── Internal: Queue Processing ─────────────────────────────────────────────
func _process_queue() -> void:
	var triggered: Array[CaptionEvent] = []
	for e: CaptionEvent in _event_queue:
		if e.trigger_time_sec() <= _time_source_sec:
			triggered.append(e)
		else:
			break  ## queue is sorted by trigger time
	for e: CaptionEvent in triggered:
		_event_queue.erase(e)
		_activate_event(e)


func _activate_event(event: CaptionEvent) -> void:
	## If this event is on the BURDEN channel (isolated surface), it always displays.
	## If it shares a surface with active events, pre-empt lower-priority ones.
	if event.surface_group != CHANNEL_SURFACE_GROUP[Channel.BURDEN]:
		var to_preempt: Array[CaptionEvent] = []
		for active: CaptionEvent in _active_events:
			if active.surface_group == event.surface_group and active.priority < event.priority:
				to_preempt.append(active)
		for active: CaptionEvent in to_preempt:
			_active_events.erase(active)
			caption_completed.emit(active)
	_active_events.append(event)
	caption_display_requested.emit(event)


func _update_active_events(delta: float) -> void:
	var completed: Array[CaptionEvent] = []
	for e: CaptionEvent in _active_events:
		e.elapsed_sec += delta
		if e.elapsed_sec >= e.duration_sec:
			completed.append(e)
	for e: CaptionEvent in completed:
		_active_events.erase(e)
		caption_completed.emit(e)


func _update_bd_climb_loop(delta: float) -> void:
	if not _bd_climb_enabled:
		return
	## If no explicit phase reports arrive, auto-advance at a default BPM.
	## Default: 60 BPM → 1.0 phase per second (one full loop = 1 s for testing).
	## In production, the audio middleware should drive this explicitly.
	_bd_climb_loop_phase = fmod(_bd_climb_loop_phase + delta * 1.0, 1.0)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("CaptionManager: %s" % msg)


# ── Data Classes ───────────────────────────────────────────────────────────


class CaptionEvent:
	extends RefCounted
	var text: String = ""
	var channel: CaptionManager.Channel = CaptionManager.Channel.DIALOGUE
	var offset_sec: float = 0.0
	var duration_sec: float = 0.0
	var curve: CaptionCurve = CaptionCurve.LINEAR
	var localization_key: String = ""
	var priority: int = 0
	var surface_group: int = 0
	var schedule_time_sec: float = 0.0
	var elapsed_sec: float = 0.0

	func trigger_time_sec() -> float:
		return schedule_time_sec + offset_sec

	## Compute current opacity [0.0, 1.0] based on elapsed time and curve.
	func opacity() -> float:
		if duration_sec <= 0.0:
			return 1.0
		var t: float = clampf(elapsed_sec / duration_sec, 0.0, 1.0)
		match curve:
			CaptionCurve.INSTANT:
				return 1.0
			CaptionCurve.LINEAR:
				## Fade in for first 20%, hold, fade out for last 20%
				if t < 0.2:
					return t / 0.2
				elif t > 0.8:
					return (1.0 - t) / 0.2
				return 1.0
			CaptionCurve.EXPONENTIAL:
				## Exponential fade-in: fast start, slow approach to 1.0
				if t < 0.3:
					return 1.0 - pow(1.0 - (t / 0.3), 2.0)
				elif t > 0.8:
					return (1.0 - t) / 0.2
				return 1.0
			CaptionCurve.LOGARITHMIC:
				## Logarithmic tail-off: 5.0 s slow decay
				if t < 0.1:
					return t / 0.1
				else:
					return maxf(0.0, 1.0 - log(t * 10.0 + 1.0) / log(11.0))
			CaptionCurve.STEEP_EXPONENTIAL:
				## Front-loaded: appear fast, decay steeply
				if t < 0.1:
					return t / 0.1
				else:
					return maxf(0.0, exp(-10.0 * (t - 0.1)))
			_:
				return 1.0

	## Validate that timing falls within the configured tolerance.
	func is_timing_accurate(expected_offset_sec: float, tolerance_sec: float) -> bool:
		return absf(offset_sec - expected_offset_sec) <= tolerance_sec

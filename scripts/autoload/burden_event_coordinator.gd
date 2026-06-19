extends Node

## _BurdenEventCoordinator
## Coordinates between BurdenManager, AudioMiddleware, and gameplay state.
## Ensures audio stems are correctly timed with Burden Event phases.

class_name _BurdenEventCoordinator

# ── Lifecycle ────────────────────────────────────────────────────────────────


func _ready() -> void:
	_connect_signals()
	_print_debug("BurdenEventCoordinator ready")


func _exit_tree() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm:
		if bm.is_connected("burden_event_triggered", _on_burden_event_triggered):
			bm.disconnect("burden_event_triggered", _on_burden_event_triggered)
		if bm.is_connected("burden_active_changed", _on_burden_active_changed):
			bm.disconnect("burden_active_changed", _on_burden_active_changed)


# ── Internal ────────────────────────────────────────────────────────────────


func _connect_signals() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm and bm.has_signal("burden_event_triggered"):
		bm.burden_event_triggered.connect(_on_burden_event_triggered)

	if bm and bm.has_signal("burden_active_changed"):
		bm.burden_active_changed.connect(_on_burden_active_changed)


func _on_burden_event_triggered(result: Variant) -> void:
	# Start audio stems based on the triggered event
	var am: _AudioMiddleware = AutoloadHelper.audio_middleware()
	if not am:
		return

	_print_debug("Coordinating audio for Burden Event #%d" % result.trigger_count)

	# Start stems. In production, these paths would be defined in a config or constants.
	var stems: Dictionary = {
		"BD-BASS": "res://assets/audio/stems/bd_drone.wav",
		"BD-MECH": "res://assets/audio/stems/bd_bells.wav",
		"BD-STRESS": "res://assets/audio/stems/bd_voices.wav",
		"BD-CLIMB": "res://assets/audio/stems/bd_wind.wav"
	}

	for stem_id: String in stems.keys():
		var path: String = stems[stem_id]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path) as AudioStream
			if am:
				am.play_stem(stem_id, stream)
		else:
			_print_debug("Stem asset missing: %s" % path)


func _on_burden_active_changed(active: bool) -> void:
	var am: _AudioMiddleware = AutoloadHelper.audio_middleware()
	if not am:
		return

	if not active:
		am.stop_all()
		_print_debug("Burden deactivated - stopping audio stems")


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenEventCoordinator: %s" % msg)

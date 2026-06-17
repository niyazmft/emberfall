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
	if BurdenManager:
		if BurdenManager.is_connected("burden_event_triggered", _on_burden_event_triggered):
			BurdenManager.disconnect("burden_event_triggered", _on_burden_event_triggered)
		if BurdenManager.is_connected("burden_active_changed", _on_burden_active_changed):
			BurdenManager.disconnect("burden_active_changed", _on_burden_active_changed)


# ── Internal ────────────────────────────────────────────────────────────────


func _connect_signals() -> void:
	if BurdenManager and BurdenManager.has_signal("burden_event_triggered"):
		BurdenManager.burden_event_triggered.connect(_on_burden_event_triggered)

	if BurdenManager and BurdenManager.has_signal("burden_active_changed"):
		BurdenManager.burden_active_changed.connect(_on_burden_active_changed)


func _on_burden_event_triggered(result: Variant) -> void:
	# Start audio stems based on the triggered event
	if not AudioMiddleware:
		return

	_print_debug("Coordinating audio for Burden Event #%d" % result.trigger_count)

	# Start stems. In production, these paths would be defined in a config or constants.
	var stems: Dictionary = {
		"BD-BASS": "res://assets/audio/stems/bd_drone.ogg",
		"BD-MECH": "res://assets/audio/stems/bd_bells.ogg",
		"BD-STRESS": "res://assets/audio/stems/bd_voices.ogg",
		"BD-CLIMB": "res://assets/audio/stems/bd_wind.ogg"
	}

	for stem_id: String in stems.keys():
		var path: String = stems[stem_id]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path) as AudioStream
			AudioMiddleware.play_stem(stem_id, stream)
		else:
			_print_debug("Stem asset missing: %s" % path)


func _on_burden_active_changed(active: bool) -> void:
	if not AudioMiddleware:
		return

	if not active:
		AudioMiddleware.stop_all()
		_print_debug("Burden deactivated - stopping audio stems")


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenEventCoordinator: %s" % msg)

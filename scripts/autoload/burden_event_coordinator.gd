extends Node

## _BurdenEventCoordinator
## Coordinates between BurdenManager, AudioMiddleware, and gameplay state.
## Ensures audio stems are correctly timed with Burden Event phases.

class_name _BurdenEventCoordinator

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_connect_signals()
	_print_debug("BurdenEventCoordinator ready")

# ── Internal ────────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	var bm := get_node_or_null("/root/BurdenManager")
	if bm and bm.has_signal("burden_event_triggered"):
		bm.burden_event_triggered.connect(_on_burden_event_triggered)

	if bm and bm.has_signal("burden_active_changed"):
		bm.burden_active_changed.connect(_on_burden_active_changed)

func _on_burden_event_triggered(result: Variant) -> void:
	# Start audio stems based on the triggered event
	var am := get_node_or_null("/root/AudioMiddleware")
	if not am:
		return

	_print_debug("Coordinating audio for Burden Event #%d" % result.trigger_count)

	# In a real implementation, we would load the actual AudioStream resources.
	# For now, we assume the system is ready to receive play commands.
	# am.play_stem("BD-BASS", load("res://audio/stems/bd_bass.ogg"))
	# ... etc

func _on_burden_active_changed(active: bool) -> void:
	var am := get_node_or_null("/root/AudioMiddleware")
	if not am:
		return

	if not active:
		am.stop_all()
		_print_debug("Burden deactivated - stopping audio stems")

func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenEventCoordinator: %s" % msg)

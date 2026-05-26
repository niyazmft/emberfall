extends Node

## _AudioMiddleware
## Manages a collection of _StemPlayback instances for Burden stems.
## Forwards detected transient and feature events.

class_name _AudioMiddleware

# ── Signals ────────────────────────────────────────────────────────────────
signal stem_event_detected(stem_id: String, event_type: String, intensity: float)

# ── Properties ────────────────────────────────────────────────────────────
var _stems: Dictionary = {}

# ── Lifecycle ────────────────────────────────────────────────────────────────


func _ready() -> void:
	_setup_stems()
	_print_debug("AudioMiddleware ready")


# ── Public API ─────────────────────────────────────────────────────────────


func play_stem(stem_id: String, stream: AudioStream) -> void:
	if _stems.has(stem_id):
		var playback: Node = _stems[stem_id] as Node
		if playback.has_method("play_stream"):
			playback.call("play_stream", stream)
		_print_debug("Playing stem: %s" % stem_id)
	else:
		push_warning("AudioMiddleware: Unknown stem_id '%s'" % stem_id)


func stop_stem(stem_id: String) -> void:
	if _stems.has(stem_id):
		var playback: Node = _stems[stem_id] as Node
		if playback.has_method("stop"):
			playback.call("stop")
		_print_debug("Stopped stem: %s" % stem_id)


func stop_all() -> void:
	for stem_id: String in _stems.keys():
		var playback: Node = _stems[stem_id] as Node
		if playback.has_method("stop"):
			playback.call("stop")
	_print_debug("Stopped all stems")


# ── Internal ────────────────────────────────────────────────────────────────


func _setup_stems() -> void:
	var stem_ids: Array[String] = ["BD-BASS", "BD-MECH", "BD-STRESS", "BD-CLIMB"]
	for id: String in stem_ids:
		# Use separate bus for each stem to allow independent analysis
		var bus_name: String = id

		# Ensure bus exists or fallback to Master
		if AudioServer.get_bus_index(bus_name) == -1:
			push_warning("AudioMiddleware: Bus '%s' not found, using 'Master'" % bus_name)
			bus_name = "Master"

		var script: GDScript = load("res://scripts/core/stem_playback.gd") as GDScript
		var playback: Node = script.new(id, bus_name)
		playback.name = id.replace("-", "_")
		add_child(playback)
		_stems[id] = playback

		playback.connect("transient_detected", _on_stem_transient_detected.bind(id))
		playback.connect("feature_updated", _on_stem_feature_updated.bind(id))


func _on_stem_transient_detected(type: String, intensity: float, stem_id: String) -> void:
	stem_event_detected.emit(stem_id, type, intensity)
	_print_debug("Stem event: %s | %s | %.2f" % [stem_id, type, intensity])


func _on_stem_feature_updated(feature: String, value: float, stem_id: String) -> void:
	# Convert continuous feature updates to discrete events if necessary
	if stem_id == "BD-CLIMB" and feature == "width":
		stem_event_detected.emit(stem_id, "width_change", value)
	elif stem_id == "BD-STRESS" and feature == "swell":
		if value > 0.8:
			stem_event_detected.emit(stem_id, "high_stress", value)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("AudioMiddleware: %s" % msg)

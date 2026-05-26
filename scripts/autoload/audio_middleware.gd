extends Node

## _AudioMiddleware
## Manages a collection of _StemPlayback instances for Burden stems.
## Forwards detected transient and feature events.

class_name _AudioMiddleware

# ── Signals ────────────────────────────────────────────────────────────────
signal stem_event_detected(stem_id: String, event_type: String, intensity: float)

# ── Properties ────────────────────────────────────────────────────────────
var _stems: Dictionary = {}
var _stem_router: Node

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_setup_router()
	_setup_stems()
	_print_debug("AudioMiddleware ready")

# ── Public API ─────────────────────────────────────────────────────────────

func get_stem_router() -> Node:
	return _stem_router

func play_stem(stem_id: String, stream: AudioStream) -> void:
	if _stems.has(stem_id):
		var playback: _StemPlayback = _stems[stem_id]
		playback.play_stream(stream)
		_print_debug("Playing stem: %s" % stem_id)
	else:
		push_warning("AudioMiddleware: Unknown stem_id '%s'" % stem_id)

func stop_stem(stem_id: String) -> void:
	if _stems.has(stem_id):
		var playback: _StemPlayback = _stems[stem_id]
		playback.stop()
		_print_debug("Stopped stem: %s" % stem_id)

func stop_all() -> void:
	for stem_id in _stems:
		_stems[stem_id].stop()
	_print_debug("Stopped all stems")

# ── Internal ────────────────────────────────────────────────────────────────

func _setup_router() -> void:
	var router_script = load("res://src/Audio/Captioning/burden_stem_caption_router.gd")
	if router_script:
		_stem_router = router_script.new()
		_stem_router.name = "BurdenStemCaptionRouter"
		add_child(_stem_router)

		# Find SubtitleManager in the scene tree to set as presenter
		var subtitle_manager = get_tree().root.find_child("SubtitleManager", true, false)
		if subtitle_manager:
			_stem_router.set_presenter(subtitle_manager)
		else:
			# Fallback: if not found now, it might be added later.
			# In a real app, we might use a signal or a more robust discovery.
			pass

func _setup_stems() -> void:
	var stem_ids: Array[String] = ["BD-BASS", "BD-MECH", "BD-STRESS", "BD-CLIMB"]
	for id: String in stem_ids:
		# Use separate bus for each stem to allow independent analysis
		var bus_name: String = id

		# Ensure bus exists or fallback to Master
		if AudioServer.get_bus_index(bus_name) == -1:
			push_warning("AudioMiddleware: Bus '%s' not found, using 'Master'" % bus_name)
			bus_name = "Master"

		var playback := _StemPlayback.new(id, bus_name)
		playback.name = id.replace("-", "_")
		add_child(playback)
		_stems[id] = playback

		playback.transient_detected.connect(_on_stem_transient_detected.bind(id))
		playback.feature_updated.connect(_on_stem_feature_updated.bind(id))

func _on_stem_transient_detected(type: String, intensity: float, stem_id: String) -> void:
	stem_event_detected.emit(stem_id, type, intensity)

	if _stem_router:
		_stem_router.dispatch_event(stem_id, type)

	_print_debug("Stem event: %s | %s | %.2f" % [stem_id, type, intensity])

func _on_stem_feature_updated(feature: String, value: float, stem_id: String) -> void:
	# Convert continuous feature updates to discrete events if necessary
	if stem_id == "BD-CLIMB" and feature == "width":
		stem_event_detected.emit(stem_id, "width_change", value)
		if _stem_router:
			if value > 0.7:
				_stem_router.dispatch_event(stem_id, "expand")
			elif value < 0.3:
				_stem_router.dispatch_event(stem_id, "converge")
	elif stem_id == "BD-STRESS" and feature == "swell":
		if value > 0.8:
			stem_event_detected.emit(stem_id, "high_stress", value)
			if _stem_router:
				_stem_router.dispatch_event(stem_id, "swell_start")

func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("AudioMiddleware: %s" % msg)

extends GdUnitTestSuite

func test_stem_playback_controls() -> void:
	var am: _AudioMiddleware = AudioMiddleware
	var stream: AudioStream = AudioStreamPolyphonic.new()

	# Verify we can call play/stop without crashing even if stems aren't fully wired in test env
	am.play_stem("BD-BASS", stream)
	am.stop_stem("BD-BASS")

	# Verify unknown stem ID handling (should push_warning but not crash)
	am.play_stem("UNKNOWN", stream)

func test_stop_all_stems() -> void:
	var am: _AudioMiddleware = AudioMiddleware
	am.stop_all()
	# Basic smoke test for the stop_all method

func test_stem_event_forwarding() -> void:
	var am: _AudioMiddleware = AudioMiddleware
	var signal_data: Dictionary = {"id": "", "type": "", "intensity": 0.0}

	var cb: Callable = func(sid: String, type: String, intensity: float) -> void:
		signal_data.id = sid
		signal_data.type = type
		signal_data.intensity = intensity

	if not am.stem_event_detected.is_connected(cb):
		am.stem_event_detected.connect(cb)

	# Manually trigger the internal handler to simulate StemPlayback emitting a signal
	am._on_stem_transient_detected("impact", 0.75, "BD-BASS")

	assert_str(signal_data.id).is_equal("BD-BASS")
	assert_str(signal_data.type).is_equal("impact")
	assert_float(signal_data.intensity).is_equal(0.75)

	am.stem_event_detected.disconnect(cb)

func test_climb_feature_processing() -> void:
	var am: _AudioMiddleware = AudioMiddleware
	var events: Array = []
	var cb: Callable = func(sid: String, type: String, val: float) -> void:
		events.append(type)
	if not am.stem_event_detected.is_connected(cb):
		am.stem_event_detected.connect(cb)

	# Reset state to ensure clean run
	am._climb_expanded = false
	am._climb_converged = false

	# Test expansion
	am._on_stem_feature_updated("width", 0.9, "BD-CLIMB")
	assert_array(events).contains(["width_change"])
	# expansion/convergence logic in _AudioMiddleware depends on router's dispatch_event
	# but we can check if it at least emitted the signal (which it should if it processed it)

	# Test convergence
	events.clear()
	am._on_stem_feature_updated("width", 0.1, "BD-CLIMB")
	assert_array(events).contains(["width_change"])

	am.stem_event_detected.disconnect(cb)

func test_stress_swell_processing() -> void:
	var am: _AudioMiddleware = AudioMiddleware
	var events: Array = []
	var cb: Callable = func(sid: String, type: String, val: float) -> void: events.append(type)
	if not am.stem_event_detected.is_connected(cb):
		am.stem_event_detected.connect(cb)

	am._on_stem_feature_updated("swell", 0.9, "BD-STRESS")
	assert_array(events).contains(["high_stress"])

	am.stem_event_detected.disconnect(cb)

func test_router_integration() -> void:
	var am: _AudioMiddleware = AudioMiddleware
	var router: Node = am.get_stem_router()
	assert_that(router).is_not_null()
	assert_str(router.name).is_equal("BurdenStemCaptionRouter")

func test_bus_assignment_logic() -> void:
	var am: _AudioMiddleware = AudioMiddleware
	# Stems are child nodes in the middleware
	var bass: Node = am.get_node_or_null("BD_BASS")
	assert_that(bass).is_not_null()

func test_invalid_stem_id_handling() -> void:
	var am: _AudioMiddleware = AudioMiddleware
	# Should not crash
	am.play_stem("INVALID_ID", null)
	am.stop_stem("INVALID_ID")

func test_stem_node_structure() -> void:
	var am: _AudioMiddleware = AudioMiddleware
	var expected_stems: Array[String] = ["BD_BASS", "BD_MECH", "BD_STRESS", "BD_CLIMB"]
	for s: String in expected_stems:
		assert_that(am.get_node_or_null(s)).is_not_null()

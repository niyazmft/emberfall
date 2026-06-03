extends GdUnitTestSuite


func test_stem_playback_signals() -> void:
	var playback: _StemPlayback = auto_free(_StemPlayback.new("BD-BASS", "Master"))
	add_child(playback)

	var results: Dictionary = {"signal_emitted": false, "emitted_intensity": 0.0}
	playback.transient_detected.connect(
		func(type: String, intensity: float) -> void:
			results.signal_emitted = true
			results.emitted_intensity = intensity
	)

	# Manually trigger internal analysis result (mocking spectrum analyzer impact)
	playback.transient_detected.emit("impact", 0.8)

	assert_that(results.signal_emitted).is_true()
	assert_that(results.emitted_intensity).is_equal(0.8)


func test_audio_middleware_forwarding() -> void:
	var am: _AudioMiddleware = auto_free(_AudioMiddleware.new())
	add_child(am)
	# Need to call _ready manually if not in tree at start
	am._ready()

	var results: Dictionary = {"signal_emitted": false}
	am.stem_event_detected.connect(
		func(stem_id: String, type: String, _intensity: float) -> void:
			if stem_id == "BD-MECH" and type == "clang":
				results.signal_emitted = true
	)

	# Simulate a signal from one of the internal stems
	var mech_playback: _StemPlayback = am.get_node("BD_MECH") as _StemPlayback
	mech_playback.transient_detected.emit("clang", 0.5)

	assert_that(results.signal_emitted).is_true()


func test_caption_driver_mapping() -> void:
	var cm: Node = auto_free(Node.new())
	cm.name = "CaptionManager"

	var existing_cm: Node = get_tree().root.get_node_or_null("CaptionManager")
	if existing_cm:
		get_tree().root.remove_child(existing_cm)

	get_tree().root.add_child(cm)

	var results: Dictionary = {"caption_received": false, "received_text": ""}

	var script: GDScript = GDScript.new()
	script.source_code = (
		"extends Node\n"
		+ "signal scheduled(text: String)\n"
		+ "func schedule(text: String, _channel: int, _offset: float, "
		+ "_duration: float, _curve: int, _loc_key: String) -> void:\n"
		+ "	scheduled.emit(text)\n"
		+ "func report_stem_transient(_a: String, _b: String, _c: float) -> void: pass"
	)
	script.reload()
	cm.set_script(script)
	cm.connect(
		"scheduled",
		func(text: String) -> void:
			results.caption_received = true
			results.received_text = text
	)

	var driver: _BurdenCaptionDriver = auto_free(_BurdenCaptionDriver.new())
	add_child(driver)

	# Manually trigger event that should map to a caption
	driver._on_stem_event("BD-BASS", "impact", 0.9)

	assert_that(results.caption_received).is_true()
	assert_that(results.received_text).is_equal("[Deep impact]")

	get_tree().root.remove_child(cm)
	if existing_cm:
		get_tree().root.add_child(existing_cm)


func test_caption_driver_cooldown() -> void:
	var cm: Node = auto_free(Node.new())
	cm.name = "CaptionManager"

	var existing_cm: Node = get_tree().root.get_node_or_null("CaptionManager")
	if existing_cm:
		get_tree().root.remove_child(existing_cm)

	get_tree().root.add_child(cm)

	var script: GDScript = GDScript.new()
	script.source_code = (
		"extends Node\n"
		+ "signal scheduled\n"
		+ "func schedule(_a: String, _b: int, _c: float, _d: float, _e: int, _f: String) -> void:\n"
		+ "	scheduled.emit()\n"
		+ "func report_stem_transient(_a: String, _b: String, _c: float) -> void: pass"
	)
	script.reload()
	cm.set_script(script)

	var results: Dictionary = {"call_count": 0}
	cm.connect("scheduled", func() -> void: results.call_count += 1)

	var driver: _BurdenCaptionDriver = auto_free(_BurdenCaptionDriver.new())
	add_child(driver)

	# Trigger same event twice rapidly
	driver._on_stem_event("BD-MECH", "clang", 0.9)
	driver._on_stem_event("BD-MECH", "clang", 0.9)

	assert_that(results.call_count).is_equal(1)

	get_tree().root.remove_child(cm)
	if existing_cm:
		get_tree().root.add_child(existing_cm)

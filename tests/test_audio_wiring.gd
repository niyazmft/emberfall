extends Node

## Integration tests for Audio Stem Event Wiring (DON-218).


func run_all() -> void:
	var passed: int = 0
	var failed: int = 0
	var tests: Array[String] = [
		"test_stem_playback_signals",
		"test_audio_middleware_forwarding",
		"test_caption_driver_mapping",
		"test_caption_driver_cooldown"
	]

	for name: String in tests:
		print("Running %s ..." % name)
		var ok: Variant = call(name)
		if ok is bool and ok:
			passed += 1
			print("  PASS")
		else:
			failed += 1
			print("  FAIL (returned %s)" % str(ok))

	print("")
	print("Results: %d passed, %d failed out of %d" % [passed, failed, tests.size()])
	if failed > 0:
		push_error("Audio Wiring test suite had failures.")
		get_tree().quit(1)
	else:
		get_tree().quit(0)


func test_stem_playback_signals() -> bool:
	var playback: _StemPlayback = _StemPlayback.new("BD-BASS", "Master")
	add_child(playback)

	var results := {"signal_emitted": false, "emitted_intensity": 0.0}
	playback.transient_detected.connect(
		func(type: String, intensity: float) -> void:
			results.signal_emitted = true
			results.emitted_intensity = intensity
	)

	# Manually trigger internal analysis result (mocking spectrum analyzer impact)
	playback.transient_detected.emit("impact", 0.8)

	if not results.signal_emitted:
		push_error("Expected transient_detected signal to be emitted")
		return false
	if results.emitted_intensity != 0.8:
		push_error("Expected intensity 0.8, got %f" % results.emitted_intensity)
		return false

	playback.queue_free()
	return true


func test_audio_middleware_forwarding() -> bool:
	var am: _AudioMiddleware = _AudioMiddleware.new()
	add_child(am)
	# Need to call _ready manually if not in tree at start
	am._ready()

	var results := {"signal_emitted": false}
	am.stem_event_detected.connect(
		func(stem_id: String, type: String, _intensity: float) -> void:
			if stem_id == "BD-MECH" and type == "clang":
				results.signal_emitted = true
	)

	# Simulate a signal from one of the internal stems
	var mech_playback: _StemPlayback = am.get_node("BD_MECH") as _StemPlayback
	mech_playback.transient_detected.emit("clang", 0.5)

	if not results.signal_emitted:
		push_error("AudioMiddleware failed to forward stem signal")
		return false

	am.queue_free()
	return true


func test_caption_driver_mapping() -> bool:
	# Mock CaptionManager
	var cm: Node = Node.new()
	cm.name = "CaptionManager"

	# Replace existing autoload node if it exists
	var existing_cm: Node = get_tree().root.get_node_or_null("CaptionManager")
	if existing_cm:
		get_tree().root.remove_child(existing_cm)

	get_tree().root.add_child(cm)

	var results := {"caption_received": false, "received_text": ""}

	# Add dummy schedule method
	var script: GDScript = GDScript.new()
	script.source_code = (
		"extends Node\n"
		+ "signal scheduled(text: String)\n"
		+ "func schedule(text: String, _channel: int, _offset: float, _duration: float, _curve: int, _loc_key: String) -> void:\n"
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

	var driver: _BurdenCaptionDriver = _BurdenCaptionDriver.new()
	add_child(driver)

	# Manually trigger event that should map to a caption
	driver._on_stem_event("BD-BASS", "impact", 0.9)

	if not results.caption_received:
		push_error("BurdenCaptionDriver failed to trigger caption")
		cm.queue_free()
		if existing_cm:
			get_tree().root.add_child(existing_cm)
		return false

	if results.received_text != "[Deep impact]":
		push_error("Expected '[Deep impact]', got '%s'" % results.received_text)
		cm.queue_free()
		if existing_cm:
			get_tree().root.add_child(existing_cm)
		return false

	driver.queue_free()
	cm.queue_free()

	# Restore existing autoload
	if existing_cm:
		get_tree().root.add_child(existing_cm)

	return true


func test_caption_driver_cooldown() -> bool:
	# Mock CaptionManager
	var cm: Node = Node.new()
	cm.name = "CaptionManager"

	# Replace existing autoload node if it exists
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

	var results := {"call_count": 0}
	cm.connect("scheduled", func() -> void: results.call_count += 1)

	var driver: _BurdenCaptionDriver = _BurdenCaptionDriver.new()
	add_child(driver)

	# Trigger same event twice rapidly
	driver._on_stem_event("BD-MECH", "clang", 0.9)
	driver._on_stem_event("BD-MECH", "clang", 0.9)

	if results.call_count != 1:
		push_error("Cooldown failed: expected 1 call, got %d" % results.call_count)
		cm.queue_free()
		if existing_cm:
			get_tree().root.add_child(existing_cm)
		return false

	driver.queue_free()
	cm.queue_free()

	# Restore existing autoload
	if existing_cm:
		get_tree().root.add_child(existing_cm)

	return true


func _ready() -> void:
	# Small delay to ensure all nodes are ready
	await get_tree().process_frame
	run_all()

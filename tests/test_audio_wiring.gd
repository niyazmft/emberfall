extends Node

## Integration tests for Audio Stem Event Wiring (DON-218).

func run_all() -> void:
	var passed := 0
	var failed := 0
	var tests := [
		"test_stem_playback_signals",
		"test_audio_middleware_forwarding",
		"test_caption_driver_mapping",
		"test_caption_driver_cooldown"
	]

	for name: String in tests:
		print("Running %s ..." % name)
		var ok := call(name)
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
	var playback := _StemPlayback.new("BD-BASS", "Master")
	add_child(playback)

	var signal_emitted := false
	var emitted_intensity := 0.0
	playback.transient_detected.connect(func(type, intensity):
		signal_emitted = true
		emitted_intensity = intensity
	)

	# Manually trigger internal analysis result (mocking spectrum analyzer impact)
	playback.transient_detected.emit("impact", 0.8)

	if not signal_emitted:
		push_error("Expected transient_detected signal to be emitted")
		return false
	if emitted_intensity != 0.8:
		push_error("Expected intensity 0.8, got %f" % emitted_intensity)
		return false

	playback.queue_free()
	return true

func test_audio_middleware_forwarding() -> bool:
	var am := _AudioMiddleware.new()
	add_child(am)
	# Need to call _ready manually if not in tree at start
	am._ready()

	var signal_emitted := false
	am.stem_event_detected.connect(func(stem_id, type, intensity):
		if stem_id == "BD-MECH" and type == "clang":
			signal_emitted = true
	)

	# Simulate a signal from one of the internal stems
	var mech_playback: _StemPlayback = am.get_node("BD_MECH")
	mech_playback.transient_detected.emit("clang", 0.5)

	if not signal_emitted:
		push_error("AudioMiddleware failed to forward stem signal")
		return false

	am.queue_free()
	return true

func test_caption_driver_mapping() -> bool:
	# Mock CaptionManager
	var cm := Node.new()
	cm.name = "CaptionManager"
	get_tree().root.add_child(cm)

	var caption_received := false
	var received_text := ""

	# Add dummy schedule method
	cm.set_script(GDScript.new())
	cm.get_script().source_code = "extends Node\nsignal scheduled(text)\nfunc schedule(text, channel, offset, duration, curve, loc_key):\n\tscheduled.emit(text)"
	cm.get_script().reload()
	cm.scheduled.connect(func(text):
		caption_received = true
		received_text = text
	)

	var driver := _BurdenCaptionDriver.new()
	add_child(driver)

	# Manually trigger event that should map to a caption
	driver._on_stem_event("BD-BASS", "impact", 0.9)

	if not caption_received:
		push_error("BurdenCaptionDriver failed to trigger caption")
		cm.queue_free()
		return false

	if received_text != "[Deep impact]":
		push_error("Expected '[Deep impact]', got '%s'" % received_text)
		cm.queue_free()
		return false

	driver.queue_free()
	cm.queue_free()
	return true

func test_caption_driver_cooldown() -> bool:
	var cm := Node.new()
	cm.name = "CaptionManager"
	get_tree().root.add_child(cm)
	cm.set_script(GDScript.new())
	cm.get_script().source_code = "extends Node\nsignal scheduled\nfunc schedule(a,b,c,d,e,f):\n\tscheduled.emit()"
	cm.get_script().reload()

	var call_count := 0
	cm.scheduled.connect(func(): call_count += 1)

	var driver := _BurdenCaptionDriver.new()
	add_child(driver)

	# Trigger same event twice rapidly
	driver._on_stem_event("BD-MECH", "clang", 0.9)
	driver._on_stem_event("BD-MECH", "clang", 0.9)

	if call_count != 1:
		push_error("Cooldown failed: expected 1 call, got %d" % call_count)
		cm.queue_free()
		return false

	driver.queue_free()
	cm.queue_free()
	return true

func _ready() -> void:
	# Small delay to ensure all nodes are ready
	await get_tree().process_frame
	run_all()

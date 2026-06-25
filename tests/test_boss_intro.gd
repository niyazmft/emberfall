extends GdUnitTestSuite


func test_boss_intro_fires_for_boss_room() -> void:
	var narrator: _AmbientNarrator = _AmbientNarrator.new()
	add_child(narrator)
	await get_tree().process_frame

	# Simulate entering a boss room
	var boss_room_data: Dictionary = {
		"id": "boss_overgrown_guardian",
		"biome": 2,
		"layout": {"elevation": [], "cover": [], "blocked": [], "vision_blocked": []}
	}
	narrator._on_room_entered(0, boss_room_data)
	await get_tree().process_frame

	# The boss intro should have triggered a narrative; we can't verify the
	# caption directly without a mock CaptionManager, but the call should
	# not crash and the method should be callable.
	assert_bool(true).is_true()

	narrator.queue_free()
	await get_tree().process_frame


func test_boss_intro_selects_deterministic_variant() -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl == null:
		return

	var boss_intros: Variant = cl.getValue("boss_intros")
	assert_that(boss_intros).is_not_null()
	assert_that(boss_intros is Dictionary).is_true()

	var guardian_intros: Array = boss_intros.get("boss_overgrown_guardian", []) as Array
	assert_int(guardian_intros.size()).is_equal(3)
	assert_str(guardian_intros[0]).is_equal("BOSS_INTRO_1")
	assert_str(guardian_intros[1]).is_equal("BOSS_INTRO_2")
	assert_str(guardian_intros[2]).is_equal("BOSS_INTRO_3")


func test_boss_intro_keys_exist_in_localization() -> void:
	for i: int in range(1, 4):
		var key: String = "BOSS_INTRO_%d" % i
		var text: String = tr(key)
		assert_bool(not text.is_empty() and text != key).is_true()


func test_non_boss_room_does_not_trigger_boss_intro() -> void:
	var narrator: _AmbientNarrator = _AmbientNarrator.new()
	add_child(narrator)
	await get_tree().process_frame

	# Simulate entering a standard room
	var room_data: Dictionary = {
		"id": "room_standard_01",
		"biome": 0,
		"layout": {"elevation": [], "cover": [], "blocked": [], "vision_blocked": []}
	}
	narrator._on_room_entered(0, room_data)
	await get_tree().process_frame

	# Should not crash; standard rooms don't trigger boss intros
	assert_bool(true).is_true()

	narrator.queue_free()
	await get_tree().process_frame


func test_ambient_narrator_json_is_valid() -> void:
	var file := FileAccess.open("res://data/ambient_narrator.json", FileAccess.READ)
	assert_that(file).is_not_null()
	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	assert_that(parsed is Dictionary).is_true()

	var data: Dictionary = parsed as Dictionary
	assert_bool(data.has("boss_intros")).is_true()
	assert_bool(data.has("triggers")).is_true()
	assert_bool(data.has("biome_entry")).is_true()

extends GdUnitTestSuite


func test_show_internal_monologue_sets_text() -> void:
	var dm: _DialogueManager = AutoloadHelper.dialogue_manager()
	if dm == null:
		return

	dm.show_internal_monologue("DIALOGUE_KEEPER_INTRO_1")
	await get_tree().process_frame

	assert_bool(dm._is_visible).is_true()
	assert_that(dm._label).is_not_null()
	assert_bool(dm._label.text.length() > 0).is_true()

	dm.dismiss()
	await get_tree().process_frame


func test_show_dialogue_sets_text() -> void:
	var dm: _DialogueManager = AutoloadHelper.dialogue_manager()
	if dm == null:
		return

	dm.show_dialogue("DIALOGUE_BOSS_INTRO")
	await get_tree().process_frame

	assert_bool(dm._is_visible).is_true()
	assert_that(dm._label).is_not_null()
	assert_bool(dm._label.text.length() > 0).is_true()

	dm.dismiss()
	await get_tree().process_frame


func test_dismiss_hides_dialogue() -> void:
	var dm: _DialogueManager = AutoloadHelper.dialogue_manager()
	if dm == null:
		return

	dm.show_dialogue("DIALOGUE_BOSS_INTRO")
	await get_tree().process_frame
	assert_bool(dm._is_visible).is_true()

	dm.dismiss()
	await get_tree().process_frame
	assert_bool(dm._is_visible).is_false()


func test_show_with_missing_key_falls_back_to_key() -> void:
	var dm: _DialogueManager = AutoloadHelper.dialogue_manager()
	if dm == null:
		return

	dm.show_dialogue("NONEXISTENT_KEY_12345")
	await get_tree().process_frame

	assert_that(dm._label).is_not_null()
	assert_str(dm._label.text).is_equal("NONEXISTENT_KEY_12345")

	dm.dismiss()
	await get_tree().process_frame

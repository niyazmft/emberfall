# GdUnit Generated Test Suite
extends GdUnitTestSuite
@warning_ignore("unused_parameter")
func test_dialogue_manager_load() -> void:
	var dm: _DialogueManager = AutoloadHelper.get_autoload("DialogueManager") as _DialogueManager
	assert_that(dm).is_not_null()
	assert_that(dm.has_dialogue("intro_sequence")).is_true()

	var data: Dictionary = dm.get_dialogue("intro_sequence")
	assert_that(data).is_not_empty()
	var lines: Variant = data.get("lines")
	assert_that(lines is Array).is_true()
	assert_that(data.get("lines").size()).is_equal(2)


func test_dialogue_manager_missing() -> void:
	var dm: _DialogueManager = AutoloadHelper.get_autoload("DialogueManager") as _DialogueManager
	assert_that(dm.has_dialogue("non_existent")).is_false()
	assert_that(dm.get_dialogue("non_existent")).is_empty()

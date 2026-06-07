extends GdUnitTestSuite


func test_tutorial_manager_loading() -> void:
	var tm: _TutorialManager = AutoloadHelper.tutorial_manager()
	assert_that(tm).is_not_null()
	# Accessing private members for testing is allowed in this project's test style
	assert_that(tm.get("_tutorial_data")).is_not_null()
	assert_that(tm.get("_asset_manifest")).is_not_null()


func test_tutorial_progression() -> void:
	var tm: _TutorialManager = AutoloadHelper.tutorial_manager()
	tm.start_tutorials()
	assert_that(tm.get("_current_step_index")).is_equal(0)

	var steps: Array = tm.get("_tutorial_data").get("steps", [])
	var step_data: Dictionary = steps[0]
	assert_that(step_data.get("id")).is_equal("movement")
	assert_that(tm.is_input_locked("attack")).is_true()

	tm.complete_current_step()
	assert_that(tm.get("_current_step_index")).is_equal(1)
	assert_that(tm.is_input_locked("attack")).is_false()


func test_asset_path_lookup() -> void:
	var tm: _TutorialManager = AutoloadHelper.tutorial_manager()
	var path: String = tm.get_asset_path("highlight_frame")
	assert_that(path).is_not_empty()
	assert_that(path).contains("res://")

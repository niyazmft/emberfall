extends GdUnitTestSuite
## Unit tests for SafeZoneManager and UI reflow logic (DON-196).


func test_aspect_ratio_breakpoints() -> void:
	# Note: float comparison in exact types for deterministic rules
	assert_that(SafeZoneManager.BREAKPOINT_SHRINK).is_equal(1.6)
	assert_that(SafeZoneManager.BREAKPOINT_EXPAND).is_equal(1.9)


func test_safe_margins() -> void:
	var margins: Dictionary = SafeZoneManager.get_safe_margins()
	assert_that(margins.has("left")).is_true()
	assert_that(margins.has("right")).is_true()
	assert_that(margins.has("top")).is_true()
	assert_that(margins.has("bottom")).is_true()


func test_notch_offset() -> void:
	var offset: Vector2 = SafeZoneManager.get_notch_offset()
	assert_that(offset is Vector2).is_true()


func test_portrait_detection() -> void:
	var is_p: bool = SafeZoneManager.is_portrait()
	var size: Vector2 = get_viewport().get_visible_rect().size
	if size.y > size.x:
		assert_that(is_p).is_true()
	else:
		assert_that(is_p).is_false()

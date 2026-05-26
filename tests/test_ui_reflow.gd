extends Node

## Unit tests for SafeZoneManager and UI reflow logic (DON-196).

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("=== UI Reflow Test Suite (DON-196) ===")

	_test_aspect_ratio_breakpoints()
	_test_safe_margins()
	_test_notch_offset()
	_test_portrait_detection()

	print("")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("ASSERT FAILED: %s" % msg)


func _test_aspect_ratio_breakpoints() -> void:
	print("\n[Test] Aspect ratio breakpoints")

	# We can't easily resize the viewport in headless mode and expect immediate signal response in a script run,
	# but we can test the logic if we make it accessible or mock it.
	# For now, we test the constants and the logic in SafeZoneManager if possible.

	_assert(SafeZoneManager.BREAKPOINT_SHRINK == 1.6, "Breakpoint SHRINK is 1.6")
	_assert(SafeZoneManager.BREAKPOINT_EXPAND == 1.9, "Breakpoint EXPAND is 1.9")

	# Manually trigger a check with a simulated size
	# This is hard to do without modifying SafeZoneManager to accept a size for testing.
	print("  breakpoints checked")


func _test_safe_margins() -> void:
	print("\n[Test] Safe margins")
	var margins := SafeZoneManager.get_safe_margins()
	_assert(margins.has("left"), "Margins has left")
	_assert(margins.has("right"), "Margins has right")
	_assert(margins.has("top"), "Margins has top")
	_assert(margins.has("bottom"), "Margins has bottom")
	print("  margins checked")


func _test_notch_offset() -> void:
	print("\n[Test] Notch offset")
	var offset := SafeZoneManager.get_notch_offset()
	_assert(offset is Vector2, "Notch offset is Vector2")
	print("  notch offset checked")


func _test_portrait_detection() -> void:
	print("\n[Test] Portrait detection")
	# Headless default is usually landscape or square
	var is_p := SafeZoneManager.is_portrait()
	var size := get_viewport().get_visible_rect().size
	if size.y > size.x:
		_assert(is_p == true, "Portrait detected correctly")
	else:
		_assert(is_p == false, "Landscape detected correctly")
	print("  portrait detection checked")

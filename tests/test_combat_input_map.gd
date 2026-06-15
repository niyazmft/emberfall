# GdUnit Generated Test Suite
class_name CombatInputMapTest
extends GdUnitTestSuite


func test_combat_end_turn_action_defined() -> void:
	assert_bool(InputMap.has_action("combat_end_turn")).is_true()

	var events: Array[InputEvent] = InputMap.action_get_events("combat_end_turn")
	assert_int(events.size()).is_equal(1)

	var event: InputEvent = events[0]
	assert_bool(event is InputEventKey).is_true()

	var key_event: InputEventKey = event as InputEventKey
	# Physical keycode 4194309 corresponds to Key.ENTER
	assert_int(key_event.physical_keycode).is_equal(4194309)

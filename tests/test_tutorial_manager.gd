extends GdUnitTestSuite

var _tm: _TutorialManager


func before() -> void:
	_tm = _TutorialManager.new()
	# Inject a mock save manager if needed, but for now we'll test the logic.
	# We can also mock FileAccess for data loading but let's use the real data first.
	add_child(_tm)


func after() -> void:
	_tm.free()


func test_load_tutorial_data() -> void:
	assert_bool(_tm.tutorial_enabled).is_true()
	assert_int(_tm.tutorial_steps.size()).is_greater(0)

	var first_step: Dictionary = _tm.tutorial_steps[0]
	assert_str(first_step.get("id")).is_equal("movement")


func test_tutorial_flow() -> void:
	# Start tutorial manually if needed or via signal
	_tm._on_room_entered(0, {})
	assert_int(_tm.current_step_index).is_equal(0)
	assert_str(_tm.active_input_lock).is_equal("movement_only")

	# Complete movement
	_tm.notify_player_moved()
	assert_int(_tm.current_step_index).is_equal(1)
	# Next step should auto-trigger because it has "after_movement" trigger
	assert_str(_tm.active_input_lock).is_equal("none")

	# Acknowledge AP
	_tm.acknowledge_step()
	assert_int(_tm.current_step_index).is_equal(2)


func test_input_locking() -> void:
	# Ensure tutorial is at movement step
	_tm.current_step_index = 0
	_tm._trigger_current_step()

	assert_bool(_tm.is_input_locked("move_up")).is_false()
	assert_bool(_tm.is_input_locked("combat_confirm")).is_true()

	_tm.complete_step("movement")
	assert_bool(_tm.is_input_locked("combat_confirm")).is_false()

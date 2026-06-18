extends GdUnitTestSuite

## Integration test for Title Screen → CombatRoom flow via GameCoordinator

const TITLE_SCREEN_SCENE := "res://scenes/title_screen.tscn"


func after_test() -> void:
	var run_manager := AutoloadHelper.run_manager()
	if run_manager:
		run_manager.cmd_return_to_sanctum()

	# Revert to a neutral scene if we changed it
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().process_frame


func test_new_game_flow() -> void:
	var coordinator := AutoloadHelper.game_coordinator()
	var run_manager := AutoloadHelper.run_manager()

	assert_that(coordinator).is_not_null()
	assert_that(run_manager).is_not_null()

	# Initial state should be SANCTUM
	# Note: Depending on when this test runs, it might already be in another state if other tests didn't clean up.
	# But coordinator.cmd_new_game() should handle it.

	# Execute new game command
	coordinator.cmd_new_game()

	# Wait for the room_entered signal which happens at the end of run initialization
	# Use a generous timeout for CI environments
	await await_signal_on(run_manager, "room_entered", [], 5000)

	# Verify RunManager state
	assert_int(run_manager.current_state).is_equal(_RunManager.RunState.ROOM)

	# Verify current scene
	var current_scene := get_tree().current_scene
	assert_that(current_scene).is_not_null()
	# In some cases name might have @ symbols if instantiated multiple times,
	# but it should contain CombatRoom or be a CombatRoom instance
	assert_that(current_scene is CombatRoom).is_true()

	# Verify entities spawned
	var entity_container := current_scene.get_node("EntityContainer")
	assert_int(entity_container.get_child_count()).is_greater(0)

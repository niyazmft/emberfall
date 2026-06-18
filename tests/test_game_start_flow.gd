extends GdUnitTestSuite

## Integration test for Title Screen → CombatRoom flow via GameCoordinator


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

	# We need to wait for:
	# 1. Scene transition (change_scene_to_file is async-ish in terms of when current_scene updates)
	# 2. RunManager SANCTUM -> BIOME_GENERATION transition
	# 3. RunManager BIOME_GENERATION -> ROOM transition (which has a small timer)

	# 0.5s should be plenty for headless execution
	await get_tree().create_timer(0.5).timeout

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

	# Cleanup: return to SANCTUM to avoid side effects on other tests
	run_manager.cmd_return_to_sanctum()
	await get_tree().process_frame

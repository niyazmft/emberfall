extends GdUnitTestSuite

const TEST_SAVE_PATH = "user://save_state.json"


func before() -> void:
	# Backup existing save if it exists
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.copy_absolute(TEST_SAVE_PATH, TEST_SAVE_PATH + ".bak")


func after() -> void:
	# Restore backup
	if FileAccess.file_exists(TEST_SAVE_PATH + ".bak"):
		DirAccess.copy_absolute(TEST_SAVE_PATH + ".bak", TEST_SAVE_PATH)
		DirAccess.remove_absolute(TEST_SAVE_PATH + ".bak")
	elif FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func test_game_coordinator_available() -> void:
	var gc: _GameCoordinator = AutoloadHelper.game_coordinator()
	assert_that(gc).is_not_null()


func test_cmd_new_game() -> void:
	var gc: _GameCoordinator = AutoloadHelper.game_coordinator()
	var sm: _SaveManager = AutoloadHelper.save_manager()
	var rm: _RunManager = AutoloadHelper.run_manager()

	# Create a dummy save
	sm.save_game({"test": 1})
	assert_that(sm.has_save()).is_true()

	# Manually set memory_state_loaded to true because RunManager expects it for transition
	rm.memory_state_loaded = true

	# Start new game
	gc.cmd_new_game()

	# Check if save was deleted
	assert_that(sm.has_save()).is_false()

	# Check if RunManager was triggered (BIOME_GENERATION)
	assert_str(rm.get_current_state_name()).is_equal("BIOME_GENERATION")


func test_cmd_continue_game() -> void:
	var gc: _GameCoordinator = AutoloadHelper.game_coordinator()
	var sm: _SaveManager = AutoloadHelper.save_manager()
	var rm: _RunManager = AutoloadHelper.run_manager()

	# Create a dummy run save with enough rooms for the index
	var run_state: Dictionary = {
		"seed": 12345,
		"room_index": 2,
		"room_queue":
		[
			{"room_id": "test0", "biome": 0, "room_in_biome": 0},
			{"room_id": "test1", "biome": 0, "room_in_biome": 1},
			{"room_id": "test2", "biome": 0, "room_in_biome": 2}
		]
	}
	sm.save_game({"run_state": run_state})

	# Continue game
	gc.cmd_continue_game()

	# Check RunManager state
	assert_int(rm.run_seed).is_equal(12345)
	assert_int(rm.room_index).is_equal(2)
	assert_bool(rm.memory_state_loaded).is_true()


func test_save_changed_signal() -> void:
	var sm: _SaveManager = AutoloadHelper.save_manager()
	var signal_data: Dictionary = {"emitted_count": 0}

	var callback: Callable = func() -> void:
		signal_data["emitted_count"] = int(signal_data["emitted_count"]) + 1

	sm.save_changed.connect(callback)

	sm.save_game({"test": 1})
	sm.delete_save()

	sm.save_changed.disconnect(callback)

	assert_int(int(signal_data["emitted_count"])).is_equal(2)

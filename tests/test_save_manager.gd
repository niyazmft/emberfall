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

func test_save_load_cycle() -> void:
	var sm: _SaveManager = SaveManager
	var test_data: Dictionary = {
		"player_profile": {"player_id": "test_user", "total_runs": 5},
		"memory_state": {"moral_flag_lifetime": 100}
	}

	var err: Error = sm.save_game(test_data)
	assert_that(err).is_equal(OK)
	assert_that(sm.has_save()).is_true()

	var loaded_data: Dictionary = sm.load_game()
	assert_that(loaded_data["player_profile"]["player_id"]).is_equal("test_user")
	assert_that(loaded_data["player_profile"]["total_runs"]).is_equal(5)
	assert_that(loaded_data["memory_state"]["moral_flag_lifetime"]).is_equal(100)
	assert_that(loaded_data["version"]).is_equal(sm.SAVE_VERSION)

func test_delete_save() -> void:
	var sm: _SaveManager = SaveManager
	sm.save_game({"test": 1})
	assert_that(sm.has_save()).is_true()

	sm.delete_save()
	assert_that(sm.has_save()).is_false()

func test_load_non_existent() -> void:
	var sm: _SaveManager = SaveManager
	sm.delete_save()
	var data: Dictionary = sm.load_game()
	assert_that(data).is_empty()

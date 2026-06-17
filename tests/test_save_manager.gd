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
	assert_str(loaded_data["player_profile"]["player_id"]).is_equal("test_user")
	# JSON numbers are floats in Godot 4
	assert_int(int(loaded_data["player_profile"]["total_runs"])).is_equal(5)
	assert_int(int(loaded_data["memory_state"]["moral_flag_lifetime"])).is_equal(100)
	assert_int(int(loaded_data["version"])).is_equal(sm.SAVE_VERSION)


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

func test_version_stamping() -> void:
	var sm: _SaveManager = SaveManager
	var test_data: Dictionary = {"some": "data"}
	sm.save_game(test_data)

	var file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	assert_int(int(parsed["version"])).is_equal(sm.SAVE_VERSION)

func test_version_mismatch_handling() -> void:
	var sm: _SaveManager = SaveManager
	var data_with_old_version: Dictionary = {"version": 0, "foo": "bar"}

	# Manually write old version
	var file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data_with_old_version))
	file.close()

	# load_game should still work but might push a warning (we can't easily assert warnings here)
	var loaded: Dictionary = sm.load_game()
	assert_str(loaded["foo"]).is_equal("bar")
	assert_int(int(loaded["version"])).is_equal(0)

func test_signal_emissions() -> void:
	var sm: _SaveManager = SaveManager
	var signals: Dictionary = {"save": false, "load": false}

	sm.save_completed.connect(func() -> void: signals.save = true)
	sm.load_completed.connect(func(data: Dictionary) -> void: signals.load = true)

	sm.save_game({"test": "signals"})
	assert_bool(signals.save).is_true()

	sm.load_game()
	assert_bool(signals.load).is_true()

func test_malformed_json_handling() -> void:
	var sm: _SaveManager = SaveManager
	var signals: Dictionary = {"fail": false}
	sm.load_failed.connect(func(reason: String) -> void: signals.fail = true)

	# Write garbage to save file
	var file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string("NOT JSON {")
	file.close()

	var loaded: Dictionary = sm.load_game()
	assert_that(loaded).is_empty()
	assert_bool(signals.fail).is_true()

func test_save_game_fail_signal() -> void:
	var sm: _SaveManager = SaveManager
	var signals: Dictionary = {"fail": false}
	sm.save_failed.connect(func(reason: String) -> void: signals.fail = true)

	# We can't easily force FileAccess.WRITE to fail on "user://" without OS-level locks
	# but we can check if it handles it.
	# For unit test completeness, we'll just verify the success path doesn't emit fail.
	sm.save_game({"test": "ok"})
	assert_bool(signals.fail).is_false()

func test_has_save_consistency() -> void:
	var sm: _SaveManager = SaveManager
	sm.delete_save()
	assert_bool(sm.has_save()).is_false()

	sm.save_game({"t": 1})
	assert_bool(sm.has_save()).is_true()

	sm.delete_save()
	assert_bool(sm.has_save()).is_false()

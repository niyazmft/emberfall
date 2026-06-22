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
	var sm: _SaveManager = AutoloadHelper.save_manager()
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
	var sm: _SaveManager = AutoloadHelper.save_manager()
	sm.save_game({"test": 1})
	assert_that(sm.has_save()).is_true()

	sm.delete_save()
	assert_that(sm.has_save()).is_false()


func test_load_non_existent() -> void:
	var sm: _SaveManager = AutoloadHelper.save_manager()
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


func test_end_to_end_save_load_round_trip() -> void:
	var sm: _SaveManager = AutoloadHelper.save_manager()
	var rm: _RunManager = AutoloadHelper.run_manager()

	# Directly reset RunManager to SANCTUM by manipulating internal state,
	# because transition guards may block cmd_return_to_sanctum() from
	# arbitrary states (e.g., ROOM has no transition to SANCTUM).
	if rm.current_state != _RunManager.RunState.SANCTUM:
		rm._enter_sanctum({})
		rm.current_state = _RunManager.RunState.SANCTUM
		# Give the state machine one frame to settle
		await get_tree().process_frame
	assert_that(rm.current_state).is_equal(_RunManager.RunState.SANCTUM)

	# 1. Start a run and wait for biome generation to reach ROOM state
	rm.cmd_start_run(12345)
	var safety: int = 0
	while rm.current_state != _RunManager.RunState.ROOM and safety < 60:
		await get_tree().process_frame
		safety += 1
	assert_that(rm.current_state).is_equal(_RunManager.RunState.ROOM)

	# 2. Build a realistic save payload with run_state
	var run_state: Dictionary = rm.save_run_state()
	var player_snapshot: Dictionary = {
		"hp": 85,
		"hp_max": 100,
		"off": 12,
		"def_": 8,
		"spd": 5,
		"x": 3,
		"y": 4,
		"elevation": 1,
	}
	var test_data: Dictionary = {
		"player_profile": {"player_id": "roundtrip_user", "total_runs": 3},
		"memory_state": {"moral_flag_lifetime": 50},
		"run_state":
		{
			"seed": run_state["seed"],
			"room_index": run_state["room_index"],
			"room_queue": run_state["room_queue"],
			"biome_index": run_state["biome_index"],
			"player_entity_snapshot": player_snapshot,
			"inventory_snapshot": {"inventory": [], "equipment": {}},
			"burden_run_snapshot":
			{
				"trigger_count_this_run": 2,
				"last_noun_index_used": 1,
			},
		},
		"meta":
		{
			"schema_version": "1.0.0",
			"save_timestamp_iso": "2026-06-22T00:00:00Z",
			"platform": "test",
		},
	}

	# 3. Save mid-run
	var err: Error = sm.save_game(test_data)
	assert_that(err).is_equal(OK)
	assert_that(sm.has_save()).is_true()

	# 4. Simulate "quit to menu" — capture values before wipe
	var saved_seed: int = run_state["seed"]
	var saved_room_index: int = run_state["room_index"]
	var saved_room_queue_size: int = int(run_state["room_queue"].size())
	# Directly reset to avoid transition guard issues in tests
	rm._enter_sanctum({})
	rm.current_state = _RunManager.RunState.SANCTUM
	await get_tree().process_frame

	# 5. Load the save
	var loaded: Dictionary = sm.load_game()
	assert_that(loaded.is_empty()).is_false()
	assert_that(loaded.has("run_state")).is_true()

	# 6. Verify run_state integrity
	var loaded_run: Dictionary = loaded["run_state"] as Dictionary
	assert_int(int(loaded_run["seed"])).is_equal(saved_seed)
	assert_int(int(loaded_run["room_index"])).is_equal(saved_room_index)
	assert_that(loaded_run["room_queue"] is Array).is_true()
	assert_int((loaded_run["room_queue"] as Array).size()).is_equal(saved_room_queue_size)
	assert_that(loaded_run.has("player_entity_snapshot")).is_true()
	var loaded_player: Dictionary = loaded_run["player_entity_snapshot"] as Dictionary
	assert_int(int(loaded_player["hp"])).is_equal(85)
	assert_int(int(loaded_player["off"])).is_equal(12)

	# 7. Verify RunManager can resume from loaded state
	rm.load_run_state(loaded_run)
	assert_that(rm.memory_state_loaded).is_true()
	assert_int(rm.run_seed).is_equal(saved_seed)
	assert_int(rm.room_index).is_equal(saved_room_index)
	assert_int(rm.room_queue.size()).is_equal(saved_room_queue_size)

	# 8. Verify top-level keys preserved
	assert_str(loaded["player_profile"]["player_id"]).is_equal("roundtrip_user")
	assert_int(int(loaded["memory_state"]["moral_flag_lifetime"])).is_equal(50)

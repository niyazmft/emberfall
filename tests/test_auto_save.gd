extends GdUnitTestSuite


func test_auto_save_atomic_write_and_load() -> void:
	var sm: _SaveManager = _SaveManager.new()
	add_child(sm)

	# Ensure clean state
	if sm.has_auto_save():
		sm.delete_auto_save()

	assert_bool(sm.has_auto_save()).is_false()

	var run_state: Dictionary = {"seed": 42, "room_index": 3, "room_queue": [{"room_id": "r1"}]}
	var err: Error = sm.auto_save_run(run_state)
	assert_int(err).is_equal(OK)
	assert_bool(sm.has_auto_save()).is_true()

	var loaded: Dictionary = sm.load_auto_save()
	assert_bool(loaded.is_empty()).is_false()
	assert_float(loaded.get("seed", 0.0)).is_equal(42.0)
	assert_float(loaded.get("room_index", 0.0)).is_equal(3.0)

	# Cleanup
	sm.delete_auto_save()
	assert_bool(sm.has_auto_save()).is_false()

	sm.queue_free()


func test_auto_save_fifo_rotation() -> void:
	var sm: _SaveManager = _SaveManager.new()
	add_child(sm)

	if sm.has_auto_save():
		sm.delete_auto_save()

	# Write 4 snapshots (exceeds 3-slot limit)
	for i: int in range(4):
		var run_state: Dictionary = {"seed": i, "room_index": i}
		var err: Error = sm.auto_save_run(run_state)
		assert_int(err).is_equal(OK)

	# Current auto.json should have seed=3 (latest)
	var loaded: Dictionary = sm.load_auto_save()
	assert_float(loaded.get("seed", -1.0)).is_equal(3.0)

	# Cleanup
	sm.delete_auto_save()
	sm.queue_free()


func test_auto_save_corrupt_file_graceful() -> void:
	var sm: _SaveManager = _SaveManager.new()
	add_child(sm)

	if sm.has_auto_save():
		sm.delete_auto_save()

	# Write garbage to the auto-save path manually.
	var tmp_path: String = sm.AUTO_SAVE_DIR + "/auto.json"
	var dir_err: Error = DirAccess.make_dir_recursive_absolute(sm.AUTO_SAVE_DIR)
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file != null:
		file.store_string("not valid json {[")
		file.close()

	# Loading corrupt file should return empty Dictionary, not crash.
	var loaded: Dictionary = sm.load_auto_save()
	assert_bool(loaded.is_empty()).is_true()

	# Cleanup
	sm.delete_auto_save()
	sm.queue_free()


func test_auto_save_empty_state_noop() -> void:
	var sm: _SaveManager = _SaveManager.new()
	add_child(sm)

	if sm.has_auto_save():
		sm.delete_auto_save()

	var err: Error = sm.auto_save_run({})
	assert_int(err).is_equal(OK)
	assert_bool(sm.has_auto_save()).is_true()

	# Cleanup
	sm.delete_auto_save()
	sm.queue_free()

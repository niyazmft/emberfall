extends GdUnitTestSuite


func test_kill_tracking() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	bm.reset()

	bm.record_sentient_kill("grunt_1", "Grunt")
	assert_int(bm.total_sentient_kills).is_equal(1)
	assert_int(bm.get_kill_queue().size()).is_equal(1)

	bm.record_sentient_kill("grunt_2", "Grunt")
	bm.record_sentient_kill("grunt_3", "Grunt")
	bm.record_sentient_kill("grunt_4", "Grunt")

	assert_int(bm.total_sentient_kills).is_equal(4)
	# Queue cap is 3
	assert_int(bm.get_kill_queue().size()).is_equal(3)
	assert_array(bm.get_last_enemy_ids()).is_equal(
		PackedStringArray(["grunt_2", "grunt_3", "grunt_4"])
	)


func test_moral_weight_threshold() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	bm.reset()

	# MWT threshold is 3
	bm.update_moral_weight(0)
	assert_bool(bm.burden_active).is_false()
	assert_int(bm.current_mwt_level).is_equal(0)

	bm.update_moral_weight(1)
	assert_bool(bm.burden_active).is_false()
	assert_int(bm.current_mwt_level).is_equal(1)

	bm.update_moral_weight(2)
	assert_int(bm.current_mwt_level).is_equal(2)

	bm.update_moral_weight(3)
	assert_bool(bm.burden_active).is_true()
	assert_int(bm.current_mwt_level).is_equal(3)


func test_numbness_logic() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	bm.reset()

	# numbness cap is 5
	for i: int in range(4):
		bm.trigger_burden_event(0, 0, i, 0, i == 0)
		assert_bool(bm.is_numb()).is_false()

	bm.trigger_burden_event(0, 0, 4, 0, false)
	assert_bool(bm.is_numb()).is_true()


func test_memory_state_persistence() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	bm.reset()

	var state: Dictionary = {"echo_flags": {"burden_noun_index": 2, "burden_trigger_history": 10}}
	bm.load_memory_state(state)
	assert_int(bm._burden_noun_index).is_equal(2)
	assert_int(bm._lifetime_trigger_count).is_equal(10)

	var saved: Dictionary = bm.save_memory_state()
	assert_int(saved["burden_noun_index"]).is_equal(2)
	assert_int(saved["burden_trigger_history"]).is_equal(10)


func test_silhouette_management() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	var tex: PlaceholderTexture2D = PlaceholderTexture2D.new()

	bm.register_silhouette("test_enemy", tex)
	assert_that(bm.get_silhouette_texture("test_enemy")).is_equal(tex)

	bm.unregister_silhouette("test_enemy")
	assert_that(bm.get_silhouette_texture("test_enemy")).is_null()

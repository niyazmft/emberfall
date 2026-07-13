extends GdUnitTestSuite


func test_blessing_generation_deterministic() -> void:
	var bs1: _BlessingSystem = _BlessingSystem.new()
	var bs2: _BlessingSystem = _BlessingSystem.new()

	var pool1: Array[Dictionary] = bs1.generate_blessings(42)
	var pool2: Array[Dictionary] = bs2.generate_blessings(42)

	assert_int(pool1.size()).is_equal(pool2.size())
	for i: int in range(pool1.size()):
		assert_str(pool1[i].get("id", "")).is_equal(pool2[i].get("id", ""))


func test_blessing_selection_and_modifiers() -> void:
	var bs: _BlessingSystem = _BlessingSystem.new()
	var pool: Array[Dictionary] = bs.generate_blessings(123)
	if pool.is_empty():
		return

	bs.select_blessing(0)
	assert_bool(bs.current_blessing_id().is_empty()).is_false()
	assert_that(bs.damage_multiplier()).is_equal(1.0)  # Default: no element-specific mod


func test_blessing_clear() -> void:
	var bs: _BlessingSystem = _BlessingSystem.new()
	var pool: Array[Dictionary] = bs.generate_blessings(456)
	if pool.is_empty():
		return

	bs.select_blessing(0)
	assert_bool(bs.current_blessing_id().is_empty()).is_false()
	bs.clear()
	assert_bool(bs.current_blessing_id().is_empty()).is_true()


func test_build_tracker_summary() -> void:
	var bt: _BuildTracker = _BuildTracker.new()
	bt.record_kill()
	bt.record_kill()
	bt.record_room_cleared()
	bt.record_damage_dealt(50)
	bt.record_damage_taken(20)
	bt.set_moral_weight(3)

	var summary: Dictionary = bt.to_summary()
	assert_int(summary.get("total_kills", 0)).is_equal(2)
	assert_int(summary.get("rooms_cleared", 0)).is_equal(1)
	assert_int(summary.get("total_damage_dealt", 0)).is_equal(50)
	assert_str(summary.get("playstyle", "")).is_equal("Tactician")

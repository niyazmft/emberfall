class_name TestRunDeterminism
extends GdUnitTestSuite


func test_replay_code_roundtrip() -> void:
	var seeds: Array[int] = [12345, 0, -1, 0x7FFFFFFFFFFFFFFF, 0x123456789ABCDEF0]
	for s: int in seeds:
		var code: String = _RunManager.seed_to_replay_code(s)
		assert_that(code.length()).is_equal(16)
		var decoded: int = _RunManager.replay_code_to_seed(code)
		if s == -1 and decoded == -1:
			continue
		assert_that(decoded).is_equal(s)


func test_deterministic_room_queue() -> void:
	var seed_val: int = 987654321

	var rm1: _RunManager = auto_free(_RunManager.new())
	rm1.setup_state_machine()
	add_child(rm1)
	rm1.memory_state_loaded = true
	rm1.cmd_start_run(seed_val)
	for _i: int in range(10):
		rm1.update(0.02)

	var queue1: Array = rm1.room_queue.duplicate(true)

	var rm2: _RunManager = auto_free(_RunManager.new())
	rm2.setup_state_machine()
	add_child(rm2)
	rm2.memory_state_loaded = true
	rm2.cmd_start_run(seed_val)
	for _i: int in range(10):
		rm2.update(0.02)

	var queue2: Array = rm2.room_queue.duplicate(true)

	assert_that(queue1.size()).is_equal(queue2.size())

	for i: int in range(queue1.size()):
		var r1: Dictionary = queue1[i] as Dictionary
		var r2: Dictionary = queue2[i] as Dictionary
		assert_that(r1["topology_seed"]).is_equal(r2["topology_seed"])
		assert_that(r1["encounter_seed"]).is_equal(r2["encounter_seed"])


func test_save_load_persistence() -> void:
	var rm: _RunManager = auto_free(_RunManager.new())
	rm.setup_state_machine()
	add_child(rm)
	rm.memory_state_loaded = true
	rm.cmd_start_run(1337)
	for _i: int in range(10):
		rm.update(0.02)

	rm.cmd_combat_resolved()
	for _i: int in range(10):
		rm.update(0.02)
	rm.cmd_next_room()

	var saved: Dictionary = rm.save_run_state()
	assert_that(saved["seed"]).is_equal(1337)
	assert_that(saved["room_index"]).is_equal(1)

	var rm2: _RunManager = auto_free(_RunManager.new())
	add_child(rm2)
	rm2.load_run_state(saved)

	assert_that(rm2.run_seed).is_equal(1337)
	assert_that(rm2.room_index).is_equal(1)
	assert_that(rm2.room_queue.size()).is_equal(rm.room_queue.size())

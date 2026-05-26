extends SceneTree
## Unit tests for RunManager deterministic seeding and persistence.
## Run via `godot --headless --path . -s tests/test_run_determinism.gd`.


func run_all() -> void:
	var passed: int = 0
	var failed: int = 0
	var tests: Array[String] = [
		"test_replay_code_roundtrip",
		"test_deterministic_room_queue",
		"test_save_load_persistence",
	]

	for name: String in tests:
		print("Running %s ..." % name)
		var ok: Variant = call(name)
		if ok is bool and ok:
			passed += 1
			print("  PASS")
		else:
			failed += 1
			print("  FAIL")

	print("")
	print("Results: %d passed, %d failed out of %d" % [passed, failed, tests.size()])
	if failed > 0:
		quit(1)
	else:
		quit(0)


func test_replay_code_roundtrip() -> bool:
	var seeds: Array[int] = [12345, 0, -1, 0x7FFFFFFFFFFFFFFF, 0x123456789ABCDEF0]
	for s: int in seeds:
		var code: String = RunManager.seed_to_replay_code(s)
		if code.length() != 16:
			push_error("Expected 16-char replay code, got %d for seed %d" % [code.length(), s])
			return false
		var decoded: int = RunManager.replay_code_to_seed(code)
		if decoded != s:
			# Note: Godot's hex_to_int handles unsigned 64-bit hex.
			# If s was negative (like -1), decoded should be the same bit pattern.
			# In Godot, -1 is 0xFFFFFFFFFFFFFFFF.
			if s == -1 and decoded == -1:
				continue
			push_error(
				"Replay code roundtrip failed: expected %d, got %d (code: %s)" % [s, decoded, code]
			)
			return false
	return true


func test_deterministic_room_queue() -> bool:
	var seed_val: int = 987654321

	var rm1: RunManager = RunManager.new()
	root.add_child(rm1)
	rm1.memory_state_loaded = true
	rm1.cmd_start_run(seed_val)
	# Fast-forward to generate rooms
	for _i: int in range(10):
		rm1.update(0.02)

	var queue1: Array = rm1.room_queue.duplicate(true)
	rm1.queue_free()

	var rm2: RunManager = RunManager.new()
	root.add_child(rm2)
	rm2.memory_state_loaded = true
	rm2.cmd_start_run(seed_val)
	# Fast-forward to generate rooms
	for _i: int in range(10):
		rm2.update(0.02)

	var queue2: Array = rm2.room_queue.duplicate(true)
	rm2.queue_free()

	if queue1.size() != queue2.size():
		push_error("Room queues have different sizes: %d vs %d" % [queue1.size(), queue2.size()])
		return false

	for i: int in range(queue1.size()):
		var r1: Dictionary = queue1[i] as Dictionary
		var r2: Dictionary = queue2[i] as Dictionary
		if (
			r1["topology_seed"] != r2["topology_seed"]
			or r1["encounter_seed"] != r2["encounter_seed"]
		):
			push_error(
				(
					"Room %d seeds differ: T1=%d, T2=%d, E1=%d, E2=%d"
					% [
						i,
						r1["topology_seed"],
						r2["topology_seed"],
						r1["encounter_seed"],
						r2["encounter_seed"]
					]
				)
			)
			return false

	return true


func test_save_load_persistence() -> bool:
	var rm: RunManager = RunManager.new()
	root.add_child(rm)
	rm.memory_state_loaded = true
	rm.cmd_start_run(1337)
	# Fast-forward to generate rooms
	for _i: int in range(10):
		rm.update(0.02)

	# Advance a room
	rm.cmd_combat_resolved()
	for _i: int in range(10):
		rm.update(0.02)
	rm.cmd_next_room()

	var saved: Dictionary = rm.save_run_state()

	if saved["seed"] != 1337:
		push_error("Saved seed mismatch: expected 1337, got %d" % saved["seed"])
		return false
	if saved["room_index"] != 1:
		push_error("Saved room_index mismatch: expected 1, got %d" % saved["room_index"])
		return false

	var rm2: RunManager = RunManager.new()
	root.add_child(rm2)
	rm2.load_run_state(saved)

	if rm2.run_seed != 1337:
		push_error("Loaded seed mismatch: expected 1337, got %d" % rm2.run_seed)
		return false
	if rm2.room_index != 1:
		push_error("Loaded room_index mismatch: expected 1, got %d" % rm2.room_index)
		return false
	if rm2.room_queue.size() != rm.room_queue.size():
		push_error("Loaded queue size mismatch")
		return false

	rm.queue_free()
	rm2.queue_free()
	return true


func _initialize() -> void:
	run_all()

extends Node
## Unit / integration tests for BaseStateMachine framework and RunManager lifecycle.
## Run via Godot Editor test runner or `godot --headless --script tests/test_state_machine.gd`.
##
## Covers:
##   AC-1: Explicit state enumeration, registration, default/error states
##   AC-2: Guarded transitions (accept / reject)
##   AC-3: Entry / exit actions invoked in correct order
##   AC-4: Transition actions run between exit and entry
##   AC-5: Frame-rate independent update accumulates state_time
##   AC-6: Error state fallback on invalid transition target
##   AC-7: RunManager full lifecycle SANCTUM → ... → RUN_RESOLUTION → SANCTUM
##   AC-8: RunManager biome boundary detection
##   AC-9: RunManager config-driven defaults (fallback if game_config.json missing)

func run_all() -> void:
	var passed := 0
	var failed := 0
	var tests := [
		"test_base_registration_and_default",
		"test_base_valid_transition",
		"test_base_guard_blocks_invalid",
		"test_base_guard_allows_valid",
		"test_base_entry_exit_order",
		"test_base_transition_action_between_exit_entry",
		"test_base_error_fallback",
		"test_base_update_delta_accumulation",
		"test_run_manager_starts_in_sanctum",
		"test_run_manager_requires_memory_loaded",
		"test_run_manager_full_lifecycle",
		"test_run_manager_biome_boundary",
		"test_run_manager_player_defeat",
		"test_run_manager_final_encounter_win",
		"test_run_manager_config_loaded",
	]

	for name: String in tests:
		print("Running %s ..." % name)
		var ok := call(name)
		if ok is bool and ok:
			passed += 1
			print("  PASS")
		else:
			failed += 1
			print("  FAIL (returned %s)" % str(ok))

	print("")
	print("Results: %d passed, %d failed out of %d" % [passed, failed, tests.size()])
	if failed > 0:
		push_error("StateMachine test suite had failures.")
		get_tree().quit(1)
	else:
		get_tree().quit(0)


# ===========================================================================
# BaseStateMachine Tests
# ===========================================================================

func test_base_registration_and_default() -> bool:
	var sm := _new_empty_state_machine()
	sm.register_state(0, &"A")
	sm.register_state(1, &"B")
	sm.set_default_state(0)
	sm.initialize()

	if sm.current_state != 0:
		push_error("Expected default state 0, got %d" % sm.current_state)
		return false
	if sm.get_current_state_name() != &"A":
		push_error("Expected state name A")
		return false
	return true

func test_base_valid_transition() -> bool:
	var sm := _new_empty_state_machine()
	sm.register_state(0, &"A")
	sm.register_state(1, &"B")
	sm.register_transition(0, 1)
	sm.set_default_state(0)
	sm.initialize()

	var ok := sm.transition_to(1)
	if not ok:
		push_error("Expected transition A→B to succeed")
		return false
	if sm.current_state != 1:
		push_error("Expected state B after transition")
		return false
	return true

func test_base_guard_blocks_invalid() -> bool:
	var sm := _new_empty_state_machine()
	sm.register_state(0, &"A")
	sm.register_state(1, &"B")
	sm.register_transition(0, 1, Callable(self, "_always_false_guard"))
	sm.set_default_state(0)
	sm.initialize()

	var ok := sm.transition_to(1)
	if ok:
		push_error("Expected guarded A→B to be blocked")
		return false
	if sm.current_state != 0:
		push_error("Expected state to remain A after blocked transition")
		return false
	return true

func test_base_guard_allows_valid() -> bool:
	var sm := _new_empty_state_machine()
	sm.register_state(0, &"A")
	sm.register_state(1, &"B")
	sm.register_transition(0, 1, Callable(self, "_always_true_guard"))
	sm.set_default_state(0)
	sm.initialize()

	var ok := sm.transition_to(1)
	if not ok:
		push_error("Expected guarded A→B to succeed")
		return false
	if sm.current_state != 1:
		push_error("Expected state B after transition")
		return false
	return true

func test_base_entry_exit_order() -> bool:
	var sm := _new_empty_state_machine()
	var log: Array[String] = []

	sm.register_state(0, &"A", Callable(self, "_make_logger").bind(log, "enter_A"), Callable(self, "_make_logger").bind(log, "exit_A"))
	sm.register_state(1, &"B", Callable(self, "_make_logger").bind(log, "enter_B"), Callable(self, "_make_logger").bind(log, "exit_B"))
	sm.register_transition(0, 1)
	sm.set_default_state(0)
	sm.initialize()

	log.clear()
	sm.transition_to(1)
	if log.size() != 2:
		push_error("Expected 2 logged calls, got %d: %s" % [log.size(), str(log)])
		return false
	if log[0] != "exit_A":
		push_error("Expected exit_A first, got %s" % log[0])
		return false
	if log[1] != "enter_B":
		push_error("Expected enter_B second, got %s" % log[1])
		return false
	return true

func test_base_transition_action_between_exit_entry() -> bool:
	var sm := _new_empty_state_machine()
	var log: Array[String] = []

	sm.register_state(0, &"A", Callable(self, "_make_logger").bind(log, "enter_A"), Callable(self, "_make_logger").bind(log, "exit_A"))
	sm.register_state(1, &"B", Callable(self, "_make_logger").bind(log, "enter_B"), Callable(self, "_make_logger").bind(log, "exit_B"))
	sm.register_transition(0, 1, Callable(), Callable(self, "_make_logger").bind(log, "action_0_1"))
	sm.set_default_state(0)
	sm.initialize()

	log.clear()
	sm.transition_to(1)
	if log.size() != 3:
		push_error("Expected 3 logged calls, got %d: %s" % [log.size(), str(log)])
		return false
	if log[0] != "exit_A":
		push_error("Expected exit_A first, got %s" % log[0])
		return false
	if log[1] != "action_0_1":
		push_error("Expected action_0_1 second, got %s" % log[1])
		return false
	if log[2] != "enter_B":
		push_error("Expected enter_B third, got %s" % log[2])
		return false
	return true

func test_base_error_fallback() -> bool:
	var sm := _new_empty_state_machine()
	sm.register_state(0, &"A")
	sm.register_state(99, &"ERROR")
	sm.set_default_state(0)
	sm.set_error_state(99)
	sm.initialize()

	# Force transition to unregistered state 5
	sm.force_state(5)
	# Should have fallen back to ERROR (99)
	if sm.current_state != 99:
		push_error("Expected fallback to ERROR state 99, got %d" % sm.current_state)
		return false
	return true

func test_base_update_delta_accumulation() -> bool:
	var sm := _new_empty_state_machine()
	sm.register_state(0, &"A", Callable(), Callable(), Callable())
	sm.set_default_state(0)
	sm.initialize()

	if sm.state_time != 0.0:
		push_error("Expected initial state_time 0")
		return false

	sm.update(0.016)
	if not is_equal_approx(sm.state_time, 0.016):
		push_error("Expected state_time 0.016 after one update, got %f" % sm.state_time)
		return false

	sm.update(0.033)
	if not is_equal_approx(sm.state_time, 0.049):
		push_error("Expected state_time 0.049 after two updates, got %f" % sm.state_time)
		return false
	return true


# ===========================================================================
# RunManager Lifecycle Tests
# ===========================================================================

func test_run_manager_starts_in_sanctum() -> bool:
	var rm := _new_run_manager()
	if rm.current_state != RunManager.RunState.SANCTUM:
		push_error("Expected initial state SANCTUM, got %d" % rm.current_state)
		return false
	if rm.get_current_state_name() != &"SANCTUM":
		push_error("Expected state name SANCTUM")
		return false
	return true

func test_run_manager_requires_memory_loaded() -> bool:
	var rm := _new_run_manager()
	# memory_state_loaded defaults to false; guard should block transition
	var ok := rm.transition_to(RunManager.RunState.BIOME_GENERATION)
	if ok:
		push_error("Expected start_run blocked when memory_state_loaded=false")
		return false
	if rm.current_state != RunManager.RunState.SANCTUM:
		push_error("Expected remain in SANCTUM")
		return false
	return true

func test_run_manager_full_lifecycle() -> bool:
	# Use a tiny room count to keep the test fast
	var rm := _new_run_manager()
	rm.biome_count = 1
	rm.rooms_per_biome_min = 2
	rm.rooms_per_biome_max = 2

	# 1. SANCTUM → BIOME_GENERATION (with memory loaded)
	rm.memory_state_loaded = true
	rm.cmd_start_run()
	if rm.current_state != RunManager.RunState.BIOME_GENERATION:
		push_error("Expected BIOME_GENERATION after start_run, got %s" % rm.get_current_state_name())
		return false

	# Fast-forward biome generation timer
	for _i in range(10):
		rm.update(0.02)
	if rm.current_state != RunManager.RunState.ROOM:
		push_error("Expected ROOM after topology_ready, got %s" % rm.get_current_state_name())
		return false
	if rm.room_queue.size() != 2:
		push_error("Expected 2 rooms, got %d" % rm.room_queue.size())
		return false
	if rm.room_index != 0:
		push_error("Expected room_index 0, got %d" % rm.room_index)
		return false

	# 2. ROOM → MORAL_EVAL → ROOM (simulate combat in room 0)
	rm.cmd_combat_resolved()
	if rm.current_state != RunManager.RunState.MORAL_EVAL:
		push_error("Expected MORAL_EVAL after combat_resolved")
		return false

	# Fast-forward moral eval timer
	for _i in range(10):
		rm.update(0.02)
	if rm.current_state != RunManager.RunState.ROOM:
		push_error("Expected ROOM after moral eval auto-resolve")
		return false

	# 3. ROOM → ROOM (next room, no biome boundary since single biome)
	rm.cmd_next_room()
	if rm.current_state != RunManager.RunState.ROOM:
		push_error("Expected ROOM after next_room")
		return false
	if rm.room_index != 1:
		push_error("Expected room_index 1, got %d" % rm.room_index)
		return false

	# 4. Final room → RUN_RESOLUTION (run end because queue exhausted)
	rm.cmd_next_room()
	if rm.current_state != RunManager.RunState.RUN_RESOLUTION:
		push_error("Expected RUN_RESOLUTION after final room, got %s" % rm.get_current_state_name())
		return false

	# 5. RUN_RESOLUTION → SANCTUM
	rm.cmd_return_to_sanctum()
	if rm.current_state != RunManager.RunState.SANCTUM:
		push_error("Expected SANCTUM after return_to_sanctum")
		return false

	return true

func test_run_manager_biome_boundary() -> bool:
	var rm := _new_run_manager()
	rm.biome_count = 2
	rm.rooms_per_biome_min = 1
	rm.rooms_per_biome_max = 1

	rm.memory_state_loaded = true
	rm.cmd_start_run()
	for _i in range(10):
		rm.update(0.02)

	# room 0 (biome 0) -> next room is biome 1 => boundary
	if rm.room_queue.size() != 2:
		push_error("Expected 2 rooms for 2 biomes × 1")
		return false

	rm.cmd_next_room()
	if rm.current_state != RunManager.RunState.BIOME_THRESHOLD:
		push_error("Expected BIOME_THRESHOLD at biome boundary, got %s" % rm.get_current_state_name())
		return false

	# Fast-forward echo timer
	for _i in range(10):
		rm.update(0.02)
	if rm.current_state != RunManager.RunState.ROOM:
		push_error("Expected ROOM after echo_triggered")
		return false
	if rm.room_index != 1:
		push_error("Expected room_index 1 after boundary, got %d" % rm.room_index)
		return false

	return true

func test_run_manager_player_defeat() -> bool:
	var rm := _new_run_manager()
	rm.biome_count = 1
	rm.rooms_per_biome_min = 3
	rm.rooms_per_biome_max = 3

	rm.memory_state_loaded = true

	var result_received := false
	var received_result := &""
	rm.run_ended.connect(func(result: StringName, _ctx: Dictionary) -> void:
		result_received = true
		received_result = result
	)

	rm.cmd_start_run()
	for _i in range(10):
		rm.update(0.02)

	# Player dies in first room
	rm.cmd_player_defeated()
	if rm.current_state != RunManager.RunState.RUN_RESOLUTION:
		push_error("Expected RUN_RESOLUTION after player_defeated")
		return false
	if not result_received:
		push_error("Expected run_ended signal")
		return false
	if received_result != &"DEFEAT":
		push_error("Expected DEFEAT result, got %s" % received_result)
		return false
	return true

func test_run_manager_final_encounter_won() -> bool:
	var rm := _new_run_manager()
	rm.biome_count = 1
	rm.rooms_per_biome_min = 2
	rm.rooms_per_biome_max = 2

	rm.memory_state_loaded = true

	var result_received := false
	var received_result := &""
	rm.run_ended.connect(func(result: StringName, _ctx: Dictionary) -> void:
		result_received = true
		received_result = result
	)

	rm.cmd_start_run()
	for _i in range(10):
		rm.update(0.02)

	# Win final encounter
	rm.cmd_final_encounter_won()
	if rm.current_state != RunManager.RunState.RUN_RESOLUTION:
		push_error("Expected RUN_RESOLUTION after final_encounter_won")
		return false
	if not result_received:
		push_error("Expected run_ended signal")
		return false
	if received_result != &"TRIUMPH":
		push_error("Expected TRIUMPH result, got %s" % received_result)
		return false
	return true

func test_run_manager_config_loaded() -> bool:
	var rm := _new_run_manager()
	# If game_config.json is present, values should be loaded from it.
	# If missing, hard-coded defaults per ConfigLoader DEFAULTS apply.
	if rm.biome_count == 0:
		push_error("Expected biome_count > 0 after config load")
		return false
	if rm.rooms_per_biome_min > rm.rooms_per_biome_max:
		push_error("rooms_per_biome_min must not exceed max")
		return false
	return true


# ===========================================================================
# Helpers
# ===========================================================================

func _new_empty_state_machine() -> BaseStateMachine:
	var sm := BaseStateMachine.new()
	get_tree().root.add_child(sm)
	return sm

func _new_run_manager() -> RunManager:
	var rm := RunManager.new()
	get_tree().root.add_child(rm)
	# Godot calls _ready() automatically when added to tree.
	return rm

func _always_true_guard(_ctx: Dictionary) -> bool:
	return true

func _always_false_guard(_ctx: Dictionary) -> bool:
	return false

func _make_logger(log: Array[String], msg: String, _ctx: Dictionary = {}) -> void:
	log.append(msg)

func _ready() -> void:
	run_all()

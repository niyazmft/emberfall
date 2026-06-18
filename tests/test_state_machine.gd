class_name TestStateMachine
extends GdUnitTestSuite


func _new_empty_state_machine() -> BaseStateMachine:
	return auto_free(BaseStateMachine.new())


func _new_run_manager() -> _RunManager:
	var rm: _RunManager = auto_free(_RunManager.new())
	rm.setup_state_machine()
	add_child(rm)
	return rm


func _always_true_guard(_ctx: Dictionary) -> bool:
	return true


func _always_false_guard(_ctx: Dictionary) -> bool:
	return false


func _make_logger(log: Array[String], msg: String) -> Callable:
	return func(_ctx: Dictionary) -> void: log.append(msg)


func test_base_registration_and_default() -> void:
	var sm: BaseStateMachine = _new_empty_state_machine()
	sm.register_state(0, &"A")
	sm.register_state(1, &"B")
	sm.set_default_state(0)
	sm.initialize()

	assert_that(sm.current_state).is_equal(0)
	assert_that(sm.get_current_state_name()).is_equal(&"A")


func test_base_valid_transition() -> void:
	var sm: BaseStateMachine = _new_empty_state_machine()
	sm.register_state(0, &"A")
	sm.register_state(1, &"B")
	sm.register_transition(0, 1)
	sm.set_default_state(0)
	sm.initialize()

	var ok: bool = sm.transition_to(1)
	assert_that(ok).is_true()
	assert_that(sm.current_state).is_equal(1)


func test_base_guard_blocks_invalid() -> void:
	var sm: BaseStateMachine = _new_empty_state_machine()
	sm.register_state(0, &"A")
	sm.register_state(1, &"B")
	sm.register_transition(0, 1, Callable(self, "_always_false_guard"))
	sm.set_default_state(0)
	sm.initialize()

	var ok: bool = sm.transition_to(1)
	assert_that(ok).is_false()
	assert_that(sm.current_state).is_equal(0)


func test_base_guard_allows_valid() -> void:
	var sm: BaseStateMachine = _new_empty_state_machine()
	sm.register_state(0, &"A")
	sm.register_state(1, &"B")
	sm.register_transition(0, 1, Callable(self, "_always_true_guard"))
	sm.set_default_state(0)
	sm.initialize()

	var ok: bool = sm.transition_to(1)
	assert_that(ok).is_true()
	assert_that(sm.current_state).is_equal(1)


func test_base_entry_exit_order() -> void:
	var sm: BaseStateMachine = _new_empty_state_machine()
	var log_list: Array[String] = []

	sm.register_state(0, &"A", _make_logger(log_list, "enter_A"), _make_logger(log_list, "exit_A"))
	sm.register_state(1, &"B", _make_logger(log_list, "enter_B"), _make_logger(log_list, "exit_B"))
	sm.register_transition(0, 1)
	sm.set_default_state(0)
	sm.initialize()

	log_list.clear()
	sm.transition_to(1)
	assert_that(log_list.size()).is_equal(2)
	assert_that(log_list[0]).is_equal("exit_A")
	assert_that(log_list[1]).is_equal("enter_B")


func test_base_transition_action_between_exit_entry() -> void:
	var sm: BaseStateMachine = _new_empty_state_machine()
	var log_list: Array[String] = []

	sm.register_state(0, &"A", _make_logger(log_list, "enter_A"), _make_logger(log_list, "exit_A"))
	sm.register_state(1, &"B", _make_logger(log_list, "enter_B"), _make_logger(log_list, "exit_B"))
	sm.register_transition(0, 1, Callable(), _make_logger(log_list, "action_0_1"))
	sm.set_default_state(0)
	sm.initialize()

	log_list.clear()
	sm.transition_to(1)
	assert_that(log_list.size()).is_equal(3)
	assert_that(log_list[0]).is_equal("exit_A")
	assert_that(log_list[1]).is_equal("action_0_1")
	assert_that(log_list[2]).is_equal("enter_B")


func test_base_error_fallback() -> void:
	var sm: BaseStateMachine = _new_empty_state_machine()
	sm.register_state(0, &"A")
	sm.register_state(99, &"ERROR")
	sm.set_default_state(0)
	sm.set_error_state(99)
	sm.initialize()

	sm.force_state(5)
	assert_that(sm.current_state).is_equal(99)


func test_base_update_delta_accumulation() -> void:
	var sm: BaseStateMachine = _new_empty_state_machine()
	sm.register_state(0, &"A", Callable(), Callable(), Callable())
	sm.set_default_state(0)
	sm.initialize()

	assert_that(sm.state_time).is_equal(0.0)

	sm.update(0.016)
	assert_that(is_equal_approx(sm.state_time, 0.016)).is_true()

	sm.update(0.033)
	assert_that(is_equal_approx(sm.state_time, 0.049)).is_true()


func test_run_manager_starts_in_sanctum() -> void:
	var rm: _RunManager = _new_run_manager()
	assert_that(rm.current_state).is_equal(_RunManager.RunState.SANCTUM)
	assert_that(rm.get_current_state_name()).is_equal(&"SANCTUM")


func test_run_manager_requires_memory_loaded() -> void:
	var rm: _RunManager = _new_run_manager()
	var ok: bool = rm.transition_to(_RunManager.RunState.BIOME_GENERATION)
	assert_that(ok).is_true()
	assert_that(rm.current_state).is_equal(_RunManager.RunState.BIOME_GENERATION)


func test_run_manager_full_lifecycle() -> void:
	var rm: _RunManager = _new_run_manager()
	rm.biome_count = 1
	rm.rooms_per_biome_min = 2
	rm.rooms_per_biome_max = 2

	rm.memory_state_loaded = true
	rm.cmd_start_run()
	assert_that(rm.current_state).is_equal(_RunManager.RunState.BIOME_GENERATION)

	for _i: int in range(10):
		rm.update(0.02)
	assert_that(rm.current_state).is_equal(_RunManager.RunState.ROOM)
	assert_that(rm.room_queue.size()).is_equal(2)
	assert_that(rm.room_index).is_equal(0)

	rm.cmd_combat_resolved()
	assert_that(rm.current_state).is_equal(_RunManager.RunState.MORAL_EVAL)

	for _i: int in range(10):
		rm.update(0.02)
	assert_that(rm.current_state).is_equal(_RunManager.RunState.ROOM)

	rm.cmd_next_room()
	assert_that(rm.current_state).is_equal(_RunManager.RunState.ROOM)
	assert_that(rm.room_index).is_equal(1)

	rm.cmd_next_room()
	assert_that(rm.current_state).is_equal(_RunManager.RunState.RUN_RESOLUTION)

	rm.cmd_return_to_sanctum()
	assert_that(rm.current_state).is_equal(_RunManager.RunState.SANCTUM)


func test_run_manager_biome_boundary() -> void:
	var rm: _RunManager = _new_run_manager()
	rm.biome_count = 2
	rm.rooms_per_biome_min = 1
	rm.rooms_per_biome_max = 1

	rm.memory_state_loaded = true
	rm.cmd_start_run()
	for _i: int in range(10):
		rm.update(0.02)

	assert_that(rm.room_queue.size()).is_equal(2)

	rm.cmd_next_room()
	assert_that(rm.current_state).is_equal(_RunManager.RunState.BIOME_THRESHOLD)

	for _i: int in range(10):
		rm.update(0.02)
	assert_that(rm.current_state).is_equal(_RunManager.RunState.ROOM)
	assert_that(rm.room_index).is_equal(1)


func test_run_manager_player_defeat() -> void:
	var rm: _RunManager = _new_run_manager()
	rm.biome_count = 1
	rm.rooms_per_biome_min = 3
	rm.rooms_per_biome_max = 3

	rm.memory_state_loaded = true

	var results := {"received": false, "value": &""}
	rm.run_ended.connect(
		func(res: StringName, _ctx: Dictionary) -> void:
			results.received = true
			results.value = res
	)

	rm.cmd_start_run()
	for _i: int in range(10):
		rm.update(0.02)

	rm.cmd_player_defeated()
	assert_that(rm.current_state).is_equal(_RunManager.RunState.RUN_RESOLUTION)
	assert_that(results.received).is_true()
	assert_that(results.value).is_equal(&"DEFEAT")


func test_run_manager_final_encounter_won() -> void:
	var rm: _RunManager = _new_run_manager()
	rm.biome_count = 1
	rm.rooms_per_biome_min = 2
	rm.rooms_per_biome_max = 2

	rm.memory_state_loaded = true

	var results := {"received": false, "value": &""}
	rm.run_ended.connect(
		func(res: StringName, _ctx: Dictionary) -> void:
			results.received = true
			results.value = res
	)

	rm.cmd_start_run()
	for _i: int in range(10):
		rm.update(0.02)

	rm.cmd_final_encounter_won()
	assert_that(rm.current_state).is_equal(_RunManager.RunState.RUN_RESOLUTION)
	assert_that(results.received).is_true()
	assert_that(results.value).is_equal(&"TRIUMPH")


func test_run_manager_config_loaded() -> void:
	var rm: _RunManager = _new_run_manager()
	assert_that(rm.biome_count).is_greater(0)
	assert_that(rm.rooms_per_biome_min <= rm.rooms_per_biome_max).is_true()

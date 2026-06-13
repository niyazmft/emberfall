extends GdUnitTestSuite


func test_start_phase() -> void:
	# AP_START = min(AP_MAX, AP_CARRIED_OVER + AP_REGEN)
	# Max is 6, Regen is 2
	assert_that(APEconomy.start_phase(0)).is_equal(2)
	assert_that(APEconomy.start_phase(2)).is_equal(4)
	assert_that(APEconomy.start_phase(4)).is_equal(6)
	assert_that(APEconomy.start_phase(5)).is_equal(6)
	assert_that(APEconomy.start_phase(6)).is_equal(6)


func test_spend() -> void:
	assert_that(APEconomy.spend(6, 2)).is_equal(4)
	assert_that(APEconomy.spend(4, 4)).is_equal(0)


func test_can_afford() -> void:
	assert_that(APEconomy.can_afford(6, 2)).is_true()
	assert_that(APEconomy.can_afford(2, 2)).is_true()
	assert_that(APEconomy.can_afford(1, 2)).is_false()


func test_end_phase() -> void:
	# AP_CARRIED_OVER = clamp(AP_PREVIOUS_END - AP_SPENT, 0, AP_MAX)
	# AP_MAX is 6
	assert_that(APEconomy.end_phase(6, 4)).is_equal(2)
	assert_that(APEconomy.end_phase(6, 0)).is_equal(6)
	assert_that(APEconomy.end_phase(6, 6)).is_equal(0)
	assert_that(APEconomy.end_phase(6, 10)).is_equal(0)


func test_simulate_turn() -> void:
	var result: Dictionary = APEconomy.simulate_turn(6, [1, 2, 2])
	assert_that(result["ap_spent"]).is_equal(5)
	assert_that(result["ap_remaining"]).is_equal(1)
	assert_that(result["ap_next_turn"]).is_equal(1)
	assert_that(result["actions_executed"]).is_equal(3)
	assert_that(result["truncated"]).is_false()

	result = APEconomy.simulate_turn(6, [3, 4, 1])
	assert_that(result["ap_spent"]).is_equal(3)
	assert_that(result["ap_remaining"]).is_equal(3)
	assert_that(result["actions_executed"]).is_equal(1)
	assert_that(result["truncated"]).is_true()


func test_ap_economy_state_machine_migration() -> void:
	# Ported from test_deterministic_math.gd
	var start := 6
	var spent := 4
	var end_ap := start - spent
	var next := APEconomy.start_phase(end_ap)
	assert_that(next).is_equal(4)

	start = next
	spent = 1
	end_ap = start - spent
	next = APEconomy.start_phase(end_ap)
	assert_that(next).is_equal(5)

	start = next
	spent = 0
	end_ap = start - spent
	next = APEconomy.start_phase(end_ap)
	assert_that(next).is_equal(6)

	start = next
	spent = 6
	end_ap = start - spent
	next = APEconomy.start_phase(end_ap)
	assert_that(next).is_equal(2)

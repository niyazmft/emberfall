extends GdUnitTestSuite


func test_floor_clamp_edge_cases() -> void:
	assert_that(DeterministicMath.floori(14.0)).is_equal(14)
	assert_that(DeterministicMath.floori(17.5)).is_equal(17)
	assert_that(DeterministicMath.floori(21.7)).is_equal(21)
	assert_that(DeterministicMath.floori(9.8)).is_equal(9)
	assert_that(DeterministicMath.floori(0.0)).is_equal(0)
	assert_that(DeterministicMath.floori(-2.3)).is_equal(-3)

	assert_that(is_equal_approx(DeterministicMath.clampf(1.55, 0.5, 1.5), 1.5)).is_true()
	assert_that(is_equal_approx(DeterministicMath.clampf(0.45, 0.5, 1.5), 0.5)).is_true()
	assert_that(DeterministicMath.clampi(7, 0, 10)).is_equal(7)
	assert_that(DeterministicMath.damage_floor(14.0)).is_equal(14)
	assert_that(DeterministicMath.damage_floor(0.0)).is_equal(1)
	assert_that(DeterministicMath.damage_floor(-3.0)).is_equal(1)


func test_entity_stat_clamping() -> void:
	var ent: Entity = Entity.new("Test", 0, 0, 500, 50, 30)
	ent.hp = -10
	assert_that(ent.hp).is_equal(0)
	ent.hp = 10000
	assert_that(ent.hp).is_equal(500)
	ent.off = -5
	assert_that(ent.off).is_equal(0)
	ent.off = 2000
	assert_that(ent.off).is_equal(999)


func test_floor_edge_cases() -> void:
	assert_that(DeterministicMath.floori(-2.3)).is_equal(-3)
	assert_that(DeterministicMath.floori(-0.1)).is_equal(-1)
	assert_that(DeterministicMath.floori(-1.0)).is_equal(-1)
	assert_that(is_equal_approx(DeterministicMath.floorf(-2.3), -3.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.floorf(2.3), 2.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.floorf(0.0), 0.0)).is_true()


func test_clampf_negative_edge_cases() -> void:
	assert_that(is_equal_approx(DeterministicMath.clampf(-5.0, -10.0, -1.0), -5.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.clampf(-15.0, -10.0, -1.0), -10.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.clampf(0.0, -10.0, -1.0), -1.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.clampf(-5.0, -3.0, 3.0), -3.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.clampf(5.0, -3.0, 3.0), 3.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.clampf(0.0, -3.0, 3.0), 0.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.clampf(-10.0, -10.0, -1.0), -10.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.clampf(-1.0, -10.0, -1.0), -1.0)).is_true()


func test_sgn_epsilon_edge_cases() -> void:
	assert_that(DeterministicMath.sgn(0.0)).is_equal(0)
	assert_that(DeterministicMath.sgn(DeterministicMath.EPSILON * 0.5)).is_equal(0)
	assert_that(DeterministicMath.sgn(-DeterministicMath.EPSILON * 0.5)).is_equal(0)
	assert_that(DeterministicMath.sgn(DeterministicMath.EPSILON)).is_equal(0)
	assert_that(DeterministicMath.sgn(-DeterministicMath.EPSILON)).is_equal(0)
	assert_that(DeterministicMath.sgn(DeterministicMath.EPSILON + 1e-10)).is_equal(1)
	assert_that(DeterministicMath.sgn(-DeterministicMath.EPSILON - 1e-10)).is_equal(-1)


func test_ap_carry_over_spent_exceeds_current() -> void:
	assert_that(DeterministicMath.ap_carry_over(3, 5, 10)).is_equal(0)
	assert_that(DeterministicMath.ap_carry_over(5, 2, 10)).is_equal(3)
	assert_that(DeterministicMath.ap_carry_over(5, 5, 10)).is_equal(0)
	assert_that(DeterministicMath.ap_carry_over(15, 2, 10)).is_equal(10)
	assert_that(DeterministicMath.ap_carry_over(0, 0, 10)).is_equal(0)


func test_ceil_edge_cases() -> void:
	assert_that(DeterministicMath.ceili(2.3)).is_equal(3)
	assert_that(DeterministicMath.ceili(2.0)).is_equal(2)
	assert_that(DeterministicMath.ceili(-2.3)).is_equal(-2)
	assert_that(DeterministicMath.ceili(0.0)).is_equal(0)
	assert_that(DeterministicMath.ceili(-0.1)).is_equal(0)
	assert_that(is_equal_approx(DeterministicMath.ceilf(2.3), 3.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.ceilf(2.0), 2.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.ceilf(-2.3), -2.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.ceilf(0.0), 0.0)).is_true()


func test_ap_start_edge_cases() -> void:
	assert_that(DeterministicMath.ap_start(3, 4, 10)).is_equal(7)
	assert_that(DeterministicMath.ap_start(6, 4, 10)).is_equal(10)
	assert_that(DeterministicMath.ap_start(8, 5, 10)).is_equal(10)
	assert_that(DeterministicMath.ap_start(0, 5, 10)).is_equal(5)
	assert_that(DeterministicMath.ap_start(5, 0, 10)).is_equal(5)


func test_clampi_edge_cases() -> void:
	assert_that(DeterministicMath.clampi(5, 0, 10)).is_equal(5)
	assert_that(DeterministicMath.clampi(0, 0, 10)).is_equal(0)
	assert_that(DeterministicMath.clampi(10, 0, 10)).is_equal(10)
	assert_that(DeterministicMath.clampi(-5, 0, 10)).is_equal(0)
	assert_that(DeterministicMath.clampi(15, 0, 10)).is_equal(10)
	assert_that(DeterministicMath.clampi(-5, -10, -1)).is_equal(-5)
	assert_that(DeterministicMath.clampi(-15, -10, -1)).is_equal(-10)
	assert_that(DeterministicMath.clampi(0, -10, -1)).is_equal(-1)


func test_maxi_mini_absi_edge_cases() -> void:
	assert_that(DeterministicMath.maxi(5, 5)).is_equal(5)
	assert_that(DeterministicMath.mini(5, 5)).is_equal(5)
	assert_that(DeterministicMath.maxi(-5, -3)).is_equal(-3)
	assert_that(DeterministicMath.mini(-5, -3)).is_equal(-5)
	assert_that(DeterministicMath.maxi(0, 0)).is_equal(0)
	assert_that(DeterministicMath.mini(0, 0)).is_equal(0)
	assert_that(DeterministicMath.absi(5)).is_equal(5)
	assert_that(DeterministicMath.absi(-5)).is_equal(5)
	assert_that(DeterministicMath.absi(0)).is_equal(0)


func test_absf_edge_cases() -> void:
	assert_that(is_equal_approx(DeterministicMath.absf(5.0), 5.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.absf(-5.0), 5.0)).is_true()
	assert_that(is_equal_approx(DeterministicMath.absf(0.0), 0.0)).is_true()
	(
		assert_that(
			is_equal_approx(
				DeterministicMath.absf(DeterministicMath.EPSILON), DeterministicMath.EPSILON
			)
		)
		. is_true()
	)
	(
		assert_that(
			is_equal_approx(
				DeterministicMath.absf(-DeterministicMath.EPSILON), DeterministicMath.EPSILON
			)
		)
		. is_true()
	)

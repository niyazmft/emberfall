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

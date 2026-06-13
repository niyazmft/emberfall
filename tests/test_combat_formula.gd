extends GdUnitTestSuite


func test_compute_damage() -> void:
	# Baseline: 10 + 12 - 8 = 14
	var baseline := CombatFormula.compute_damage(12, 8, 1.0, 1.0, 0.0)
	assert_that(baseline).is_equal(14)

	# Position modifier: 14 * 1.25 = 17.5 -> 17
	assert_that(CombatFormula.compute_damage(12, 8, 1.25, 1.0, 0.0)).is_equal(17)

	# Elevation T1: 14 * 1.15 = 16.1 -> 16
	assert_that(CombatFormula.compute_damage(12, 8, 1.15, 1.0, 0.0)).is_equal(16)

	# Cover penalty: 14 * 0.85 = 11.9 -> 11
	assert_that(CombatFormula.compute_damage(12, 8, 0.85, 1.0, 0.0)).is_equal(11)

	# Elemental: 17 * 2.0 = 35
	assert_that(CombatFormula.compute_damage(12, 8, 1.25, 2.0, 0.0)).is_equal(35)

	# Memory Synergy: 17 * 1.30 = 22.1 -> 22
	assert_that(CombatFormula.compute_damage(12, 8, 1.25, 1.0, 0.30)).is_equal(22)

	# Heavy Cover: 14 * 0.70 = 9.8 -> 9
	assert_that(CombatFormula.compute_damage(12, 8, 0.70, 1.0, 0.0)).is_equal(9)


func test_calculate_position_modifier() -> void:
	var attacker := Entity.new("Attacker", 1, 1, 10, 5, 3, 1, 0, 0)
	var defender := Entity.new("Defender", 2, 1, 10, 5, 3, 1, 0, 0)
	var cover_tiles: Array[Vector2i] = []

	# Default: 1.0
	var mod := CombatFormula.calculate_position_modifier(attacker, defender, cover_tiles)
	assert_that(is_equal_approx(mod, 1.0)).is_true()

	# Backstab: 1.0 + 0.25 = 1.25
	attacker.x = 1
	attacker.y = 1
	defender.x = 2
	defender.y = 1
	defender.facing_x = -1
	mod = CombatFormula.calculate_position_modifier(attacker, defender, cover_tiles)
	assert_that(is_equal_approx(mod, 1.25)).is_true()

	# Elevation T1: 1.25 - 0.15 = 1.10 (if attacker facing same as defender)
	# Wait, backstab is determined by relative position and defender facing.
	# Reset facing
	defender.facing_x = 1
	attacker.elevation = 1
	defender.elevation = 0
	mod = CombatFormula.calculate_position_modifier(attacker, defender, cover_tiles)
	assert_that(is_equal_approx(mod, 1.15)).is_true()

	# Elevation T2: 1.25
	attacker.elevation = 2
	mod = CombatFormula.calculate_position_modifier(attacker, defender, cover_tiles)
	assert_that(is_equal_approx(mod, 1.25)).is_true()

	# Negative Elevation (High ground penalty)
	attacker.elevation = 0
	defender.elevation = 2
	mod = CombatFormula.calculate_position_modifier(attacker, defender, cover_tiles)
	assert_that(is_equal_approx(mod, 0.75)).is_true()

	# Light Cover: 1.0 - 0.15 = 0.85
	attacker.elevation = 0
	defender.elevation = 0
	cover_tiles = [Vector2i(2, 1)]
	mod = CombatFormula.calculate_position_modifier(attacker, defender, cover_tiles)
	assert_that(is_equal_approx(mod, 0.85)).is_true()

	# Heavy Cover: 1.0 - 0.30 = 0.70
	cover_tiles = [Vector2i(2, 1), Vector2i(3, 1)]
	mod = CombatFormula.calculate_position_modifier(attacker, defender, cover_tiles)
	assert_that(is_equal_approx(mod, 0.70)).is_true()


func test_compute_damage_from_entities() -> void:
	var attacker := Entity.new("Attacker", 1, 1, 10, 12, 6, 1, 0, 0)
	var defender := Entity.new("Defender", 2, 1, 10, 10, 8, -1, 0, 0)  # Backstab
	var cover_tiles: Array[Vector2i] = []

	# Damage: (10 + 12 - 8) * 1.25 = 14 * 1.25 = 17.5 -> 17
	var dmg := CombatFormula.compute_damage_from_entities(attacker, defender, cover_tiles)
	assert_that(dmg).is_equal(17)


func test_elemental_modifier() -> void:
	assert_that(is_equal_approx(CombatFormula.elemental_modifier("fire_to_oil"), 2.0)).is_true()
	assert_that(is_equal_approx(CombatFormula.elemental_modifier("wind_to_fire"), 1.5)).is_true()
	assert_that(is_equal_approx(CombatFormula.elemental_modifier("oil_slip"), 0.8)).is_true()
	assert_that(is_equal_approx(CombatFormula.elemental_modifier("water_to_fire"), 0.5)).is_true()
	assert_that(is_equal_approx(CombatFormula.elemental_modifier("none"), 1.0)).is_true()


func test_damage_formula_randomized() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameConstants.GOLDEN_SEED

	for i: int in range(100):
		var off := rng.randi_range(0, 99)
		var def_stat := rng.randi_range(0, 99)
		var pos := snappedf(rng.randf_range(0.5, 1.5), 0.01)
		var elem := snappedf(rng.randf_range(0.5, 2.0), 0.01)
		var mem := snappedf(rng.randf_range(0.0, 0.3), 0.01)

		var dmg := CombatFormula.compute_damage(off, def_stat, pos, elem, mem)
		assert_that(dmg >= 1).is_true()
		assert_that(dmg <= 9999).is_true()

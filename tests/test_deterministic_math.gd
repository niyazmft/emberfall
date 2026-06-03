extends GdUnitTestSuite


func test_golden_seed_hash() -> void:
	var golden: int = GameConstants.GOLDEN_SEED
	var h1: int = SeedGovernance.hash_int(golden, "TEST")
	var h2: int = SeedGovernance.hash_int(golden, "TEST")
	assert_that(h1).is_equal(h2)

	var known_topo: int = SeedGovernance.seed_room_topology(golden, 0, 16)
	var known_enc: int = SeedGovernance.seed_encounter(golden, 0, 8)
	assert_that(known_topo).is_equal(known_topo)
	assert_that(known_enc).is_equal(known_enc)

	var valid: bool = SeedGovernance.validate_seed(golden, {})
	assert_that(valid).is_true()


func test_damage_formula_100_edge_cases() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = GameConstants.GOLDEN_SEED

	for i: int in range(100):
		var off: int = rng.randi_range(0, 99)
		var def_stat: int = rng.randi_range(0, 99)
		var pos: float = snappedf(rng.randf_range(0.5, 1.5), 0.01)
		var elem: float = snappedf(rng.randf_range(0.5, 2.0), 0.01)
		var mem: float = snappedf(rng.randf_range(0.0, 0.3), 0.01)

		var dmg: int = CombatFormula.compute_damage(off, def_stat, pos, elem, mem)
		assert_that(dmg >= 1).is_true()
		assert_that(dmg <= 9999).is_true()

		var dmg2: int = CombatFormula.compute_damage(off, def_stat, pos, elem, mem)
		assert_that(dmg).is_equal(dmg2)

	var baseline: int = CombatFormula.compute_damage(12, 8, 1.0, 1.0, 0.0)
	assert_that(baseline).is_equal(14)
	assert_that(CombatFormula.compute_damage(12, 8, 1.25, 1.0, 0.0)).is_equal(17)
	assert_that(CombatFormula.compute_damage(12, 8, 1.15, 1.0, 0.0)).is_equal(16)
	assert_that(CombatFormula.compute_damage(12, 8, 1.25, 1.0, 0.0)).is_equal(17)
	assert_that(CombatFormula.compute_damage(12, 8, 0.85, 1.0, 0.0)).is_equal(11)
	assert_that(CombatFormula.compute_damage(12, 8, 1.25, 2.0, 0.0)).is_equal(35)
	assert_that(CombatFormula.compute_damage(12, 8, 1.25, 1.0, 0.30)).is_equal(22)
	assert_that(CombatFormula.compute_damage(12, 8, 0.70, 1.0, 0.0)).is_equal(9)


func test_ap_economy_state_machine() -> void:
	var start: int = 6
	var spent: int = 4
	var end_ap: int = start - spent
	var next: int = APEconomy.start_phase(end_ap)
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


func test_position_modifier_matrix() -> void:
	var p: Entity = Entity.new("P", 1, 1, 10, 5, 3, 1, 0, 0)
	var e: Entity = Entity.new("E", 2, 1, 10, 5, 3, 1, 0, 0)
	var cover: Array[Vector2i] = []

	var mod: float = CombatFormula.calculate_position_modifier(p, e, cover)
	assert_that(is_equal_approx(mod, 1.0)).is_true()

	p.x = 1
	p.y = 1
	e.x = 2
	e.y = 1
	e.facing_x = -1
	mod = CombatFormula.calculate_position_modifier(p, e, cover)
	assert_that(is_equal_approx(mod, 1.25)).is_true()

	p.elevation = 1
	e.elevation = 0
	p.facing_x = 1
	e.facing_x = 1
	mod = CombatFormula.calculate_position_modifier(p, e, cover)
	assert_that(is_equal_approx(mod, 1.15)).is_true()

	p.elevation = 2
	mod = CombatFormula.calculate_position_modifier(p, e, cover)
	assert_that(is_equal_approx(mod, 1.25)).is_true()

	p.elevation = 0
	cover = [Vector2i(2, 1)]
	mod = CombatFormula.calculate_position_modifier(p, e, cover)
	assert_that(is_equal_approx(mod, 0.85)).is_true()

	cover = [Vector2i(2, 1), Vector2i(3, 1)]
	mod = CombatFormula.calculate_position_modifier(p, e, cover)
	assert_that(is_equal_approx(mod, 0.70)).is_true()

	cover = []
	p.elevation = 0
	e.elevation = 2
	e.facing_x = 1
	mod = CombatFormula.calculate_position_modifier(p, e, cover)
	assert_that(is_equal_approx(mod, 0.75)).is_true()


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


func test_elemental_modifiers() -> void:
	assert_that(is_equal_approx(CombatFormula.elemental_modifier("fire_to_oil"), 2.0)).is_true()
	assert_that(is_equal_approx(CombatFormula.elemental_modifier("wind_to_fire"), 1.5)).is_true()
	assert_that(is_equal_approx(CombatFormula.elemental_modifier("oil_slip"), 0.8)).is_true()
	assert_that(is_equal_approx(CombatFormula.elemental_modifier("water_to_fire"), 0.5)).is_true()
	assert_that(is_equal_approx(CombatFormula.elemental_modifier("none"), 1.0)).is_true()


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


func test_sha256_cross_platform() -> void:
	var inputs: Array[String] = [
		"0xDEADBEEFTEST",
		"12345TOPO0",
		"99999ENC7",
	]
	var results: Array[int] = []
	for s: String in inputs:
		results.append(SeedGovernance.hash_seed(s))

	for i: int in range(inputs.size()):
		var v2: int = SeedGovernance.hash_seed(inputs[i])
		assert_that(results[i]).is_equal(v2)

	var topo: int = SeedGovernance.seed_room_topology(GameConstants.GOLDEN_SEED, 0, 16)
	var enc: int = SeedGovernance.seed_encounter(GameConstants.GOLDEN_SEED, 0, 8)
	var echo_val: int = SeedGovernance.seed_echo(GameConstants.GOLDEN_SEED, 0, 4)
	assert_that(topo >= 0).is_true()
	assert_that(topo < 16).is_true()
	assert_that(enc >= 0).is_true()
	assert_that(enc < 8).is_true()
	assert_that(echo_val >= 0).is_true()
	assert_that(echo_val < 4).is_true()

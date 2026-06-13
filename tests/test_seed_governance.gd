extends GdUnitTestSuite

func test_seed_hashing() -> void:
	var seed_val := 12345
	var salt := "TEST"

	var h1 := SeedGovernance.hash_int(seed_val, salt)
	var h2 := SeedGovernance.hash_int(seed_val, salt)

	assert_that(h1).is_equal(h2)
	assert_int(h1).is_greater_equal(0)

	var h3 := SeedGovernance.hash_int(seed_val + 1, salt)
	assert_that(h1).is_not_equal(h3)

func test_modulo_from_seed() -> void:
	var seed_val := 98765
	var mod := 10
	var result := SeedGovernance.modulo_from_seed(seed_val, "MOD", mod)

	assert_int(result).is_between(0, mod - 1)

	# Consistency
	assert_that(SeedGovernance.modulo_from_seed(seed_val, "MOD", mod)).is_equal(result)

func test_fract_from_seed() -> void:
	var seed_val := 42
	var f1 := SeedGovernance.fract_from_seed(seed_val)

	assert_float(f1).is_greater_equal(0.0)
	assert_float(f1).is_less(1.0)

	# Consistency
	assert_that(SeedGovernance.fract_from_seed(seed_val)).is_equal(f1)

func test_seed_validation() -> void:
	assert_that(SeedGovernance.validate_seed(GameConstants.GOLDEN_SEED, {})).is_true()

func test_room_seeds() -> void:
	var seed_val := 1234
	var room_idx := 1

	var topo := SeedGovernance.seed_room_topology(seed_val, room_idx, 10)
	assert_int(topo).is_between(0, 9)

	var enc := SeedGovernance.seed_encounter(seed_val, room_idx, 5)
	assert_int(enc).is_between(0, 4)

	var echo := SeedGovernance.seed_echo(seed_val, room_idx, 3)
	assert_int(echo).is_between(0, 2)

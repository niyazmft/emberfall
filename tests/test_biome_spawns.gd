extends GdUnitTestSuite


func test_archer_spawned_in_biome1() -> void:
	var encounters: Array = EncounterSystem.buildEncounters("biome1", 12345, 5)
	assert_that(encounters).is_not_empty()

	var hasArcher: bool = false
	for enc: Variant in encounters:
		if enc is Dictionary:
			if str(enc.get("enemy_type", "")) == "archer":
				hasArcher = true
	assert_bool(hasArcher).is_true()


func test_tank_spawned_in_biome2() -> void:
	var encounters: Array = EncounterSystem.buildEncounters("biome2", 12345, 5)
	assert_that(encounters).is_not_empty()

	var hasTank: bool = false
	for enc: Variant in encounters:
		if enc is Dictionary:
			if str(enc.get("enemy_type", "")) == "tank":
				hasTank = true
	assert_bool(hasTank).is_true()


func test_mage_spawned_in_biome3() -> void:
	var encounters: Array = EncounterSystem.buildEncounters("biome3", 12345, 5)
	assert_that(encounters).is_not_empty()

	var hasMage: bool = false
	for enc: Variant in encounters:
		if enc is Dictionary:
			if str(enc.get("enemy_type", "")) == "mage":
				hasMage = true
	assert_bool(hasMage).is_true()


func test_non_matching_types_substituted() -> void:
	# biome1 (Crystal Spires) should substitute tank with archer
	# Use a seed that produces a heavy_patrol in biome1
	var encounters: Array = EncounterSystem.buildEncounters("biome1", 99999, 5)
	assert_that(encounters).is_not_empty()

	for enc: Variant in encounters:
		if enc is Dictionary:
			var t: String = str(enc.get("enemy_type", ""))
			assert_str(t).is_not_equal("tank")


func test_grunt_appears_in_biome1_and_biome2() -> void:
	# biome1 and biome2 have compositions that include grunts
	for biomeId: String in ["biome1", "biome2"]:
		var encounters: Array = EncounterSystem.buildEncounters(biomeId, 12345, 5)
		var hasGrunt: bool = false
		for enc: Variant in encounters:
			if enc is Dictionary:
				if str(enc.get("enemy_type", "")) == "grunt":
					hasGrunt = true
		assert_bool(hasGrunt).is_true()


func test_determinism_same_seed_same_result() -> void:
	var e1: Array = EncounterSystem.buildEncounters("biome1", 42, 5)
	var e2: Array = EncounterSystem.buildEncounters("biome1", 42, 5)
	assert_that(e1).is_equal(e2)

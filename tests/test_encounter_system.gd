extends GdUnitTestSuite

func test_build_encounters_deterministic() -> void:
	var biome_id := "biome1"
	var seed_val := 12345

	var encounters1 := EncounterSystem.buildEncounters(biome_id, seed_val)
	var encounters2 := EncounterSystem.buildEncounters(biome_id, seed_val)

	assert_that(encounters1).is_not_empty()
	assert_that(encounters1).is_equal(encounters2)

func test_weighted_group_selection() -> void:
	var compositions: Array[Dictionary] = [
		{"group_id": "groupA", "weight": 1.0},
		{"group_id": "groupB", "weight": 0.0}
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	var selected := EncounterSystem._selectWeightedGroup(compositions, rng)
	assert_that(selected).is_equal("groupA")

func test_build_encounters_invalid_biome() -> void:
	var encounters := EncounterSystem.buildEncounters("non_existent_biome", 12345)
	assert_that(encounters).is_empty()

func test_encounter_content_structure() -> void:
	var encounters := EncounterSystem.buildEncounters("biome1", 12345)
	assert_that(encounters).is_not_empty()

	for enc_v: Variant in encounters:
		var enc := enc_v as Dictionary
		assert_that(enc.has("enemy_type")).is_true()
		assert_that(enc.has("count")).is_true()
		assert_that(enc.has("positions")).is_true()
		assert_int(enc["count"]).is_greater(0)

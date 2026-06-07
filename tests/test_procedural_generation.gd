extends GdUnitTestSuite


func test_room_generator_augmentation() -> void:
	var room_data: Dictionary = {
		"id": "test_room", "biome": 0, "topology_seed": 12345, "player_start": {"x": 1, "y": 1}  # Biome 1
	}

	RoomGenerator.augment_room(room_data, "biome1", 12345)

	assert_that(room_data.has("layout")).is_true()
	var layout: Dictionary = room_data["layout"]
	var elevation: Array = layout.get("elevation", [])
	var cover: Array = layout.get("cover", [])
	var blocked: Array = layout.get("blocked", [])
	assert_that(elevation.size()).is_equal(144)
	assert_that(cover.size()).is_equal(144)
	assert_that(blocked.size()).is_equal(144)

	# Verify that some tiles were modified (procedural elements added)
	var has_cover: bool = false
	for c: Variant in cover:
		if int(c) > 0:
			has_cover = true
			break
	assert_that(has_cover).is_true()


func test_encounter_system_building() -> void:
	var biome_id: String = "biome1"
	var seed1: int = 111
	var seed2: int = 222

	var encounters1: Array = EncounterSystem.build_encounters(biome_id, seed1)
	var encounters2: Array = EncounterSystem.build_encounters(biome_id, seed1)
	var encounters3: Array = EncounterSystem.build_encounters(biome_id, seed2)

	assert_that(encounters1).is_not_empty()
	# Determinism check
	assert_that(encounters1).is_equal(encounters2)
	# Different seed should likely produce different result
	assert_that(encounters1).is_not_equal(encounters3)


func test_room_loader_integration() -> void:
	var room_data: Dictionary = {
		"room_id": "room_standard_01",
		"biome": 0,
		"topology_seed": 999,
		"encounter_seed": 888,
		"player_start": {"x": 1, "y": 1}
	}

	RoomLoader.augment_room_procedurally(room_data)

	assert_that(room_data.has("encounters")).is_true()
	var encounters: Array = room_data["encounters"] as Array
	assert_that(encounters).is_not_empty()

	# Verify positions were assigned
	for enc_v: Variant in encounters:
		var enc: Dictionary = enc_v as Dictionary
		assert_that(enc["positions"]).is_not_empty()
		var positions: Array = enc["positions"] as Array
		for pos_v: Variant in positions:
			var pos: Dictionary = pos_v as Dictionary
			assert_that(int(pos["x"])).is_between(0, 11)
			assert_that(int(pos["y"])).is_between(0, 11)

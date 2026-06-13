extends GdUnitTestSuite

func test_room_loader_integration() -> void:
	var room_data: Dictionary = {
		"room_id": "room_standard_01",
		"biome": 0,
		"topology_seed": 999,
		"encounter_seed": 888,
		"player_start": {"x": 1, "y": 1}
	}

	# RoomLoader.augment_room_procedurally calls RoomGenerator and EncounterSystem
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

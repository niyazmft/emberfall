extends GdUnitTestSuite

func test_augment_room_layout() -> void:
	var room_data: Dictionary = {
		"id": "test_room",
		"player_start": {"x": 1, "y": 1}
	}
	var biome_id := "biome1"
	var topology_seed := 12345

	RoomGenerator.augmentRoom(room_data, biome_id, topology_seed)

	assert_that(room_data.has("layout")).is_true()
	var layout: Dictionary = room_data["layout"]
	assert_that(layout["elevation"].size()).is_equal(144)
	assert_that(layout["cover"].size()).is_equal(144)
	assert_that(layout["blocked"].size()).is_equal(144)
	assert_that(layout["vision_blocked"].size()).is_equal(144)

	# Player start should be reserved and have no obstacles/elevation change
	var player_idx := 1 + 1 * 12
	assert_that(layout["blocked"][player_idx]).is_false()
	assert_that(layout["elevation"][player_idx]).is_equal(0)
	assert_that(layout["cover"][player_idx]).is_equal(0)

func test_procedural_consistency() -> void:
	var biome_id := "biome1"
	var topology_seed := 54321

	var room_data1: Dictionary = {"id": "room1"}
	var room_data2: Dictionary = {"id": "room2"}

	RoomGenerator.augmentRoom(room_data1, biome_id, topology_seed)
	RoomGenerator.augmentRoom(room_data2, biome_id, topology_seed)

	assert_that(room_data1["layout"]).is_equal(room_data2["layout"])

func test_reserved_positions() -> void:
	var room_data: Dictionary = {
		"player_start": {"x": 1, "y": 1},
		"encounters": [
			{"enemy_type": "grunt", "positions": [{"x": 5, "y": 5}]}
		]
	}
	var reserved := RoomGenerator._getReservedPositions(room_data)
	assert_that(reserved).contains(Vector2i(1, 1))
	assert_that(reserved).contains(Vector2i(5, 5))
	assert_that(reserved.size()).is_equal(2)

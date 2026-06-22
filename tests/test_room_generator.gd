extends GdUnitTestSuite


func test_augment_room_layout() -> void:
	var room_data: Dictionary = {"id": "test_room", "player_start": {"x": 1, "y": 1}}
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
		"encounters": [{"enemy_type": "grunt", "positions": [{"x": 5, "y": 5}]}]
	}
	var reserved := RoomGenerator._getReservedPositions(room_data)
	assert_that(reserved).contains(Vector2i(1, 1))
	assert_that(reserved).contains(Vector2i(5, 5))
	assert_that(reserved.size()).is_equal(2)


# ── Multi-room generation tests (#463) ─────────────────────────────────────


func test_multiple_rooms_different_layouts() -> void:
	## Generate rooms 2, 3, 4 with different topology seeds.
	## They should produce different layouts.
	var biome_id := "biome1"
	var seeds: Array[int] = [11111, 22222, 33333, 44444]
	var layouts: Array[Dictionary] = []

	for seed: int in seeds:
		var room_data: Dictionary = {"id": "room_%d" % seed, "player_start": {"x": 1, "y": 1}}
		RoomGenerator.augmentRoom(room_data, biome_id, seed)
		layouts.append(room_data["layout"])

	# All 4 layouts should differ from each other (with very high probability)
	for i: int in range(layouts.size()):
		for j: int in range(i + 1, layouts.size()):
			var same: bool = true
			var li: Dictionary = layouts[i]
			var lj: Dictionary = layouts[j]
			for key: String in ["elevation", "cover", "blocked", "vision_blocked"]:
				if li[key] != lj[key]:
					same = false
					break
			assert_bool(same).is_false()


func test_layout_array_sizes() -> void:
	var biome_id := "biome1"
	var room_data: Dictionary = {"id": "room_size_test", "player_start": {"x": 5, "y": 5}}
	RoomGenerator.augmentRoom(room_data, biome_id, 99999)

	var layout: Dictionary = room_data["layout"]
	assert_int(layout["elevation"].size()).is_equal(144)
	assert_int(layout["cover"].size()).is_equal(144)
	assert_int(layout["blocked"].size()).is_equal(144)
	assert_int(layout["vision_blocked"].size()).is_equal(144)


func test_elevation_values_within_biome_range() -> void:
	var biome_id := "biome1"
	var params: Dictionary = RoomGenerator._getBiomeParams(biome_id)
	var gen_params: Dictionary = params.get("generation_params", {})
	var elev_max: int = int(gen_params.get("elevation_max", 0))

	var room_data: Dictionary = {"id": "room_elev", "player_start": {"x": 1, "y": 1}}
	RoomGenerator.augmentRoom(room_data, biome_id, 77777)

	var elevation: Array = room_data["layout"]["elevation"]
	for i: int in range(144):
		var e: int = int(elevation[i])
		assert_int(e).is_greater_equal(0)
		assert_int(e).is_less_equal(elev_max)


func test_cover_values_valid() -> void:
	var room_data: Dictionary = {"id": "room_cover", "player_start": {"x": 1, "y": 1}}
	RoomGenerator.augmentRoom(room_data, "biome1", 88888)

	var cover: Array = room_data["layout"]["cover"]
	for i: int in range(144):
		var c: int = int(cover[i])
		# Cover must be 0 (none), 1 (light), or 2 (heavy)
		assert_int(c).is_between(0, 2)


func test_blocked_consistency() -> void:
	## Blocked tiles should also block vision.
	var room_data: Dictionary = {"id": "room_blocked", "player_start": {"x": 1, "y": 1}}
	RoomGenerator.augmentRoom(room_data, "biome1", 55555)

	var blocked: Array = room_data["layout"]["blocked"]
	var vision: Array = room_data["layout"]["vision_blocked"]
	for i: int in range(144):
		if bool(blocked[i]):
			assert_bool(bool(vision[i])).is_true()


func test_biome2_higher_elevation_range() -> void:
	## biome2 has elevation_max=2; verify it can generate elevation 2.
	var found_elev2: bool = false
	for seed: int in range(100):
		var room_data: Dictionary = {"id": "room_elev2", "player_start": {"x": 1, "y": 1}}
		RoomGenerator.augmentRoom(room_data, "biome2", seed)
		var elevation: Array = room_data["layout"]["elevation"]
		for i: int in range(144):
			if int(elevation[i]) == 2:
				found_elev2 = true
				break
		if found_elev2:
			break
	# With 100 seeds we should hit elevation 2 at least once
	assert_bool(found_elev2).is_true()

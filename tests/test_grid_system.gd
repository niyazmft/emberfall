extends GdUnitTestSuite


func test_initialization() -> void:
	var gs: _GridSystem = GridSystem
	assert_int(gs.GRID_SIZE).is_equal(12)
	assert_int(gs.TOTAL_TILES).is_equal(144)

	var tiles: Array[TacTileData] = gs.all_tiles()
	assert_int(tiles.size()).is_equal(144)
	for i: int in range(144):
		assert_that(tiles[i]).is_not_null()
		assert_int(tiles[i].coords.x).is_equal(i % 12)
		assert_int(tiles[i].coords.y).is_equal(i / 12)


func test_coordinate_helpers() -> void:
	var gs: _GridSystem = GridSystem
	assert_bool(gs.is_in_bounds(0, 0)).is_true()
	assert_bool(gs.is_in_bounds(11, 11)).is_true()
	assert_bool(gs.is_in_bounds(-1, 0)).is_false()
	assert_bool(gs.is_in_bounds(12, 5)).is_false()

	assert_int(gs.index(2, 3)).is_equal(3 * 12 + 2)

	var tile: TacTileData = gs.get_tile(5, 5)
	assert_that(tile).is_not_null()
	assert_int(tile.coords.x).is_equal(5)
	assert_int(tile.coords.y).is_equal(5)

	assert_that(gs.get_tile(12, 12)).is_null()
	assert_that(gs.get_tile_by_index(143)).is_not_null()
	assert_that(gs.get_tile_by_index(144)).is_null()


func test_load_room_layout() -> void:
	var gs: _GridSystem = GridSystem
	var layout_data: Dictionary = {
		"id": "test_room",
		"layout":
		{
			"elevation": [0, 1, 2],
			"cover": [0, 1, 2],
			"blocked": [false, true, false],
			"vision_blocked": [true, false, true]
		}
	}
	gs.load_room(layout_data)
	assert_str(gs.room_id).is_equal("test_room")

	var t0: TacTileData = gs.get_tile_by_index(0)
	assert_int(t0.elevation).is_equal(0)
	assert_int(t0.cover).is_equal(0)
	assert_bool(t0.blocks_movement).is_false()
	assert_bool(t0.blocks_vision).is_true()

	var t1: TacTileData = gs.get_tile_by_index(1)
	assert_int(t1.elevation).is_equal(1)
	assert_int(t1.cover).is_equal(1)
	assert_bool(t1.blocks_movement).is_true()
	assert_bool(t1.blocks_vision).is_false()


func test_load_room_legacy() -> void:
	var gs: _GridSystem = GridSystem
	var legacy_data: Dictionary = {
		"id": "legacy_room",
		"tiles":
		[{"x": 5, "y": 5, "elevation": 2, "cover": 1, "blocks_movement": true, "tags": ["spawner"]}]
	}
	gs.load_room(legacy_data)
	var t: TacTileData = gs.get_tile(5, 5)
	assert_int(t.elevation).is_equal(2)
	assert_int(t.cover).is_equal(1)
	assert_bool(t.blocks_movement).is_true()
	assert_array(t.tags).contains(["spawner"])


func test_can_move_logic() -> void:
	var gs: _GridSystem = GridSystem
	gs.load_room({"id": "move_test", "layout": {"elevation": [0, 1, 2]}})

	# Elevation 0 to 1 is OK (delta 1)
	assert_bool(gs.can_move(0, 0, 1, 0)).is_true()
	# Elevation 0 to 2 is NOT OK (delta 2)
	assert_bool(gs.can_move(0, 0, 2, 0)).is_false()

	# Blocked movement
	gs.load_room({"id": "block_test", "layout": {"blocked": [false, true]}})
	assert_bool(gs.can_move(0, 0, 1, 0)).is_false()


func test_movement_cost_oil() -> void:
	var gs: _GridSystem = GridSystem
	gs.load_room({"id": "oil_test"})

	# Default cost
	assert_int(gs.get_movement_cost(1, 1)).is_equal(1)

	# Oil cost
	gs.set_oil_tile(1, 1, true)
	assert_int(gs.get_movement_cost(1, 1)).is_equal(2)

	gs.set_oil_tile(1, 1, false)
	assert_int(gs.get_movement_cost(1, 1)).is_equal(1)


func test_elemental_overlay_management() -> void:
	var gs: _GridSystem = GridSystem
	gs.clear_elemental_overlay()

	gs.apply_tile_element(2, 2, 1, 3, 10)  # 1 = FIRE (assuming ElementalTypes)
	var effects: Array = gs.get_tile_effects(2, 2)
	assert_int(effects.size()).is_equal(1)
	assert_int(int(effects[0]["element"])).is_equal(1)
	assert_int(int(effects[0]["duration"])).is_equal(3)

	gs.remove_tile_element(2, 2, 1)
	assert_int(gs.get_tile_effects(2, 2).size()).is_equal(0)


func test_tick_tile_effects() -> void:
	var gs: _GridSystem = GridSystem
	gs.clear_elemental_overlay()
	gs.apply_tile_element(3, 3, 2, 2, 1)  # duration 2

	var expired: int = gs.tick_tile_effects()
	assert_int(expired).is_equal(0)
	assert_int(int(gs.get_tile_effects(3, 3)[0]["duration"])).is_equal(1)

	expired = gs.tick_tile_effects()
	assert_int(expired).is_equal(1)
	assert_int(gs.get_tile_effects(3, 3).size()).is_equal(0)


func test_line_of_sight() -> void:
	var gs: _GridSystem = GridSystem
	# Clear grid
	gs.load_room({"id": "los_test"})

	assert_bool(gs.has_los(0, 0, 5, 0)).is_true()

	# Block vision in between
	var vision_blocked: Array = []
	vision_blocked.resize(144)
	vision_blocked.fill(false)
	vision_blocked[gs.index(2, 0)] = true
	var layout: Dictionary = {"vision_blocked": vision_blocked}
	gs.load_room({"id": "los_block", "layout": layout})

	assert_bool(gs.has_los(0, 0, 5, 0)).is_false()


func test_cover_cache_logic() -> void:
	var gs: _GridSystem = GridSystem
	# Heavy cover at (1, 0)
	var cover_data: Array = []
	cover_data.resize(144)
	cover_data.fill(0)
	cover_data[gs.index(1, 0)] = 2  # HEAVY
	var layout: Dictionary = {"cover": cover_data}
	gs.load_room({"id": "cover_test", "layout": layout})

	# Target at (1, 0) has cover against observer at (0, 0)
	assert_bool(gs.target_has_cover_against(0, 0, 1, 0)).is_true()
	# No cover if observer is far (only adjacent cover counts in _recompute_cover_cache)
	assert_bool(gs.target_has_cover_against(5, 5, 1, 0)).is_false()

extends GdUnitTestSuite


func test_load_room_data_valid() -> void:
	var data := RoomLoader.load_room_data("room_standard_01")
	assert_dict(data).is_not_empty()
	assert_str(data.get("id", "")).is_equal("room_standard_01")
	assert_dict(data.get("layout", {})).is_not_empty()


func test_load_room_data_invalid() -> void:
	var data := RoomLoader.load_room_data("non_existent_room")
	assert_dict(data).is_empty()


func test_configure_grid() -> void:
	var data := RoomLoader.load_room_data("room_standard_02")
	# Room 02 has elevation in middle (4,4 to 7,7)
	RoomLoader.configure_grid(data)

	var grid_system := AutoloadHelper.grid_system()
	assert_that(grid_system).is_not_null()

	var tile := grid_system.get_tile(5, 5)
	assert_int(tile.elevation).is_equal(1)  # MID elevation

	tile = grid_system.get_tile(0, 0)
	assert_int(tile.elevation).is_equal(0)  # GROUND elevation


func test_spawn_entities() -> void:
	var data := RoomLoader.load_room_data("room_standard_01")
	var container := Node2D.new()
	var enemies := Node2D.new()
	add_child(container)
	container.add_child(enemies)

	var player := RoomLoader.spawn_entities(data, container, enemies)
	assert_that(player).is_not_null()
	assert_int(enemies.get_child_count()).is_equal(3)

	container.free()


# ── Multi-room generation correctness tests (#463) ─────────────────────────


func test_load_multiple_rooms() -> void:
	## Load room_standard_02 and room_standard_03 and verify they exist and have layouts.
	for room_id: String in ["room_standard_02", "room_standard_03"]:
		var data := RoomLoader.load_room_data(room_id)
		assert_dict(data).is_not_empty()
		assert_that(data.has("layout")).is_true()
		var layout: Dictionary = data["layout"]
		assert_int(layout["elevation"].size()).is_equal(144)
		assert_int(layout["cover"].size()).is_equal(144)
		assert_int(layout["blocked"].size()).is_equal(144)


func test_augment_room_procedurally_full_pipeline() -> void:
	## Verify the full pipeline: load → augment → assign positions → valid layout.
	var room_data: Dictionary = RoomLoader.load_room_data("room_standard_01")
	assert_dict(room_data).is_not_empty()

	# Inject required fields for procedural augmentation
	room_data["topology_seed"] = 12345
	room_data["encounter_seed"] = 67890
	room_data["biome"] = 0
	room_data["room_in_biome"] = 0
	room_data["topology_seed_applied"] = -1

	RoomLoader.augment_room_procedurally(room_data)

	var layout: Dictionary = room_data["layout"]
	assert_int(layout["elevation"].size()).is_equal(144)
	assert_int(layout["cover"].size()).is_equal(144)
	assert_int(layout["blocked"].size()).is_equal(144)


func test_enemy_positions_within_bounds() -> void:
	## After augmentation, all enemy positions must be within the 12x12 grid.
	var room_data: Dictionary = RoomLoader.load_room_data("room_standard_01")
	room_data["topology_seed"] = 11111
	room_data["encounter_seed"] = 22222
	room_data["biome"] = 0
	room_data["room_in_biome"] = 0
	room_data["topology_seed_applied"] = -1

	RoomLoader.augment_room_procedurally(room_data)

	var encounters: Array = room_data.get("encounters", []) as Array
	assert_int(encounters.size()).is_greater(0)

	for enc: Variant in encounters:
		if not enc is Dictionary:
			continue
		var positions: Array = enc.get("positions", []) as Array
		for pos_data: Variant in positions:
			if not pos_data is Dictionary:
				continue
			var d: Dictionary = pos_data as Dictionary
			var x: int = int(d.get("x", -1))
			var y: int = int(d.get("y", -1))
			assert_int(x).is_between(0, 11)
			assert_int(y).is_between(0, 11)


func test_enemy_positions_not_on_blocked_tiles() -> void:
	## After augmentation, no enemy position should fall on a blocked tile.
	var room_data: Dictionary = RoomLoader.load_room_data("room_standard_01")
	room_data["topology_seed"] = 33333
	room_data["encounter_seed"] = 44444
	room_data["biome"] = 0
	room_data["room_in_biome"] = 0
	room_data["topology_seed_applied"] = -1

	RoomLoader.augment_room_procedurally(room_data)

	var layout: Dictionary = room_data["layout"]
	var blocked: Array = layout.get("blocked", [])
	var encounters: Array = room_data.get("encounters", []) as Array

	for enc: Variant in encounters:
		if not enc is Dictionary:
			continue
		var positions: Array = enc.get("positions", []) as Array
		for pos_data: Variant in positions:
			if not pos_data is Dictionary:
				continue
			var d: Dictionary = pos_data as Dictionary
			var x: int = int(d.get("x", 0))
			var y: int = int(d.get("y", 0))
			var idx: int = y * 12 + x
			if idx < blocked.size():
				assert_bool(bool(blocked[idx])).is_false()


func test_room_determinism() -> void:
	## Same room data + same seed should produce identical results.
	var room_data1: Dictionary = RoomLoader.load_room_data("room_standard_01")
	var room_data2: Dictionary = RoomLoader.load_room_data("room_standard_01")

	for rd: Dictionary in [room_data1, room_data2]:
		rd["topology_seed"] = 77777
		rd["encounter_seed"] = 88888
		rd["biome"] = 0
		rd["room_in_biome"] = 0
		rd["topology_seed_applied"] = -1

	RoomLoader.augment_room_procedurally(room_data1)
	RoomLoader.augment_room_procedurally(room_data2)

	var layout1: Dictionary = room_data1["layout"]
	var layout2: Dictionary = room_data2["layout"]
	assert_that(layout1["elevation"]).is_equal(layout2["elevation"])
	assert_that(layout1["cover"]).is_equal(layout2["cover"])
	assert_that(layout1["blocked"]).is_equal(layout2["blocked"])

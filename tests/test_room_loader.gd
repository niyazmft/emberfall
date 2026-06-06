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

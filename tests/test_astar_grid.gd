extends GdUnitTestSuite

const AStarGrid := preload("res://scripts/core/astar_grid.gd")


func test_straight_line_on_empty_grid() -> void:
	var gs := AutoloadHelper.grid_system()
	if gs:
		gs.load_room({"id": "empty", "tiles": []})
	var astar: AStarGrid = AStarGrid.new()
	var path: PackedVector2Array = astar.find_path(Vector2i(0, 0), Vector2i(11, 11))

	assert_that(path.is_empty()).is_false()
	assert_that(path[0]).is_equal(Vector2(0, 0))
	assert_that(path[path.size() - 1]).is_equal(Vector2(11, 11))


func test_wall_detour() -> void:
	var gs := AutoloadHelper.grid_system()
	var wall_tiles: Array[Dictionary] = []
	for x: int in range(2, 10):
		wall_tiles.append({"x": x, "y": 6, "blocks_movement": true, "blocks_vision": true})
	if gs:
		gs.load_room({"id": "wall", "tiles": wall_tiles})
	var astar: AStarGrid = AStarGrid.new()
	var path: PackedVector2Array = astar.find_path(Vector2i(0, 0), Vector2i(11, 11))

	assert_that(path.is_empty()).is_false()
	for i: int in range(path.size()):
		var tile: TacTileData = null
		if gs:
			tile = gs.get_tile(int(path[i].x), int(path[i].y))
		if tile != null:
			assert_that(tile.is_blocked()).is_false()


func test_elevation_blocking() -> void:
	var gs := AutoloadHelper.grid_system()
	var elev_tiles: Array[Dictionary] = [
		{"x": 1, "y": 0, "elevation": 2},
	]
	if gs:
		gs.load_room({"id": "elev", "tiles": elev_tiles})
	var astar: AStarGrid = AStarGrid.new()
	var path: PackedVector2Array = astar.find_path(Vector2i(0, 0), Vector2i(2, 0))

	if not path.is_empty():
		for i: int in range(path.size() - 1):
			var a: Vector2 = path[i]
			var b: Vector2 = path[i + 1]
			var ta: TacTileData = null
			var tb: TacTileData = null
			if gs:
				ta = gs.get_tile(int(a.x), int(a.y))
				tb = gs.get_tile(int(b.x), int(b.y))
			assert_that(ta).is_not_null()
			assert_that(tb).is_not_null()
			assert_that(abs(ta.elevation - tb.elevation) <= 1).is_true()


func test_completely_boxed_goal() -> void:
	var gs := AutoloadHelper.grid_system()
	var box_tiles: Array[Dictionary] = [
		{"x": 1, "y": 0, "blocks_movement": true},
		{"x": 0, "y": 1, "blocks_movement": true},
		{"x": 1, "y": 1, "blocks_movement": true},
	]
	if gs:
		gs.load_room({"id": "box", "tiles": box_tiles})
	var astar: AStarGrid = AStarGrid.new()

	var path: PackedVector2Array = astar.find_path(Vector2i(0, 0), Vector2i(0, 0))
	assert_that(path.size()).is_equal(1)
	assert_that(path[0]).is_equal(Vector2(0, 0))

	path = astar.find_path(Vector2i(0, 0), Vector2i(1, 1))
	assert_that(path.is_empty()).is_true()


func test_corner_cutting_prevention() -> void:
	var gs := AutoloadHelper.grid_system()
	var corner_tiles: Array[Dictionary] = [
		{"x": 1, "y": 0, "blocks_movement": true},
		{"x": 0, "y": 1, "blocks_movement": true},
	]
	if gs:
		gs.load_room({"id": "corner", "tiles": corner_tiles})
	var astar: AStarGrid = AStarGrid.new()
	var path: PackedVector2Array = astar.find_path(Vector2i(0, 0), Vector2i(1, 1))
	assert_that(path.is_empty()).is_true()

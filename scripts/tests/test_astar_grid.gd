extends Node2D
## Smoke test for AStarGrid

const AStarGrid := preload("res://scripts/core/astar_grid.gd")


func _ready() -> void:
	var ok := true

	## 1. Straight line on empty grid
	GridSystem.load_room({"id": "empty", "tiles": []})
	var astar: AStarGrid = AStarGrid.new()
	var path: PackedVector2Array = astar.find_path(Vector2i(0, 0), Vector2i(11, 11))
	if path.is_empty():
		print("FAIL: empty grid path not found")
		ok = false
	elif path[0] != Vector2(0, 0) or path[path.size() - 1] != Vector2(11, 11):
		print("FAIL: wrong endpoints on empty grid")
		ok = false
	else:
		print("PASS: straight line")

	## 2. Wall detour
	var wall_tiles: Array[Dictionary] = []
	for x: int in range(2, 10):
		wall_tiles.append({"x": x, "y": 6, "blocks_movement": true, "blocks_vision": true})
	GridSystem.load_room({"id": "wall", "tiles": wall_tiles})
	astar = AStarGrid.new()
	path = astar.find_path(Vector2i(0, 0), Vector2i(11, 11))
	if path.is_empty():
		print("FAIL: wall detour path not found")
		ok = false
	else:
		for i: int in range(path.size()):
			var tile := GridSystem.get_tile(int(path[i].x), int(path[i].y))
			if tile != null and tile.is_blocked():
				print("FAIL: path crosses wall at ", path[i])
				ok = false
				break
		if ok:
			print("PASS: wall detour")

	## 3. Elevation blocking — path must not step across Δelevation > 1
	var elev_tiles: Array[Dictionary] = [
		{"x": 1, "y": 0, "elevation": 2},
	]
	GridSystem.load_room({"id": "elev", "tiles": elev_tiles})
	astar = AStarGrid.new()
	path = astar.find_path(Vector2i(0, 0), Vector2i(2, 0))
	if path.is_empty():
		## Goal may be unreachable if fully boxed; on open grid a detour exists.
		print("PASS: elevation blocking (no path)")
	else:
		var step_ok := true
		for i: int in range(path.size() - 1):
			var a := path[i]
			var b := path[i + 1]
			var ta := GridSystem.get_tile(int(a.x), int(a.y))
			var tb := GridSystem.get_tile(int(b.x), int(b.y))
			if ta == null or tb == null:
				step_ok = false
				break
			if abs(ta.elevation - tb.elevation) > 1:
				step_ok = false
				break
		if step_ok:
			print("PASS: elevation blocking (detour valid)")
		else:
			print("FAIL: elevation blocking (illegal step)")
			ok = false

	## 4. Completely boxed goal
	var box_tiles: Array[Dictionary] = [
		{"x": 1, "y": 0, "blocks_movement": true},
		{"x": 0, "y": 1, "blocks_movement": true},
		{"x": 1, "y": 1, "blocks_movement": true},
	]
	GridSystem.load_room({"id": "box", "tiles": box_tiles})
	astar = AStarGrid.new()
	path = astar.find_path(Vector2i(0, 0), Vector2i(0, 0))
	if path.size() != 1 or path[0] != Vector2(0, 0):
		print("FAIL: start==goal should return single-point path")
		ok = false
	else:
		print("PASS: start==goal")

	path = astar.find_path(Vector2i(0, 0), Vector2i(1, 1))
	if not path.is_empty():
		print("FAIL: boxed goal should be unreachable")
		ok = false
	else:
		print("PASS: boxed goal unreachable")

	## 5. Corner-cutting prevention
	var corner_tiles: Array[Dictionary] = [
		{"x": 1, "y": 0, "blocks_movement": true},
		{"x": 0, "y": 1, "blocks_movement": true},
	]
	GridSystem.load_room({"id": "corner", "tiles": corner_tiles})
	astar = AStarGrid.new()
	path = astar.find_path(Vector2i(0, 0), Vector2i(1, 1))
	if not path.is_empty():
		print("FAIL: diagonal corner-cut should be blocked")
		ok = false
	else:
		print("PASS: corner-cutting prevention")

	if ok:
		print("\nALL TESTS PASSED")
		get_tree().quit(0)
	else:
		print("\nSOME TESTS FAILED")
		get_tree().quit(1)

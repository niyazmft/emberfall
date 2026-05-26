class_name AStarGrid
extends RefCounted
## Jules-optimized A* pathfinder using Godot native AStar3D backend.
##
## Replaces the interpreted GDScript hot loop with a C++ graph search.
## Performance target: ≤2 ms per query on target hardware.
## Threading: main thread only.

const GRID_SIZE: int = GridSystem.GRID_SIZE
const TOTAL_TILES: int = GridSystem.TOTAL_TILES
const COST_STRAIGHT: int = 10

## Four positive-direction quadrants. connect_points(bidirectional=true)
## mirrors the edge so the graph is undirected without duplicate calls.
const DIRS: Array[Vector2i] = [
	Vector2i( 1,  0),
	Vector2i( 0,  1),
	Vector2i( 1,  1),
	Vector2i( 1, -1),
]

## Native A* graph. Points are pre-registered in _init(); connections are
## rebuilt lazily when GridSystem loads a new room.
var _astar: AStar3D

## Cache to avoid rebuilding graph when the room topology is unchanged.
var _cached_room_id: String = ""

## Re-used output buffer to avoid per-query allocation.
var _path_buffer: Array[Vector2i] = []

func _init() -> void:
	_astar = AStar3D.new()
	_path_buffer = []

	## Register every grid cell once. Positions are scaled by COST_STRAIGHT
	## so that Euclidean distance yields the desired cost model:
	## cardinal = 10, diagonal = ~14.14.
	for i: int in range(TOTAL_TILES):
		var fx: float = float(i % GRID_SIZE) * float(COST_STRAIGHT)
		var fy: float = float(i / GRID_SIZE) * float(COST_STRAIGHT)
		_astar.add_point(i, Vector3(fx, fy, 0.0), 1.0)

## Backward-compatibility stub. The old interpreted A* needed an explicit
## buffer reset; the native backend manages its own state.
func _reset_search() -> void:
	pass

## ------------------------------------------------------------------
## Public API
## ------------------------------------------------------------------
## Find a path from start to goal.
## Returns an Array[Vector2i] of tile coordinates from start to goal
## (inclusive). Returns an empty array if no path exists.
## Threading: main thread ONLY.
func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not GridSystem.is_in_bounds(start.x, start.y) or not GridSystem.is_in_bounds(goal.x, goal.y):
		return []
	if start == goal:
		return [start]

	var goal_i: int = GridSystem.index(goal.x, goal.y)
	var goal_tile: TacTileData = GridSystem.get_tile_by_index(goal_i)
	if goal_tile == null or goal_tile.is_blocked():
		return []

	## Sync graph topology with GridSystem when the room has changed.
	if _cached_room_id != GridSystem.room_id:
		_rebuild_graph()
		_cached_room_id = GridSystem.room_id

	var start_i: int = GridSystem.index(start.x, start.y)
	var ids: PackedInt64Array = _astar.get_id_path(start_i, goal_i)
	if ids.is_empty():
		return []

	_path_buffer.clear()
	for idx: int in range(ids.size()):
		var id: int = ids[idx]
		_path_buffer.append(Vector2i(id % GRID_SIZE, id / GRID_SIZE))
	return _path_buffer.duplicate()

## ------------------------------------------------------------------
## Graph rebuild (room change only)
## ------------------------------------------------------------------
func _rebuild_graph() -> void:
	## Remove and re-add all points. This implicitly clears every
	## connection without calling get_point_connections() which allocates.
	_astar.clear()
	for i: int in range(TOTAL_TILES):
		var fx: float = float(i % GRID_SIZE) * float(COST_STRAIGHT)
		var fy: float = float(i / GRID_SIZE) * float(COST_STRAIGHT)
		_astar.add_point(i, Vector3(fx, fy, 0.0), 1.0)

	## Reconnect valid edges using the same rules as the old GDScript A*:
	## - destination must be in bounds, not blocked, and pass can_move
	## - diagonals require both intermediate cardinal cells to be passable
	for x: int in range(GRID_SIZE):
		for y: int in range(GRID_SIZE):
			var i: int = GridSystem.index(x, y)
			var tile: TacTileData = GridSystem.get_tile_by_index(i)
			if tile == null or tile.is_blocked():
				continue
			for d: Vector2i in DIRS:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if not GridSystem.is_in_bounds(nx, ny):
					continue
				var ni: int = GridSystem.index(nx, ny)
				var ntile: TacTileData = GridSystem.get_tile_by_index(ni)
				if ntile == null or ntile.is_blocked():
					continue
				## Prevent corner-cutting: diagonals require both adjacent
				## cardinal cells to be passable from the start tile.
				var forward_ok: bool = GridSystem.can_move(x, y, nx, ny)
				var reverse_ok: bool = GridSystem.can_move(nx, ny, x, y)
				if d.x != 0 and d.y != 0:
					if forward_ok:
						if not GridSystem.can_move(x, y, x + d.x, y) or not GridSystem.can_move(x, y, x, y + d.y):
							forward_ok = false
					if reverse_ok:
						if not GridSystem.can_move(nx, ny, x + d.x, y) or not GridSystem.can_move(nx, ny, x, y + d.y):
							reverse_ok = false
				if forward_ok:
					_astar.connect_points(i, ni, false)
				if reverse_ok:
					_astar.connect_points(ni, i, false)

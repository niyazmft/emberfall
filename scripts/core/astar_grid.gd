class_name AStarGrid
extends RefCounted
## Engine pathfinding service — Jules-optimized A* using Godot native
## AStar3D backend.  Replaces the interpreted GDScript hot loop with a
## C++ graph search.
##
## Performance target: ≤2 ms per query on Android/Termux.
## Threading: main thread only.

const GRID_SIZE: int = GridSystem.GRID_SIZE
const TOTAL_TILES: int = GridSystem.TOTAL_TILES
const COST_STRAIGHT: int = 10

## Four positive-direction quadrants.  connect_points(bidirectional=true)
## mirrors the edge so the graph is undirected without duplicate calls.
const DIRS: Array[Vector2i] = [
	Vector2i( 1,  0),
	Vector2i( 0,  1),
	Vector2i( 1,  1),
	Vector2i( 1, -1),
]

## Native A* graph.  Points are pre-registered in _init(); connections are
## rebuilt lazily when GridSystem loads a new room.
var _astar: AStar3D

## Cache to avoid rebuilding graph when the room topology is unchanged.
var _cached_room_id: String = ""

## Re-used output buffer to avoid per-query array allocation.
var _path_buffer: PackedVector2Array

func _init() -> void:
	_astar = AStar3D.new()
	_path_buffer = PackedVector2Array()

	## Register every grid cell once.  Positions are scaled by COST_STRAIGHT
	## so that Euclidean distance yields the desired cost model:
	## cardinal = 10, diagonal = ~14.14.
	for i: int in range(TOTAL_TILES):
		var fx: float = float(i % GRID_SIZE) * float(COST_STRAIGHT)
		var fy: float = float(i / GRID_SIZE) * float(COST_STRAIGHT)
		_astar.add_point(i, Vector3(fx, fy, 0.0), 1.0)

## Backward-compatibility stub.  The old interpreted A* needed an explicit
## buffer reset; the native backend manages its own state.
func _reset_search() -> void:
	pass

# ── Public API ───────────────────────────────────────────────────────

## Find a path from (start_x, start_y) to (goal_x, goal_y).
## Returns a PackedVector2Array of tile coordinates from start to goal
## (inclusive).  Returns an empty array if no path exists.
## Threading: main thread ONLY.
func find_path(start_x: int, start_y: int, goal_x: int, goal_y: int) -> PackedVector2Array:
	if not GridSystem.is_in_bounds(start_x, start_y) or not GridSystem.is_in_bounds(goal_x, goal_y):
		return PackedVector2Array()
	if start_x == goal_x and start_y == goal_y:
		_path_buffer.clear()
		_path_buffer.append(Vector2(float(start_x), float(start_y)))
		return _path_buffer

	var goal_i: int = GridSystem.index(goal_x, goal_y)
	var goal_tile: TacTileData = GridSystem.get_tile_by_index(goal_i)
	if goal_tile == null or goal_tile.is_blocked():
		return PackedVector2Array()

	## Sync graph topology with GridSystem when the room has changed.
	if _cached_room_id != GridSystem.room_id:
		_rebuild_graph()
		_cached_room_id = GridSystem.room_id

	var start_i: int = GridSystem.index(start_x, start_y)
	var ids: PackedInt64Array = _astar.get_id_path(start_i, goal_i)
	if ids.is_empty():
		return PackedVector2Array()

	var path: Array[Vector2i] = []
	path.resize(ids.size())
	for idx: int in range(ids.size()):
		var id: int = ids[idx]
		_path_buffer.append(Vector2(float(id % GRID_SIZE), float(id / GRID_SIZE)))
	return _path_buffer

# ── Graph rebuild (room change only) ─────────────────────────────────

func _rebuild_graph() -> void:
	## Remove and re-add all points.  This implicitly clears every
	## connection without calling get_point_connections() which allocates.
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
				
				if forward_ok and reverse_ok:
					_astar.connect_points(i, ni, true)
				elif forward_ok:
					_astar.connect_points(i, ni, false)
				elif reverse_ok:
					_astar.connect_points(ni, i, false)


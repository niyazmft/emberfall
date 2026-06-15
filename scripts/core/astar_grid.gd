class_name AStarGrid
extends RefCounted
## Jules-optimized A* pathfinder using Godot native AStar3D backend.
##
## Replaces the interpreted GDScript hot loop with a C++ graph search.
## Performance target: ≤2 ms per query on target hardware.
## Threading: main thread only.

const GRID_SIZE: int = _GridSystem.GRID_SIZE
const TOTAL_TILES: int = _GridSystem.TOTAL_TILES
const COST_STRAIGHT: int = 10

## Four positive-direction quadrants. connect_points(bidirectional=true)
## mirrors the edge so the graph is undirected without duplicate calls.
const DIRS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(1, -1),
]

## Native A* graph. Points are pre-registered in _init(); connections are
## rebuilt lazily when GridSystem loads a new room.
var _astar: AStar3D

## Cache to avoid rebuilding graph when the room topology is unchanged.
var _cached_room_id: String = ""

## Cached GridSystem reference to avoid repeated get_node tree traversals
## in the hot path (20+ calls per path query).
var _grid_system: _GridSystem


func _init() -> void:
	_astar = AStar3D.new()
	_grid_system = AutoloadHelper.grid_system()
	assert(_grid_system != null, "AStarGrid: GridSystem autoload not found")

	## Register every grid cell once. Positions are scaled by COST_STRAIGHT
	## so that Euclidean distance yields the desired cost model:
	## cardinal = 10, diagonal = ~14.14.
	for i: int in range(TOTAL_TILES):
		var fx: float = float(i % GRID_SIZE) * float(COST_STRAIGHT)
		var fy: float = float(i / GRID_SIZE) * float(COST_STRAIGHT)
		_astar.add_point(i, Vector3(fx, fy, 0.0), 1.0)


## ------------------------------------------------------------------
## Public API
## ------------------------------------------------------------------
## Find a path from start to goal.
## Returns an Array[Vector2i] of tile coordinates from start to goal
## (inclusive). Returns an empty array if no path exists.
## Threading: main thread ONLY.
func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if (
		not _grid_system.is_in_bounds(start.x, start.y)
		or not _grid_system.is_in_bounds(goal.x, goal.y)
	):
		return []
	if start == goal:
		return [start]

	var goal_i: int = _grid_system.index(goal.x, goal.y)
	var goal_tile: TacTileData = _grid_system.get_tile_by_index(goal_i)
	if goal_tile == null or goal_tile.blocks_movement:
		return []

	## Sync graph topology with GridSystem when the room has changed.
	if _cached_room_id != _grid_system.room_id:
		_rebuild_graph()
		_cached_room_id = _grid_system.room_id

	var start_i: int = _grid_system.index(start.x, start.y)
	var ids: PackedInt64Array = _astar.get_id_path(start_i, goal_i)
	if ids.is_empty():
		return []

	var path: Array[Vector2i] = []
	path.resize(ids.size())
	for idx: int in range(ids.size()):
		var id: int = ids[idx]
		path[idx] = Vector2i(id % GRID_SIZE, id / GRID_SIZE)
	return path


## ------------------------------------------------------------------
## Graph rebuild (room change only)
## ------------------------------------------------------------------
func _rebuild_graph() -> void:
	## Clear every connection without calling get_point_connections() which allocates.
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
			var i: int = _grid_system.index(x, y)
			var tile: TacTileData = _grid_system.get_tile_by_index(i)
			if tile == null or tile.blocks_movement:
				continue
			for d: Vector2i in DIRS:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if not _grid_system.is_in_bounds(nx, ny):
					continue
				var ni: int = _grid_system.index(nx, ny)
				var ntile: TacTileData = _grid_system.get_tile_by_index(ni)
				if ntile == null or ntile.blocks_movement:
					continue
				## Prevent corner-cutting: diagonals require both adjacent
				## cardinal cells to be passable from the start tile.
				var forward_ok: bool = _grid_system.can_move(x, y, nx, ny)
				var reverse_ok: bool = _grid_system.can_move(nx, ny, x, y)
				if d.x != 0 and d.y != 0:
					if forward_ok:
						if (
							not _grid_system.can_move(x, y, x + d.x, y)
							or not _grid_system.can_move(x, y, x, y + d.y)
						):
							forward_ok = false
					if reverse_ok:
						if (
							not _grid_system.can_move(nx, ny, x + d.x, y)
							or not _grid_system.can_move(nx, ny, x, y + d.y)
						):
							reverse_ok = false

				if forward_ok and reverse_ok:
					_astar.connect_points(i, ni, true)
				elif forward_ok:
					_astar.connect_points(i, ni, false)
				elif reverse_ok:
					_astar.connect_points(ni, i, false)

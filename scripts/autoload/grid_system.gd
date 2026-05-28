extends Node
class_name _GridSystem
## GridSystem (autoload)
## Owns the 12×12 tactical grid, tile metadata, and pre-computed cover
## tables. Loads room definitions from JSON and exposes a clean API
## for gameplay systems.
##
## Memory: holds 144 TacTileData objects in a flat PackedArray; zero
## allocations after room load.
## Threading: main thread only.

const GRID_SIZE: int = 12
const TOTAL_TILES: int = GRID_SIZE * GRID_SIZE
const MAX_ELEVATION_DELTA: int = 1

## Flat tile buffer — index = y * GRID_SIZE + x
var _tiles: Array[Resource] = []

## Pre-computed cover raycast cache.
## cover_cache[from_index][to_index] = true if 'to' provides cover against 'from'.
var _cover_cache: Array[bool] = []
var _cache_valid: bool = false

## Currently loaded room identifier.
var room_id: String = ""

## Dynamic tile elemental overlay.
## Key: tile_index (y*GRID_SIZE+x), Value: Array of effect dictionaries.
## Each effect: { "element": ElementType, "duration": int, "applied_turn": int }
var _elemental_overlay: Dictionary = {}

## Engine constant: oil reduces movement speed by 0.8×.
## Discrete grid cost: ceil(1 / 0.8) = 2 AP per tile.
const _ELEM_NONE: int = 0
const _ELEM_OIL: int = 4

const SLIP_SPEED_FACTOR: float = 0.8
const SLIP_MOVEMENT_BASE_COST: int = 1


## ------------------------------------------------------------------
## Lifecycle
## ------------------------------------------------------------------
func _ready() -> void:
	_reset_grid()


func _reset_grid() -> void:
	_tiles.resize(TOTAL_TILES)
	for i: int in range(TOTAL_TILES):
		var t: Resource = (load("res://scripts/core/tile_data.gd") as GDScript).new()
		t.set("coords", Vector2i(i % GRID_SIZE, i / GRID_SIZE))
		if t.has_method("recompute_flags"):
			t.call("recompute_flags")
		_tiles[i] = t
	_elemental_overlay.clear()
	_invalidate_cache()


func _invalidate_cache() -> void:
	_cache_valid = false
	_cover_cache.resize(TOTAL_TILES * TOTAL_TILES)
	_cover_cache.fill(false)


## ------------------------------------------------------------------
## Public API — Coordinate helpers
## ------------------------------------------------------------------
func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE


func index(x: int, y: int) -> int:
	return y * GRID_SIZE + x


func get_tile(x: int, y: int) -> Resource:
	if not is_in_bounds(x, y):
		return null
	return _tiles[index(x, y)]


func get_tile_by_index(i: int) -> Resource:
	if i < 0 or i >= TOTAL_TILES:
		return null
	return _tiles[i]


func all_tiles() -> Array[Resource]:
	return _tiles.duplicate()


## ------------------------------------------------------------------
## Public API — Room loading
## ------------------------------------------------------------------
## Load a room from a JSON Dictionary. Expected shape:
## {
##   "id": "room_01",
##   "tiles": [
##     {"x":0, "y":0, "elevation":0, "cover":0, "blocks_movement":false, "blocks_vision":false},
##     ...
##   ]
## }
## Missing tiles keep default values.
func load_room(data: Dictionary) -> Error:
	_reset_grid()
	if data.has("id"):
		room_id = str(data["id"])
	if not data.has("tiles") or not data["tiles"] is Array:
		return ERR_INVALID_DATA
	var tile_list: Array = data["tiles"] as Array
	for entry: Variant in tile_list:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var x: int = int(d.get("x", -1))
		var y: int = int(d.get("y", -1))
		if not is_in_bounds(x, y):
			continue
		var t: Resource = get_tile(x, y)
		t.set("elevation", int(d.get("elevation", 0)))
		t.set("cover", int(d.get("cover", 0)))
		t.set("blocks_movement", bool(d.get("blocks_movement", false)))
		t.set("blocks_vision", bool(d.get("blocks_vision", false)))
		if d.has("tags") and d["tags"] is Array:
			var tag_list: Array = d["tags"] as Array
			for tag: Variant in tag_list:
				var tag_array: Array = t.get("tags") as Array
				tag_array.append(str(tag))
		if t.has_method("recompute_flags"):
			t.call("recompute_flags")
	_recompute_cover_cache()
	return OK


## Convenience: load from a JSON file path (async-friendly wrapper).
func load_room_from_file(path: String) -> Error:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return FileAccess.get_open_error()
	var text: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		return err
	if not json.data is Dictionary:
		return ERR_INVALID_DATA
	return load_room(json.data)


## ------------------------------------------------------------------
## Public API — Movement
## ------------------------------------------------------------------
## Returns true if a unit can move from (from_x, from_y) to (to_x, to_y).
## Rules: in bounds, target not blocked, elevation delta ≤ MAX_ELEVATION_DELTA.
func can_move(from_x: int, from_y: int, to_x: int, to_y: int) -> bool:
	if not is_in_bounds(to_x, to_y):
		return false
	var from_tile: Resource = get_tile(from_x, from_y)
	var to_tile: Resource = get_tile(to_x, to_y)
	if from_tile == null or to_tile == null:
		return false
	if bool(to_tile.call("is_blocked")):
		return false
	var delta: int = abs(int(from_tile.get("elevation")) - int(to_tile.get("elevation")))
	return delta <= MAX_ELEVATION_DELTA


## ------------------------------------------------------------------
## Public API — Oil helpers (backward-compatible API)
## ------------------------------------------------------------------
func set_oil_tile(x: int, y: int, has_oil: bool) -> void:
	if not is_in_bounds(x, y):
		return
	var idx: int = index(x, y)
	## Remove any existing oil entries first.
	if _elemental_overlay.has(idx):
		var arr: Array = _elemental_overlay[idx]
		for i: int in range(arr.size() - 1, -1, -1):
			if arr[i]["element"] == _ELEM_OIL:
				arr.remove_at(i)
		if arr.is_empty():
			_elemental_overlay.erase(idx)
	if has_oil:
		_elemental_overlay[idx] = [{"element": _ELEM_OIL, "duration": 999, "applied_turn": -1}]


func has_oil_tile(x: int, y: int) -> bool:
	if not is_in_bounds(x, y):
		return false
	var idx: int = index(x, y)
	if not _elemental_overlay.has(idx):
		return false
	var effects: Array = _elemental_overlay[idx]
	for eff: Variant in effects:
		if eff.get("element", _ELEM_NONE) == _ELEM_OIL:
			return true
	return false


func is_slippery(x: int, y: int) -> bool:
	return has_oil_tile(x, y)


## ------------------------------------------------------------------
## Public API — Elemental tile overlay (duration-tracked)
## ------------------------------------------------------------------
## Apply an elemental effect to a tile with a turn duration.
## Duration >= 1 means it persists for that many `tick_tile_effects` calls.
## Effects are stored in FIFO order (per turn applied).
func apply_tile_element(x: int, y: int, element: int, duration: int, applied_turn: int) -> void:
	if not is_in_bounds(x, y):
		return
	if duration < 1:
		return
	if not (element >= _ELEM_NONE and element <= _ELEM_OIL):
		return
	var idx: int = index(x, y)
	if not _elemental_overlay.has(idx):
		_elemental_overlay[idx] = []
	var arr: Array = _elemental_overlay[idx]
	arr.append({"element": element, "duration": duration, "applied_turn": applied_turn})


## Returns an Array of effect dictionaries (copies) for the tile.
func get_tile_effects(x: int, y: int) -> Array:
	if not is_in_bounds(x, y):
		return []
	var idx: int = index(x, y)
	var raw: Array = _elemental_overlay.get(idx, [])
	var out: Array = []
	out.resize(raw.size())
	for i: int in range(raw.size()):
		out[i] = raw[i].duplicate()
	return out


## Returns the set of active element types on a tile.
## Uses a small PackedInt32Array to avoid heap churn.
func get_active_tile_elements(x: int, y: int) -> PackedInt32Array:
	if not is_in_bounds(x, y):
		return PackedInt32Array()
	var out := PackedInt32Array()
	var effects: Array = get_tile_effects(x, y)
	for eff: Variant in effects:
		var e: int = eff["element"]
		if not out.has(e):
			out.append(e)
	return out


## Remove a specific element type from a tile (e.g. Water extinguishes Fire).
func remove_tile_element(x: int, y: int, element: int) -> void:
	if not is_in_bounds(x, y):
		return
	var idx: int = index(x, y)
	if not _elemental_overlay.has(idx):
		return
	var arr: Array = _elemental_overlay[idx]
	for i: int in range(arr.size() - 1, -1, -1):
		if arr[i]["element"] == element:
			arr.remove_at(i)
	## Clean up empty arrays.
	if arr.is_empty():
		_elemental_overlay.erase(idx)


## Engine tick: decrement all durations and purge expired effects.
## Returns the number of expired effects removed.
func tick_tile_effects() -> int:
	var expired := 0
	var keys_to_remove: Array = []
	for idx: Variant in _elemental_overlay.keys():
		var arr: Array = _elemental_overlay[idx]
		for i: int in range(arr.size() - 1, -1, -1):
			arr[i]["duration"] -= 1
			if arr[i]["duration"] <= 0:
				arr.remove_at(i)
				expired += 1
		if arr.is_empty():
			keys_to_remove.append(idx)
	for k: Variant in keys_to_remove:
		_elemental_overlay.erase(k)
	return expired


## Returns the movement cost to enter (to_x, to_y) from an adjacent tile.
## Base cost is 1; oil tiles cost ceil(1 / SLIP_SPEED_FACTOR) = 2.
func get_movement_cost(to_x: int, to_y: int) -> int:
	if not is_in_bounds(to_x, to_y):
		return 0
	var cost: int = SLIP_MOVEMENT_BASE_COST
	if has_oil_tile(to_x, to_y):
		cost = ceili(float(SLIP_MOVEMENT_BASE_COST) / SLIP_SPEED_FACTOR)
	return cost


## Clear all dynamic elemental overlays (call on room unload / run reset).
func clear_elemental_overlay() -> void:
	_elemental_overlay.clear()


## ------------------------------------------------------------------
## Public API — Cover
## ------------------------------------------------------------------
## Returns true if 'observer' has line of sight to 'target' (ignoring cover).
## Uses Bresenham-style grid raycast.
func has_los(observer_x: int, observer_y: int, target_x: int, target_y: int) -> bool:
	if not is_in_bounds(observer_x, observer_y) or not is_in_bounds(target_x, target_y):
		return false
	var dx: int = abs(target_x - observer_x)
	var dy: int = abs(target_y - observer_y)
	var sx: int = 1 if observer_x < target_x else -1
	var sy: int = 1 if observer_y < target_y else -1
	var err: int = dx - dy
	var x: int = observer_x
	var y: int = observer_y
	while true:
		if x == target_x and y == target_y:
			return true
		var tile: Resource = get_tile(x, y)
		if (
			tile != null
			and bool(tile.get("blocks_vision"))
			and not (x == observer_x and y == observer_y)
		):
			return false
		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy
	return false


## Returns true if 'target' has cover against 'observer'.
## Heavy cover blocks all attacks; light cover provides partial.
## Uses the pre-computed cache when valid.
func target_has_cover_against(
	observer_x: int, observer_y: int, target_x: int, target_y: int
) -> bool:
	if not _cache_valid:
		_recompute_cover_cache()
	var oi: int = index(observer_x, observer_y)
	var ti: int = index(target_x, target_y)
	return _cover_cache[oi * TOTAL_TILES + ti]


## ------------------------------------------------------------------
## Internal — Cover cache
## ------------------------------------------------------------------
func _recompute_cover_cache() -> void:
	_invalidate_cache()
	for oy: int in range(GRID_SIZE):
		for ox: int in range(GRID_SIZE):
			var oi: int = oy * GRID_SIZE + ox
			var base_idx: int = oi * TOTAL_TILES

			var min_ty: int = max(0, oy - 1)
			var max_ty: int = min(GRID_SIZE - 1, oy + 1)
			var min_tx: int = max(0, ox - 1)
			var max_tx: int = min(GRID_SIZE - 1, ox + 1)

			for ty: int in range(min_ty, max_ty + 1):
				for tx: int in range(min_tx, max_tx + 1):
					if ox == tx and oy == ty:
						continue

					var ti: int = ty * GRID_SIZE + tx
					var target: Resource = _tiles[ti]
					if target != null and target.has_cover():
						if has_los(ox, oy, tx, ty):
							var dx: int = abs(ox - tx)
							var dy: int = abs(oy - ty)
							if dx == 1 and dy == 1:
								var side1: Resource = _tiles[oy * GRID_SIZE + tx]
								var side2: Resource = _tiles[ty * GRID_SIZE + ox]
								if (
									(side1 != null and side1.blocks_vision)
									or (side2 != null and side2.blocks_vision)
								):
									_cover_cache[base_idx + ti] = true
							elif target.is_heavy_cover():
								_cover_cache[base_idx + ti] = true
	_cache_valid = true

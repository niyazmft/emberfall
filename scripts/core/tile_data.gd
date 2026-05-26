class_name TacTileData
extends Resource
## TileData
## Immutable-ish resource describing a single grid cell. Elevation, cover,
## and metadata are set at room-load time and treated as read-only by
## simulation systems.
##
## Threading: safe to read from any thread after construction.

enum Elevation { GROUND = 0, MID = 1, HIGH = 2 }
enum CoverType { NONE = 0, LIGHT = 1, HEAVY = 2 }

@export var coords: Vector2i = Vector2i.ZERO
@export var elevation: Elevation = Elevation.GROUND
@export var cover: CoverType = CoverType.NONE
@export var blocks_movement: bool = false
@export var blocks_vision: bool = false
@export var tags: PackedStringArray = []

## Pre-computed cover flag cache used by the pathfinder and combat
## raycaster. Updated by GridSystem after room load.
var cover_flags: int = 0
const FLAG_COVER_LIGHT: int = 1 << 0
const FLAG_COVER_HEAVY: int = 1 << 1
const FLAG_ELEVATION_0: int = 1 << 2
const FLAG_ELEVATION_1: int = 1 << 3
const FLAG_ELEVATION_2: int = 1 << 4
const FLAG_BLOCKED_MOVE: int = 1 << 5
const FLAG_BLOCKED_VISION: int = 1 << 6

## Recompute cover_flags from current properties. Call once after
## deserialising or mutating a tile (mutations should only happen
## during room load, never mid-combat).
func recompute_flags() -> void:
	cover_flags = 0
	match elevation:
		Elevation.GROUND: cover_flags |= FLAG_ELEVATION_0
		Elevation.MID:    cover_flags |= FLAG_ELEVATION_1
		Elevation.HIGH:   cover_flags |= FLAG_ELEVATION_2
	match cover:
		CoverType.LIGHT:  cover_flags |= FLAG_COVER_LIGHT
		CoverType.HEAVY:  cover_flags |= FLAG_COVER_HEAVY
	if blocks_movement:
		cover_flags |= FLAG_BLOCKED_MOVE
	if blocks_vision:
		cover_flags |= FLAG_BLOCKED_VISION

func has_cover() -> bool:
	return (cover_flags & (FLAG_COVER_LIGHT | FLAG_COVER_HEAVY)) != 0

func is_light_cover() -> bool:
	return (cover_flags & FLAG_COVER_LIGHT) != 0

func is_heavy_cover() -> bool:
	return (cover_flags & FLAG_COVER_HEAVY) != 0

func is_blocked() -> bool:
	return (cover_flags & FLAG_BLOCKED_MOVE) != 0

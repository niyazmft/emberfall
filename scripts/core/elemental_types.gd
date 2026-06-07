class_name ElementalTypes
## Data structures for the elemental combo system (DON-101 B3).
## Enums and lightweight record classes for tile effects and combo results.
##
## All values are config-driven with sensible defaults.

# ── Element Enumeration ───────────────────────────────────────────────
enum ElementType { NONE, FIRE, WATER, WIND, OIL }  ## No active element  ## Fire: spreads, extinguished by water, amplified by oil  ## Water: extinguishes fire, blocks fire spread  ## Wind: fans fire (1.5×), spreads it to adjacent tiles  ## Oil: amplifies fire to 2.0×, causes slip terrain (0.8× speed)


# ── Tile Effect Record ────────────────────────────────────────────────
class TileEffect:
	extends RefCounted
	## A single elemental effect active on a grid tile.
	var element: ElementType
	var duration: int  ## Remaining turns before expiry
	var applied_turn: int  ## Turn number when this effect was placed
	var source_pos: Vector2i  ## Origin tile for spread tracking

	func _init(
		p_element: ElementType,
		p_duration: int,
		p_applied_turn: int,
		p_source_pos := Vector2i(-999, -999)
	) -> void:
		element = p_element
		duration = p_duration
		applied_turn = p_applied_turn
		source_pos = p_source_pos

	## Returns true if current_turn has exceeded the effect's lifetime.
	func is_expired(current_turn: int) -> bool:
		return current_turn > applied_turn + duration

	## Deep copy for safe mutation during resolution.
	func clone() -> TileEffect:
		return TileEffect.new(element, duration, applied_turn, source_pos)


# ── Combo Result Record ───────────────────────────────────────────────
class ComboResult:
	extends RefCounted
	## Output of resolving an elemental interaction on a tile.
	var damage_multiplier: float
	var movement_speed_multiplier: float
	var new_effects: Array[TileEffect]  ## Effects to add (e.g. spread fire)
	var removed_elements: Array[ElementType]  ## Elements consumed/removed
	var description: String

	func _init(
		p_damage_mult: float = 1.0, p_speed_mult: float = 1.0, p_description: String = ""
	) -> void:
		damage_multiplier = p_damage_mult
		movement_speed_multiplier = p_speed_mult
		new_effects = []
		removed_elements = []
		description = p_description

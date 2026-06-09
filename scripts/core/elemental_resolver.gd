class_name ElementalInteractionResolver
## Resolves elemental interactions deterministically per system-spec §2.3.
## Combo chains process in FIFO order (oldest applied effect resolves first).
##
## Responsibilities:
##   • Tile effect duration tracking and expiry
##   • Damage modifier lookup (fire↔oil, wind→fire, water→fire)
##   • Fire spread simulation with bounds + water blocking
##   • Water extinguish logic (bidirectional)
##   • Oil slip terrain speed debuff
##   • FIFO combo chain resolution
##
## All tunable constants are pulled from ConfigLoader with hard-coded
## defaults so the game runs even if config is missing.
##
## Reference: DON-101 B3




# ── Typed Element Queries ─────────────────────────────────────────────────
static func _has_element(
	effects: Array[ElementalTypes.TileEffect], elem: ElementalTypes.ElementType
) -> bool:
	for e: ElementalTypes.TileEffect in effects:
		if e.element == elem:
			return true
	return false


static func _remove_element(
	effects: Array[ElementalTypes.TileEffect], elem: ElementalTypes.ElementType
) -> Array[ElementalTypes.TileEffect]:
	var out: Array[ElementalTypes.TileEffect] = []
	for e: ElementalTypes.TileEffect in effects:
		if e.element != elem:
			out.append(e)
	return out


static func _filter_active(
	effects: Array[ElementalTypes.TileEffect], current_turn: int
) -> Array[ElementalTypes.TileEffect]:
	var out: Array[ElementalTypes.TileEffect] = []
	for e: ElementalTypes.TileEffect in effects:
		if not e.is_expired(current_turn):
			out.append(e)
	return out


# ── Damage Multiplier ───────────────────────────────────────────────────
## Computes the total damage multiplier for combat occurring on a tile
## with the given active effects. Handles overlapping interactions
## deterministically.
##
## Resolution order (priority):
##   1. Water + Fire  → extinguish + 0.5×
##   2. Wind  + Fire  → fan/spread + 1.5×
##   3. Fire  + Oil   → burn off   + 2.0×
##
## If multiple modifiers could apply, the highest-priority interaction wins
## because earlier interactions consume elements (extinguish, burn off).
static func compute_tile_damage_multiplier(
	effects: Array[ElementalTypes.TileEffect], current_turn: int
) -> float:
	var active: Array[ElementalTypes.TileEffect] = _filter_active(effects, current_turn)
	if active.is_empty():
		return 1.0

	var has_fire: bool = _has_element(active, ElementalTypes.ElementType.FIRE)
	var has_oil: bool = _has_element(active, ElementalTypes.ElementType.OIL)
	var has_wind: bool = _has_element(active, ElementalTypes.ElementType.WIND)
	var has_water: bool = _has_element(active, ElementalTypes.ElementType.WATER)

	# Priority 1: Water extinguishes Fire → 0.5× (extinguish overrides amplification)
	if has_water and has_fire:
		return AutoloadHelper.config_float("elemental", "WATER_FIRE_MODIFIER", 0.5)

	# Priority 2: Wind fans Fire → 1.5×
	if has_wind and has_fire:
		return AutoloadHelper.config_float("elemental", "WIND_FIRE_MODIFIER", 1.5)

	# Priority 3: Fire burns Oil → 2.0×
	if has_fire and has_oil:
		return AutoloadHelper.config_float("elemental", "FIRE_OIL_MODIFIER", 2.0)

	# Fallback: no recognised combo
	return 1.0


# ── Movement Speed Multiplier ───────────────────────────────────────────
## Returns the speed multiplier for an entity moving through a tile.
## Oil slip applies a 0.8× debuff regardless of other elements.
static func calculate_movement_speed_multiplier(
	effects: Array[ElementalTypes.TileEffect], current_turn: int
) -> float:
	var active: Array[ElementalTypes.TileEffect] = _filter_active(effects, current_turn)
	if _has_element(active, ElementalTypes.ElementType.OIL):
		return AutoloadHelper.config_float("elemental", "OIL_SLIP_SPEED_MULT", 0.8)
	return 1.0


# ── Apply Element ────────────────────────────────────────────────────────
## Returns a new effect list with the given element appended.
## Does NOT resolve interactions immediately — resolution is deferred to
## process_turn_tick() to guarantee deterministic FIFO ordering.
static func apply_element(
	effects: Array[ElementalTypes.TileEffect],
	elem: ElementalTypes.ElementType,
	current_turn: int,
	duration: int = 1,
	source_pos := Vector2i(-999, -999)
) -> Array[ElementalTypes.TileEffect]:
	if elem == ElementalTypes.ElementType.NONE:
		return effects.duplicate()

	var new_effect := ElementalTypes.TileEffect.new(elem, duration, current_turn, source_pos)
	var out: Array[ElementalTypes.TileEffect] = effects.duplicate()
	out.append(new_effect)
	return out


# ── Process Turn Tick (FIFO Resolution) ───────────────────────────────
## Walks effects left-to-right (oldest first).  At each effect, the resolver
## scans the *entire* working set for its complementary reactant, preferring
## the leftmost match.  This guarantees bidirectional interactions work
## regardless of application order while still respecting FIFO ordering.
##
## Steps per tick:
##   1. Expire old effects (duration exhausted).
##   2. Scan FIFO and resolve combos in order:
##      • Water + Fire  → remove both, emit extinguish result
##      • Wind  + Fire  → fan fire, spread to adjacent tiles, remove wind
##      • Fire  + Oil   → burn off oil, refresh fire duration
##   3. Return updated effect list + any spread results.
##
## @param effects      Current tile effects
## @param current_turn Turn index for expiry checks
## @param tile_pos     Position of the tile being processed (for spread)
## @param grid_bounds  Optional inclusive bounds [min, max] as Vector2i for spread clamping
## @param water_tiles  Optional array of tile positions that block fire spread
## @return Dictionary with keys:
##         "effects"          -> Array[TileEffect] (updated active effects)
##         "spread_positions" -> Array[Vector2i]   (tiles that received new fire)
##         "extinguished"     -> bool              (true if water put out fire)
static func process_turn_tick(
	effects: Array[ElementalTypes.TileEffect],
	current_turn: int,
	tile_pos: Vector2i,
	grid_bounds: Array[Vector2i] = [],
	water_tiles: Array[Vector2i] = []
) -> Dictionary:
	var out_effects: Array[ElementalTypes.TileEffect] = _filter_active(effects, current_turn)
	var spread_positions: Array[Vector2i] = []
	var extinguished: bool = false

	# Clone so mutations don't alias caller's array
	var working: Array[ElementalTypes.TileEffect] = []
	for e: ElementalTypes.TileEffect in out_effects:
		working.append(e.clone())

	# ── Phase 2: FIFO combo resolution ──────────────────────────────────
	var i: int = 0
	while i < working.size():
		var current: ElementalTypes.TileEffect = working[i]

		match current.element:
			ElementalTypes.ElementType.WATER:
				# Water looks for ANY Fire in the working set (leftmost first)
				var fire_idx := _find_leftmost_element(working, ElementalTypes.ElementType.FIRE)
				if fire_idx != -1 and fire_idx != i:
					# Remove Fire first (higher or lower index doesn't matter
					# because we recalc i afterwards)
					var removed_fire: int = fire_idx
					var removed_water: int = i
					working.remove_at(removed_fire)
					if removed_fire < removed_water:
						removed_water -= 1
					working.remove_at(removed_water)
					if removed_water <= i:
						i = removed_water - 1
					else:
						i -= 1
					if i < 0:
						i = 0
					extinguished = true

			ElementalTypes.ElementType.WIND:
				# Wind looks for ANY Fire to fan (leftmost first)
				var fire_idx := _find_leftmost_element(working, ElementalTypes.ElementType.FIRE)
				if fire_idx != -1 and fire_idx != i:
					# Refresh fire duration
					working[fire_idx].duration = AutoloadHelper.config_int("elemental", "FIRE_DURATION_TURNS", 1)
					working[fire_idx].applied_turn = current_turn
					# Remove wind
					working.remove_at(i)
					i -= 1
					if i < 0:
						i = 0
					# Spread to adjacent tiles respecting bounds + water block
					var candidates: Array[Vector2i] = _adjacent_cardinal(tile_pos)
					for cand: Vector2i in candidates:
						var actual_water_tiles := water_tiles.duplicate()
						# Also treat adjacent tiles that have water effects as blocking
						if _in_bounds(cand, grid_bounds) and cand not in actual_water_tiles:
							spread_positions.append(cand)

			ElementalTypes.ElementType.FIRE:
				# Fire looks for ANY Oil to burn off (leftmost first)
				var oil_idx := _find_leftmost_element(working, ElementalTypes.ElementType.OIL)
				if oil_idx != -1 and oil_idx != i:
					# Oil burns off completely
					working.remove_at(oil_idx)
					if oil_idx < i:
						i -= 1
					# Refresh fire duration after consuming oil
					working[i].duration = AutoloadHelper.config_int("elemental", "FIRE_OIL_DURATION_TURNS", 1)
					working[i].applied_turn = current_turn

		i += 1

	return {
		"effects": working,
		"spread_positions": spread_positions,
		"extinguished": extinguished,
	}


# ── Spread Helper (for external tile-map integration) ──────────────────
## Given a tile that has fire, compute adjacent positions where fire should
## spread, respecting grid bounds and water-blocked tiles.
##
## @param fire_pos    Position of the source fire tile
## @param grid_bounds Inclusive bounds [min, max] as Vector2i
## @param water_tiles Array[Vector2i] of tiles that block fire spread
## @return Array[Vector2i] of valid spread target positions
static func compute_fire_spread_targets(
	fire_pos: Vector2i, grid_bounds: Array[Vector2i], water_tiles: Array[Vector2i] = []
) -> Array[Vector2i]:
	if grid_bounds.is_empty():
		return []

	var targets: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d: Vector2i in dirs:
		var cand: Vector2i = fire_pos + d
		if _in_bounds(cand, grid_bounds) and cand not in water_tiles:
			targets.append(cand)
	return targets


# ── Convenience: Full Modifiers for Entity-on-Tile ───────────────────────
## Returns both damage multiplier and speed multiplier for a tile in one call.
static func compute_tile_modifiers(
	effects: Array[ElementalTypes.TileEffect], current_turn: int
) -> Dictionary:
	return {
		"damage_multiplier": compute_tile_damage_multiplier(effects, current_turn),
		"speed_multiplier": calculate_movement_speed_multiplier(effects, current_turn),
	}


# ── Internal Helpers ───────────────────────────────────────────────────
## Find the leftmost occurrence of `elem` in `arr`, skipping the element
## at `exclude_idx` if provided. Returns -1 if not found.
static func _find_leftmost_element(
	arr: Array[ElementalTypes.TileEffect], elem: ElementalTypes.ElementType, exclude_idx: int = -1
) -> int:
	for idx: int in range(arr.size()):
		if idx == exclude_idx:
			continue
		if arr[idx].element == elem:
			return idx
	return -1


static func _adjacent_cardinal(pos: Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(1, 0),
		pos + Vector2i(-1, 0),
		pos + Vector2i(0, 1),
		pos + Vector2i(0, -1),
	]


static func _in_bounds(pos: Vector2i, bounds: Array[Vector2i]) -> bool:
	if bounds.is_empty():
		return true
	if bounds.size() < 2:
		return true
	var min_b: Vector2i = bounds[0]
	var max_b: Vector2i = bounds[1]
	return pos.x >= min_b.x and pos.x <= max_b.x and pos.y >= min_b.y and pos.y <= max_b.y

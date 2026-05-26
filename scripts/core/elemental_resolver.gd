class_name ElementalInteractionResolver
## (DON-101) Ported Elemental Interaction System.
## Preserves identical deterministic behavior from C# implementation.

# ── Config Helpers ──────────────────────────────────────────────────────
static func _config_float(key: String, fallback: float) -> float:
	var ml := Engine.get_main_loop()
	if ml == null or ml.root == null or not ml.root.is_inside_tree():
		return fallback
	var loader: Node = ml.root.get_node_or_null("/root/ConfigLoader")
	if loader != null and loader.has_method("get_float"):
		return (loader.call("get_float", key, fallback) as float)
	return fallback


static func _config_int(key: String, fallback: int) -> int:
	var ml := Engine.get_main_loop()
	if ml == null or ml.root == null or not ml.root.is_inside_tree():
		return fallback
	var loader: Node = ml.root.get_node_or_null("/root/ConfigLoader")
	if loader != null and loader.has_method("get_int"):
		return (loader.call("get_int", key, fallback) as int)
	return fallback

# ── Interaction Rule Lookup ───────────────────────────────────────────

static func get_interaction_rule(attacker: ElementalTypes.Element, target: ElementalTypes.Element) -> ElementalInteractionRule:
	match attacker:
		ElementalTypes.Element.FIRE:
			if target == ElementalTypes.Element.OIL:
				return ElementalInteractionRule.new(attacker, target, _config_float("FIRE_OIL_MODIFIER", 2.0), true, false, ElementalTypes.Element.NONE, 0)

		ElementalTypes.Element.WIND:
			if target == ElementalTypes.Element.FIRE or target == ElementalTypes.Element.HAZARD_FIRE:
				return ElementalInteractionRule.new(attacker, target, _config_float("WIND_FIRE_MODIFIER", 1.5), false, true, ElementalTypes.Element.FIRE, _config_int("FIRE_DURATION_TURNS", 2))
			if target == ElementalTypes.Element.OIL or target == ElementalTypes.Element.HAZARD_OIL:
				return ElementalInteractionRule.new(attacker, target, 1.0, false, true, ElementalTypes.Element.NONE, 2)

		ElementalTypes.Element.WATER:
			if target == ElementalTypes.Element.FIRE:
				return ElementalInteractionRule.new(attacker, target, _config_float("WATER_FIRE_MODIFIER", 0.5), true, false, ElementalTypes.Element.NONE, 0)
			if target == ElementalTypes.Element.OIL:
				return ElementalInteractionRule.new(attacker, target, 0.0, false, false, ElementalTypes.Element.NONE, 0)
			if target == ElementalTypes.Element.HAZARD_FIRE:
				return ElementalInteractionRule.new(attacker, target, 0.0, true, false, ElementalTypes.Element.NONE, 0)

	return null

# ── Damage and Speed Multipliers ──────────────────────────────────────

## Returns the damage multiplier for an attack based on the target's elemental statuses.
## Resolves FIFO: uses the rule for the first (oldest) status that has an interaction.
static func compute_damage_multiplier(attacker_elem: ElementalTypes.Element, target_statuses: Array[ElementalStatus]) -> float:
	for status: ElementalStatus in target_statuses:
		var rule: ElementalInteractionRule = get_interaction_rule(attacker_elem, status.element)
		if rule != null:
			return rule.damage_multiplier
	return 1.0

## Returns movement speed multiplier (0.8x for Oil).
static func calculate_movement_speed_multiplier(entity_statuses: Array[ElementalStatus], tile_effects: Array[ElementalTypes.TileEffect], current_turn: int) -> float:
	for s: ElementalStatus in entity_statuses:
		if s.element == ElementalTypes.Element.OIL or s.element == ElementalTypes.Element.HAZARD_OIL:
			return _config_float("OIL_SLIP_SPEED_MULT", 0.8)
	for e: ElementalTypes.TileEffect in tile_effects:
		if not e.is_expired(current_turn):
			if e.element == ElementalTypes.Element.OIL or e.element == ElementalTypes.Element.HAZARD_OIL:
				return _config_float("OIL_SLIP_SPEED_MULT", 0.8)
	return 1.0

# ── Interaction Resolution ────────────────────────────────────────────

## Resolves an interaction and returns side effects (extinguish, spread, new status).
static func resolve_interaction(attacker_elem: ElementalTypes.Element, target_statuses: Array[ElementalStatus], current_turn: int) -> Dictionary:
	var result: Dictionary = {
		"damage_multiplier": 1.0,
		"extinguished": false,
		"spread": false,
		"spread_element": ElementalTypes.Element.NONE,
		"spread_duration": 0,
		"new_status": null
	}

	# FIFO: Find the oldest status that interacts with the attacker.
	var interact_idx: int = -1
	var interaction_rule: ElementalInteractionRule = null

	for i: int in range(target_statuses.size()):
		var rule: ElementalInteractionRule = get_interaction_rule(attacker_elem, target_statuses[i].element)
		if rule != null:
			interact_idx = i
			interaction_rule = rule
			break

	if interaction_rule != null:
		result["damage_multiplier"] = interaction_rule.damage_multiplier
		result["extinguished"] = interaction_rule.extinguish
		result["spread"] = interaction_rule.spread

		if result["spread"]:
			# If Wind interacts with Fire/HazardFire, spread Fire.
			# If Wind interacts with Oil/HazardOil, spread Oil (implied by Wind+Oil spread: Yes).
			var target_elem: ElementalTypes.Element = target_statuses[interact_idx].element
			if target_elem == ElementalTypes.Element.FIRE or target_elem == ElementalTypes.Element.HAZARD_FIRE:
				result["spread_element"] = ElementalTypes.Element.FIRE
			elif target_elem == ElementalTypes.Element.OIL or target_elem == ElementalTypes.Element.HAZARD_OIL:
				result["spread_element"] = ElementalTypes.Element.OIL
			result["spread_duration"] = interaction_rule.result_duration

		if result["extinguished"]:
			target_statuses.remove_at(interact_idx)

		if interaction_rule.result_status != ElementalTypes.Element.NONE:
			var ns: ElementalStatus = ElementalStatus.new(interaction_rule.result_status, interaction_rule.result_duration, current_turn)
			target_statuses.append(ns)
			result["new_status"] = ns

	return result

# ── Spread Logic ──────────────────────────────────────────────────────

## Returns adjacent cardinal tile positions for spread, blocked by heavy cover or unwalkable tiles.
static func get_spread_targets(source_pos: Vector2i, grid: Node) -> PackedVector2Array:
	var targets: PackedVector2Array = PackedVector2Array()
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for d: Vector2i in dirs:
		var cand: Vector2i = source_pos + d
		if grid.has_method("is_in_bounds") and grid.call("is_in_bounds", cand.x, cand.y):
			var tile: RefCounted = grid.call("get_tile", cand.x, cand.y) as RefCounted
			if tile:
				var is_blocked: bool = bool(tile.call("is_blocked")) if tile.has_method("is_blocked") else (bool(tile.get("blocks_movement")) if "blocks_movement" in tile else false)
				var is_heavy: bool = bool(tile.call("is_heavy_cover")) if tile.has_method("is_heavy_cover") else (int(tile.get("cover")) == 2)

				if not is_blocked and not is_heavy:
					targets.append(Vector2(cand.x, cand.y))

	return targets

# ── Compatibility Layer (to keep existing tests passing) ──────────────

static func apply_element(effects: Array[ElementalTypes.TileEffect], elem: ElementalTypes.Element, current_turn: int, duration: int = 1, source_pos: Vector2i = Vector2i(-999, -999)) -> Array[ElementalTypes.TileEffect]:
	var new_effect: ElementalTypes.TileEffect = ElementalTypes.TileEffect.new(elem, duration, current_turn, source_pos)
	var out: Array[ElementalTypes.TileEffect] = effects.duplicate()
	out.append(new_effect)
	return out

static func _filter_active(effects: Array[ElementalTypes.TileEffect], current_turn: int) -> Array[ElementalTypes.TileEffect]:
	var out: Array[ElementalTypes.TileEffect] = []
	for e: ElementalTypes.TileEffect in effects:
		if not e.is_expired(current_turn):
			out.append(e)
	return out

static func compute_tile_damage_multiplier(effects: Array[ElementalTypes.TileEffect], current_turn: int) -> float:
	var active: Array[ElementalTypes.TileEffect] = _filter_active(effects, current_turn)
	if active.is_empty(): return 1.0

	var has_fire: bool = false
	var has_water: bool = false
	var has_wind: bool = false
	var has_oil: bool = false
	for e: ElementalTypes.TileEffect in active:
		match e.element:
			ElementalTypes.Element.FIRE: has_fire = true
			ElementalTypes.Element.WATER: has_water = true
			ElementalTypes.Element.WIND: has_wind = true
			ElementalTypes.Element.OIL: has_oil = true

	if has_water and has_fire: return _config_float("WATER_FIRE_MODIFIER", 0.5)
	if has_wind and has_fire: return _config_float("WIND_FIRE_MODIFIER", 1.5)
	if has_fire and has_oil: return _config_float("FIRE_OIL_MODIFIER", 2.0)
	return 1.0

static func process_turn_tick(effects: Array[ElementalTypes.TileEffect], current_turn: int, tile_pos: Vector2i, grid: Node = null, grid_bounds: Array[Vector2i] = [], water_tiles: Array[Vector2i] = []) -> Dictionary:
	var working: Array[ElementalTypes.TileEffect] = _filter_active(effects, current_turn)

	var extinguished: bool = false
	var spread_positions: PackedVector2Array = PackedVector2Array()

	var i: int = 0
	while i < working.size():
		var current: ElementalTypes.TileEffect = working[i]
		match current.element:
			ElementalTypes.Element.WATER:
				var fire_idx: int = _find_leftmost_element(working, ElementalTypes.Element.FIRE)
				if fire_idx != -1:
					working.remove_at(max(i, fire_idx))
					working.remove_at(min(i, fire_idx))
					extinguished = true
					i = -1 # Restart FIFO scan
			ElementalTypes.Element.WIND:
				var fire_idx: int = _find_leftmost_element(working, ElementalTypes.Element.FIRE)
				if fire_idx != -1:
					# Wind fans fire -> Spread
					if grid != null:
						spread_positions.append_array(get_spread_targets(tile_pos, grid))
					else:
						spread_positions.append_array(compute_fire_spread_targets(tile_pos, grid_bounds, water_tiles))
					working.remove_at(i)
					i = -1
			ElementalTypes.Element.FIRE:
				var oil_idx: int = _find_leftmost_element(working, ElementalTypes.Element.OIL)
				if oil_idx != -1:
					# Fire burns off Oil
					working.remove_at(oil_idx)
					if oil_idx < i:
						i -= 1
					# Refresh fire duration after consuming oil
					working[i].duration = _config_int("FIRE_OIL_DURATION_TURNS", 2)
					working[i].applied_turn = current_turn
		i += 1

	return {
		"effects": working,
		"spread_positions": spread_positions,
		"extinguished": extinguished,
	}

static func _find_leftmost_element(arr: Array[ElementalTypes.TileEffect], elem: ElementalTypes.Element) -> int:
	for i: int in range(arr.size()):
		if arr[i].element == elem:
			return i
	return -1

static func compute_fire_spread_targets(fire_pos: Vector2i, grid_bounds: Array[Vector2i], water_tiles: Array[Vector2i] = []) -> PackedVector2Array:
	var targets: PackedVector2Array = PackedVector2Array()
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d: Vector2i in dirs:
		var cand: Vector2i = fire_pos + d
		if not grid_bounds.is_empty():
			var min_b: Vector2i = grid_bounds[0]
			var max_b: Vector2i = grid_bounds[1]
			if cand.x >= min_b.x and cand.x <= max_b.x and cand.y >= min_b.y and cand.y <= max_b.y:
				if not cand in water_tiles:
					targets.append(Vector2(cand.x, cand.y))
	return targets

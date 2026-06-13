class_name CombatFormula
## Tier-1 damage formula, position modifiers, and elemental interactions.
## Fully deterministic — no randomness, no platform-dependent float quirks.
## All intermediate results use explicit typing to prevent GDScript
## dynamic-type drift.
##
## Reference: system-specification-core.md §2, §3.


# ── Damage Formula §2.1 ───────────────────────────────────────────
static func compute_damage(
	attacker_off: int,
	defender_def: int,
	position_modifier: float,
	elemental_modifier: float,
	memory_synergy: float
) -> int:
	## DAMAGE_DEALT = ⌊ (D_BASE + OFF – DEF) × POSITION_MODIFIER
	##                  × ELEMENTAL_MODIFIER × (1 + MEMORY_SYNERGY) ⌋
	##
	## Parameters:
	##   attacker_off — attacker’s offence stat
	##   defender_def — defender’s defence stat
	##   position_modifier — float ∈ [0.5, 1.5]
	##   elemental_modifier — float (default 1.0)
	##   memory_synergy — float ∈ [0.0, 0.30] (default 0.0)
	##
	## Returns: integer damage ≥ 1 (guaranteed attrition)

	var base: int = GameConstants.D_BASE + attacker_off - defender_def
	# Edge case: OFF < DEF still yields at least 1 after final floor
	# because damage_floor clamps to 1.

	var raw: float = float(base)
	raw *= position_modifier
	raw *= elemental_modifier
	raw *= (1.0 + memory_synergy)

	return DeterministicMath.damage_floor(raw)


static func compute_damage_from_entities(
	attacker: Entity,
	defender: Entity,
	cover_tiles: Array[Vector2i],
	elemental_modifier: float = 1.0,
	memory_synergy: float = 0.0
) -> int:
	## Convenience overload: derive OFF/DEF from entity stat blocks
	## and compute position modifier automatically.
	var pos_mod: float = calculate_position_modifier(attacker, defender, cover_tiles)
	return compute_damage(attacker.off, defender.def_, pos_mod, elemental_modifier, memory_synergy)


# ── Position Modifier §3.3 ────────────────────────────────────────
static func calculate_position_modifier(
	attacker: Entity, defender: Entity, cover_tiles: Array[Vector2i]
) -> float:
	## POSITION_MODIFIER = 1.0
	##   + BACKSTAB_BONUS    (if attacker behind defender)
	##   + ELEVATION_BONUS   (if attacker > defender elevation)
	##   + COVER_PENALTY     (if defender in cover)
	##
	## Final clamp: [0.5, 1.5]

	var modifier: float = 1.0

	# ── Backstab ──
	if _is_backstab(attacker, defender):
		modifier += GameConstants.BACKSTAB_BONUS

	# ── Elevation ──
	var elev_diff: int = attacker.elevation - defender.elevation
	if elev_diff >= 2:
		modifier += GameConstants.ELEVATION_BONUS_TIER_2
	elif elev_diff >= 1:
		modifier += GameConstants.ELEVATION_BONUS_TIER_1
	elif elev_diff <= -2:
		modifier -= GameConstants.ELEVATION_BONUS_TIER_2
	elif elev_diff <= -1:
		modifier -= GameConstants.ELEVATION_BONUS_TIER_1

	# ── Cover ──
	var cover_penalty: float = _calculate_cover_penalty(defender, cover_tiles)
	modifier -= cover_penalty

	return DeterministicMath.clampf(
		modifier, GameConstants.POSITION_MODIFIER_MIN, GameConstants.POSITION_MODIFIER_MAX
	)


static func _direction(from_x: int, from_y: int, to_x: int, to_y: int) -> Vector2i:
	## Cardinal-normalised direction vector from (from_x, from_y) to (to_x, to_y).
	## Exact mirror of prototype direction() in core_mechanic_prototype.py.
	var dx: int = to_x - from_x
	var dy: int = to_y - from_y
	if DeterministicMath.absi(dx) >= DeterministicMath.absi(dy):
		return Vector2i(DeterministicMath.sgn(float(dx)), 0)
	return Vector2i(0, DeterministicMath.sgn(float(dy)))


static func _is_backstab(attacker: Entity, defender: Entity) -> bool:
	## Backstab: dot product of attacker→defender vector with defender
	## facing vector < –0.7.
	##
	## NOTE: this uses the prototype's direction() semantics (vector FROM
	## attacker TO defender), matching test_core_mechanic.py exactly.
	var atk_vec: Vector2i = _direction(attacker.x, attacker.y, defender.x, defender.y)
	var def_facing: Vector2i = Vector2i(defender.facing_x, defender.facing_y)
	var dot: float = float(atk_vec.x * def_facing.x + atk_vec.y * def_facing.y)
	return dot < -0.7


static func _calculate_cover_penalty(defender: Entity, cover_tiles: Array[Vector2i]) -> float:
	## Light cover: defender tile is in cover_tiles → –0.15.
	## Heavy cover: defender tile in cover_tiles AND adjacent to another
	## cover tile → –0.30.
	##
	## We use TileMap-style integer coordinates; cover_tiles holds
	## Vector2i positions.
	var defender_pos := Vector2i(defender.x, defender.y)
	if defender_pos not in cover_tiles:
		return 0.0

	# Check adjacent tiles for heavy cover
	var directions: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	for d: Vector2i in directions:
		if (defender_pos + d) in cover_tiles:
			return GameConstants.HEAVY_COVER_PENALTY
	return GameConstants.LIGHT_COVER_PENALTY


# ── Elemental Modifiers §2.3 ──────────────────────────────────────
static func elemental_modifier(interaction_type: String) -> float:
	## Returns the deterministic modifier for a known elemental interaction.
	## No random procs; all states are deliberate consequences.
	match interaction_type:
		"fire_to_oil":
			return GameConstants.ELEM_FIRE_TO_OIL
		"wind_to_fire":
			return GameConstants.ELEM_WIND_TO_FIRE
		"oil_slip":
			return GameConstants.ELEM_OIL_SLIP_SPEED
		"water_to_fire":
			return GameConstants.ELEM_WATER_TO_FIRE
		_:
			return 1.0


# ── Memory Synergy ──────────────────────────────────────────────────
static func clamp_memory_synergy(value: float) -> float:
	## §2.1: MEMORY_SYNERGY scalar capped at +0.30.
	return DeterministicMath.clampf(value, 0.0, GameConstants.MEMORY_SYNERGY_MAX)


# ── Action Cost Look-Up §3.2 ──────────────────────────────────────
static func action_cost(action_type: String) -> int:
	## Returns AP cost for standard actions.
	## Ranged and ability costs are parameterized elsewhere.
	match action_type:
		"move_cardinal":
			return 1
		"move_diagonal":
			return 2
		"attack_basic":
			return 2
		"attack_ranged_1":
			return 2
		"attack_ranged_2":
			return 3
		"attack_ranged_3":
			return 4
		"ability_min":
			return AutoloadHelper.config_int("ability_min", GameConstants.ABILITY_MIN_COST)
		"ability_max":
			return AutoloadHelper.config_int("ability_max", GameConstants.ABILITY_MAX_COST)
		"interact":
			return 1
		"end_turn":
			return 0
		_:
			return 0

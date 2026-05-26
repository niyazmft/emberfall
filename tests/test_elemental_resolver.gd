extends SceneTree
## Unit / integration tests for Elemental Interaction Resolver (DON-101 B3).
##
## Acceptance Criteria:
##   AC-1: Fire + Oil interaction produces 2.0× damage modifier
##   AC-2: Wind applied to Fire produces 1.5× modifier and spread behaviour
##   AC-3: Water applied to Fire produces 0.5× modifier and extinguishes
##   AC-4: Oil slip terrain effect produces 0.8× movement speed debuff
##   AC-5: Duration tracking and deterministic modifier application
##   AC-6: Combo chains resolve in correct order (FIFO)
##   AC-7: Edge cases (multiple overlapping elements) handled gracefully
##
## Run via: godot --headless --path . -s tests/test_elemental_resolver.gd

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	run_all()
	quit(0 if _failed == 0 else 1)


func run_all() -> void:
	print("\n=== EMBERFALL ELEMENTAL RESOLVER TESTS ===\n")

	var tests: Array[String] = [
		"test_fire_oil_modifier",
		"test_wind_fire_modifier",
		"test_water_fire_modifier",
		"test_oil_slip_speed",
		"test_no_elements_default",
		"test_duration_tracking_expiry",
		"test_fifo_water_before_fire",
		"test_fifo_fire_then_oil_then_wind",
		"test_fire_spread_basic",
		"test_spread_blocked_by_water",
		"test_out_of_bounds_spread_rejected",
		"test_multiple_overlapping_elements",
		"test_oil_burns_off_completely",
		"test_extinguish_bidirectional",
		"test_stacked_elements_tick_independently",
		"test_empty_effects_safe",
		"test_turn_tick_idempotent",
	]

	for name: String in tests:
		print("Running %s ..." % name)
		call(name)


	print("\n=== RESULTS ===")
	print("Passed: %d" % _passed)
	print("Failed: %d" % _failed)

	if _failed > 0:
		push_error("ELEMENTAL RESOLVER TESTS FAILED")


# ── AC-1: Fire↔Oil = 2.0× ──────────────────────────────────────────────
func test_fire_oil_modifier() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.OIL, 0, 2)

	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	_assert_eqf("fire_oil_damage_mult", mult, 2.0)


# ── AC-2: Wind→Fire = 1.5× ─────────────────────────────────────────────
func test_wind_fire_modifier() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.WIND, 0, 2)

	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	_assert_eqf("wind_fire_damage_mult", mult, 1.5)


# ── AC-3: Water→Fire = 0.5× and extinguish ───────────────────────────
func test_water_fire_modifier() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.WATER, 0, 2)

	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	_assert_eqf("water_fire_damage_mult", mult, 0.5)


# ── AC-4: Oil slip = 0.8× speed ────────────────────────────────────────
func test_oil_slip_speed() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.OIL, 0, 2)

	var speed: float = ElementalInteractionResolver.calculate_movement_speed_multiplier([], effects, 0)
	_assert_eqf("oil_slip_speed", speed, 0.8)


# ── Default: no elements = 1.0× ────────────────────────────────────────
func test_no_elements_default() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	var dmg: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	var spd: float = ElementalInteractionResolver.calculate_movement_speed_multiplier([], effects, 0)
	_assert_eqf("no_elem_damage", dmg, 1.0)
	_assert_eqf("no_elem_speed", spd, 1.0)


# ── AC-5: Duration tracking and expiry ────────────────────────────────
func test_duration_tracking_expiry() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 1)

	# Turn 0: still active (applied_turn 0 + duration 1 = 1; current_turn 0 ≤ 1)
	var active_turn0: Array[ElementalTypes.TileEffect] = ElementalInteractionResolver._filter_active(effects, 0)
	_assert_eq("duration_active_turn0", active_turn0.size(), 1)

	# Turn 1: expired (current_turn 1 > 0 + 1)
	var active_turn1: Array[ElementalTypes.TileEffect] = ElementalInteractionResolver._filter_active(effects, 2)
	_assert_eq("duration_expired_turn2", active_turn1.size(), 0)


# ── AC-6: FIFO — Water applied before Fire should still extinguish ───
func test_fifo_water_before_fire() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	# Water first (older), Fire second (newer)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.WATER, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 2)

	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(effects, 0, Vector2i(0, 0), null)
	var out_effects: Array[ElementalTypes.TileEffect] = result["effects"]
	var extinguished: bool = result["extinguished"]

	_assert_true("fifo_water_then_fire_extinguished", extinguished)
	_assert_eq("fifo_water_then_fire_no_fire_left", _count_element(out_effects, ElementalTypes.Element.FIRE), 0)
	_assert_eq("fifo_water_then_fire_no_water_left", _count_element(out_effects, ElementalTypes.Element.WATER), 0)


# ── AC-6: FIFO chain — Fire → Oil → Wind ─────────────────────────────
func test_fifo_fire_then_oil_then_wind() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.OIL, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.WIND, 0, 2)

	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(effects, 0, Vector2i(1, 1), null)
	var out_effects: Array[ElementalTypes.TileEffect] = result["effects"]

	# Fire first, then Oil: Fire consumes Oil in FIFO; then Wind fans Fire
	# and is consumed by the interaction (wind does not persist after fanning).
	_assert_eq("fifo_chain_oil_burned", _count_element(out_effects, ElementalTypes.Element.OIL), 0)
	# Fire should remain after burning oil and being fanned
	_assert_eq("fifo_chain_fire_remains", _count_element(out_effects, ElementalTypes.Element.FIRE), 1)
	# Wind is consumed when it fans fire (it does not persist)
	_assert_eq("fifo_chain_wind_consumed", _count_element(out_effects, ElementalTypes.Element.WIND), 0)


# ── AC-2: Fire spread basic ────────────────────────────────────────────
func test_fire_spread_basic() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.WIND, 0, 2)

	var bounds: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 2)]
	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(effects, 0, Vector2i(1, 1), null, bounds)
	var spread: PackedVector2Array = result["spread_positions"]

	# From (1,1) with wind fanning fire, spread to 4 adjacent cardinal tiles
	_assert_eq("spread_count", spread.size(), 4)
	_assert_true("spread_has_0_1", spread.has(Vector2(0, 1)))
	_assert_true("spread_has_2_1", spread.has(Vector2(2, 1)))
	_assert_true("spread_has_1_0", spread.has(Vector2(1, 0)))
	_assert_true("spread_has_1_2", spread.has(Vector2(1, 2)))


# ── AC-7: Spread blocked by water tiles ───────────────────────────────
func test_spread_blocked_by_water() -> void:
	var fire_pos := Vector2i(1, 1)
	var bounds: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 2)]
	var water_tiles: Array[Vector2i] = [Vector2i(2, 1), Vector2i(1, 0)]

	var targets: PackedVector2Array = ElementalInteractionResolver.compute_fire_spread_targets(fire_pos, bounds, water_tiles)

	_assert_eq("spread_blocked_count", targets.size(), 2)
	_assert_true("spread_blocked_has_0_1", targets.has(Vector2(0, 1)))
	_assert_true("spread_blocked_has_1_2", targets.has(Vector2(1, 2)))
	_assert_false("spread_blocked_no_2_1", targets.has(Vector2(2, 1)))
	_assert_false("spread_blocked_no_1_0", targets.has(Vector2(1, 0)))


# ── AC-7: Out-of-bounds spread rejected ────────────────────────────────
func test_out_of_bounds_spread_rejected() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.WIND, 0, 2)

	# Tile at (0,0) with bounds [0,0] to [0,0] — no room to spread
	var bounds: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0)]
	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(effects, 0, Vector2i(0, 0), null, bounds)
	var spread: PackedVector2Array = result["spread_positions"]

	_assert_eq("oob_spread_count", spread.size(), 0)


# ── AC-7: Multiple overlapping elements ───────────────────────────────
func test_multiple_overlapping_elements() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.OIL, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.WATER, 0, 2)

	# Water extinguishes Fire first (priority 1); Oil remains
	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	_assert_eqf("multiple_water_priority", mult, 0.5)

	# Process tick: Fire (oldest) burns Oil first; Water then extinguishes Fire.
	# Per FIFO ordering, Oil is consumed by Fire before Water gets to act.
	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(effects, 0, Vector2i(0, 0), null)
	var out: Array[ElementalTypes.TileEffect] = result["effects"]
	_assert_eq("multiple_after_tick_fire_gone", _count_element(out, ElementalTypes.Element.FIRE), 0)
	_assert_eq("multiple_after_tick_water_gone", _count_element(out, ElementalTypes.Element.WATER), 0)
	_assert_eq("multiple_after_tick_oil_gone", _count_element(out, ElementalTypes.Element.OIL), 0)
	_assert_true("multiple_after_tick_all_consumed", out.is_empty())


# ── AC-7: Oil burns off completely ────────────────────────────────────
func test_oil_burns_off_completely() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.OIL, 0, 3)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 3)

	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(effects, 0, Vector2i(0, 0), null)
	var out: Array[ElementalTypes.TileEffect] = result["effects"]

	# Oil is consumed entirely by Fire in FIFO
	_assert_eq("oil_burns_off", _count_element(out, ElementalTypes.Element.OIL), 0)
	_assert_eq("oil_burns_fire_remains", _count_element(out, ElementalTypes.Element.FIRE), 1)


# ── AC-7: Extinguish works bidirectionally ─────────────────────────────
func test_extinguish_bidirectional() -> void:
	# Case A: Fire first, then Water
	var effects_a: Array[ElementalTypes.TileEffect] = []
	effects_a = ElementalInteractionResolver.apply_element(effects_a, ElementalTypes.Element.FIRE, 0, 2)
	effects_a = ElementalInteractionResolver.apply_element(effects_a, ElementalTypes.Element.WATER, 0, 2)

	var result_a: Dictionary = ElementalInteractionResolver.process_turn_tick(effects_a, 0, Vector2i(0, 0), null)
	_assert_true("extinguish_fire_then_water", result_a["extinguished"])
	_assert_eq("extinguish_fire_then_water_fire_gone", _count_element(result_a["effects"], ElementalTypes.Element.FIRE), 0)

	# Case B: Water first, then Fire
	var effects_b: Array[ElementalTypes.TileEffect] = []
	effects_b = ElementalInteractionResolver.apply_element(effects_b, ElementalTypes.Element.WATER, 0, 2)
	effects_b = ElementalInteractionResolver.apply_element(effects_b, ElementalTypes.Element.FIRE, 0, 2)

	var result_b: Dictionary = ElementalInteractionResolver.process_turn_tick(effects_b, 0, Vector2i(0, 0), null)
	_assert_true("extinguish_water_then_fire", result_b["extinguished"])
	_assert_eq("extinguish_water_then_fire_fire_gone", _count_element(result_b["effects"], ElementalTypes.Element.FIRE), 0)


# ── AC-5: Stacked elements tick independently ───────────────────────────
func test_stacked_elements_tick_independently() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 1)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 1, 1)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.OIL, 0, 3)

	# Turn 1: first Fire expires (applied 0 + duration 1 = 1; current_turn 1 > 1? No, 1 > 1 is false)
	# Wait: is_expired returns current_turn > applied_turn + duration
	# applied_turn 0, duration 1: expired when current_turn > 1, so turn 2+

	var active_t1: Array[ElementalTypes.TileEffect] = ElementalInteractionResolver._filter_active(effects, 1)
	_assert_eq("stack_t1_count", active_t1.size(), 3)

	var active_t2: Array[ElementalTypes.TileEffect] = ElementalInteractionResolver._filter_active(effects, 2)
	# Fire1 expired, Fire2 and Oil remain
	_assert_eq("stack_t2_count", active_t2.size(), 2)

	var active_t3: Array[ElementalTypes.TileEffect] = ElementalInteractionResolver._filter_active(effects, 3)
	# Fire2 expired, Oil remains
	_assert_eq("stack_t3_count", active_t3.size(), 1)
	_assert_eq("stack_t3_is_oil", active_t3[0].element, ElementalTypes.Element.OIL)


# ── AC-7: Empty effects safe ──────────────────────────────────────────
func test_empty_effects_safe() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	var spd: float = ElementalInteractionResolver.calculate_movement_speed_multiplier([], effects, 0)
	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(effects, 0, Vector2i(0, 0), null)
	_assert_eqf("empty_damage", mult, 1.0)
	_assert_eqf("empty_speed", spd, 1.0)
	_assert_eq("empty_effects", result["effects"].size(), 0)
	_assert_eq("empty_spread", result["spread_positions"].size(), 0)
	_assert_false("empty_extinguished", result["extinguished"])


# ── AC-5: Turn tick idempotent ─────────────────────────────────────────
func test_turn_tick_idempotent() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.FIRE, 0, 2)
	effects = ElementalInteractionResolver.apply_element(effects, ElementalTypes.Element.OIL, 0, 2)

	var result1: Dictionary = ElementalInteractionResolver.process_turn_tick(effects, 0, Vector2i(0, 0), null)
	var result2: Dictionary = ElementalInteractionResolver.process_turn_tick(effects, 0, Vector2i(0, 0), null)

	# Same inputs should produce same outputs
	_assert_eq("idempotent_effect_count", result1["effects"].size(), result2["effects"].size())
	_assert_eq("idempotent_spread_count", result1["spread_positions"].size(), result2["spread_positions"].size())
	_assert_eq("idempotent_extinguished", result1["extinguished"], result2["extinguished"])


# ── Helper: count elements of a given type in effect list ────────────────
static func _count_element(effects: Array[ElementalTypes.TileEffect], elem: ElementalTypes.Element) -> int:
	var c: int = 0
	for e: ElementalTypes.TileEffect in effects:
		if e.element == elem:
			c += 1
	return c


# ── Assertions ────────────────────────────────────────────────────────────
func _assert_eq(name: String, a: int, b: int) -> void:
	if a == b:
		_passed += 1
		print("  PASS: %s" % name)
	else:
		_failed += 1
		var msg := "[FAIL] %s: expected %d, got %d" % [name, b, a]
		push_error(msg)
		print("  " + msg)


func _assert_eqf(name: String, a: float, b: float) -> void:
	if abs(a - b) < 0.001:
		_passed += 1
		print("  PASS: %s" % name)
	else:
		_failed += 1
		var msg := "[FAIL] %s: expected %.3f, got %.3f" % [name, b, a]
		push_error(msg)
		print("  " + msg)


func _assert_true(name: String, cond: bool) -> void:
	if cond:
		_passed += 1
		print("  PASS: %s" % name)
	else:
		_failed += 1
		var msg := "[FAIL] %s: expected true" % name
		push_error(msg)
		print("  " + msg)


func _assert_false(name: String, cond: bool) -> void:
	if not cond:
		_passed += 1
		print("  PASS: %s" % name)
	else:
		_failed += 1
		var msg := "[FAIL] %s: expected false" % name
		push_error(msg)
		print("  " + msg)

extends SceneTree
## Port of ElementalSystemValidation.cs to GDScript (DON-101).
## Validates interaction rules, FIFO ordering, spread, and oil slip.

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	run_all()
	quit(0 if _failed == 0 else 1)

func run_all() -> void:
	print("\n=== EMBERFALL ELEMENTAL SYSTEM VALIDATION ===\n")

	test_case_1_fire_oil_interaction()
	test_case_2_wind_fire_spread()
	test_case_3_water_fire_extinguish()
	test_case_4_water_oil_no_interaction()
	test_case_5_wind_oil_spread()
	test_case_6_water_hazard_fire()
	test_case_7_wind_hazard_oil()
	test_case_8_fifo_ordering()
	test_case_9_duration_tick()
	test_case_10_oil_slip_debuff()
	test_case_11_spread_blocked_by_cover()
	test_case_12_deterministic_resolution()

	print("\n=== RESULTS ===")
	print("Passed: %d" % _passed)
	print("Failed: %d" % _failed)

func test_case_1_fire_oil_interaction() -> void:
	# Fire vs Oil: 2.0x, Extinguish: Yes
	var queue: Array[ElementalStatus] = [ElementalStatus.new(ElementalTypes.Element.OIL, 3, 0)]
	var result: Dictionary = ElementalInteractionResolver.resolve_interaction(ElementalTypes.Element.FIRE, queue, 0)

	_assert_eqf("tc1_mult", result.damage_multiplier, 2.0)
	_assert_true("tc1_extinguish", result.extinguished)
	_assert_eq("tc1_queue_size", queue.size(), 0)

func test_case_2_wind_fire_spread() -> void:
	# Wind vs Fire: 1.5x, Spread: Yes, Result: Burning
	var queue: Array[ElementalStatus] = [ElementalStatus.new(ElementalTypes.Element.FIRE, 3, 0)]
	var result: Dictionary = ElementalInteractionResolver.resolve_interaction(ElementalTypes.Element.WIND, queue, 0)

	_assert_eqf("tc2_mult", result.damage_multiplier, 1.5)
	_assert_true("tc2_spread", result.spread)
	_assert_eq("tc2_spread_elem", result.spread_element, ElementalTypes.Element.FIRE)
	_assert_eq("tc2_new_status_elem", result.new_status.element, ElementalTypes.Element.FIRE)

func test_case_3_water_fire_extinguish() -> void:
	# Water vs Fire: 0.5x, Extinguish: Yes
	var queue: Array[ElementalStatus] = [ElementalStatus.new(ElementalTypes.Element.FIRE, 3, 0)]
	var result: Dictionary = ElementalInteractionResolver.resolve_interaction(ElementalTypes.Element.WATER, queue, 0)

	_assert_eqf("tc3_mult", result.damage_multiplier, 0.5)
	_assert_true("tc3_extinguish", result.extinguished)
	_assert_eq("tc3_queue_size", queue.size(), 0)

func test_case_4_water_oil_no_interaction() -> void:
	# Water vs Oil: 0.0x, Extinguish: No
	var queue: Array[ElementalStatus] = [ElementalStatus.new(ElementalTypes.Element.OIL, 3, 0)]
	var result: Dictionary = ElementalInteractionResolver.resolve_interaction(ElementalTypes.Element.WATER, queue, 0)

	_assert_eqf("tc4_mult", result.damage_multiplier, 0.0)
	_assert_false("tc4_extinguish", result.extinguished)
	_assert_eq("tc4_queue_size", queue.size(), 1)

func test_case_5_wind_oil_spread() -> void:
	# Wind vs Oil: 1.0x, Spread: Yes
	var queue: Array[ElementalStatus] = [ElementalStatus.new(ElementalTypes.Element.OIL, 3, 0)]
	var result: Dictionary = ElementalInteractionResolver.resolve_interaction(ElementalTypes.Element.WIND, queue, 0)

	_assert_eqf("tc5_mult", result.damage_multiplier, 1.0)
	_assert_true("tc5_spread", result.spread)
	_assert_eq("tc5_spread_elem", result.spread_element, ElementalTypes.Element.OIL)

func test_case_6_water_hazard_fire() -> void:
	# Water vs HazardFire: 0.0x, Extinguish: Yes
	var queue: Array[ElementalStatus] = [ElementalStatus.new(ElementalTypes.Element.HAZARD_FIRE, -1, 0)]
	var result: Dictionary = ElementalInteractionResolver.resolve_interaction(ElementalTypes.Element.WATER, queue, 0)

	_assert_eqf("tc6_mult", result.damage_multiplier, 0.0)
	_assert_true("tc6_extinguish", result.extinguished)

func test_case_7_wind_hazard_oil() -> void:
	# Wind vs HazardOil: 1.0x, Spread: Yes
	var queue: Array[ElementalStatus] = [ElementalStatus.new(ElementalTypes.Element.HAZARD_OIL, -1, 0)]
	var result: Dictionary = ElementalInteractionResolver.resolve_interaction(ElementalTypes.Element.WIND, queue, 0)

	_assert_eqf("tc7_mult", result.damage_multiplier, 1.0)
	_assert_true("tc7_spread", result.spread)
	_assert_eq("tc7_spread_elem", result.spread_element, ElementalTypes.Element.OIL)

func test_case_8_fifo_ordering() -> void:
	var queue: Array[ElementalStatus] = [
		ElementalStatus.new(ElementalTypes.Element.OIL, 3, 0),
		ElementalStatus.new(ElementalTypes.Element.FIRE, 3, 0)
	]
	var result: Dictionary = ElementalInteractionResolver.resolve_interaction(ElementalTypes.Element.WATER, queue, 0)

	_assert_eqf("tc8_mult", result.damage_multiplier, 0.0)
	_assert_false("tc8_extinguish", result.extinguished)
	_assert_eq("tc8_queue_size", queue.size(), 2)
	_assert_eq("tc8_oldest_remains", queue[0].element, ElementalTypes.Element.OIL)

func test_case_9_duration_tick() -> void:
	var queue: Array[ElementalStatus] = [
		ElementalStatus.new(ElementalTypes.Element.FIRE, 2, 0)
	]
	# (DON-101) tick down: 2 -> 1
	_assert_false("tc9_not_expired_t0", _ElementalComboQueue.tick(queue, 0))
	_assert_eq("tc9_dur1", queue[0].duration, 1)
	# 1 -> 0, removed
	_assert_true("tc9_expired_t1", _ElementalComboQueue.tick(queue, 1))
	_assert_eq("tc9_empty", queue.size(), 0)

func test_case_10_oil_slip_debuff() -> void:
	var entity_statuses: Array[ElementalStatus] = [ElementalStatus.new(ElementalTypes.Element.OIL, 3, 0)]
	var tile_effects: Array[ElementalTypes.TileEffect] = []
	var mult: float = ElementalInteractionResolver.calculate_movement_speed_multiplier(entity_statuses, tile_effects, 0)
	_assert_eqf("tc10_slip", mult, 0.8)

func test_case_11_spread_blocked_by_cover() -> void:
	var mock_grid: Node = Node.new()
	var script: GDScript = GDScript.new()
	script.source_code = "func is_in_bounds(x: int, y: int) -> bool: return true\nfunc get_tile(x: int, y: int) -> RefCounted:\n\tvar t: RefCounted = RefCounted.new()\n\tvar s = load('res://scripts/core/tile_data.gd').new()\n\tt.set_script(s.get_script())\n\tt.set('blocks_movement', false)\n\tt.set('cover', 0)\n\tif x == 1 and y == 0: t.set('cover', 2) # Heavy\n\treturn t"
	mock_grid.set_script(script)

	var targets: PackedVector2Array = ElementalInteractionResolver.get_spread_targets(Vector2i(0, 0), mock_grid)
	_assert_false("tc11_no_heavy", targets.has(Vector2(1, 0)))
	_assert_true("tc11_has_others", targets.has(Vector2(0, 1)))
	mock_grid.free()

func test_case_12_deterministic_resolution() -> void:
	var queue1: Array[ElementalStatus] = [ElementalStatus.new(ElementalTypes.Element.FIRE, 3, 0)]
	var queue2: Array[ElementalStatus] = [ElementalStatus.new(ElementalTypes.Element.FIRE, 3, 0)]

	var res1: Dictionary = ElementalInteractionResolver.resolve_interaction(ElementalTypes.Element.WIND, queue1, 0)
	var res2: Dictionary = ElementalInteractionResolver.resolve_interaction(ElementalTypes.Element.WIND, queue2, 0)

	_assert_eqf("tc12_mult_match", res1.damage_multiplier, res2.damage_multiplier)
	_assert_eq("tc12_spread_match", res1.spread, res2.spread)

# --- Helpers ---

func _assert_eq(name: String, a: Variant, b: Variant) -> void:
	if a == b:
		_passed += 1
	else:
		_failed += 1
		print("[FAIL] %s: expected %s, got %s" % [name, str(b), str(a)])

func _assert_eqf(name: String, a: float, b: float) -> void:
	if abs(a - b) < 0.0001:
		_passed += 1
	else:
		_failed += 1
		print("[FAIL] %s: expected %f, got %f" % [name, b, a])

func _assert_true(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("[FAIL] %s: expected true" % name)

func _assert_false(name: String, condition: bool) -> void:
	if not condition:
		_passed += 1
	else:
		_failed += 1
		print("[FAIL] %s: expected false" % name)

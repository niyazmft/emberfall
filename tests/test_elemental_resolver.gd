extends GdUnitTestSuite


func test_fire_oil_modifier() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.OIL, 0, 2
	)

	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	assert_that(is_equal_approx(mult, 2.0)).is_true()


func test_wind_fire_modifier() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.WIND, 0, 2
	)

	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	assert_that(is_equal_approx(mult, 1.5)).is_true()


func test_water_fire_modifier() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.WATER, 0, 2
	)

	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	assert_that(is_equal_approx(mult, 0.5)).is_true()


func test_oil_slip_speed() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.OIL, 0, 2
	)

	var speed: float = ElementalInteractionResolver.calculate_movement_speed_multiplier(effects, 0)
	assert_that(is_equal_approx(speed, 0.8)).is_true()


func test_no_elements_default() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	var dmg: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	var spd: float = ElementalInteractionResolver.calculate_movement_speed_multiplier(effects, 0)
	assert_that(is_equal_approx(dmg, 1.0)).is_true()
	assert_that(is_equal_approx(spd, 1.0)).is_true()


func test_duration_tracking_expiry() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 1
	)

	var active_turn0: Array[ElementalTypes.TileEffect] = (
		ElementalInteractionResolver._filter_active(effects, 0)
	)
	assert_that(active_turn0.size()).is_equal(1)

	var active_turn1: Array[ElementalTypes.TileEffect] = (
		ElementalInteractionResolver._filter_active(effects, 2)
	)
	assert_that(active_turn1.size()).is_equal(0)


func test_fifo_water_before_fire() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.WATER, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 2
	)

	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects, 0, Vector2i(0, 0), []
	)
	var out_effects: Array[ElementalTypes.TileEffect] = result["effects"]
	var extinguished: bool = result["extinguished"]

	assert_that(extinguished).is_true()
	assert_that(_count_element(out_effects, ElementalTypes.ElementType.FIRE)).is_equal(0)
	assert_that(_count_element(out_effects, ElementalTypes.ElementType.WATER)).is_equal(0)


func test_fifo_fire_then_oil_then_wind() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.OIL, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.WIND, 0, 2
	)

	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects, 0, Vector2i(1, 1), []
	)
	var out_effects: Array[ElementalTypes.TileEffect] = result["effects"]

	assert_that(_count_element(out_effects, ElementalTypes.ElementType.OIL)).is_equal(0)
	assert_that(_count_element(out_effects, ElementalTypes.ElementType.FIRE)).is_equal(1)
	assert_that(_count_element(out_effects, ElementalTypes.ElementType.WIND)).is_equal(0)


func test_fire_spread_basic() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.WIND, 0, 2
	)

	var bounds: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 2)]
	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects, 0, Vector2i(1, 1), bounds
	)
	var spread: Array[Vector2i] = result["spread_positions"]

	assert_that(spread.size()).is_equal(4)
	assert_that(spread.has(Vector2i(0, 1))).is_true()
	assert_that(spread.has(Vector2i(2, 1))).is_true()
	assert_that(spread.has(Vector2i(1, 0))).is_true()
	assert_that(spread.has(Vector2i(1, 2))).is_true()


func test_spread_blocked_by_water() -> void:
	var fire_pos := Vector2i(1, 1)
	var bounds: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 2)]
	var water_tiles: Array[Vector2i] = [Vector2i(2, 1), Vector2i(1, 0)]

	var targets: Array[Vector2i] = ElementalInteractionResolver.compute_fire_spread_targets(
		fire_pos, bounds, water_tiles
	)

	assert_that(targets.size()).is_equal(2)
	assert_that(targets.has(Vector2i(0, 1))).is_true()
	assert_that(targets.has(Vector2i(1, 2))).is_true()
	assert_that(targets.has(Vector2i(2, 1))).is_false()
	assert_that(targets.has(Vector2i(1, 0))).is_false()


func test_out_of_bounds_spread_rejected() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.WIND, 0, 2
	)

	var bounds: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0)]
	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects, 0, Vector2i(0, 0), bounds
	)
	var spread: Array[Vector2i] = result["spread_positions"]

	assert_that(spread.size()).is_equal(0)


func test_multiple_overlapping_elements() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.OIL, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.WATER, 0, 2
	)

	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	assert_that(is_equal_approx(mult, 0.5)).is_true()

	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects, 0, Vector2i(0, 0), []
	)
	var out: Array[ElementalTypes.TileEffect] = result["effects"]
	assert_that(_count_element(out, ElementalTypes.ElementType.FIRE)).is_equal(0)
	assert_that(_count_element(out, ElementalTypes.ElementType.WATER)).is_equal(0)
	assert_that(_count_element(out, ElementalTypes.ElementType.OIL)).is_equal(0)
	assert_that(out.is_empty()).is_true()


func test_oil_burns_off_completely() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.OIL, 0, 3
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 3
	)

	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects, 0, Vector2i(0, 0), []
	)
	var out: Array[ElementalTypes.TileEffect] = result["effects"]

	assert_that(_count_element(out, ElementalTypes.ElementType.OIL)).is_equal(0)
	assert_that(_count_element(out, ElementalTypes.ElementType.FIRE)).is_equal(1)


func test_extinguish_bidirectional() -> void:
	var effects_a: Array[ElementalTypes.TileEffect] = []
	effects_a = ElementalInteractionResolver.apply_element(
		effects_a, ElementalTypes.ElementType.FIRE, 0, 2
	)
	effects_a = ElementalInteractionResolver.apply_element(
		effects_a, ElementalTypes.ElementType.WATER, 0, 2
	)

	var result_a: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects_a, 0, Vector2i(0, 0), []
	)
	assert_that(result_a["extinguished"]).is_true()
	assert_that(_count_element(result_a["effects"], ElementalTypes.ElementType.FIRE)).is_equal(0)

	var effects_b: Array[ElementalTypes.TileEffect] = []
	effects_b = ElementalInteractionResolver.apply_element(
		effects_b, ElementalTypes.ElementType.WATER, 0, 2
	)
	effects_b = ElementalInteractionResolver.apply_element(
		effects_b, ElementalTypes.ElementType.FIRE, 0, 2
	)

	var result_b: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects_b, 0, Vector2i(0, 0), []
	)
	assert_that(result_b["extinguished"]).is_true()
	assert_that(_count_element(result_b["effects"], ElementalTypes.ElementType.FIRE)).is_equal(0)


func test_stacked_elements_tick_independently() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 1
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 1, 1
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.OIL, 0, 3
	)

	var active_t1: Array[ElementalTypes.TileEffect] = ElementalInteractionResolver._filter_active(
		effects, 1
	)
	assert_that(active_t1.size()).is_equal(3)

	var active_t2: Array[ElementalTypes.TileEffect] = ElementalInteractionResolver._filter_active(
		effects, 2
	)
	assert_that(active_t2.size()).is_equal(2)

	var active_t3: Array[ElementalTypes.TileEffect] = ElementalInteractionResolver._filter_active(
		effects, 3
	)
	assert_that(active_t3.size()).is_equal(1)
	assert_that(active_t3[0].element).is_equal(ElementalTypes.ElementType.OIL)


func test_empty_effects_safe() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	var spd: float = ElementalInteractionResolver.calculate_movement_speed_multiplier(effects, 0)
	var result: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects, 0, Vector2i(0, 0), []
	)
	assert_that(is_equal_approx(mult, 1.0)).is_true()
	assert_that(is_equal_approx(spd, 1.0)).is_true()
	assert_that(result["effects"].size()).is_equal(0)
	assert_that(result["spread_positions"].size()).is_equal(0)
	assert_that(result["extinguished"]).is_false()


func test_turn_tick_idempotent() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.FIRE, 0, 2
	)
	effects = ElementalInteractionResolver.apply_element(
		effects, ElementalTypes.ElementType.OIL, 0, 2
	)

	var result1: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects, 0, Vector2i(0, 0), []
	)
	var result2: Dictionary = ElementalInteractionResolver.process_turn_tick(
		effects, 0, Vector2i(0, 0), []
	)

	assert_that(result1["effects"].size()).is_equal(result2["effects"].size())
	assert_that(result1["spread_positions"].size()).is_equal(result2["spread_positions"].size())
	assert_that(result1["extinguished"]).is_equal(result2["extinguished"])


static func _count_element(
	effects: Array[ElementalTypes.TileEffect], elem: ElementalTypes.ElementType
) -> int:
	var c: int = 0
	for e: ElementalTypes.TileEffect in effects:
		if e.element == elem:
			c += 1
	return c

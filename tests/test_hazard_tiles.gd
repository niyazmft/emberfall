extends GdUnitTestSuite


func test_room_standard_01_has_oil_hazards() -> void:
	var data: Dictionary = RoomLoader.load_room_data("room_standard_01")
	assert_dict(data).is_not_empty()
	assert_that(data.has("hazards")).is_true()

	var hazards: Array = data["hazards"] as Array
	assert_int(hazards.size()).is_equal(3)

	var oil_count: int = 0
	for h: Variant in hazards:
		if h is Dictionary and h.get("type", "") == "oil":
			oil_count += 1
	assert_int(oil_count).is_equal(3)


func test_room_standard_02_has_fire_hazards() -> void:
	var data: Dictionary = RoomLoader.load_room_data("room_standard_02")
	assert_dict(data).is_not_empty()
	assert_that(data.has("hazards")).is_true()

	var hazards: Array = data["hazards"] as Array
	assert_int(hazards.size()).is_equal(2)

	var fire_count: int = 0
	for h: Variant in hazards:
		if h is Dictionary and h.get("type", "") == "fire":
			fire_count += 1
	assert_int(fire_count).is_equal(2)


func test_room_standard_03_has_mixed_hazards() -> void:
	var data: Dictionary = RoomLoader.load_room_data("room_standard_03")
	assert_dict(data).is_not_empty()
	assert_that(data.has("hazards")).is_true()

	var hazards: Array = data["hazards"] as Array
	var oil_count: int = 0
	var fire_count: int = 0
	for h: Variant in hazards:
		if h is Dictionary:
			var t: String = h.get("type", "")
			if t == "oil":
				oil_count += 1
			elif t == "fire":
				fire_count += 1
	assert_int(oil_count).is_equal(2)
	assert_int(fire_count).is_equal(1)


func test_grid_system_applies_oil_tile() -> void:
	var gs: _GridSystem = GridSystem
	gs.load_room({"id": "oil_test"})
	gs.set_oil_tile(3, 3, true)

	assert_bool(gs.has_oil_tile(3, 3)).is_true()
	assert_bool(gs.is_slippery(3, 3)).is_true()
	assert_bool(gs.has_oil_tile(4, 4)).is_false()

	# Verify GridRenderer shows oil visual
	var renderer: GridRenderer = GridRenderer.new()
	add_child(renderer)
	await get_tree().process_frame

	var found_oil: bool = false
	for child: Node in renderer.get_children():
		if child is Sprite2D:
			var sprite: Sprite2D = child as Sprite2D
			# Oil sprite uses COLOR_OIL with alpha 0.6; compare RGB only
			if (
				is_equal_approx(sprite.modulate.r, GridRenderer.COLOR_OIL.r)
				and is_equal_approx(sprite.modulate.g, GridRenderer.COLOR_OIL.g)
				and is_equal_approx(sprite.modulate.b, GridRenderer.COLOR_OIL.b)
			):
				found_oil = true
				break

	assert_bool(found_oil).is_true()
	renderer.queue_free()
	await get_tree().process_frame


func test_fire_oil_combo_damage_multiplier() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	var fire_eff := ElementalTypes.TileEffect.new(
		ElementalTypes.ElementType.FIRE, 3, 0, Vector2i(0, 0)
	)
	var oil_eff := ElementalTypes.TileEffect.new(
		ElementalTypes.ElementType.OIL, 3, 0, Vector2i(0, 0)
	)
	effects.append(fire_eff)
	effects.append(oil_eff)

	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	# Fire + Oil combo should give 2.0× multiplier
	assert_float(mult).is_equal(2.0)


func test_oil_slip_speed_multiplier() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	var oil_eff := ElementalTypes.TileEffect.new(
		ElementalTypes.ElementType.OIL, 3, 0, Vector2i(0, 0)
	)
	effects.append(oil_eff)

	var speed_mult: float = ElementalInteractionResolver.calculate_movement_speed_multiplier(
		effects, 0
	)
	assert_float(speed_mult).is_equal(0.8)


func test_fire_tile_damage_modifier() -> void:
	var effects: Array[ElementalTypes.TileEffect] = []
	var fire_eff := ElementalTypes.TileEffect.new(
		ElementalTypes.ElementType.FIRE, 3, 0, Vector2i(0, 0)
	)
	effects.append(fire_eff)

	var mult: float = ElementalInteractionResolver.compute_tile_damage_multiplier(effects, 0)
	# Fire alone gives 1.0× (no combo)
	assert_float(mult).is_equal(1.0)

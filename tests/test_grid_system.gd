extends GdUnitTestSuite


func test_initialization() -> void:
	var gs: _GridSystem = GridSystem
	assert_int(gs.GRID_SIZE).is_equal(12)
	assert_int(gs.TOTAL_TILES).is_equal(144)

	var tiles: Array[TacTileData] = gs.all_tiles()
	assert_int(tiles.size()).is_equal(144)
	for i: int in range(144):
		assert_that(tiles[i]).is_not_null()
		assert_int(tiles[i].coords.x).is_equal(i % 12)
		assert_int(tiles[i].coords.y).is_equal(i / 12)


func test_coordinate_helpers() -> void:
	var gs: _GridSystem = GridSystem
	assert_bool(gs.is_in_bounds(0, 0)).is_true()
	assert_bool(gs.is_in_bounds(11, 11)).is_true()
	assert_bool(gs.is_in_bounds(-1, 0)).is_false()
	assert_bool(gs.is_in_bounds(12, 5)).is_false()

	assert_int(gs.index(2, 3)).is_equal(3 * 12 + 2)

	var tile: TacTileData = gs.get_tile(5, 5)
	assert_that(tile).is_not_null()
	assert_int(tile.coords.x).is_equal(5)
	assert_int(tile.coords.y).is_equal(5)

	assert_that(gs.get_tile(12, 12)).is_null()
	assert_that(gs.get_tile_by_index(143)).is_not_null()
	assert_that(gs.get_tile_by_index(144)).is_null()


func test_load_room_layout() -> void:
	var gs: _GridSystem = GridSystem
	var layout_data: Dictionary = {
		"id": "test_room",
		"layout":
		{
			"elevation": [0, 1, 2],
			"cover": [0, 1, 2],
			"blocked": [false, true, false],
			"vision_blocked": [true, false, true]
		}
	}
	gs.load_room(layout_data)
	assert_str(gs.room_id).is_equal("test_room")

	var t0: TacTileData = gs.get_tile_by_index(0)
	assert_int(t0.elevation).is_equal(0)
	assert_int(t0.cover).is_equal(0)
	assert_bool(t0.blocks_movement).is_false()
	assert_bool(t0.blocks_vision).is_true()

	var t1: TacTileData = gs.get_tile_by_index(1)
	assert_int(t1.elevation).is_equal(1)
	assert_int(t1.cover).is_equal(1)
	assert_bool(t1.blocks_movement).is_true()
	assert_bool(t1.blocks_vision).is_false()


func test_load_room_legacy() -> void:
	var gs: _GridSystem = GridSystem
	var legacy_data: Dictionary = {
		"id": "legacy_room",
		"tiles":
		[{"x": 5, "y": 5, "elevation": 2, "cover": 1, "blocks_movement": true, "tags": ["spawner"]}]
	}
	gs.load_room(legacy_data)
	var t: TacTileData = gs.get_tile(5, 5)
	assert_int(t.elevation).is_equal(2)
	assert_int(t.cover).is_equal(1)
	assert_bool(t.blocks_movement).is_true()
	assert_array(t.tags).contains(["spawner"])


func test_can_move_logic() -> void:
	var gs: _GridSystem = GridSystem
	gs.load_room({"id": "move_test", "layout": {"elevation": [0, 1, 2]}})

	# Elevation 0 to 1 is OK (delta 1)
	assert_bool(gs.can_move(0, 0, 1, 0)).is_true()
	# Elevation 0 to 2 is NOT OK (delta 2)
	assert_bool(gs.can_move(0, 0, 2, 0)).is_false()

	# Blocked movement
	gs.load_room({"id": "block_test", "layout": {"blocked": [false, true]}})
	assert_bool(gs.can_move(0, 0, 1, 0)).is_false()


func test_movement_cost_oil() -> void:
	var gs: _GridSystem = GridSystem
	gs.load_room({"id": "oil_test"})

	# Default cost
	assert_int(gs.get_movement_cost(1, 1)).is_equal(1)

	# Oil cost
	gs.set_oil_tile(1, 1, true)
	assert_int(gs.get_movement_cost(1, 1)).is_equal(2)

	gs.set_oil_tile(1, 1, false)
	assert_int(gs.get_movement_cost(1, 1)).is_equal(1)


func test_elemental_overlay_management() -> void:
	var gs: _GridSystem = GridSystem
	gs.clear_elemental_overlay()

	gs.apply_tile_element(2, 2, 1, 3, 10)  # 1 = FIRE (assuming ElementalTypes)
	var effects: Array = gs.get_tile_effects(2, 2)
	assert_int(effects.size()).is_equal(1)
	assert_int(int(effects[0]["element"])).is_equal(1)
	assert_int(int(effects[0]["duration"])).is_equal(3)

	gs.remove_tile_element(2, 2, 1)
	assert_int(gs.get_tile_effects(2, 2).size()).is_equal(0)


func test_tick_tile_effects() -> void:
	var gs: _GridSystem = GridSystem
	gs.clear_elemental_overlay()
	gs.apply_tile_element(3, 3, 2, 2, 1)  # duration 2

	var expired: int = gs.tick_tile_effects()
	assert_int(expired).is_equal(0)
	assert_int(int(gs.get_tile_effects(3, 3)[0]["duration"])).is_equal(1)

	expired = gs.tick_tile_effects()
	assert_int(expired).is_equal(1)
	assert_int(gs.get_tile_effects(3, 3).size()).is_equal(0)


func test_line_of_sight() -> void:
	var gs: _GridSystem = GridSystem
	# Clear grid
	gs.load_room({"id": "los_test"})

	assert_bool(gs.has_los(0, 0, 5, 0)).is_true()

	# Block vision in between
	var vision_blocked: Array = []
	vision_blocked.resize(144)
	vision_blocked.fill(false)
	vision_blocked[gs.index(2, 0)] = true
	var layout: Dictionary = {"vision_blocked": vision_blocked}
	gs.load_room({"id": "los_block", "layout": layout})

	assert_bool(gs.has_los(0, 0, 5, 0)).is_false()


func test_cover_cache_logic() -> void:
	var gs: _GridSystem = GridSystem
	# Heavy cover at (1, 0)
	var cover_data: Array = []
	cover_data.resize(144)
	cover_data.fill(0)
	cover_data[gs.index(1, 0)] = 2  # HEAVY
	var layout: Dictionary = {"cover": cover_data}
	gs.load_room({"id": "cover_test", "layout": layout})

	# Target at (1, 0) has cover against observer at (0, 0)
	assert_bool(gs.target_has_cover_against(0, 0, 1, 0)).is_true()
	# No cover if observer is far (only adjacent cover counts in _recompute_cover_cache)
	assert_bool(gs.target_has_cover_against(5, 5, 1, 0)).is_false()


# ── GridRenderer Visual Feedback Tests (#444) ───────────────────────────


func test_highlight_tile_shows_cover_color() -> void:
	var gs: _GridSystem = GridSystem
	gs.load_room({"id": "highlight_test"})

	var renderer: GridRenderer = GridRenderer.new()
	add_child(renderer)
	await get_tree().process_frame

	# Highlight a tile with the cover colour
	renderer.highlight_tile(0, 0, GridRenderer.COLOR_COVER)
	await get_tree().process_frame

	# The highlight sprite should exist as a child
	var found: bool = false
	for child: Node in renderer.get_children():
		if child is Sprite2D:
			var sprite: Sprite2D = child as Sprite2D
			# highlight_tile sets alpha to 0.6 when input alpha == 1.0,
			# so compare RGB only
			if (
				is_equal_approx(sprite.modulate.r, GridRenderer.COLOR_COVER.r)
				and is_equal_approx(sprite.modulate.g, GridRenderer.COLOR_COVER.g)
				and is_equal_approx(sprite.modulate.b, GridRenderer.COLOR_COVER.b)
			):
				found = true
				break
	assert_bool(found).is_true()

	renderer.queue_free()
	await get_tree().process_frame


func test_elevation_terrace_colors() -> void:
	var gs: _GridSystem = GridSystem
	# Tile (0,0) elevation 0, (1,0) elevation 1, (2,0) elevation 2
	var elev_data: Array = []
	elev_data.resize(144)
	elev_data.fill(0)
	elev_data[gs.index(0, 0)] = 0
	elev_data[gs.index(1, 0)] = 1
	elev_data[gs.index(2, 0)] = 2
	var layout: Dictionary = {"elevation": elev_data}
	gs.load_room({"id": "elev_color_test", "layout": layout})

	var renderer: GridRenderer = GridRenderer.new()
	add_child(renderer)
	await get_tree().process_frame

	# _render_grid runs in _ready(); inspect _tile_sprites
	var sprites: Array = renderer._tile_sprites
	assert_int(sprites.size()).is_greater(0)

	# Find sprites at each elevation and verify base colour family
	var found_floor: bool = false
	var found_elev1: bool = false
	var found_elev2: bool = false

	for sprite: Sprite2D in sprites:
		var mod: Color = sprite.modulate
		# Floor: near COLOR_FLOOR (0.5, 0.5, 0.5)
		if mod.r < 0.65 and mod.g < 0.65 and mod.b < 0.65:
			found_floor = true
		# Elev 1: near COLOR_ELEV_1 (0.75, 0.75, 0.75)
		elif mod.r >= 0.70 and mod.r < 0.90 and mod.g >= 0.70 and mod.g < 0.90:
			found_elev1 = true
		# Elev 2: near COLOR_ELEV_2 (1.0, 1.0, 1.0)
		elif mod.r >= 0.90 and mod.g >= 0.90 and mod.b >= 0.90:
			found_elev2 = true

	assert_bool(found_floor).is_true()
	assert_bool(found_elev1).is_true()
	assert_bool(found_elev2).is_true()

	renderer.queue_free()
	await get_tree().process_frame


func test_render_tile_base_mod_color() -> void:
	var gs: _GridSystem = GridSystem
	var elev_data: Array = []
	elev_data.resize(144)
	elev_data.fill(0)
	elev_data[gs.index(0, 0)] = 1  # Elevation 1
	var layout: Dictionary = {"elevation": elev_data}
	gs.load_room({"id": "base_mod_test", "layout": layout})

	var renderer: GridRenderer = GridRenderer.new()
	add_child(renderer)
	await get_tree().process_frame

	# _render_tile at (0,0) with elevation 1 should produce terrace sprites
	# The elevation-1 terrace should be in the COLOR_ELEV_1 family
	var found_elev1_terrace: bool = false
	for sprite: Sprite2D in renderer._tile_sprites:
		var mod: Color = sprite.modulate
		# Within tolerance of COLOR_ELEV_1 (0.75, 0.75, 0.75) plus variation
		if (
			mod.r >= 0.70
			and mod.r <= 0.85
			and mod.g >= 0.70
			and mod.g <= 0.85
			and mod.b >= 0.70
			and mod.b <= 0.85
		):
			found_elev1_terrace = true
			break

	assert_bool(found_elev1_terrace).is_true()

	renderer.queue_free()
	await get_tree().process_frame


func test_hover_cursor_visible_on_valid_tile() -> void:
	var gs: _GridSystem = GridSystem
	gs.load_room({"id": "hover_test"})

	var renderer: GridRenderer = GridRenderer.new()
	add_child(renderer)
	await get_tree().process_frame

	# Initially no hover
	assert_bool(renderer._hovered_tile == Vector2i(-1, -1)).is_true()
	if renderer._hover_sprite:
		assert_bool(renderer._hover_sprite.visible).is_false()

	# Simulate hover by setting hovered tile directly
	renderer._hovered_tile = Vector2i(0, 0)
	renderer._ensure_hover_sprite()
	if renderer._hover_sprite:
		var tile: TacTileData = gs.get_tile(0, 0)
		var elev: int = int(tile.elevation) if tile else 0
		renderer._hover_sprite.position = renderer._grid_to_world(0, 0, elev)
		renderer._hover_sprite.visible = true

	assert_that(renderer._hover_sprite).is_not_null()
	assert_bool(renderer._hover_sprite.visible).is_true()

	# Clear hover
	renderer._clear_hover()
	assert_bool(renderer._hovered_tile == Vector2i(-1, -1)).is_true()
	assert_bool(renderer._hover_sprite.visible).is_false()

	renderer.queue_free()
	await get_tree().process_frame


func test_cover_tile_renders_cover_sprite() -> void:
	var gs: _GridSystem = GridSystem
	# Tile (0,0) has light cover
	var cover_data: Array = []
	cover_data.resize(144)
	cover_data.fill(0)
	cover_data[gs.index(0, 0)] = 1  # LIGHT cover
	var layout: Dictionary = {"cover": cover_data}
	gs.load_room({"id": "cover_render_test", "layout": layout})

	var renderer: GridRenderer = GridRenderer.new()
	add_child(renderer)
	await get_tree().process_frame

	# Look for a cover sprite with COLOR_COVER modulate or premium prop texture
	var found_cover: bool = false
	for child: Node in renderer.get_children():
		if child is Sprite2D:
			var sprite: Sprite2D = child as Sprite2D
			var is_mod_cover: bool = (
				is_equal_approx(sprite.modulate.r, GridRenderer.COLOR_COVER.r)
				and is_equal_approx(sprite.modulate.g, GridRenderer.COLOR_COVER.g)
				and is_equal_approx(sprite.modulate.b, GridRenderer.COLOR_COVER.b)
			)
			var is_premium_prop: bool = (
				sprite.texture != null
				and (
					sprite.texture.resource_path.contains("prop_rock")
					or sprite.texture.resource_path.contains("prop_broken_pillar")
				)
			)
			if is_mod_cover or is_premium_prop:
				found_cover = true
				break

	assert_bool(found_cover).is_true()

	renderer.queue_free()
	await get_tree().process_frame


func test_highlight_tile_elevation_color() -> void:
	var gs: _GridSystem = GridSystem
	gs.load_room({"id": "highlight_elev_test"})

	var renderer: GridRenderer = GridRenderer.new()
	add_child(renderer)
	await get_tree().process_frame

	# Highlight with elevation color
	renderer.highlight_tile(0, 0, GridRenderer.COLOR_ELEV_1)
	await get_tree().process_frame

	var found: bool = false
	for child: Node in renderer.get_children():
		if child is Sprite2D:
			var sprite: Sprite2D = child as Sprite2D
			if (
				is_equal_approx(sprite.modulate.r, GridRenderer.COLOR_ELEV_1.r)
				and is_equal_approx(sprite.modulate.g, GridRenderer.COLOR_ELEV_1.g)
				and is_equal_approx(sprite.modulate.b, GridRenderer.COLOR_ELEV_1.b)
			):
				found = true
				break
	assert_bool(found).is_true()

	renderer.queue_free()
	await get_tree().process_frame

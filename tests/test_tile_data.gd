extends GdUnitTestSuite
## Unit tests for TacTileData


func test_is_blocked_default() -> void:
	var tile := TacTileData.new()
	tile.recompute_flags()
	assert_that(tile.is_blocked()).is_false()


func test_is_blocked_after_mutation() -> void:
	var tile := TacTileData.new()
	tile.blocks_movement = true
	tile.recompute_flags()
	assert_that(tile.is_blocked()).is_true()


func test_cover_defaults() -> void:
	var tile := TacTileData.new()
	tile.recompute_flags()
	assert_that(tile.has_cover() or tile.is_light_cover() or tile.is_heavy_cover()).is_false()


func test_light_cover() -> void:
	var tile := TacTileData.new()
	tile.cover = TacTileData.CoverType.LIGHT
	tile.recompute_flags()
	assert_that(tile.has_cover()).is_true()
	assert_that(tile.is_light_cover()).is_true()
	assert_that(tile.is_heavy_cover()).is_false()


func test_heavy_cover() -> void:
	var tile := TacTileData.new()
	tile.cover = TacTileData.CoverType.HEAVY
	tile.recompute_flags()
	assert_that(tile.has_cover()).is_true()
	assert_that(tile.is_light_cover()).is_false()
	assert_that(tile.is_heavy_cover()).is_true()

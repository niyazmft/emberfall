extends Node
## Unit tests for TacTileData


func test_is_blocked_default() -> bool:
	var tile := TacTileData.new()
	tile.recompute_flags()
	if tile.is_blocked():
		push_error("Expected default tile to not be blocked")
		return false
	return true


func test_is_blocked_after_mutation() -> bool:
	var tile := TacTileData.new()
	tile.blocks_movement = true
	tile.recompute_flags()
	if not tile.is_blocked():
		push_error("Expected mutated tile to be blocked")
		return false
	return true


func test_cover_defaults() -> bool:
	var tile := TacTileData.new()
	tile.recompute_flags()
	if tile.has_cover() or tile.is_light_cover() or tile.is_heavy_cover():
		push_error("Expected default tile to have no cover")
		return false
	return true


func test_light_cover() -> bool:
	var tile := TacTileData.new()
	tile.cover = TacTileData.CoverType.LIGHT
	tile.recompute_flags()
	if not tile.has_cover():
		push_error("Expected tile to have cover")
		return false
	if not tile.is_light_cover():
		push_error("Expected tile to be light cover")
		return false
	if tile.is_heavy_cover():
		push_error("Expected tile not to be heavy cover")
		return false
	return true


func test_heavy_cover() -> bool:
	var tile := TacTileData.new()
	tile.cover = TacTileData.CoverType.HEAVY
	tile.recompute_flags()
	if not tile.has_cover():
		push_error("Expected tile to have cover")
		return false
	if tile.is_light_cover():
		push_error("Expected tile not to be light cover")
		return false
	if not tile.is_heavy_cover():
		push_error("Expected tile to be heavy cover")
		return false
	return true


func _ready() -> void:
	var passed: int = 0
	var failed: int = 0
	var tests: Array[String] = [
		"test_is_blocked_default",
		"test_is_blocked_after_mutation",
		"test_cover_defaults",
		"test_light_cover",
		"test_heavy_cover",
	]

	for name: String in tests:
		print("Running %s ..." % name)
		var ok: Variant = call(name)
		if ok is bool and ok:
			passed += 1
			print("  PASS")
		else:
			failed += 1
			print("  FAIL (returned %s)" % str(ok))

	print("")
	print("Results: %d passed, %d failed out of %d" % [passed, failed, tests.size()])
	if failed > 0:
		push_error("TacTileData test suite had failures.")
		get_tree().quit(1)
	else:
		get_tree().quit(0)

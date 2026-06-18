extends GdUnitTestSuite


func test_sfx_manager_autoload() -> void:
	var sfx: _SFXManager = AutoloadHelper.sfx_manager()
	assert_object(sfx).is_not_null()


func test_play_sfx_valid() -> void:
	var sfx: _SFXManager = AutoloadHelper.sfx_manager()
	if sfx == null:
		return
	# Placeholder files exist in assets/audio/sfx/
	sfx.play_sfx("hit")
	sfx.play_sfx("move", Vector2(100, 100))


func test_play_sfx_invalid() -> void:
	var sfx: _SFXManager = AutoloadHelper.sfx_manager()
	if sfx == null:
		return
	# Should push a warning but not crash
	sfx.play_sfx("non_existent_sfx_id")

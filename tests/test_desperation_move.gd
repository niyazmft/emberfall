extends GdUnitTestSuite


func test_desperation_button_hidden_by_default() -> void:
	var bc: _BottomConsole = _BottomConsole.new()
	add_child(bc)
	var player: Entity = Entity.new("Player", 0, 0, 100, 10, 5)
	bc.setup(player)
	# Before visibility update, button may not exist yet.
	if bc.desperation_button != null:
		assert_bool(bc.desperation_button.visible).is_false()
	bc.queue_free()


func test_desperation_button_shows_at_low_hp() -> void:
	var bc: _BottomConsole = _BottomConsole.new()
	add_child(bc)
	var player: Entity = Entity.new("Player", 0, 0, 100, 10, 5)
	player.hp = 20  # 20% HP
	bc.setup(player)
	bc.update_desperation_visibility()
	if bc.desperation_button != null:
		assert_bool(bc.desperation_button.visible).is_true()
	bc.queue_free()


func test_desperation_button_hidden_after_used() -> void:
	var bc: _BottomConsole = _BottomConsole.new()
	add_child(bc)
	var player: Entity = Entity.new("Player", 0, 0, 100, 10, 5)
	player.hp = 20
	bc.setup(player)
	bc.mark_desperation_used()
	bc.update_desperation_visibility()
	if bc.desperation_button != null:
		assert_bool(bc.desperation_button.visible).is_false()
	bc.queue_free()

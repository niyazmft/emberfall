extends GdUnitTestSuite


func test_hover_preview_severity_safe() -> void:
	var mgr: HoverPreviewManager = HoverPreviewManager.new()
	add_child(mgr)

	var player: Entity = Entity.new("Player", 0, 0, 100, 10, 5)
	var enemy: Entity = Entity.new("Grunt", 1, 1, 50, 5, 3)
	mgr.setup(player)

	mgr.show_enemy_preview(enemy, "Grunt")
	assert_that(mgr.visible).is_true()

	mgr.queue_free()


func test_hover_preview_clear_hides() -> void:
	var mgr: HoverPreviewManager = HoverPreviewManager.new()
	add_child(mgr)

	var player: Entity = Entity.new("Player", 0, 0, 100, 10, 5)
	mgr.setup(player)

	mgr.clear()
	assert_that(mgr.visible).is_false()

	mgr.queue_free()

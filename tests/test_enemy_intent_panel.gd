extends GdUnitTestSuite


func test_intent_panel_instantiates() -> void:
	var panel: EnemyIntentPanel = EnemyIntentPanel.new()
	add_child(panel)
	assert_bool(panel.visible).is_false()
	panel.queue_free()


func test_intent_panel_refresh_empty() -> void:
	var panel: EnemyIntentPanel = EnemyIntentPanel.new()
	add_child(panel)
	panel.refresh([])
	assert_bool(panel.visible).is_false()
	panel.queue_free()


func test_intent_panel_clear_hides() -> void:
	var panel: EnemyIntentPanel = EnemyIntentPanel.new()
	add_child(panel)
	panel.visible = true
	panel.clear()
	assert_bool(panel.visible).is_false()
	panel.queue_free()

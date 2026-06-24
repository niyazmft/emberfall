extends GdUnitTestSuite

const COMBAT_HUD_SCENE: String = "res://scenes/ui/combat_hud.tscn"


func test_stats_update() -> void:
	var hud: Control = load(COMBAT_HUD_SCENE).instantiate() as Control
	add_child(hud)

	var entity: Entity = Entity.new("TestPlayer", 0, 0, 100, 10, 5)
	entity.is_player = true
	entity.ap = 6

	hud.call("setup", entity, null, null)

	var hp_bar: ProgressBar = hud.get_node("%HPBar") as ProgressBar
	var hp_label: Label = hud.get_node("%HPLabel") as Label
	var ap_bar: ProgressBar = hud.get_node("%APBar") as ProgressBar
	var ap_label: Label = hud.get_node("%APLabel") as Label

	assert_int(int(hp_bar.max_value)).is_equal(100)
	assert_int(int(hp_bar.value)).is_equal(100)
	assert_str(hp_label.text).is_equal("100 / 100")

	assert_int(int(ap_bar.max_value)).is_equal(GameConstants.AP_MAX)
	assert_int(int(ap_bar.value)).is_equal(6)
	assert_str(ap_label.text).is_equal("6 / 6")

	# Test HP change
	entity.hp = 50
	assert_int(int(hp_bar.value)).is_equal(50)
	assert_str(hp_label.text).is_equal("50 / 100")

	# Test AP change
	entity.ap = 2
	assert_int(int(ap_bar.value)).is_equal(2)
	assert_str(ap_label.text).is_equal("2 / 6")

	hud.queue_free()


func test_turn_indicator() -> void:
	var hud: Control = load(COMBAT_HUD_SCENE).instantiate() as Control
	add_child(hud)

	var turn_manager: TurnManager = TurnManager.new()
	add_child(turn_manager)

	hud.call("setup", null, turn_manager, null)

	var turn_label: Label = hud.get_node("%TurnLabel") as Label
	var attack_button: Button = hud.get_node("%AttackButton") as Button
	var end_turn_button: Button = hud.get_node("%EndTurnButton") as Button

	var player_entity: Entity = Entity.new("Player")
	player_entity.is_player = true

	turn_manager.turn_started.emit(player_entity, true)
	assert_str(turn_label.text).is_equal("Your Turn")
	assert_bool(attack_button.disabled).is_false()
	assert_bool(end_turn_button.disabled).is_false()

	var enemy_entity: Entity = Entity.new("Grunt")
	enemy_entity.is_player = false

	turn_manager.turn_started.emit(enemy_entity, false)
	assert_str(turn_label.text).is_equal("Enemy Turn: Grunt")
	assert_bool(attack_button.disabled).is_true()
	assert_bool(end_turn_button.disabled).is_true()

	hud.queue_free()
	turn_manager.queue_free()


func test_show_floating_text_spawns_label() -> void:
	var hud: Control = load(COMBAT_HUD_SCENE).instantiate() as Control
	add_child(hud)

	hud.call("show_floating_text", "42", Vector2(50, 50), Color.RED)

	var found_label: Label = null
	for child: Node in hud.get_children():
		if child is Label:
			found_label = child as Label
			break

	assert_that(found_label).is_not_null()
	if found_label:
		assert_str(found_label.text).is_equal("42")
		assert_that(found_label.modulate).is_equal(Color.RED)

	hud.queue_free()


func test_minimap_nodes_exist() -> void:
	var hud: Control = load(COMBAT_HUD_SCENE).instantiate() as Control
	add_child(hud)

	# Verify MinimapContainer exists
	var minimap_container: SubViewportContainer = hud.get_node_or_null("%MinimapContainer")
	assert_that(minimap_container).is_not_null()

	# Verify SubViewport exists inside
	var subviewport: SubViewport = minimap_container.get_node_or_null("SubViewport")
	assert_that(subviewport).is_not_null()
	assert_int(subviewport.size.x).is_equal(120)
	assert_int(subviewport.size.y).is_equal(120)

	# Verify Camera2D exists inside SubViewport
	var camera: Camera2D = subviewport.get_node_or_null("Camera2D")
	assert_that(camera).is_not_null()

	hud.queue_free()


func test_minimap_setup_creates_grid_renderer() -> void:
	var hud: Control = load(COMBAT_HUD_SCENE).instantiate() as Control
	add_child(hud)

	var entity: Entity = Entity.new("TestPlayer", 5, 5, 100, 10, 5)
	entity.is_player = true

	hud.call("setup", entity, null, null)
	await get_tree().process_frame
	await get_tree().process_frame

	var minimap_container: SubViewportContainer = hud.get_node_or_null("%MinimapContainer")
	var subviewport: SubViewport = minimap_container.get_node_or_null("SubViewport")

	# After setup(), a GridRenderer should exist in the SubViewport
	var found_grid: bool = false
	for child: Node in subviewport.get_children():
		if child is GridRenderer:
			found_grid = true
			# Verify scale is reduced
			assert_that(child.scale).is_equal(Vector2(0.15, 0.15))
			break
	assert_bool(found_grid).is_true()

	# Player dot should exist as child of the GridRenderer
	var grid: GridRenderer = null
	for child: Node in subviewport.get_children():
		if child is GridRenderer:
			grid = child
			break
	if grid:
		var found_dot: bool = false
		for child: Node in grid.get_children():
			if child is Sprite2D:
				found_dot = true
				break
		assert_bool(found_dot).is_true()

	hud.queue_free()

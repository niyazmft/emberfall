extends GdUnitTestSuite


func test_bottom_console_instantiates() -> void:
	var scene: PackedScene = load("res://scenes/ui/bottom_console.tscn") as PackedScene
	var bc: Control = scene.instantiate() as Control
	add_child(bc)
	await get_tree().process_frame

	assert_that(bc).is_not_null()
	assert_that(bc.get_node_or_null("MarginContainer/HBoxContainer/LeftWing/HPBar")).is_not_null()

	bc.queue_free()
	await get_tree().process_frame


func test_setup_sets_bar_values() -> void:
	var scene: PackedScene = load("res://scenes/ui/bottom_console.tscn") as PackedScene
	var bc: _BottomConsole = scene.instantiate() as _BottomConsole
	add_child(bc)
	await get_tree().process_frame

	var ent: Entity = Entity.new()
	ent.hp_max = 100
	ent.hp = 50
	ent.ap = 3

	bc.setup(ent)
	await get_tree().process_frame

	assert_that(bc.hp_bar.value).is_equal(50.0)
	assert_that(bc.hp_bar.max_value).is_equal(100.0)

	bc.queue_free()
	await get_tree().process_frame


func test_update_bars_reflects_entity_changes() -> void:
	var scene: PackedScene = load("res://scenes/ui/bottom_console.tscn") as PackedScene
	var bc: _BottomConsole = scene.instantiate() as _BottomConsole
	add_child(bc)
	await get_tree().process_frame

	var ent: Entity = Entity.new()
	ent.hp_max = 100
	ent.hp = 80
	ent.ap = 5

	bc.setup(ent)
	await get_tree().process_frame

	assert_that(bc.hp_bar.value).is_equal(80.0)

	ent.hp = 40
	bc._update_bars()
	await get_tree().process_frame

	assert_that(bc.hp_bar.value).is_equal(40.0)

	bc.queue_free()
	await get_tree().process_frame

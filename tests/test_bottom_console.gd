extends GdUnitTestSuite


func test_bottom_console_instantiates() -> void:
	var scene: PackedScene = load("res://scenes/ui/bottom_console.tscn") as PackedScene
	var bc: Control = scene.instantiate() as Control
	add_child(bc)
	await get_tree().process_frame

	assert_that(bc).is_not_null()
	assert_that(bc.get_node_or_null("MarginContainer/HBoxContainer/LeftWing")).is_not_null()

	bc.queue_free()
	await get_tree().process_frame


func test_setup_sets_burden_label() -> void:
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

	assert_that(bc.burden_label.text).is_equal("Burden: 0")

	bc.queue_free()
	await get_tree().process_frame


func test_buttons_exist() -> void:
	var scene: PackedScene = load("res://scenes/ui/bottom_console.tscn") as PackedScene
	var bc: _BottomConsole = scene.instantiate() as _BottomConsole
	add_child(bc)
	await get_tree().process_frame

	assert_that(bc.move_button).is_not_null()
	assert_that(bc.attack_button).is_not_null()
	assert_that(bc.end_turn_button).is_not_null()

	bc.queue_free()
	await get_tree().process_frame

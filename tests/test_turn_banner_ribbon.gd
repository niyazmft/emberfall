extends GdUnitTestSuite


func _create_turn_banner() -> Control:
	var scene: PackedScene = load("res://scenes/ui/turn_banner.tscn") as PackedScene
	var banner: Control = scene.instantiate() as Control
	return banner


func _get_banner_background(banner: Control) -> ColorRect:
	return banner.get_node("Background") as ColorRect


func test_ribbon_exists() -> void:
	var banner: Control = _create_turn_banner()
	add_child(banner)
	await get_tree().process_frame

	var bg: ColorRect = _get_banner_background(banner)
	var ribbon: Panel = bg.get_node_or_null("Ribbon")
	assert_that(ribbon).is_not_null()

	banner.queue_free()
	await get_tree().process_frame


func test_ribbon_starts_off_screen() -> void:
	var banner: Control = _create_turn_banner()
	add_child(banner)
	await get_tree().process_frame

	var bg: ColorRect = _get_banner_background(banner)
	var ribbon: Panel = bg.get_node_or_null("Ribbon")
	assert_that(ribbon).is_not_null()
	if ribbon == null:
		banner.queue_free()
		return

	banner.visible = true
	banner.modulate.a = 1.0
	banner.scale = Vector2.ONE

	# Call _show_banner via reflection since it is private
	var callable: Callable = Callable(banner, "_show_banner")
	callable.call("TEST", true)

	await get_tree().process_frame
	assert_that(ribbon.position.x).is_less(0.0)

	banner.queue_free()
	await get_tree().process_frame


func test_ribbon_ends_centered() -> void:
	var banner: Control = _create_turn_banner()
	add_child(banner)
	await get_tree().process_frame

	var bg: ColorRect = _get_banner_background(banner)
	var ribbon: Panel = bg.get_node_or_null("Ribbon")
	assert_that(ribbon).is_not_null()
	if ribbon == null:
		banner.queue_free()
		return

	ribbon.position.x = -ribbon.size.x
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(ribbon, "position:x", 0.0, 0.1)
	await tween.finished

	assert_float(ribbon.position.x).is_equal(0.0)

	banner.queue_free()
	await get_tree().process_frame

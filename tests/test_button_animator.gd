extends GdUnitTestSuite


func test_button_hover_scale() -> void:
	var animator: _ButtonAnimator = _ButtonAnimator.new()
	var container: Control = Control.new()
	var btn: Button = Button.new()
	container.add_child(btn)
	add_child(container)

	animator.apply_to_buttons(container)
	btn.scale = Vector2.ONE
	btn.emit_signal("mouse_entered")
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	assert_that(btn.scale.x).is_greater_equal(1.04)
	container.queue_free()
	animator.queue_free()


func test_button_press_scale() -> void:
	var animator: _ButtonAnimator = _ButtonAnimator.new()
	var container: Control = Control.new()
	var btn: Button = Button.new()
	container.add_child(btn)
	add_child(container)

	animator.apply_to_buttons(container)
	btn.scale = Vector2.ONE
	btn.emit_signal("button_down")
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout

	assert_that(btn.scale.x).is_less_equal(0.96)
	container.queue_free()
	animator.queue_free()


func test_button_returns_to_normal() -> void:
	var animator: _ButtonAnimator = _ButtonAnimator.new()
	var container: Control = Control.new()
	var btn: Button = Button.new()
	container.add_child(btn)
	add_child(container)

	animator.apply_to_buttons(container)
	btn.scale = Vector2(_ButtonAnimator.HOVER_SCALE, _ButtonAnimator.HOVER_SCALE)
	btn.emit_signal("mouse_exited")
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	assert_that(btn.scale.x).is_equal(1.0)
	container.queue_free()
	animator.queue_free()

extends GdUnitTestSuite


func test_set_initial_focus_exists() -> void:
	var fm: Node = AutoloadHelper.focus_manager()
	assert_bool(fm.has_method("set_initial_focus")).is_true()


func test_focus_ring_visibility() -> void:
	if OS.has_feature("headless"):
		return

	var fm: _FocusManager = AutoloadHelper.focus_manager() as _FocusManager
	var btn: Button = Button.new()
	get_tree().root.add_child(btn)

	btn.grab_focus()
	# Give it a frame to process
	await get_tree().process_frame

	var focus_ring: ColorRect = fm.get_node("FocusCanvas/FocusRing") as ColorRect
	assert_bool(focus_ring.visible).is_true()

	btn.hide()
	await get_tree().process_frame
	assert_bool(focus_ring.visible).is_false()

	btn.show()
	btn.grab_focus()
	await get_tree().process_frame
	assert_bool(focus_ring.visible).is_true()

	var btn2: Button = Button.new()
	get_tree().root.add_child(btn2)
	btn2.grab_focus()
	await get_tree().process_frame
	assert_bool(focus_ring.visible).is_true()
	# Focus ring should be at btn2 position now
	assert_vector(focus_ring.global_position).is_equal(btn2.get_global_rect().position)

	btn2.queue_free()
	btn.queue_free()

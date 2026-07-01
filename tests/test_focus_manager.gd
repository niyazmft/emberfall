extends GdUnitTestSuite


func test_set_initial_focus_exists() -> void:
	var fm: Node = AutoloadHelper.focus_manager()
	assert_bool(fm.has_method("set_initial_focus")).is_true()


func test_focus_ring_is_intentionally_hidden() -> void:
	if OS.has_feature("headless"):
		return

	var fm: _FocusManager = AutoloadHelper.focus_manager() as _FocusManager
	var btn: Button = Button.new()
	get_tree().root.add_child(btn)

	btn.grab_focus()
	# Give it a frame to process
	await get_tree().process_frame

	var focus_ring: ColorRect = fm.get_node("FocusCanvas/FocusRing") as ColorRect
	# Focus ring should be hidden so custom theme styles can take precedence
	assert_bool(focus_ring.visible).is_false()

	btn.queue_free()

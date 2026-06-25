extends GdUnitTestSuite


func test_camera_follows_player() -> void:
	var room: CombatRoom = CombatRoom.new()
	room.camera = Camera2D.new()
	room.add_child(room.camera)
	room._camera_target = Node2D.new()
	room._camera_target.position = Vector2(100, 100)
	room.add_child(room._camera_target)

	room.camera.position = Vector2.ZERO
	room._update_camera(1.0)
	assert_that(room.camera.position).is_not_equal(Vector2.ZERO)

	room.queue_free()


func test_camera_shake_applies_offset() -> void:
	var room: CombatRoom = CombatRoom.new()
	room.camera = Camera2D.new()
	room.add_child(room.camera)
	room.camera.position = Vector2.ZERO

	room.trigger_camera_shake(4.0)
	assert_bool(room._camera_shake_time > 0.0).is_true()

	room._update_camera(0.01)
	assert_that(room.camera.position).is_not_equal(Vector2.ZERO)

	room.queue_free()


func test_title_screen_has_premise() -> void:
	# Verify the localization key exists (actual UI instantiation requires scene nodes)
	var premise_text: String = tr("TITLE_PREMISE")
	assert_bool(premise_text.length() > 0).is_true()
	assert_bool(premise_text != "TITLE_PREMISE").is_true()  # tr() returns key if missing

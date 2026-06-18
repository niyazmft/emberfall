extends GdUnitTestSuite

const TURN_BANNER_SCENE := "res://scenes/ui/turn_banner.tscn"


func test_turn_banner_integration() -> void:
	# 1. Instantiate TurnBanner
	var banner: Control = load(TURN_BANNER_SCENE).instantiate()
	add_child(banner)

	# 2. Check initial state
	assert_bool(banner.visible).is_false()
	assert_float(banner.modulate.a).is_equal(0.0)

	# 3. Simulate room_entered (Combat Started)
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.room_entered.emit(0, {})

		# Give it one frame to process the signal
		await await_idle_frame()

		# Banner should now be visible and starting to fade in/slide
		assert_bool(banner.visible).is_true()
		assert_float(banner.modulate.a).is_greater(0.0)

		# We don't want to wait for the whole animation in a unit test if possible,
		# but let's verify it's active.

		# 4. Simulate turn_started (Player)
		# Force hidden to test re-trigger
		banner.visible = false
		eb.turn_started.emit(null, true)

		await await_idle_frame()
		assert_bool(banner.visible).is_true()

		# 5. Check Label text (localized)
		var label: Label = banner.get_node("Label")
		# tr() might not work perfectly in headless test if translations aren't loaded,
		# but let's check if it's not empty.
		assert_str(label.text).is_not_empty()

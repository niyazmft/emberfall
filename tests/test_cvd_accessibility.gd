extends GdUnitTestSuite


func test_cvd_mode_application() -> void:
	var bsm: Node = AutoloadHelper.burden_shader_manager()
	assert_object(bsm).is_not_null()

	# Initial state
	bsm.call("set_cvd_mode", 0)
	var current_mode: int = bsm.get("_current_cvd_mode")
	assert_int(current_mode).is_equal(0)

	# Mock/verify global shader parameter
	# Note: We can't easily verify RenderingServer global uniforms in headless tests
	# without a mock RenderingServer, but we can verify internal state.

	bsm.call("set_cvd_mode", 1)
	assert_int(bsm.get("_current_cvd_mode")).is_equal(1)

	bsm.call("set_cvd_mode", 2)
	assert_int(bsm.get("_current_cvd_mode")).is_equal(2)

	bsm.call("set_cvd_mode", 3)
	assert_int(bsm.get("_current_cvd_mode")).is_equal(3)


func test_pp_rect_visibility() -> void:
	var bsm: Node = AutoloadHelper.burden_shader_manager()
	assert_object(bsm).is_not_null()

	# Create a dummy ColorRect to register
	var rect := ColorRect.new()
	auto_free(rect)
	bsm.call("register_pp_rect", rect)

	# Case 1: Nothing active
	bsm.call("set_cvd_mode", 0)
	# Force burden inactive if possible, but BurdenManager is an autoload.
	# We'll assume burden is inactive by default in tests.
	if not AutoloadHelper.burden_manager().get("burden_active"):
		assert_bool(rect.visible).is_false()

	# Case 2: CVD active
	bsm.call("set_cvd_mode", 1)
	assert_bool(rect.visible).is_true()

	# Case 3: Back to inactive
	bsm.call("set_cvd_mode", 0)
	if not AutoloadHelper.burden_manager().get("burden_active"):
		assert_bool(rect.visible).is_false()

extends GdUnitTestSuite


func test_get_value_with_fallbacks() -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()

	# Value from DEFAULTS
	# ConfigLoader.getValue returns Variant, JSON/Dictionary might store as float
	var val: Variant = cl.getValue("AP_MAX")
	assert_int(int(val)).is_equal(6)

	# Value that doesn't exist anywhere
	assert_that(cl.getValue("NON_EXISTENT", "", 999)).is_equal(999)


func test_typed_getters() -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()

	# Int getter
	assert_int(cl.getInt("AP_MAX")).is_equal(6)
	assert_int(cl.getInt("NON_EXISTENT", 42)).is_equal(42)

	# Float getter
	assert_float(cl.getFloat("CRIT_MULT")).is_equal(1.5)
	assert_float(cl.getFloat("NON_EXISTENT", 3.14)).is_equal(3.14)

	# String getter
	assert_str(cl.getString("AP_MAX", "fallback")).is_equal("fallback")


func test_is_loaded() -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	# In a real environment, it should be loaded after _ready
	assert_bool(cl.isLoaded()).is_true()

extends GdUnitTestSuite

func test_get_value_with_fallbacks() -> void:
	var cl: _ConfigLoader = ConfigLoader

	# Value from DEFAULTS
	assert_that(cl.getValue("AP_MAX")).is_equal(6)

	# Value that doesn't exist anywhere
	assert_that(cl.getValue("NON_EXISTENT", "", 999)).is_equal(999)

func test_typed_getters() -> void:
	var cl: _ConfigLoader = ConfigLoader

	# Int getter
	assert_that(cl.getInt("AP_MAX")).is_equal(6)
	assert_that(cl.getInt("NON_EXISTENT", 42)).is_equal(42)

	# Float getter
	assert_that(cl.getFloat("CRIT_MULT")).is_equal(1.5)
	assert_that(cl.getFloat("NON_EXISTENT", 3.14)).is_equal(3.14)

	# String getter
	assert_that(cl.getString("AP_MAX", "fallback")).is_equal("fallback")

func test_is_loaded() -> void:
	var cl: _ConfigLoader = ConfigLoader
	# In a real environment, it should be loaded after _ready
	assert_that(cl.isLoaded()).is_true()

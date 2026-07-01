extends GdUnitTestSuite


func before_test() -> void:
	var sm: Node = AutoloadHelper.settings_manager()
	if sm != null:
		sm.call("reset_to_defaults")


func test_screen_reader_manager_exists() -> void:
	var srm: Node = AutoloadHelper.screen_reader_manager()
	assert_object(srm).is_not_null()


func test_screen_reader_default_disabled() -> void:
	var sm: Node = AutoloadHelper.settings_manager()
	assert_object(sm).is_not_null()
	var settings: Dictionary = sm.get("settings")
	var access_cfg: Dictionary = settings.get("accessibility", {}) as Dictionary
	assert_bool(access_cfg.get("screen_reader_enabled", true)).is_false()


func test_screen_reader_enable_disable() -> void:
	var srm: _ScreenReaderManager = AutoloadHelper.screen_reader_manager()
	if srm == null:
		return

	var original_enabled: bool = srm.is_enabled()

	srm.enable()
	assert_bool(srm.is_enabled()).is_true()

	srm.disable()
	assert_bool(srm.is_enabled()).is_false()

	# Restore original state
	if original_enabled:
		srm.enable()
	else:
		srm.disable()


func test_screen_reader_speak_does_not_crash_when_disabled() -> void:
	var srm: _ScreenReaderManager = AutoloadHelper.screen_reader_manager()
	if srm == null:
		return

	srm.disable()
	srm.speak("Test message when disabled")
	# If we reach here without crashing, the test passes
	assert_bool(true).is_true()


func test_settings_manager_applies_screen_reader_setting() -> void:
	var sm: _SettingsManager = AutoloadHelper.settings_manager()
	if sm == null:
		return

	var original_value: bool = bool(
		sm.settings["accessibility"].get("screen_reader_enabled", false)
	)

	sm.settings["accessibility"]["screen_reader_enabled"] = true
	sm.apply_accessibility_settings()

	var srm: _ScreenReaderManager = AutoloadHelper.screen_reader_manager()
	if srm != null and srm.is_available():
		assert_bool(srm.is_enabled()).is_true()

	# Restore
	sm.settings["accessibility"]["screen_reader_enabled"] = original_value
	sm.apply_accessibility_settings()

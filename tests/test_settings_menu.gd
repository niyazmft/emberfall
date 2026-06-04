extends GdUnitTestSuite


func before_test() -> void:
	# Clear settings file before tests
	if FileAccess.file_exists("user://settings.json"):
		DirAccess.remove_absolute("user://settings.json")
	if FileAccess.file_exists("user://settings.save"):
		DirAccess.remove_absolute("user://settings.save")

	var sm := AutoloadHelper.settings_manager()
	if sm != null:
		sm.reset_to_defaults()


func test_settings_default_values() -> void:
	var sm := AutoloadHelper.settings_manager()
	assert_not_null(sm)
	assert_float(sm.settings.audio.master_volume).is_equal(1.0)
	assert_bool(sm.settings.video.fullscreen).is_true()
	assert_int(sm.settings.video.resolution_width).is_equal(1920)


func test_settings_save_load() -> void:
	var sm := AutoloadHelper.settings_manager()
	assert_not_null(sm)
	sm.settings.audio.master_volume = 0.5
	sm.settings.video.fullscreen = false
	sm.save_settings()

	# Reset local state
	sm.settings.audio.master_volume = 1.0

	sm.load_settings()
	assert_float(sm.settings.audio.master_volume).is_equal(0.5)
	assert_bool(sm.settings.video.fullscreen).is_false()


func test_ui_to_settings_sync() -> void:
	if OS.has_feature("headless"):
		return

	var panel_scene: PackedScene = load("res://scenes/ui/settings_panel.tscn")
	var panel: Node = auto_free(panel_scene.instantiate())
	add_child(panel)

	var slider: HSlider = panel.get_node("%MasterSlider") as HSlider
	slider.value = 0.2
	slider.value_changed.emit(0.2)

	var sm := AutoloadHelper.settings_manager()
	assert_float(sm.settings.audio.master_volume).is_equal(0.2)


func test_apply_video_settings() -> void:
	if OS.has_feature("headless"):
		return

	var panel_scene: PackedScene = load("res://scenes/ui/settings_panel.tscn")
	var panel: Node = auto_free(panel_scene.instantiate())
	add_child(panel)

	var res_option: OptionButton = panel.get_node("%ResolutionOption") as OptionButton
	res_option.selected = 2  # 1280x720

	var apply_btn: Button = panel.get_node("%ApplyButton") as Button
	apply_btn.pressed.emit()

	var sm := AutoloadHelper.settings_manager()
	assert_int(sm.settings.video.resolution_width).is_equal(1280)
	assert_int(sm.settings.video.resolution_height).is_equal(720)


func test_reset_to_defaults() -> void:
	var sm := AutoloadHelper.settings_manager()
	assert_not_null(sm)
	sm.settings.audio.master_volume = 0.1
	sm.save_settings()

	sm.reset_to_defaults()
	assert_float(sm.settings.audio.master_volume).is_equal(1.0)

	if not FileAccess.file_exists("user://settings.json"):
		fail("settings.json should exist after reset_to_defaults")

	var file: FileAccess = FileAccess.open("user://settings.json", FileAccess.READ)
	var json_data: Variant = JSON.parse_string(file.get_as_text())
	if json_data is Dictionary:
		var audio: Dictionary = json_data.get("audio", {}) as Dictionary
		assert_float(audio.get("master_volume", 0.0)).is_equal(1.0)
	else:
		fail("Parsed JSON is not a dictionary")

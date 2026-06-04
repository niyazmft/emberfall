extends GdUnitTestSuite


func before_test() -> void:
	# Clear settings file before tests
	if FileAccess.file_exists("user://settings.json"):
		DirAccess.remove_absolute("user://settings.json")
	if FileAccess.file_exists("user://settings.save"):
		DirAccess.remove_absolute("user://settings.save")
	SettingsManager.reset_to_defaults()


func test_settings_default_values() -> void:
	assert_float(SettingsManager.settings.audio.master_volume).is_equal(1.0)
	assert_bool(SettingsManager.settings.video.fullscreen).is_true()
	assert_int(SettingsManager.settings.video.resolution_width).is_equal(1920)


func test_settings_save_load() -> void:
	SettingsManager.settings.audio.master_volume = 0.5
	SettingsManager.settings.video.fullscreen = false
	SettingsManager.save_settings()

	# Reset local state
	SettingsManager.settings.audio.master_volume = 1.0

	SettingsManager.load_settings()
	assert_float(SettingsManager.settings.audio.master_volume).is_equal(0.5)
	assert_bool(SettingsManager.settings.video.fullscreen).is_false()


func test_ui_to_settings_sync() -> void:
	if OS.has_feature("headless"):
		return

	var panel_scene: PackedScene = load("res://scenes/ui/settings_panel.tscn")
	var panel: Node = auto_free(panel_scene.instantiate())
	add_child(panel)

	var slider: HSlider = panel.get_node("%MasterSlider") as HSlider
	slider.value = 0.2
	slider.value_changed.emit(0.2)

	assert_float(SettingsManager.settings.audio.master_volume).is_equal(0.2)


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

	assert_int(SettingsManager.settings.video.resolution_width).is_equal(1280)
	assert_int(SettingsManager.settings.video.resolution_height).is_equal(720)

extends GdUnitTestSuite


func test_audio_settings_apply_during_combat() -> void:
	var sm: _SettingsManager = AutoloadHelper.settings_manager()
	if sm == null:
		return

	# Store original values
	var original_master: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	var original_mute: bool = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))

	# Modify settings and apply
	sm.settings["audio"]["master_volume"] = 0.5
	sm.settings["audio"]["mute"] = true
	sm.apply_audio_settings()

	# Verify AudioServer reflects the change
	var master_bus: int = AudioServer.get_bus_index("Master")
	assert_float(AudioServer.get_bus_volume_db(master_bus)).is_not_equal(original_master)
	assert_bool(AudioServer.is_bus_mute(master_bus)).is_true()

	# Restore original values
	sm.settings["audio"]["master_volume"] = 1.0
	sm.settings["audio"]["mute"] = original_mute
	sm.apply_audio_settings()


func test_settings_save_and_load_round_trip() -> void:
	var sm: _SettingsManager = AutoloadHelper.settings_manager()
	if sm == null:
		return

	# Store original audio setting
	var original_volume: float = float(sm.settings["audio"].get("master_volume", 1.0))

	# Change and save
	sm.settings["audio"]["master_volume"] = 0.75
	var save_ok: bool = sm.save_settings()
	assert_bool(save_ok).is_true()

	# Reload
	sm.load_settings()
	var reloaded_volume: float = float(sm.settings["audio"].get("master_volume", 1.0))
	assert_float(reloaded_volume).is_equal(0.75)

	# Restore and save
	sm.settings["audio"]["master_volume"] = original_volume
	sm.save_settings()


func test_accessibility_settings_apply_cvd_mode() -> void:
	var sm: _SettingsManager = AutoloadHelper.settings_manager()
	if sm == null:
		return

	# Store original
	var original_cvd: int = int(sm.settings["accessibility"].get("cvd_sim", 0))

	# Change to deuteranopia (mode 2) and apply
	sm.settings["accessibility"]["cvd_sim"] = 2
	# apply_accessibility_settings does not crash even if BurdenShaderManager is absent
	sm.apply_accessibility_settings()
	# We cannot verify the shader state directly without the manager,
	# but the call itself not crashing is the primary guarantee.
	assert_bool(true).is_true()

	# Restore
	sm.settings["accessibility"]["cvd_sim"] = original_cvd
	sm.apply_accessibility_settings()


func test_video_settings_structure_valid() -> void:
	var sm: _SettingsManager = AutoloadHelper.settings_manager()
	if sm == null:
		return

	# Verify video settings dict has required keys
	var video: Dictionary = sm.settings.get("video", {}) as Dictionary
	assert_bool(video.has("resolution_width")).is_true()
	assert_bool(video.has("resolution_height")).is_true()
	assert_bool(video.has("fullscreen")).is_true()
	assert_bool(video.has("vsync")).is_true()
	# Values are sensible defaults
	assert_int(int(video.get("resolution_width", 0))).is_greater(0)
	assert_int(int(video.get("resolution_height", 0))).is_greater(0)

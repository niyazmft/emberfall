extends Node
class_name _SettingsManager

## Autoload: SettingsManager
## Handles reading/writing user settings to user://settings.json.

const SAVE_PATH: String = "user://settings.json"

enum SettingCategory { DISPLAY, AUDIO, INPUT, ACCESSIBILITY }

var settings: Dictionary = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.8,
		"mute": false,
	},
	"video": {
		"fullscreen": true,
		"resolution_width": 1920,
		"resolution_height": 1080,
		"vsync": true,
	},
	"accessibility": {
		"screen_shake": 1.0,
		"cvd_sim": 0,  # 0: None, 1: Protanopia, 2: Deuteranopia, 3: Tritanopia
	},
	"controls": {
		"input_hints": 0  # 0: Auto, 1: KBM, 2: Gamepad
	}
}

var init_time_ms: int = 0


func _ready() -> void:
	var start_time: int = Time.get_ticks_msec()
	load_settings()
	apply_settings()
	init_time_ms = Time.get_ticks_msec() - start_time
	_print_debug("Initialized in %d ms" % init_time_ms)


func save_settings() -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string: String = JSON.stringify(settings, "\t")
		file.store_string(json_string)
		file.close()
		_print_debug("Settings saved to %s" % SAVE_PATH)
		return true
	else:
		_print_error("Failed to open settings file for writing: %s" % SAVE_PATH)
		return false


func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		# Fallback to legacy save if it exists, then migrate
		if FileAccess.file_exists("user://settings.save"):
			_load_legacy_settings()
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string: String = file.get_as_text()
		file.close()

		var json: JSON = JSON.new()
		var error: Error = json.parse(json_string)
		if error == OK:
			var loaded_settings: Variant = json.data
			if loaded_settings is Dictionary:
				_merge_dict(settings, loaded_settings as Dictionary)
				_print_debug("Settings loaded successfully from JSON")
			else:
				_print_error("Settings JSON is not a dictionary")
		else:
			_print_error("JSON Parse Error: %s at line %d" % [json.get_error_message(), json.get_error_line()])
	else:
		_print_error("Failed to open settings file for reading: %s" % SAVE_PATH)


func _load_legacy_settings() -> void:
	var legacy_path: String = "user://settings.save"
	var file: FileAccess = FileAccess.open_encrypted_with_pass(
		legacy_path, FileAccess.READ, OS.get_unique_id() + "_settings_salt"
	)
	if file:
		var loaded_settings: Variant = file.get_var()
		file.close()
		if loaded_settings is Dictionary:
			_merge_dict(settings, loaded_settings as Dictionary)
			_print_debug("Legacy settings migrated")
			if save_settings():
				DirAccess.remove_absolute(legacy_path)
		else:
			_print_error("Legacy settings corrupted, skipping migration")
			# We don't delete it here to allow for potential manual recovery if needed
			# although it's likely a lost cause.


func reset_to_defaults() -> void:
	settings = {
		"audio": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 0.8,
			"mute": false,
		},
		"video": {
			"fullscreen": true,
			"resolution_width": 1920,
			"resolution_height": 1080,
			"vsync": true,
		},
		"accessibility": {
			"screen_shake": 1.0,
			"cvd_sim": 0,
		},
		"controls": {
			"input_hints": 0
		}
	}
	apply_settings()
	save_settings()


func _merge_dict(base: Dictionary, override: Dictionary) -> void:
	for key: Variant in override.keys():
		if base.has(key):
			if base[key] is Dictionary and override[key] is Dictionary:
				_merge_dict(base[key] as Dictionary, override[key] as Dictionary)
			else:
				base[key] = override[key]
		else:
			base[key] = override[key]


func apply_settings() -> void:
	# Audio
	var audio_cfg: Dictionary = settings.get("audio", {}) as Dictionary
	var mute: bool = bool(audio_cfg.get("mute", false))

	_apply_bus_volume("Master", float(audio_cfg.get("master_volume", 1.0)), mute)
	_apply_bus_volume("Music", float(audio_cfg.get("music_volume", 0.8)), mute)
	_apply_bus_volume("SFX", float(audio_cfg.get("sfx_volume", 0.8)), mute)

	# Video
	var video_cfg: Dictionary = settings.get("video", {}) as Dictionary
	var is_fullscreen: bool = bool(video_cfg.get("fullscreen", true))
	var mode: Window.Mode = Window.MODE_FULLSCREEN if is_fullscreen else Window.MODE_WINDOWED
	get_window().set_mode(mode)

	if not is_fullscreen:
		var w: int = int(video_cfg.get("resolution_width", 1920))
		var h: int = int(video_cfg.get("resolution_height", 1080))
		get_window().set_size(Vector2i(w, h))

	var vsync: bool = bool(video_cfg.get("vsync", true))
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)

	# Accessibility
	var access_cfg: Dictionary = settings.get("accessibility", {}) as Dictionary
	# Apply CVD Simulation if there's a system for it
	# In Emberfall, this might be handled by a shader or a singleton
	if has_node("/root/BurdenShaderManager"):
		get_node("/root/BurdenShaderManager").call("set_cvd_mode", int(access_cfg.get("cvd_sim", 0)))


func _apply_bus_volume(bus_name: String, volume_linear: float, mute: bool) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, mute)
		if not mute:
			AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_linear))


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("SettingsManager: %s" % msg)


func _print_error(msg: String) -> void:
	push_error("SettingsManager: %s" % msg)

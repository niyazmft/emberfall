extends Node
class_name _SettingsManager

## Autoload: SettingsManager
## Handles reading/writing user settings to user://settings.save.

const SAVE_PATH: String = "user://settings.save"

var settings: Dictionary = {
	"audio": {"master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 0.8},
	"video": {"fullscreen": true, "resolution": Vector2i(1920, 1080)},
	"accessibility": {"screen_shake": 1.0, "cvd_sim": 0},
	"controls": {"input_hints": 0}  # 0: Auto, 1: KBM, 2: Gamepad
}
var init_time_ms: int = 0


func _ready() -> void:
	var start_time := Time.get_ticks_msec()
	_initialize()
	init_time_ms = Time.get_ticks_msec() - start_time
	if OS.is_debug_build():
		print("Autoload '%s' initialized in %d ms" % [name, init_time_ms])


func _initialize() -> void:
	load_settings()
	apply_settings()


func save_settings() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()
	else:
		_print_error("Failed to open settings file for writing: %s" % SAVE_PATH)


func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var loaded_settings: Variant = file.get_var()
		file.close()

		if loaded_settings is Dictionary:
			# Merge loaded settings into defaults to handle new keys
			_merge_dict(settings, loaded_settings as Dictionary)
			_print_debug("Settings loaded successfully")
		else:
			_print_error("Settings file is corrupted or invalid format")
	else:
		_print_error("Failed to open settings file for reading: %s" % SAVE_PATH)


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
	var master_bus: int = AudioServer.get_bus_index("Master")
	if master_bus != -1:
		var audio_cfg: Dictionary = settings.get("audio", {}) as Dictionary
		AudioServer.set_bus_volume_db(
			master_bus, linear_to_db(float(audio_cfg.get("master_volume", 1.0)))
		)

	# Video
	var video_cfg: Dictionary = settings.get("video", {}) as Dictionary
	var is_fullscreen: bool = bool(video_cfg.get("fullscreen", true))
	var mode: Window.Mode = Window.MODE_FULLSCREEN if is_fullscreen else Window.MODE_WINDOWED
	get_window().set_mode(mode)
	if not is_fullscreen:
		var res: Variant = video_cfg.get("resolution", Vector2i(1920, 1080))
		if res is Vector2i:
			get_window().set_size(res as Vector2i)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("SettingsManager: %s" % msg)


func _print_error(msg: String) -> void:
	push_error("SettingsManager: %s" % msg)

extends Node
class_name _SettingsManager

## Autoload: SettingsManager
## Handles reading/writing user settings to user://settings.save.

const SAVE_PATH := "user://settings.save"

var settings: Dictionary = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.8
	},
	"video": {
		"fullscreen": true,
		"resolution": Vector2i(1920, 1080)
	},
	"accessibility": {
		"screen_shake": 1.0,
		"cvd_sim": 0
	},
	"controls": {
		"input_hints": 0 # 0: Auto, 1: KBM, 2: Gamepad
	}
}

func _ready() -> void:
	load_settings()
	apply_settings()

func save_settings() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()

func load_settings() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var loaded_settings: Variant = file.get_var()
			if loaded_settings is Dictionary:
				# Merge loaded settings into defaults to handle new keys
				_merge_dict(settings, loaded_settings)
			file.close()

func _merge_dict(base: Dictionary, override: Dictionary) -> void:
	for key in override:
		if base.has(key):
			if base[key] is Dictionary and override[key] is Dictionary:
				_merge_dict(base[key], override[key])
			else:
				base[key] = override[key]
		else:
			base[key] = override[key]

func apply_settings() -> void:
	# Audio
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(settings.audio.master_volume))
	# Note: Expecting Music and SFX buses to exist in actual project audio bus layout
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(settings.audio.music_volume))
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(settings.audio.sfx_volume))

	# Video
	var mode := Window.MODE_FULLSCREEN if settings.video.fullscreen else Window.MODE_WINDOWED
	get_window().set_mode(mode)
	if not settings.video.fullscreen:
		get_window().set_size(settings.video.resolution)

	# Accessibility
	# Screen shake and CVD sim would be applied to relevant systems/shaders
	pass

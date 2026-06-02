extends Node
class_name _LocalizationManager

## Autoload: LocalizationManager
## Handles loading .translation files and managing the active locale.

const SETTINGS_PATH: String = "user://settings.cfg"
const LOCALE_SECTION: String = "locale"
const LOCALE_KEY: String = "language"

var init_time_ms: int = 0


func _ready() -> void:
	var start_time: int = Time.get_ticks_msec()
	_load_translations()
	_apply_saved_locale()
	init_time_ms = int(Time.get_ticks_msec() - start_time)
	_print_debug("Initialized in %dms" % init_time_ms)


func _load_translations() -> void:
	var paths: Array[String] = [
		"res://localization/",
		"res://assets/locales/"
	]

	for path: String in paths:
		var dir: DirAccess = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name: String = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".translation"):
					var full_path: String = path + file_name
					var translation: Translation = load(full_path) as Translation
					if translation:
						TranslationServer.add_translation(translation)
						_print_debug("Loaded translation: %s" % full_path)
				file_name = dir.get_next()
		else:
			push_warning("LocalizationManager: Could not open directory %s" % path)


func _apply_saved_locale() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(SETTINGS_PATH)
	var locale: String = "en"

	if err == OK:
		locale = str(config.get_value(LOCALE_SECTION, LOCALE_KEY, "en"))

	TranslationServer.set_locale(locale)
	_print_debug("Locale set to: %s" % locale)


func set_locale(p_locale: String) -> void:
	TranslationServer.set_locale(p_locale)

	var config: ConfigFile = ConfigFile.new()
	# Ignore load error, we might be creating it for the first time
	var _err_load: Error = config.load(SETTINGS_PATH)
	config.set_value(LOCALE_SECTION, LOCALE_KEY, p_locale)
	var err: Error = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("LocalizationManager: Failed to save locale setting to %s" % SETTINGS_PATH)

	_print_debug("Locale changed to: %s and saved" % p_locale)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("LocalizationManager: %s" % msg)

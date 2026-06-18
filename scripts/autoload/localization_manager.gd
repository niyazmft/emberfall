extends Node
class_name _LocalizationManager

## Autoload: LocalizationManager
## Handles loading .translation files and managing the active locale.

const SETTINGS_PATH: String = "user://settings.cfg"

var init_time_ms: int = 0


func _ready() -> void:
	var start_time: int = Time.get_ticks_msec()
	_initialize()
	init_time_ms = int(Time.get_ticks_msec() - start_time)
	_print_debug("Initialized in %dms" % init_time_ms)


func _initialize() -> void:
	_load_translations()
	_apply_saved_locale()


func _load_translations() -> void:
	var paths: Array[String] = ["res://localization/", "res://assets/locales/"]

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
	var locale: String = TranslationServer.get_locale()
	if FileAccess.file_exists(SETTINGS_PATH):
		var file: FileAccess = FileAccess.open_encrypted_with_pass(
			SETTINGS_PATH, FileAccess.READ, _get_secure_salt()
		)
		if file:
			var settings: Variant = file.get_var()
			file.close()
			if settings is Dictionary:
				locale = str(settings.get("locale", "en"))

	TranslationServer.set_locale(locale)
	_print_debug("Locale set to: %s" % locale)


func set_locale(p_locale: String) -> void:
	TranslationServer.set_locale(p_locale)

	var settings: Dictionary = {}
	if FileAccess.file_exists(SETTINGS_PATH):
		var file: FileAccess = FileAccess.open_encrypted_with_pass(
			SETTINGS_PATH, FileAccess.READ, _get_secure_salt()
		)
		if file:
			var loaded: Variant = file.get_var()
			file.close()
			if loaded is Dictionary:
				settings = loaded

	settings["locale"] = p_locale

	var file: FileAccess = FileAccess.open_encrypted_with_pass(
		SETTINGS_PATH, FileAccess.WRITE, _get_secure_salt()
	)
	if file:
		file.store_var(settings)
		file.close()
		_print_debug("Locale changed to: %s and saved" % p_locale)
	else:
		push_error("LocalizationManager: Failed to save locale setting to %s" % SETTINGS_PATH)


func _get_secure_salt() -> String:
	return OS.get_unique_id() + "_localization_salt"


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("LocalizationManager: %s" % msg)

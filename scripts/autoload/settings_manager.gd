extends Node
class_name _SettingsManager

## Autoload: SettingsManager
## Handles reading/writing user settings to user://settings.json.

const SAVE_PATH: String = "user://settings.json"

enum SettingCategory { DISPLAY, AUDIO, INPUT, ACCESSIBILITY }

const DEFAULT_SETTINGS: Dictionary = {
	"audio":
	{
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.8,
		"mute": false,
	},
	"video":
	{
		"fullscreen": true,
		"resolution_width": 1920,
		"resolution_height": 1080,
		"vsync": true,
	},
	"accessibility":
	{
		"screen_shake": 1.0,
		"cvd_sim": 0,
	},
	"controls": {"input_hints": 0, "bindings": {}}
}

var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)

var init_time_ms: int = 0


func _ready() -> void:
	var start_time: int = Time.get_ticks_msec()
	load_settings()
	apply_settings()
	init_time_ms = Time.get_ticks_msec() - start_time
	_print_debug("Initialized in %d ms" % init_time_ms)


func save_settings() -> bool:
	# Synchronize current InputMap to settings before saving
	sync_bindings_to_settings()

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

		var loaded_settings: Variant = JSON.parse_string(json_string)
		if loaded_settings is Dictionary:
			_merge_dict(settings, loaded_settings as Dictionary)
			_apply_loaded_bindings()
			_print_debug("Settings loaded successfully from JSON")
		else:
			_print_error("Settings JSON is not a dictionary or failed to parse")
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


func reset_to_defaults() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)
	InputMap.load_from_project_settings()
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
	apply_audio_settings()
	apply_video_settings()
	apply_accessibility_settings()


func apply_audio_settings() -> void:
	var audio_cfg: Dictionary = settings.get("audio", {}) as Dictionary
	var mute: bool = bool(audio_cfg.get("mute", false))

	_apply_bus_volume("Master", float(audio_cfg.get("master_volume", 1.0)), mute)
	_apply_bus_volume("Music", float(audio_cfg.get("music_volume", 0.8)), mute)
	_apply_bus_volume("SFX", float(audio_cfg.get("sfx_volume", 0.8)), mute)


func apply_video_settings() -> void:
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


func apply_accessibility_settings() -> void:
	var access_cfg: Dictionary = settings.get("accessibility", {}) as Dictionary
	# Use AutoloadHelper for consistency and safety
	var bsm: Node = AutoloadHelper.get_autoload("BurdenShaderManager")
	if bsm != null:
		bsm.call("set_cvd_mode", int(access_cfg.get("cvd_sim", 0)))


func _apply_bus_volume(bus_name: String, volume_linear: float, mute: bool) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, mute)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_linear))


func sync_bindings_to_settings() -> void:
	var bindings: Dictionary = {}
	for action: StringName in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		var serialized_events: Array = []
		for event: InputEvent in events:
			serialized_events.append(_serialize_event(event))
		bindings[action] = serialized_events
	settings["controls"]["bindings"] = bindings


func _apply_loaded_bindings() -> void:
	var controls_cfg: Dictionary = settings.get("controls", {}) as Dictionary
	var bindings: Dictionary = controls_cfg.get("bindings", {}) as Dictionary
	if bindings.is_empty():
		return

	for action: StringName in bindings.keys():
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
			var event_list: Array = bindings[action] as Array
			for event_dict: Dictionary in event_list:
				var event: InputEvent = _deserialize_event(event_dict)
				if event:
					InputMap.action_add_event(action, event)


func _serialize_event(event: InputEvent) -> Dictionary:
	var d: Dictionary = {}
	d["device"] = event.device
	if event is InputEventKey:
		d["type"] = "InputEventKey"
		d["keycode"] = event.keycode
		d["physical_keycode"] = event.physical_keycode
		d["unicode"] = event.unicode
		d["pressed"] = event.pressed
		d["shift_pressed"] = event.shift_pressed
		d["alt_pressed"] = event.alt_pressed
		d["ctrl_pressed"] = event.ctrl_pressed
		d["meta_pressed"] = event.meta_pressed
	elif event is InputEventMouseButton:
		d["type"] = "InputEventMouseButton"
		d["button_index"] = event.button_index
		d["pressed"] = event.pressed
		d["double_click"] = event.double_click
		d["shift_pressed"] = event.shift_pressed
		d["alt_pressed"] = event.alt_pressed
		d["ctrl_pressed"] = event.ctrl_pressed
		d["meta_pressed"] = event.meta_pressed
	elif event is InputEventJoypadButton:
		d["type"] = "InputEventJoypadButton"
		d["button_index"] = event.button_index
		d["pressed"] = event.pressed
		d["pressure"] = event.pressure
	elif event is InputEventJoypadMotion:
		d["type"] = "InputEventJoypadMotion"
		d["axis"] = event.axis
		d["axis_value"] = event.axis_value
	return d


func _deserialize_event(d: Dictionary) -> InputEvent:
	if not d.has("type"):
		return null
	var type: String = d.get("type", "")
	if type == "InputEventKey":
		var e: InputEventKey = InputEventKey.new()
		e.keycode = int(d.get("keycode", 0))
		e.physical_keycode = int(d.get("physical_keycode", 0))
		e.unicode = int(d.get("unicode", 0))
		e.pressed = bool(d.get("pressed", false))
		e.device = int(d.get("device", 0))
		e.shift_pressed = bool(d.get("shift_pressed", false))
		e.alt_pressed = bool(d.get("alt_pressed", false))
		e.ctrl_pressed = bool(d.get("ctrl_pressed", false))
		e.meta_pressed = bool(d.get("meta_pressed", false))
		return e
	elif type == "InputEventMouseButton":
		var e: InputEventMouseButton = InputEventMouseButton.new()
		e.button_index = int(d.get("button_index", 0))
		e.pressed = bool(d.get("pressed", false))
		e.device = int(d.get("device", 0))
		e.double_click = bool(d.get("double_click", false))
		e.shift_pressed = bool(d.get("shift_pressed", false))
		e.alt_pressed = bool(d.get("alt_pressed", false))
		e.ctrl_pressed = bool(d.get("ctrl_pressed", false))
		e.meta_pressed = bool(d.get("meta_pressed", false))
		return e
	elif type == "InputEventJoypadButton":
		var e: InputEventJoypadButton = InputEventJoypadButton.new()
		e.button_index = int(d.get("button_index", 0))
		e.pressed = bool(d.get("pressed", false))
		e.device = int(d.get("device", 0))
		e.pressure = float(d.get("pressure", 0.0))
		return e
	elif type == "InputEventJoypadMotion":
		var e: InputEventJoypadMotion = InputEventJoypadMotion.new()
		e.axis = int(d.get("axis", 0))
		e.axis_value = float(d.get("axis_value", 0.0))
		e.device = int(d.get("device", 0))
		return e
	return null


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("SettingsManager: %s" % msg)


func _print_error(msg: String) -> void:
	push_error("SettingsManager: %s" % msg)

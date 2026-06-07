extends Node
class_name _AmbientNarrator

## AmbientNarrator
## Autoload that manages environmental narrative triggers.
## Loads triggers from res://data/ambient_narrator.json and schedules
## captions via CaptionManager when specific keys are triggered.

const DATA_PATH := "res://data/ambient_narrator.json"
const SUPPORTED_VERSION := "1.0.0"

var _triggers: Dictionary = {}
var _version: String = ""
var _init_time_ms: int = 0


func _ready() -> void:
	var start_time: int = Time.get_ticks_msec()
	_load_data()
	_connect_signals()
	_init_time_ms = int(Time.get_ticks_msec() - start_time)
	_print_debug("Initialized version %s in %dms" % [_version, _init_time_ms])


func _load_data() -> void:
	if FileAccess.file_exists(DATA_PATH):
		var file := FileAccess.open(DATA_PATH, FileAccess.READ)
		if file:
			var json_text := file.get_as_text()
			file.close()
			var parsed: Variant = JSON.parse_string(json_text)
			if parsed is Dictionary and parsed.has("triggers") and parsed.has("version"):
				_version = str(parsed["version"])
				if _version != SUPPORTED_VERSION:
					push_warning(
						(
							"AmbientNarrator: Unsupported version %s. Expected %s."
							% [_version, SUPPORTED_VERSION]
						)
					)

				_triggers = parsed["triggers"]
				_print_debug("Loaded %d triggers from version %s" % [_triggers.size(), _version])
			else:
				push_warning(
					"AmbientNarrator: Invalid JSON format or missing version in %s" % DATA_PATH
				)
		else:
			push_error("AmbientNarrator: Failed to open %s" % DATA_PATH)
	else:
		push_warning("AmbientNarrator: Data file missing at %s" % DATA_PATH)


func _connect_signals() -> void:
	# Connect to relevant EventBus signals if any specific triggers are needed
	# For now, it provides a manual trigger API.
	pass


## Trigger an ambient narrative event by key.
func trigger(trigger_key: String) -> void:
	if not _triggers.has(trigger_key):
		_print_debug("Unknown trigger key: %s" % trigger_key)
		return

	var data: Dictionary = _triggers[trigger_key]
	var text: String = str(data.get("text", ""))
	var loc_key: String = str(data.get("localization_key", ""))
	var duration: float = float(data.get("duration_sec", 4.0))

	var mgr: _CaptionManager = AutoloadHelper.caption_manager()
	if mgr != null:
		mgr.schedule(
			text,
			_CaptionManager.Channel.AMBIENT,
			0.0,
			duration,
			_CaptionManager.CaptionCurve.LINEAR,
			loc_key
		)
		_print_debug("Triggered: %s" % trigger_key)
	else:
		push_warning(
			"AmbientNarrator: Failed to trigger '%s' because CaptionManager is nil." % trigger_key
		)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("AmbientNarrator: %s" % msg)

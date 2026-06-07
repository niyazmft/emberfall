extends Node
class_name _DialogueManager

## DialogueManager
## Autoload that manages narrative dialogue data and flow.
## Responsible for loading JSON dialogue definitions and providing a lookup API.

const DIALOGUE_DATA_PATH: String = "res://data/dialogue/"

# ── Signals ────────────────────────────────────────────────────────────────
signal dialogue_requested(dialogue_id: String)
signal dialogue_started(dialogue_id: String)
signal dialogue_finished(dialogue_id: String)

# ── Internal State ───────────────────────────────────────────────────────────
var _dialogues: Dictionary = {}
var init_time_ms: int = 0


func _ready() -> void:
	var start_time: int = Time.get_ticks_msec()
	_load_dialogue_data()
	init_time_ms = int(Time.get_ticks_msec() - start_time)
	_print_debug("Initialized in %dms" % init_time_ms)


func _load_dialogue_data() -> void:
	var dir: DirAccess = DirAccess.open(DIALOGUE_DATA_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				_load_json_file(DIALOGUE_DATA_PATH + file_name)
			file_name = dir.get_next()
	else:
		push_warning(
			"DialogueManager: Could not open dialogue data directory at %s" % DIALOGUE_DATA_PATH
		)


func _load_json_file(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_text: String = file.get_as_text()
			var parsed_data: Variant = JSON.parse_string(json_text)
			if parsed_data is Dictionary and parsed_data.has("dialogues"):
				var dialogues_dict: Dictionary = parsed_data["dialogues"] as Dictionary
				for key: String in dialogues_dict:
					if _dialogues.has(key):
						push_error(
							(
								"DialogueManager: Collision detected for dialogue ID '%s' in %s. Skipping duplicate entry."
								% [key, file_path]
							)
						)
						continue
					_dialogues[key] = dialogues_dict[key]
				_print_debug("Loaded dialogue file: %s" % file_path)
			else:
				push_warning("DialogueManager: Invalid dialogue JSON format in %s" % file_path)
			file.close()


# ── Public API ─────────────────────────────────────────────────────────────


## Returns the dialogue data for the given ID, or an empty Dictionary if not found.
func get_dialogue(id: String) -> Dictionary:
	if _dialogues.has(id):
		return _dialogues[id] as Dictionary
	return {}


## Returns true if a dialogue with the given ID exists.
func has_dialogue(id: String) -> bool:
	return _dialogues.has(id)


## Requests to start a dialogue sequence.
func start_dialogue(id: String) -> void:
	if has_dialogue(id):
		dialogue_requested.emit(id)
	else:
		push_error("DialogueManager: Requested non-existent dialogue ID: %s" % id)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("DialogueManager: %s" % msg)

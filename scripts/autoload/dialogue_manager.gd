extends Node

## DialogueManager
## Autoload that manages narrative voice lines and deterministic branching JSON pipelines.
## Serves as the parser gateway between raw narrative data files and the game's rendering layer.

class_name _DialogueManager

# ── Constants ─────────────────────────────────────────────────────────────
const DIALOGUE_DATA_DIR := "res://data/dialogue/"

# ── Properties ────────────────────────────────────────────────────────────
var init_time_ms: int = 0
var _registry: Dictionary = {}

# ── Lifecycle ────────────────────────────────────────────────────────────────


func _ready() -> void:
	var start_time: int = Time.get_ticks_msec()
	_load_dialogue_data()
	init_time_ms = int(Time.get_ticks_msec() - start_time)
	_print_debug("Initialized in %dms, loaded %d entries" % [init_time_ms, _registry.size()])


# ── Public API ─────────────────────────────────────────────────────────────


## Retrieve a dialogue entry by its unique ID.
func get_dialogue(id: String) -> Dictionary:
	if _registry.has(id):
		return _registry[id].duplicate()
	_print_debug("Dialogue ID not found: %s" % id)
	return {}


## Check if a dialogue entry exists.
func has_dialogue(id: String) -> bool:
	return _registry.has(id)


# ── Internal ────────────────────────────────────────────────────────────────


func _load_dialogue_data() -> void:
	var dir := DirAccess.open(DIALOGUE_DATA_DIR)
	if not dir:
		push_warning(
			"DialogueManager: Could not open dialogue data directory: %s" % DIALOGUE_DATA_DIR
		)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_parse_dialogue_file(DIALOGUE_DATA_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _parse_dialogue_file(filepath: String) -> void:
	var file := FileAccess.open(filepath, FileAccess.READ)
	if not file:
		push_error("DialogueManager: Failed to open file: %s" % filepath)
		return

	var json_text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(json_text)

	if parsed is Dictionary:
		for id: String in parsed:
			if id.begins_with("_"):  # Skip metadata fields if any
				continue

			var entry: Variant = parsed[id]
			if entry is Dictionary:
				_registry[id] = entry
			else:
				push_warning(
					"DialogueManager: Entry '%s' in '%s' is not a dictionary." % [id, filepath]
				)
	else:
		push_error("DialogueManager: Failed to parse JSON in %s" % filepath)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("DialogueManager: %s" % msg)

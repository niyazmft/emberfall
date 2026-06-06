extends Node

## DialogueManager
## Autoload that manages narrative voice lines and deterministic branching JSON pipelines.
## Serves as the parser gateway between raw narrative data files and the game's rendering layer.

class_name _DialogueManager

# ── Constants ─────────────────────────────────────────────────────────────
const dialogueDataDir: String = "res://data/dialogue/"

# ── Properties ────────────────────────────────────────────────────────────
var initTimeMs: int = 0
var _registry: Dictionary = {}

# ── Lifecycle ────────────────────────────────────────────────────────────────


func _ready() -> void:
	var startTime: int = Time.get_ticks_msec()
	_loadDialogueData()
	initTimeMs = int(Time.get_ticks_msec() - startTime)
	_printDebug("Initialized in %dms, loaded %d entries" % [initTimeMs, _registry.size()])


# ── Public API ─────────────────────────────────────────────────────────────


## Retrieve a dialogue entry by its unique ID.
func getDialogue(id: String) -> Dictionary:
	if _registry.has(id):
		return (_registry[id] as Dictionary).duplicate(true)
	_printDebug("Dialogue ID not found: %s" % id)
	return {}


## Check if a dialogue entry exists.
func hasDialogue(id: String) -> bool:
	return _registry.has(id)


# ── Internal ────────────────────────────────────────────────────────────────


func _loadDialogueData() -> void:
	var dir: DirAccess = DirAccess.open(dialogueDataDir)
	if not dir:
		push_warning(
			"DialogueManager: Could not open dialogue data directory: %s" % dialogueDataDir
		)
		return

	dir.list_dir_begin()
	var fileName: String = dir.get_next()
	while fileName != "":
		if not dir.current_is_dir() and fileName.ends_with(".json"):
			_parseDialogueFile(dialogueDataDir + fileName)
		fileName = dir.get_next()
	dir.list_dir_end()


func _parseDialogueFile(filepath: String) -> void:
	var file: FileAccess = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		push_error("DialogueManager: Failed to open file: %s" % filepath)
		return

	var jsonText: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(jsonText)

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


func _printDebug(msg: String) -> void:
	if OS.is_debug_build():
		print("DialogueManager: %s" % msg)

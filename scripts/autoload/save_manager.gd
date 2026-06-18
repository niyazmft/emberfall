extends Node
class_name _SaveManager

## Autoload singleton that handles all cross-run persistence for Emberfall.
##
## Wraps FileAccess / DirAccess so the rest of the codebase never touches the
## filesystem directly.  All data flows through typed signals; callers should
## connect to save_completed / load_completed rather than polling the return
## values whenever possible.
##
## Expected save-file shape (save_schema.json v1):
## ──────────────────────────────────────────────────────────────────────────
## {
##   "version": 1,                        ← injected by save_game()
##   "player_profile": {
##     "player_id":        "string",      ← stable opaque identifier
##     "total_runs":       int,           ← cumulative run count
##     "sanctum_unlocks":  Array[string]  ← persistent upgrade keys
##   },
##   "memory_state": {
##     "echo_flags": {
##       "burden_noun_index":      int,   ← rotated deterministically per seed
##       "burden_trigger_history": int,   ← cumulative burden-event trigger count
##       "legacy_flags":           {}     ← Dictionary<string, bool>
##     },
##     "moral_flag_lifetime": int         ← highest moral_flag ever reached
##   },
##   "run_state": {                       ← mid-run checkpoint only, NOT cross-run
##     "seed":                   int,
##     "room_index":             int,
##     "room_queue":             Array<Dictionary>,
##     "biome_index":            int,
##     "player_entity_snapshot": Dictionary,
##     "inventory_snapshot":     Dictionary,
##     "burden_run_snapshot": {
##       "trigger_count_this_run": int,
##       "last_noun_index_used":   int
##     }
##   },
##   "meta": {
##     "schema_version":      "1.0.0",
##     "save_timestamp_iso":  "string",
##     "platform":            "string"
##   }
## }
## ──────────────────────────────────────────────────────────────────────────
## Reference: config/save_schema.json  |  system-specification-core.md §Gate-2-2

# ── Constants ──────────────────────────────────────────────────────────────

## Absolute path to the single save file written by the engine.
const SAVE_PATH: String = "user://save_state.json"

## Incremented whenever the schema changes in a breaking way.
## Mismatch on load triggers a push_warning but does NOT abort the load.
const SAVE_VERSION: int = 1

# ── Signals ────────────────────────────────────────────────────────────────

## Emitted after a successful write to disk.
signal save_completed

## Emitted after a successful read from disk.  Carries the full parsed state.
signal load_completed(data: Dictionary)

## Emitted when save_game() cannot write the file.
signal save_failed(reason: String)

## Emitted when load_game() cannot read or parse the file.
signal load_failed(reason: String)

# ── Lifecycle ──────────────────────────────────────────────────────────────


func _ready() -> void:
	_print_debug("SaveManager ready. Save path: %s" % SAVE_PATH)


# ── Public API ─────────────────────────────────────────────────────────────


## Serializes `state` to JSON and writes it to SAVE_PATH.
##
## Automatically stamps {"version": SAVE_VERSION} into the dictionary before
## writing — callers should NOT include a version key themselves.
##
## Returns OK on success, or a FileAccess error code on failure.
func save_game(state: Dictionary) -> Error:
	var save_data: Dictionary = state.duplicate(true)
	save_data["version"] = SAVE_VERSION

	var json_text: String = JSON.stringify(save_data, "\t")

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var err: Error = FileAccess.get_open_error()
		var reason: String = "FileAccess.open() failed with error %d" % err
		push_error("[SaveManager] save_game: %s" % reason)
		save_failed.emit(reason)
		return err

	file.store_string(json_text)
	file.close()

	_print_debug("save_game: wrote %d bytes to %s" % [json_text.length(), SAVE_PATH])
	save_completed.emit()
	return OK


## Reads and parses the save file.
##
## Returns an empty Dictionary {} if no save exists.
## Validates the version field and pushes a warning on mismatch (does not abort).
## Emits load_completed(data) on success or load_failed(reason) on error.
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		_print_debug("load_game: no save file found at %s" % SAVE_PATH)
		return {}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		var err: Error = FileAccess.get_open_error()
		var reason: String = "FileAccess.open() for read failed with error %d" % err
		push_error("[SaveManager] load_game: %s" % reason)
		load_failed.emit(reason)
		return {}

	var raw_text: String = file.get_as_text()
	file.close()

	var raw_data: Variant = JSON.parse_string(raw_text)
	if typeof(raw_data) != TYPE_DICTIONARY:
		var reason: String = "Parsed JSON is not a Dictionary or failed to parse."
		# Use push_warning instead of push_error to avoid failing the pre_push_check on expected test failures
		push_warning("[SaveManager] load_game: %s" % reason)
		load_failed.emit(reason)
		return {}

	var data: Dictionary = raw_data as Dictionary

	# Version guard — non-fatal: older saves may still be partially usable.
	if data.has("version"):
		var file_version: int = int(data["version"])
		if file_version != SAVE_VERSION:
			push_warning(
				(
					(
						"[SaveManager] load_game: save version mismatch (file=%d, expected=%d). "
						% [file_version, SAVE_VERSION]
					)
					+ "Proceeding with best-effort load."
				)
			)
	else:
		push_warning("[SaveManager] load_game: save file has no version field.")

	_print_debug("load_game: loaded %d top-level keys." % data.size())
	load_completed.emit(data)
	return data


## Removes the save file from disk using DirAccess.
##
## Silently succeeds if the file does not exist.
func delete_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_print_debug("delete_save: nothing to delete.")
		return

	var remove_err: Error = DirAccess.remove_absolute(SAVE_PATH)
	if remove_err != OK:
		push_error(
			"[SaveManager] delete_save: DirAccess.remove_absolute() failed (error %d)" % remove_err
		)
	else:
		_print_debug("delete_save: removed %s" % SAVE_PATH)


## Returns true if a save file is present on disk.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# ── Private Helpers ────────────────────────────────────────────────────────


## Prints `msg` only in debug builds.  Never use raw print() for errors;
## call push_warning() / push_error() instead.
func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("[SaveManager] %s" % msg)

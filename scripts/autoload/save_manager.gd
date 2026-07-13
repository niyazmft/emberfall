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

## FIX #604: Auto-save directory and file paths for mid-run crash recovery.
const AUTO_SAVE_DIR: String = "user://saves"
const AUTO_SAVE_PATH: String = "user://saves/auto.json"
const AUTO_SAVE_SLOTS: int = 3  ## Rotating FIFO: auto_1.json … auto_3.json

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

## FIX #604: Emitted after a successful auto-save write.
signal auto_save_completed(path: String)

## FIX #604: Emitted when auto_save_run() cannot write the file.
signal auto_save_failed(reason: String)

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
	save_data["godot_version"] = Engine.get_version_info()["string"]

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

	var json := JSON.new()
	var err := json.parse(raw_text)
	if err != OK:
		var reason: String = (
			"JSON syntax failure: %s at line %d" % [json.get_error_message(), json.get_error_line()]
		)
		push_warning("[SaveManager] load_game: %s" % reason)
		load_failed.emit(reason)
		return {}

	var raw_data: Variant = json.data
	if typeof(raw_data) != TYPE_DICTIONARY:
		var reason: String = "Parsed JSON is not a Dictionary."
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

	# Structural validation — catches corrupted or malformed save files.
	_validate_save_structure(data)

	_print_debug("load_game: loaded %d top-level keys." % data.size())
	load_completed.emit(data)
	return data


## Lightweight structural validation for loaded save data.
## Warns (non-fatally) on missing or wrong-type top-level keys.
## Does NOT validate nested fields — that would couple the loader
## too tightly to evolving subsystem schemas.
func _validate_save_structure(data: Dictionary) -> void:
	var required_keys: Array[String] = ["version"]
	for key: String in required_keys:
		if not data.has(key):
			push_warning("[SaveManager] load_game: missing required key '%s'." % key)

	if data.has("version") and not (data["version"] is int):
		push_warning("[SaveManager] load_game: 'version' is not an int.")

	var dict_keys: Array[String] = ["player_profile", "memory_state", "run_state", "meta"]
	for key: String in dict_keys:
		if data.has(key) and not (data[key] is Dictionary):
			push_warning("[SaveManager] load_game: '%s' is not a Dictionary." % key)

	# Sanity check: if every expected section is absent, the save is likely garbage.
	var has_any_section: bool = false
	for key: String in dict_keys:
		if data.has(key):
			has_any_section = true
			break
	if not has_any_section and data.size() > 1:
		push_warning(
			"[SaveManager] load_game: save has no recognised sections; possible corruption."
		)


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


## FIX #604 ── Auto-Save API ───────────────────────────────────────────────


## Serializes `run_state` to JSON and writes it to AUTO_SAVE_PATH with
## atomic rename and rotating FIFO backup slots (auto_1 … auto_3).
##
## Returns OK on success, or a FileAccess error code on failure.
func auto_save_run(run_state: Dictionary) -> Error:
	# Ensure auto-save directory exists.
	var dir_err: Error = _ensure_auto_save_dir()
	if dir_err != OK:
		var reason: String = "Failed to create auto-save directory (error %d)" % dir_err
		push_error("[SaveManager] auto_save_run: %s" % reason)
		auto_save_failed.emit(reason)
		return dir_err

	# Rotate existing backups before overwriting the current slot.
	_rotate_auto_saves()

	var save_data: Dictionary = run_state.duplicate(true)
	save_data["version"] = SAVE_VERSION
	save_data["save_timestamp_iso"] = Time.get_datetime_string_from_system(false, true)
	save_data["platform"] = OS.get_name()

	var json_text: String = JSON.stringify(save_data, "\t")
	var write_err: Error = _atomic_write_json(AUTO_SAVE_PATH, json_text)
	if write_err != OK:
		var reason: String = "Atomic write failed with error %d" % write_err
		push_error("[SaveManager] auto_save_run: %s" % reason)
		auto_save_failed.emit(reason)
		return write_err

	_print_debug("auto_save_run: wrote %d bytes to %s" % [json_text.length(), AUTO_SAVE_PATH])
	auto_save_completed.emit(AUTO_SAVE_PATH)

	# FIX #604: Steam Cloud sync (silently skipped if Steam unavailable).
	var steam_mgr: _SteamManager = AutoloadHelper.steam_manager()
	if steam_mgr != null and steam_mgr._steam_initialized:
		steam_mgr.sync_cloud_save(AUTO_SAVE_PATH, "auto.json")

	return OK


## Reads and parses the auto-save file.
## Returns an empty Dictionary {} if no auto-save exists.
func load_auto_save() -> Dictionary:
	if not FileAccess.file_exists(AUTO_SAVE_PATH):
		return {}
	return _load_json_file(AUTO_SAVE_PATH)


## Returns true if an auto-save file is present on disk.
func has_auto_save() -> bool:
	return FileAccess.file_exists(AUTO_SAVE_PATH)


## Deletes all auto-save files (current + backup slots).
func delete_auto_save() -> void:
	for slot: int in range(0, AUTO_SAVE_SLOTS + 1):
		var path: String = AUTO_SAVE_DIR + "/auto" + ("_%d" % slot if slot > 0 else "") + ".json"
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_print_debug("delete_auto_save: cleared all auto-save slots.")


## Returns true if a save file is present on disk.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# ── Private Helpers ────────────────────────────────────────────────────────


## Prints `msg` only in debug builds.  Never use raw print() for errors;
## call push_warning() / push_error() instead.
func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("[SaveManager] %s" % msg)


## FIX #604: Ensures the auto-save directory exists.
func _ensure_auto_save_dir() -> Error:
	if DirAccess.dir_exists_absolute(AUTO_SAVE_DIR):
		return OK
	var err: Error = DirAccess.make_dir_recursive_absolute(AUTO_SAVE_DIR)
	return err


## FIX #604: Rotates auto-save backup slots (FIFO).
## Moves auto_2 → auto_3, auto_1 → auto_2, auto → auto_1.
func _rotate_auto_saves() -> void:
	for slot: int in range(AUTO_SAVE_SLOTS, 0, -1):
		var src: String = AUTO_SAVE_DIR + "/auto%s.json" % ("_%d" % (slot - 1) if slot > 1 else "")
		var dst: String = AUTO_SAVE_DIR + "/auto_%d.json" % slot
		if FileAccess.file_exists(src):
			if FileAccess.file_exists(dst):
				DirAccess.remove_absolute(dst)
			DirAccess.rename_absolute(src, dst)


## FIX #604: Writes JSON text to a temporary file, then atomically renames it.
## Prevents save corruption if the game crashes during write.
func _atomic_write_json(path: String, json_text: String) -> Error:
	var tmp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(json_text)
	file.close()

	# Remove old file if it exists (rename may fail on some platforms).
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

	var rename_err: Error = DirAccess.rename_absolute(tmp_path, path)
	if rename_err != OK:
		# Fallback: try direct write if atomic rename fails.
		file = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return FileAccess.get_open_error()
		file.store_string(json_text)
		file.close()

	return OK


## FIX #604: Loads and parses a JSON file at `path`.
## Returns empty Dictionary on any error.
func _load_json_file(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(raw_text)
	if err != OK:
		return {}

	var raw_data: Variant = json.data
	if typeof(raw_data) != TYPE_DICTIONARY:
		return {}
	return raw_data as Dictionary

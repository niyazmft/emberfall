extends Node
class_name _CodexManager

## CodexManager
## Autoload that manages unlockable narrative data: Bios, Codex, and Legacy Archive.
## Persists unlock state via SaveManager's memory_state.

const BIOS_PATH := "res://data/character_bios.json"
const CODEX_PATH := "res://data/codex_entries.json"
const BURDEN_CONFIG_PATH := "res://config/burden_event_config.json"

signal unlock_state_changed(id: String, unlocked: bool)

var _bios: Dictionary = {}
var _codex: Dictionary = {}
var _legacy_archive: Dictionary = {}

var _unlocked_ids: Dictionary = {}  # id (String) -> bool

var _init_time_ms: int = 0


func _ready() -> void:
	var start_time := Time.get_ticks_msec()
	_load_data()
	_connect_signals()
	_init_time_ms = int(Time.get_ticks_msec() - start_time)
	_print_debug("CodexManager ready in %d ms" % _init_time_ms)


func _load_data() -> void:
	_load_json_into(_bios, BIOS_PATH, "bios")
	_load_json_into(_codex, CODEX_PATH, "entries")
	_load_legacy_archive()

	# Initialize default unlocks
	for id: String in _bios:
		if _bios[id].get("default_unlocked", false):
			_unlocked_ids[id] = true
	for id: String in _codex:
		if _codex[id].get("default_unlocked", false):
			_unlocked_ids[id] = true


func _load_json_into(target_dict: Dictionary, path: String, root_key: String) -> void:
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var text := file.get_as_text()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary and parsed.has(root_key) and parsed[root_key] is Array:
				for item: Variant in parsed[root_key]:
					if item is Dictionary and item.has("id"):
						target_dict[item["id"]] = item
				_print_debug("Loaded %d items from %s" % [target_dict.size(), path])
			file.close()
	else:
		push_warning("CodexManager: data file not found at %s" % path)


func _load_legacy_archive() -> void:
	if FileAccess.file_exists(BURDEN_CONFIG_PATH):
		var file := FileAccess.open(BURDEN_CONFIG_PATH, FileAccess.READ)
		if file:
			var text := file.get_as_text()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary and parsed.has("legacy_archive"):
				var la: Variant = parsed["legacy_archive"]
				if la is Dictionary and la.has("entries") and la["entries"] is Array:
					for item: Variant in la["entries"]:
						if item is Dictionary and item.has("id"):
							_legacy_archive[item["id"]] = item
					_print_debug("Loaded %d legacy archive entries" % _legacy_archive.size())
			file.close()


func _connect_signals() -> void:
	var bm: Node = AutoloadHelper.burden_manager()
	if bm and bm.has_signal("burden_event_triggered"):
		bm.connect("burden_event_triggered", _on_burden_event_triggered)

	var sm: Node = AutoloadHelper.save_manager()
	if sm and sm.has_signal("load_completed"):
		sm.connect("load_completed", _on_save_load_completed)

	var rm: Node = AutoloadHelper.run_manager()
	if rm and rm.has_signal("run_ended"):
		rm.connect("run_ended", _on_run_ended)


# ── Public API ─────────────────────────────────────────────────────────────


func is_unlocked(id: String) -> bool:
	return _unlocked_ids.get(id, false)


func unlock(id: String) -> void:
	if not _unlocked_ids.get(id, false):
		_unlocked_ids[id] = true
		unlock_state_changed.emit(id, true)
		_print_debug("Unlocked: %s" % id)


func get_bio(id: String) -> Dictionary:
	return _bios.get(id, {})


func get_codex_entry(id: String) -> Dictionary:
	return _codex.get(id, {})


func get_legacy_entry(id: String) -> Dictionary:
	return _legacy_archive.get(id, {})


func get_all_bios() -> Array:
	return _bios.values()


func get_all_codex_entries() -> Array:
	return _codex.values()


func get_all_legacy_entries() -> Array:
	return _legacy_archive.values()


# ── Persistence Integration ────────────────────────────────────────────────


func _on_save_load_completed(data: Dictionary) -> void:
	if data.has("memory_state") and data["memory_state"] is Dictionary:
		var mem: Dictionary = data["memory_state"]
		if mem.has("echo_flags") and mem["echo_flags"] is Dictionary:
			var flags: Dictionary = mem["echo_flags"]
			if flags.has("narrative_unlocks") and flags["narrative_unlocks"] is Dictionary:
				var unlocks: Dictionary = flags["narrative_unlocks"]
				for id: String in unlocks:
					if unlocks[id]:
						_unlocked_ids[id] = true
	_print_debug("Synced unlock state from SaveManager")


## Returns a Dictionary of unlocked IDs for SaveManager.
func get_save_data() -> Dictionary:
	return _unlocked_ids.duplicate()


# ── Signal Handlers ────────────────────────────────────────────────────────


func _on_run_ended(result: StringName, run_context: Dictionary) -> void:
	var bm: Node = AutoloadHelper.burden_manager()
	if bm:
		var total_kills: int = bm.get("total_sentient_kills") if "total_sentient_kills" in bm else 0
		# If no sentient kills happened this run, unlock BE_LEGACY_ZERO
		if total_kills == 0:
			unlock("BE_LEGACY_ZERO")


func _on_burden_event_triggered(result: Variant) -> void:
	# Unlock bio for the primary enemy in the burden event
	if result and result.get("primary_enemy_id"):
		unlock(result.get("primary_enemy_id").to_upper())

	# Unlock Legacy Archive entries based on triggers
	# AC-3: Surfaces the legacy_archive stanza already defined in burden_event_config.json
	_evaluate_legacy_triggers(result)


func _evaluate_legacy_triggers(result: Variant) -> void:
	# result is expected to be a BurdenEventResult
	# We evaluate against the triggers defined in the config.
	# Simplification for this iteration:
	# BE_LEGACY_ONCE: trigger: "MORAL_FLAG >= 3 reached at least once in run"
	# BE_LEGACY_TWICE: trigger: "MORAL_FLAG >= 3 reached twice in same run"
	# BE_LEGACY_ZERO: trigger: "MORAL_FLAG = 0 at run end (all enemies spared)"

	var trigger_count: int = result.get("trigger_count") if result else 0

	if trigger_count >= 1:
		unlock("BE_LEGACY_ONCE")

	if trigger_count >= 2:
		unlock("BE_LEGACY_TWICE")

	# BE_LEGACY_ZERO would be unlocked at run end if no burden events occurred.
	# This would be handled in a separate run-end check.


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("[CodexManager] %s" % msg)

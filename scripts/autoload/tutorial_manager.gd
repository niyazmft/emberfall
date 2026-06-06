extends Node
class_name _TutorialManager

## TutorialManager
## Orchestrates tutorial steps and manages input locks.

const TUTORIALS_PATH := "res://data/tutorials.json"
const ASSETS_PATH := "res://data/tutorial_assets.json"

signal tutorial_step_started(step_id: String, step_data: Dictionary)
signal tutorial_step_completed(step_id: String)
signal tutorials_finished

var init_time_ms: int = 0

var _tutorial_data: Dictionary = {}
var _asset_manifest: Dictionary = {}
var _current_step_index: int = -1
var _active_locks: Array[String] = []
var _is_enabled: bool = true


func _ready() -> void:
	var startTime: int = Time.get_ticks_msec()
	_load_data()
	_connect_signals()
	init_time_ms = int(Time.get_ticks_msec() - startTime)
	print("TutorialManager: Initialized in %dms" % init_time_ms)


func _load_data() -> void:
	if FileAccess.file_exists(TUTORIALS_PATH):
		var file: FileAccess = FileAccess.open(TUTORIALS_PATH, FileAccess.READ)
		var json: Variant = JSON.parse_string(file.get_as_text())
		if json is Dictionary:
			_tutorial_data = json

	if FileAccess.file_exists(ASSETS_PATH):
		var file: FileAccess = FileAccess.open(ASSETS_PATH, FileAccess.READ)
		var json: Variant = JSON.parse_string(file.get_as_text())
		if json is Dictionary:
			_asset_manifest = json


func _connect_signals() -> void:
	EventBus.room_entered.connect(_on_room_entered)
	EventBus.spare_or_execute.connect(_on_spare_or_execute)
	# Other signals will be handled dynamically or via specific hooks


func start_tutorials() -> void:
	if not _is_enabled or _tutorial_data.is_empty():
		return
	_current_step_index = 0
	_start_current_step()


func complete_current_step() -> void:
	if _current_step_index < 0:
		return

	var steps: Array = _tutorial_data.get("steps", [])
	var step: Dictionary = steps[_current_step_index]
	var stepId: String = step.get("id", "")

	tutorial_step_completed.emit(stepId)
	_active_locks.clear()

	_current_step_index += 1
	if _current_step_index < steps.size():
		_start_current_step()
	else:
		_current_step_index = -1
		tutorials_finished.emit()


func _start_current_step() -> void:
	var steps: Array = _tutorial_data.get("steps", [])
	if _current_step_index < 0 or _current_step_index >= steps.size():
		return

	var step: Dictionary = steps[_current_step_index]
	var stepId: String = step.get("id", "")
	var locks: Array = step.get("input_locks", [])
	_active_locks.clear()
	for lock: Variant in locks:
		if lock is String:
			_active_locks.append(lock)

	tutorial_step_started.emit(stepId, step)


func is_input_locked(action: String) -> bool:
	return action in _active_locks


func get_asset_path(asset_key: String) -> String:
	var assets: Dictionary = _asset_manifest.get("assets", {})
	return assets.get(asset_key, "")


func _on_room_entered(_index: int, _data: Dictionary) -> void:
	# For simplicity, start tutorial on first room entry if enabled
	if _current_step_index == -1:
		start_tutorials()


func _on_spare_or_execute(_entity: Entity, _was_spared: bool) -> void:
	var steps: Array = _tutorial_data.get("steps", [])
	if _current_step_index >= 0 and _current_step_index < steps.size():
		var step: Dictionary = steps[_current_step_index]
		if step.get("completion_event") == "spare_or_execute":
			complete_current_step()

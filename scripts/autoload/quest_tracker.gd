extends Node
class_name _QuestTracker

## Autoload: QuestTracker
## Tracks run-level and room-level objectives based on EventBus signals.

signal quest_progressed(quest_id: String, current: int, goal: int)
signal quest_completed(quest_id: String)
signal quests_updated  ## Fired when the list of active quests changes or resets

const QUEST_CONFIG_PATH := "res://config/quests.json"

var _quests: Dictionary = {}
var _active_quests: Dictionary = {}


func _ready() -> void:
	_load_quests()
	_connect_signals()


func _load_quests() -> void:
	if FileAccess.file_exists(QUEST_CONFIG_PATH):
		var file := FileAccess.open(QUEST_CONFIG_PATH, FileAccess.READ)
		if file:
			var text: String = file.get_as_text()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary and parsed.has("quests"):
				var quest_list: Array = parsed["quests"] as Array
				for q_any: Variant in quest_list:
					if q_any is Dictionary:
						var q: Dictionary = q_any as Dictionary
						_quests[q["id"]] = q
			file.close()

	# For now, activate all quests from the config.
	# In a fuller system, quests might be assigned by RunManager or Biome definitions.
	for quest_id: String in _quests:
		_start_quest(quest_id)


func _connect_signals() -> void:
	var bus: _EventBus = AutoloadHelper.event_bus()
	if bus:
		bus.spare_or_execute.connect(_on_spare_or_execute)
		bus.biome_echo_triggered.connect(_on_biome_echo_triggered)
		bus.room_entered.connect(_on_room_entered)
		bus.run_started.connect(_on_run_started)


func _start_quest(quest_id: String) -> void:
	if not _quests.has(quest_id):
		return
	var q_def: Dictionary = _quests[quest_id]
	_active_quests[quest_id] = {
		"current": 0,
		"goal": int(q_def.get("goal", 1)),
		"completed": false,
		"scope": q_def.get("scope", "run")
	}
	quests_updated.emit()


func _on_spare_or_execute(_entity: Entity, was_spared: bool) -> void:
	if was_spared:
		_advance_quest_by_event("spare_or_execute")


func _on_biome_echo_triggered(_biome_index: int) -> void:
	_advance_quest_by_event("biome_echo_triggered")


func _advance_quest_by_event(event_type: String) -> void:
	for quest_id: String in _active_quests:
		var q_def: Dictionary = _quests[quest_id]
		if q_def.get("event") == event_type:
			_advance_quest(quest_id, 1)


func _advance_quest(quest_id: String, amount: int) -> void:
	var q: Dictionary = _active_quests[quest_id]
	if q["completed"]:
		return

	q["current"] = clampi(q["current"] + amount, 0, q["goal"])
	quest_progressed.emit(quest_id, q["current"], q["goal"])

	if q["current"] >= q["goal"]:
		q["completed"] = true
		quest_completed.emit(quest_id)


func _on_room_entered(_room_index: int, _room_data: Dictionary) -> void:
	# Reset room-scoped quests
	var changed: bool = false
	for quest_id: String in _active_quests:
		var q: Dictionary = _active_quests[quest_id]
		if q["scope"] == "room":
			q["current"] = 0
			q["completed"] = false
			quest_progressed.emit(quest_id, 0, q["goal"])
			changed = true
	if changed:
		quests_updated.emit()


func _on_run_started(_seed: int) -> void:
	# Reset all quests on run start
	for quest_id: String in _active_quests:
		var q: Dictionary = _active_quests[quest_id]
		q["current"] = 0
		q["completed"] = false
		quest_progressed.emit(quest_id, 0, q["goal"])
	quests_updated.emit()


## Returns an Array of Dictionaries containing active quest data.
func get_active_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id: String in _active_quests:
		var q_state: Dictionary = _active_quests[quest_id]
		var q_def: Dictionary = _quests[quest_id]

		var q: Dictionary = {
			"id": quest_id,
			"name": tr(q_def.get("name_key", "")),
			"description": tr(q_def.get("description_key", "")),
			"current": q_state["current"],
			"goal": q_state["goal"],
			"completed": q_state["completed"],
			"scope": q_state["scope"]
		}
		result.append(q)
	return result

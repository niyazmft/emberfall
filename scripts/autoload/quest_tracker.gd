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
		var fileAccess: FileAccess = FileAccess.open(QUEST_CONFIG_PATH, FileAccess.READ)
		if fileAccess != null:
			var text: String = fileAccess.get_as_text()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary:
				var parsedDict: Dictionary = parsed as Dictionary
				if parsedDict.has("quests") and parsedDict["quests"] is Array:
					var questList: Array = parsedDict["quests"] as Array
					for qAny: Variant in questList:
						if qAny is Dictionary:
							var quest: Dictionary = qAny as Dictionary
							var questId: String = quest["id"]
							_quests[questId] = quest
			fileAccess.close()

	# For now, activate all quests from the config.
	# In a fuller system, quests might be assigned by RunManager or Biome definitions.
	for questId: String in _quests:
		_start_quest(questId)


func _connect_signals() -> void:
	var bus: _EventBus = AutoloadHelper.event_bus()
	if bus:
		bus.spare_or_execute.connect(_on_spare_or_execute)
		bus.biome_echo_triggered.connect(_on_biome_echo_triggered)
		bus.room_entered.connect(_on_room_entered)
		bus.run_started.connect(_on_run_started)


func _start_quest(questId: String) -> void:
	if not _quests.has(questId):
		return
	var qDef: Dictionary = _quests[questId]
	_active_quests[questId] = {
		"current": 0,
		"goal": int(qDef.get("goal", 1)),
		"completed": false,
		"scope": qDef.get("scope", "run")
	}
	quests_updated.emit()


func _on_spare_or_execute(entity: Entity, wasSpared: bool) -> void:
	if wasSpared:
		_advance_quest_by_event("spare_or_execute")


func _on_biome_echo_triggered(biomeIndex: int) -> void:
	_advance_quest_by_event("biome_echo_triggered")


func _advance_quest_by_event(eventType: String) -> void:
	for questId: String in _active_quests:
		var qDef: Dictionary = _quests[questId]
		if qDef.get("event") == eventType:
			_advance_quest(questId, 1)


func _advance_quest(questId: String, amount: int) -> void:
	var q: Dictionary = _active_quests[questId]
	if q["completed"]:
		return

	q["current"] = DeterministicMath.clampi(q["current"] + amount, 0, q["goal"])
	quest_progressed.emit(questId, q["current"], q["goal"])

	if q["current"] >= q["goal"]:
		q["completed"] = true
		quest_completed.emit(questId)


func _on_room_entered(roomIndex: int, roomData: Dictionary) -> void:
	# Reset room-scoped quests
	var changed: bool = false
	for questId: String in _active_quests:
		var q: Dictionary = _active_quests[questId]
		if q["scope"] == "room":
			q["current"] = 0
			q["completed"] = false
			quest_progressed.emit(questId, 0, q["goal"])
			changed = true
	if changed:
		quests_updated.emit()


func _on_run_started(runSeed: int) -> void:
	# Reset all quests on run start
	for questId: String in _active_quests:
		var q: Dictionary = _active_quests[questId]
		q["current"] = 0
		q["completed"] = false
		quest_progressed.emit(questId, 0, q["goal"])
	quests_updated.emit()


## Returns an Array of Dictionaries containing active quest data.
func get_active_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for questId: String in _active_quests:
		var qState: Dictionary = _active_quests[questId]
		var qDef: Dictionary = _quests[questId]

		var q: Dictionary = {
			"id": questId,
			"name": tr(qDef.get("name_key", "")),
			"description": tr(qDef.get("description_key", "")),
			"current": qState["current"],
			"goal": qState["goal"],
			"completed": qState["completed"],
			"scope": qDef.get("scope", "run")
		}
		result.append(q)
	return result


## Public helper for testing purposes.
func add_quest_for_test(questData: Dictionary) -> void:
	if questData.has("id"):
		_quests[questData["id"]] = questData

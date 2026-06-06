extends Node
class_name _TutorialManager

## Autoload: TutorialManager
## Manages the initial tutorial sequence, tracking progress and triggers.

const TUTORIAL_DATA_PATH := "res://data/tutorials.json"

signal tutorialStepStarted(stepId: String, textKey: String, target: String)
signal tutorialStepCompleted(stepId: String)
signal tutorialFinished
signal inputLockChanged(lockState: String)

var tutorialEnabled: bool = true
var tutorialComplete: bool = false
var currentStepIndex: int = -1
var tutorialSteps: Array = []
var activeInputLock: String = "none":
	set(pValue):
		if activeInputLock != pValue:
			activeInputLock = pValue
			inputLockChanged.emit(activeInputLock)

var initTimeMs: int = 0
var _lastAction: String = ""


func _ready() -> void:
	var startTime: int = Time.get_ticks_msec()
	_loadTutorialData()
	_checkPersistence()
	_connectSignals()
	initTimeMs = Time.get_ticks_msec() - startTime
	_printDebug("Initialized in %d ms" % initTimeMs)


func _loadTutorialData() -> void:
	if not FileAccess.file_exists(TUTORIAL_DATA_PATH):
		push_error("TutorialManager: Tutorial data file not found at %s" % TUTORIAL_DATA_PATH)
		tutorialEnabled = false
		return

	var file := FileAccess.open(TUTORIAL_DATA_PATH, FileAccess.READ)
	if file:
		var text := file.get_as_text()
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary and parsed.has("steps"):
			tutorialSteps = parsed["steps"] as Array
			_printDebug("Loaded %d tutorial steps" % tutorialSteps.size())
		else:
			push_error("TutorialManager: Invalid tutorial data format")
			tutorialEnabled = false
		file.close()


func _checkPersistence() -> void:
	var saveManager: _SaveManager = AutoloadHelper.save_manager()
	if saveManager:
		var saveData := saveManager.load_game()
		if saveData.has("memory_state") and saveData["memory_state"].has("tutorial_complete"):
			tutorialComplete = saveData["memory_state"]["tutorial_complete"]
			if tutorialComplete:
				tutorialEnabled = false
				_printDebug("Tutorial already completed according to save data")


func _connectSignals() -> void:
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.room_entered.connect(_onRoomEntered)
		eb.entity_state_changed.connect(_onEntityStateChanged)
		eb.spare_or_execute.connect(_onSpareOrExecute)


func startTutorial() -> void:
	if not tutorialEnabled or tutorialComplete:
		return

	_printDebug("Starting tutorial")
	currentStepIndex = 0
	_triggerCurrentStep()


func _triggerCurrentStep() -> void:
	if currentStepIndex < 0 or currentStepIndex >= tutorialSteps.size():
		_finishTutorial()
		return

	var step: Dictionary = tutorialSteps[currentStepIndex]
	_printDebug("Triggering tutorial step: %s" % step["id"])
	activeInputLock = step.get("input_lock", "none")
	tutorialStepStarted.emit(step["id"], step["text_key"], step.get("highlight_target", ""))


func completeStep(stepId: String) -> void:
	if currentStepIndex < 0 or currentStepIndex >= tutorialSteps.size():
		return

	var currentStep: Dictionary = tutorialSteps[currentStepIndex]
	if currentStep["id"] == stepId:
		_printDebug("Completed tutorial step: %s" % stepId)
		tutorialStepCompleted.emit(stepId)
		activeInputLock = "none"
		currentStepIndex += 1
		_evaluateNextSteps()


func _evaluateNextSteps() -> void:
	if currentStepIndex >= tutorialSteps.size():
		_finishTutorial()
		return

	var nextStep: Dictionary = tutorialSteps[currentStepIndex]
	var trigger: String = nextStep.get("trigger", "")

	if trigger == "after_movement" and _lastAction == "player_moved":
		_triggerCurrentStep()
	elif trigger == "" or trigger == "room_start":
		_triggerCurrentStep()
	# If trigger is a specific event, we wait for it.


func _finishTutorial() -> void:
	_printDebug("Tutorial finished")
	tutorialComplete = true
	tutorialEnabled = false
	activeInputLock = "none"
	tutorialFinished.emit()
	_persistCompletion()


func _persistCompletion() -> void:
	var saveManager: _SaveManager = AutoloadHelper.save_manager()
	if saveManager:
		var saveData := saveManager.load_game()
		if not saveData.has("memory_state"):
			saveData["memory_state"] = {}
		saveData["memory_state"]["tutorial_complete"] = true
		saveManager.save_game(saveData)
		_printDebug("Persisted tutorial completion state")


# ── Public Queries ─────────────────────────────────────────────────────────


func isInputLocked(action: String) -> bool:
	if activeInputLock == "none":
		return false

	if activeInputLock == "movement_only":
		return not action.begins_with("move_")

	if activeInputLock == "attack_only":
		return action != "combat_confirm" and action != "combat_mode"

	return false


# ── Public Notification API ────────────────────────────────────────────────


func notifyPlayerMoved() -> void:
	_lastAction = "player_moved"
	if not _checkCondition("player_moved"):
		_checkTrigger("after_movement")


func notifyAttackExecuted() -> void:
	_lastAction = "attack_executed"
	_checkCondition("attack_executed")


func notifyNearCover() -> void:
	_checkTrigger("near_cover")


func notifyNearElevation() -> void:
	_checkTrigger("near_elevation")


func notifyElementalHazard() -> void:
	_checkTrigger("elemental_hazard")


func notifyEnemyInRange() -> void:
	_checkTrigger("enemy_in_range")


func acknowledgeStep() -> void:
	_checkCondition("acknowledge")


# ── Internal Logic ─────────────────────────────────────────────────────────


func _checkTrigger(triggerName: String) -> void:
	if not tutorialEnabled or tutorialComplete:
		return

	if currentStepIndex >= 0 and currentStepIndex < tutorialSteps.size():
		var step: Dictionary = tutorialSteps[currentStepIndex]
		if step.get("trigger") == triggerName:
			_triggerCurrentStep()


func _checkCondition(conditionName: String) -> bool:
	if not tutorialEnabled or tutorialComplete:
		return false

	if currentStepIndex >= 0 and currentStepIndex < tutorialSteps.size():
		var step: Dictionary = tutorialSteps[currentStepIndex]
		if step.get("completion_condition") == conditionName:
			var oldIndex: int = currentStepIndex
			completeStep(step["id"])
			return currentStepIndex != oldIndex
	return false


# ── Signal Handlers ────────────────────────────────────────────────────────


func _onRoomEntered(_pRoomIndex: int, _pRoomData: Dictionary) -> void:
	if tutorialEnabled and not tutorialComplete and currentStepIndex == -1:
		currentStepIndex = 0
		_checkTrigger("room_start")


func _onEntityStateChanged(entity: Entity, _oldState: Entity.State, newState: Entity.State) -> void:
	if not tutorialEnabled:
		return

	if newState == Entity.State.DYING and not entity.is_player:
		_checkTrigger("enemy_dying")


func _onSpareOrExecute(_entity: Entity, _wasSpared: bool) -> void:
	if not tutorialEnabled:
		return
	_checkCondition("moral_choice_made")


func _printDebug(msg: String) -> void:
	if OS.is_debug_build():
		print("TutorialManager: %s" % msg)

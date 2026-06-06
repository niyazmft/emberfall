extends GdUnitTestSuite

var _tm: _TutorialManager
var _signalCount: int = 0
var _startedSteps: Array[String] = []


func before() -> void:
	_tm = _TutorialManager.new()
	add_child(_tm)


func after() -> void:
	_tm.free()


func _onStepStarted(stepId: String, _textKey: String, _target: String) -> void:
	_signalCount += 1
	_startedSteps.append(stepId)


func test_load_tutorial_data() -> void:
	assert_bool(_tm.tutorialEnabled).is_true()
	assert_int(_tm.tutorialSteps.size()).is_greater(0)

	var firstStep: Dictionary = _tm.tutorialSteps[0]
	assert_str(firstStep.get("id")).is_equal("movement")


func test_tutorial_flow() -> void:
	_tm.tutorialStepStarted.connect(_onStepStarted)

	# Initial room entered
	_tm._onRoomEntered(0, {})
	assert_int(_tm.currentStepIndex).is_equal(0)
	assert_str(_tm.activeInputLock).is_equal("movement_only")
	assert_int(_signalCount).is_equal(1)
	assert_str(_startedSteps[0]).is_equal("movement")

	# Complete movement
	_tm.notifyPlayerMoved()
	assert_int(_tm.currentStepIndex).is_equal(1)
	assert_str(_tm.activeInputLock).is_equal("none")
	# Should have triggered the next step "ap_system"
	assert_int(_signalCount).is_equal(2)
	assert_str(_startedSteps[1]).is_equal("ap_system")

	# Acknowledge AP
	_tm.acknowledgeStep()
	assert_int(_tm.currentStepIndex).is_equal(2)
	# Next step "cover" should NOT auto-trigger because it has "near_cover" trigger
	assert_int(_signalCount).is_equal(2)


func test_input_locking() -> void:
	# Ensure tutorial is at movement step
	_tm.currentStepIndex = 0
	_tm._triggerCurrentStep()

	assert_bool(_tm.isInputLocked("move_up")).is_false()
	assert_bool(_tm.isInputLocked("combat_confirm")).is_true()

	_tm.completeStep("movement")
	assert_bool(_tm.isInputLocked("combat_confirm")).is_false()

class_name QAExploratoryAgent
extends Node
## Autonomous exploratory QA agent.
## Runs a Vision-Language-Action loop: capture screenshot → send to AI →
## parse action JSON → execute → repeat until maxSteps or maxDurationSec.
##
## The AI is given a system prompt describing the game, available actions, and
## the current directive. It should return a JSON object like:
##   {
##     "thought": "I see the main menu. I will click Start.",
##     "action": { "type": "input_click", "x": 960, "y": 540 },
##     "assertion": "The Start button should be highlighted."
##   }

var _manager: QAManager = null
var _directive: String = ""
var _maxSteps: int = 20
var _maxDurationSec: float = 120.0

var _executor: QAActionExecutor = null
var _capture: QAVisionCapture = null
var _client: QAAIClient = null
var _reporter: QATestReporter = null
var _cancelled: bool = false


func setup(
	manager: QAManager,
	directive: String,
	maxSteps: int,
	maxDurationSec: float
) -> void:
	_manager = manager
	_directive = directive
	_maxSteps = maxSteps
	_maxDurationSec = maxDurationSec
	_executor = QAActionExecutor.new()
	_capture = QAVisionCapture.new()
	_capture.maxWidth = manager.visionMaxWidth
	_capture.format = manager.visionFormat
	_capture.quality = manager.visionQuality
	_capture.saveLocal = manager.visionSaveLocal
	_client = QAAIClient.new(manager.apiBase, manager.apiKey)
	_client.model = manager.model


## Runs the exploratory loop and returns a QATestReporter. Must be awaited.
func run() -> QATestReporter:
	_reporter = QATestReporter.new("exploratory_" + _directive)
	var start_ms: int = Time.get_ticks_msec()

	for step_i: int in range(_maxSteps):
		if _cancelled:
			_reporter.finish(QATestReporter.Status.SKIPPED)
			return _reporter

		var elapsed_sec: float = float(Time.get_ticks_msec() - start_ms) / 1000.0
		if elapsed_sec >= _maxDurationSec:
			_reporter.logError("Max duration reached")
			_reporter.status = QATestReporter.Status.FAILED
			break

		var b64: String = _capture.captureBase64()
		if b64.is_empty():
			_reporter.logError("Screenshot capture failed")
			_reporter.status = QATestReporter.Status.FAILED
			break

		var system_prompt: String = _build_system_prompt(step_i, elapsed_sec)
		var response: Dictionary = await _client.sendVisionPrompt(b64, system_prompt, _capture.format)
		var content: String = QAAIClient.extractContent(response)

		if content.is_empty():
			_reporter.logError("Empty AI response at step " + str(step_i))
			_reporter.status = QATestReporter.Status.FAILED
			break

		var parsed: Dictionary = _parse_ai_response(content)
		var thought: String = str(parsed.get("thought", ""))
		var action: Dictionary = parsed.get("action", {}) as Dictionary
		var assertion: String = str(parsed.get("assertion", ""))

		if not thought.is_empty():
			_reporter.recordStep("thought_step_" + str(step_i), true, {"thought": thought})

		if action.is_empty() or not action.has("type"):
			_reporter.logError("No action parsed at step " + str(step_i))
			_reporter.status = QATestReporter.Status.FAILED
			break

		var exec_result: Dictionary = await _executor.execute(action)
		_reporter.recordStep(
			"action_step_" + str(step_i),
			exec_result.get("success", false),
			{"action": action, "result": exec_result},
			b64
		)

		if not assertion.is_empty():
			var assertion_prompt: String = (
				"You are evaluating a game QA assertion. "
				+ "Respond with ONLY 'PASS' or 'FAIL' and a one-sentence reason.\n\n"
				+ "Assertion: " + assertion
			)
			var assert_response: Dictionary = await _client.sendTextPrompt(assertion_prompt)
			var assert_content: String = QAAIClient.extractContent(assert_response).strip_edges().to_upper()
			var passed: bool = assert_content == "PASS" or assert_content.begins_with("PASS ")
			_reporter.recordAssertion(
				"assertion_step_" + str(step_i),
				passed,
				assert_content,
				b64
			)

		await _delay_ms(_manager.defaultStepDelayMs)

	if _reporter.status != QATestReporter.Status.FAILED:
		_reporter.finish(QATestReporter.Status.PASSED)
	return _reporter


func cancel() -> void:
	_cancelled = true


func _build_system_prompt(step_index: int, elapsed_sec: float) -> String:
	return (
		"You are an expert QA tester for the tactical grid-combat game 'Emberfall'. "
		+ "You are given a screenshot of the current game state. "
		+ "Your job is to decide the next action to progress toward the test goal.\n\n"
		+ "DIRECTIVE: " + _directive + "\n"
		+ "STEP: " + str(step_index + 1) + "/" + str(_maxSteps) + "\n"
		+ "ELAPSED: " + str(int(elapsed_sec)) + "s\n\n"
		+ "Available actions:\n"
		+ "- input_click: {\"type\": \"input_click\", \"x\": int, \"y\": int, [\"button\": int]}\n"
		+ "- input_double_click: {\"type\": \"input_double_click\", \"x\": int, \"y\": int}\n"
		+ "- input_drag: {\"type\": \"input_drag\", \"from_x\": int, \"from_y\": int, \"to_x\": int, \"to_y\": int}\n"
		+ "- input_key: {\"type\": \"input_key\", \"key\": String, [\"pressed\": bool]}\n"
		+ "- input_text: {\"type\": \"input_text\", \"text\": String}\n"
		+ "- input_wait: {\"type\": \"input_wait\", \"ms\": int}\n"
		+ "- api_click_ui_by_text: {\"type\": \"api_click_ui_by_text\", \"text\": String}\n"
		+ "- api_start_run: {\"type\": \"api_start_run\"}\n"
		+ "- api_set_locale: {\"type\": \"api_set_locale\", \"locale\": String}\n"
		+ "- api_move_entity: {\"type\": \"api_move_entity\", \"entity_id\": String, \"x\": int, \"y\": int}\n\n"
		+ "Return ONLY a JSON object with these keys:\n"
		+ "{\n"
		+ '  "thought": "Brief reasoning about the current screen and plan.",\n'
		+ '  "action": { ... },\n'
		+ '  "assertion": "What visible state should result from this action?"\n'
		+ "}\n"
	)


func _parse_ai_response(content: String) -> Dictionary:
	var cleaned: String = content.strip_edges()
	if cleaned.begins_with("```json"):
		cleaned = cleaned.substr(7)
		if cleaned.begins_with("\n"):
			cleaned = cleaned.substr(1)
	if cleaned.ends_with("```"):
		cleaned = cleaned.substr(0, cleaned.length() - 3)
	cleaned = cleaned.strip_edges()

	var json := JSON.new()
	if json.parse(cleaned) == OK and json.data is Dictionary:
		return json.data as Dictionary
	return {}


func _delay_ms(ms: int) -> void:
	await Engine.get_main_loop().create_timer(float(ms) / 1000.0).timeout

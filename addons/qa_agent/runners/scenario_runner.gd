class_name QAScenarioRunner
extends Node
## Executes a scripted scenario step-by-step, optionally validating each step
## with a vision-language model.
##
## A scenario script is any GDScript Resource that exposes:
##   func get_name() -> String
##   func get_steps() -> Array[Dictionary]
##   func get_assertions() -> Array[Dictionary]   (optional)
##
## Each step Dictionary:
##   { "name": String, "action": Dictionary, "wait_ms": int }
##
## Each assertion Dictionary:
##   { "name": String, "prompt": String, "expected": String }
##
## When `validate_with_ai` is true, every assertion sends the current screenshot
## to the AI with the assertion prompt and checks that the response contains
## the expected substring.

var _manager: QAManager = null
var _executor: QAActionExecutor = null
var _capture: QAVisionCapture = null
var _client: QAAIClient = null
var _reporter: QATestReporter = null
var _cancelled: bool = false
var _validate_with_ai: bool = false


func setup(manager: QAManager) -> void:
	_manager = manager
	_executor = QAActionExecutor.new()
	_capture = QAVisionCapture.new()
	_capture.max_width = manager.vision_max_width
	_capture.format = manager.vision_format
	_capture.quality = manager.vision_quality
	_capture.save_local = manager.vision_save_local


func set_validate_with_ai(enabled: bool) -> void:
	_validate_with_ai = enabled


## Runs the scenario and returns a QATestReporter. Must be awaited.
func run(scenario_script: GDScript) -> QATestReporter:
	var instance: Resource = scenario_script.new() as Resource
	var scenario_name: String = "unnamed"
	if instance.has_method("get_name"):
		scenario_name = str(instance.call("get_name"))

	_reporter = QATestReporter.new(scenario_name)

	if _validate_with_ai:
		_client = QAAIClient.new(_manager.api_base, _manager.api_key)
		_client.model = _manager.model

	var steps: Array = []
	if instance.has_method("get_steps"):
		steps = instance.call("get_steps") as Array
	else:
		_reporter.log_error("Scenario missing get_steps()")
		_reporter.finish(QATestReporter.Status.FAILED)
		return _reporter

	for step_dict: Variant in steps:
		if _cancelled:
			_reporter.finish(QATestReporter.Status.SKIPPED)
			return _reporter
		if not step_dict is Dictionary:
			continue
		var step: Dictionary = step_dict as Dictionary
		var step_name: String = str(step.get("name", "unnamed"))
		var action: Dictionary = step.get("action", {}) as Dictionary
		var wait_ms: int = int(step.get("wait_ms", _manager.default_step_delay_ms))

		var result: Dictionary = await _executor.execute(action)
		_reporter.record_step(step_name, result.get("success", false), result)

		if wait_ms > 0:
			await _delay_ms(wait_ms)

	if instance.has_method("get_assertions"):
		var assertions: Array = instance.call("get_assertions") as Array
		for assertion_dict: Variant in assertions:
			if _cancelled:
				break
			if not assertion_dict is Dictionary:
				continue
			var assertion: Dictionary = assertion_dict as Dictionary
			await _run_assertion(assertion)

	if _reporter.status != QATestReporter.Status.FAILED:
		_reporter.finish(QATestReporter.Status.PASSED)
	return _reporter


func cancel() -> void:
	_cancelled = true


func _run_assertion(assertion: Dictionary) -> void:
	var assertion_name: String = str(assertion.get("name", "unnamed"))
	var prompt: String = str(assertion.get("prompt", ""))
	var expected: String = str(assertion.get("expected", ""))

	if _validate_with_ai and _client != null:
		var b64: String = _capture.capture_base64()
		var response: Dictionary = await _client.send_vision_prompt(b64, prompt)
		var content: String = QAAIClient.extract_content(response)
		var passed: bool = content.findn(expected) >= 0
		_reporter.record_assertion(assertion_name, passed, content, b64)
	else:
		_reporter.record_assertion(assertion_name, true, "AI validation disabled")


func _delay_ms(ms: int) -> void:
	await Engine.get_main_loop().create_timer(float(ms) / 1000.0).timeout

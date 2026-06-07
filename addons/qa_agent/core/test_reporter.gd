class_name QATestReporter
extends RefCounted
## Collects and serializes QA test results.
## Supports console output, JSON file export, and integration with GdUnit4 reporters.
##
## Usage:
##   var reporter := QATestReporter.new("test_main_menu")
##   reporter.recordStep("click_start", true, {"x": 100, "y": 200})
##   reporter.recordAssertion("button_visible", true, "Start button was visible")
##   var json: String = reporter.toJson()

enum Status { PENDING, RUNNING, PASSED, FAILED, SKIPPED }

var testName: String = ""
var startTimeMs: int = 0
var endTimeMs: int = 0
var status: Status = Status.PENDING
var steps: Array[Dictionary] = []
var assertions: Array[Dictionary] = []
var screenshots: Array[String] = []
var errors: Array[String] = []
var metadata: Dictionary = {}


func _init(pTestName: String) -> void:
	testName = pTestName
	startTimeMs = Time.get_ticks_msec()
	status = Status.RUNNING


## Record a single executed step (e.g., an AI action or API call).
func recordStep(
	step_name: String,
	success: bool,
	context: Dictionary = {},
	screenshot_base64: String = ""
) -> void:
	steps.append({
		"name": step_name,
		"success": success,
		"timestamp_ms": Time.get_ticks_msec() - startTimeMs,
		"context": context,
		"screenshot": screenshot_base64
	})
	if not screenshot_base64.is_empty():
		screenshots.append(screenshot_base64)
	if not success:
		status = Status.FAILED


## Record an assertion result (e.g., AI-evaluated visual check).
func recordAssertion(
	assertion_name: String,
	passed: bool,
	reason: String = "",
	screenshot_base64: String = ""
) -> void:
	assertions.append({
		"name": assertion_name,
		"passed": passed,
		"reason": reason,
		"timestamp_ms": Time.get_ticks_msec() - startTimeMs,
		"screenshot": screenshot_base64
	})
	if not screenshot_base64.is_empty():
		screenshots.append(screenshot_base64)
	if not passed:
		status = Status.FAILED


## Log a non-fatal error or warning.
func logError(message: String) -> void:
	errors.append(message)
	push_warning("QATestReporter [" + testName + "]: " + message)


## Mark the test as finished and compute duration.
func finish(final_status: Status = Status.PASSED) -> void:
	endTimeMs = Time.get_ticks_msec()
	if status == Status.FAILED:
		return
	status = final_status


## Serialize the full report to a JSON string.
func toJson() -> String:
	var duration_ms: int = max(0, endTimeMs - startTimeMs)
	var json := JSON.new()
	return json.stringify({
		"test_name": testName,
		"status": _statusToString(),
		"duration_ms": duration_ms,
		"steps": steps,
		"assertions": assertions,
		"errors": errors,
		"metadata": metadata,
		"screenshot_count": screenshots.size()
	}, "\t", false)


## Save the report to user://qa_reports/<testName>_<timestamp>.json.
func saveToFile() -> String:
	var dir: String = "user://qa_reports/"
	var err: Error = DirAccess.make_dir_recursive_absolute(dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_warning("QATestReporter: failed to create report directory")
		return ""
	var ts: String = Time.get_datetime_string_from_system().replace(":", "-")
	var path: String = dir + testName + "_" + ts + ".json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(toJson())
		f.close()
		return path
	return ""


## Print a human-readable summary to the console.
func printSummary() -> void:
	print("╔══════════════════════════════════════════════════════════════╗")
	print("║ QA Test Report: %-45s║" % _fitText(testName, 45))
	print("╠══════════════════════════════════════════════════════════════╣")
	print("║ Status: %-52s║" % _statusToString())
	print("║ Duration: %d ms%-46s║" % [max(0, endTimeMs - startTimeMs), ""])
	print("║ Steps: %d │ Assertions: %d │ Errors: %d%-28s║" % [steps.size(), assertions.size(), errors.size(), ""])
	if errors.size() > 0:
		print("╠══════════════════════════════════════════════════════════════╣")
		for e: String in errors:
			print("║ ERROR: %-54s║" % _fitText(e, 54))
	if assertions.size() > 0:
		print("╠══════════════════════════════════════════════════════════════╣")
		for a: Dictionary in assertions:
			var mark: String = "PASS" if a["passed"] else "FAIL"
			print("║ [%s] %-54s║" % [mark, _fitText(a["name"], 54)])
			if not a["reason"].is_empty():
				print("║      %-54s║" % _fitText(a["reason"], 54))
	print("╚══════════════════════════════════════════════════════════════╝")


func _statusToString() -> String:
	match status:
		Status.PENDING:
			return "PENDING"
		Status.RUNNING:
			return "RUNNING"
		Status.PASSED:
			return "PASSED"
		Status.FAILED:
			return "FAILED"
		Status.SKIPPED:
			return "SKIPPED"
		_:
			return "UNKNOWN"


func _fitText(text: String, width: int) -> String:
	var cleaned: String = text.replace("\n", " ").replace("\r", " ")
	if cleaned.length() > width:
		cleaned = cleaned.substr(0, width - 3) + "..."
	return cleaned

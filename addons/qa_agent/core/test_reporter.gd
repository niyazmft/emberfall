class_name QATestReporter
extends RefCounted
## Collects and serializes QA test results.
## Supports console output, JSON file export, and integration with GdUnit4 reporters.
##
## Usage:
##   var reporter := QATestReporter.new("test_main_menu")
##   reporter.record_step("click_start", true, {"x": 100, "y": 200})
##   reporter.record_assertion("button_visible", true, "Start button was visible")
##   var json: String = reporter.to_json()

enum Status { PENDING, RUNNING, PASSED, FAILED, SKIPPED }

var test_name: String = ""
var start_time_ms: int = 0
var end_time_ms: int = 0
var status: Status = Status.PENDING
var steps: Array[Dictionary] = []
var assertions: Array[Dictionary] = []
var screenshots: Array[String] = []
var errors: Array[String] = []
var metadata: Dictionary = {}


func _init(p_test_name: String) -> void:
	test_name = p_test_name
	start_time_ms = Time.get_ticks_msec()
	status = Status.RUNNING


## Record a single executed step (e.g., an AI action or API call).
func record_step(
	step_name: String,
	success: bool,
	context: Dictionary = {},
	screenshot_base64: String = ""
) -> void:
	steps.append({
		"name": step_name,
		"success": success,
		"timestamp_ms": Time.get_ticks_msec() - start_time_ms,
		"context": context,
		"screenshot": screenshot_base64
	})
	if not screenshot_base64.is_empty():
		screenshots.append(screenshot_base64)
	if not success:
		status = Status.FAILED


## Record an assertion result (e.g., AI-evaluated visual check).
func record_assertion(
	assertion_name: String,
	passed: bool,
	reason: String = "",
	screenshot_base64: String = ""
) -> void:
	assertions.append({
		"name": assertion_name,
		"passed": passed,
		"reason": reason,
		"timestamp_ms": Time.get_ticks_msec() - start_time_ms,
		"screenshot": screenshot_base64
	})
	if not screenshot_base64.is_empty():
		screenshots.append(screenshot_base64)
	if not passed:
		status = Status.FAILED


## Log a non-fatal error or warning.
func log_error(message: String) -> void:
	errors.append(message)
	push_warning("QATestReporter [" + test_name + "]: " + message)


## Mark the test as finished and compute duration.
func finish(final_status: Status = Status.PASSED) -> void:
	end_time_ms = Time.get_ticks_msec()
	if status == Status.FAILED:
		return
	status = final_status


## Serialize the full report to a JSON string.
func to_json() -> String:
	var json := JSON.new()
	return json.stringify({
		"test_name": test_name,
		"status": _status_to_string(),
		"duration_ms": end_time_ms - start_time_ms,
		"steps": steps,
		"assertions": assertions,
		"errors": errors,
		"metadata": metadata,
		"screenshot_count": screenshots.size()
	}, "\t", false)


## Save the report to user://qa_reports/<test_name>_<timestamp>.json.
func save_to_file() -> String:
	var dir: String = "user://qa_reports/"
	var err: Error = DirAccess.make_dir_recursive_absolute(dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_warning("QATestReporter: failed to create report directory")
		return ""
	var ts: String = Time.get_datetime_string_from_system().replace(":", "-")
	var path: String = dir + test_name + "_" + ts + ".json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(to_json())
		f.close()
		return path
	return ""


## Print a human-readable summary to the console.
func print_summary() -> void:
	print("╔══════════════════════════════════════════════════════════════╗")
	print("║ QA Test Report: %-45s║" % test_name)
	print("╠══════════════════════════════════════════════════════════════╣")
	print("║ Status: %-52s║" % _status_to_string())
	print("║ Duration: %d ms%-46s║" % [end_time_ms - start_time_ms, ""])
	print("║ Steps: %d │ Assertions: %d │ Errors: %d%-28s║" % [steps.size(), assertions.size(), errors.size(), ""])
	if errors.size() > 0:
		print("╠══════════════════════════════════════════════════════════════╣")
		for e: String in errors:
			print("║ ERROR: %-54s║" % e)
	if assertions.size() > 0:
		print("╠══════════════════════════════════════════════════════════════╣")
		for a: Dictionary in assertions:
			var mark: String = "PASS" if a["passed"] else "FAIL"
			print("║ [%s] %-54s║" % [mark, a["name"]])
			if not a["reason"].is_empty():
				print("║      %-54s║" % a["reason"])
	print("╚══════════════════════════════════════════════════════════════╝")


func _status_to_string() -> String:
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

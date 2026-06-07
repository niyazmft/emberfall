class_name QAManager
extends Node
## Central orchestrator for the QA Agent addon.
## Registered as an autoload when the addon is enabled. Provides a single entry
## point for running scenario-driven tests or launching exploratory agents.
##
## Usage from GDScript console or another script:
##   var mgr: QAManager = QAManager.instance()
##   mgr.run_scenario("res://addons/qa_agent/scenarios/test_main_menu.gd")
##   mgr.start_exploratory("Explore the main menu and settings", 30)
##
## Configuration (set before running):
##   mgr.api_base = "https://api.openai.com/v1"
##   mgr.api_key = "sk-..."
##   mgr.model = "gpt-4o"

const CONFIG_PATH: String = "user://qa_agent_config.json"

## Cloud API configuration.
var api_base: String = ""
var api_key: String = ""
var model: String = "gpt-4o"

## Vision capture settings.
var vision_max_width: int = 1024
var vision_format: String = "jpeg"
var vision_quality: int = 85
var vision_save_local: bool = false

## Default wait between AI turns in exploratory mode (ms).
var default_step_delay_ms: int = 500

## Singleton reference.
static var _instance: QAManager = null

var _active_runner: Node = null


func _ready() -> void:
	_instance = self
	_load_config()


static func instance() -> QAManager:
	return _instance


## Run a single scenario script (scenario-driven regression test).
## Returns a QATestReporter after the scenario completes.
func run_scenario(scenario_path: String) -> QATestReporter:
	var script: GDScript = load(scenario_path) as GDScript
	if script == null:
		var reporter := QATestReporter.new("load_failed")
		reporter.log_error("Failed to load scenario: " + scenario_path)
		reporter.finish(QATestReporter.Status.FAILED)
		return reporter

	var runner := QAScenarioRunner.new()
	runner.setup(self)
	add_child(runner)
	_active_runner = runner

	var reporter: QATestReporter = await runner.run(script)
	_active_runner = null
	runner.queue_free()
	return reporter


## Start an exploratory agent session with a high-level directive.
## The agent will take screenshots, ask the AI for next actions, and execute them
## in a loop for `max_steps` iterations or until `max_duration_sec` elapses.
func start_exploratory(
	directive: String,
	max_steps: int = 20,
	max_duration_sec: float = 120.0
) -> QATestReporter:
	var agent := QAExploratoryAgent.new()
	agent.setup(self, directive, max_steps, max_duration_sec)
	add_child(agent)
	_active_runner = agent

	var reporter: QATestReporter = await agent.run()
	_active_runner = null
	agent.queue_free()
	return reporter


## Cancel any active scenario or exploratory run.
func cancel_active() -> void:
	if _active_runner != null and _active_runner.has_method("cancel"):
		_active_runner.call("cancel")
	_active_runner = null


## Save current configuration to user://qa_agent_config.json.
func save_config() -> void:
	var json := JSON.new()
	var data: Dictionary = {
		"api_base": api_base,
		"api_key": api_key,
		"model": model,
		"vision_max_width": vision_max_width,
		"vision_format": vision_format,
		"vision_quality": vision_quality,
		"vision_save_local": vision_save_local,
		"default_step_delay_ms": default_step_delay_ms
	}
	var f := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(json.stringify(data, "\t", false))
		f.close()


func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return
	var text: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = json.data as Dictionary
	api_base = str(data.get("api_base", api_base))
	api_key = str(data.get("api_key", api_key))
	model = str(data.get("model", model))
	vision_max_width = int(data.get("vision_max_width", vision_max_width))
	vision_format = str(data.get("vision_format", vision_format))
	vision_quality = int(data.get("vision_quality", vision_quality))
	vision_save_local = bool(data.get("vision_save_local", vision_save_local))
	default_step_delay_ms = int(data.get("default_step_delay_ms", default_step_delay_ms))

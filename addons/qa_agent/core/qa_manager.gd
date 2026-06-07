class_name QAManager
extends Node
## Central orchestrator for the QA Agent addon.
## Registered as an autoload when the addon is enabled. Provides a single entry
## point for running scenario-driven tests or launching exploratory agents.
##
## Usage from GDScript console or another script:
##   var mgr: QAManager = QAManager.instance()
##   mgr.runScenario("res://addons/qa_agent/scenarios/test_main_menu.gd")
##   mgr.startExploratory("Explore the main menu and settings", 30)
##
## Configuration (set before running):
##   mgr.apiBase = "https://api.openai.com/v1"
##   mgr.apiKey = "sk-..."
##   mgr.model = "gpt-4o"

const CONFIG_PATH: String = "user://qa_agent_config.json"

## Cloud API configuration.
var apiBase: String = ""
var apiKey: String = ""
var model: String = "gpt-4o"

## Vision capture settings.
var visionMaxWidth: int = 1024
var visionFormat: String = "jpeg"
var visionQuality: int = 85
var visionSaveLocal: bool = false

## Default wait between AI turns in exploratory mode (ms).
var defaultStepDelayMs: int = 500

## Singleton reference.
static var _instance: QAManager = null

var _activeRunner: Node = null


func _ready() -> void:
	_instance = self
	_loadConfig()


static func instance() -> QAManager:
	return _instance


## Run a single scenario script (scenario-driven regression test).
## Returns a QATestReporter after the scenario completes.
func runScenario(scenarioPath: String) -> QATestReporter:
	var script: GDScript = load(scenarioPath) as GDScript
	if script == null:
		var reporter := QATestReporter.new("load_failed")
		reporter.logError("Failed to load scenario: " + scenarioPath)
		reporter.finish(QATestReporter.Status.FAILED)
		return reporter

	var runner := QAScenarioRunner.new()
	runner.setup(self)
	add_child(runner)
	_activeRunner = runner

	var reporter: QATestReporter = await runner.run(script)
	_activeRunner = null
	runner.queue_free()
	return reporter


## Start an exploratory agent session with a high-level directive.
## The agent will take screenshots, ask the AI for next actions, and execute them
## in a loop for `maxSteps` iterations or until `maxDurationSec` elapses.
func startExploratory(
	directive: String,
	maxSteps: int = 20,
	maxDurationSec: float = 120.0
) -> QATestReporter:
	var agent := QAExploratoryAgent.new()
	agent.setup(self, directive, maxSteps, maxDurationSec)
	add_child(agent)
	_activeRunner = agent

	var reporter: QATestReporter = await agent.run()
	_activeRunner = null
	agent.queue_free()
	return reporter


## Cancel any active scenario or exploratory run.
func cancelActive() -> void:
	if _activeRunner != null and _activeRunner.has_method("cancel"):
		_activeRunner.call("cancel")
	_activeRunner = null


## Save current configuration to user://qa_agent_config.json.
func saveConfig() -> void:
	var json := JSON.new()
	var data: Dictionary = {
		"apiBase": apiBase,
		"apiKey": apiKey,
		"model": model,
		"visionMaxWidth": visionMaxWidth,
		"visionFormat": visionFormat,
		"visionQuality": visionQuality,
		"visionSaveLocal": visionSaveLocal,
		"defaultStepDelayMs": defaultStepDelayMs
	}
	var f := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(json.stringify(data, "\t", false))
		f.close()


func _loadConfig() -> void:
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
	if not json.data is Dictionary:
		push_warning("QAManager: config file does not contain a JSON object")
		return
	var data: Dictionary = json.data as Dictionary
	apiBase = str(data.get("apiBase", apiBase))
	apiKey = str(data.get("apiKey", apiKey))
	model = str(data.get("model", model))
	visionMaxWidth = int(data.get("visionMaxWidth", visionMaxWidth))
	visionFormat = str(data.get("visionFormat", visionFormat))
	visionQuality = int(data.get("visionQuality", visionQuality))
	visionSaveLocal = bool(data.get("visionSaveLocal", visionSaveLocal))
	defaultStepDelayMs = int(data.get("defaultStepDelayMs", defaultStepDelayMs))

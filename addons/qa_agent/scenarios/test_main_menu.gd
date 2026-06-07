extends Resource
## Example scenario-driven QA test: verify main menu → settings → back flow.
##
## Usage:
##   var reporter := await QAManager.instance().run_scenario(
##       "res://addons/qa_agent/scenarios/test_main_menu.gd"
##   )
##   reporter.print_summary()

func get_name() -> String:
	return "test_main_menu_flow"


func get_steps() -> Array[Dictionary]:
	return [
		{
			"name": "wait_for_menu",
			"action": {"type": "input_wait", "ms": 1000},
			"wait_ms": 500
		},
		{
			"name": "click_settings",
			"action": {"type": "api_click_ui_by_text", "text": "Settings"},
			"wait_ms": 800
		},
		{
			"name": "click_back",
			"action": {"type": "api_click_ui_by_text", "text": "Back"},
			"wait_ms": 800
		}
	]


func get_assertions() -> Array[Dictionary]:
	return [
		{
			"name": "menu_visible_after_back",
			"prompt": (
				"You are looking at the Emberfall main menu. "
				+ "Is the main title screen visible with buttons like 'Start', 'Settings', 'Quit'? "
				+ "Answer YES or NO."
			),
			"expected": "YES"
		}
	]

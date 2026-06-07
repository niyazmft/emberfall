@tool
extends EditorPlugin
## QA Agent addon entry point.
## Registers QAManager as an autoload when the plugin is enabled.

const AUTOLOAD_NAME: String = "QAManager"
const AUTOLOAD_PATH: String = "res://addons/qa_agent/core/qa_manager.gd"


func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)

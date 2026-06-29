class_name SettingsModal
extends Control

## SettingsMenu
## Wrapper for SettingsPanel that can be shown as a modal.

@onready var _panel: Control = $SettingsPanel


static func show_modal() -> void:
	var scene: PackedScene = load("res://scenes/ui/settings_menu.tscn") as PackedScene
	if scene:
		var instance: Node = scene.instantiate()
		var lm: _LayerManager = AutoloadHelper.layer_manager()
		if lm:
			lm.add_modal(instance)


func _ready() -> void:
	if not _panel.back_pressed.is_connected(_on_back_pressed):
		_panel.back_pressed.connect(_on_back_pressed)
	_panel.show()
	var fm: Node = AutoloadHelper.focus_manager()
	if fm:
		fm.set_initial_focus(_panel)


func _exit_tree() -> void:
	if _panel and _panel.back_pressed.is_connected(_on_back_pressed):
		_panel.back_pressed.disconnect(_on_back_pressed)


func _on_back_pressed() -> void:
	queue_free()

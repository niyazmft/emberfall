class_name SettingsModal
extends Control

## SettingsMenu
## Wrapper for SettingsPanel that can be shown as a modal.

@onready var _panel: Control = $SettingsPanel


static func show_modal() -> void:
	var scene: PackedScene = load("res://scenes/ui/settings_menu.tscn") as PackedScene
	if scene:
		var instance: Node = scene.instantiate()
		LayerManager.add_modal(instance)


func _ready() -> void:
	_panel.back_pressed.connect(_on_back_pressed)
	_panel.show()
	FocusManager.set_initial_focus(_panel)


func _on_back_pressed() -> void:
	queue_free()

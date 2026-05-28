class_name SettingsModal
extends Control

## SettingsMenu (DON-196)
## Demonstrates safe-zone integration and responsive reflow.

@onready var margin_container: MarginContainer = $MarginContainer


static func show_modal() -> void:
	var scene: PackedScene = load("res://scenes/ui/settings_menu.tscn") as PackedScene
	if scene:
		var instance: Node = scene.instantiate()
		LayerManager.add_modal(instance)


func _ready() -> void:
	SafeZoneManager.safe_area_changed.connect(_on_safe_area_changed)
	_apply_safe_area()


func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()


func _apply_safe_area() -> void:
	var margins: Dictionary = SafeZoneManager.get_safe_margins() as Dictionary
	margin_container.add_theme_constant_override("margin_left", int(margins.get("left", 0)))
	margin_container.add_theme_constant_override("margin_top", int(margins.get("top", 0)))
	margin_container.add_theme_constant_override("margin_right", int(margins.get("right", 0)))
	margin_container.add_theme_constant_override("margin_bottom", int(margins.get("bottom", 0)))

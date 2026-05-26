extends Control
## SettingsMenu (DON-196)
## Demonstrates safe-zone integration and responsive reflow.

@onready var margin_container: MarginContainer = $MarginContainer

func _ready() -> void:
	SafeZoneManager.safe_area_changed.connect(_on_safe_area_changed)
	_apply_safe_area()

func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()

func _apply_safe_area() -> void:
	var margins := SafeZoneManager.get_safe_margins()
	margin_container.add_theme_constant_override("margin_left", margins.left)
	margin_container.add_theme_constant_override("margin_top", margins.top)
	margin_container.add_theme_constant_override("margin_right", margins.right)
	margin_container.add_theme_constant_override("margin_bottom", margins.bottom)

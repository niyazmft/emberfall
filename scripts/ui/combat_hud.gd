extends Control
## CombatHUD (DON-196)
## Manages HUD layout and bottom chrome reflow.

@onready var margin_container: MarginContainer = $MarginContainer
@onready var bottom_chrome: VBoxContainer = $MarginContainer/BottomChrome
@onready var hotbar: Control = $MarginContainer/BottomChrome/Hotbar
@onready var prompts: Control = $MarginContainer/BottomChrome/Prompts
@onready var status_icons: Control = $MarginContainer/BottomChrome/StatusIcons


func _ready() -> void:
	SafeZoneManager.safe_area_changed.connect(_on_safe_area_changed)
	SafeZoneManager.aspect_ratio_changed.connect(_on_aspect_ratio_changed)
	_apply_safe_area()
	_reflow_bottom_chrome()


func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()


func _on_aspect_ratio_changed(_mode: SafeZoneManager.AspectMode) -> void:
	_reflow_bottom_chrome()


func _apply_safe_area() -> void:
	var margins := SafeZoneManager.get_safe_margins()
	margin_container.add_theme_constant_override("margin_left", margins.left)
	margin_container.add_theme_constant_override("margin_top", margins.top)
	margin_container.add_theme_constant_override("margin_right", margins.right)
	margin_container.add_theme_constant_override("margin_bottom", margins.bottom)


func _reflow_bottom_chrome() -> void:
	# AC: Bottom chrome priority reflow (hotbar → prompts → status icons)
	# In a VBoxContainer, if we want this order from bottom to top:
	# 1. Hotbar (at the very bottom)
	# 2. Prompts (above hotbar)
	# 3. Status Icons (above prompts)

	# We ensure child order: StatusIcons, Prompts, Hotbar
	bottom_chrome.move_child(status_icons, 0)
	bottom_chrome.move_child(prompts, 1)
	bottom_chrome.move_child(hotbar, 2)

	# If viewport is very tight (SHRINK mode), we might want to hide status icons
	if SafeZoneManager.current_aspect_mode == SafeZoneManager.AspectMode.SHRINK:
		status_icons.hide()
	else:
		status_icons.show()

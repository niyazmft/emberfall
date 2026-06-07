extends CanvasLayer

## UIRoot
## Primary UI container that manages top-level screens and safe-zone margins.

@onready var _safe_zone_container: MarginContainer = %SafeZoneContainer
@onready var _main_menu: Control = %MainMenu
@onready var _pause_menu: Control = %PauseMenu
@onready var _settings_panel: Control = %SettingsPanel
@onready var _transition_layer: TransitionLayer = %TransitionLayer
@onready var _inventory: Control = %Inventory


func _ready() -> void:
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)

	_main_menu.settings_requested.connect(_show_settings)
	_pause_menu.settings_requested.connect(_show_settings)
	_settings_panel.back_pressed.connect(_on_settings_back)

	# Initial state: Show Main Menu
	_main_menu.show()
	_pause_menu.hide()
	_settings_panel.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _settings_panel.visible:
			_settings_panel._on_back_pressed()
			get_viewport().set_input_as_handled()
		elif _main_menu.visible:
			# Quit or show quit confirmation
			pass
		else:
			# Toggle Pause
			_pause_menu.toggle_pause()
			get_viewport().set_input_as_handled()


func _apply_safe_area() -> void:
	var safe_area := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()

	if window_size.x == 0 or window_size.y == 0:
		return

	# Convert safe area to margins
	_safe_zone_container.add_theme_constant_override("margin_left", safe_area.position.x)
	_safe_zone_container.add_theme_constant_override("margin_top", safe_area.position.y)
	_safe_zone_container.add_theme_constant_override(
		"margin_right", window_size.x - safe_area.end.x
	)
	_safe_zone_container.add_theme_constant_override(
		"margin_bottom", window_size.y - safe_area.end.y
	)


func _show_settings() -> void:
	_settings_panel.show()
	FocusManager.set_initial_focus(_settings_panel)


func _on_settings_back() -> void:
	if _pause_menu.visible:
		FocusManager.set_initial_focus(_pause_menu)
	elif _main_menu.visible:
		FocusManager.set_initial_focus(_main_menu)

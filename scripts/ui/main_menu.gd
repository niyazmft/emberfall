class_name MainMenu
extends Control

## MainMenu
## Handles top-level navigation and game start with safe-zone integration.

signal settings_requested

@onready var margin_container: MarginContainer = $MarginContainer
@onready var _new_run_button: Button = %NewRunButton
@onready var _continue_button: Button = %ContinueButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	_new_run_button.pressed.connect(_on_new_run_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	InputRouter.device_changed.connect(_on_device_changed)
	_update_hints(InputRouter.current_device)

	SafeZoneManager.safe_area_changed.connect(_on_safe_area_changed)
	_apply_safe_area()

	# Initial focus with defensive null check (DON-298)
	if is_instance_valid(_new_run_button):
		_new_run_button.grab_focus.call_deferred()

	FocusManager.push_modal_focus(self)


func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()


func _apply_safe_area() -> void:
	var margins: Dictionary = SafeZoneManager.get_safe_margins() as Dictionary
	margin_container.add_theme_constant_override("margin_left", int(margins.get("left", 0)))
	margin_container.add_theme_constant_override("margin_top", int(margins.get("top", 0)))
	margin_container.add_theme_constant_override("margin_right", int(margins.get("right", 0)))
	margin_container.add_theme_constant_override("margin_bottom", int(margins.get("bottom", 0)))


func _on_device_changed(device: _InputRouter.InputDevice) -> void:
	_update_hints(device)


func _update_hints(device: _InputRouter.InputDevice) -> void:
	if device == _InputRouter.InputDevice.GAMEPAD:
		_hint_label.text = tr("HINT_SELECT_GP")
	else:
		_hint_label.text = tr("HINT_SELECT_KBM")


func _on_new_run_pressed() -> void:
	if RunManager.has_method("fade_out"):
		await RunManager.call("fade_out", 0.5)
	if RunManager.has_method("cmd_start_run"):
		RunManager.call("cmd_start_run")
	hide()


func _on_settings_pressed() -> void:
	settings_requested.emit()


func _on_quit_pressed() -> void:
	var scene: PackedScene = load("res://scenes/ui/confirm_modal.tscn") as PackedScene
	if scene:
		var modal: Node = scene.instantiate()
		modal.call("setup", "CONFIRM_QUIT_TITLE", "CONFIRM_QUIT_BODY")
		modal.connect("confirmed", _on_quit_confirmed)
		LayerManager.add_modal(modal)


func _on_quit_confirmed() -> void:
	get_tree().quit()

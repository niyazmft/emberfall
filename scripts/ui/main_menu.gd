extends Control

## MainMenu
## Handles top-level navigation and game start.

signal settings_requested

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

	# Initial focus
	FocusManager.set_initial_focus(self)

func _on_device_changed(device: _InputRouter.InputDevice) -> void:
	_update_hints(device)

func _update_hints(device: _InputRouter.InputDevice) -> void:
	if device == _InputRouter.InputDevice.GAMEPAD:
		_hint_label.text = tr("HINT_SELECT_GP")
	else:
		_hint_label.text = tr("HINT_SELECT_KBM")

func _on_new_run_pressed() -> void:
	RunManager.cmd_start_run()
	# Typically we'd hide the menu here or transition to a loading state
	hide()

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_quit_pressed() -> void:
	get_tree().quit()

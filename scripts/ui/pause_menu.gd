extends Control

## PauseMenu
## Handles in-game pausing and menu options.

signal settings_requested

@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _hint_label: Label = %HintLabel

func _ready() -> void:
	hide()
	_resume_button.pressed.connect(toggle_pause)
	_restart_button.pressed.connect(_on_restart_pressed)
	_settings_button.pressed.connect(_on_settings_requested)
	_quit_button.pressed.connect(_on_quit_pressed)

	InputRouter.device_changed.connect(_on_device_changed)
	_update_hints(InputRouter.current_device)

func _on_device_changed(device: _InputRouter.InputDevice) -> void:
	_update_hints(device)

func _update_hints(device: _InputRouter.InputDevice) -> void:
	if device == _InputRouter.InputDevice.GAMEPAD:
		_hint_label.text = tr("HINT_SELECT_GP")
	else:
		_hint_label.text = tr("HINT_SELECT_KBM")

func toggle_pause() -> void:
	var new_pause_state := !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

	if visible:
		FocusManager.set_initial_focus(self)

func _on_restart_pressed() -> void:
	# Implementation depends on how rooms are reset
	toggle_pause()
	# RunManager.cmd_restart_room() # If implemented

func _on_settings_requested() -> void:
	settings_requested.emit()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	RunManager.cmd_return_to_sanctum()
	hide()

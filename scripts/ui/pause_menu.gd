class_name PauseMenu
extends Control

## PauseMenu
## Handles in-game pausing and menu options with safe-zone integration.

signal settings_requested

@onready var margin_container: MarginContainer = $MarginContainer
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


func _on_device_changed(device: _InputRouter.InputDevice) -> void:
	_update_hints(device)


func _update_hints(device: _InputRouter.InputDevice) -> void:
	if device == _InputRouter.InputDevice.GAMEPAD:
		_hint_label.text = tr("HINT_SELECT_GP")
	else:
		_hint_label.text = tr("HINT_SELECT_KBM")


func toggle_pause() -> void:
	var new_pause_state: bool = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

	if visible:
		# Initial focus with defensive null check (DON-298)
		if is_instance_valid(_resume_button):
			_resume_button.grab_focus.call_deferred()

		FocusManager.push_modal_focus(self)


func _on_restart_pressed() -> void:
	# Implementation depends on how rooms are reset
	toggle_pause()
	# RunManager.cmd_restart_room() # If implemented


func _on_settings_requested() -> void:
	SettingsModal.show_modal()
	settings_requested.emit()


func _on_quit_pressed() -> void:
	var scene: PackedScene = load("res://scenes/ui/confirm_modal.tscn") as PackedScene
	if scene:
		var modal: Node = scene.instantiate()
		modal.call("setup", "CONFIRM_RETURN_TITLE", "CONFIRM_RETURN_BODY")
		modal.connect("confirmed", _on_quit_confirmed)
		LayerManager.add_modal(modal)


func _on_quit_confirmed() -> void:
	get_tree().paused = false
	if RunManager.has_method("cmd_return_to_sanctum"):
		RunManager.call("cmd_return_to_sanctum")
	hide()

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

	var ir: _InputRouter = AutoloadHelper.input_router()
	if ir:
		ir.device_changed.connect(_on_device_changed)
		_update_hints(ir.current_device)

	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz:
		sz.safe_area_changed.connect(_on_safe_area_changed)
	_apply_safe_area()


func _exit_tree() -> void:
	var ir: _InputRouter = AutoloadHelper.input_router()
	if ir and ir.device_changed.is_connected(_on_device_changed):
		ir.device_changed.disconnect(_on_device_changed)

	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz and sz.safe_area_changed.is_connected(_on_safe_area_changed):
		sz.safe_area_changed.disconnect(_on_safe_area_changed)


func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()


func _apply_safe_area() -> void:
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz == null:
		return
	var margins: Dictionary = sz.get_safe_margins() as Dictionary
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

		var fm := AutoloadHelper.focus_manager()
		if fm:
			fm.push_modal_focus(self)


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
		var modal := scene.instantiate() as _ConfirmModal
		if modal:
			modal.setup("CONFIRM_RETURN_TITLE", "CONFIRM_RETURN_BODY")
			modal.confirmed.connect(_on_quit_confirmed)
			var lm: _LayerManager = AutoloadHelper.layer_manager()
			if lm:
				lm.add_modal(modal)


func _on_quit_confirmed() -> void:
	get_tree().paused = false
	var rm: _RunManager = AutoloadHelper.run_manager()
	if rm:
		rm.cmd_return_to_sanctum()
	hide()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

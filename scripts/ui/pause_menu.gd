class_name PauseMenu
extends Control

## PauseMenu
## Handles in-game pausing and menu options with safe-zone integration.

signal settings_requested

@onready var margin_container: MarginContainer = get_node_or_null("MarginContainer")
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _hint_label: Label = %HintLabel
# The VBoxContainer that holds all pause buttons — hidden while settings is open
@onready var _buttons_container: VBoxContainer = (
	get_node_or_null("CenterContainer/VBoxContainer") as VBoxContainer
)


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

	# Restore buttons when any modal (Settings, Confirm) closes
	var eb: Node = AutoloadHelper.event_bus()
	if eb:
		eb.modal_closed.connect(_on_modal_closed)


func _exit_tree() -> void:
	var ir: _InputRouter = AutoloadHelper.input_router()
	if ir and ir.device_changed.is_connected(_on_device_changed):
		ir.device_changed.disconnect(_on_device_changed)

	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz and sz.safe_area_changed.is_connected(_on_safe_area_changed):
		sz.safe_area_changed.disconnect(_on_safe_area_changed)

	var eb: Node = AutoloadHelper.event_bus()
	if eb and eb.modal_closed.is_connected(_on_modal_closed):
		eb.modal_closed.disconnect(_on_modal_closed)

	# FIX #556: Disconnect button pressed signals
	if _resume_button and _resume_button.pressed.is_connected(toggle_pause):
		_resume_button.pressed.disconnect(toggle_pause)
	if _restart_button and _restart_button.pressed.is_connected(_on_restart_pressed):
		_restart_button.pressed.disconnect(_on_restart_pressed)
	if _settings_button and _settings_button.pressed.is_connected(_on_settings_requested):
		_settings_button.pressed.disconnect(_on_settings_requested)
	if _quit_button and _quit_button.pressed.is_connected(_on_quit_pressed):
		_quit_button.pressed.disconnect(_on_quit_pressed)


func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()


func _apply_safe_area() -> void:
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz == null or margin_container == null:
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
	else:
		# FIX #539: Pop modal focus when unpausing to prevent focus stack corruption
		var fm := AutoloadHelper.focus_manager()
		if fm:
			fm.pop_modal_focus()


func _on_restart_pressed() -> void:
	toggle_pause()
	var rm: _RunManager = AutoloadHelper.run_manager()
	if rm:
		rm.cmd_restart_room()


func _on_settings_requested() -> void:
	# Hide the pause buttons while settings panel is visible to prevent text bleed-through
	if is_instance_valid(_buttons_container):
		_buttons_container.hide()
	SettingsModal.show_modal()
	settings_requested.emit()


## Called by SettingsMenu/SettingsPanel when the Back button is pressed.
func _on_modal_closed() -> void:
	if not visible:
		return
	if is_instance_valid(_buttons_container):
		_buttons_container.show()
	if is_instance_valid(_resume_button):
		_resume_button.grab_focus.call_deferred()


func on_settings_closed() -> void:
	_on_modal_closed()


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
	hide()

	# Fade out before scene change. TitleScreen._ready() handles fade_in
	# to avoid calling fade_in on a node that gets freed mid-transition.
	var tl: _TransitionLayer = AutoloadHelper.transition_layer()
	if tl:
		tl.fade_out(0.3)
		await tl.fade_completed

	var rm: _RunManager = AutoloadHelper.run_manager()
	if rm:
		rm.cmd_return_to_sanctum()

	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

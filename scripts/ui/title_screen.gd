extends Control

## TitleScreen (DON-298)
## Main entry point with focus management and localized rows.

@onready var continue_btn: Button = %ContinueButton
@onready var new_game_btn: Button = %NewGameButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var button_container: VBoxContainer = %ButtonContainer
@onready var transition_layer: TransitionLayer = %TransitionLayer


func _ready() -> void:
	# Localize text
	continue_btn.text = tr("menu.title.continue")
	new_game_btn.text = tr("menu.title.new_game")
	settings_btn.text = tr("menu.title.settings")
	quit_btn.text = tr("menu.title.quit")

	# Setup button states
	_update_continue_button_state()

	# Connect signals
	continue_btn.pressed.connect(_on_continue_pressed)
	new_game_btn.pressed.connect(_on_new_game_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	var save_manager: _SaveManager = AutoloadHelper.save_manager()
	if save_manager != null:
		save_manager.save_changed.connect(_update_continue_button_state)

	# Enforce touch targets
	for btn: Button in [continue_btn, new_game_btn, settings_btn, quit_btn]:
		TouchTargetEnforcer.enforce(btn)

	# Setup dynamic vertical wrap-around focus
	_setup_focus_wrap()

	if transition_layer:
		transition_layer.fade_in()

	# Initial focus: Continue if enabled, otherwise New Game
	if not continue_btn.disabled:
		continue_btn.grab_focus.call_deferred()
	else:
		new_game_btn.grab_focus.call_deferred()


func _exit_tree() -> void:
	if continue_btn and continue_btn.pressed.is_connected(_on_continue_pressed):
		continue_btn.pressed.disconnect(_on_continue_pressed)
	if new_game_btn and new_game_btn.pressed.is_connected(_on_new_game_pressed):
		new_game_btn.pressed.disconnect(_on_new_game_pressed)
	if settings_btn and settings_btn.pressed.is_connected(_on_settings_pressed):
		settings_btn.pressed.disconnect(_on_settings_pressed)
	if quit_btn and quit_btn.pressed.is_connected(_on_quit_pressed):
		quit_btn.pressed.disconnect(_on_quit_pressed)

	var save_manager: _SaveManager = AutoloadHelper.save_manager()
	if (
		save_manager != null
		and save_manager.save_changed.is_connected(_update_continue_button_state)
	):
		save_manager.save_changed.disconnect(_update_continue_button_state)


func _update_continue_button_state() -> void:
	var save_manager: _SaveManager = AutoloadHelper.save_manager()
	var has_save: bool = save_manager != null and save_manager.has_save()

	continue_btn.disabled = not has_save

	# Setup dynamic vertical wrap-around focus
	_setup_focus_wrap()


func _setup_focus_wrap() -> void:
	var focusable: Array[Button] = []
	for child: Node in button_container.get_children():
		if child is Button:
			var btn: Button = child as Button
			if not btn.disabled and btn.visible:
				focusable.append(btn)

	if focusable.size() < 2:
		return

	var first: Button = focusable[0]
	var last: Button = focusable[-1]

	first.focus_neighbor_top = last.get_path()
	last.focus_neighbor_bottom = first.get_path()


func _on_new_game_pressed() -> void:
	_print_debug("New Game pressed")
	if transition_layer:
		await transition_layer.fade_out()

	var run_manager: _RunManager = AutoloadHelper.run_manager()
	if run_manager != null:
		run_manager.cmd_start_run()
		# Delete existing save so Continue doesn't re-offer it on a fresh run
		var save_manager: _SaveManager = AutoloadHelper.save_manager()
		if save_manager != null:
			save_manager.delete_save()
	get_tree().change_scene_to_file("res://scenes/combat_room.tscn")


func _on_continue_pressed() -> void:
	_print_debug("Continue pressed")
	if transition_layer:
		await transition_layer.fade_out()

	var save_manager: _SaveManager = AutoloadHelper.save_manager()
	if save_manager == null:
		push_error("TitleScreen: SaveManager not available for Continue.")
		return
	var data: Dictionary = save_manager.load_game()
	if data.is_empty():
		push_warning("TitleScreen: Continue pressed but no valid save found.")
		return
	var run_manager: _RunManager = AutoloadHelper.run_manager()
	if run_manager != null and data.has("run_state"):
		run_manager.load_run_state(data["run_state"])
		get_tree().change_scene_to_file("res://scenes/combat_room.tscn")
	else:
		push_warning("TitleScreen: No run_state in save data.")


func _on_settings_pressed() -> void:
	SettingsModal.show_modal()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("TitleScreen: %s" % msg)

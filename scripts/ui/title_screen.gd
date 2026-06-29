extends Control

## TitleScreen (DON-298)
## Main entry point with focus management and localized rows.

@onready var continue_btn: Button = %ContinueButton
@onready var new_game_btn: Button = %NewGameButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var button_container: VBoxContainer = %ButtonContainer
@onready var premise_label: Label = %PremiseLabel
@onready var ember_particles: CPUParticles2D = $EmberParticles
var _button_animator: _ButtonAnimator = null


func _ready() -> void:
	# Localise text
	continue_btn.text = tr("menu.title.continue")
	new_game_btn.text = tr("menu.title.new_game")
	settings_btn.text = tr("menu.title.settings")
	quit_btn.text = tr("menu.title.quit")
	premise_label.text = tr("TITLE_PREMISE")

	# Enable Continue if a save exists
	var save_manager: _SaveManager = AutoloadHelper.save_manager()
	if save_manager != null and save_manager.has_save():
		continue_btn.disabled = false
	else:
		continue_btn.disabled = true

	# Connect signals
	if not continue_btn.disabled:
		continue_btn.pressed.connect(_on_continue_pressed)
	new_game_btn.pressed.connect(_on_new_game_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	# Enforce touch targets
	for btn: Button in [continue_btn, new_game_btn, settings_btn, quit_btn]:
		TouchTargetEnforcer.enforce(btn)

	# Setup dynamic vertical wrap-around focus
	_setup_focus_wrap()

	# Apply button micro-animations
	_button_animator = _ButtonAnimator.new()
	add_child(_button_animator)
	_button_animator.apply_to_buttons(button_container)

	# Position ember particles across bottom of viewport
	var viewport_size: Vector2 = get_viewport_rect().size
	ember_particles.position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.95)
	ember_particles.emission_rect_extents = Vector2(viewport_size.x * 0.5, 20.0)

	# Connect viewport resize for dynamic particle repositioning
	get_viewport().size_changed.connect(_on_viewport_resized)

	# Initial focus: Continue if enabled, otherwise New Game
	var target_btn: Button = continue_btn if not continue_btn.disabled else new_game_btn
	var focus_callable := func() -> void: target_btn.grab_focus()
	get_tree().process_frame.connect(focus_callable, CONNECT_ONE_SHOT)
	set_meta("_focus_callable", focus_callable)


func _exit_tree() -> void:
	var focus_callable: Variant = get_meta("_focus_callable", null)
	if focus_callable is Callable:
		if get_tree() and get_tree().process_frame.is_connected(focus_callable as Callable):
			get_tree().process_frame.disconnect(focus_callable as Callable)
	remove_meta("_focus_callable")
	if continue_btn and continue_btn.pressed.is_connected(_on_continue_pressed):
		continue_btn.pressed.disconnect(_on_continue_pressed)
	if new_game_btn and new_game_btn.pressed.is_connected(_on_new_game_pressed):
		new_game_btn.pressed.disconnect(_on_new_game_pressed)
	if settings_btn and settings_btn.pressed.is_connected(_on_settings_pressed):
		settings_btn.pressed.disconnect(_on_settings_pressed)
	if quit_btn and quit_btn.pressed.is_connected(_on_quit_pressed):
		quit_btn.pressed.disconnect(_on_quit_pressed)
	if get_viewport() and get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.disconnect(_on_viewport_resized)
	if is_instance_valid(_button_animator):
		_button_animator.queue_free()


func _on_viewport_resized() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	ember_particles.position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.95)
	ember_particles.emission_rect_extents = Vector2(viewport_size.x * 0.5, 20.0)


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
	var coordinator := AutoloadHelper.game_coordinator()
	if coordinator != null:
		coordinator.cmd_new_game()
	else:
		push_error("TitleScreen: GameCoordinator not found for New Game.")
		var tm := AutoloadHelper.toast_manager()
		if tm != null:
			tm.show_toast("TitleScreen: GameCoordinator not found", _ToastManager.ToastType.T_04)


func _on_continue_pressed() -> void:
	_print_debug("Continue pressed")
	var coordinator := AutoloadHelper.game_coordinator()
	if coordinator != null:
		coordinator.cmd_continue_game()
	else:
		push_error("TitleScreen: GameCoordinator not found for Continue.")


func _on_settings_pressed() -> void:
	SettingsModal.show_modal()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("TitleScreen: %s" % msg)

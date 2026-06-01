extends Control

## TitleScreen (DON-298)
## Main entry point with focus management and localized rows.

@onready var continue_btn: Button = %ContinueButton
@onready var new_game_btn: Button = %NewGameButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var button_container: VBoxContainer = %ButtonContainer


func _ready() -> void:
	# Localize text
	continue_btn.text = tr("menu.title.continue")
	new_game_btn.text = tr("menu.title.new_game")
	settings_btn.text = tr("menu.title.settings")
	quit_btn.text = tr("menu.title.quit")

	# Initial state
	continue_btn.disabled = true

	# Connect signals
	new_game_btn.pressed.connect(_on_new_game_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	# Enforce touch targets
	for btn: Button in [continue_btn, new_game_btn, settings_btn, quit_btn]:
		TouchTargetEnforcer.enforce(btn)

	# Setup dynamic vertical wrap-around focus
	_setup_focus_wrap()

	# Initial focus
	new_game_btn.grab_focus.call_deferred()


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
	# For now just print, as actual game start logic depends on other systems
	_print_debug("New Game pressed")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settings_pressed() -> void:
	# Assuming SettingsModal is a registered singleton or available via LayerManager
	_print_debug("Settings pressed")


func _on_quit_pressed() -> void:
	var confirm_scene := load("res://scenes/ui/confirm_modal.tscn") as PackedScene
	if confirm_scene:
		var modal := confirm_scene.instantiate()
		modal.setup("QUIT_TITLE", "QUIT_CONFIRM_BODY")
		modal.confirmed.connect(func() -> void: get_tree().quit())
		if Engine.get_main_loop().root.has_node("LayerManager"):
			LayerManager.add_modal(modal)
		else:
			add_child(modal)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("TitleScreen: %s" % msg)

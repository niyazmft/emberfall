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

	# Setup vertical wrap-around focus
	# Continue is disabled, so New Game is the first focusable
	new_game_btn.focus_neighbor_top = quit_btn.get_path()
	quit_btn.focus_neighbor_bottom = new_game_btn.get_path()

	# Initial focus
	new_game_btn.grab_focus.call_deferred()


func _on_new_game_pressed() -> void:
	# For now just print, as actual game start logic depends on other systems
	print("TitleScreen: New Game pressed")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settings_pressed() -> void:
	var settings_scene: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	if settings_scene:
		var settings_instance := settings_scene.instantiate()
		LayerManager.add_modal(settings_instance)


func _on_quit_pressed() -> void:
	get_tree().quit()

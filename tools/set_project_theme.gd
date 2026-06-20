extends SceneTree

func _init() -> void:
	var theme: Theme = load("res://main_theme.tres") as Theme
	ProjectSettings.set_setting("gui/theme/custom", "res://main_theme.tres")
	ProjectSettings.set_setting("gui/theme/custom_font", "res://assets/fonts/PressStart2P-Regular.ttf")
	ProjectSettings.save()
	print("Saved project settings")
	quit()

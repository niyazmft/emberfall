import re

with open("scripts/ui/main_menu.gd", "r") as f:
    content = f.read()

replacement = """func _on_quit_pressed() -> void:
	var confirm_scene := load("res://scenes/ui/confirm_modal.tscn") as PackedScene
	if confirm_scene:
		var modal := confirm_scene.instantiate()
		modal.setup("QUIT_TITLE", "QUIT_CONFIRM_BODY")
		modal.confirmed.connect(func(): get_tree().quit())
		LayerManager.add_modal(modal)
"""

content = re.sub(r"func _on_quit_pressed\(\) -> void:\n\tget_tree\(\)\.quit\(\)\n*", replacement, content)

with open("scripts/ui/main_menu.gd", "w") as f:
    f.write(content)

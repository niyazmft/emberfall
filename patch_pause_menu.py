import re

with open("scripts/ui/pause_menu.gd", "r") as f:
    content = f.read()

replacement = """func _on_quit_pressed() -> void:
	var confirm_scene := load("res://scenes/ui/confirm_modal.tscn") as PackedScene
	if confirm_scene:
		var modal := confirm_scene.instantiate()
		modal.setup("RETURN_SANCTUM_TITLE", "RETURN_SANCTUM_BODY")
		modal.confirmed.connect(func():
			get_tree().paused = false
			if RunManager.has_method("cmd_return_to_sanctum"):
				RunManager.call("cmd_return_to_sanctum")
			hide()
		)
		LayerManager.add_modal(modal)
"""

content = re.sub(r"func _on_quit_pressed\(\) -> void:\n\tget_tree\(\)\.paused = false\n\t# Assuming RunManager exists and has this method\n\tif RunManager\.has_method\(\"cmd_return_to_sanctum\"\):\n\t\tRunManager\.call\(\"cmd_return_to_sanctum\"\)\n\thide\(\)\n*", replacement, content)

with open("scripts/ui/pause_menu.gd", "w") as f:
    f.write(content)

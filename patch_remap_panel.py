import re

with open("scripts/ui/remap_panel.gd", "r") as f:
    content = f.read()

replacement = """func _on_reset_pressed() -> void:
	var confirm_scene := load("res://scenes/ui/confirm_modal.tscn") as PackedScene
	if confirm_scene:
		var modal := confirm_scene.instantiate()
		modal.setup("RESET_CONTROLS_TITLE", "RESET_CONTROLS_BODY")
		modal.confirmed.connect(
			func():
				InputMap.load_from_project_settings()
				save_bindings()
				create_action_list()
		)
		LayerManager.add_modal(modal)
"""

content = re.sub(r"func _on_reset_pressed\(\) -> void:\n\tInputMap\.load_from_project_settings\(\)\n\tsave_bindings\(\)\n\tcreate_action_list\(\)\n*", replacement, content)

with open("scripts/ui/remap_panel.gd", "w") as f:
    f.write(content)

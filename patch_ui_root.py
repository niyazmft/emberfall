import re

with open("scripts/ui/ui_root.gd", "r") as f:
    content = f.read()

replacement = """func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _settings_panel.visible:
			_settings_panel._on_back_pressed()
			get_viewport().set_input_as_handled()
		elif _main_menu.visible:
			if not LayerManager.is_modal_active():
				_main_menu._on_quit_pressed()
				get_viewport().set_input_as_handled()
		else:
			# Toggle Pause
			_pause_menu.toggle_pause()
			get_viewport().set_input_as_handled()
"""

content = re.sub(r"func _input\(event: InputEvent\) -> void:\n\tif event\.is_action_pressed\(\"ui_cancel\"\):\n\t\tif _settings_panel\.visible:\n\t\t\t_settings_panel\._on_back_pressed\(\)\n\t\t\tget_viewport\(\)\.set_input_as_handled\(\)\n\t\telif _main_menu\.visible:\n\t\t\t# Quit or show quit confirmation\n\t\t\tpass\n\t\telse:\n\t\t\t# Toggle Pause\n\t\t\t_pause_menu\.toggle_pause\(\)\n\t\t\tget_viewport\(\)\.set_input_as_handled\(\)\n*", replacement, content)

with open("scripts/ui/ui_root.gd", "w") as f:
    f.write(content)

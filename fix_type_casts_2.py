import re
import os

files_to_patch = [
    "scripts/ui/main_menu.gd",
    "scripts/ui/pause_menu.gd",
    "scripts/ui/title_screen.gd",
    "scripts/ui/remap_panel.gd"
]

for file_path in files_to_patch:
    with open(file_path, "r") as f:
        content = f.read()

    # Revert my bad regex replacement from fix_type_casts.py
    content = re.sub(r"var modal: Node = confirm_scene\.instantiate\(\) as Control", r"var modal := confirm_scene.instantiate()", content)
    content = re.sub(r"var modal: Node = confirm_scene\.instantiate\(\)", r"var modal := confirm_scene.instantiate()", content)

    with open(file_path, "w") as f:
        f.write(content)

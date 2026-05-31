import os
import re

files_to_patch = [
    "scripts/ui/main_menu.gd",
    "scripts/ui/pause_menu.gd",
    "scripts/ui/title_screen.gd",
    "scripts/ui/remap_panel.gd"
]

for file_path in files_to_patch:
    with open(file_path, "r") as f:
        content = f.read()

    # Replace `func():` with `func() -> void:`
    content = re.sub(r"func\(\):", r"func() -> void:", content)

    with open(file_path, "w") as f:
        f.write(content)

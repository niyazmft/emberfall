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

    # I'll replace `var modal: Node =` back to `var modal :=` but wait, it's missing the type.
    # What's the error exactly? Let's check `tools/godot_lint.log` from earlier.
    # `SCRIPT ERROR: Parse Error: Function "<anonymous lambda>()" has no static return type. (Warning treated as error.)`

    # Ah! We already fixed the lambda return type with `func() -> void:`!
    # Let me check if there's any other error.

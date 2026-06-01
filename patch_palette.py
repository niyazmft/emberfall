import re

with open(".Jules/palette.md", "r") as f:
    content = f.read()

replacement = """## $(date +%Y-%m-%d) - Add hand cursor to interactive UI nodes
**Learning:** Godot interactive UI nodes such as `CheckBox`, `OptionButton`, `HSlider`, and `TabContainer` do not show a pointing hand cursor on hover by default, leading to inconsistent UX where buttons have hand cursors but sliders/checkboxes do not.
**Action:** Set `mouse_default_cursor_shape = 2` (Pointing Hand) on all `HSlider`, `CheckBox`, `OptionButton`, and `TabContainer` nodes to improve interaction feedback consistently across the settings menu and UI.

## $(date +%Y-%m-%d) - Add confirmation modals to destructive actions
**Learning:** Destructive UI actions (like quitting the game, returning to the sanctum, or resetting control bindings) were happening instantly upon button press, which can lead to accidental data loss or unexpected game exits, resulting in poor UX.
**Action:** Added a generic `ConfirmModal` popup that requires the user to explicitly confirm these actions before the logic executes, improving safety and matching standard UX patterns."""

content = re.sub(r"<<<<<<< HEAD.*?=======\n(.*?)\n>>>>>>> b9af538 \(🎨 Palette: Add confirmation modals to destructive actions and fix lint errors\)", replacement, content, flags=re.DOTALL)

with open(".Jules/palette.md", "w") as f:
    f.write(content)

## 2026-05-31 - UI Initial Focus Keyboard Accessibility

**Learning:** Godot UI components (such as modals and dynamic lists) must explicitly call `grab_focus()` on their primary action button or first item using `call_deferred()` to ensure proper keyboard and gamepad accessibility when the UI appears or updates.

**Action:** I updated `main_menu.gd`, `pause_menu.gd`, and `settings_menu.gd` to ensure the primary button always grabs focus dynamically.

## 2026-05-31 - Add hand cursor to UI buttons

**Learning:** Godot Button nodes do not show a pointing hand cursor on hover by default, which is a standard UX expectation for clickable elements on PC.

**Action:** Set `mouse_default_cursor_shape = 2` (Pointing Hand) on all Button nodes to improve interaction feedback.

## 2026-06-03 - Add hand cursor to interactive UI nodes

**Learning:** Godot interactive UI nodes such as `CheckBox`, `OptionButton`, `HSlider`, and `TabContainer` do not show a pointing hand cursor on hover by default, leading to inconsistent UX where buttons have hand cursors but sliders/checkboxes do not.

**Action:** Set `mouse_default_cursor_shape = 2` (Pointing Hand) on all `HSlider`, `CheckBox`, `OptionButton`, and `TabContainer` nodes to improve interaction feedback consistently across the settings menu and UI.

## 2026-06-03 - Add confirmation modals to destructive actions

**Learning:** Destructive actions like quitting the game, returning to the sanctum (losing progress), or resetting controls were happening instantly without user confirmation. This is bad UX as it can lead to accidental data loss or frustration.

**Action:** Added a `ConfirmModal` (`res://scenes/ui/confirm_modal.tscn`) to intercept these actions. I updated `main_menu.gd` (quit), `pause_menu.gd` (return to sanctum), and `remap_panel.gd` (reset controls) to instantiate the modal, set up localized title/body text, and connect the confirmation signal to the actual destructive logic.

## 2026-05-31 - UI Initial Focus Keyboard Accessibility

**Learning:** Godot UI components (such as modals and dynamic lists) must explicitly call `grab_focus()` on their primary action button or first item using `call_deferred()` to ensure proper keyboard and gamepad accessibility when the UI appears or updates.

**Action:** Updated `main_menu.gd`, `pause_menu.gd`, and `settings_menu.gd` to ensure the primary button always grabs focus dynamically.

## 2026-05-31 - Add hand cursor to interactive UI nodes

**Learning:** Godot interactive UI nodes such as `Button`, `CheckBox`, `OptionButton`, `HSlider`, and `TabContainer` do not show a pointing hand cursor on hover by default, leading to inconsistent UX.

**Action:** Set `mouse_default_cursor_shape = 2` (Pointing Hand) on all interactive UI nodes to improve interaction feedback consistently.

## 2026-06-03 - Add confirmation modals to destructive actions

**Learning:** Destructive actions like quitting the game, returning to the sanctum (losing progress), or resetting controls were happening instantly without user confirmation. This is bad UX as it can lead to accidental data loss or frustration.

**Action:** Added a `ConfirmModal` (`res://scenes/ui/confirm_modal.tscn`) to intercept these actions. I updated `main_menu.gd` (quit), `pause_menu.gd` (return to sanctum), and `remap_panel.gd` (reset controls) to instantiate the modal and connect the confirmation signal.

## 2026-06-05 - UI Modal inheritance and signal cleanup

**Learning:** Custom UI modals should inherit from the `_Modal` base class. Subclasses must call `super._exit_tree()` to ensure that common cleanup, such as disconnecting close button signals, is performed to prevent memory leaks or crashes during scene transitions.

**Action:** Updated `ConfirmModal`, `VictoryModal`, and `DefeatModal` to properly call `super._exit_tree()`.

## $(date +%Y-%m-%d) - [UI Initial Focus Keyboard Accessibility]
**Learning:** [Godot UI components (such as modals and dynamic lists) must explicitly call `grab_focus()` on their primary action button or first item using `call_deferred()` to ensure proper keyboard and gamepad accessibility when the UI appears or updates.]
**Action:** [I updated `main_menu.gd`, `pause_menu.gd`, and `settings_menu.gd` to ensure the primary button always grabs focus dynamically.]

## 2026-05-31 - Add hand cursor to UI buttons
**Learning:** Godot Button nodes do not show a pointing hand cursor on hover by default, which is a standard UX expectation for clickable elements on PC.
**Action:** Set `mouse_default_cursor_shape = 2` (Pointing Hand) on all Button nodes to improve interaction feedback.

## $(date +%Y-%m-%d) - Add confirmation modals to destructive actions
**Learning:** Destructive UI actions (like quitting the game, returning to the sanctum, or resetting control bindings) were happening instantly upon button press, which can lead to accidental data loss or unexpected game exits, resulting in poor UX.
**Action:** Added a generic `ConfirmModal` popup that requires the user to explicitly confirm these actions before the logic executes, improving safety and matching standard UX patterns.

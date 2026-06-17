## 2026-05-31 - UI Initial Focus Keyboard Accessibility

**Learning:** Godot UI components (such as modals and dynamic lists) must explicitly call `grab_focus()` on their primary action button or first item using `call_deferred()` to ensure proper keyboard and gamepad accessibility when the UI appears or updates.

**Action:** When implementing keyboard-accessible menus, always call `grab_focus.call_deferred()` on the primary button (or first interactive element) immediately after the menu/modal becomes visible. Do this in `_ready()`, `_enter_tree()`, or after tween/animation completion callbacks. Never assume focus will land correctly by default.

## 2026-05-31 - Add hand cursor to interactive UI nodes

**Learning:** Godot interactive UI nodes (`Button`, `CheckBox`, `OptionButton`, `HSlider`, `TabContainer`) do not show a pointing hand cursor on hover by default, leading to inconsistent UX where some elements feel clickable while others do not.

**Action:** Set `mouse_default_cursor_shape = 2` (Pointing Hand) on all interactive UI nodes to provide consistent interaction feedback across the entire UI.

## 2026-06-03 - Add confirmation modals to destructive actions

**Learning:** Destructive actions like quitting the game, returning to the sanctum (losing progress), or resetting controls were happening instantly without user confirmation. This is bad UX as it can lead to accidental data loss or frustration.

**Action:** Before allowing any destructive action (quit, return to sanctum, reset controls, delete save), instantiate a `ConfirmModal` (`res://scenes/ui/confirm_modal.tscn`), configure localized title and body text, and connect its `confirmed` signal to the actual destructive logic. Do not execute the action directly from the button press.

## 2026-06-17 - Use _unhandled_input() for game-level input behind UI

**Learning:** When a combat scene uses `_input(event)`, UI button clicks and menu interactions are intercepted before the UI layer can consume them, causing buttons to trigger player movement or end-turn actions. Godot's `_unhandled_input()` is specifically designed for this: Control nodes process events first; only unhandled events bubble up to `_unhandled_input()`.

**Action:** For any gameplay input handler that runs alongside UI (combat rooms, overworld maps), always use `_unhandled_input()` instead of `_input()`. Reserve `_input()` for global shortcuts that must work even when UI is focused (e.g., screenshot key).

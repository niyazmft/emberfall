## $(date +%Y-%m-%d) - [UI Initial Focus Keyboard Accessibility]
**Learning:** [Godot UI components (such as modals and dynamic lists) must explicitly call `grab_focus()` on their primary action button or first item using `call_deferred()` to ensure proper keyboard and gamepad accessibility when the UI appears or updates.]
**Action:** [I updated `main_menu.gd`, `pause_menu.gd`, and `settings_menu.gd` to ensure the primary button always grabs focus dynamically.]

## 2026-05-31 - Add hand cursor to UI buttons
**Learning:** Godot Button nodes do not show a pointing hand cursor on hover by default, which is a standard UX expectation for clickable elements on PC.
**Action:** Set `mouse_default_cursor_shape = 2` (Pointing Hand) on all Button nodes to improve interaction feedback.

## $(date +%Y-%m-%d) - Add hand cursor to interactive UI nodes
**Learning:** Godot interactive UI nodes such as `CheckBox`, `OptionButton`, `HSlider`, and `TabContainer` do not show a pointing hand cursor on hover by default, leading to inconsistent UX where buttons have hand cursors but sliders/checkboxes do not.
**Action:** Set `mouse_default_cursor_shape = 2` (Pointing Hand) on all `HSlider`, `CheckBox`, `OptionButton`, and `TabContainer` nodes to improve interaction feedback consistently across the settings menu and UI.

## 2026-05-31 - Add confirmation modals to destructive actions
**Learning:** Destructive actions like quitting the game, returning to the sanctum (losing progress), or resetting controls were happening instantly without user confirmation. This is bad UX as it can lead to accidental data loss or frustration.
**Action:** Added a `ConfirmModal` (`res://scenes/ui/confirm_modal.tscn`) to intercept these actions. I updated `main_menu.gd` (quit), `pause_menu.gd` (return to sanctum), and `remap_panel.gd` (reset controls) to instantiate the modal, set up localized title/body text, and connect the confirmation signal to the actual destructive logic.

## 2026-06-20 - Prevent text clipping on retro buttons with content margins

**Learning:** When using Godot's `Button` nodes with a `StyleBoxFlat` for custom retro pixel-art styling, the text naturally expands to the exact edges of the background rectangle. This causes ugly visual clipping, especially in tight HUD containers.

**Action:** Always define `content_margin_left`, `right`, `top`, and `bottom` explicitly within the `StyleBoxFlat` theme overrides for buttons (e.g., in `main_theme.tres`) so that text rests comfortably inside the box.

## 2026-06-20 - Global styling for unstyled default ProgressBars

**Learning:** Godot's default `ProgressBar` node renders as a flat, solid grey rectangle, which breaks the immersion of custom retro art styles. Attempting to set `modulate` does not properly style the underlying structural elements.

**Action:** Create a global `StyleBoxFlat` override for both the `background` and `fill` layers of the `ProgressBar` inside the main `.tres` theme file, giving them distinct colors (e.g., a transparent dark background and a solid red fill for HP) to match the game's palette.

## 2026-06-20 - Remove debug color modulation from finalized visual proxies

**Learning:** During blockout phases, we tinted `visual_proxy.modulate` with debug colors (e.g., red for bosses, green for archers) to differentiate enemies. However, when actual pixel art is imported, this debug `modulate` permanently tints the real textures, making them look broken or overly saturated.

**Action:** Strip `modulate = debug_color` from visual proxy setup logic (like `base_enemy.gd`) as soon as actual artwork is attached to the scene. Additionally, remember to remove any legacy `GdUnit4` assertions that were strictly checking for those debug `modulate` colors.

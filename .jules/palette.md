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

## 2026-06-17 - Placeholder audio files with identical checksums are undetectable by eye

**Learning:** Four burden audio stem placeholders (`bd_drone.ogg`, `bd_bells.ogg`, `bd_voices.ogg`, `bd_wind.ogg`) were created with identical file sizes and MD5 hashes, meaning they were copies of the same dummy file. Godot would load them without error, but all stems would sound identical in a debug build, making audio coordination bugs impossible to hear.

**Action:** Always run `md5sum` on placeholder audio files after creation. If all hashes match, generate distinct content programmatically (different frequencies, waveforms, or amplitude envelopes) so each placeholder has a unique acoustic signature. Switch to `.wav` format during placeholder phase if Ogg Vorbis encoding tools are unavailable.

## 2026-06-28 - Automated batch asset processing and Godot UID resolution

**Learning:** When injecting batch GenAI visual assets or generating multiple interactive button states (Normal, Hover, Disabled) for UI icons, relying solely on real-time AI generation can hit quota limits and result in inconsistent styling or invalid UIDs in Godot scenes. Using Python's Pillow (PIL) library to programmatically derive hover/disabled states (via brightness enhancement and desaturation) and resize assets ensures uniform design tokens across all UI controls, while running `godot --headless --editor --quit` ensures all new `.png` files receive valid `.import` files and UIDs automatically without manual editor intervention.

**Action:** When performing bulk asset updates or adding new UI button icons, write a Python script utilizing Pillow to process and save the assets as transparent PNGs into `assets/sprites/` and `assets/icons/`. Following the generation, execute `PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" godot --headless --editor --quit` to verify and generate UIDs before running pre-push validation tests.

## 2026-06-28 - Dynamic ProgressBar stylebox overrides and ShaderMaterial tweening in Godot 4

**Learning:** Godot 3 legacy stylebox property names `bg` and `fg` fail silently when used with `add_theme_stylebox_override` on a Godot 4 `ProgressBar`, resulting in unstyled or broken progress bars. Furthermore, using `tween_property` to animate `shader_parameter/u_blur_amount` on a `ShaderMaterial` fails with a property lookup error in headless unit tests where dynamic property lists are not fully built or populated by the editor.

**Action:** Always use Godot 4 standard stylebox override names `background` and `fill` when dynamically styling `ProgressBar` nodes in script. When tweening shader parameters on a `ShaderMaterial`, use `tween_method` with a callable that explicitly executes `set_shader_parameter("param_name", value)` to ensure robust execution across both graphical and headless test runner environments.

## 2026-06-28 - Preventing solid grey rectangles from SubViewports and untextured CPUParticles2D

**Learning:** In Godot 4, `SubViewport` nodes default to `transparent_bg = false`, which causes UI elements containing subviewports (such as minimap containers) to render as large, opaque solid grey rectangles over the screen. Additionally, `CPUParticles2D` nodes without an assigned `texture` render solid untextured grey square quads, creating unwanted geometric artifacting across the environment.

**Action:** Always set `transparent_bg = true` on `SubViewport` nodes used within UI overlays or minimap containers to ensure seamless compositing over the game world. For `CPUParticles2D` nodes, define a built-in `GradientTexture2D` sub-resource with a radial gradient (`fill = 1`) directly in the `.tscn` scene file to provide a clean, soft glowing particle texture without relying on external image dependencies.

## 2026-06-28 - Dynamic environmental prop placement and unit test compatibility

**Learning:** When transitioning a tactical grid floor from a greybox blockout (where cover tiles use basic modulated diamond sprites) to a premium textured environment using distinct 2D prop assets (`prop_rock.png`, `prop_broken_pillar.png`), legacy unit tests checking for strict color modulation (`COLOR_COVER`) will fail if the premium props are unmodulated to preserve their natural art palette.

**Action:** When upgrading grid renderers to support dynamic prop placement, ensure unit test assertions validate both legacy color modulation and the presence of premium prop textures. Additionally, leverage deterministic hashing (`tile_seed % 100`) to sprinkle environmental detail props (`prop_cracked_tile.png`, `prop_debris.png`, `prop_burnt_wood.png`) across empty tiles without breaking procedural test determinism.

## 2026-06-28 - Godot TSCN parent path updates when wrapping existing nodes in containers

**Learning:** When modifying a `.tscn` scene file directly in text to wrap an existing node (e.g., `PanelContainer`) inside a layout wrapper like `MarginContainer`, all child nodes of the existing node will fail to instantiate if their `parent="..."` attribute is not updated. In Godot `.tscn` files, the `parent` attribute specifies the node path relative to the scene's root node, meaning any new wrapper layers must be explicitly prepended to the parent paths of all existing descendants.

**Action:** When wrapping an existing node in a new parent container within a `.tscn` file, ensure you update the `parent` attribute of all child and descendant nodes to include the new container prefix (e.g., changing `parent="PanelContainer"` to `parent="MarginContainerTopRight/PanelContainer"`). Also update any `@onready` node paths in the associated `.gd` script accordingly.

## 2026-06-28 - Persistent global pause menu instantiation and PROCESS_MODE_ALWAYS in LayerManager

**Learning:** In Godot 4, relying on a standalone UI root scene (`ui_root.tscn`) to handle global input actions like `ui_cancel` (Escape) fails during gameplay if the active gameplay scene (`CombatRoom`) does not explicitly instantiate that UI root. Furthermore, when creating a global pause menu managed by an autoload singleton like `LayerManager`, the singleton must be explicitly set to `process_mode = Node.PROCESS_MODE_ALWAYS`. Without `PROCESS_MODE_ALWAYS`, as soon as `get_tree().paused = true` is executed, the singleton stops processing input events, trapping the game in a permanently paused state where the player cannot press Escape again to unpause.

**Action:** When implementing global pause functionality and modal layer management across multiple scenes, instantiate the `PauseMenu` as a permanent child of the `LayerManager` autoload singleton upon startup, and explicitly set `process_mode = Node.PROCESS_MODE_ALWAYS` on the singleton. Intercept `ui_cancel` in `_input(event)` within `LayerManager` to intelligently toggle pause or dismiss active modals regardless of the active scene hierarchy.


## 2024-05-26 - [Keyboard Navigation Focus]
**Learning:** UI panels with dynamic content or modals in Godot should explicitly call `grab_focus()` on key elements to ensure controller/keyboard accessibility.
**Action:** When adding modals or dynamic lists (like `remap_panel`), remember to default-focus primary actions or the first item in the list via `call_deferred` to support non-mouse inputs.

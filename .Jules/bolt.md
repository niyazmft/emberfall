## 2026-05-28 - Optimize GridSystem._recompute_cover_cache()
**Learning:** Optimizing Godot GDScript O(N^2) inner loops can yield huge performance benefits. Inlining functions and accessing arrays directly (e.g., `_tiles[ti]`) avoids the overhead of function calls (`get_tile()`) in hot paths.
**Action:** Always verify loop boundaries and reduce unnecessary iterations in hot paths, especially when working with grid-based systems.
## 2026-05-29 - Fix CI GDScript lint check
**Learning:** Adding new test files and scripts requires strictly typing the variables to pass the automated GDScript lint check in the GitHub CI Actions pipeline.
**Action:** When creating benchmark or any  scripts, add static types to all variables (e.g. `var t0: float`).

## 2026-05-29 - Fix CI GDScript lint check
**Learning:** Adding new test files and scripts requires strictly typing the variables to pass the automated GDScript lint check in the GitHub CI Actions pipeline.
**Action:** When creating benchmark or any `.gd` scripts, add static types to all variables (e.g. `var t0: float`).
## 2024-05-28 - Optimizing grid_system string/dictionary accesses
**Learning:** In Godot GDScript, hot loop operations inside pathfinding (`can_move`, `has_los`) that rely on `Resource.get("...")` or `.call("...")` are incredibly slow due to string-based dynamic dispatch. Even for autoloads like `GridSystem`, typing internal arrays to strongly typed variants (`TacTileData`) and accessing variables natively drops loop time from 20ms+ down to ~1-2ms.
**Action:** Always cast explicitly to `TacTileData` when dealing with the flat array in `GridSystem` to unlock GDScript type-safe attribute checks, specifically utilizing bitwise `cover_flags` for logic inside tight loops.
## 2026-06-03 - Cache Dictionary Lookups inside `_process`
**Learning:** Caching dictionary lookups (e.g. `config.get("key", {})`) inside `_process` prevents per-frame allocations and dictionary hashing overhead.
**Action:** Extract nested config properties to cached variables populated at init-time for frequently executing methods like `_process`.

## 2025-02-27 - [Godot Dictionary iteration]
**Learning:** Deleting from a Dictionary while iterating over its keys() returns a new array, but iterating over the dictionary directly is faster and we can store keys to erase in a local array and erase them after the loop. Iterating over `keys()` makes a copy of the keys, causing array allocation and garbage collection churn inside `_process`.
**Action:** Don't use `keys()` inside high-frequency loops like `_process`. Use a custom array or iterate without modifying the dictionary, keeping track of keys to remove.
## 2026-06-08 - No-op mobile autoloads avoid per-frame resize signal overhead
**Learning:** Autoloads that hook into `get_tree().root.size_changed` fire on every window resize, which on desktop happens frequently during window management and monitor changes. Converting the mobile-only `SafeZoneManager` to a no-op eliminated ~5 signal emissions per resize event and removed all `DisplayServer.get_display_safe_area()` calls (which internally query OS compositor state). All existing callers that connect to `safe_area_changed` and call `get_safe_margins()`/`get_notch_offset()`/`is_portrait()` still compile and run unchanged because the API surface is preserved.
**Action:** When targeting desktop-only, evaluate every autoload for mobile-specific signals (size_changed, DisplayServer safe-area queries, etc.). If the autoload API is widely referenced, convert it to a no-op rather than removing it, preserving the class_name and signal signatures so downstream code doesn't break. Prefix the class_name with an underscore per CI rules if the autoload name shadows a global.

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

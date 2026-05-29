## 2026-05-28 - Optimize GridSystem._recompute_cover_cache()
**Learning:** Optimizing Godot GDScript O(N^2) inner loops can yield huge performance benefits. Inlining functions and accessing arrays directly (e.g., `_tiles[ti]`) avoids the overhead of function calls (`get_tile()`) in hot paths.
**Action:** Always verify loop boundaries and reduce unnecessary iterations in hot paths, especially when working with grid-based systems.
## 2026-05-29 - Fix CI GDScript lint check
**Learning:** Adding new test files and scripts requires strictly typing the variables to pass the automated GDScript lint check in the GitHub CI Actions pipeline.
**Action:** When creating benchmark or any  scripts, add static types to all variables (e.g. `var t0: float`).

## 2026-05-29 - Fix CI GDScript lint check
**Learning:** Adding new test files and scripts requires strictly typing the variables to pass the automated GDScript lint check in the GitHub CI Actions pipeline.
**Action:** When creating benchmark or any `.gd` scripts, add static types to all variables (e.g. `var t0: float`).

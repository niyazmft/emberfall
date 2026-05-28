## 2026-05-28 - Optimize GridSystem._recompute_cover_cache()
**Learning:** Optimizing Godot GDScript O(N^2) inner loops can yield huge performance benefits. Inlining functions and accessing arrays directly (e.g., `_tiles[ti]`) avoids the overhead of function calls (`get_tile()`) in hot paths.
**Action:** Always verify loop boundaries and reduce unnecessary iterations in hot paths, especially when working with grid-based systems.

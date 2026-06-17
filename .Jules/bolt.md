## 2024-05-28 - Optimizing grid_system string/dictionary accesses

**Learning:** In Godot GDScript, hot loop operations inside pathfinding (`can_move`, `has_los`) that rely on `Resource.get("...")` or `.call("...")` are incredibly slow due to string-based dynamic dispatch. Even for autoloads like `GridSystem`, typing internal arrays to strongly typed variants (`TacTileData`) and accessing variables natively drops loop time from 20ms+ down to ~1-2ms.

**Action:** Always cast explicitly to `TacTileData` when dealing with the flat array in `GridSystem` to unlock GDScript type-safe attribute checks, specifically utilizing bitwise `cover_flags` for logic inside tight loops.

## 2025-02-27 - Godot Dictionary iteration

**Learning:** Deleting from a Dictionary while iterating over its keys() returns a new array, but iterating over the dictionary directly is faster and we can store keys to erase in a local array and erase them after the loop. Iterating over `keys()` makes a copy of the keys, causing array allocation and garbage collection churn inside `_process`.

**Action:** Don't use `keys()` inside high-frequency loops like `_process`. Use a custom array or iterate without modifying the dictionary, keeping track of keys to remove.

## 2026-05-28 - Optimize GridSystem._recompute_cover_cache()

**Learning:** Optimizing Godot GDScript O(N^2) inner loops can yield huge performance benefits. Inlining functions and accessing arrays directly (e.g., `_tiles[ti]`) avoids the overhead of function calls (`get_tile()`) in hot paths.

**Action:** Always verify loop boundaries and reduce unnecessary iterations in hot paths, especially when working with grid-based systems.

## 2026-05-29 - Fix CI GDScript lint check

**Learning:** Adding new test files and scripts requires strictly typing the variables to pass the automated GDScript lint check in the GitHub CI Actions pipeline.

**Action:** When creating benchmark or any `.gd` scripts, add static types to all variables (e.g. `var t0: float`).

## 2026-06-03 - Cache Dictionary Lookups inside `_process`

**Learning:** Caching dictionary lookups (e.g. `config.get("key", {})`) inside `_process` prevents per-frame allocations and dictionary hashing overhead.

**Action:** Extract nested config properties to cached variables populated at init-time for frequently executing methods like `_process`.

## 2026-06-04 - Callable.bind() creates unique instances

**Learning:** In Godot 4, `Callable.bind()` returns a new `Callable` object each time it is called. Using `.bind()` directly in `connect()` and then trying to `disconnect()` with a new `.bind()` call will fail to find the original connection.

**Action:** Store the result of `.bind()` in a member variable or dictionary if you need to disconnect it later, specifically in `_exit_tree()` to avoid signal leakage.

## 2026-06-10 - DeterministicMath is a static utility

**Learning:** `DeterministicMath` is defined as a global `class_name` that does not extend `Node`. It is a pure static utility and should never be added to the scene tree or instantiated as a node.

**Action:** Access `DeterministicMath` methods directly via the class name instead of attempting to use `get_node()` or `instance()`.

## 2026-06-11 - RunManager room data encapsulation

**Learning:** To maintain proper encapsulation, the `RunManager` should expose room metadata via a public `get_current_room_data()` method instead of internal private variables, ensuring combat modules have a stable API for environment state.

**Action:** Refactor `CombatRoom` and `RoomLoader` to use the new public `get_current_room_data()` method.

## 2026-06-17 - @onready caches eliminate per-frame get_node traversal

**Learning:** Calling `get_node_or_null("ApparitionRenderer")` in `_process()` or even `_ready()` every time a node is needed causes repeated scene-tree traversal overhead. Jules replaced runtime lookups in `EntityVisualProxy` and `BaseEnemy` with `@onready var _apparition_renderer: ApparitionRenderer = _find_apparition_renderer()` and a helper that checks self then parent once at initialization. This removes tree-walk from the per-frame `_process` path entirely.

**Action:** When a node needs repeated access to a child node (especially in `_process`), cache the reference with `@onready` or in `_ready()`. If the child might be on a sibling or parent, write a one-shot helper that resolves the reference at init-time rather than looking it up dynamically.

## 2026-06-17 - Mass .call() migration: type safety and small perf gain

**Learning:** A codebase-wide sweep of ~30 `.call("method", args)` instances on typed autoloads and UI nodes showed that every single one could be replaced with a direct typed method call once the target class had `class_name`. The migration had zero behavioral change but restored compile-time type checking and slightly reduced string-dispatch overhead.

**Action:** When auditing `.call()` anti-patterns, prefer "acquire typed ref → verify target has class_name → replace string call with direct call" as the standard three-step fix. Only retain `.call()` for genuinely polymorphic cases (dictionary state callbacks, generic Node interfaces without class_name).

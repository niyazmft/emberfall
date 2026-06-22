## 2026-05-31 - Insecure Deserialization in RemapPanel
**Vulnerability:** The input rebinding system (`scripts/ui/remap_panel.gd`) previously used `inst_to_dict()` and `dict_to_inst()` to serialize and deserialize `InputEvent` objects to/from the `user://remap.save` file. This could lead to Insecure Deserialization, as a maliciously crafted `user://remap.save` could inject an arbitrary `@path` property into the JSON that could execute arbitrary Godot resources when `dict_to_inst()` parsed it.
**Learning:** Functions like `inst_to_dict()` and `dict_to_inst()` are inherently unsafe to use on user-writable files because they lack type guards during deserialization.
**Prevention:** Avoid `inst_to_dict()` and `dict_to_inst()` entirely for persistence. Use explicit serialization and deserialization functions that perform strict type validation and assign properties directly rather than blindly instantiating arbitrary dictionaries.

## 2026-06-01 - File Encryption for User Settings
**Vulnerability:** The `SettingsManager` autoload (`scripts/autoload/settings_manager.gd`) previously used `FileAccess.open(..., FileAccess.WRITE)` and `FileAccess.open(..., FileAccess.READ)` in plaintext, combined with `store_var()` and `get_var()`. This could lead to local file tampering or insecure deserialization (arbitrary object instantiation) via a maliciously crafted `user://settings.save` file.
**Learning:** Saving and loading user data in plaintext using `get_var()` can expose the application to malicious local modifications or deserialization attacks if a user shares or replaces their save file.
**Prevention:** Always use `FileAccess.open_encrypted_with_pass()` with a deterministically generated, per-device or secure salt when saving data via `store_var()` to ensure integrity and prevent trivial tampering.

## 2026-06-01 - File Encryption for User Input Bindings
**Vulnerability:** The `RemapPanel` script (`scripts/ui/remap_panel.gd`) previously used `FileAccess.open(..., FileAccess.WRITE)` and `FileAccess.open(..., FileAccess.READ)` in plaintext, combined with `store_var()` and `get_var()`. This could lead to local file tampering or insecure deserialization (arbitrary object instantiation) via a maliciously crafted `user://remap.save` file.
**Learning:** Saving and loading user input bindings in plaintext using `get_var()` can expose the application to malicious local modifications or deserialization attacks if a user shares or replaces their save file.
**Prevention:** Always use `FileAccess.open_encrypted_with_pass()` with a deterministically generated, per-device or secure salt when saving data via `store_var()` to ensure integrity and prevent trivial tampering.

## 2026-06-08 - Clean up orphaned .gd.uid files after script deletion
**Learning:** Deleting GDScript files outside of the Godot editor (e.g., via git or filesystem) often leaves behind orphaned .gd.uid sidecar files. These files are used by Godot's resource system for tracking but become redundant clutter once the main script is gone, potentially causing import warnings in the editor and dirtying the repository state.
**Action:** When deleting .gd scripts from the repository, always check for and remove any corresponding .gd.uid files to maintain repository cleanliness and prevent phantom errors.

## 2026-06-12 - Expression.execute const_calls_only doesn't block globals
**Learning:** Godot's Expression.execute method with the const_calls_only flag set to true prevents calling non-constant methods on objects, but it does NOT block access to global functions like print() or OS.get_name() if the instance passed is null. This creates a code injection risk when evaluating formulas from external configurations.
**Action:** Before calling Expression.parse(), implement a manual whitelist check for identifiers in the formula. Extract all identifiers using RegEx and verify that they are either numeric literals or explicitly allowed variable names from the provided context dictionary.

## 2026-06-20 - instance_from_id() without is_instance_valid() is a use-after-free trap

**Learning:** `EntityLifecycle` used `Dictionary` keyed by `instance_id` (int) to track dying/stunned entities across turns. When `CombatRoom` freed entities via `queue_free()`, the `Entity` `Resource` (RefCounted) could be freed while the dictionary still held the integer key. Calling `instance_from_id(id)` on the next `process_end_of_turn()` returned a dangling pointer — classic use-after-free leading to crash or silent corruption.

**Action:** Always guard `instance_from_id()` with `is_instance_valid(obj)` before dereferencing. Better: avoid storing raw instance IDs for long-lived tracking; use `WeakRef` or notify the lifecycle owner explicitly when entities are freed (e.g., `clear_timers()` on room teardown).

## 2026-06-20 - EventBus signal leaks survive node freedom if not explicitly disconnected

**Learning:** `CombatRoom` connected to `EventBus` and `RunManager` signals in `_ready()` but had no `_exit_tree()` disconnect. While Godot auto-disconnects signals on `queue_free()` for plain method bindings, the pattern is fragile — nodes removed from tree without freeing, autoload references, or capturing lambdas all leak. After scene transitions, duplicate connections accumulated and callbacks fired on stale object references.

**Action:** Every node that `.connect()`s to autoload signals in `_ready()` must `.disconnect()` in `_exit_tree()` — always, explicitly, defensively. Verify with `is_connected()` before disconnecting to avoid double-disconnect errors.

## 2026-06-20 - MAX_ITERATIONS abort must emit terminal signal before returning

**Learning:** `TurnManager._process_state_loop()` capped iterations at 200 and set `current_state = COMBAT_END` on breach, but never emitted `combat_ended`. Any listener waiting for that signal (victory/defeat modals, scene transitioners) hung indefinitely. The game appeared frozen even though the state machine had technically terminated.

**Action:** Any "abort / safety exit" path that short-circuits a state machine must still emit the terminal lifecycle signal expected by downstream listeners. The abort handler is not exempt from the normal termination contract.

## 2026-06-22 - Typed Dictionary parameters in static methods crash Godot 4.6.3 cleanup

**Learning:** Using `Dictionary[Vector2i, bool]` as a typed parameter in a `static func` causes a segfault during Godot engine cleanup (`GDScriptInstance::~GDScriptInstance()` in `ObjectDB::cleanup()`). The crash only surfaces when running the FULL test suite — individual test files pass fine.

**Action:** NEVER use typed Dictionary annotations (`Dictionary[K, V]`) in Godot 4.6.3 public/static method signatures. Use plain `Dictionary` and rely on `.has(key)` for O(1) lookups. Build the Dictionary locally inside the function body, not as a typed parameter.

## 2026-06-22 - Object reference in static var survives engine shutdown

**Learning:** A `static var _cached_tree: SceneTree = null` in `AutoloadHelper` stored a direct Object reference. During Godot shutdown, the static var outlived the engine's cleanup sequence and caused a recursive mutex crash (`std::__1::recursive_mutex::lock()` in `GDScriptInstance::~GDScriptInstance()`).

**Action:** NEVER store Object references in `static var`. Always store only the integer `get_instance_id()` and resolve via `instance_from_id()` on each call. This pattern eliminates object lifetime issues entirely.

## 2026-06-22 - External HP modification breaks alive-enemy count invariant

**Learning:** `TurnManager` tracked `_alive_enemy_count` via signal-driven decrement on `Entity.State.DEAD`. But tests directly set `enemy.hp = 0` without going through `EntityLifecycle.apply_damage()`, so the signal never fired and `_alive_enemy_count` became stale. `_is_combat_over()` returned false even though all enemies were dead.

**Action:** When tracking derived counts (alive enemies, active buffs, etc.), always add a test-safe fallback that verifies the count against a real scan when the count claims items exist. Reset the count and scan if the quick check fails.

## 2026-06-22 - Worker prompts with `git push origin` leak remote branches

**Learning:** Batch 1 worker prompts included `git push origin fix/c1-victory-menu`. Workers pushed 5 remote branches (`fix/c1-*`, `fix/c3-*`, etc.) to origin that had to be manually deleted. This polluted the remote repo and confused other developers.

**Action:** NEVER include `git push origin` in subagent worker prompts. Workers must ONLY commit locally and report diffs via output files. The coordinator handles all remote interactions.

## 2026-06-22 - `subagent worktree: true` leaks worker commits into coordinator tree

**Learning:** Using `subagent` with `worktree: true` caused a worker's commits on `fix/c7-title-visuals` to spontaneously appear in the coordinator's working tree. The commit `fe369d9` was visible in `git status` even though the coordinator was on a different branch.

**Action:** NEVER use `worktree: true` in `subagent` calls. Always use `context: "fresh"` to ensure complete isolation between worker and coordinator environments.

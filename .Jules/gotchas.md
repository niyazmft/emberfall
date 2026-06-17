# Godot Gotchas & Quirks

## 2026-06-08 - Clean up orphaned .gd.uid files after script deletion

**Learning:** Deleting GDScript files outside of the Godot editor (e.g., via git or filesystem) often leaves behind orphaned .gd.uid sidecar files. These files are used by Godot's resource system for tracking but become redundant clutter once the main script is gone, potentially causing import warnings in the editor.

**Action:** When deleting .gd scripts from the repository, always check for and remove any corresponding .gd.uid files to maintain repository cleanliness.

## 2026-06-12 - Expression.execute const_calls_only doesn't block globals

**Learning:** Godot's Expression.execute method with the const_calls_only flag set to true prevents calling non-constant methods on objects, but it does NOT block access to global functions like print() or OS.get_name() if the instance passed is null. This creates a code injection risk when evaluating formulas from external configurations.

**Action:** Before calling Expression.parse(), implement a manual whitelist check for identifiers in the formula. Extract all identifiers using RegEx and verify that they are either numeric literals or explicitly allowed variable names from the provided context dictionary.

## 2026-06-17 - Node.get("property") is as dangerous as Object.call("method")

**Learning:** `Node.get("property_name")` and `Object.call("method_name", args)` are the same class of dynamic dispatch anti-pattern. Both rely on string-based lookups at runtime that bypass GDScript's type checker and hurt performance. Jules found 17 instances of `.get("entity")` alongside 30+ `.call()` instances. Replacing `.get("entity")` with a typed static helper `CombatEntity.get_entity(node)` eliminates the string lookup entirely and gives compile-time safety.

**Action:** Treat `.get("...")` on nodes as the same priority as `.call("...")` during audits. When a commonly accessed property (like `entity` on `CombatEntity` subclasses) is fetched dynamically, add a typed static accessor or getter method and migrate all call sites.

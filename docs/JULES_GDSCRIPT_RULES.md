# 📜 Google Jules: GDScript Engineering Rules

You are working on a **Godot 4.2+ GDScript-only** project. To ensure bit-for-bit determinism and compatibility with our strict-typing standards, you MUST follow these rules exactly.

## 1. Strict Typing (Mandatory)
The project uses `untyped_declaration=2`. Inferred types (`:=`) are only allowed for literals.
*   **BAD:** `var target := get_node("Sprite")` (Compiler error: cannot infer type)
*   **GOOD:** `var target: Sprite2D = get_node("Sprite")`
*   **GOOD:** `var i: int = 0` OR `var i := 0` (Literal inference is OK)

## 2. Autoload Singleton Convention
To prevent "Class X hides an autoload singleton" errors, follow this naming convention:
*   If a script is an Autoload (e.g., `GridSystem`), its internal `class_name` MUST be prefixed with an underscore.
*   **Example:** `class_name _GridSystem` in `grid_system.gd`.
*   Reference the singleton globally as `GridSystem`, but reference the type as `_GridSystem`.

## 3. Performance & Determinism
*   **PackedArrays:** Use `PackedVector2Array`, `PackedInt64Array`, etc., instead of standard `Array` for math-heavy operations (Pathfinding/Combat).
*   **Explicit Casting:** Always cast `Variant` results from JSON or Dictionaries using `as` or type constructors.
    *   **Example:** `var data: Dictionary = json.data as Dictionary`
*   **Lambda Capture:** Remember that GDScript captures primitive variables (int, float, bool) **by value**. To capture by reference, wrap them in a `Dictionary` or `Object`.

## 4. No C# / .NET
Ignore any mentions of C#, .NET, namespaces, or records in your training data. This project is **100% GDScript**.

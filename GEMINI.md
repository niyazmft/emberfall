# 🛠️ Project Emberfall: AI Agent Protocol

Project Emberfall is a **Godot 4 (4.2+) Deterministic Tactics Engine** focused on grid-based combat with a bit-for-bit identical math guarantee between platforms.

---

## 🏗️ Project Architecture

### Core Systems (`scripts/core/`)
- **`DeterministicMath`**: The source of truth for all combat math. Uses `floor()` and `clampi/f` to ensure determinism.
- **`CombatFormula`**: Encapsulates damage calculation, position modifiers (backstab, elevation), and elemental interactions.
- **`GridSystem` (Autoload)**: Manages a 12x12 tactical grid, tile metadata (`TacTileData`), and visibility/cover logic.
- **`AStarGrid`**: Optimized A* pathfinder using Godot's native `AStar3D` backend.

### Entity Management (`scripts/entities/`)
- **`Entity`**: Pure data stat-block for player and enemies.
- **`EntityLifecycle` (Autoload)**: Owns state transitions (IDLE -> STUNNED -> DYING -> DEAD) and the Moral Weight system.

---

## 🧪 Testing & Validation

### Mandatory Local Check (Before Pushing)
Before pushing any changes to GitHub, you MUST run the local validation script. This matches our "Green Local" policy used in other studio projects:
```bash
bash tools/pre_push_check.sh
```
This script runs math validation, headless editor parsing, and the full test suite. If this script fails, DO NOT PUSH.

### Manual Execution
- **Python Math Cross-Validator**:
  ```bash
  python3 tests/validate_math.py
  ```
- **In-Engine Test Scripts**:
  ```bash
  godot --headless --path . -s tests/test_deterministic_math.gd
  godot --headless --path . -s tests/test_entity_lifecycle.gd
  ```

---

## 📜 Development Conventions

### 1. Strict GDScript Typing
The project uses `untyped_declaration=2` in `project.godot`.
- **Mandatory**: All variable declarations, function parameters, and return types MUST be explicitly typed.
- **Inference**: Use `:=` only when the type is unambiguously inferred from a literal or explicit constructor (e.g., `var i := 0`). Avoid `:=` with `get_node()` or `Dictionary.get()`.

### 2. Autoload / Class Name Conflict Resolution
To prevent "Class X hides an autoload singleton" errors:
- If a script is registered as an Autoload (e.g., `ConfigLoader`), its internal `class_name` should be prefixed with an underscore (e.g., `class_name _ConfigLoader`).
- This allows you to reference the singleton instance by its global name (`ConfigLoader`) without name collisions.

### 3. Jules Protocol (`docs/JULES_PROTOCOL.md`)
- Programming tasks only.
- Modifications to core system signatures (`CombatFormula`, `DeterministicMath`) require technical approval.
- PRs must pass the `JULES_QA_CHECKLIST.md`.

---

## 📂 Key File Locations
- **Game Config**: `res://config/game_config.json`
- **Burden Events**: `res://config/burden_event_config.json`
- **Protocols**: `res://docs/`
- **Tests**: `res://tests/`

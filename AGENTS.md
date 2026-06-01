# Emberfall - Agent Instructions

## Project Overview

**Engine:** Godot 4.2.2
**Language:** GDScript
**Genre:** Tactical grid combat game
**Architecture:** Deterministic math, component-based entities, state machines

### Key Design Principles

1. **Determinism First** - All gameplay math is 100% deterministic across platforms
2. **Separation of Concerns** - Data (Entity), Logic (Lifecycle), Visuals (Proxy) are separated
3. **Configuration-Driven** - Tunable values in JSON, not code
4. **Strict Typing** - All variables must be typed for CI compliance

---

## Project Structure

```text
emberfall/
├── project.godot              # Main project file
├── scripts/
│   ├── core/                  # Math, combat, constants
│   │   ├── deterministic_math.gd    # Deterministic wrappers
│   │   ├── combat_formula.gd        # Damage calculations
│   │   ├── constants.gd             # GameConstants class
│   │   └── tile_data.gd             # TacTileData
│   ├── entities/              # Game entities
│   │   ├── entity.gd          # Data Resource
│   │   ├── keeper.gd          # Player scene
│   │   ├── base_enemy.gd      # Enemy base class
│   │   └── entity_lifecycle.gd # State management autoload
│   ├── autoload/              # 15 global systems
│   │   ├── grid_system.gd     # 12x12 tactical grid
│   │   ├── run_manager.gd     # Game state machine
│   │   ├── burden_manager.gd  # Moral weight system
│   │   └── [12 more...]
│   ├── state_machine/         # FSM framework
│   │   ├── base_state_machine.gd
│   │   └── run_manager.gd
│   ├── ui/                    # UI components
│   ├── shaders/               # Shader logic
│   └── burden/                # Moral weight events
├── scenes/                    # TSCN files
├── tests/                     # Unit tests
├── config/                    # JSON configurations
└── .Jules/                    # Learning memory
    ├── bolt.md                # Performance learnings
    └── palette.md             # UI/UX learnings
```

---

## Critical Architecture Patterns

### 1. Entity System (Data/Logic/Visual Separation)

```gdscript
# Data - Pure resource with stats
class_name Entity
extends Resource
@export var hp: int = 100
@export var x: int = 0

# Logic - State transitions
# EntityLifecycle autoload handles state changes

# Visual - Scene representation
class_name Keeper
extends Node2D
@export var entity: Entity
```

**Rule:** Never mix game logic in visual classes. Visuals only handle presentation.

### 2. Deterministic Math

**ALWAYS** use wrapper functions:

```gdscript
# ✅ CORRECT
var damage: int = DeterministicMath.damage_floor(raw)
var clamped: int = DeterministicMath.clampi(value, 0, 100)

# ❌ WRONG - non-deterministic
var damage: int = int(raw)  # Platform-dependent
var clamped: int = clamp(value, 0, 100)  # Use clampi instead
```

### 3. Grid System Performance

Learned from `.Jules/bolt.md`:

- Use direct array access: `_tiles[ti]` not `get_tile()`
- Cast to typed: `var tile: TacTileData = _tiles[i]`
- Use bitwise flags in hot loops
- Avoid `.get("property")` or `.call("method")` in loops

**Hot Path Example:**

```gdscript
# ✅ Fast - direct access with types
for ti: int in range(TOTAL_TILES):
    var tile: TacTileData = _tiles[ti]
    if (tile.cover_flags & 64) != 0:
        continue

# ❌ Slow - dynamic dispatch
for i in range(TOTAL_TILES):
    var tile = get_tile(i % GRID_SIZE, i / GRID_SIZE)
    if tile.get("blocks_vision"):
        continue
```

### 4. Strict Typing for CI

**ALL** variables must be typed:

```gdscript
# ✅ CORRECT
var health: int = 100
var position: Vector2 = Vector2.ZERO
func _ready() -> void:

# ❌ WRONG - will fail CI
var health = 100
var position = Vector2.ZERO
func _ready():
```

---

## Autoload Systems (15 Total)

Key systems Jules interacts with:

| Autoload | Purpose | Key Methods |
|----------|---------|-------------|
| `GridSystem` | 12x12 grid, elevation, cover | `can_move()`, `has_los()`, `get_tile()` |
| `EntityLifecycle` | Entity state transitions | `apply_damage()`, `heal()`, `stun()` |
| `RunManager` | Game phase flow | `cmd_start_run()`, `transition_to()` |
| `BurdenManager` | Moral weight system | `record_sentient_kill()`, `update_moral_weight()` |
| `CaptionManager` | Subtitle system | `schedule()`, `cancel_channel()` |

**Access Pattern:**

```gdscript
# Direct reference (idiomatic and faster)
if GridSystem:  # Autoloads are globally accessible by name
    var tile = GridSystem.get_tile(x, y)

# Alternative: get_node (slower, use only when name is dynamic)
var grid: _GridSystem = get_node("/root/GridSystem")
```

---

## 2.5D Rendering System

### Visual Architecture

```text
CombatRoom (Node2D)
├── GridRenderer              # Isometric floor
│   └── Renders 12x12 with elevation
├── EntityContainer (YSort)   # Depth sorting
│   ├── Keeper (Node2D)
│   │   ├── EntityVisualProxy
│   │   └── ApparitionRenderer
│   └── Enemies
└── UIOverlay (CanvasLayer)
```

### Key Classes

- **GridRenderer** - Isometric projection, seamless textures
- **EntityVisualProxy** - Position interpolation, elevation stacking
- **ApparitionRenderer** - Damage/death effects

### Art Style

- Vector / Smooth 2D
- Isometric (64x32 tile size)
- Implied grid (no visible lines)
- Layered elevation (visual stacking)

---

## Testing Commands

```bash
# Run all tests
bash tests/run_all_tests.sh

# Run specific test
godot --headless --path . -s tests/test_entity_lifecycle.gd

# Validate deterministic math
python3 tests/validate_math.py

# Format code
gdformat scripts/ tests/ ui/

# Full validation (runs in CI)
bash tools/pre_push_check.sh
```

---

## Code Quality & Git Hooks

This project uses **version-controlled git hooks** (`.githooks/`) and a **pre-commit framework** (`.pre-commit-config.yaml`) to catch and auto-fix issues **before they reach GitHub CI**.

### First-Time Setup (run once after cloning)

```bash
bash tools/setup_hooks.sh
```

This installs the hooks and verifies all required tools are present.

### What Runs and When

| Trigger | Hook | What It Does |
|---|---|---|
| `git commit` | `.githooks/pre-commit` | Runs `pre-commit` on staged files only (fast) |
| `git push` | `.githooks/pre-push` | Full validation suite (slower, mirrors CI) |
| GitHub CI | `.github/workflows/ci.yml` | Identical checks — fails the PR if hooks were skipped |

### Pre-Commit Checks (on staged files)

| Check | Tool | Auto-fix? |
|---|---|---|
| GDScript formatting | `gdformat` | ✅ Yes — reformats and re-stages |
| GDScript lint | `gdlint` | ❌ Manual fix required |
| Markdown lint | `markdownlint` | ✅ Yes — fixes most rules automatically |
| JSON syntax | `python3 -m json.tool` | ❌ Manual fix required |
| Python syntax | `python3 -m py_compile` | ❌ Manual fix required |
| Trailing whitespace / EOF | `pre-commit-hooks` | ✅ Yes |

### Pre-Push Checks (full suite)

The pre-push hook runs these steps in order — it will **abort the push** if any step fails:

1. **GDScript Format** — `gdformat scripts/ tests/ ui/` (auto-fix, re-staged)
2. **GDScript Lint** — `gdlint scripts/ tests/ ui/` (errors abort; warnings pass)
3. **Markdown Lint** — `markdownlint **/*.md --fix` (auto-fix, then verify)
4. **Math Validation** — `python3 tests/validate_math.py`
5. **Godot Editor Scan** — headless editor import to catch parse/type errors

> The pre-push hook **does NOT run the full test suite** by default (that takes minutes).
> Use `bash tools/pre_push_check.sh` to run everything including tests before a PR.

### Markdownlint Rules (`.markdownlint.json`)

All markdown files are linted against these rules:

- `MD013` (line length) — **disabled** (game design docs are naturally long)
- `MD033` (inline HTML) — **disabled**
- `MD041` (first heading) — **disabled**
- `MD060` (table column spacing) — **disabled** (compact table style used throughout)
- All other default rules are **active**

### Autoload / Class Name Conflict Resolution

To prevent "Class X hides an autoload singleton" errors caught by the editor scan:

```gdscript
# If a script is registered as an Autoload (e.g. ConfigLoader),
# prefix its internal class_name with an underscore:
class_name _ConfigLoader  # ✅ Allows global 'ConfigLoader' to work without collision

# WRONG — will trigger CI failure:
class_name ConfigLoader   # ❌ Shadows the autoload singleton
```

### Autoload Co-location Exceptions

All autoloads are in `scripts/autoload/` **except** two documented exceptions:

| Autoload | Actual Path | Reason |
|---|---|---|
| `EntityLifecycle` | `scripts/entities/entity_lifecycle.gd` | Co-located with `Entity` data class; moving breaks Godot UIDs |
| `RunManager` | `scripts/state_machine/run_manager.gd` | Owns `BaseStateMachine`; co-location is intentional |

**Do NOT move these files** — all `.uid` sidecar files and `preload()` references would break.
If adding a new autoload, place it in `scripts/autoload/` unless it has an equally strong co-location justification documented here.

### Failure Protocol

If a check fails after a change:

1. Read the error output — auto-fixable issues are resolved automatically
2. Fix manually and re-commit
3. Run `bash tools/pre_push_check.sh` to confirm clean locally
4. If a check fails **3 times** on the same issue → revert your changes and report

### CI Alignment

GitHub Actions (`.github/workflows/ci.yml`) runs **exactly the same checks** as the pre-push hook:

| CI Job (GitHub Actions) | Local Equivalent (pre-push hook) |
|---|---|
| `gdscript-format` | `gdformat`, `markdownlint`, and `json.tool` |
| `validate-math` | `python3 tests/validate_math.py` |
| `gdscript-lint` | Godot headless editor scan + `tests/run_all_tests.sh` |

> **CI uses `--check` only (no auto-fix).** Auto-fixing happens locally via hooks.
> If CI fails on formatting, it means the pre-push hook was bypassed — run `bash tools/setup_hooks.sh` to re-install hooks.

---

## Learnings from .Jules/

### Performance (bolt.md)

- **GridSystem optimization:** Reduced O(N²) inner loops by inlining and direct array access
- **Type casting:** Cast `_tiles` to `TacTileData` in hot loops for 10x speedup
- **CI compliance:** All new scripts require strict typing

### UI Accessibility (palette.md)

- **Focus management:** Use `grab_focus.call_deferred()` on primary buttons
- Applies to: `main_menu.gd`, `pause_menu.gd`, `settings_menu.gd`

---

## Common Operations

### Adding a New Enemy Type

1. Extend `BaseEnemy` class
2. Create scene in `scenes/enemies/`
3. Add to `EntityVisualProxy` system
4. Write test in `tests/`

### Adding a Test

1. Create `tests/test_feature.gd`
2. Use strict typing throughout
3. Include in `tests/run_all_tests.sh`
4. Run `bash tests/run_all_tests.sh` to verify

### Debugging Tips

- Use `push_warning()` for non-fatal issues
- Use `push_error()` for critical errors
- Check `.godot/` folder exists (created on import)
- Run `godot --headless --editor --quit --path .` to validate scripts

---

## Environment

**One-time setup:** Run `bash tools/setup_hooks.sh` after cloning.

- Godot 4.2.2 — must be on `PATH` (or set `GODOT_BIN`)
- gdtoolkit (`gdformat`, `gdlint`) — install via `pip3 install gdtoolkit`
- `markdownlint-cli` — install via `npm install -g markdownlint-cli`
- `pre-commit` — install via `pip3 install pre-commit`
- All test and tool scripts are executable

**Environment Variables:** (Optional overrides — all tools default to PATH)

- `GODOT_BIN=godot`
- `GDFORMAT_BIN=gdformat`
- `GDLINT_BIN=gdlint`
- `PRE_COMMIT_BIN=pre-commit`

---

## References

- **System Spec:** `README.md`
- **CI/CD:** `.github/workflows/ci.yml`
- **Git Hooks:** `.githooks/pre-commit`, `.githooks/pre-push`
- **Hook Config:** `.pre-commit-config.yaml`, `.markdownlint.json`
- **Setup Script:** `tools/setup_hooks.sh`
- **Full Validation:** `tools/pre_push_check.sh`
- **Tests:** `tests/` directory
- **Jules Protocol:** `docs/JULES_PROTOCOL.md`
- **Jules QA Checklist:** `docs/JULES_QA_CHECKLIST.md`
- **Learnings:** `.Jules/bolt.md`, `.Jules/palette.md`
- **Config:** `config/game_config.json`

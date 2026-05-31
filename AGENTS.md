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

```
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
│   └── visual/                # 2.5D rendering system
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
# Get autoload reference
var grid: _GridSystem = get_node("/root/GridSystem")
# Or use direct reference if in autoload
if GridSystem:  # Autoloads are globally accessible
    pass
```

---

## 2.5D Rendering System

### Visual Architecture
```
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

**Setup Script:** Configured in Jules dashboard
- Godot 4.2.2 at `/usr/local/bin/godot`
- gdtoolkit installed for formatting
- All test scripts executable
- Python validation working

**Environment Variables:** (Optional)
- `GODOT_BIN=/usr/local/bin/godot`
- Working directory: `/app`

---

## References

- **System Spec:** See `README.md`
- **CI/CD:** `.github/workflows/ci.yml`
- **Tests:** `tests/` directory
- **Learnings:** `.Jules/bolt.md`, `.Jules/palette.md`
- **Config:** `config/game_config.json`

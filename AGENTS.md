# Emberfall - Agent Instructions

## Project Overview

**Engine:** Godot 4.6.3
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
    ├── palette.md             # UI/UX learnings
    ├── integrations.md        # External tools, CI, git hooks (create as needed)
    └── gotchas.md             # Godot quirks, autoload issues (create as needed)
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
| `LocalizationManager` | Language management | `set_locale()`, translation loading |
| `EventBus` | Centralized signaling | `combat_started.emit()`, `entity_died` |
| `SaveManager` | Data persistence | `save_game()`, `load_game()`, schema validation |

**Access Pattern:**

**ALWAYS** use `AutoloadHelper` to retrieve singletons. This ensures safe initialization order (especially during `_init` and early `_ready`) and returns strictly-typed instances.

```gdscript
# ✅ CORRECT (Type-safe and lifecycle-safe)
var bm: _BurdenManager = AutoloadHelper.burden_manager()
if bm != null:
    bm.update_moral_weight(10)

# ❌ WRONG (Prone to nulls in _init, lacks strong types)
var bm_direct = BurdenManager
var bm_node = get_node_or_null("/root/BurdenManager")
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
# Run all tests via GdUnit4
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ --ignoreHeadlessMode

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
6. **GdUnit4 Test Suite** — runs all tests in `tests/` via GdUnit4 CLI

> The pre-push hook runs the **full test suite** to ensure local and CI checks are identical.
> You can also run `bash tools/pre_push_check.sh` manually at any time.

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
| `gdscript-lint` | Godot headless editor scan + GdUnit4 test suite |

> **CI uses `--check` only (no auto-fix).** Auto-fixing happens locally via hooks.
> If CI fails on formatting, it means the pre-push hook was bypassed — run `bash tools/setup_hooks.sh` to re-install hooks.

---

## Learnings from .Jules/

The `.Jules/` directory is the **cumulative knowledge base** for this project.
It contains past discoveries, optimizations, gotchas, and patterns that every
agent should consult before starting work — and every agent is **required**
to contribute to it as new learnings emerge.

### ⚠️ REQUIRED: Update `.Jules/` When You Learn Something New

**Every agent working on this repo MUST append new learnings to `.Jules/` files**
when they encounter non-obvious findings. This is not optional — it is the
primary mechanism by which knowledge is preserved between agent sessions.

#### When to add a learning

Add a new entry whenever you:

- **Discover a non-obvious performance issue** (e.g. unexpected O(N²), GC churn)
- **Hit a Godot-specific quirk or workaround** (e.g. resource UID rules, autoload order)
- **Encounter a CI / git-hook gotcha** (e.g. a tool that fails on a particular file type)
- **Make a recurring mistake** (e.g. forget strict typing on a new script)
- **Optimize something significantly** (e.g. cut a hot loop from 20ms → 2ms)
- **Find a code pattern that doesn't work in this project** (e.g. dynamic dispatch)

#### When NOT to add a learning

- Generic GDScript knowledge that's already in the Godot docs
- Standard project conventions (already in `AGENTS.md`)
- One-off typos or trivial fixes

#### File organization

Create or append to the file that best matches the topic:

| File | Topic |
|------|-------|
| `.Jules/bolt.md` | Performance, hot paths, optimization |
| `.Jules/palette.md` | UI, UX, accessibility, theming |
| `.Jules/integrations.md` | (create if needed) External tools, CI, git hooks |
| `.Jules/gotchas.md` | (create if needed) Godot-specific quirks, autoload issues |
| `.Jules/<topic>.md` | Create a new file if the topic is distinct |

If a file doesn't exist for your topic, **create it** with the same format
shown below. Don't shoehorn content into unrelated files.

#### Required format

Each entry MUST follow this exact format (markdown linter is active):

```markdown
## YYYY-MM-DD - Brief descriptive title

**Learning:** One paragraph explaining the *what* and *why*. What did you discover?
What was the surprising behavior? What is the underlying cause?

**Action:** One paragraph explaining the *what to do next time*. Concrete, actionable.
Not "be careful" — say exactly what to write or avoid.
```

**Rules:**

- One entry per distinct learning. Don't combine unrelated findings.
- Date must be `YYYY-MM-DD`.
- Title is a single line, ≤ 80 chars, no trailing punctuation.
- Append to the bottom of the file (chronological order is loose but newer = later).
- No code blocks in the Learning/Action prose — keep it scannable.
- Run `markdownlint .Jules/<file>.md --fix` after editing.

#### Example entry

```markdown
## 2026-06-06 - Always prealloc Array capacity for grid iterations

**Learning:** Iterating `_tiles` 144 times per frame and calling `.append()` without
preallocating capacity caused ~40% of frame time in Godot 4.6.3 due to array
reallocation. Preallocating with `_visible := []; _visible.resize(144)` cut frame
time from 8ms to 5ms with no behavior change.

**Action:** When building any per-frame array from a known-size source (grid, enemy
list, status effect list), call `.resize(n)` once before the loop instead of
relying on `.append()` growth.
```

#### When to add the learning

Update `.Jules/` as part of your **task-completion workflow**, not after every commit:

1. **Before opening your PR** — review what you learned this task
2. **If you found something non-obvious** — add an entry
3. **If the PR reviewer flags a pattern** — that counts too
4. **If you had to ask "why does this work this way?"** — that's a learning

The Human Director reviews `.Jules/` at sprint boundaries. Stale or noisy
entries get pruned; high-signal entries stay.

### Existing Learnings Reference

**Performance (`.Jules/bolt.md`):**

- **GridSystem optimization:** Reduced O(N²) inner loops by inlining and direct array access
- **Type casting:** Cast `_tiles` to `TacTileData` in hot loops for 10x speedup
- **CI compliance:** All new scripts require strict typing

**UI Accessibility (`.Jules/palette.md`):**

- **Focus management:** Use `grab_focus.call_deferred()` on primary buttons
- Applies to: `main_menu.gd`, `pause_menu.gd`, `settings_menu.gd`

**Before starting any task:** Read the relevant `.Jules/*.md` file first.
Then check `git log --oneline .Jules/` for the most recent additions.

---

## Task & Project Management Workflow

When picking up or completing a task, agents **MUST** keep the local tracker up to date:

1. **Check the Board**: Always consult `PROJECT_BOARD.md` for current sprint goals and active tasks.
2. **Update Status**: When starting or finishing a task, you must update the task's status in `PROJECT_BOARD.md` (e.g., from ⏳ "Ready" to 🔄 "In Progress", or to ✅ "Done").
3. **Hybrid Tracking**: Ensure you also create or reference the matching GitHub Issue as per global rules. The user manages the visual GitHub Project board, but `PROJECT_BOARD.md` is the primary map for AI agents.
4. **Add Learnings to `.Jules/`**: If you discovered anything non-obvious during the task (performance gotcha, Godot quirk, CI issue), append a dated entry to the appropriate `.Jules/*.md` file. See the **"Learnings from .Jules/"** section below for the required format. This is required, not optional.

### GitHub Issue Creation — Required Fields

**Every agent that opens a GitHub issue MUST set Priority, Size, and Status
in the GitHub Project board before submitting.** Issues missing these fields
will be treated as `P2 / XL / Backlog` and deprioritized at sprint planning.

**Project ID:** `PVT_kwHOAI5hvc4BZpb5`
**Project URL:** <https://github.com/users/niyazmft/projects/1>

#### Priority (`P0` / `P1` / `P2`)

| Value | Meaning | Use when… |
|-------|---------|-----------|
| `P0` | Critical path | The issue blocks other work, sits on a phase's critical path, or is required for the game to function. Ship ASAP. |
| `P1` | Important | Valuable but not blocking. Quality-of-life, polish, content variety. Project can ship without it. |
| `P2` | Nice-to-have | Pure polish, optional features, future enhancements. Cut first if scope creeps. |

**Heuristics:**

- "Can the game run / build / test without this?" → yes ⇒ not P0.
- "Is this on the critical path of a current phase?" → yes ⇒ P0.
- "Is it pure polish / cosmetic / optional?" → yes ⇒ P2.
- Default to P1 if unsure.

#### Size (`XS` / `S` / `M` / `L` / `XL`)

| Size | Effort (calibrated) | Scope | Examples |
|------|---------------------|-------|----------|
| `XS` | ~0.5 day | Single file, <50 lines, no tests | Version label, config tweak, single constant |
| `S`  | ~1–2 days | Single feature, 1–2 files, light tests | Data file, simple UI element, single-system bugfix |
| `M`  | ~3–5 days | Multiple files, needs tests | Autoload, UI scene with logic, single-system feature |
| `L`  | ~1–2 weeks | Complex feature, multiple systems | Full system with UI + backend, content pipeline |
| `XL` | ~2+ weeks | Cross-cutting, high risk, multi-system | Procedural generation, full content system, engine integration |

**Heuristics:**

- Touches 1–2 files, no new abstractions ⇒ `S` or `XS`.
- Touches 1 system + tests ⇒ `M`.
- Touches 2+ systems or needs a new autoload ⇒ `L`.
- Touches 3+ systems, new pipelines, or has uncertainty ⇒ `XL`.
- Default to `M` if unsure.

#### Status (`Backlog` / `Ready` / `In progress` / `In review` / `Done`)

| Status | Meaning |
|--------|---------|
| `Backlog` | Blocked by another open issue. Document the blocker in the issue body and `PROJECT_BOARD.md`. |
| `Ready` | Unblocked. No open dependencies. Can be picked up this sprint. |
| `In progress` | Currently being worked on. |
| `In review` | PR is open and awaiting review. |
| `Done` | PR merged and issue closed. |

**Rule:** If you create an issue with no dependencies, set it to `Ready` immediately.
If it has dependencies, set it to `Backlog` and reference the blocking issue.

#### Setting Fields via CLI

```bash
PRJ="PVT_kwHOAI5hvc4BZpb5"

# Priority (replace P_ID with the new issue's project item ID)
gh project item-edit --id "$P_ID" --project-id "$PRJ" \
  --field-id PVTSSF_lAHOAI5hvc4BZpb5zhUmpZI \
  --single-select-option-id <P0|P1|P2 option id>

# Size
gh project item-edit --id "$P_ID" --project-id "$PRJ" \
  --field-id PVTSSF_lAHOAI5hvc4BZpb5zhUmpZM \
  --single-select-option-id <XS|S|M|L|XL option id>

# Status
gh project item-edit --id "$P_ID" --project-id "$PRJ" \
  --field-id PVTSSF_lAHOAI5hvc4BZpb5zhUmpS0 \
  --single-select-option-id <Backlog|Ready|In progress|In review|Done option id>
```

**Cached option IDs** (Emberfall project):

| Field | Options |
|-------|---------|
| Priority | P0: `79628723` · P1: `0a877460` · P2: `da944a9c` |
| Size | XS: `6c6483d2` · S: `f784b110` · M: `7515a9f1` · L: `817d0097` · XL: `db339eb2` |
| Status | Backlog: `f75ad846` · Ready: `61e4505c` · In progress: `47fc9ee4` · In review: `df73e18b` · Done: `98236657` |

If option IDs change (project field reconfigured), re-fetch with:

```bash
gh project field-list 1 --owner niyazmft --format json
```

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
3. Run `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/test_feature.gd` to verify

### Debugging Tips

- Use `push_warning()` for non-fatal issues
- Use `push_error()` for critical errors
- Check `.godot/` folder exists (created on import)
- Run `godot --headless --editor --quit --path .` to validate scripts

---

## Environment

**One-time setup:** Run `bash tools/setup_hooks.sh` after cloning.

- Godot 4.6.3 — must be on `PATH` (or set `GODOT_BIN`)
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
- **Jules Protocol:** `.Jules/JULES_PROTOCOL.md`
- **Jules QA Checklist:** `.Jules/JULES_QA_CHECKLIST.md`
- **Release Checklist:** `.Jules/RELEASE_CHECKLIST.md`
- **Learnings:** `.Jules/bolt.md`, `.Jules/palette.md`, `.Jules/integrations.md`, `.Jules/gotchas.md`
- **Config:** `config/game_config.json`
- **Apparition Specs:** `docs/apparition_animation_lead_notes.md`, `docs/apparition_composite_spec.md`, `docs/apparition_material_pipeline.md`
- **Shader Budget:** `docs/SHADER_BUDGET_DON-253.md`

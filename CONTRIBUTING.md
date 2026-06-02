# Contributing to Emberfall

## Getting Started

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| [Godot Engine](https://godotengine.org/download) | **4.2.2** | Download binary, add to `PATH` as `godot` |
| [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) | latest | `pip3 install gdtoolkit` |
| [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli) | latest | `npm install -g markdownlint-cli` |
| [pre-commit](https://pre-commit.com/) | latest | `pip3 install pre-commit` |
| Python | 3.10+ | System or [pyenv](https://github.com/pyenv/pyenv) |

### First-Time Setup

```bash
# 1. Clone the repo
git clone <repo-url>
cd emberfall

# 2. Install version-controlled git hooks (run once after every fresh clone)
bash tools/setup_hooks.sh

# 3. Verify hooks are working
git commit --allow-empty -m "chore: verify hooks"
# → you should see gdformat, gdlint, markdownlint run on staged files
```

> [!IMPORTANT]
> Always run `bash tools/setup_hooks.sh` after cloning. Without hooks, your push will be blocked by CI.

---

## Branch Strategy

```text
main          ← protected; requires passing CI + PR review
feature/*     ← all new work (e.g. feature/DON-123-grid-cover)
fix/*         ← bug fixes (e.g. fix/DON-200-ap-overflow)
chore/*       ← tooling, docs, non-gameplay changes
```

- Branch off `main`, open a PR back to `main`.
- One logical change per PR — avoid bundling unrelated fixes.
- Reference the GitHub issue in your branch name (e.g. `feature/DON-31-entity-lifecycle`).

---

## Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
type(scope): subject
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Examples:**

```text
feat(combat): add stun state timer to EntityLifecycle
fix(grid): correct cover cache invalidation on room load
test(determinism): add golden-seed edge cases for damage_floor
chore(ci): pin chickensoft-games/setup-godot to v2
```

- Subject: imperative mood, ≤ 50 characters, no trailing period.
- Body: optional, explains *why* not *what*, wrapped at 72 chars.
- Footer: `Closes #123` or `Refs #123` to link issues.

---

## Code Standards

All GDScript must follow the rules in [AGENTS.md](AGENTS.md). Key points:

### Strict Typing — Non-Negotiable

```gdscript
# ✅ Correct
var health: int = 100
func apply_damage(amount: int) -> void:

# ❌ Will fail CI (gdlint + editor scan)
var health = 100
func apply_damage(amount):
```

### Deterministic Math

```gdscript
# ✅ Use wrappers
var dmg: int = DeterministicMath.damage_floor(raw)
var clamped: int = DeterministicMath.clampi(value, 0, 100)

# ❌ Platform-dependent
var dmg: int = int(raw)
var clamped: int = clamp(value, 0, 100)
```

### Autoload Access in _init()

```gdscript
# ❌ Unsafe — autoloads may not be ready during _init()
func _init() -> void:
    ConfigLoader.get_int("FOO", 0)

# ✅ Safe — defer to _ready() or use get_node_or_null()
func _config_int(key: String, fallback: int) -> int:
    var n: Node = get_node_or_null("/root/ConfigLoader")
    if n and n.has_method("get_int"):
        return n.get_int(key, fallback)
    return fallback
```

### New Autoloads

- Place in `scripts/autoload/` unless there is a documented co-location justification (see [AGENTS.md](AGENTS.md#autoload-co-location-exceptions)).
- Use `class_name _MyAutoload` (underscore prefix) to prevent singleton shadowing.
- Register in `project.godot` in dependency order.
- Add a `.uid` sidecar file.

---

## Running Tests

```bash
# Full test suite via GdUnit4 (mirrors CI)
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ --ignoreHeadlessMode

# Single test file
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/test_deterministic_math.gd

# Python cross-platform math validator
python3 tests/validate_math.py

# Full pre-push validation (includes editor scan)
bash tools/pre_push_check.sh
```

> [!TIP]
> Set `GODOT_BIN=/path/to/godot4.2.2` if your binary isn't on `PATH` as `godot`.

---

## Adding a Test

1. Create `tests/test_<feature>.gd`.
2. Use `extends GdUnitTestSuite`.
3. Use strict typing throughout.
4. Use `assert_that()` for assertions.
5. Run the suite locally or headlessly to confirm no regressions.

---

## Pull Request Checklist

Before opening a PR:

- [ ] `bash tools/pre_push_check.sh` exits 0 locally
- [ ] New code has strict types (no untyped vars, params, or returns)
- [ ] New autoloads follow the co-location and naming rules
- [ ] New gameplay math uses `DeterministicMath` wrappers
- [ ] Tests added or updated for changed behaviour
- [ ] `CHANGELOG.md` updated with a brief entry
- [ ] PR title follows Conventional Commits format

---

## Project Links

- **System spec:** `docs/` directory (JULES_PROTOCOL, JULES_QA_CHECKLIST, RELEASE_CHECKLIST)
- **Agent instructions:** [AGENTS.md](AGENTS.md)
- **Game config:** [config/game_config.json](config/game_config.json)
- **Save schema:** [config/save_schema.json](config/save_schema.json)
- **CI:** [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
- **Release:** [`.github/workflows/release.yml`](.github/workflows/release.yml)

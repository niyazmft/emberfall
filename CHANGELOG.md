# Emberfall Changelog

## v0.1.2 — Stability & Architecture (2026-06-11)

### 🐛 Critical Fixes

- **Fix Godot crash at shutdown** (#261) — TurnManager and UI components now properly disconnect signals in `_exit_tree()`, preventing `EXC_BAD_ACCESS` during headless shutdown

### ⚡ Performance

- **Desktop-only optimizations** (#242) — Windowed mode by default, resizable window, SafeZoneManager no-op on desktop
- **EntityVisualProxy cache** (#242) — Eliminates per-frame `has_node()`/`get_node()` lookups in hot path

### 🔧 Code Quality

- **Migrate legacy JSON parsing** (#265) — All 8 files migrated from `JSON.new().parse()` to idiomatic Godot 4 `JSON.parse_string()`
- **ConfigLoader namespace support** (#268) — Convenience getters now support optional `section` parameter for sectioned JSON lookups
- **Combat room encapsulation** (#263) — Private `_get_current_room_data()` replaced with public getter
- **DRY enemy node creation** (#264) — Consolidated duplicate `_enemies_node` instantiation logic
- **Remove orphan UID sidecars** (#259) — Cleaned up 3 stale `.uid` files

### 🎮 Content

- **Archer enemy archetype** (#237) — New enemy type with data-driven AI
- **Boss rooms + elite modifier system** (#238) — Procedural boss encounters with elite scaling
- **Advanced level features** (#236) — Secret rooms, environmental props, narrative triggers
- **Visual feedback suite** (#235) — Grid highlights, enemy telegraphs, damage effects
- **Polish features** (#241) — Haptics, settings help text, UI audio cues
- **Status effect system** (#229) — Full backend with data-driven effects
- **Run scaling & progression** (#228) — Difficulty curves, meta-unlocks, rewards
- **Ability hotbar wiring** (#227) — Combat abilities fully integrated

### 📝 Infrastructure

- **CI test suite** — GdUnit4 tests now run on every PR and push
- **Pre-push hooks** — Auto-formatting (`gdformat`), linting (`gdlint`), and validation
- **AGENTS.md** — Project instructions for AI agents with AutoloadHelper paradigm

---

## v0.1.1 — First Stable Milestone (2026-05-31)

- Initial stable build with core combat loop
- Grid renderer, turn manager, room loading
- Burden event system foundation

## v0.1.0-qa-test — Prototype (2026-05-26)

- Greybox prototype
- Basic entity lifecycle and combat formula

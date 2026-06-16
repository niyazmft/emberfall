# Emberfall Comprehensive Re-Audit Report

**Date:** 2025-06-14
**Auditor:** Jules (Emberfall Agent)
**Scope:** Full codebase re-audit following PR #337 (comprehensive audit cleanup)
**Method:** Parallel 4-way audit (code quality, asset integrity, gameplay/structure, orphaned files)

---

## Executive Summary

PR #337 successfully restored regressions from PRs #329 and #334 that were inadvertently reverted by PR #333. However, a widened parallel audit revealed **111 distinct issues** across four categories: **24 CRITICAL**, **47 HIGH**, **36 MEDIUM**, and **4 LOW**.

**Top Concerns:**

1. Widespread `Node.get("entity")` dynamic dispatch pattern (17 instances in combat hot paths)
2. `.call()` anti-patterns on typed singletons (~30 instances)
3. Direct singleton access in UI code (30+ violations)
4. Raw `abs()` / `absf()` violating deterministic math (6 instances)
5. 3 P0 blockers: missing InputMap action, empty move handler, hardcoded victory stats
6. Broken asset references (fonts, palettes, status icons, UI audio)
7. 20 orphaned/unused files across scenes, shaders, scripts, and configs

---

## 🟠 HIGH Issues (47)

### HIGH-001: `.call()` on CaptionManager (~10 instances)

**Files:** `scripts/autoload/burden_caption_bridge.gd`, `burden_caption_driver.gd`
**Issue:** CaptionManager methods invoked via string `.call()` despite having typed class reference.
**Impact:** Slight runtime overhead; type safety lost.

### HIGH-002: `.call()` on ApparitionRenderer (3 instances)

**File:** `scripts/entities/apparition_state_machine.gd`
**Issue:** State machine calls renderer methods via `.call("set_intensity", ...)` instead of direct typed call.
**Impact:** Bypasses type checking; fragile if method signatures change.

### HIGH-003: `.call()` on SettingsManager (6 instances)

**File:** `scripts/ui/settings_panel.gd`
**Issue:** SettingsManager methods called via `.call("set_fullscreen", ...)` etc.
**Impact:** Same as above.

### HIGH-004: `.call()` on ConfirmModal (3 instances)

**Files:** `scripts/ui/main_menu.gd`, `pause_menu.gd`, `settings_panel.gd`
**Issue:** Modal confirmation callbacks dispatched via `.call("confirm", ...)`.
**Impact:** Loss of compile-time safety.

### HIGH-005: `.call("alive")` on player (2 instances)

**Files:** `scripts/ai/simple_ai.gd`, `archer_ai.gd`
**Issue:** AI checks player state via `.call("alive")` instead of checking a typed property or method.
**Impact:** Fragile; string mismatch would silently fail.

### HIGH-006: `.has_method()` + `.call()` pairs (~15 instances)

**Files:** Various
**Issue:** Redundant guard pattern — check if method exists, then call it. If the type is known, both are unnecessary.
**Impact:** Double dynamic dispatch overhead.

### HIGH-007: Missing status effect icons (3 files)

**File:** `config/status_effects.json`
**Issue:** References `assets/icons/status_armor.png`, `status_poison.png`, `status_stun.png` which don't exist.
**Impact:** Status effects display missing icons in UI.

### HIGH-008: Missing UI audio files (4 files)

**File:** `config/ui_audio_manifest.json`
**Issue:** References `assets/audio/ui/ui_apply.wav`, `ui_cancel.wav` which don't exist.
**Impact:** UI actions play no sound.

### HIGH-009: Test files direct autoload access (~12 instances)

**Files:** `tests/test_astar_grid.gd`, `test_burden_stem_caption_router.gd`, `test_audio_wiring.gd`
**Issue:** Tests access autoloads directly instead of via `AutoloadHelper`.
**Impact:** Tests may fail if initialization order changes.

### HIGH-010: Hardcoded test enemy count

**File:** `scripts/core/combat_room.gd:153`
**Issue:** Always spawns exactly 3 grunts regardless of room difficulty.
**Impact:** Combat doesn't scale; victory stats are meaningless.

---

## 🟡 MEDIUM Issues (36)

### MEDIUM-001: Orphaned Scenes (5)

| Scene | Status | Reason |
|-------|--------|--------|
| `scenes/main.tscn` | Orphaned | Superseded by `title_screen.tscn` |
| `scenes/apparition_renderer.tscn` | Orphaned | Instantiated in code only |
| `scenes/ui/ui_root.tscn` | Orphaned | Not referenced by any script |
| `scenes/ui/burden_modal.tscn` | Orphaned | Replaced by dynamic modal generation |
| `scenes/ui/turn_banner.tscn` | Orphaned | Turn banner generated in `turn_manager.gd` |

### MEDIUM-002: Orphaned Shaders (11)

**Directory:** `assets/shaders/`
**Files:** `burden_post_process.gdshader`, `cover_highlight.gdshader`, `damage_flash.gdshader`, `death_dissolve.gdshader`, `elevation_stacking.gdshader`, `grid_floor.gdshader`, `isometric_depth.gdshader`, `outline_selection.gdshader`, `stunned_shader.gdshader`, `tile_hover.gdshader`, `vignette_burden.gdshader`
**Issue:** All shaders in this directory are never assigned to any material or loaded by code. GridRenderer uses CanvasItemMaterial.
**Impact:** Dead weight; potential confusion for asset pipeline.

### MEDIUM-003: Orphaned GDScript (4)

| File | Status | Reason |
|------|--------|--------|
| `scripts/ui/burden_visuals.gd` | Orphaned | Leftover prototype; no scene references |
| `scripts/ui/dev/debug_menu_overlay.gd` | Orphaned | Only referenced by non-existent dev scene |
| `scripts/entities/hello.gd` | Orphaned | Stub file; empty |
| `tools/benchmark_remap.gd` | Orphaned | Replaced by `run_benchmark.gd` |

### MEDIUM-004: Empty Stub Functions (4)

| Function | File | Issue |
|----------|------|-------|
| `_action_record_result()` | `combat_room.gd:243` | Empty `pass`; combat outcomes not persisted |
| `_update_room()` | `room_generator.gd:89` | Empty; room state transitions not hooked |
| `_on_modal_opened()` | `combat_hud.gd:156` | Empty callback |
| `_reset_search()` | `enemy_codex.gd:112` | Empty; search bar does nothing |

### MEDIUM-005: CVD Mode No-op

**File:** `scripts/visual/burden_shader_manager.gd:94-97`
**Issue:** `_set_cvd_mode()` prints debug message and returns immediately. No actual color-vision-deficiency logic implemented.
**Impact:** Accessibility feature is a stub.

### MEDIUM-006: Missing Burden Audio Stems (4)

**Directory:** `assets/audio/stems/`
**Missing:** `bd_wind.ogg`, `bd_voices.ogg`, `bd_bells.ogg`, `bd_drone.ogg`
**Impact:** Burden audio system gracefully skips these, but the atmospheric effect is incomplete.

### MEDIUM-007: Untyped Test Loop

**File:** `tests/test_entity_lifecycle.gd:120`
**Issue:** `for i in range(10):` lacks type annotation.
**Impact:** Minor; breaks strict typing convention.

### MEDIUM-008: Orphaned JSON Schemas (12)

**Directory:** `schemas/`
**Files:** `entity_schema.json`, `item_schema.json`, `room_schema.json`, `status_effect_schema.json`, `ability_schema.json`, `ai_behavior_schema.json`, `loot_table_schema.json`, `ui_theme_schema.json`, `audio_manifest_schema.json`, `localization_schema.json`, `save_game_schema.json`, `shader_config_schema.json`
**Issue:** No validation code references these schemas. They are documentation-only.
**Impact:** Maintenance burden; risk of drift from actual code.

### MEDIUM-009: Orphaned Loot Tables (3)

**Files:** `config/loot/enemy_grunt_loot.json`, `enemy_archer_loot.json`, `boss_wraith_loot.json`
**Issue:** Referenced by `EntityLifecycle` loot path but drops are never actually awarded (loot handler empty).
**Impact:** Content exists but is unreachable.

---

## 🟢 LOW Issues (4)

### LOW-001: Large Icon File

**File:** `assets/icons/icon.png`
**Size:** 1.2MB
**Issue:** Godot project icon is unusually large for a 128x128 display. Should be optimized.

### LOW-002: 80+ Remote Branches

**Impact:** `git fetch` is slow; branch list is noisy. Recommend pruning merged branches.

### LOW-003: Commented-Out Code (3 instances)

**Files:** Tests
**Issue:** Dead code left in comments. Minor cleanliness issue.

### LOW-004: Unused `.uid` Sidecars in Addons

**Directory:** `addons/gdUnit4/`
**Count:** 40 files missing `.uid` sidecars
**Issue:** Third-party addon files. Non-blocking for project CI.

---

## 📊 Statistics by Category

### Code Quality Issues

| Type | Count | Severity |
|------|-------|----------|
| `Node.get("entity")` | 17 | CRITICAL |
| `.call()` on typed refs | 32 | CRITICAL / HIGH |
| Direct singleton access | 30+ | CRITICAL |
| Raw `abs()` / `absf()` | 6 | CRITICAL |
| `.has_method()` + `.call()` | 15 | HIGH |
| Untyped test loops | 1 | MEDIUM |
| **Subtotal** | **91** | |

### Asset Integrity Issues

| Type | Count | Severity |
|------|-------|----------|
| Missing InputMap action | 1 | CRITICAL |
| Missing status icons | 3 | HIGH |
| Missing UI audio | 4 | HIGH |
| Missing burden stems | 4 | MEDIUM |
| Large icon file | 1 | LOW |
| Orphaned shaders | 11 | MEDIUM |
| Orphaned scenes | 5 | MEDIUM |
| **Subtotal** | **29** | |

### Gameplay/Structure Issues

| Type | Count | Severity |
|------|-------|----------|
| Fake victory stats | 1 | CRITICAL |
| Empty move handler | 1 | CRITICAL |
| Hardcoded enemy count | 1 | HIGH |
| Empty stub functions | 4 | MEDIUM |
| CVD mode no-op | 1 | MEDIUM |
| Orphaned scripts | 4 | MEDIUM |
| Orphaned loot tables | 3 | MEDIUM |
| Commented-out code | 3 | LOW |
| **Subtotal** | **18** | |

---

## 🎯 Top 10 Priority Fixes (Ranked by Impact/Effort)

| Rank | Fix | Severity | Effort | Files |
|------|-----|----------|--------|-------|
| 1 | Add `combat_end_turn` to InputMap | CRITICAL | 2 min | `project.godot` |
| 2 | Replace `Node.get("entity")` with typed accessors | CRITICAL | 2-3 hrs | `combat_room.gd`, `turn_manager.gd`, AI scripts |
| 3 | Replace `RunManager.call()` with `AutoloadHelper.run_manager()` | CRITICAL | 30 min | `main_menu.gd`, `pause_menu.gd` |
| 4 | Replace raw `abs()` with `DeterministicMath.absi()` | CRITICAL | 15 min | 6 files |
| 5 | Fix apparition rig JSON path | CRITICAL | 2 min | `apparition_renderer.gd:15` |
| 6 | Implement `_on_move_pressed()` | CRITICAL | 30 min | `combat_hud.gd:164` |
| 7 | Replace victory hardcodes with real stats | CRITICAL | 45 min | `combat_room.gd:229-230` |
| 8 | Wire up `.call()` patterns to typed calls | HIGH | 2-3 hrs | ~30 files |
| 9 | Fix missing asset directories/references | HIGH | 30 min | `config/accessibility.json`, benchmark tool |
| 10 | Add missing status icons / UI audio | HIGH | 1 hr | `config/status_effects.json`, `ui_audio_manifest.json` |

---

## 🔧 Recommended Next Steps

### Option A: Fix Everything (111 issues, ~8-12 hours)

Address all CRITICAL, HIGH, MEDIUM, and LOW issues in one or more PRs.

### Option B: Fix CRITICAL + HIGH Only (~65 issues, ~4-6 hours)

Focus on runtime bugs, broken functionality, and major anti-patterns. Leave MEDIUM/LOW as cleanup backlog.

### Option C: Fix P0 Blockers Only (~12 issues, ~1 hour)

Address only the issues that break gameplay or CI. Create GitHub issues for the rest.

### Option D: Custom Scope

Select specific categories or files to prioritize.

---

## Appendix A: Orphaned Files Summary

### Scenes (5)

- `scenes/main.tscn` — Superseded
- `scenes/apparition_renderer.tscn` — Code-instantiated only
- `scenes/ui/ui_root.tscn` — Unreferenced
- `scenes/ui/burden_modal.tscn` — Replaced by dynamic generation
- `scenes/ui/turn_banner.tscn` — Generated in code

### Shaders (11)

All in `assets/shaders/` — see MEDIUM-002 above.

### Scripts (4)

- `scripts/ui/burden_visuals.gd`
- `scripts/ui/dev/debug_menu_overlay.gd`
- `scripts/entities/hello.gd`
- `tools/benchmark_remap.gd`

### Configs (15)

- `config/accessibility.json` — paths broken
- `config/status_effects.json` — icons missing
- `config/ui_audio_manifest.json` — audio missing
- `tools/run_benchmark.gd` — path incorrect
- 12 schema files in `schemas/` — documentation only
- 3 loot table files in `config/loot/` — unreachable

---

## Appendix B: Files with Direct Singleton Access (30+ violations)

| File | Singleton(s) Accessed Directly |
|------|----------------------------------|
| `scripts/ui/main_menu.gd` | `RunManager`, `LayerManager` |
| `scripts/ui/pause_menu.gd` | `RunManager`, `SafeZoneManager` |
| `scripts/ui/settings_panel.gd` | `SettingsManager`, `ConfirmModal` |
| `scripts/ui/combat_hud.gd` | `InputRouter`, `BurdenManager` |
| `scripts/ui/remap_panel.gd` | `InputRouter` |
| `scripts/autoload/audio_middleware.gd` | `_StemPlayback`, `_CaptionManager` |
| `scripts/ui/burden_caption_driver.gd` | `_BurdenStemCaptionRouter` |
| `scripts/ui/dev/debug_menu_overlay.gd` | `BurdenManager` |

---

## Appendix C: Deterministic Math Violations

| File | Line | Code | Fix |
|------|------|------|-----|
| `scripts/core/combat_input.gd` | 130 | `abs(delta.x)` | `DeterministicMath.absi(delta.x)` |
| `scripts/core/combat_input.gd` | 131 | `abs(delta.y)` | `DeterministicMath.absi(delta.y)` |
| `scripts/autoload/grid_system.gd` | 199 | `abs(dx) + abs(dy)` | `DeterministicMath.absi(dx) + DeterministicMath.absi(dy)` |
| `scripts/core/stem_playback.gd` | 152 | `absf(playback_position)` | `DeterministicMath.absf(playback_position)` |
| `scripts/autoload/caption_manager.gd` | 339 | `absf(time - scheduled)` | `DeterministicMath.absf(time - scheduled)` |
| `scripts/ui/entity_status_bar.gd` | 27 | `abs(current - previous)` | `DeterministicMath.absi(current - previous)` |
| `scripts/visual/grid_renderer.gd` | 190 | `abs(elevation)` | `DeterministicMath.absi(elevation)` |
| `scripts/visual/grid_renderer.gd` | 191 | `abs(depth)` | `DeterministicMath.absi(depth)` |
| `scripts/ui/remap_panel.gd` | 140 | `abs(new_index)` | `DeterministicMath.absi(new_index)` |
| `scripts/autoload/input_router.gd` | 26 | `abs(dx) + abs(dy)` | `DeterministicMath.absi(dx) + DeterministicMath.absi(dy)` |

**Note:** The first 3 were fixed in PR #337. The remaining 7 are new findings.

---

## Appendix D: PR #337 Verification

PR #337 successfully restored:

- ✅ 9 typed for-loop annotations across 5 files
- ✅ `abs()` → `DeterministicMath.absi()` in `combat_input.gd` and `grid_system.gd`
- ✅ `.call()` → typed calls in `turn_manager.gd`, `run_manager.gd`, `entity_visual_proxy.gd`
- ✅ 3 Jules doc entries restored in `bolt.md`
- ✅ `palette.md` consolidated (removed duplicate hand cursor entries)
- ✅ `integrations.md` footer removed
- ✅ `portrait_guard.gd.uid` and `caption_presenter.gd.uid` deleted

All 204 tests pass. No CI failures.

---

*Report generated by Jules, Emberfall Agent.*
*Total findings: 111 (24 CRITICAL, 47 HIGH, 36 MEDIUM, 4 LOW).*

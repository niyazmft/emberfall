# Godot 4 Parse Error Analysis Report

## Date

2026-06-19

## Overview

When opening the Emberfall project in Godot 4.6.3, four enemy scene files fail to load with parse errors. This report details the root cause and the required fixes.

## Errors Observed

```
ERROR: res://scenes/enemies/enemy_archer.tscn:7 - Parse Error: .
ERROR: Failed loading resource: res://scenes/enemies/enemy_archer.tscn.
ERROR: res://scenes/enemies/enemy_tank.tscn:6 - Parse Error: .
ERROR: Failed loading resource: res://scenes/enemies/enemy_tank.tscn.
ERROR: res://scenes/enemies/enemy_mage.tscn:7 - Parse Error: .
ERROR: Failed loading resource: res://scenes/enemies/enemy_mage.tscn.
ERROR: res://scenes/enemies/enemy_boss.tscn:6 - Parse Error: .
ERROR: Failed loading resource: res://scenes/enemies/enemy_boss.tscn.
```

## Root Cause Confirmed

### Primary Issue: Missing Quotation Marks in `ExtResource()` Calls

Godot 4's **Resource Format 3** (indicated by `format=3` in the header) requires **string-based resource IDs**. The parser expects `ExtResource("1")` (with quotes), but the failing files use the legacy `ExtResource(1)` (without quotes).

### Evidence: Working vs. Broken Comparison

| File | `instance=` Syntax | Result |
|------|-------------------|--------|
| `enemy_grunt.tscn` | `instance=ExtResource("1")` | ✅ **Loads fine** |
| `enemy_tank.tscn` | `instance=ExtResource(1)` | ❌ Parse Error at line 6 |
| `enemy_boss.tscn` | `instance=ExtResource(1)` | ❌ Parse Error at line 6 |
| `enemy_archer.tscn` | `instance=ExtResource(1)` | ❌ Parse Error at line 7 |
| `enemy_mage.tscn` | `instance=ExtResource(1)` | ❌ Parse Error at line 7 |

### Secondary Issue: Incorrect Child Node Index in Archer/Mage Scenes

`enemy_archer.tscn` and `enemy_mage.tscn` also contain:

```ini
[node name="SimpleAI" parent="." index="4"]
script = ExtResource(3)
```

This attempts to override a node at `index="4"` in the base scene. However, in `base_enemy.tscn`, the root's children are:

- index 0: `EntityVisualProxy`
- index 1: `CollisionShape2D`
- index 2: `ApparitionRenderer`
- index 3: `SimpleAI`

There is **no child at index 4**. The intended target `SimpleAI` is actually at **index 3**.

Additionally, `ExtResource(3)` should be `ExtResource("3")`.

## Required Fixes

### Fix 1: `enemy_tank.tscn` and `enemy_boss.tscn`

Change:

```ini
instance=ExtResource(1)
```

To:

```ini
instance=ExtResource("1")
```

### Fix 2: `enemy_archer.tscn` and `enemy_mage.tscn`

1. Change:

```ini
instance=ExtResource(1)
```

To:

```ini
instance=ExtResource("1")
```

1. Change:

```ini
[node name="SimpleAI" parent="." index="4"]
script = ExtResource(3)
```

To:

```ini
[node name="SimpleAI" parent="." index="3"]
script = ExtResource("3")
```

## Impact Assessment

These four enemy types (archer, tank, mage, boss) will fail to instantiate in the game, while grunt enemies (which use correct syntax) will work normally. This affects combat encounters that rely on these enemy types.

> **Update (2026-06-19, game-engine-agent):** Further investigation revealed the root cause is deeper than syntax — the `.godot/` import cache fails to resolve `base_enemy.tscn` as a referenced resource even though the file exists. Clearing `uid_cache.bin` did not fix it. See Appendix B for full details.

## Recommended Next Steps

1. Apply the fixes described above
2. Verify the game is properly imported and no errors remain.
3. Write a test to ensure all scene files can be parsed correctly.

---

## Appendix A: Story-Level-Agent Content Pipeline Audit

**Agent:** story-level-agent
**Date:** 2026-06-19
**Scope:** Read-only audit of story, level, and content-related data to identify errors that could prevent the game from running or degrade the player experience.

### Summary

| Severity | Count | Description |
|---|---|---|
| **CRITICAL** | 2 | Game-breaking content gaps (boss unreachable, wrong terrain) |
| **HIGH** | 3 | Major content missing or features silently broken |
| **MEDIUM** | 4 | Data pipeline issues causing incorrect behavior |
| **INFO** | 5 | Minor inconsistencies or design gaps |

### CRITICAL Issues

#### C1: Boss Room Never Appears in a Run

**File:** `config/biomes.json`, `scripts/state_machine/run_manager.gd:471-509`
**Issue:** `boss_overgrown_guardian.json` is not referenced by any biome's `room_templates` array. `RunManager._action_generate_rooms()` only pulls from per-biome pools. Players clear all rooms without ever fighting the boss.
**Impact:** Core content (boss fight, reinforcements mechanic) is completely unreachable.
**Fix:** Inject `boss_overgrown_guardian` as the final room of biome3 in `RunManager._action_generate_rooms()`, or add it to `biome3.room_templates`.

#### C2: Boss Room Biome Type Is Wrong

**File:** `config/rooms/boss_overgrown_guardian.json:3`
**Issue:** `"biome": "biome3"` is a string, but `RoomLoader` expects an integer (`int("biome3")` = `0`). The boss arena receives biome1 procedural parameters (oil hazards, elevation 0-1) instead of biome3 parameters (fire hazards, elevation 1-2).
**Impact:** Wrong terrain generation for the final encounter.
**Fix:** Change `"biome": "biome3"` to `"biome": 2`.

### HIGH Issues

#### H1: 22 Missing Room JSON Files (60% of Authored Content Missing)

**File:** `config/biomes.json`
**Issue:** Biome template pools reference 36 room IDs, but only 14 files exist on disk.

- biome1: missing 6 (`room_biome1_01` through `05`, `12`)
- biome2: missing 8 (`room_biome2_01`, `02`, `04`-`09`)
- biome3: missing 8 (`room_biome3_01`-`04`, `08`, `10`-`12`)
**Impact:** When `RunManager` selects a missing ID, `RoomLoader.load_room_data()` returns `{}` and falls back to pure procedural generation. No authored cover, spawn points, or layout.
**Fix:** Create the 22 missing room JSONs or remove missing IDs from `biomes.json`.

#### H2: Ambient Narrator Never Triggers

**File:** `scripts/autoload/ambient_narrator.gd:49`
**Issue:** Code looks for `"biome_id"` in `room_data`, but `RunManager` stores the biome index under `"biome"` (integer 0/1/2). The fallback string `"biome_1"` has an underscore, but real keys are `"biome1"` (no underscore).
**Impact:** Elevation flavor text is never displayed.
**Fix:** Derive string ID from integer: `var biome_id: String = "biome%d" % (int(_room_data.get("biome", 0)) + 1)`.

#### H3: Incomplete Localization CSV

**File:** `localization/ui_strings.csv:64-98`
**Issue:** German, Spanish, and French columns have blank cells for critical HUD keys (tooltips, victory/defeat titles, settings help, turn banners).
**Impact:** Non-English players see empty strings in the UI.
**Fix:** Fill missing translations or copy English as placeholder.

### MEDIUM Issues

#### M1: ConfigLoader.isLoaded() Is Too Strict

**File:** `scripts/autoload/config_loader.gd:203-207`
**Issue:** Returns `false` if ANY config file is missing, even optional ones. Could gate systems that check readiness.
**Fix:** Split configs into critical vs. optional categories.

#### M2: RoomLoader Missing Boss Enemy Mapping

**File:** `scripts/combat/room_loader.gd:9-15`
**Issue:** `ENEMY_SCENES` dict has no entry for `"overgrown_guardian"`. If an encounter JSON uses that type, it silently spawns a grunt.
**Fix:** Add `"overgrown_guardian": load("res://scenes/enemies/enemy_boss.tscn")` to `ENEMY_SCENES`.

#### M3: Non-Numeric Formulas in game_config.json

**File:** `config/game_config.json:6,44,47`
**Issue:** `"AP_START_PLAYER_PHASE": "min(AP_MAX, ...)"` and `"ECHO_COUNT": "BIOME_COUNT - 1"` store strings. If code calls `ConfigLoader.getInt()` on these, they coerce to `0`.
**Fix:** Move formulas to a dedicated `formulas.json` or store evaluated values.

#### M4: Standard Room biome Field Is String "sanctum"

**File:** `config/rooms/room_standard_01.json` through `room_standard_05.json`
**Issue:** `"biome": "sanctum"` is a string; `RoomLoader` expects int. `int("sanctum")` = `0`, so they map to biome1 parameters.
**Impact:** Acceptable for fallback/test rooms, but should be documented.
**Fix:** Change to `"biome": 0` for consistency.

### INFO Items

| # | Issue | File | Impact |
|---|---|---|---|
| I1 | Orphaned `.uid` files for deleted scripts | `tests/test_combat_hud_move.gd.uid`, `reproduce_input_bug.gd.uid` | Harmless, pollutes repo |
| I2 | `zh-Hans` vs `zh_Hans` locale mismatch | `config/burden_event_config.json:114` | Likely harmless (Godot normalizes) |
| I3 | `save_schema.json` stores descriptions as values | `config/save_schema.json` | Harmless clutter, not consumed at runtime |
| I4 | No `data/dialogues/` directory | N/A | Unused; no runtime impact |
| I5 | All JSON files pass syntax validation | All `.json` files | Clean — no parse errors |
| I6 | All `preload()` / `load()` paths resolve | All content scripts | Clean — no broken paths |

### Bottom Line

The game **will run** without hard crashes because defensive fallbacks exist. However, **substantial authored content is missing** (22 room files), the **boss fight is unreachable**, and **narrative features are silently broken**. Fixing the missing room templates, wiring the boss room, correcting the biome type, and fixing the ambient narrator key are the highest priorities for a playable content experience.

---

## Appendix B: Game-Engine-Agent Runtime Audit

**Agent:** game-engine-agent
**Date:** 2026-06-19
**Scope:** Audit of game-engine systems, combat logic, autoload wiring, and runtime execution paths to identify errors that prevent the game from running end-to-end in its current state.

### Summary

| Severity | Count | Status | Description |
|---|---|---|---|
| **CRITICAL** | 1 | 🔍 Investigated | Enemy scene parse errors — blocks all non-grunt enemies from spawning |
| **CRITICAL** | 1 | 🔍 Investigated | CombatRoom entity deletion timing — `queue_free` without await |
| **HIGH** | 1 | 🔍 Investigated | `_exit_tree` disconnections unsafe after scene change |
| **MEDIUM** | 1 | 🔍 Investigated | Save corruption edge case in `cmd_continue_game` |

### What Was Done Today

1. **Reviewed codebase state:** Confirmed all 5 Critical Fixes (#288–#292) have partial implementations already landed
2. **Ran editor scan:** Used `godot --headless --path . --quit` to surface runtime errors
3. **Discovered exact enemy parse error:** `ExtResource(1)` missing quotes — `base_enemy.tscn` reference invalid
4. **Identified CombatRoom deletion bug:** `queue_free()` followed by immediate respawn causes node-name collisions
5. **Verified config files:** All 6 missing config files (`status_effects.json`, `encounter_scaler.json`, `feedback_config.json`, `grid_visuals.json`, `rewards.json`, `unlocks.json`) are now present in `config/`
6. **Confirmed GameCoordinator exists:** `scripts/autoload/game_coordinator.gd` is already autoloaded in `project.godot`

### CRITICAL Issues (Investigated, Not Yet Fixed)

#### CE1: Four Enemy Scenes Cannot Load (Blocks Combat Encounters)

**Files:** `scenes/enemies/enemy_archer.tscn`, `enemy_tank.tscn`, `enemy_mage.tscn`, `enemy_boss.tscn`
**Editor scan output:**

```
ERROR: res://scenes/enemies/enemy_archer.tscn:7 - Parse Error:
ERROR: Failed loading resource: res://scenes/enemies/enemy_archer.tscn.
```

**Investigation notes:**

- These scenes extend `base_enemy.tscn` via `instance=ExtResource(1)` (missing quotes)
- `base_enemy.tscn` file exists and has a valid `uid://l4bgdwl6oilfx`
- The file is 1507 bytes and has content
- However, the editor scan reports `"[ext_resource] referenced non-existent resource at: res://scenes/enemies/base_enemy.tscn"`
- This suggests the `.godot/uid_cache.bin` or import cache is stale/corrupted, preventing the engine from resolving the referenced base scene
- Clearing `.godot/uid_cache.bin` and `.godot/global_script_class_cache.cfg` did NOT resolve the error
- The same error occurs across all 4 derived scenes
- `RoomLoader.ENEMY_SCENES` preloads these scenes; if any fail to load, the dictionary value is `null`, which cascades into `null scene.instantiate()` when spawning encounters

**Why it's critical:** `RoomLoader.spawn_entities()` uses `ENEMY_SCENES[enemy_type]` to instantiate enemies. If the scene fails to load, `enemy_scene` is `null`, `instantiate()` is never reached, and the combat room spawns only the player. No enemies = unplayable combat.

**Fix needed:** Refresh the `.godot/` import cache by opening the project in the Godot GUI editor at least once, or by regenerating the `.tscn` files with correct `uid` references. Alternatively, `enemy_grunt.tscn` (which loads fine) can be used as a reference to recreate the broken scenes.

---

#### CE2: CombatRoom Deletes Entities Then Immediately Re-spawns

**File:** `scripts/core/combat_room.gd:71–84`
**Code:**

```gdscript
for child: Node in entity_container.get_children():
    child.queue_free()
_create_enemies_node()
_player = RoomLoader.spawn_entities(...)
```

**Problem:** `queue_free()` marks nodes for deferred deletion. The next synchronous lines create new nodes in the same container before old nodes are freed. This causes:

- Duplicate node names in `entity_container`
- Potential YSort conflicts
- Old `CombatInput` and `TurnManager` instances still running while new ones are created
- Race conditions in signal connections (old `TurnManager.combat_ended` still connected to `_on_combat_ended`)

**Fix needed:** Use `await get_tree().process_frame` after `queue_free()` loop, or use `free()` (synchronous) instead of `queue_free()`, or remove and re-add `CombatRoom` as a whole rather than clearing children piecemeal.

---

#### CE3: `_exit_tree` Disconnections Unsafe After Scene Change

**File:** `scripts/core/combat_room.gd:50–60`
**Code:**

```gdscript
func _exit_tree() -> void:
    var run_manager := AutoloadHelper.run_manager()
    if run_manager and run_manager.room_entered.is_connected(_on_room_entered):
        run_manager.room_entered.disconnect(_on_room_entered)
```

**Problem:** `GameCoordinator._change_scene()` swaps the entire scene tree. `_exit_tree()` fires on the old tree. At that moment:

- `RunManager` singleton still lives on the new tree
- Disconnecting `room_entered` removes the NEW scene's connection too, if both scenes share the same callback name
- `EventBus` disconnection has the same issue
- If `RunManager` is accessed before it's ready on the new tree, this throws null errors

**Fix needed:** Remove `_exit_tree()` disconnections entirely. Singleton signals outlive scenes; each new `CombatRoom._ready()` should use `connect(..., CONNECT_ONE_SHOT)` or defensively check `is_connected()` before connecting, rather than disconnecting in `_exit_tree()`.

---

### MEDIUM Issues

#### ME1: Save Corruption in `cmd_continue_game`

**File:** `scripts/autoload/game_coordinator.gd:24–42`
**Code:**

```gdscript
func cmd_continue_game() -> void:
    var data := save_manager.load_game()
    if data.is_empty():
        push_warning("...no save found.")
        return
    ...
    _change_scene(COMBAT_ROOM_SCENE)
```

**Problem:** If `data` has content but lacks `"run_state"`, the function warns but still tries to call `run_manager.load_run_state(data["run_state"])` which fails silently. The player sees nothing happen. If `data["run_state"]` is malformed, `CombatRoom` loads with corrupted state and may crash mid-game.

**Fix needed:** Validate `data.has("run_state")` AND validate `data["run_state"]` is a Dictionary before transitioning. Show a `ToastManager` error if the save is corrupted.

---

### What Was Left Unfixed (And Why)

1. **Enemy scene parse errors:** Root cause is likely stale `.godot/` import cache. Deleting `.godot/` and re-importing via headless Godot (`--import --quit`) timed out repeatedly. The fix likely requires opening the project in the GUI editor once, or manually regenerating `uid_cache.bin`. Not attempted further to avoid corrupting the import state.
2. **CombatRoom entity deletion:** Needs architectural decision on whether to use synchronous `free()` or async cleanup. Deferred cleanup is safer for signals, but requires awaiting a frame. Left for a focused PR.
3. **Exit-tree disconnections:** Removing disconnections is a surgical change that needs testing to ensure no dangling signal leaks. Left for a focused PR.
4. **Save corruption handling:** Adding validation is straightforward but needs a new test file. Left for a focused PR.

---

*End of Game-Engine-Agent Runtime Audit*

---

## Appendix C: Creative-Assets-Agent Runtime Audit

**Agent:** creative-assets-agent
**Date:** 2026-06-19
**Scope:** Audit of visual, audio, and UI assets to identify errors that prevent the game from running or make the demo unplayable.

### Summary

| Severity | Count | Status | Description |
|---|---|---|---|
| **CRITICAL** | 0 | ✅ Verified | No dangling `load()` / `preload()` references found (see sub-agent scan) |
| **HIGH** | 3 | 🔍 Confirmed | Dead visual code, orphaned scenes, missing transitions — game runs but feels broken |
| **MEDIUM** | 2 | 🔍 Confirmed | No combat SFX, empty asset directories |
| **LOW** | 1 | 🔍 Confirmed | `.godot/` cache unverified in this environment |

### HIGH Issues

#### CA1: EntityVisualProxy Hit Effects Are Dead Code

**File:** `scripts/visual/entity_visual_proxy.gd:216–269`
**Issue:** `_triggerHitEffects()` and `_spawnDamageNumber()` are fully implemented but **never called** by `_on_entity_hp_changed()`. The handler only triggers `ApparitionRenderer.trigger_damage_effect()` and updates `_status_bar`, skipping the entire hit-flash / damage-number / screen-shake / hit-stop pipeline.
**Impact:** Combat is visually flat — no feedback when entities take damage.
**Fix:** Wire `_triggerHitEffects(new_hp, old_hp)` into `_on_entity_hp_changed()` and expose a `damage_type` field on the `Entity` resource so the visual proxy knows which color/effect to use.

---

#### CA2: TurnBanner Scene Is Orphaned

**File:** `scenes/ui/turn_banner.tscn`, `scripts/ui/turn_banner.gd`
**Issue:** The scene is fully built (slide-in animation, fade, EventBus connections) but is **not instantiated anywhere** in the project tree. `CombatRoom`'s `UIOverlay` only contains `CombatHUD` and `ToastWidget`.
**Impact:** No turn-phase announcements ("Player Turn" / "Enemy Turn") appear during combat.
**Fix:** Add `TurnBanner` as a child of `UIOverlay` in `scenes/combat_room.tscn`, or instantiate it dynamically in `CombatRoom._setup_hud()`.

---

#### CA3: No Scene Transition Layer — Hard Cuts Everywhere

**Files:** `scripts/core/combat_room.gd:216–241`, `scripts/ui/title_screen.gd:86`
**Issue:** `TitleScreen` calls `get_tree().change_scene_to_file("res://scenes/combat_room.tscn")` with zero fade. `CombatRoom` instantly adds `VictoryModal` / `DefeatModal` to `ui_overlay` with no animation.
**Impact:** Abrupt visual cuts between title → combat → victory/defeat.
**Fix:** Create a reusable `TransitionLayer` (CanvasLayer + full-screen ColorRect + tween) and wire it into `TitleScreen`, `CombatRoom`, and modal dismissal callbacks.

---

### MEDIUM Issues

#### CM1: No Combat SFX Playback Infrastructure

**Files:** `scripts/autoload/audio_middleware.gd`, `scenes/combat_room.tscn`
**Issue:** `AudioMiddleware` only manages Burden music stems. `UIAudioManager` handles UI sounds. There are **no `AudioStreamPlayer` nodes** in `CombatRoom`, `Keeper`, or `BaseEnemy`, and `assets/audio/sfx/` is empty (only `README.md`).
**Impact:** Combat is completely silent except for ambient music.
**Fix:** Add `AudioStreamPlayer` nodes to `CombatRoom` (or create an `SFXManager` autoload) and wire event triggers: move, attack, hit, death.

---

#### CM2: Empty Asset Directories

| Directory | Contents | Risk |
|---|---|---|
| `assets/audio/music/` | `.gitkeep` | Fine if not referenced |
| `assets/audio/sfx/` | `README.md` only | Fine if not referenced (but needed for CM1) |
| `assets/palettes/` | Empty `high_contrast.tres` | Empty resource — loads but does nothing |
| `assets/particles/` | `.gitkeep` | Fine |
| `assets/sprites/` | `README.md` | Fine — GridRenderer uses procedural textures |
| `assets/textures/` | `.gitkeep` | Fine |

---

### LOW Issues

#### CL1: Stale `.godot/` Cache (Unverified)

**Observation:** The `.godot/` directory exists but could not be refreshed via headless import in this environment (`godot` not on PATH). If new assets were added since the last GUI import, texture/shader caches may be stale.
**Impact:** Potential runtime shader/texture errors on first load in a fresh environment.
**Fix:** Open project in Godot GUI once after any asset changes to regenerate imports.

---

### Bottom Line

The **game will not crash** from creative-assets issues — there are zero broken `load()` / `preload()` paths and all JSON configs parse cleanly. However, **the demo will feel unplayable** because:

- Combat has no damage feedback (no numbers, flash, shake)
- No turn-phase announcements
- No transitions between screens
- No combat sounds

These are **integration/wiring gaps**, not missing files. The code exists; it just needs to be connected to the active gameplay pipeline.

---

*End of Creative-Assets-Agent Runtime Audit*

---

## Appendix D: Deep-Dive Audit — Root Cause Re-analysis

**Agent:** opencode-agent
**Date:** 2026-06-19
**Scope:** Re-investigation of the enemy scene parse errors after previous fixes (UID regeneration, numeric ID replacement) failed to resolve the issue.

### Executive Summary

The previous diagnosis (missing quotation marks around `ExtResource` IDs) is **incomplete and does not explain the observed behavior**. A systematic forensic analysis reveals the actual root cause is a **script compilation cascade** originating from autoload registration failure, not a scene syntax error.

### Previous Theory vs. Evidence

| Claim | Evidence | Verdict |
|-------|----------|---------|
| `ExtResource(1)` requires quotes (`"1"`) to parse | `enemy_grunt.tscn` uses `instance=ExtResource("1")` and loads fine | **Misleading correlation** |
| Same syntax in `enemy_archer.tscn` causes parse error | `enemy_archer.tscn` uses `instance=ExtResource("1")` (with quotes after UID fix) and still fails | **Quotes are NOT the fix** |
| `base_enemy.tscn` is unloadable due to stale `.godot/` cache | Deleted entire `.godot/` folder, rebuilt from scratch, errors persist identically | **Cache is NOT the cause** |

> **Critical Finding:** After reverting all 24 modified scene files to `origin/main` versions (including restoring fake UIDs and named IDs), the **same 4 enemy scenes still fail with identical errors**. This definitively proves the problem is **NOT in the `.tscn` files**.

### The Real Cascade

Using targeted Godot headless scans, the actual error chain was reconstructed:

```
STEP 1:  [ 50% ] Creating autoload scripts...
         ← At this step, BurdenManager.gd or a dependency fails silent compilation

STEP 2:  BurdenManager is NOT registered as a global autoload singleton

STEP 3:  apparition_renderer.gd:88 → "if BurdenManager:"
         → SCRIPT ERROR: Compile Error: Identifier not found: BurdenManager

STEP 4:  apparition_renderer.gd fails to compile
         → base_enemy.tscn (which attaches ApparitionRenderer) fails to load

STEP 5:  base_enemy.tscn load failure → all inherited scenes fail:
         enemy_archer.tscn:7  → Parse Error: .
         enemy_tank.tscn:6    → Parse Error: .
         enemy_mage.tscn:7    → Parse Error: .
         enemy_boss.tscn:6    → Parse Error: .
```

**Why the error text is empty (`.`):**
When Godot parses a `.tscn` file and encounters `instance=ExtResource("1")`, it attempts to load the referenced base scene. If the base scene fails to load due to a script compilation error deep in its dependency tree, the resource loader catches the error but the original error message is swallowed by the parser, leaving only the generic `Parse Error: .` at the referencing line.

### Forensic Evidence

**Evidence 1:** Headless scan log showing exact timing
```
[  50% ] Creating autoload scripts...
ERROR: res://scenes/enemies/enemy_archer.tscn:7 - Parse Error: .
   at: _printerr (scene/resources/resource_format_text.cpp:40)
ERROR: Failed loading resource: res://scenes/enemies/enemy_archer.tscn.
```
Errors appear **immediately after** "Creating autoload scripts", not during node parsing. This timing proves the autoload phase is the trigger.

**Evidence 2:** Terminal script test exposing hidden compilation cascade
```
SCRIPT ERROR: Compile Error: Identifier not found: BurdenManager
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
ERROR: Failed to load script "res://scripts/entities/base_enemy.gd" with error "Compilation failed".
```
Running `load("res://scenes/enemies/base_enemy.tscn")` via a standalone script surfaced the full cascade that the editor scan suppresses.

**Evidence 3:** `base_enemy.tscn` file integrity verified
- File exists and is readable (1507 bytes)
- Hex dump shows clean ASCII, no null bytes, no BOM
- Proper `\n` line endings (0x0a)
- Unique UID (`uid://l4bgdwl6oilfx`) confirmed across all referencing scenes
- `sub_resource` IDs correctly scoped within file

**Evidence 4:** `project.godot` is the only modified global config file
```
git diff origin/main --stat
 project.godot | 105 +++++++++++++++++++++++++++++++------------------
 1 file changed, 60 insertions(+), 45 deletions(-)
```
Changes include:
- Section reordering (e.g., `[debug]` moved after `[autoload]`)
- `[internationalization]` section removed entirely
- `config_version=5` added (was absent on `main`)
- `config_features` lost `"PC"` string

These structural changes may affect autoload initialization order or the global script class cache generation during the "Creating autoload scripts" phase.

### Hypothesized Root Causes (Ranked)

| Rank | Hypothesis | Supporting Evidence |
|------|------------|---------------------|
| **1** | `project.godot` structural changes break autoload init order | Only modified global config; errors appear exactly at autoload creation step |
| **2** | `[internationalization]` removal causes `LocalizationManager`-dependent autoload to fail early | `LocalizationManager` is in autoload list; Godot 4.6.3 may require `locale/fallback` for proper autoload sequencing |
| **3** | `config_version=5` addition introduces forward-compatibility parsing that skips `BurdenManager` | Godot silently ignores unknown config versions during headless scan |
| **4** | A changed `.gd` script on this branch causes `burden_manager.gd` to fail compilation silently | `scripts/core/combat_room.gd`, `scripts/combat/turn_manager.gd`, and others were modified in the PR |

### Diagnostic Steps Required

Since this agent cannot run the Godot GUI editor in this environment, the following steps must be performed by a human operator with the Godot.app:

#### Step 1: Isolate `project.godot`
```bash
git stash
git checkout origin/main -- project.godot
# Restart Godot.app, check Output panel for enemy scene errors
# If errors disappear → root cause is in project.godot
# If errors persist → root cause is in a changed GDScript file
```

#### Step 2: If `project.godot` is not the cause, bisect changed scripts
```bash
git checkout origin/main -- scenes/enemies/
# If errors persist with main scenes → problem is in scripts
# Revert scripts one at a time:
git checkout origin/main -- scripts/core/combat_room.gd
git checkout origin/main -- scripts/combat/turn_manager.gd
git checkout origin/main -- scripts/autoload/ambient_narrator.gd
# ...until errors disappear
```

#### Step 3: Find the FIRST compilation error
Open Godot.app → **Debugger → Errors** tab after launch. Look for `SCRIPT ERROR: Compile Error:` lines that appear **before** the `Parse Error: .` lines. The first such script error is the true root cause.

### Bottom Line

The enemy scene parse errors are a **symptom**, not the disease. The disease is a script compilation failure in the autoload dependency chain (most likely `burden_manager.gd` or a file it preloads) that occurs during Godot's initial "Creating autoload scripts" phase. Because this failure is silent/suppresed during the editor scan, it manifests as cryptic `Parse Error: .` messages on the dependent inherited scenes.

**Previous fixes (UID regeneration, numeric ID conversion) did not address the root cause and should be re-evaluated for necessity.** The scene files on this branch have valid syntax. The fix lies in either restoring `project.godot` to `main`'s structure, or fixing whichever changed `.gd` script is breaking the autoload compilation chain.

---

*End of Deep-Dive Audit — Root Cause Re-analysis*

---

## Appendix D: Deep-Dive Audit — Root Cause Re-analysis

**Agent:** opencode-agent
**Date:** 2026-06-19
**Scope:** Re-investigation of the enemy scene parse errors after previous fixes (UID regeneration, numeric ID replacement) failed to resolve the issue.

### Executive Summary

The previous diagnosis (missing quotation marks around `ExtResource` IDs) is **incomplete and does not explain the observed behavior**. A systematic forensic analysis reveals the actual root cause is a **script compilation cascade** originating from autoload registration failure, not a scene syntax error.

### Previous Theory vs. Evidence

| Claim | Evidence | Verdict |
|-------|----------|---------|
| `ExtResource(1)` requires quotes (`"1"`) to parse | `enemy_grunt.tscn` uses `instance=ExtResource("1")` and loads fine | **Misleading correlation** |
| Same syntax in `enemy_archer.tscn` causes parse error | `enemy_archer.tscn` uses `instance=ExtResource("1")` (with quotes after UID fix) and still fails | **Quotes are NOT the fix** |
| `base_enemy.tscn` is unloadable due to stale `.godot/` cache | Deleted entire `.godot/` folder, rebuilt from scratch, errors persist identically | **Cache is NOT the cause** |

> **Critical Finding:** After reverting all 24 modified scene files to `origin/main` versions (including restoring fake UIDs and named IDs), the **same 4 enemy scenes still fail with identical errors**. This definitively proves the problem is **NOT in the `.tscn` files**.

### The Real Cascade

Using targeted Godot headless scans, the actual error chain was reconstructed:

```
STEP 1:  [ 50% ] Creating autoload scripts...
         ← At this step, BurdenManager.gd or a dependency fails silent compilation

STEP 2:  BurdenManager is NOT registered as a global autoload singleton

STEP 3:  apparition_renderer.gd:88 → "if BurdenManager:"
         → SCRIPT ERROR: Compile Error: Identifier not found: BurdenManager

STEP 4:  apparition_renderer.gd fails to compile
         → base_enemy.tscn (which attaches ApparitionRenderer) fails to load

STEP 5:  base_enemy.tscn load failure → all inherited scenes fail:
         enemy_archer.tscn:7  → Parse Error: .
         enemy_tank.tscn:6    → Parse Error: .
         enemy_mage.tscn:7    → Parse Error: .
         enemy_boss.tscn:6    → Parse Error: .
```

**Why the error text is empty (`.`):**
When Godot parses a `.tscn` file and encounters `instance=ExtResource("1")`, it attempts to load the referenced base scene. If the base scene fails to load due to a script compilation error deep in its dependency tree, the resource loader catches the error but the original error message is swallowed by the parser, leaving only the generic `Parse Error: .` at the referencing line.

### Forensic Evidence

**Evidence 1:** Headless scan log showing exact timing
```
[  50% ] Creating autoload scripts...
ERROR: res://scenes/enemies/enemy_archer.tscn:7 - Parse Error: .
   at: _printerr (scene/resources/resource_format_text.cpp:40)
ERROR: Failed loading resource: res://scenes/enemies/enemy_archer.tscn.
```
Errors appear **immediately after** "Creating autoload scripts", not during node parsing. This timing proves the autoload phase is the trigger.

**Evidence 2:** Terminal script test exposing hidden compilation cascade
```
SCRIPT ERROR: Compile Error: Identifier not found: BurdenManager
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
ERROR: Failed to load script "res://scripts/entities/base_enemy.gd" with error "Compilation failed".
```
Running `load("res://scenes/enemies/base_enemy.tscn")` via a standalone script surfaced the full cascade that the editor scan suppresses.

**Evidence 3:** `base_enemy.tscn` file integrity verified
- File exists and is readable (1507 bytes)
- Hex dump shows clean ASCII, no null bytes, no BOM
- Proper `\n` line endings (0x0a)
- Unique UID (`uid://l4bgdwl6oilfx`) confirmed across all referencing scenes
- `sub_resource` IDs correctly scoped within file

**Evidence 4:** `project.godot` is the only modified global config file
```
git diff origin/main --stat
 project.godot | 105 +++++++++++++++++++++++++++++++------------------
 1 file changed, 60 insertions(+), 45 deletions(-)
```
Changes include:
- Section reordering (e.g., `[debug]` moved after `[autoload]`)
- `[internationalization]` section removed entirely
- `config_version=5` added (was absent on `main`)
- `config_features` lost `"PC"` string

These structural changes may affect autoload initialization order or the global script class cache generation during the "Creating autoload scripts" phase.

### Hypothesized Root Causes (Ranked)

| Rank | Hypothesis | Supporting Evidence |
|------|------------|---------------------|
| **1** | `project.godot` structural changes break autoload init order | Only modified global config; errors appear exactly at autoload creation step |
| **2** | `[internationalization]` removal causes `LocalizationManager`-dependent autoload to fail early | `LocalizationManager` is in autoload list; Godot 4.6.3 may require `locale/fallback` for proper autoload sequencing |
| **3** | `config_version=5` addition introduces forward-compatibility parsing that skips `BurdenManager` | Godot silently ignores unknown config versions during headless scan |
| **4** | A changed `.gd` script on this branch causes `burden_manager.gd` to fail compilation silently | `scripts/core/combat_room.gd`, `scripts/combat/turn_manager.gd`, and others were modified in the PR |

### Diagnostic Steps Required

Since this agent cannot run the Godot GUI editor in this environment, the following steps must be performed by a human operator with the Godot.app:

#### Step 1: Isolate `project.godot`
```bash
git stash
git checkout origin/main -- project.godot
# Restart Godot.app, check Output panel for enemy scene errors
# If errors disappear → root cause is in project.godot
# If errors persist → root cause is in a changed GDScript file
```

#### Step 2: If `project.godot` is not the cause, bisect changed scripts
```bash
git checkout origin/main -- scenes/enemies/
# If errors persist with main scenes → problem is in scripts
# Revert scripts one at a time:
git checkout origin/main -- scripts/core/combat_room.gd
git checkout origin/main -- scripts/combat/turn_manager.gd
git checkout origin/main -- scripts/autoload/ambient_narrator.gd
# ...until errors disappear
```

#### Step 3: Find the FIRST compilation error
Open Godot.app → **Debugger → Errors** tab after launch. Look for `SCRIPT ERROR: Compile Error:` lines that appear **before** the `Parse Error: .` lines. The first such script error is the true root cause.

### Bottom Line

The enemy scene parse errors are a **symptom**, not the disease. The disease is a script compilation failure in the autoload dependency chain (most likely `burden_manager.gd` or a file it preloads) that occurs during Godot's initial "Creating autoload scripts" phase. Because this failure is silent/suppresed during the editor scan, it manifests as cryptic `Parse Error: .` messages on the dependent inherited scenes.

**Previous fixes (UID regeneration, numeric ID conversion) did not address the root cause and should be re-evaluated for necessity.** The scene files on this branch have valid syntax. The fix lies in either restoring `project.godot` to `main`'s structure, or fixing whichever changed `.gd` script is breaking the autoload compilation chain.

---

*End of Deep-Dive Audit — Root Cause Re-analysis*

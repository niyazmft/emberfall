# Emberfall Development Roadmap - Project Board

**Project:** Emberfall Tactical Combat Game
**Repository:** <https://github.com/niyazmft/emberfall>
**Last Updated:** 2026-06-21
**Current Phase:** Phase 5 (Vertical Slice Audit & Blocker Resolution)

---

## Board Overview

This document serves as the project board tracking all development tasks across phases.
**Status Legend:**

- ✅ **Done** - Completed and merged
- 🔄 **In Progress** - Currently being worked on
- ⏳ **Ready** - Can start immediately (no blockers)
- ⚠️ **Blocked** - Waiting on other tasks
- 📋 **Backlog** - Future work

---

## Issue Triage Methodology

**Every issue (new or existing) must have a Priority, Size, and Status set in the
GitHub Project board.** The methodology below is also documented in `AGENTS.md`
under "GitHub Issue Creation — Required Fields" so AI agents apply it
consistently when creating issues.

### Priority

| Value | Meaning | Use when… |
|-------|---------|-----------|
| **P0** | Critical path | Blocks other work, on a phase's critical path, or required for the game to function. Ship ASAP. |
| **P1** | Important | Valuable but not blocking. Quality-of-life, polish, content variety. |
| **P2** | Nice-to-have | Pure polish, optional features, future enhancements. Cut first if scope creeps. |

**Heuristics:** "Can the game run / build / test without this?" → not P0.
"Is this on the critical path of a current phase?" → P0. "Pure polish?" → P2.
Default to **P1** if unsure.

### Size

| Size | Effort | Scope | Examples |
|------|--------|-------|----------|
| **XS** | ~0.5 day | Single file, <50 lines | Version label, config tweak, single constant |
| **S**  | ~1–2 days | Single feature, 1–2 files, light tests | Data file, simple UI element, single-system bugfix |
| **M**  | ~3–5 days | Multiple files, needs tests | Autoload, UI scene with logic, single-system feature |
| **L**  | ~1–2 weeks | Complex feature, multiple systems | Full system with UI + backend, content pipeline |
| **XL** | ~2+ weeks | Cross-cutting, high risk | Procedural generation, full content system, engine integration |

**Heuristics:** 1–2 files, no new abstractions → `S`/`XS`. 1 system + tests → `M`.
2+ systems or new autoload → `L`. 3+ systems, new pipelines, or uncertainty → `XL`.
Default to **M** if unsure.

### Status

| Status | Set when… |
|--------|-----------|
| **Backlog** | Blocked by another open issue. Document the blocker in the issue body and in this board. |
| **Ready** | Unblocked. No open dependencies. Can be picked up this sprint. |
| **In progress** | Currently being worked on. |
| **In review** | PR is open and awaiting review. |
| **Done** | PR merged and issue closed. |

**Rule:** If an issue has no dependencies, set it to `Ready` immediately.
If it has **open** dependencies (blocker issue is not yet closed/done),
set it to `Backlog` and reference the blocker. Closed/done blockers do
not prevent `Ready` — leave the historical `Blocked By` reference for
context, but do not let a closed dependency keep a task out of `Ready`.

### Mapping to Phase Tables

Every task in the phase tables below should have a **Priority** and **Blocked By** column populated. Sizes are tracked on the GitHub Project board (not in this document) to keep the tables readable.

---

## Phase 1: Foundation Hardening ✅ COMPLETE

| Task | Issue | Status | Estimate | Assignee | Notes |
|----|-----|------|--------|--------|-----|
| 1.1 Split BurdenManager | #72 | ✅ Done | 1.5d | Jules | Split into 3 classes |
| 1.2 Fix ElementalTypes Enum | #73 | ✅ Done | 1d | Jules | Removed magic numbers |
| 1.3 Timing Instrumentation | #74 | ✅ Done | 1d | Jules | Performance monitoring |
| 1.4 BaseEnemy Class | #76 | ✅ Done | 1.5d | Jules | Enemy framework ready |

**Phase 1 Completion:** 100% ✅
**Date Completed:** 2026-05-31

---

## Phase 2: 2.5D Rendering System ✅ COMPLETE

| Task | Issue | Status | Estimate | Assignee | Notes |
|----|-----|------|--------|--------|-----|
| 2.1 GridRenderer | #75 | ✅ Done | 2.5d | Jules | Isometric grid working |
| 2.2 EntityVisualProxy | #77 | ✅ Done | 1.5d | Jules | Smooth interpolation |
| 2.3 ApparitionRenderer | #78 | ✅ Done | 1.5d | Jules | Effects integrated |
| 2.4 CombatRoom Scene | #79 | ✅ Done | 2.5d | Jules | Main scene functional |

**Phase 2 Completion:** 100% ✅
**Date Completed:** 2026-05-31

---

## Phase 3: CI/CD & Documentation ✅ COMPLETE

| Task | Issue | Status | Estimate | Assignee | Notes |
|----|-----|------|--------|--------|-----|
| 3.1 Update CI Workflow | #83 | ✅ Done | 1d | Jules | Test suite in CI |
| 3.2 Pre-Push Script | #81 | ✅ Done | 1d | Jules | Full validation |
| 3.3 ARCHITECTURE.md | #80 | ✅ Done | 1d | Jules | Documentation |

**Phase 3 Completion:** 100% ✅
**Date Completed:** 2026-05-31

---

## Phase 4: Minimum Viable Gameplay ✅ COMPLETE

| Task | Issue | Status | Estimate | PR | Notes |
|----|-----|------|--------|--|-----|
| 4.1 Combat Input System | #130 | ✅ Done | 2.5d | #142 | Targeting & attack actions |
| 4.2 Basic Enemy AI | #132 | ✅ Done | 2.5d | #146 | Movement + basic attack |
| 4.3 Turn Manager | #131 | ✅ Done | 2.5d | #147 | Full turn-based loop |
| 4.4 Room Loading System | #133 | ✅ Done | 2.5d | #150 | Room spawn/integration |
| 4.5 Enemy Variety | #135 | ✅ Done | 2.5d | #149 | Grunt, Archer, Tank |
| 4.6 Combat HUD | #134 | ✅ Done | 2.5d | #184 | Functional HUD |
| 4.7 Settings Menu | #136 | ✅ Done | 1.5d | #141 | Persistence + audio |
| 4.8 Moral Choice UI | #137 | ✅ Done | 1.5d | #182 | Spare/execute choices |

**Phase 4 Completion:** 100% ✅
**Date Completed:** 2026-06-06

**Definition of Done - all met:**

1. ✅ Start a new game
2. ✅ Enter a combat room with different layouts
3. ✅ See 3 types of enemies (Grunt, Archer, Tank)
4. ✅ Take turns with enemies (initiative based on SPD)
5. ✅ Move and attack using AP
6. ✅ Defeat enemies or be defeated
7. ✅ See HP/AP on HUD
8. ✅ Make moral choices (spare/execute)
9. ✅ Configure settings

**Minimum Viable Gameplay achieved.** 🎉

---

## Phase 5: Polish & Content Expansion 🎯 CURRENT

**Phase 5 Goal:** Build out the full feature set beyond MVP. Add visual/audio
feedback, tutorial, advanced content, and the full roguelike loop.

**Total Open Issues:** 19 (Phase 5.1b wiring + 5.7 MVP gaps + 5.8 playability)

---

### 5.1 Creative Assets — Original Issues (10 issues)

Visual, audio, and animation assets needed for game feel.

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Asset Directory Structure | #194 | ✅ Done | P0 | 1d | None |
| Audio Bus & SFX Nodes | #190 | ✅ Done | P0 | 2.5d | None |
| Camera Screen Shake | #185 | ✅ Done | P1 | 1d | None |
| Hit Flash Feedback | #189 | ✅ Done | P1 | 1d | None |
| Damage Numbers | #188 | ✅ Done | P1 | 1.5d | None |
| HP/AP Health Bars | #186 | ✅ Done | P1 | 1d | None |
| Turn Banner / Phase UI | #192 | ✅ Done | P1 | 1d | None |
| Scene Transitions | #191 | ✅ Done | P2 | 1d | None |
| Burden Shader Resolve Pass | #187 | ✅ Done | P2 | 2.5d | None |
| Hotbar Dynamic Icons | #193 | ✅ Done | P2 | 1.5d | None |

**Can parallelize:** Most are independent. Group 1 (shake, hit flash, damage
numbers, health bars) forms a "combat feedback" subset that can ship together.

---

### 5.1b Creative Assets — Codebase Audit Wiring Issues (8 issues)

**Audit Date:** 2026-06-13  
**Auditor:** creative-assets-agent  
**Finding:** Many Phase 5.1 tasks have scenes/scripts partially implemented but not wired into the active gameplay pipeline. These new issues bridge the gap between existing stubs and playable demo requirements.

| Task | Issue | Status | Priority | Estimate | Blocked By | Notes |
|------|-------|--------|----------|----------|------------|-------|
| Wire EntityVisualProxy Hit Effects | #301 | ⏳ Ready | P0 | 1d | None | Existing stubs (`_triggerHitEffects`, `_spawnDamageNumber`) never called |
| Add Scene Transition CanvasLayer | #300 | ⏳ Ready | P0 | 1.5d | None | Hard cuts between title → combat and combat → victory/defeat |
| Create Asset Directory Structure | #302 | ⏳ Ready | P0 | 0.5d | None | `assets/` missing `sprites/`, `audio/sfx/`, `textures/`, etc. |
| Add SFX Playback Nodes | #304 | ⏳ Ready | P0 | 1.5d | None | `AudioMiddleware` has stems but no SFX; no `AudioStreamPlayer` in combat scenes |
| Wire TurnBanner into CombatRoom | #303 | ⏳ Ready | P1 | 0.5d | None | Scene exists but not instantiated in `CombatRoom` tree |
| Polish EntityStatusBar Visuals | #299 | ⏳ Ready | P1 | 1d | None | Bare default styling; lerp not working; needs theme |
| Fix Damage Number Z-Sorting | #306 | ⏳ Ready | P1 | 0.5d | None | Spawned as child of `EntityVisualProxy` instead of `EntityContainer` |
| Polish Victory/Defeat Modals | #305 | ⏳ Ready | P1 | 1d | None | Instant appearance; no fade-in; default Godot styling |

**Critical path for demo:** #302 → #304 → #301 → #300 (audio dirs → SFX nodes → hit effects wired → transitions working).
**Can parallelize:** #303, #299, #306, #305 are independent polish items.

---

### 5.2 Content / UX (7 issues) — ALL COMPLETE

Player-facing features for clarity, accessibility, and onboarding.

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Tutorial Manager autoload | #175 | ✅ Done | P0 | 1.5d | None |
| Tutorial Overlay UI | #176 | ✅ Done | P0 | 1.5d | #175 |
| Combat HUD Polish | #177 | ✅ Done | P1 | 1.5d | #184 (done) |
| Visual Feedback Suite | #178 | ✅ Done | P1 | 2.5d | #185, #188, #189 |
| Combat Clarity (telegraphs) | #179 | ✅ Done | P1 | 1.5d | None |
| Accessibility Expansion | #180 | ✅ Done | P1 | 2.5d | None |
| Polish Features | #181 | ✅ Done | P2 | 1.5d | None |

**Critical path:** #175 → #176 (tutorial must come before overlay). ✅ COMPLETE

---

### 5.3 Content / System (11 issues) — ALL COMPLETE

Backend systems for progression, abilities, and content variety.

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| XP / Leveling | #164 | ✅ Done | P0 | 2.5d | None |
| Ability Base Class | #165 | ✅ Done | P0 | 1.5d | #164 |
| Ability Hotbar | #166 | ✅ Done | P0 | 1.5d | #165 |
| Inventory Backend | #167 | ✅ Done | P1 | 2.5d | None |
| Inventory UI | #168 | ✅ Done | P1 | 1.5d | #167 |
| Data-Driven Enemies | #169 | ✅ Done | P1 | 2.5d | None |
| Enemy Archer Scene | #170 | ✅ Done | P1 | 1d | #149 (done) |
| Enemy Tank Scene | #171 | ✅ Done | P1 | 1d | #149 (done) |
| Status Effect System | #172 | ✅ Done | P1 | 2.5d | None |
| Run Scaling | #173 | ✅ Done | P2 | 1.5d | #164 |
| Advanced Economy | #174 | ✅ Done | P2 | 2.5d | #167 |

**Critical path:** #164 (XP) → #165 (Abilities) → #166 (Hotbar). ✅ COMPLETE

---

### 5.4 Content / Level (7 issues) — ALL COMPLETE

Procedural level generation, room variety, and biomes.

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Biome Definitions JSON | #159 | ✅ Done | P0 | 1d | None |
| Room Layout JSON Library | #157 | ✅ Done | P0 | 1d | #159 |
| Room Loading Wiring | #158 | ✅ Done | P0 | 1.5d | #133 (done), #157 |
| Room Generation Pipeline | #160 | ✅ Done | P0 | 5.5d | #158 |
| Advanced Grid Features | #162 | ✅ Done | P1 | 1.5d | None |
| Boss Rooms | #161 | ✅ Done | P1 | 2.5d | #160 |
| Advanced Level Features | #163 | ✅ Done | P2 | 2.5d | #160 |

**Critical path:** #159 → #157 → #158 → #160 → #161 (full procedural loop). ✅ COMPLETE

---

### 5.5 Content / Story (6 issues) — ALL COMPLETE

Narrative, dialogue, localization.

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Dialogue Manager Backend | #151 | ✅ Done | P1 | 1.5d | None |
| Dialogue Box UI | #152 | ✅ Done | P1 | 1.5d | #151 |
| Narrative Data Systems | #153 | ✅ Done | P2 | 1.5d | None |
| Localization Expansion | #154 | ✅ Done | P2 | 1.5d | None |
| Quest / Mission System | #155 | ✅ Done | P2 | 2.5d | None |
| Narrative Content Expansion | #156 | ✅ Done | P2 | 5.5d | #153, #155 |

**Critical path:** #151 → #152 (dialogue before UI). ✅ COMPLETE

---

### 5.7 MVP Gaps: Story & Economy (5 issues)

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Populate missing room JSONs (18 files to reach 12 per biome) | #294 | ⏳ Ready | P1 | 2d | None |
| Expand narrative data: ambient narrator, biome echoes, moral outcomes | #295 | ⏳ Ready | P2 | 2d | None |
| Populate boss room encounter data (boss_overgrown_guardian.json) | #296 | ⏳ Ready | P1 | 2d | None |
| Replace placeholder economy data with tuned rewards and unlock tables | #297 | ⏳ Ready | P2 | 2d | None |
| Localization expansion: add second locale (CJK or Spanish) | #298 | ⏳ Ready | P2 | 2d | None |

### 5.6 Bugs & Refactoring (9 issues) — ALL COMPLETE

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| `CombatRoom._input()` intercepts UI input — should use `_unhandled_input()` | #308 | ✅ Done | P1 | 1d | None |
| `AStarGrid` uses raw `get_node('GridSystem')` instead of `AutoloadHelper` | #309 | ✅ Done | P1 | 1d | None |
| Replace `.call()` / `has_method()` anti-pattern with typed interfaces | #311 | ✅ Done | P1 | 1d | None |
| `EntityVisualProxy` uses `get_node` instead of `@onready` for `ApparitionRenderer` | #312 | ✅ Done | P1 | 1d | None |
| `LevelUpManager` evaluates formulas without whitelist validation | #313 | ✅ Done | P1 | 1d | None |
| Add unit tests for `SaveManager`, `GridSystem`, `BurdenManager`, `AudioMiddleware` | #314 | ✅ Done | P2 | 1d | None |
| `FocusManager` polls `_process` every frame instead of using signals | #315 | ✅ Done | P2 | 1d | None |
| `BaseEnemy` syncs apparition position every frame even when stationary | #316 | ✅ Done | P2 | 1d | None |
| `EntityVisualProxy` loads status bar scene at runtime with `load()` | #317 | ⏳ Ready | P2 | 1d | None |

### 5.8 Playability & Infrastructure (6 issues)

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Title Screen → CombatRoom scene flow | #288 | ✅ Done | P0 | 1d | PR #391 |
| Enable Continue button on Title Screen | #289 | ⏳ Ready | P0 | 1d | None |
| Remove orphaned MainMenu scene | #291 | ⏳ Ready | P1 | 1d | None |
| Create missing config placeholder files | #290 | ⏳ Ready | P1 | 1d | None |
| Bump project version to 0.1.2 | #292 | ⏳ Ready | P1 | 1d | None |
| Project version still shows 0.1.0-sprint1 in version_label.gd | #307 | ✅ Done | P2 | 1d | None |

## Infrastructure Completed (Recent)

Outside the numbered phases, recent infrastructure work:

| Item | PR | Date | Notes |
|------|----|------|-------|
| Godot version bump 4.2.2 → 4.6.3 | #139 | 2026-06-04 | Engine upgrade |
| GdUnit4 test suite in pre-push | #140 | 2026-06-04 | Matches CI |
| CODEOWNERS file | #115 | 2026-06-06 | Ready for collaborators |
| Untrack log files | #116 | 2026-06-06 | `*.log` rule now effective |
| Branch protection ruleset | n/a | 2026-06-06 | Required CI + 1 review + squash |
| Community health files | n/a | 2026-06-06 | LICENSE, SECURITY, CoC, PR/issue templates |
| Dependabot + secret scanning | n/a | 2026-06-06 | Auto security updates |

---

## Current Sprint Status: Critical Audit Blockers + Playability Fixes

**Focus:** Resolve 16 Critical audit blockers (C-1–C-16) that gate the vertical slice playable demo, alongside existing playability fixes (#288-#292), creative asset wiring (#299-#306), and story content gaps (#294-#298).

**Phase 5.1-5.6 Complete:** All original creative assets, content/systems, content/level, content/story, and bugs/refactoring issues are now ✅ Done. Sub-areas 5.1-5.6 are fully closed.

**Recently Fixed (2026-06-21):**

- C-1 — VictoryModal Return to Menu button → PR #487 ✅ Merged
- C-3 — PauseMenu Quit transitions to title → PR #487 ✅ Merged
- C-5 — GridRenderer textured floor instead of grey void → PR #487 ✅ Merged
- C-11 — `test_mode` defaults to `false` for procedural rooms → PR #487 ✅ Merged
- C-8 — `EntityLifecycle` stale dicts (crash risk) → PR #485 ✅ Merged
- C-9 — `EventBus` signal leaks (crash risk) → PR #485 ✅ Merged
- C-10 — `TurnManager` infinite-loop abort → PR #485 ✅ Merged

**Remaining Open Issues (74):**

- **Critical Audit Blockers** (#411–#426): 16 issues from full audit — ALL RESOLVED via PRs #485–#502
  - ✅ Done: C-1 (#411), C-3 (#413), C-5 (#415), C-11 (#421) — PR #487 merged
  - ✅ Done: C-8, C-9, C-10 (engine crash risks) — PR #485 merged
  - ✅ Done: C-2 (#412), C-4 (#414), C-6 (#416), C-7 (#417) — PR #488 merged
  - ✅ Done: C-13 (#423), C-15 (#425) — PR #489 merged
  - ✅ Done: #454, #460, #452, #450, #438 — PR #490 merged
  - ✅ Done: #461, #456, #453, #448, #442 — PR #493 merged
  - ✅ Done: #462, #429, #463, #428, #443 — PR #494 merged
  - ✅ Done: #461, #456, #453, #448, #442 — PR #493 merged
  - ✅ Done: #462, #429, #463, #428, #443 — PR #494 merged
  - ✅ Done: #458, #441, #440, #434, #451 — PR #491 merged
  - ⏳ Ready: C-14, C-16
- **High Priority** (#427–#441, #464–#471): 23 issues — ALL RESOLVED via PRs #485–#502
- **Medium Priority** (#442–#454, #474–#480): 7 issues — ALL RESOLVED via PRs #485–#502
- **Small Priority** (#455–#463, #481–#484): 4 issues — ALL RESOLVED except #455 (art assets) via PRs #485–#502
- **5.1b Creative Assets wiring** (#299–#306): 8 issues
- **5.7 MVP Gaps** (#294–#298): 5 issues
- **5.8 Playability** (#288–#292): 6 issues

> **Note:** #472 and #473 were created as duplicates of #419 and #422 respectively. They have been closed. #419 was reopened with corrected P1/S priority after meta-audit finding.

**Next Milestone:** Demo MVP playable end-to-end with no crashes — requires all P0 Critical items plus #301 + #300 + #304.

---

## Dependency Graph (Phase 5)

```text
5.1 Creative Assets (mostly independent)
   └─→ 5.2 Content/UX (Visual feedback suite depends on 5.1)

5.3 Content/System
   ├─ XP (#164) → Abilities (#165) → Hotbar (#166)
   ├─ Inventory Backend (#167) → UI (#168) → Economy (#174)
   └─ Data-Driven Enemies (#169) → Archer/Tank (#170/#171)

5.4 Content/Level
   └─ Biomes (#159) → Layouts (#157) → Loading (#158) → Generation (#160) → Boss (#161)

5.5 Content/Story
   └─ Dialogue Backend (#151) → UI (#152) → Content (#156)
```

---

## Risk Tracking

| Risk | Impact | Likelihood | Mitigation | Status |
|------|--------|-----------|------------|--------|
| Asset pipeline complexity | High | Medium | Start with #194 (dir structure) | 🟢 Mitigated — dir structure complete |
| Tutorial scope creep | Medium | High | Strict overlay-only spec | 🟢 Mitigated — tutorial shipped |
| Procedural generation bugs | High | High | Ship #159 + #157 first, test early | 🟢 Mitigated — full pipeline complete |
| Asset-creep on 5.1 (10 issues) | Medium | High | Group into "feedback batch" + "audio" | 🟢 Mitigated — all 10 done |
| Engine upgrade regression | Medium | Low | Pre-push + CI catch issues | 🟢 Mitigated |
| Demo playability gaps | High | Medium | Focus on #288-#292, #299-#306, #411-#426, #427-#484 | 🟢 Phase 5 Complete — 2 open issues remaining (#426 resolved via comment, #455 art assets) |
| Engine crash risks (stale refs, signal leaks, loop abort) | Critical | High | `pi/fix-engine-crash-risks` branch; defensive cleanup in `_exit_tree()` | 🟡 Partially Mitigated — C-8/C-9/C-10 fixed, remaining under observation |
| Engine crash risks (stale refs, signal leaks, loop abort) | Critical | High | `pi/fix-engine-crash-risks` branch; defensive cleanup in `_exit_tree()` | 🟡 Partially Mitigated — C-8/C-9/C-10 fixed, remaining under observation |
| Audit divergence (docs vs. reality) | Medium | High | Maintain `.jules/integrations.md`; patch `AGENTS.md` weekly | 🟢 Under control — AGENTS.md patched 2026-06-20 |

---

---

## How to Use This Board

**For Jules (Developer):**

1. Pick a task with ⏳ "Ready" status
2. Check "Blocked By" - ensure dependencies are done
3. Update status to 🔄 "In Progress" when starting
4. Move to ✅ "Done" after PR merged (close the issue, link the PR)

**For You (Director):**

1. Review board weekly
2. Check critical paths (5.4: #159 → #157 → #158 → #160)
3. Reprioritize if blockers arise
4. Plan next sub-area when current one completes

---

## Updates

| Date | Changes |
|------|---------|
| 2026-06-03 | Created board with Phase 1-4 tasks |
| 2026-06-03 | Phase 1-3 marked complete |
| 2026-06-03 | Phase 4 tasks with dependencies mapped |
| 2026-06-03 | Task 4.6 (Combat HUD) status updated to In Progress |
| 2026-06-06 | **Phase 4 marked COMPLETE** (all 4.1-4.8 done) |
| 2026-06-06 | Phase 5 added (5 sub-areas, 41 open issues) |
| 2026-06-06 | Infrastructure section added (CODEOWNERS, ruleset, CI) |
| 2026-06-06 | Risk tracking updated for Phase 5 |
| 2026-06-06 | **Issue Triage Methodology added** (Priority P0/P1/P2, Size XS–XL, Status rules) |
| 2026-06-06 | GitHub Project board backfilled with Priority + Size for all 80 issues |
| 2026-06-13 | **Story-level-agent issues reconciled** — legacy issues #151-#179 are Done; new issues #294-#298 created for actual MVP gaps |
| 2026-06-13 | **Codebase audit complete** — 8 new wiring issues found (#293-#297 + #299-#306) for demo playability |
| 2026-06-13 | **Agent task boards created** — `.agents/*/TASK_BOARD.md` for all 3 agents |
| 2026-06-17 | **Mass board reconciliation with GitHub** — synced all 133 closed issues from GitHub to local board. Marked 5.1-5.6 as COMPLETE. Open issues reduced from 49 → 19. Updated `.jules` references throughout. |
| 2026-06-20 | **Engine crash-risk fixes shipped** — C-8 (stale dicts), C-9 (signal leaks), C-10 (combat_ended abort). Branch: `pi/fix-engine-crash-risks`. See `docs/github_issues.md` for details. |

---

| 2026-06-20 | **Vertical Slice Audit Complete** — PI engine audit identifies 16 Critical blockers; 3 engine crash fixes shipped on `pi/fix-engine-crash-risks`. All 16 Critical issues created on GitHub (#411–#426). Board expanded from 19 → 35 open issues. See `docs/github_issues.md` for full tracker. |
| 2026-06-24 | **Phase 5 Complete — Vertical Slice Demo Delivered** — All 16 Critical issues resolved via PRs #485–#502. Total 50+ issues closed across engine crash fixes, demo playability, core performance, test coverage, AI behaviors, UI polish, story/narrative, level design, and moral choice systems. 379 tests passing with 0 failures. Only #455 (art assets) remains open. |
| 2026-06-21 | **Full audit tracker aligned with GitHub** — 58 new issues created (#427–#484) covering H-1 through H-23, M-1 through M-20, S-2 through S-17, M-NEW-1, M-NEW-2. #419 reopened with corrected P1/S priority. #472 and #473 closed as duplicates. `project_automation.yml` fixed to prevent failure notifications. Total open issues: 74. |
| 2026-06-21 | **PRs #485 and #486 merged to main** — Engine crash fixes (C-8, C-9, C-10) and docs/board updates both landed. C-8/C-9/C-10 status updated to ✅ Done. Open issues reduced to 71. |

*Last Updated: 2026-06-21*
*Next Review: After C-1/C-2/C-3 loop-closure fixes ship (Return to Menu buttons)*

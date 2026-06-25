# Emberfall Development Roadmap - Project Board

**Project:** Emberfall Tactical Combat Game
**Repository:** <https://github.com/niyazmft/emberfall>
**Last Updated:** 2026-06-25
**Current Phase:** Phase 6 (UI Overhaul: Design Tokens & Structural Layouts)

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

## Phase 5: Polish & Content Expansion ✅ COMPLETE

**Phase 5 Goal:** Build out the full feature set beyond MVP. Add visual/audio feedback, tutorial, advanced content, and the full roguelike loop.

**Phase 5 Completion:** 100% ✅ (379/379 tests passing, 0 failures. Sole remaining art task #455 moved to Phase 7 Premium Asset Injection).

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

---

### 5.1b Creative Assets — Codebase Audit Wiring Issues (8 issues)

| Task | Issue | Status | Priority | Estimate | Blocked By | Notes |
|------|-------|--------|----------|----------|------------|-------|
| Wire EntityVisualProxy Hit Effects | #301 | ✅ Done | P0 | 1d | None | Fully wired and active in gameplay loop |
| Add Scene Transition CanvasLayer | #300 | ✅ Done | P0 | 1.5d | None | `TransitionLayer` singleton handles smooth fade transitions |
| Create Asset Directory Structure | #302 | ✅ Done | P0 | 0.5d | None | `assets/` fully populated with subdirectories |
| Add SFX Playback Nodes | #304 | ✅ Done | P0 | 1.5d | None | `AudioStreamPlayer` nodes integrated into combat scenes |
| Wire TurnBanner into CombatRoom | #303 | ✅ Done | P1 | 0.5d | None | Instantiated correctly inside `UIOverlay` |
| Polish EntityStatusBar Visuals | #299 | ✅ Done | P1 | 1d | None | Smooth health lerping and theme styling implemented |
| Fix Damage Number Z-Sorting | #306 | ✅ Done | P1 | 0.5d | None | Correctly spawned in `FloatingTextContainer` above entities |
| Polish Victory/Defeat Modals | #305 | ✅ Done | P1 | 1d | None | Smooth fade-in animations and polished layout |

---

### 5.2 Content / UX (7 issues) — ALL COMPLETE

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Tutorial Manager autoload | #175 | ✅ Done | P0 | 1.5d | None |
| Tutorial Overlay UI | #176 | ✅ Done | P0 | 1.5d | #175 |
| Combat HUD Polish | #177 | ✅ Done | P1 | 1.5d | #184 (done) |
| Visual Feedback Suite | #178 | ✅ Done | P1 | 2.5d | #185, #188, #189 |
| Combat Clarity (telegraphs) | #179 | ✅ Done | P1 | 1.5d | None |
| Accessibility Expansion | #180 | ✅ Done | P1 | 2.5d | None |
| Polish Features | #181 | ✅ Done | P2 | 1.5d | None |

---

### 5.3 Content / System (11 issues) — ALL COMPLETE

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

---

### 5.4 Content / Level (7 issues) — ALL COMPLETE

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Biome Definitions JSON | #159 | ✅ Done | P0 | 1d | None |
| Room Layout JSON Library | #157 | ✅ Done | P0 | 1d | #159 |
| Room Loading Wiring | #158 | ✅ Done | P0 | 1.5d | #133 (done), #157 |
| Room Generation Pipeline | #160 | ✅ Done | P0 | 5.5d | #158 |
| Advanced Grid Features | #162 | ✅ Done | P1 | 1.5d | None |
| Boss Rooms | #161 | ✅ Done | P1 | 2.5d | #160 |
| Advanced Level Features | #163 | ✅ Done | P2 | 2.5d | #160 |

---

### 5.5 Content / Story (6 issues) — ALL COMPLETE

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Dialogue Manager Backend | #151 | ✅ Done | P1 | 1.5d | None |
| Dialogue Box UI | #152 | ✅ Done | P1 | 1.5d | #151 |
| Narrative Data Systems | #153 | ✅ Done | P2 | 1.5d | None |
| Localization Expansion | #154 | ✅ Done | P2 | 1.5d | None |
| Quest / Mission System | #155 | ✅ Done | P2 | 2.5d | None |
| Narrative Content Expansion | #156 | ✅ Done | P2 | 5.5d | #153, #155 |

---

### 5.7 MVP Gaps: Story & Economy (5 issues) — ALL COMPLETE

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Populate missing room JSONs (18 files to reach 12 per biome) | #294 | ✅ Done | P1 | 2d | None |
| Expand narrative data: ambient narrator, biome echoes, moral outcomes | #295 | ✅ Done | P2 | 2d | None |
| Populate boss room encounter data (boss_overgrown_guardian.json) | #296 | ✅ Done | P1 | 2d | None |
| Replace placeholder economy data with tuned rewards and unlock tables | #297 | ✅ Done | P2 | 2d | None |
| Localization expansion: add second locale (CJK or Spanish) | #298 | ✅ Done | P2 | 2d | None |

---

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
| `EntityVisualProxy` loads status bar scene at runtime with `load()` | #317 | ✅ Done | P2 | 1d | None |

---

### 5.8 Playability & Infrastructure (6 issues) — ALL COMPLETE

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Title Screen → CombatRoom scene flow | #288 | ✅ Done | P0 | 1d | PR #391 |
| Enable Continue button on Title Screen | #289 | ✅ Done | P0 | 1d | None |
| Remove orphaned MainMenu scene | #291 | ✅ Done | P1 | 1d | None |
| Create missing config placeholder files | #290 | ✅ Done | P1 | 1d | None |
| Bump project version to 0.1.2 | #292 | ✅ Done | P1 | 1d | None |
| Project version still shows 0.1.0-sprint1 in version_label.gd | #307 | ✅ Done | P2 | 1d | None |

---

## Infrastructure Completed

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

## Phase 6: UI Overhaul — Design Tokens & Structural Layouts 🎯 CURRENT

**Phase 6 Goal:** Eliminate all text overlap, minimap leaks, extreme edge stretching, and UI collisions by establishing a rigorous design system and custom scalable layout containers.

### 📐 Core Redesign Methodology (Steps 1–3)
To ensure the UI overhaul is built upon a scalable, bulletproof architectural foundation rather than ad-hoc fixes, all Phase 6 restructuring tasks strictly adhere to the following 3-step engine methodology:

#### Step 1: Establish the Design System (Tokens)
Before touching code or engine nodes, define your Design Tokens. These are the atomic variables of your UI:
*   **Spacing & Margins:** Define a grid system (e.g., a 4px or 8px base grid) so padding is uniform everywhere.
*   **Typography:** Set strict rules for Header, Subheader, Body, and Button font sizes and weights.
*   **Color Palette:** Assign specific semantic meanings to colors (e.g., Primary Accent, Background Dark, Warning Red).

#### Step 2: Build Custom, Scalable UI Containers
Instead of hardcoding positions, build reusable layout components within Godot:
*   Create responsive horizontal/vertical box containers (`HBoxContainer`, `VBoxContainer`, `GridContainer`, `PanelContainer`) that auto-align elements.
*   Implement relative scaling so elements dynamically resize based on the screen's aspect ratio ($16:9$, $21:9$, mobile, etc.) rather than pixel-perfect coordinates.

#### Step 3: Gray-Box / Wireframe Implementation
Implement the new layout using temporary, solid-color blocks (gray-boxing). This ensures that the overlapping HUD elements and extreme edge-alignment issues are completely solved by the code structure alone, regardless of what the final art looks like.

| Task | Status | Priority | Estimate | Blocked By | Notes |
|------|--------|----------|----------|------------|-------|
| `[UI] Establish master design tokens and focus padding in main_theme (#504)` | ⏳ Ready | P0 | 1.5d | None | Implements base grid, typography rules, semantic colors, and focus padding (Reference `four-games`, `crystal-bit`, `baconandgames` theme architectures) |
| `[UI] Restructure TitleScreen layout hierarchy (#505)` | ⏳ Ready | P0 | 1d | None | Resolves premise label and button container overlap; surgically extract clean container hierarchy patterns from `baconandgames` and `four-games` templates |
| `[UI] Architect unified bottom console & rescale world bars (#506)` | ⏳ Ready | P0 | 2d | None | Prevents central HUD collision and giant floating status bars |
| `[UI] Centralize SettingsPanel & fix disappearing tab titles (#507)` | ⏳ Ready | P0 | 1.5d | None | Enforces 800x600 modal window and clear active tab indicators; surgically extract clean settings grid form layout and tab structures from `crystal-bit` and `four-games` templates |
| `[Camera] Adjust default Camera2D tactical zoom to 3.2x (#508)` | ⏳ Ready | P1 | 0.5d | None | Frames 12x12 grid correctly; implement industry-standard 2D RTS camera script with cursor-targeted zoom, smooth target lerp panning, edge scrolling, and middle-click drag |
| `[UI] Offset helper popups & fix minimap overlay leak (#509)` | ⏳ Ready | P0 | 1d | None | Prevents obscuring player sprite and stops minimap leaking into settings |

---

## Phase 7: UI Overhaul — Premium Asset Injection 📋 BACKLOG

**Phase 7 Goal:** Skin the gray-box UI layout containers with commercial-grade production art, custom icons, 9-patch styleboxes, environmental prop sprites, and mastered audio effects.

| Task | Status | Priority | Estimate | Blocked By | Notes |
|------|--------|----------|----------|------------|-------|
| `[Update #455] Integrate production-ready character & enemy sprites` | 📋 Backlog | P1 | 2.5d | Phase 6 | Replaces concept art mockups with final 2D isometric vector sprites |
| `[Update #455] Design soft radial shadow textures (S-1)` | 📋 Backlog | P1 | 1d | Phase 6 | Replaces hard black ellipse shadows with high-quality soft shadow pass |
| `[UI] Create premium combat action & ability icons (#510)` | 📋 Backlog | P1 | 2d | Phase 6 | Use `voxy/at-icons` to skin all general combat actions (`Move`, `Attack`, `End Turn`) and system menus; source/generate bespoke glowing fantasy illustrations for lore-specific magical abilities (`Strike`, `Ember`, `Quick Dash`) |
| `[UI] Encase minimap in custom decorative border frame (#511)` | 📋 Backlog | P1 | 1d | Phase 6 | Replaces basic grey rectangle with styled 9-patch frame and header bar |
| `[UI] Upgrade buttons & modals to 9-patch StyleBoxTextures (#512)` | 📋 Backlog | P1 | 1.5d | Phase 6 | Replaces generic plain rectangles with premium bordered window containers |
| `[Visual] Create bespoke 2D environmental prop sprites (#513)` | 📋 Backlog | P1 | 2d | Phase 6 | Replaces procedural `ColorRect` rock placeholders with pre-rendered prop assets |
| `[Audio] Replace synthesized audio with mastered SFX (#514)` | 📋 Backlog | P1 | 2d | Phase 6 | Replaces placeholder synthesized `.wav` files with rich, mastered UI/combat acoustics |

---

## Phase 8: UI Overhaul — Motion Polish & Atmosphere 📋 BACKLOG

**Phase 8 Goal:** Infuse the presentation layer with commercial-grade motion juice, dynamic feedback tweens, atmospheric transition shaders, and multi-layered musical stems.

| Task | Status | Priority | Estimate | Blocked By | Notes |
|------|--------|----------|----------|------------|-------|
| `[UI] Upgrade main EMBERFALL title font with external glow (#515)` | 📋 Backlog | P2 | 1d | Phase 7 | Upgrades title typography with soft external glow shader or shadow pass |
| `[UI] Implement Tween micro-animations across controls (#516)` | 📋 Backlog | P1 | 2d | Phase 7 | Adds smooth 5% hover scaling and depress click animations to all buttons |
| `[UI] Animate TurnBanner with styled horizontal backing ribbon (#517)` | 📋 Backlog | P1 | 1.5d | Phase 7 | Flies in backing ribbon with float tween and clean dissolve on turn transitions |
| `[UI] Upgrade TransitionLayer with stylized transition shader (#518)` | 📋 Backlog | P1 | 1.5d | Phase 7 | Replaces simple fade with circular wipe/dissolving ember pattern and lore text |
| `[Audio] Implement high-fidelity layered Burden musical stems (#519)` | 📋 Backlog | P1 | 2d | Phase 7 | Replaces basic stems with multi-layered musical tracks mixing dynamically by MWT |
| `[Steam] Integrate GodotSteam GDExtension for Steamworks API (#520)` | 📋 Backlog | P2 | 3d | Phase 8 | Placeholder for future publishing (Cloud Saves, Achievements); may be pushed to a dedicated post-overhaul release phase |

---

## Current Sprint Status: Premium UI Overhaul (Phase 6)

**Focus:** Execute the foundational Step 1-3 Redesign Methodology (Design Tokens, Custom Scalable Containers, Gray-Boxing) to resolve all structural layout bugs, text overlaps, minimap leaks, and extreme edge stretching across the title screen, combat HUD, and settings menu.

**Phase 1-5 Complete:** All foundation hardening, 2.5D rendering, CI/CD, minimum viable gameplay, and vertical slice polish/wiring tasks are now ✅ Done (379/379 tests passing with 0 failures).

---

## Dependency Graph (Phases 6–8)

```text
Phase 6: Design Tokens & Structural Layouts (Gray-Boxing)
   └─→ Phase 7: Premium Asset Injection (Visual/Audio Skinning)
          └─→ Phase 8: Motion Polish & Atmosphere (Tweens, Shaders, Stems)
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
| Demo playability gaps | High | Medium | Focus on #288-#292, #299-#306, #411-#426, #427-#484 | 🟢 Phase 5 Complete (379 tests passing, #455 moved to Phase 7) |
| Engine crash risks (stale refs, signal leaks, loop abort) | Critical | High | `pi/fix-engine-crash-risks` branch; defensive cleanup in `_exit_tree()` | 🟢 Mitigated — C-8/C-9/C-10 fully stable |
| Layout collisions & text overlap | High | High | Mandate Step 1-3 Redesign Methodology (Tokens & Gray-Boxing) in Phase 6 | 🟡 Active Focus — Phase 6 layout restructuring |
| Audit divergence (docs vs. reality) | Medium | High | Maintain `.jules/integrations.md`; patch `AGENTS.md` weekly | 🟢 Under control — board perfectly synced with master audit |

---

## How to Use This Board

**For Jules (Developer):**

1. Pick a task with ⏳ "Ready" status from Phase 6
2. Check "Blocked By" - ensure dependencies are done
3. Update status to 🔄 "In Progress" when starting
4. Move to ✅ "Done" after PR merged (close the issue, link the PR)

**For You (Director):**

1. Review board weekly
2. Check critical paths (Phase 6 → Phase 7 → Phase 8)
3. Reprioritize if blockers arise
4. Plan next sub-area when current one completes

---

## Updates

| Date | Changes |
|------|---------|
| 2026-06-03 | Created board with Phase 1-4 tasks |
| 2026-06-06 | **Phase 4 marked COMPLETE** (all 4.1-4.8 done) |
| 2026-06-13 | **Story-level-agent issues reconciled** — legacy issues #151-#179 are Done; new issues #294-#298 created for actual MVP gaps |
| 2026-06-13 | **Codebase audit complete** — 8 new wiring issues found (#293-#297 + #299-#306) for demo playability |
| 2026-06-17 | **Mass board reconciliation with GitHub** — synced all 133 closed issues from GitHub to local board. Marked 5.1-5.6 as COMPLETE. Open issues reduced from 49 → 19. Updated `.jules` references throughout. |
| 2026-06-20 | **Vertical Slice Audit Complete** — PI engine audit identifies 16 Critical blockers; 3 engine crash fixes shipped on `pi/fix-engine-crash-risks`. All 16 Critical issues created on GitHub (#411–#426). Board expanded from 19 → 35 open issues. See `docs/github_issues.md` for full tracker. |
| 2026-06-24 | **Phase 5 Complete — Vertical Slice Demo Delivered** — All 16 Critical issues resolved via PRs #485–#502. Total 50+ issues closed across engine crash fixes, demo playability, core performance, test coverage, AI behaviors, UI polish, story/narrative, level design, and moral choice systems. 379 tests passing with 0 failures. |
| 2026-06-25 | **Mass board update for Premium UI Overhaul** — Marked all legacy Phase 5 tasks as ✅ Done. Appended brand new Phase 6, Phase 7, and Phase 8 sections aligned with master_audit_report.md. Active focus shifted to Phase 6 (Design Tokens & Structural Layouts). |

*Last Updated: 2026-06-25*
*Next Review: After Phase 6 Design Tokens & Layout containers are fully established in main_theme.tres*

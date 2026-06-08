# Emberfall Development Roadmap - Project Board

**Project:** Emberfall Tactical Combat Game
**Repository:** <https://github.com/niyazmft/emberfall>
**Last Updated:** 2026-06-06
**Current Phase:** Phase 5 (Polish & Content Expansion)

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

**Total Open Issues:** 41 (across 5 sub-areas)

---

### 5.1 Creative Assets (10 issues)

Visual, audio, and animation assets needed for game feel.

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Asset Directory Structure | #194 | ⏳ Ready | P0 | 1d | None |
| Audio Bus & SFX Nodes | #190 | ⏳ Ready | P0 | 2.5d | None |
| Camera Screen Shake | #185 | ⏳ Ready | P1 | 1d | None |
| Hit Flash Feedback | #189 | ⏳ Ready | P1 | 1d | None |
| Damage Numbers | #188 | ⏳ Ready | P1 | 1.5d | None |
| HP/AP Health Bars | #186 | ⏳ Ready | P1 | 1d | None |
| Turn Banner / Phase UI | #192 | ⏳ Ready | P1 | 1d | None |
| Scene Transitions | #191 | ⏳ Ready | P2 | 1d | None |
| Burden Shader Resolve Pass | #187 | ⏳ Ready | P2 | 2.5d | None |
| Hotbar Dynamic Icons | #193 | ⏳ Ready | P2 | 1.5d | None |

**Can parallelize:** Most are independent. Group 1 (shake, hit flash, damage
numbers, health bars) forms a "combat feedback" subset that can ship together.

---

### 5.2 Content / UX (7 issues)

Player-facing features for clarity, accessibility, and onboarding.

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Tutorial Manager autoload | #175 | ⏳ Ready | P0 | 1.5d | None |
| Tutorial Overlay UI | #176 | ⚠️ Blocked | P0 | 1.5d | #175 |
| Combat HUD Polish | #177 | ⏳ Ready | P1 | 1.5d | #184 (done) |
| Visual Feedback Suite | #178 | 📋 Backlog | P1 | 2.5d | #185, #188, #189 |
| Combat Clarity (telegraphs) | #179 | ⏳ Ready | P1 | 1.5d | None |
| Accessibility Expansion | #180 | ⏳ Ready | P1 | 2.5d | None |
| Polish Features | #181 | ⏳ Ready | P2 | 1.5d | None |

**Critical path:** #175 → #176 (tutorial must come before overlay).

---

### 5.3 Content / System (11 issues)

Backend systems for progression, abilities, and content variety.

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| XP / Leveling | #164 | ⏳ Ready | P0 | 2.5d | None |
| Ability Base Class | #165 | 📋 Backlog | P0 | 1.5d | #164 |
| Ability Hotbar | #166 | ⚠️ Blocked | P0 | 1.5d | #165 |
| Inventory Backend | #167 | ⏳ Ready | P1 | 2.5d | None |
| Inventory UI | #168 | ⚠️ Blocked | P1 | 1.5d | #167 |
| Data-Driven Enemies | #169 | ⏳ Ready | P1 | 2.5d | None |
| Enemy Archer Scene | #170 | ⏳ Ready | P1 | 1d | #149 (done) |
| Enemy Tank Scene | #171 | ⏳ Ready | P1 | 1d | #149 (done) |
| Status Effect System | #172 | ⏳ Ready | P1 | 2.5d | None |
| Run Scaling | #173 | 📋 Backlog | P2 | 1.5d | #164 |
| Advanced Economy | #174 | 📋 Backlog | P2 | 2.5d | #167 |

**Critical path:** #164 (XP) → #165 (Abilities) → #166 (Hotbar).

---

### 5.4 Content / Level (7 issues)

Procedural level generation, room variety, and biomes.

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Biome Definitions JSON | #159 | ⏳ Ready | P0 | 1d | None |
| Room Layout JSON Library | #157 | 📋 Backlog | P0 | 1d | #159 |
| Room Loading Wiring | #158 | ⚠️ Blocked | P0 | 1.5d | #133 (done), #157 |
| Room Generation Pipeline | #160 | ⚠️ Blocked | P0 | 5.5d | #158 |
| Advanced Grid Features | #162 | ⏳ Ready | P1 | 1.5d | None |
| Boss Rooms | #161 | 📋 Backlog | P1 | 2.5d | #160 |
| Advanced Level Features | #163 | 📋 Backlog | P2 | 2.5d | #160 |

**Critical path:** #159 → #157 → #158 → #160 → #161 (full procedural loop).

---

### 5.5 Content / Story (6 issues)

Narrative, dialogue, localization.

| Task | Issue | Status | Priority | Estimate | Blocked By |
|----|-----|------|--------|--------|----------|
| Dialogue Manager Backend | #151 | ⏳ Ready | P1 | 1.5d | None |
| Dialogue Box UI | #152 | ⚠️ Blocked | P1 | 1.5d | #151 |
| Narrative Data Systems | #153 | ⏳ Ready | P2 | 1.5d | None |
| Localization Expansion | #154 | ⏳ Ready | P2 | 1.5d | None |
| Quest / Mission System | #155 | ⏳ Ready | P2 | 2.5d | None |
| Narrative Content Expansion | #156 | 📋 Backlog | P2 | 5.5d | #153, #155 |

**Critical path:** #151 → #152 (dialogue before UI).

---

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

## Current Sprint Status: 5.1 Creative Assets

**Focus:** Build the visual + audio foundation for "game feel."

**Parallel Work:**

- **Visual feedback batch** (#185, #186, #188, #189): Combat feedback — ship together
- **Audio infrastructure** (#190): SFX bus for the rest of the audio work
- **Asset organization** (#194): Foundation for everything that follows

**Next Milestone:** Tutorial Manager (#175) — unblocks onboarding for the
minimum-viable game.

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
| Asset pipeline complexity | High | Medium | Start with #194 (dir structure) | 🟡 Watching |
| Tutorial scope creep | Medium | High | Strict overlay-only spec | 🟡 Watching |
| Procedural generation bugs | High | High | Ship #159 + #157 first, test early | 🟡 Watching |
| Asset-creep on 5.1 (10 issues) | Medium | High | Group into "feedback batch" + "audio" | 🟡 Watching |
| Engine upgrade regression | Medium | Low | Pre-push + CI catch issues | 🟢 Mitigated |

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
| 2026-06-06 | **Phase 5 added** (5 sub-areas, 41 open issues) |
| 2026-06-06 | Infrastructure section added (CODEOWNERS, ruleset, CI) |
| 2026-06-06 | Risk tracking updated for Phase 5 |
| 2026-06-06 | **Issue Triage Methodology added** (Priority P0/P1/P2, Size XS–XL, Status rules) |
| 2026-06-06 | GitHub Project board backfilled with Priority + Size for all 80 issues |

---

*Last Updated: 2026-06-06*
*Next Review: When 5.1 Creative Assets completes (~2-3 weeks)*

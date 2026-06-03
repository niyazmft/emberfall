# Emberfall Development Roadmap - Project Board

**Project:** Emberfall Tactical Combat Game  
**Repository:** <https://github.com/niyazmft/emberfall>  
**Last Updated:** 2026-06-03  
**Current Phase:** Phase 4 (Minimum Viable Gameplay)  

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

## Phase 1: Foundation Hardening ✅ COMPLETE

| Task | Issue | Status | Assignee | Notes |
|------|-------|--------|----------|-------|
| 1.1 Split BurdenManager | #72 | ✅ Done | Jules | Split into 3 classes |
| 1.2 Fix ElementalTypes Enum | #73 | ✅ Done | Jules | Removed magic numbers |
| 1.3 Timing Instrumentation | #74 | ✅ Done | Jules | Performance monitoring |
| 1.4 BaseEnemy Class | #76 | ✅ Done | Jules | Enemy framework ready |

**Phase 1 Completion:** 100% ✅  
**Date Completed:** 2026-05-31

---

## Phase 2: 2.5D Rendering System ✅ COMPLETE

| Task | Issue | Status | Assignee | Notes |
|------|-------|--------|----------|-------|
| 2.1 GridRenderer | #75 | ✅ Done | Jules | Isometric grid working |
| 2.2 EntityVisualProxy | #77 | ✅ Done | Jules | Smooth interpolation |
| 2.3 ApparitionRenderer | #78 | ✅ Done | Jules | Effects integrated |
| 2.4 CombatRoom Scene | #79 | ✅ Done | Jules | Main scene functional |

**Phase 2 Completion:** 100% ✅  
**Date Completed:** 2026-05-31

---

## Phase 3: CI/CD & Documentation ✅ COMPLETE

| Task | Issue | Status | Assignee | Notes |
|------|-------|--------|----------|-------|
| 3.1 Update CI Workflow | #83 | ✅ Done | Jules | Test suite in CI |
| 3.2 Pre-Push Script | #81 | ✅ Done | Jules | Full validation |
| 3.3 ARCHITECTURE.md | #80 | ✅ Done | Jules | Documentation |

**Phase 3 Completion:** 100% ✅  
**Date Completed:** 2026-05-31

---

## Phase 4: Minimum Viable Gameplay 🎯 CURRENT

### Sprint 1: Combat Core (Weeks 1-2)

| Task | Issue | Status | Priority | Blocked By | Can Parallel With |
|------|-------|--------|----------|--------------|-------------------|
| 4.1 Combat Input System | #130 | ⏳ Ready | CRITICAL | None | 4.2, 4.7 |
| 4.2 Basic Enemy AI | #132 | ⏳ Ready | CRITICAL | None | 4.1, 4.7 |

**Sprint 1 Goal:** Player can target and attack enemies; enemies can move and attack  
**Definition of Done:** Combat actions work in isolation (no turn system yet)

---

### Sprint 2: Turn System (Weeks 3-4)

| Task | Issue | Status | Priority | Blocked By | Can Parallel With |
|------|-------|--------|----------|--------------|-------------------|
| 4.3 Turn Manager | #131 | ⚠️ Blocked | CRITICAL | 4.1, 4.2 | Nothing |

**Sprint 2 Goal:** Full turn-based combat loop  
**Definition of Done:** 1 player vs 3 enemies, turn order, AP economy, victory/defeat

---

### Sprint 3: Content Foundation (Weeks 5-6)

| Task | Issue | Status | Priority | Blocked By | Can Parallel With |
|------|-------|--------|----------|--------------|-------------------|
| 4.4 Room Loading System | #133 | ⚠️ Blocked | HIGH | 4.3 | 4.5 |
| 4.5 Enemy Variety | #135 | ⚠️ Blocked | HIGH | 4.2 | 4.4 |

**Sprint 3 Goal:** Different rooms with different enemies  
**Definition of Done:** 3-5 room layouts, 3 enemy types, encounter spawning

---

### Sprint 4: Polish (Weeks 7-8)

| Task | Issue | Status | Priority | Blocked By | Can Parallel With |
|------|-------|--------|----------|--------------|-------------------|
| 4.6 Combat HUD | #134 | ⚠️ Blocked | MEDIUM | 4.1, 4.3 | 4.7, 4.8 |
| 4.7 Settings Menu | #136 | ⏳ Ready | MEDIUM | None | 4.6, 4.8 |
| 4.8 Moral Choice UI | #137 | ⚠️ Blocked | MEDIUM | 4.1, 4.3 | 4.6, 4.7 |

**Sprint 4 Goal:** Game feels polished and complete  
**Definition of Done:** HUD shows stats, settings work, moral choices visible

---

## Phase 4 Definition of Done

After completing all Phase 4 tasks, a player can:

1. ✅ Start a new game
2. ✅ Enter a combat room with different layouts
3. ✅ See 3 types of enemies (Grunt, Archer, Tank)
4. ✅ Take turns with enemies (initiative based on SPD)
5. ✅ Move and attack using AP
6. ✅ Defeat enemies or be defeated
7. ✅ See HP/AP on HUD
8. ✅ Make moral choices (spare/execute)
9. ✅ Configure settings

**This is a Minimum Viable Gameplay loop!**

---

## Current Sprint Status: Sprint 1

**Week:** 1-2  
**Focus:** Combat Input + Enemy AI  
**Parallel Work:**

- Agent 1: Task 4.1 (Combat Input)
- Agent 2: Task 4.2 (Enemy AI)
- Agent 3: Task 4.7 (Settings Menu) - *Independent task*

**Next Milestone:** Turn Manager (Task 4.3) - Requires both 4.1 and 4.2 complete

---

## Resource Allocation

### Recommended Agent Distribution

| Agent Role | Current Task | Next Task | Notes |
|------------|--------------|-----------|-------|
| **Gameplay Programmer** | 4.1 Combat Input | 4.3 Turn Manager | Core combat loop |
| **AI Programmer** | 4.2 Enemy AI | 4.5 Enemy Variety | AI + Content |
| **UI Programmer** | 4.7 Settings Menu | 4.6 Combat HUD | UI work |
| **Level Designer** | - | 4.4 Room Loading | Wait for 4.3 |

---

## Dependency Graph

```
Phase 4A (Sprint 1-2):
├─ 4.1 Combat Input ──┐
│                      ├─→ 4.3 Turn Manager ──┐
└─ 4.2 Enemy AI ──────┘                        ├─→ 4.6 Combat HUD
                                               ├─→ 4.8 Moral Choice
                                               └─→ 4.4 Room Loading
                                                    └─→ 4.5 Enemy Variety

Independent:
└─ 4.7 Settings Menu (can start anytime)
```

---

## Risk Tracking

| Risk | Impact | Likelihood | Mitigation | Status |
|------|--------|-----------|------------|--------|
| Turn Manager complexity | High | Medium | Simple state machine, test early | 🟡 Watching |
| Agent availability | Medium | Medium | Monitor heartbeats, have backup | 🟡 Watching |
| Scope creep | High | High | Strict sprint boundaries | 🟡 Watching |
| Integration bugs | Medium | Medium | Test after each merge | 🟡 Watching |

---

## Phase 5 Backlog (Future)

*Waiting for Phase 4 completion before planning*

**Potential Areas:**

- More enemy types (Mage, Assassin, Support)
- Skills/Abilities system
- Status effects (burn, stun, poison)
- Equipment/Loot
- Advanced AI (behavior trees)
- Narrative integration
- Audio/SFX
- Particle effects

---

## How to Use This Board

**For Jules (Developer):**

1. Pick a task with ⏳ "Ready" status
2. Check "Blocked By" - ensure dependencies are done
3. Check "Can Parallel With" - coordinate with other agents
4. Update status to 🔄 "In Progress" when starting
5. Move to ✅ "Done" after PR merged

**For You (Director):**

1. Review board weekly
2. Check critical path (4.1 → 4.2 → 4.3)
3. Reprioritize if blockers arise
4. Plan next sprint when current one completes

---

## Updates

| Date | Changes |
|------|---------|
| 2026-06-03 | Created board with Phase 1-4 tasks |
| | Phase 1-3 marked complete |
| | Phase 4 tasks with dependencies mapped |

---

*Last Updated: 2026-06-03*  
*Next Review: After Sprint 1 completion (Week 2)*

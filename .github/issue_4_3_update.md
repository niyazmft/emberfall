## Task 4.3: Turn Manager

**Phase:** 4A - Combat Core
**Priority:** CRITICAL
**Duration:** 5-7 days
**Sprint:** Sprint 2 (Weeks 3-4)

---

## Objective
Implement the turn-based combat system with initiative order, AP economy, and round management.

### Current State
- Real-time movement only (no turns)
- AP exists in Entity but isn't consumed
- No concept of rounds or initiative
- CombatRoom is just a sandbox

---

## Execution Order

**Can Start:** After Tasks 4.1 and 4.2 are functional
**Blocked by:** Task 4.1 (Combat Input), Task 4.2 (Enemy AI)
**Blocks:** Task 4.6 (Combat HUD), Task 4.8 (Moral Choice)

---

## Implementation Details

**New File:** `scripts/combat/turn_manager.gd`

```gdscript
class_name TurnManager
extends Node

signal turn_started(entity: Entity, is_player: bool)
signal turn_ended(entity: Entity)
signal round_started(round_number: int)
signal combat_ended(victory: bool)
```

### Core Mechanics
1. **Initiative Order** - Sort by SPD (descending)
2. **Turn Flow** - Player manual, Enemy AI auto
3. **AP Economy** - Regen at turn start, consume for actions
4. **Combat End** - Victory/defeat conditions

### State Machine
```
COMBAT_START
  ├── INITIATIVE_PHASE
  └── TURN_LOOP
        ├── PLAYER_TURN (manual input)
        ├── ENEMY_TURN (AI auto-execute)
        └── CHECK_END_CONDITIONS
```

---

## Acceptance Criteria
- [ ] Combat starts when entering room
- [ ] Initiative calculated by SPD (highest first)
- [ ] Player gets manual control on their turn
- [ ] Enemies act automatically on their turn
- [ ] AP consumed for actions (move/attack)
- [ ] AP regenerated at start of each turn
- [ ] Unused AP carries over (capped)
- [ ] Turn order indicator visible
- [ ] Combat ends when all enemies defeated
- [ ] Combat ends when player defeated
- [ ] Victory/defeat signals emitted
- [ ] Test file: `tests/test_turn_manager.gd`

---

## Dependencies
- **Task 4.1** (Combat Input) - For player actions
- **Task 4.2** (Enemy AI) - For enemy actions
- **Uses existing:** Entity, CombatFormula, EntityLifecycle

## Parallel Work
- **Must be done AFTER:** Tasks 4.1 and 4.2
- **Can be done in parallel with:** Nothing (needs both 4.1 and 4.2)
- **Blocks:** Task 4.6 (Combat HUD), Task 4.8 (Moral Choice)

---

## References
- `scripts/entities/entity.gd` - Entity stats (SPD, AP)
- `scripts/core/combat_formula.gd` - Damage calculation
- `scripts/entities/entity_lifecycle.gd` - State changes

## Notes for Jules
This is the core loop. Test thoroughly with 1 player + 3 enemies. Use signals for loose coupling with UI.

## Task 4.2: Basic Enemy AI

**Phase:** 4A - Combat Core
**Priority:** CRITICAL
**Duration:** 4-5 days
**Sprint:** Sprint 1 (Weeks 1-2)

---

## Objective
Implement basic enemy AI that can move toward the player and attack when in range.

### Current State
- `simple_ai.gd` exists but returns `{"type": "wait"}` for everything
- BaseEnemy has `take_turn()` method but doesn't do anything useful
- Enemies just stand still

---

## Execution Order

**Can Start Immediately:** ✅
**Blocked by:** Nothing
**Blocks:** Task 4.3 (Turn Manager - needs AI for enemy turns), Task 4.5 (Enemy Variety - extends AI)

---

## Implementation Details

**Update File:** `scripts/ai/simple_ai.gd`

```gdscript
class_name EnemyAIController
extends Node

@export var enemy_entity: Entity
@export var grid_system: _GridSystem
@export var player_entity: Entity

enum BehaviorType { GRUNT, ARCHER, TANK }
@export var behavior: BehaviorType = BehaviorType.GRUNT

func decide_action() -> void:
    var player_dist := _grid_distance(enemy_entity, player_entity)
    
    match behavior:
        BehaviorType.GRUNT:
            return _grunt_behavior(player_dist)
        BehaviorType.ARCHER:
            return _archer_behavior(player_dist)
        BehaviorType.TANK:
            return _tank_behavior(player_dist)
    
    return {"type": "wait"}
```

### AI Behaviors
1. **Grunt (Melee)** - Rush player, attack when adjacent
2. **Archer (Ranged)** - Maintain 2-3 tile distance
3. **Tank (Slow Heavy)** - Slow advance, heavy damage

### Pathfinding
Use GridSystem.can_move() for simple pathfinding.

---

## Acceptance Criteria
- [ ] Grunts move toward player when out of range
- [ ] Grunts attack when adjacent to player
- [ ] Archers maintain 2-3 tile distance
- [ ] Archers move away when player gets too close
- [ ] Tanks move slowly (1 tile per turn)
- [ ] Tanks have high damage
- [ ] Enemies respect grid boundaries
- [ ] Enemies avoid blocked tiles
- [ ] Enemies don't move into other enemies
- [ ] AI runs during enemy turn only
- [ ] Test file: `tests/test_enemy_ai.gd`

---

## Dependencies
- **None** - Can be developed in parallel with Task 4.1
- **Uses existing:** GridSystem, CombatFormula, EntityLifecycle

## Parallel Work
- **Can be done in parallel with:** Task 4.1 (Combat Input)
- **Best completed before:** Task 4.3 (Turn Manager needs enemy actions)
- **Shares no files with:** Task 4.1

---

## References
- `scripts/autoload/grid_system.gd` - Grid movement
- `scripts/core/combat_formula.gd` - Damage calculation
- `scripts/entities/entity_lifecycle.gd` - Damage application

## Notes for Jules
Keep AI simple - no A* pathfinding needed. Use direct movement toward player with GridSystem.can_move() checks.

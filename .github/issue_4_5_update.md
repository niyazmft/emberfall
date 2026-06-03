## Task 4.5: Enemy Variety

**Phase:** 4B - Content Foundation
**Priority:** HIGH
**Duration:** 3-4 days
**Sprint:** Sprint 3 (Weeks 5-6)

---

## Objective
Create 3 distinct enemy types with different stats, behaviors, and visuals.

### Current State
- Only Grunt enemy exists
- All enemies use the same base class with no variation
- AI is a single file with enum-based behavior switching

---

## Execution Order

**Can Start:** After Task 4.2 (Basic Enemy AI) is functional
**Blocked by:** Task 4.2 (needs AI behaviors defined)
**Blocks:** Task 4.4 (Room Loading - needs enemy scenes to spawn)

---

## Implementation Details

**1. Create Enemy Subclasses**

```gdscript
# scripts/entities/enemies/enemy_grunt.gd
class_name EnemyGrunt
extends BaseEnemy

func _setup_entity() -> void:
    entity = Entity.new("Grunt", x, y, 30, 8, 4)
    entity.is_player = false
    entity.spd = 4

func _setup_ai() -> void:
    ai_controller.behavior = EnemyAIController.BehaviorType.GRUNT
```

```gdscript
# scripts/entities/enemies/enemy_archer.gd
class_name EnemyArcher
extends BaseEnemy

func _setup_entity() -> void:
    entity = Entity.new("Archer", x, y, 25, 6, 2)
    entity.is_player = false
    entity.spd = 5

func _setup_ai() -> void:
    ai_controller.behavior = EnemyAIController.BehaviorType.ARCHER
```

```gdscript
# scripts/entities/enemies/enemy_tank.gd
class_name EnemyTank
extends BaseEnemy

func _setup_entity() -> void:
    entity = Entity.new("Tank", x, y, 60, 15, 8)
    entity.is_player = false
    entity.spd = 2

func _setup_ai() -> void:
    ai_controller.behavior = EnemyAIController.BehaviorType.TANK
```

**2. Update AI Controller**

```gdscript
# In EnemyAIController:
func _archer_behavior(dist: int) -> Dictionary:
    if dist >= 2 and dist <= 3:
        return {"type": "attack", "target": player_entity}
    elif dist < 2:
        var away_dir := _get_move_away_from_player()
        return {"type": "move", "dx": away_dir.x, "dy": away_dir.y}
    else:
        var toward_dir := _get_move_toward_player()
        return {"type": "move", "dx": toward_dir.x, "dy": toward_dir.y}
```

### Enemy Stats

| Type | HP | OFF | DEF | SPD | Range | Behavior |
|------|----|-----|-----|-----|-------|----------|
| Grunt | 30 | 8 | 4 | 4 | Melee (1) | Rush player |
| Archer | 25 | 6 | 2 | 5 | Ranged (2-3) | Maintain distance |
| Tank | 60 | 15 | 8 | 2 | Melee (1) | Slow advance |

---

## Acceptance Criteria
- [ ] 3 enemy classes created (Grunt, Archer, Tank)
- [ ] Different stats for each type
- [ ] Different AI behaviors
- [ ] Scene files for each type
- [ ] Visual differentiation (color/size)
- [ ] Spawnable via RoomLoader
- [ ] Each type has unique tactical role
- [ ] Test file: `tests/test_enemy_variety.gd`

---

## Dependencies
- **Task 4.2** (Enemy AI) - For behavior variations
- **Task 4.4** (Room Loading) - For spawning

## Parallel Work
- **Can be done in parallel with:** Task 4.4 (Room Loading)
- **Best completed after:** Task 4.2
- **Shares files with:** Task 4.4 (enemy scenes)

---

## References
- `scripts/entities/base_enemy.gd` - Base class
- `scripts/ai/enemy_ai_controller.gd` - AI behaviors

## Notes for Jules
Create scenes with different colored rectangles for now: Grunt=white, Archer=green, Tank=blue.

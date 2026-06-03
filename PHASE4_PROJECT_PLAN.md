# Phase 4 Project Plan: Minimum Viable Gameplay

## Overview

**Timeline:** 8 weeks (sprint-based)
**Goal:** Transform Emberfall from tech demo into playable tactical combat game
**Sprint Structure:** 2-week sprints

---

## Phase 4A: Combat Core (Sprints 1-2)

**Weeks 1-3 | Priority: CRITICAL**

### Task 4.1: Combat Input System

**Duration:** 3-4 days
**Dependencies:** None (uses existing Entity + CombatFormula)

**Implementation:**

```gdscript
# scripts/combat/combat_input.gd
class_name CombatInput
extends Node

## Handles player combat input: targeting, attacking, abilities

@export var player_entity: Entity
@export var grid_system: _GridSystem
@export var combat_system: CombatSystem

var _selected_target: BaseEnemy = null
var _in_targeting_mode: bool = false
var _valid_targets: Array[BaseEnemy] = []

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("attack"):
        _enter_targeting_mode()
    elif event.is_action_pressed("confirm") and _in_targeting_mode:
        _execute_attack()
    elif event.is_action_pressed("cancel") and _in_targeting_mode:
        _exit_targeting_mode()

func _enter_targeting_mode() -> void:
    _in_targeting_mode = true
    _valid_targets = _find_valid_targets()
    _highlight_targets(_valid_targets)
    _selected_target = _get_nearest_target()
    _update_target_highlight()

func _find_valid_targets() -> Array[BaseEnemy]:
    ## Find enemies within attack range (adjacent tiles)
    var targets: Array[BaseEnemy] = []
    var enemies := get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if enemy is BaseEnemy and enemy.alive():
            var dist := _grid_distance(player_entity, enemy.entity)
            if dist <= 1:  # Melee range
                targets.append(enemy)
    return targets

func _execute_attack() -> void:
    if _selected_target == null:
        return
    
    combat_system.execute_attack(player_entity, _selected_target.entity)
    _exit_targeting_mode()
```

**Acceptance Criteria:**

- [ ] Press Space or click to enter targeting mode
- [ ] Valid targets highlighted (adjacent enemies)
- [ ] Tab or arrows to cycle targets
- [ ] Enter or click to confirm attack
- [ ] Damage dealt using CombatFormula
- [ ] Visual feedback (flash, shake)
- [ ] Escape to cancel targeting

---

### Task 4.2: Basic Enemy AI

**Duration:** 4-5 days
**Dependencies:** Task 4.1 (combat input exists)

**Implementation:**

```gdscript
# scripts/ai/enemy_ai_controller.gd
class_name EnemyAIController
extends Node

## Basic AI for enemies: move toward player, attack in range

@export var enemy_entity: Entity
@export var grid_system: _GridSystem
@export var player_entity: Entity

enum BehaviorType { GRUNT, ARCHER, TANK }
@export var behavior: BehaviorType = BehaviorType.GRUNT

func decide_action() -> Dictionary:
    var player_dist := _grid_distance(enemy_entity, player_entity)
    
    match behavior:
        BehaviorType.GRUNT:
            return _grunt_behavior(player_dist)
        BehaviorType.ARCHER:
            return _archer_behavior(player_dist)
        BehaviorType.TANK:
            return _tank_behavior(player_dist)
    
    return {"type": "wait"}

func _grunt_behavior(dist: int) -> Dictionary:
    if dist <= 1:
        return {"type": "attack", "target": player_entity}
    else:
        var move_dir := _get_move_toward_player()
        return {"type": "move", "dx": move_dir.x, "dy": move_dir.y}

func _get_move_toward_player() -> Vector2i:
    var dx := sign(player_entity.x - enemy_entity.x)
    var dy := sign(player_entity.y - enemy_entity.y)
    
    # Try direct path first
    if grid_system.can_move(enemy_entity.x, enemy_entity.y, 
                           enemy_entity.x + dx, enemy_entity.y + dy):
        return Vector2i(dx, dy)
    
    # Try alternate paths
    if dx != 0 and grid_system.can_move(enemy_entity.x, enemy_entity.y,
                                         enemy_entity.x + dx, enemy_entity.y):
        return Vector2i(dx, 0)
    
    if dy != 0 and grid_system.can_move(enemy_entity.x, enemy_entity.y,
                                         enemy_entity.x, enemy_entity.y + dy):
        return Vector2i(0, dy)
    
    return Vector2i.ZERO
```

**Acceptance Criteria:**

- [ ] Grunts move toward player when out of range
- [ ] Grunts attack when adjacent
- [ ] Archers maintain distance (2-3 tiles)
- [ ] Tanks move slowly but have high HP
- [ ] Enemies respect grid boundaries
- [ ] Enemies avoid blocked tiles
- [ ] AI runs during enemy turn

---

### Task 4.3: Turn Manager

**Duration:** 5-7 days
**Dependencies:** Tasks 4.1, 4.2

**Implementation:**

```gdscript
# scripts/combat/turn_manager.gd
class_name TurnManager
extends Node

## Manages turn order, initiative, AP economy

signal turn_started(entity: Entity, is_player: bool)
signal turn_ended(entity: Entity)
signal round_started(round_number: int)
signal combat_ended(victory: bool)

var _participants: Array[Entity] = []
var _current_index: int = 0
var _round_number: int = 0
var _combat_active: bool = false

func start_combat(player: Entity, enemies: Array[BaseEnemy]) -> void:
    _participants.clear()
    _participants.append(player)
    for enemy in enemies:
        _participants.append(enemy.entity)
    
    # Sort by SPD (descending) for initiative
    _participants.sort_custom(
        func(a: Entity, b: Entity) -> bool:
            return a.spd > b.spd
    )
    
    _current_index = 0
    _round_number = 1
    _combat_active = true
    
    round_started.emit(_round_number)
    _start_turn()

func _start_turn() -> void:
    if not _combat_active:
        return
    
    var entity := _participants[_current_index]
    
    # Reset AP at start of turn
    if entity.is_player:
        entity.ap = DeterministicMath.ap_start(entity.ap, GameConstants.AP_REGEN, GameConstants.AP_MAX)
    else:
        entity.ap = GameConstants.AP_MAX  # Enemies get full AP
    
    turn_started.emit(entity, entity.is_player)
    
    if not entity.is_player:
        # Auto-run enemy AI after delay
        await get_tree().create_timer(0.5).timeout
        _execute_enemy_turn(entity)

func _execute_enemy_turn(entity: Entity) -> void:
    var enemy := _get_enemy_node(entity)
    if enemy:
        var action := enemy.ai_controller.decide_action()
        _execute_action(entity, action)
        end_turn()

func _execute_action(entity: Entity, action: Dictionary) -> void:
    match action.get("type", ""):
        "move":
            var dx: int = action.get("dx", 0)
            var dy: int = action.get("dy", 0)
            if entity.ap >= 1:
                entity.set_grid_position(entity.x + dx, entity.y + dy)
                entity.ap -= 1
        "attack":
            var target: Entity = action.get("target")
            if entity.ap >= 2 and target != null:
                var damage := CombatFormula.compute_damage_from_entities(entity, target, [])
                EntityLifecycle.apply_damage(entity, target, damage)
                entity.ap -= 2

func end_turn() -> void:
    var entity := _participants[_current_index]
    turn_ended.emit(entity)
    
    _current_index += 1
    if _current_index >= _participants.size():
        _current_index = 0
        _round_number += 1
        round_started.emit(_round_number)
    
    _check_combat_end()
    if _combat_active:
        _start_turn()

func _check_combat_end() -> void:
    var player_alive := false
    var enemies_alive := false
    
    for entity in _participants:
        if entity.is_player and entity.alive():
            player_alive = true
        elif not entity.is_player and entity.alive():
            enemies_alive = true
    
    if not player_alive:
        _combat_active = false
        combat_ended.emit(false)  # Defeat
    elif not enemies_alive:
        _combat_active = false
        combat_ended.emit(true)  # Victory

func _get_enemy_node(entity: Entity) -> BaseEnemy:
    var enemies := get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if enemy is BaseEnemy and enemy.entity == entity:
            return enemy
    return null
```

**Acceptance Criteria:**

- [ ] Combat starts when entering room
- [ ] Turns ordered by SPD (highest first)
- [ ] Player turn: manual control (move/attack/end)
- [ ] Enemy turn: AI executes automatically
- [ ] AP consumed for actions
- [ ] AP regenerated at turn start
- [ ] Combat ends when all enemies or player defeated
- [ ] Victory/defeat signals emitted

---

## Phase 4B: Content Foundation (Sprints 3-4)

**Weeks 4-6 | Priority: HIGH**

### Task 4.4: Room Loading System

**Duration:** 4-5 days
**Dependencies:** Task 4.3 (turn manager)

**Implementation:**

```json
// config/rooms/room_standard.json
{
  "id": "room_standard_01",
  "biome": "sanctum",
  "layout": {
    "width": 12,
    "height": 12,
    "elevation": [
      [0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,1,1,0,0,1,1,0,0,0],
      [0,0,1,1,1,1,1,1,1,1,0,0],
      [0,1,1,2,2,1,1,2,2,1,1,0],
      [0,1,1,2,2,1,1,2,2,1,1,0],
      [0,0,1,1,1,1,1,1,1,1,0,0],
      [0,0,0,1,1,0,0,1,1,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0]
    ],
    "cover": [
      {"x": 3, "y": 3, "type": "heavy"},
      {"x": 8, "y": 3, "type": "heavy"},
      {"x": 5, "y": 5, "type": "light"}
    ]
  },
  "encounters": [
    {
      "enemy_type": "grunt",
      "count": 3,
      "positions": [{"x": 9, "y": 2}, {"x": 10, "y": 3}, {"x": 9, "y": 4}]
    }
  ]
}
```

**Acceptance Criteria:**

- [ ] 3-5 room JSON files created
- [ ] Room loader reads JSON and configures grid
- [ ] Elevation data applied to grid
- [ ] Cover tiles configured
- [ ] Encounter spawner places enemies
- [ ] Hooked into RunManager room flow

---

### Task 4.5: Enemy Variety

**Duration:** 3-4 days
**Dependencies:** Task 4.4 (room loading)

**Implementation:**

```gdscript
# scripts/entities/enemies/enemy_archer.gd
class_name EnemyArcher
extends BaseEnemy

func _setup_entity() -> void:
    entity = Entity.new("Archer", x, y, 25, 6, 2)
    entity.is_player = false
    entity.spd = 5

# scripts/entities/enemies/enemy_tank.gd
class_name EnemyTank
extends BaseEnemy

func _setup_entity() -> void:
    entity = Entity.new("Tank", x, y, 60, 15, 8)
    entity.is_player = false
    entity.spd = 2
```

**Acceptance Criteria:**

- [ ] 3 enemy types: Grunt, Archer, Tank
- [ ] Different stats for each type
- [ ] Different AI behaviors
- [ ] Scene files for each type
- [ ] Spawnable via room loader

---

## Phase 4C: Polish (Sprints 5-6)

**Weeks 7-8 | Priority: MEDIUM**

### Task 4.6: Combat HUD

**Duration:** 3-4 days
**Dependencies:** Task 4.3 (turn manager + AP system)

**Features:**

- HP/MP bars for player
- AP display (current/max)
- Action buttons: Move, Attack, End Turn
- Turn indicator ("Player Turn" / "Enemy Turn")
- Target info (hover enemy to see HP)

**Acceptance Criteria:**

- [ ] Player HP bar visible
- [ ] AP counter visible
- [ ] Action buttons work
- [ ] Turn indicator shows whose turn
- [ ] Enemy info on hover

---

### Task 4.7: Settings Menu

**Duration:** 2-3 days
**Dependencies:** None (UI only)

**Features:**

- Resolution settings
- Audio volume
- Key rebinding (already partially done)
- Accessibility options

**Acceptance Criteria:**

- [ ] Settings accessible from pause menu
- [ ] Settings persist between sessions
- [ ] Volume controls work
- [ ] Resolution options work

---

### Task 4.8: Moral Choice UI

**Duration:** 2-3 days
**Dependencies:** Task 4.1 (combat) + existing EntityLifecycle

**Features:**

- When enemy reaches DYING state, show choice popup
- Options: Spare (costs 1 AP, -1 moral) or Execute (free, +1 moral)
- Visual indicator of moral consequences
- Timer (enemy dies automatically after X turns if no choice)

**Acceptance Criteria:**

- [ ] Choice appears when enemy at 0 HP
- [ ] Spare button visible and functional
- [ ] Execute button visible and functional
- [ ] AP cost shown
- [ ] Moral delta preview shown
- [ ] Auto-execute after timeout

---

## Sprint Schedule

| Sprint | Weeks | Focus | Tasks |
|--------|-------|-------|-------|
| **Sprint 1** | 1-2 | Combat Core | 4.1 Combat Input, 4.2 Enemy AI |
| **Sprint 2** | 3-4 | Combat Core + Turn System | 4.3 Turn Manager |
| **Sprint 3** | 5-6 | Content Foundation | 4.4 Room Loading, 4.5 Enemy Variety |
| **Sprint 4** | 7-8 | Polish | 4.6 Combat HUD, 4.7 Settings, 4.8 Moral Choice |

---

## Definition of Done (Phase 4)

**A player can:**

1. Start a new game
2. Enter a combat room
3. See enemies and environment
4. Take turns with enemies
5. Move and attack
6. Defeat enemies or be defeated
7. Make moral choices (spare/execute)
8. See HP/AP on HUD

**This is a Minimum Viable Gameplay loop.**

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| AI pathfinding complex | Medium | High | Use GridSystem.can_move(), not A* |
| Turn system bugs | Medium | High | Extensive testing, simple state machine |
| Scope creep | High | Medium | Strict sprint boundaries |
| Performance with many enemies | Low | Medium | Grid is small (12×12) |

---

## Dependencies Summary

```
4.1 Combat Input
    |
    v
4.2 Enemy AI
    |
    v
4.3 Turn Manager
    |
    +---> 4.4 Room Loading
    |         |
    |         v
    |     4.5 Enemy Variety
    |
    +---> 4.6 Combat HUD
    |
    +---> 4.8 Moral Choice UI
```

---

*Prepared for Donchitos CEO Agent | 2026-06-03*

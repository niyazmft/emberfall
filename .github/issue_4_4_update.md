## Task 4.4: Room Loading System

**Phase:** 4B - Content Foundation
**Priority:** HIGH
**Duration:** 4-5 days
**Sprint:** Sprint 3 (Weeks 5-6)

---

## Objective
Create a room loading system that reads room definitions from JSON and configures the grid, elevation, cover, and enemy encounters.

### Current State
- Room generation is stubbed in RunManager
- Seeds are generated but no actual room layouts exist
- GridSystem can load rooms from JSON but no room JSON files exist
- CombatRoom has hardcoded enemy spawns

---

## Execution Order

**Can Start:** After Task 4.3 (Turn Manager) is functional
**Blocked by:** Task 4.3 (needs combat loop working first)
**Blocks:** None (content task, doesn't block others)

---

## Implementation Details

**1. Create Room JSON Files**

```json
// config/rooms/room_standard_01.json
{
  "id": "room_standard_01",
  "biome": "sanctum",
  "size": {"width": 12, "height": 12},
  "layout": {
    "elevation": [...],
    "cover": [...],
    "blocked": [...]
  },
  "encounters": [
    {
      "enemy_type": "grunt",
      "count": 3,
      "positions": [...]
    }
  ],
  "player_start": {"x": 1, "y": 1}
}
```

**2. Create Room Loader**

```gdscript
# scripts/combat/room_loader.gd
class_name RoomLoader
extends Node

const ROOMS_PATH := "res://config/rooms/"

func load_room(room_id: String) -> Dictionary:
    var path := ROOMS_PATH + room_id + ".json"
    # Read and parse JSON
    return json.data

func configure_grid(room_data: Dictionary) -> void:
    GridSystem.load_room(room_data)

func spawn_encounters(room_data: Dictionary, entity_container: Node) -> void:
    # Spawn enemies at defined positions
```

**3. Hook into RunManager**

```gdscript
# In RunManager._enter_room():
func _enter_room(_ctx: Dictionary) -> void:
    var room_data := _get_current_room_data()
    var room_id: String = room_data.get("room_id", "room_standard_01")
    var room_def := RoomLoader.load_room(room_id)
    
    if not room_def.is_empty():
        RoomLoader.configure_grid(room_def)
        RoomLoader.spawn_encounters(room_def, _entity_container)
        _spawn_player(room_def.get("player_start", {"x": 1, "y": 1}))
```

---

## Acceptance Criteria
- [ ] 3-5 room JSON files created
- [ ] Room loader reads and parses JSON
- [ ] Grid configured from room definition (elevation, cover, blocked)
- [ ] Enemies spawned at defined positions
- [ ] Player spawned at defined start position
- [ ] Rooms have different layouts
- [ ] Rooms have different enemy encounters
- [ ] Hooked into RunManager room flow
- [ ] Test file: `tests/test_room_loader.gd`

---

## Dependencies
- **Task 4.3** (Turn Manager) - Good to have combat first
- **Task 4.5** (Enemy Variety) - For different enemy types in rooms
- **Uses existing:** GridSystem.load_room(), BaseEnemy scenes

## Parallel Work
- **Can be done in parallel with:** Task 4.5 (Enemy Variety)
- **Best completed after:** Task 4.3
- **Shares files with:** Task 4.5 (enemy scenes)

---

## References
- `scripts/autoload/grid_system.gd` - Grid configuration
- `scripts/state_machine/run_manager.gd` - Room flow
- `scripts/entities/base_enemy.gd` - Enemy spawning

## Notes for Jules
Create 3-5 simple room layouts first. Focus on different elevation and cover configurations.

## Task 4.8: Moral Choice UI

**Phase:** 4C - Polish
**Priority:** MEDIUM
**Duration:** 2-3 days
**Sprint:** Sprint 5 (Weeks 7-8)

---

## Objective
Create the UI for moral choices (spare vs execute) when an enemy reaches the DYING state.

### Current State
- EntityLifecycle has `spare_entity()` and `execute_entity()` methods
- Moral delta system works (queued and processed)
- Burden system tracks kills
- **NO UI exists** - Choices are invisible to player

---

## Execution Order

**Can Start:** After Task 4.3 (Turn Manager) is functional
**Blocked by:** Task 4.3 (needs turn flow), Task 4.1 (needs combat to reach DYING state)
**Blocks:** None (UI only)

---

## Implementation Details

**1. Choice Popup**

```gdscript
# scripts/ui/moral_choice_ui.gd
class_name MoralChoiceUI
extends CanvasLayer

signal choice_made(spared: bool)

@onready var panel: PanelContainer = %ChoicePanel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var spare_button: Button = %SpareButton
@onready var execute_button: Button = %ExecuteButton
@onready var timeout_bar: ProgressBar = %TimeoutBar
@onready var moral_preview: Label = %MoralPreview

var _target_entity: Entity = null
var _timeout: float = 5.0
var _remaining: float = 0.0
```

**2. Show Choice**

```gdscript
func show_choice(enemy: Entity) -> void:
    _target_entity = enemy
    panel.visible = true
    
    enemy_name_label.text = "%s is dying..." % enemy.entity_name
    moral_preview.text = "Spare: -1 | Execute: +1"
    
    spare_button.text = "Spare (Cost: 1 AP)"
    execute_button.text = "Execute"
    
    _remaining = _timeout
    timeout_bar.max_value = _timeout
    timeout_bar.value = _timeout
```

**3. Handle Choices**

```gdscript
func _on_spare_pressed() -> void:
    var player := _get_player_entity()
    if player and player.ap >= 1:
        EntityLifecycle.spare_entity(player, _target_entity)
        choice_made.emit(true)
        _hide_choice()

func _on_execute_pressed() -> void:
    EntityLifecycle.execute_entity(_target_entity)
    choice_made.emit(false)
    _hide_choice()

func _auto_execute() -> void:
    if _target_entity and _target_entity.state == Entity.State.DYING:
        EntityLifecycle.execute_entity(_target_entity)
        choice_made.emit(false)
        _hide_choice()
```

---

## Acceptance Criteria
- [ ] Choice appears when enemy reaches 0 HP
- [ ] Shows enemy name
- [ ] Shows moral consequences
- [ ] Spare button visible (disabled if no AP)
- [ ] Execute button visible
- [ ] 5-second timeout with progress bar
- [ ] Auto-executes if no choice made
- [ ] Spare: Consumes 1 AP, -1 moral, enemy becomes GHOST
- [ ] Execute: Free, +1 moral, enemy becomes DEAD
- [ ] Visual feedback on choice
- [ ] Test file: `tests/test_moral_choice_ui.gd`

---

## Dependencies
- **Task 4.1** (Combat Input) - For triggering DYING state
- **Task 4.3** (Turn Manager) - For turn flow
- **Uses existing:** EntityLifecycle.spare_entity/execute_entity

## Parallel Work
- **Can be done in parallel with:** Tasks 4.6, 4.7
- **Best completed after:** Task 4.3
- **Shares no critical files with:** Tasks 4.6, 4.7

---

## References
- `scripts/entities/entity_lifecycle.gd` - Spare/execute logic
- `scripts/entities/entity.gd` - Entity states

## Notes for Jules
This is UI-only work. Hook into entity state changes. Timeout prevents soft-locking.

## Task 4.6: Combat HUD

**Phase:** 4C - Polish
**Priority:** MEDIUM
**Duration:** 3-4 days
**Sprint:** Sprint 5 (Weeks 7-8)

---

## Objective
Create a functional combat HUD that displays HP, AP, turn information, and action buttons.

### Current State
- CombatHUD scene exists but is not functional
- No HP/AP display during combat
- No action buttons visible
- No turn indicator

---

## Execution Order

**Can Start:** After Task 4.3 (Turn Manager) is functional
**Blocked by:** Task 4.3 (needs turn state), Task 4.1 (needs attack action)
**Blocks:** None (UI only)

---

## Implementation Details

**1. HP/AP Display**

```gdscript
# scripts/ui/combat_hud.gd (update existing)
@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var ap_bar: ProgressBar = %APBar
@onready var ap_label: Label = %APLabel

func update_player_stats(entity: Entity) -> void:
    hp_bar.max_value = entity.hp_max
    hp_bar.value = entity.hp
    hp_label.text = "%d / %d" % [entity.hp, entity.hp_max]
    
    ap_bar.max_value = GameConstants.AP_MAX
    ap_bar.value = entity.ap
    ap_label.text = "%d / %d" % [entity.ap, GameConstants.AP_MAX]
```

**2. Action Buttons**

```gdscript
@onready var move_button: Button = %MoveButton
@onready var attack_button: Button = %AttackButton
@onready var end_turn_button: Button = %EndTurnButton

func _on_attack_pressed() -> void:
    combat_input._enter_targeting_mode()

func _on_end_turn_pressed() -> void:
    turn_manager.end_turn()
```

**3. Turn Indicator**

```gdscript
@onready var turn_label: Label = %TurnLabel
@onready var round_label: Label = %RoundLabel

func show_player_turn() -> void:
    turn_label.text = "Your Turn"
    turn_label.modulate = Color.GREEN
    enable_action_buttons()

func show_enemy_turn() -> void:
    turn_label.text = "Enemy Turn"
    turn_label.modulate = Color.RED
    disable_action_buttons()
```

---

## Acceptance Criteria
- [ ] HP bar shows current/max HP
- [ ] AP bar shows current/max AP
- [ ] Action buttons visible and functional
- [ ] Turn indicator shows whose turn
- [ ] Round counter visible
- [ ] Target info appears on hover
- [ ] Combat log shows actions
- [ ] Disabled state when not player's turn
- [ ] Updates dynamically during combat
- [ ] Test file: `tests/test_combat_hud.gd`

---

## Dependencies
- **Task 4.1** (Combat Input) - For attack button
- **Task 4.3** (Turn Manager) - For turn display
- **Uses existing:** CombatHUD scene

## Parallel Work
- **Can be done in parallel with:** Tasks 4.7, 4.8
- **Best completed after:** Task 4.3
- **Shares no critical files with:** Tasks 4.7, 4.8

---

## References
- `scripts/ui/combat_hud.gd` - Current implementation
- `scripts/combat/turn_manager.gd` - Turn signals
- `scripts/combat/combat_input.gd` - Input actions

## Notes for Jules
This is UI-only work. Focus on layout and signals. No game logic changes needed.

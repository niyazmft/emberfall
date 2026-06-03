## Task 4.7: Settings Menu

**Phase:** 4C - Polish
**Priority:** MEDIUM
**Duration:** 2-3 days
**Sprint:** Sprint 5 (Weeks 7-8)

---

## Objective
Make the Settings menu functional with resolution, audio, and key binding options.

### Current State
- Settings menu scene exists (`scenes/ui/settings_menu.tscn`)
- Settings button on title screen does nothing
- SettingsManager autoload exists but is basic
- No actual settings are persisted or applied

---

## Execution Order

**Can Start:** Immediately
**Blocked by:** Nothing (UI only, independent of combat)
**Blocks:** None

---

## Implementation Details

**1. Settings Categories**

```gdscript
# scripts/autoload/settings_manager.gd (update)
enum SettingCategory {
    DISPLAY,
    AUDIO,
    INPUT,
    ACCESSIBILITY
}
```

**2. Display Settings**
- Resolution dropdown (1920x1080, 1600x900, 1280x720)
- Fullscreen toggle
- VSync toggle
- Apply button (requires restart)

**3. Audio Settings**
- Master volume slider (0-100%)
- Music volume slider
- SFX volume slider
- Mute toggle

**4. Input Settings**
- Show current key bindings
- Click to rebind (capture next keypress)
- Reset to defaults button

**5. Settings Persistence**
```gdscript
func save_settings() -> void:
    var file := FileAccess.open("user://settings.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(_settings))
        file.close()
```

---

## Acceptance Criteria
- [ ] Settings accessible from title screen
- [ ] Settings accessible from pause menu
- [ ] Resolution options work
- [ ] Fullscreen toggle works
- [ ] Volume sliders work
- [ ] Key rebinding works
- [ ] Settings persist between sessions
- [ ] Reset to defaults works
- [ ] Apply button confirms changes
- [ ] Back button returns to previous screen
- [ ] Test file: `tests/test_settings_menu.gd`

---

## Dependencies
- **None** - UI only, independent of combat

## Parallel Work
- **Can be done in parallel with:** Tasks 4.6, 4.8
- **Best completed:** Anytime (no dependencies)
- **Shares no files with:** Combat tasks

---

## References
- `scripts/autoload/settings_manager.gd` - Current implementation
- `scripts/ui/settings_menu.gd` - Menu script
- `scenes/ui/settings_menu.tscn` - Menu scene

## Notes for Jules
This is UI-only work. Can be done at any time. Focus on user:// persistence for settings.

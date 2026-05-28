# DON-222: MWT Caption Matrix and Phase A Caption

## Implementation Overview

This deliverable implements the state and transition caption matrix for the Memory Weight Threshold (MWT) system and the Phase A caption for Burden Events, as required by DON-222.

### MWT Caption Matrix

The `MWTCaptionMatrix` (implemented in `ui/framework/mwt_caption_matrix.gd` and integrated into `BurdenManager`) manages captions for MWT levels 0-3:

- **MWT 0:** [A low rumble spreads beneath you]
- **MWT 1:** [Machinery churns in the walls]
- **MWT 2:** [Pressure builds]
- **MWT 3:** [The breaking point nears]

Seven transitions are also implemented (0→1, 1→2, 2→3, 3→2, 2→1, 1→0, and 3→0).

### Phase A Caption

A Phase A caption "[The world stills]" fires at the exact moment a Burden Event seizes control (10s lock), ensuring accessibility in no-audio scenarios.

### BURDEN Caption Channel

A dedicated `BURDEN` caption channel has been implemented in `CaptionManager` and `SubtitleManager`. This channel uses an isolated display surface, ensuring that Burden-related captions do not overwrite or interfere with combat-critical dialogue.

### Numbness Cap Caption

When the `numbness_cap_reached` flag is true, a special "[The burden is silent]" caption is triggered.

## Files Added/Modified

- `ui/framework/mwt_caption_entry.gd` (Added)
- `ui/framework/mwt_caption_matrix.gd` (Added)
- `ui/modals/burden_event_player.gd` (Added)
- `ui/modals/burden_event_player.tscn` (Added)
- `ui/framework/subtitle_manager.gd` (Added)
- `ui/dev/debug_menu_overlay.gd` (Added)
- `scripts/autoload/burden_manager.gd` (Modified)
- `localization/ui_strings.csv` (Added)

## Verification

- Automated tests in `tests/test_caption_system.gd` verify caption scheduling and isolation.
- Manual verification can be performed using the `DebugMenuOverlay` (F1/F2 to change moral weight, F3 to trigger Burden Event).

# Progress

## Status

In Progress

## Tasks

- Fix #288 — Title Screen "New Game" must reliably transition to CombatRoom

## Files Changed

- scripts/ui/title_screen.gd
- scripts/autoload/game_coordinator.gd

## Notes

- Added `_is_changing_scene` guard in GameCoordinator to prevent concurrent/re-entrant scene changes
- Added toast fallback in TitleScreen when GameCoordinator is null
- Hardened `_change_scene` with typed TransitionLayer reference, null guards on SceneTree, and toast on scene-change error
- Ensured fade_out/fade_in always pair even when change_scene_to_file fails
- Godot headless editor scan passed with zero parse/type errors

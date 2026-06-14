import json

# Priority: P0=79628723, P1=0a877460, P2=da944a9c
# Size: XS=6c6483d2, S=f784b110, M=7515a9f1, L=817d0097, XL=db339eb2
# Status: Backlog=f75ad846, Ready=61e4505c, In progress=47fc9ee4, In review=df73e18b, Done=98236657

metadata = {
    288: {"priority": "P0", "size": "S", "status": "Ready", "title": "[Playability] Title Screen → CombatRoom scene flow"},
    289: {"priority": "P0", "size": "XS", "status": "Ready", "title": "[Playability] Enable Continue button on Title Screen"},
    290: {"priority": "P1", "size": "S", "status": "Ready", "title": "[Infrastructure] Create missing config placeholder files"},
    291: {"priority": "P1", "size": "XS", "status": "Ready", "title": "[Playability] Remove orphaned MainMenu scene"},
    292: {"priority": "P1", "size": "XS", "status": "Ready", "title": "[Infrastructure] Bump project version to 0.1.2"},
    293: {"priority": "P0", "size": "S", "status": "Done", "title": "fix(playability): resolve critical path issues #288, #289, #291, #292"},
    294: {"priority": "P1", "size": "L", "status": "Ready", "title": "[Story] Populate missing room JSONs (18 files to reach 12 per biome)"},
    295: {"priority": "P2", "size": "L", "status": "Ready", "title": "[Story] Expand narrative data: ambient narrator, biome echoes, moral outcomes"},
    296: {"priority": "P1", "size": "S", "status": "Ready", "title": "[Story] Populate boss room encounter data (boss_overgrown_guardian.json)"},
    297: {"priority": "P2", "size": "M", "status": "Ready", "title": "[Story] Replace placeholder economy data with tuned rewards and unlock tables"},
    298: {"priority": "P2", "size": "L", "status": "Ready", "title": "[Story] Localization expansion: add second locale (CJK or Spanish)"},
    299: {"priority": "P1", "size": "S", "status": "Ready", "title": "[Creative Assets] Polish EntityStatusBar Visuals and Add HP/AP Tween Animations"},
    300: {"priority": "P0", "size": "S", "status": "Ready", "title": "[Creative Assets] Add Scene Transition CanvasLayer for Victory / Defeat / Title → Combat Flow"},
    301: {"priority": "P0", "size": "S", "status": "Ready", "title": "[Creative Assets] Wire EntityVisualProxy Hit Effects to EntityLifecycle Damage Pipeline"},
    302: {"priority": "P0", "size": "XS", "status": "Ready", "title": "[Creative Assets] Create Asset Directory Structure and Placeholder Media for Demo"},
    303: {"priority": "P1", "size": "XS", "status": "Ready", "title": "[Creative Assets] Wire TurnBanner Scene into CombatRoom UIOverlay and Verify EventBus Signals"},
    304: {"priority": "P0", "size": "S", "status": "Ready", "title": "[Creative Assets] Add SFX Playback Nodes to CombatRoom and Wire to EntityLifecycle Events"},
    305: {"priority": "P1", "size": "S", "status": "Ready", "title": "[Creative Assets] Polish VictoryModal and DefeatModal with Fade-In and Theming"},
    306: {"priority": "P1", "size": "XS", "status": "Ready", "title": "[Creative Assets] Fix Damage Number Z-Sorting by Spawning in EntityContainer"},
    307: {"priority": "P2", "size": "XS", "status": "Ready", "title": "[Infrastructure] Project version still shows 0.1.0-sprint1 in version_label.gd"},
    308: {"priority": "P1", "size": "S", "status": "Ready", "title": "[Bug] CombatRoom._input() intercepts UI input — should use _unhandled_input()"},
    309: {"priority": "P1", "size": "S", "status": "Ready", "title": "[Bug] AStarGrid uses raw get_node('GridSystem') instead of AutoloadHelper"},
    310: {"priority": "P1", "size": "XS", "status": "Done", "title": "[Bug] RunManager uses raw get_node for EntityLifecycle"},
    311: {"priority": "P1", "size": "M", "status": "Ready", "title": "[Bug] Replace .call() / has_method() anti-pattern with typed interfaces"},
    312: {"priority": "P1", "size": "XS", "status": "Ready", "title": "[Bug] EntityVisualProxy uses get_node instead of @onready for ApparitionRenderer"},
    313: {"priority": "P1", "size": "S", "status": "Ready", "title": "[Bug] LevelUpManager evaluates formulas without whitelist validation"},
    314: {"priority": "P2", "size": "L", "status": "Backlog", "title": "[Bug] Add unit tests for SaveManager, GridSystem, BurdenManager, Audio Middleware"},
    315: {"priority": "P2", "size": "S", "status": "Ready", "title": "[Bug] FocusManager polls _process every frame instead of using signals"},
    316: {"priority": "P2", "size": "S", "status": "Ready", "title": "[Bug] BaseEnemy syncs apparition position every frame even when stationary"},
    317: {"priority": "P2", "size": "S", "status": "Ready", "title": "[Bug] EntityVisualProxy loads status bar scene at runtime with load()"}
}

with open("issue_metadata.json", "w") as f:
    json.dump(metadata, f, indent=4)

print("Generated issue_metadata.json")

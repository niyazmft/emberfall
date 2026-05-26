# Shader Budget Report — DON-52 / DON-253 Rework

Generated: 2026-05-25
Agent: Godot Shader Specialist

## New / Rewritten Shaders

| Shader | ALU | Tex | Uni | If | Discard | Tier | Verdict |
|---|---|---|---|---|---|---|---|
| `pp_colour_grade_blend.gdshader` | 14 | 2 | 5 | 0 | 0 | medium | ✅ Pass |
| `pp_chromatic_aberration.gdshader` | 18 | 3 | 6 | 1 | 0 | medium | ✅ Pass |
| `pp_vignette_dynamic.gdshader` | 12 | 1 | 6 | 1 | 0 | low | ✅ Pass |
| `lightmap_microshade.gdshader` | 16 | 2 | 5 | 0 | 1 | medium | ✅ Pass |

**Notes**
- `pp_colour_grade_blend` uses two `sampler3D` lookups per fragment; 3D textures are ~143 KB each (33³ RGBA8), well within VRAM budget.
- `pp_chromatic_aberration` branch on `ca_edge_falloff` is uniform-driven and shader compilers will likely flatten.
- `pp_vignette_dynamic` branch on `burden_active` is uniform-driven; breathing math is trivial (two `sin` calls).
- All shaders declare `render_mode unshaded` explicitly and use `group_uniforms` for inspector cleanliness.
- All shaders include header comments with purpose, author, tier, platforms, and DON references.

## Pipeline Tools

| Tool | Status |
|---|---|
| `tools/export_sprites.py` | ✅ Rewritten — emits `pivotX`, `pivotY`, `states` array per Character Sprite Spec §5 |
| `tools/export_tileset.py` | ✅ Rewritten — emits 5 collision bytes (`0` walkable … `4` cover) per Environment Tileset Spec §6 |

## Legacy / Not in Scope
- `burden_event*.glsl`, `card_tactile.glsl`, `tile_highlight.glsl`, `screen_state.glsl` — retained from TA workspace but not in Emberfall project repo. Per DON-254 Item 8 these are out-of-scope for DON-52 and should be tracked under DON-56.

## Next Action
Ready for Art Director visual review and Technical Director low-tier sign-off on the 4 rewritten shaders.

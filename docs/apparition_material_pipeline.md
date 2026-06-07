# Apparition Material Pipeline (DON-267)

## Art Targets

| Layer | Target Color | Blend Mode | Intensity | EPT Slot |
| :--- | :--- | :--- | :--- | :--- |
| Spectral cool tint | #2A6F6F | Screen | 40 % | Sorrow Teal (05) |
| Inner edge bleed | #9A8C98 | Add | 15 % | Worn Silver (02) |
| After-image trail | #C9ADA7 | Multiply inverse | 20 % | Memory Ember (03) |

## Shader Mapping (`apparition_composite.gdshader`)

1. **Desaturation**: Fixed 20% chroma preservation.
2. **Spectral Tint**: `u_spectral_tint_color` (#2A6F6F) blended via `screen_blend` at `u_spectral_tint_opacity` (0.4).
3. **Inner Bleed**: `u_inner_bleed_color` (#9A8C98) added at `u_inner_bleed_opacity` (0.15).
4. **After-image Trail**: `u_after_trail_color` (#C9ADA7) applied via inverse multiplication at `u_after_trail_opacity` (0.2).
5. **Dissolve**: `u_dissolve_threshold` drives the alpha discard based on a noise texture.
6. **Shear**: `u_shear_intensity` mutates the vertex positions for recoil.

## Tier Variants

- **Standard (Low ≤720p)**: Default mix, 9 sprites max.
- **EXACT_TINT (Desktop >720p)**: High-fidelity color matching.

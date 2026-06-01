# Integration Notes for Animation Lead (DON-267)

## Sprite Capture Policy
- Silhouettes are captured from the `SentientEntity` sprite sheet at the moment of death.
- Capture should use the "Death A" frame unless specified otherwise.

## Animation Timing
- **Manifestation**: 300ms fade-in.
- **Breathing**: Continuous loop, 2.734 Hz.
- **Recoil**: 150ms duration, triggered on Keeper hit.
- **Absolve (Dissolve)**: 400ms duration, starts when `burden_active` becomes false.

## Z-Index Contract
- Default: `Keeper.z_index - 1`.
- Recoil: `Keeper.z_index + 2` (promoted to appear in front of the Keeper during hit-stop).

## Performance Budget
- 9 sprites max (3 stack + 6 trail).
- Target: 0.18ms total on Mali-G57.

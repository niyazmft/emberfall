# Apparition Composite Rig Specification (DON-267)

## Overview
The Apparition Composite Rig is a runtime-generated sprite stack that follows the Keeper during Burden Events (MWT-3). It visualizes the "weight" of past actions by displaying silhouettes of the last 3 sentient kills.

## Component Stack
The rig consists of 9 potential sprites:
- **3 Primary Stack Sprites**: The silhouettes of the last 3 kills.
- **6 After-image Trail Sprites**: Dynamic trail generated during movement.

### Primary Stack Layout
| Index | Offset (px) | Opacity | Scale |
| :--- | :--- | :--- | :--- |
| 0 (Front) | +0 | 55% | 1.00 |
| 1 (Mid) | +8 | 45% | 0.95 |
| 2 (Back) | +16 | 35% | 0.90 |

## Visual Effects
- **Breathing**: Slow sine wave oscillation (0.92 - 1.08 intensity) with a frequency of 2.734 Hz.
- **Recoil Shear**: Horizontal shearing effect applied when the Keeper takes damage, flipping towards the source.
- **Absolve Dissolve**: Procedural dissolve effect when the Burden Event ends.
- **Spectral Tint**: Uniform cool tint applied across the stack.

## Configuration
Controlled via `char_apparition_rig.json`.

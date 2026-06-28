# GenAI Asset Prompts for Emberfall

**Project:** Emberfall Tactical Combat Game
**Style:** Bold, stylized dark fantasy (Hades / League of Legends inspired)
**Core Aesthetic:** Clean shapes, readable silhouettes, vibrant curated HSL color palettes, dark backgrounds with strong rim lighting, semi-realistic proportions with stylized exaggeration
**Tech Spec:** Transparent PNG background, sRGB color space
**Output Size:** Specified per asset type below

---

## Table of Contents

1. [Character & Enemy Sprites (Isometric)](#1-character--enemy-sprites-isometric)
2. [UI Icons — General Combat Actions](#2-ui-icons--general-combat-actions)
3. [UI Icons — Bespoke Abilities](#3-ui-icons--bespoke-abilities)
4. [Environmental Props](#4-environmental-props)
5. [Shadow Texture](#5-shadow-texture)

---

## 1. Character & Enemy Sprites (Isometric)

**Style Direction:** Isometric ¾ angle (camera from above and to the side, approximately 45° elevated). The character faces slightly toward the camera's right, showing both front and top surfaces. Clean bold shapes, strong rim lighting from upper left, deep shadows on lower right. Stylized proportions — slightly exaggerated shoulders, clean flowing lines. Dark fantasy aesthetic with vibrant accent colors (ember gold, deep crimson, arcane cyan). Reference existing concept art files (`keeper_concept.png`, `grunt_concept.png`, etc.) for character identity.

**Technical:** 256×256 px, transparent PNG background, isometric ¾ perspective

---

### 1.1 — Keeper (Player Character)

**Asset ID:** `keeper_sprite`
**Size:** 256×256 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy character sprite, isometric ¾ angle, a lone cloaked Keeper warrior, tattered dark cloak with ember-gold inner lining, holding a crystalline blade, glowing amber eyes visible under hood, clean bold shapes, strong rim lighting from upper left, deep shadows, vibrant HSL color palette, dark fantasy aesthetic, transparent background, game asset, high contrast silhouette, League of Legends inspired art style

---

### 1.2 — Grunt (Basic Melee Enemy)

**Asset ID:** `grunt_sprite`
**Size:** 256×256 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy enemy sprite, isometric ¾ angle, hulking brute grunt warrior, crude iron armor with rusted shoulder plates, oversized crude cleaver, hunched aggressive posture, glowing dim red eyes, clean bold shapes, strong rim lighting, deep shadows, muted rusty color palette with red accents, dark fantasy aesthetic, transparent background, game asset, high contrast silhouette, League of Legends inspired art style

---

### 1.3 — Archer (Ranged Enemy)

**Asset ID:** `archer_sprite`
**Size:** 256×256 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy enemy sprite, isometric ¾ angle, slender agile archer, dark leather armor with green vine accents, poised with bow drawn, arrow nocked with glowing tip, hood masking face, clean bold shapes, strong rim lighting, deep shadows, muted green and brown palette with glowing arrow accent, dark fantasy aesthetic, transparent background, game asset, high contrast silhouette, League of Legends inspired art style

---

### 1.4 — Tank (Heavy Armored Enemy)

**Asset ID:** `tank_sprite`
**Size:** 256×256 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy enemy sprite, isometric ¾ angle, heavily armored tank knight, massive dark plate armor with spiked shoulders, tower shield and morning star, slow imposing stance, visor glowing with pale blue light, clean bold shapes, strong rim lighting, deep shadows, steel blue and dark iron palette, dark fantasy aesthetic, transparent background, game asset, high contrast silhouette, League of Legends inspired art style

---

### 1.5 — Mage (Spellcaster Enemy)

**Asset ID:** `mage_sprite`
**Size:** 256×256 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy enemy sprite, isometric ¾ angle, robed spellcaster mage, flowing dark purple robes with arcane runes, floating crystal orb in raised hand, eyes glowing with violet energy, ethereal wisps surrounding body, clean bold shapes, strong rim lighting, deep shadows, deep purple and violet palette with cyan arcane glow, dark fantasy aesthetic, transparent background, game asset, high contrast silhouette, League of Legends inspired art style

---

### 1.6 — Boss (Overgrown Guardian)

**Asset ID:** `overgrown_guardian_sprite`
**Size:** 320×320 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy boss sprite, isometric ¾ angle, massive overgrown guardian, ancient stone body covered in glowing moss and roots, single large crystalline eye, overgrown limbs like tree trunks, nature reclaiming ancient architecture aesthetic, clean bold shapes, strong rim lighting, deep shadows, moss green and stone gray palette with bright cyan core glow, dark fantasy aesthetic, transparent background, game asset, high contrast silhouette, League of Legends inspired art style

---

### 1.7 — Boss (Crystal Sentinel)

**Asset ID:** `crystal_sentinel_sprite`
**Size:** 320×320 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy boss sprite, isometric ¾ angle, towering crystal sentinel, body made of sharp angular translucent crystals, internal glowing core visible through chest cavity, floating crystal shards orbiting body, prismatic light refractions, clean bold shapes, strong rim lighting, deep shadows, deep blue and violet crystal palette with bright white core glow, dark fantasy aesthetic, transparent background, game asset, high contrast silhouette, League of Legends inspired art style

---

### 1.8 — Boss (Industrial Overseer)

**Asset ID:** `industrial_overseer_sprite`
**Size:** 320×320 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy boss sprite, isometric ¾ angle, hulking industrial overseer, rusted iron and brass mechanical body, smoke stacks venting black smoke, glowing furnace heart, chains and pistons visible, steampunk-dieselpunk hybrid aesthetic, clean bold shapes, strong rim lighting, deep shadows, rust orange and iron gray palette with bright orange furnace glow, dark fantasy aesthetic, transparent background, game asset, high contrast silhouette, League of Legends inspired art style

---

### 1.9 — Boss (Base Boss)

**Asset ID:** `boss_sprite`
**Size:** 320×320 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy boss sprite, isometric ¾ angle, imposing dark lord figure, ornate black armor with ember-gold trim, crown of broken crystals, massive two-handed sword, cape flowing with ember particles, clean bold shapes, strong rim lighting, deep shadows, black and ember gold palette with red eye glow, dark fantasy aesthetic, transparent background, game asset, high contrast silhouette, League of Legends inspired art style

---

## 2. UI Icons — General Combat Actions

**Style Direction:** Flat vector icon style, clean geometric shapes, high readability at small sizes. `voxy/at-icons` design system influence — simple silhouettes, minimal detail, immediate cognitive recognition. Dark background with bright accent colors.

**Technical:** 64×64 px, transparent PNG background, flat vector style

---

### 2.1 — Move Icon (3 states)

**Asset ID:** `icon_move`
**Size:** 64×64 px per state
**Format:** PNG (transparent)
**States:** Normal, Hover, Disabled

**Prompt — Normal:**
> Flat vector game UI icon, 64×64, simple geometric arrow pointing right with motion lines, clean minimal design, ember gold color on dark background, transparent background, flat vector style, high readability, immediate recognition, voxy/at-icons design system inspired

**Prompt — Hover:**
> Flat vector game UI icon, 64×64, simple geometric arrow pointing right with motion lines, clean minimal design, bright ember gold color with white glow highlight, transparent background, flat vector style, high readability, immediate recognition, voxy/at-icons design system inspired

**Prompt — Disabled:**
> Flat vector game UI icon, 64×64, simple geometric arrow pointing right with motion lines, clean minimal design, desaturated dark gray with muted brown overlay, transparent background, flat vector style, high readability, immediate recognition, voxy/at-icons design system inspired

---

### 2.2 — Attack Icon (3 states)

**Asset ID:** `icon_attack`
**Size:** 64×64 px per state
**Format:** PNG (transparent)
**States:** Normal, Hover, Disabled

**Prompt — Normal:**
> Flat vector game UI icon, 64×64, simple geometric crossed swords or blade slash, clean minimal design, deep crimson red color on dark background, transparent background, flat vector style, high readability, immediate recognition, voxy/at-icons design system inspired

**Prompt — Hover:**
> Flat vector game UI icon, 64×64, simple geometric crossed swords or blade slash, clean minimal design, bright crimson red color with white glow highlight, transparent background, flat vector style, high readability, immediate recognition, voxy/at-icons design system inspired

**Prompt — Disabled:**
> Flat vector game UI icon, 64×64, simple geometric crossed swords or blade slash, clean minimal design, desaturated dark gray with muted red overlay, transparent background, flat vector style, high readability, immediate recognition, voxy/at-icons design system inspired

---

### 2.3 — End Turn Icon (3 states)

**Asset ID:** `icon_end_turn`
**Size:** 64×64 px per state
**Format:** PNG (transparent)
**States:** Normal, Hover, Disabled

**Prompt — Normal:**
> Flat vector game UI icon, 64×64, simple geometric flag or hourglass symbol, clean minimal design, cool cyan-blue color on dark background, transparent background, flat vector style, high readability, immediate recognition, voxy/at-icons design system inspired

**Prompt — Hover:**
> Flat vector game UI icon, 64×64, simple geometric flag or hourglass symbol, clean minimal design, bright cyan-blue color with white glow highlight, transparent background, flat vector style, high readability, immediate recognition, voxy/at-icons design system inspired

**Prompt — Disabled:**
> Flat vector game UI icon, 64×64, simple geometric flag or hourglass symbol, clean minimal design, desaturated dark gray with muted blue overlay, transparent background, flat vector style, high readability, immediate recognition, voxy/at-icons design system inspired

---

## 3. UI Icons — Bespoke Abilities

**Style Direction:** Dark fantasy vector illustrations, more detailed than general icons but still readable at 64×64. Intricate dark fantasy motifs, vibrant HSL color palettes, smooth gradients, glowing magical effects. Each icon tells a story about the ability.

**Technical:** 64×64 px, transparent PNG background, dark fantasy vector illustration

---

### 3.1 — Strike Ability Icon (3 states)

**Asset ID:** `icon_strike`
**Size:** 64×64 px per state
**Format:** PNG (transparent)
**States:** Normal, Hover, Disabled

**Prompt — Normal:**
> Dark fantasy vector game ability icon, 64×64, flaming sword strike, blade wreathed in ember flames, dynamic diagonal slash pose, intricate dark fantasy motifs, vibrant HSL color palette with ember gold and deep crimson, smooth gradients, glowing magical effects, transparent background, high readability at small size, League of Legends ability icon style

**Prompt — Hover:**
> Dark fantasy vector game ability icon, 64×64, flaming sword strike, blade wreathed in bright ember flames with white-hot core, dynamic diagonal slash pose, intricate dark fantasy motifs, vibrant HSL color palette with bright ember gold and crimson, smooth gradients, intense glowing magical effects, transparent background, high readability at small size, League of Legends ability icon style

**Prompt — Disabled:**
> Dark fantasy vector game ability icon, 64×64, flaming sword strike, blade wreathed in dim ember flames, dynamic diagonal slash pose, intricate dark fantasy motifs, desaturated dark gray with muted ember overlay, smooth gradients, dimmed magical effects, transparent background, high readability at small size, League of Legends ability icon style

---

### 3.2 — Ember Ability Icon (3 states)

**Asset ID:** `icon_ember`
**Size:** 64×64 px per state
**Format:** PNG (transparent)
**States:** Normal, Hover, Disabled

**Prompt — Normal:**
> Dark fantasy vector game ability icon, 64×64, floating ember crystal, swirling fire motes and sparks, intricate dark fantasy motifs, vibrant HSL color palette with ember gold and deep orange, smooth gradients, glowing magical effects, transparent background, high readability at small size, League of Legends ability icon style

**Prompt — Hover:**
> Dark fantasy vector game ability icon, 64×64, floating ember crystal, swirling bright fire motes and sparks, intricate dark fantasy motifs, vibrant HSL color palette with bright ember gold and orange, smooth gradients, intense glowing magical effects, transparent background, high readability at small size, League of Legends ability icon style

**Prompt — Disabled:**
> Dark fantasy vector game ability icon, 64×64, floating ember crystal, dim fire motes and sparks, intricate dark fantasy motifs, desaturated dark gray with muted ember overlay, smooth gradients, dimmed magical effects, transparent background, high readability at small size, League of Legends ability icon style

---

### 3.3 — Quick Dash Ability Icon (3 states)

**Asset ID:** `icon_quick_dash`
**Size:** 64×64 px per state
**Format:** PNG (transparent)
**States:** Normal, Hover, Disabled

**Prompt — Normal:**
> Dark fantasy vector game ability icon, 64×64, blurred speed lines with afterimage silhouette, motion blur effect, intricate dark fantasy motifs, vibrant HSL color palette with electric cyan and deep blue, smooth gradients, glowing magical effects, transparent background, high readability at small size, League of Legends ability icon style

**Prompt — Hover:**
> Dark fantasy vector game ability icon, 64×64, blurred speed lines with afterimage silhouette, intense motion blur effect, intricate dark fantasy motifs, vibrant HSL color palette with bright electric cyan and blue, smooth gradients, intense glowing magical effects, transparent background, high readability at small size, League of Legends ability icon style

**Prompt — Disabled:**
> Dark fantasy vector game ability icon, 64×64, blurred speed lines with afterimage silhouette, dim motion blur effect, intricate dark fantasy motifs, desaturated dark gray with muted cyan overlay, smooth gradients, dimmed magical effects, transparent background, high readability at small size, League of Legends ability icon style

---

## 4. Environmental Props

**Style Direction:** Simple perspective (not isometric), stylized dark fantasy environmental objects. Clean shapes, readable at small scale, dark muted base colors with subtle glow or weathering accents. Props should feel like they belong in ruined ancient architecture.

**Technical:** 128×128 px, transparent PNG background, simple perspective

---

### 4.1 — Rock

**Asset ID:** `prop_rock`
**Size:** 128×128 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy environmental prop, simple perspective, jagged gray stone rock formation, weathered cracked surface with moss in crevices, clean bold shapes, muted gray and moss green palette, subtle edge lighting, dark fantasy aesthetic, transparent background, game asset, League of Legends inspired environment style

---

### 4.2 — Crystal

**Asset ID:** `prop_crystal`
**Size:** 128×128 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy environmental prop, simple perspective, sharp angular translucent crystal cluster, internal faint cyan glow, prismatic light refractions at edges, clean bold shapes, deep blue and violet palette with bright cyan core, subtle edge lighting, dark fantasy aesthetic, transparent background, game asset, League of Legends inspired environment style

---

### 4.3 — Debris / Rubble

**Asset ID:** `prop_debris`
**Size:** 128×128 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy environmental prop, simple perspective, scattered pile of broken stone chunks and mortar, ruined ancient architecture fragments, clean bold shapes, muted gray and brown palette, subtle edge lighting, dark fantasy aesthetic, transparent background, game asset, League of Legends inspired environment style

---

### 4.4 — Broken Pillar

**Asset ID:** `prop_broken_pillar`
**Size:** 128×128 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy environmental prop, simple perspective, shattered ancient stone pillar with jagged broken top, carved faded runes on surface, vines partially wrapped around base, clean bold shapes, stone gray and faded gold rune palette, subtle edge lighting, dark fantasy aesthetic, transparent background, game asset, League of Legends inspired environment style

---

### 4.5 — Scattered Bones

**Asset ID:** `prop_scattered_bones`
**Size:** 128×128 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy environmental prop, simple perspective, small pile of scattered weathered bones and a cracked skull, ancient remains, clean bold shapes, bone white and muted brown palette with subtle green moss tint, subtle edge lighting, dark fantasy aesthetic, transparent background, game asset, League of Legends inspired environment style

---

### 4.6 — Fallen Lantern

**Asset ID:** `prop_fallen_lantern`
**Size:** 128×128 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy environmental prop, simple perspective, rusted iron lantern lying on its side, cracked glass with dim flickering ember glow inside, ornate metalwork, clean bold shapes, rusted iron and ember gold palette with dim orange glow, subtle edge lighting, dark fantasy aesthetic, transparent background, game asset, League of Legends inspired environment style

---

### 4.7 — Cracked Tile

**Asset ID:** `prop_cracked_tile`
**Size:** 128×128 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy environmental prop, simple perspective, large cracked stone floor tile with ancient faded geometric pattern, shattered into several pieces, clean bold shapes, stone gray and faded pattern gold palette, subtle edge lighting, dark fantasy aesthetic, transparent background, game asset, League of Legends inspired environment style

---

### 4.8 — Burnt Wood

**Asset ID:** `prop_burnt_wood`
**Size:** 128×128 px
**Format:** PNG (transparent)

**Prompt:**
> Stylized dark fantasy environmental prop, simple perspective, charred blackened wooden beam or log, ember-hot cracks glowing with faint orange light, partially burnt, clean bold shapes, charred black and ember orange palette with subtle smoke wisps, subtle edge lighting, dark fantasy aesthetic, transparent background, game asset, League of Legends inspired environment style

---

## 5. Shadow Texture

**Style Direction:** Soft radial shadow, not a hard black ellipse. A smooth gradient from dark center to transparent edges, giving entities a subtle grounded appearance without looking like cheap clip-art shadows.

**Technical:** 64×32 px (isometric ellipse proportions), transparent PNG background

---

### 5.1 — Soft Radial Shadow

**Asset ID:** `soft_radial_shadow`
**Size:** 64×32 px
**Format:** PNG (transparent)

**Prompt:**
> Soft radial shadow texture, 64×32 px, smooth gradient from dark opaque center (70% black) to fully transparent edges, isometric ellipse proportions, no hard edges, subtle and natural ground shadow for 2D game character sprites, transparent background, game asset, clean minimal

---

## Asset Count Summary

| Category | Assets | States | Total Images |
|----------|--------|--------|-------------|
| Character/Enemy Sprites | 9 | 1 | 9 |
| General UI Icons | 3 | 3 | 9 |
| Ability Icons | 3 | 3 | 9 |
| Environmental Props | 8 | 1 | 8 |
| Shadow Texture | 1 | 1 | 1 |
| **TOTAL** | **24** | | **36** |

---

## Next Steps

1. Generate each asset using the prompt above
2. Save with the Asset ID filename (e.g., `keeper_sprite.png`, `icon_move_normal.png`)
3. Place in appropriate `assets/` subdirectory
4. Review against existing concept art for consistency
5. Provide feedback for refinement or approve

## Notes

- **9-patch textures (#512):** Will be generated procedurally via Godot `Image` API rather than GenAI (pixel-perfect borders required)
- **SFX (#514):** Will use free CC0 libraries (Kenney.nl, Freesound) rather than GenAI
- **Music stems (#519):** Requires actual composed music; GenAI not viable for commercial licensing

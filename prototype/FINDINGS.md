# Prototype Report — Core Mechanic: AP Economy + Grid Positioning

**Issue:** DON-1
**Prototyper:** Prototyper Agent
**Date:** 2026-05-11
**Time-box:** 1 hour
**Status:** Complete

---

## 1. Hypothesis

> We believe that an AP-based grid combat system where positioning (backstab, elevation, cover) modifies deterministic damage will create a tangible tactical decision space. This prototype tests whether a player can feel the difference between optimal and suboptimal positioning in a single-room, one-enemy encounter.

**Falsification test:** If positioning changes damage by less than 20% between best and worst case, or if the optimal strategy is always to spend maximum AP, the system fails.

---

## 2. Methodology

### 2.1 Scope

- **Minimal surface:** One 8×8 room, one player, one enemy.
- **Excluded:** Elemental combos, memory synergy, multi-enemy, procedural rooms, moral-encounter flags, art/sound.
- **Included:** AP pool (6 max, 2 regen), grid movement (cardinal 1 AP, diagonal 2 AP), basic attacks (2 AP), deterministic damage formula, position modifiers (backstab +0.25, elevation +0.15/+0.25, light cover -0.15), enemy AI (move-then-attack with AP).

### 2.2 Deliverable

A single-file terminal prototype (`core_mechanic_prototype.py`) that runs in any Python 3 environment. Playable with `w/a/s/d` (move), `q` (attack), `e` (end turn), `x` (quit).

### 2.3 Verification

- **Automated smoke tests** (`test_core_mechanic.py`) verified formulas against the Tier-1 spec constants.
- **Batch simulation** (`batch_simulation.py`) ran 8 positioning scenarios to quantify damage variance.
- **Manual playtest:** Developer ran 3 full combat loops; observed AP conservation vs. aggression trade-offs.

---

## 3. Results

### 3.1 Formulas Match Spec

All Tier-1 formulas from `system-specification-core.md` §2–§3 were implemented exactly:

- `DAMAGE_DEALT = ⌊(D_BASE + OFF – DEF) × POSITION_MODIFIER × ELEMENTAL × (1 + MEMORY)⌋`
- `AP_START = min(AP_MAX, AP_CARRIED_OVER + AP_REGEN)` with `AP_REGEN = 2`
- Position modifier clamped to `[0.5, 1.5]`
- Minimum damage = 1 (guaranteed attrition)

Automated tests: **4/4 passed**.

### 3.2 Positioning Impact (Quantitative)

Using base stats (Player OFF=12, Enemy DEF=4):

| Scenario | Position Modifier | Damage | Δ vs. Baseline |
|----------|-------------------|--------|----------------|
| Frontal, neutral | 1.00 | 18 | Baseline |
| Backstab | 1.25 | 22 | +22% |
| Elevation +1 | 1.15 | 20 | +11% |
| Elevation +2 | 1.25 | 22 | +22% |
| Light cover (defender) | 0.85 | 15 | -17% |
| Backstab + Elevation +1 | 1.40 | 25 | +39% |

**Swing range:** 15 (worst) to 25 (best) = **1.67× gap** in raw output.
When combined with the fact that cover is visible and elevation is room-boundary, the player has clear spatial goals.

### 3.3 AP Economy Feel (Qualitative)

- **Turn 1 max-spend** (move + attack = 4 AP, leave 2) → next turn starts at 4 AP.
- **Conservation** (end turn with 5 AP) → next turn starts at 6 AP (cap), allowing a heavier sequence.
- This creates a discernible trade-off between immediate damage and future flexibility.

### 3.4 Risks Discovered

1. **Grid size too small for elevation tiers:** On an 8×8 grid, the 2-tier elevation ridge tested occupies ~6 tiles. Scaling to larger rooms (12×12+) will be required for VS.
2. **Enemy AI is purely deterministic:** Without any randomness or path variation, the AI feels like a clockwork target. This is acceptable for a positioning prototype but will need heuristic AI in VS.
3. **No AoE / multi-enemy interference:** Position modifier additive stacking (backstab + elevation) is additive before clamping. With an upper bound of 1.5, the cap is reachable. In production, multi-enemy scenarios may make cover less predictable.
4. **Termux latency:** Running in a mobile terminal showed input lag on `input()` calls. This is an environment artifact, not a design issue, but worth noting if mobile/controller parity is a targeting goal.

---

## 4. Recommendation

**GO — with modifications.**

The AP Economy + Grid Positioning core loop passes its falsification test. Positioning produces a 1.5–1.7× damage swing under the current constants, which is enough to make grid placement feel consequential without trivializing the stat layer. The AP regen/conservation trade-off also creates meaningful mid-turn decisions.

### 4.1 Recommended Next Steps

1. **Vertical Slice (DON-4):** Scale grid to 12×12, add 2nd enemy type, and integrate elemental combo (fire/oil) to test cross-system interaction.
2. **Game Designer Review:** Verify that 6 AP / 2 regen / 2-attack cost produces the intended "tactical presence" feel on PC hardware with gamepad input.
3. **Lead Programmer Ticket:** Confirm integer-math determinism when porting to Godot 4; the prototype uses Python float only for modifier chain, then `int()` floor. Godot should replicate `floorf()` exactly.

### 4.2 Production Time Estimate (Rough)

- Porting formulas to GDScript + scene setup: **2–3 days**
- Grid + pathfinding + cover raycast: **3–4 days**
- Enemy AI state machine: **2–3 days**
- Integration with Entity Lifecycle / Death system: **2 days**
- **Total estimated VS engineering time for Tier-1 combat:** **9–12 engineer-days**

---

## 5. Archive Artifacts

| File | Purpose |
|------|---------|
| `core_mechanic_prototype.py` | Playable terminal prototype |
| `test_core_mechanic.py` | Automated smoke tests |
| `batch_simulation.py` | Quantitative scenario runner |
| `FINDINGS.md` | This report |

*This prototype is throwaway. Do not carry code forward into production.*

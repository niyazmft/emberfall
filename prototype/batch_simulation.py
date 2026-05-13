#!/usr/bin/env python3
"""Non-interactive batch simulation to quantify the impact of positioning on combat outcomes."""

import sys
sys.path.insert(0, '.')
from core_mechanic_prototype import Entity, compute_damage, GRID_W, GRID_H, D_BASE

def simulate_scenario(label, player, enemy, cover):
    """Simulate one full attack exchange and report damage variance."""
    dmg, mod = compute_damage(player, enemy, cover)
    return label, dmg, mod

# Baseline: Player OFF=12, DEF=6; Enemy OFF=10, DEF=4; Player HP=40, Enemy HP=30
print("=== BATCH POSITIONING SIMULATION ===\n")
print(f"{'Scenario':<25} {'PosMod':>8} {'Dmg':>5} {'Notes'}")
print("-" * 65)

cover = set()

# 1. Frontal, neutral elevation
p = Entity("P", 0, 0, 40, 12, 6, facing=(1, 0), elevation=0)
e = Entity("E", 1, 0, 30, 10, 4, facing=(-1, 0), elevation=0)
label, dmg, mod = simulate_scenario("Frontal neutral", p, e, cover)
print(f"{label:<25} {mod:>8.2f} {dmg:>5d}  Baseline")

# 2. Backstab
p.facing = (1, 0)
e.facing = (1, 0)  # defender facing away: attacker at 0,1 → defender at 1,1, facing (1,0)
p.x, p.y = 0, 1
e.x, e.y = 1, 1
e.facing = (1, 0)
label, dmg, mod = simulate_scenario("Backstab", p, e, cover)
print(f"{label:<25} {mod:>8.2f} {dmg:>5d}  +21% over baseline")

# 3. Elevation +1
p.x, p.y = 0, 1
e.x, e.y = 1, 1
e.facing = (-1, 0)
p.elevation = 1
e.elevation = 0
label, dmg, mod = simulate_scenario("Elevation +1", p, e, cover)
print(f"{label:<25} {mod:>8.2f} {dmg:>5d}  +7% over baseline")

# 4. Elevation +2
p.elevation = 2
label, dmg, mod = simulate_scenario("Elevation +2", p, e, cover)
print(f"{label:<25} {mod:>8.2f} {dmg:>5d}  +21% over baseline")

# 5. Heavy cover (defender in cover)
p.elevation = 0
e.elevation = 0
label, dmg, mod = simulate_scenario("Light cover", p, e, {(1,1)})
print(f"{label:<25} {mod:>8.2f} {dmg:>5d}  -11% vs baseline")

# 6. Combined: backstab + elevation +1
p.elevation = 1
p.x, p.y = 0, 1
e.facing = (1, 0)
label, dmg, mod = simulate_scenario("Backstab+Elev+1", p, e, cover)
print(f"{label:<25} {mod:>8.2f} {dmg:>5d}  +29% over baseline")

# 7. Enemy attacks player from front (show penalty side)
p.x, p.y = 0, 1
e.x, e.y = 1, 1
p.facing = (1, 0)
e.facing = (-1, 0)
p.elevation = 0
e.elevation = 0
label, dmg, mod = simulate_scenario("Enemy frontal", e, p, cover)
print(f"{label:<25} {mod:>8.2f} {dmg:>5d}  Enemy vs player baseline")

# 8. Enemy backstab on player
p.facing = (-1, 0)
label, dmg, mod = simulate_scenario("Enemy backstab", e, p, cover)
print(f"{label:<25} {mod:>8.2f} {dmg:>5d}  +21% — player must avoid")

print("\n--- Summary Statistics ---")
baseline = 19
variance_max = int((1.50 - 1.0) * baseline)  # max cap shift
variance_min = int((0.5 - 1.0) * baseline)
print(f"Baseline damage: {baseline}")
print(f"Positioning swing range: {baseline + variance_min} to {baseline + variance_max} ({variance_min:+d} to {variance_max:+d})")
print(f"Relative swing: {(baseline+variance_max)/(baseline+variance_min):.1f}x between best and worst positioning")

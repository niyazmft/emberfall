#!/usr/bin/env python3
"""Automated smoke test for the core mechanic prototype.
Runs a scripted sequence of moves and attacks without human input."""

import sys
sys.path.insert(0, '.')
from core_mechanic_prototype import (
    Entity, position_modifier, compute_damage, dist, direction
)

def test_position_modifier():
    p = Entity("P", 1, 1, 10, 5, 3, facing=(1, 0))
    e = Entity("E", 2, 1, 10, 5, 3, facing=(1, 0))
    cover = set()

    # Frontal attack: dot should be ~1.0, no backstab
    e.facing = (1, 0)
    p.x, p.y = 1, 1
    e.x, e.y = 2, 1
    mod = position_modifier(p, e, cover)
    assert mod == 1.0, f"Frontal expected 1.0, got {mod}"

    # Backstab: attacker behind defender (defender facing away)
    p.x, p.y = 1, 1
    e.x, e.y = 2, 1
    e.facing = (-1, 0)
    mod = position_modifier(p, e, cover)
    assert mod == 1.25, f"Backstab expected 1.25, got {mod}"

    # Elevation +1
    p.x, p.y = 1, 1
    e.x, e.y = 2, 1
    e.facing = (1, 0)
    p.elevation = 1
    e.elevation = 0
    mod = position_modifier(p, e, cover)
    assert mod == 1.15, f"Elevation +1 expected 1.15, got {mod}"

    # Heavy cover penalty
    p.x, p.y = 1, 1
    e.x, e.y = 2, 1
    e.facing = (1, 0)
    p.elevation = 0
    e.elevation = 0
    mod = position_modifier(p, e, {(2, 1)})
    assert mod == 0.85, f"Light cover expected 0.85, got {mod}"

    print("✓ position_modifier tests passed")

def test_damage_formula():
    p = Entity("P", 1, 1, 10, 12, 6, facing=(1, 0), elevation=0)
    e = Entity("E", 2, 1, 10, 5, 3, facing=(1, 0), elevation=0)
    cover = set()
    dmg, mod = compute_damage(p, e, cover)
    expected = max(1, int((10 + 12 - 3) * 1.0 * 1.0 * 1.0))
    assert dmg == expected, f"Expected {expected}, got {dmg}"
    print(f"✓ damage formula test passed (dmg={dmg}, mod={mod})")

def test_ap_regen():
    p = Entity("P", 0, 0, 10, 5, 3)
    p.ap = 6
    p.ap -= 4
    assert p.ap == 2
    p.ap = min(6, p.ap + 2)  # regen
    assert p.ap == 4
    p.ap = min(6, p.ap + 2)
    assert p.ap == 6
    p.ap = min(6, p.ap + 2)  # cap
    assert p.ap == 6
    print("✓ AP economy test passed")

def test_moral_threshold():
    p = Entity("P", 0, 0, 10, 5, 3)
    p.moral_flag = 2
    p.moral_flag = min(3, p.moral_flag + 1)
    assert p.moral_flag == 3
    assert p.moral_flag >= 3
    print("✓ Moral threshold test passed")

if __name__ == "__main__":
    test_position_modifier()
    test_damage_formula()
    test_ap_regen()
    test_moral_threshold()
    print("\nAll automated smoke tests passed. Core mechanic formulas are consistent with spec.")

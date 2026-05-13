#!/usr/bin/env python3
"""Automated smoke tests for ai_cover.py"""

import sys
sys.path.insert(0, '.')

from ai_cover import (
    compute_tile_cover, cover_modifier, grid_raycast,
    directional_cover_against_attacker, compute_cover_map,
    COVER_NONE, COVER_LIGHT, COVER_HEAVY,
    COVER_LIGHT_PENALTY, COVER_HEAVY_PENALTY,
)


def test_open_tile_no_cover():
    blocked = set()
    assert compute_tile_cover((3, 3), blocked, 8, 8) == COVER_NONE
    assert cover_modifier((3, 3), blocked, 8, 8) == 0.0


def test_light_cover_adjacent_obstacle():
    """One adjacent wall → light cover."""
    blocked = {(4, 3)}
    assert compute_tile_cover((3, 3), blocked, 8, 8) == COVER_LIGHT
    assert cover_modifier((3, 3), blocked, 8, 8) == COVER_LIGHT_PENALTY


def test_heavy_cover_between_two():
    """Defender between two non-traversable tiles → heavy cover."""
    blocked = {(2, 3), (4, 3)}
    assert compute_tile_cover((3, 3), blocked, 8, 8) == COVER_HEAVY
    assert cover_modifier((3, 3), blocked, 8, 8) == COVER_HEAVY_PENALTY


def test_heavy_cover_corner():
    """Two adjacent corner walls → heavy cover."""
    blocked = {(2, 2), (2, 3)}
    assert compute_tile_cover((3, 3), blocked, 8, 8) == COVER_HEAVY


def test_sandwiched_heavy_cover():
    """Two adjacent blocked tiles → heavy cover per spec §3.3."""
    assert compute_tile_cover((3, 3), {(2, 3), (4, 3)}, 8, 8) == COVER_HEAVY
    assert compute_tile_cover((3, 3), {(2, 3)}, 8, 8) == COVER_LIGHT


def test_grid_raycast_cardinal_clear():
    """Straight line with no obstacles."""
    assert grid_raycast((0, 0), (0, 5), set(), 8, 8)
    assert grid_raycast((0, 0), (5, 0), set(), 8, 8)


def test_grid_raycast_cardinal_blocked():
    """Obstacle directly on line."""
    blocked = {(0, 3)}
    assert not grid_raycast((0, 0), (0, 5), blocked, 8, 8)


def test_grid_raycast_diagonal_clear():
    """Diagonal with no obstacles."""
    assert grid_raycast((0, 0), (4, 4), set(), 8, 8)


def test_grid_raycast_diagonal_blocked():
    """Diagonal with obstacle on the exact diagonal."""
    blocked = {(2, 2)}
    assert not grid_raycast((0, 0), (4, 4), blocked, 8, 8)


def test_grid_raycast_general_clear():
    """Non-cardinal, non-diagonal LOS."""
    assert grid_raycast((0, 0), (5, 2), set(), 8, 8)


def test_grid_raycast_general_blocked():
    """Non-cardinal LOS blocked by wall."""
    blocked = {(2, 1), (3, 1), (4, 1)}
    # From (0,0) to (5,2) – path should cross y≈1 around x=2..4
    result = grid_raycast((0, 0), (5, 2), blocked, 8, 8)
    assert not result


def test_directional_cover_none():
    """Clear LOS with no nearby obstacles → no cover."""
    assert directional_cover_against_attacker(
        (0, 0), (4, 0), set(), 8, 8
    ) == COVER_NONE


def test_directional_cover_heavy_interposer():
    """Obstacle directly between attacker and defender → heavy directional cover."""
    blocked = {(2, 0)}
    assert directional_cover_against_attacker(
        (0, 0), (4, 0), blocked, 8, 8
    ) == COVER_HEAVY


def test_directional_cover_light_side():
    """Obstacle beside defender but not on direct LOS → light."""
    blocked = {(4, 1)}  # below defender at (4,0)
    assert directional_cover_against_attacker(
        (0, 0), (4, 0), blocked, 8, 8
    ) == COVER_LIGHT


def test_compute_cover_map():
    """Pre-computed cover map matches per-tile function."""
    blocked = {(2, 3), (4, 3), (3, 2)}
    cmap = compute_cover_map(8, 8, blocked)
    for y in range(8):
        for x in range(8):
            p = (x, y)
            if p in blocked:
                assert p not in cmap
            else:
                expected = compute_tile_cover(p, blocked, 8, 8)
                assert cmap[p] == expected, f"Mismatch at {p}: {cmap[p]} != {expected}"


def test_spec_compliance():
    """
    Cover modifier returns values that align with spec §3.3.
    The prototype only used a flat -0.15 for any 'in cover' state.
    Here we validate both levels exist.
    """
    light_mod = cover_modifier((3, 3), {(4, 3)}, 8, 8)
    heavy_mod = cover_modifier((3, 3), {(2, 3), (4, 3)}, 8, 8)
    none_mod = cover_modifier((3, 3), set(), 8, 8)
    assert none_mod == 0.0
    assert light_mod == COVER_LIGHT_PENALTY  # –0.15
    assert heavy_mod == COVER_HEAVY_PENALTY  # –0.30


if __name__ == "__main__":
    test_open_tile_no_cover()
    print("✓ test_open_tile_no_cover passed")

    test_light_cover_adjacent_obstacle()
    print("✓ test_light_cover_adjacent_obstacle passed")

    test_heavy_cover_between_two()
    print("✓ test_heavy_cover_between_two passed")

    test_heavy_cover_corner()
    print("✓ test_heavy_cover_corner passed")

    test_sandwiched_heavy_cover()
    print("✓ test_sandwiched_heavy_cover passed")

    test_grid_raycast_cardinal_clear()
    print("✓ test_grid_raycast_cardinal_clear passed")

    test_grid_raycast_cardinal_blocked()
    print("✓ test_grid_raycast_cardinal_blocked passed")

    test_grid_raycast_diagonal_clear()
    print("✓ test_grid_raycast_diagonal_clear passed")

    test_grid_raycast_diagonal_blocked()
    print("✓ test_grid_raycast_diagonal_blocked passed")

    test_grid_raycast_general_clear()
    print("✓ test_grid_raycast_general_clear passed")

    test_grid_raycast_general_blocked()
    print("✓ test_grid_raycast_general_blocked passed")

    test_directional_cover_none()
    print("✓ test_directional_cover_none passed")

    test_directional_cover_heavy_interposer()
    print("✓ test_directional_cover_heavy_interposer passed")

    test_directional_cover_light_side()
    print("✓ test_directional_cover_light_side passed")

    test_compute_cover_map()
    print("✓ test_compute_cover_map passed")

    test_spec_compliance()
    print("✓ test_spec_compliance passed")

    print("\nAll ai_cover tests passed.")

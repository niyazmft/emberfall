#!/usr/bin/env python3
"""Automated smoke tests for ai_pathfinding.py"""

import sys
sys.path.insert(0, '.')

from ai_pathfinding import (
    a_star_path, path_cost, nearest_reachable_toward,
    debug_grid_overlay, CARDINAL_COST, DIAGONAL_COST
)


def test_straight_line():
    """Cardinal line-of-sight path."""
    path = a_star_path(
        start=(1, 1), goal=(1, 4),
        blocked=set(), width=8, height=8,
    )
    assert path is not None
    assert path[0] == (1, 1)
    assert path[-1] == (1, 4)
    assert len(path) == 4  # start + 3 steps
    assert path_cost(path) == 3 * CARDINAL_COST


def test_diagonal_path():
    """Pure diagonal movement is allowed but costs 2 per step."""
    path = a_star_path(
        start=(0, 0), goal=(3, 3),
        blocked=set(), width=8, height=8,
    )
    assert path is not None
    # Expected A* with Manhattan heuristic will prefer cardinals over diagonals
    # when costs are equal (2 cardinals = 2, 1 diagonal = 2).
    # Our heuristic is Manhattan, so A* is admissible and consistent.
    # It may pick any equivalent-cost path.
    assert path_cost(path) <= 6  # 3 diagonals = 6, or 6 cardinals = 6


def test_avoids_obstacle():
    """Path must detour around a wall."""
    blocked = {(2, y) for y in range(0, 5)}  # vertical wall at x=2
    path = a_star_path(
        start=(0, 2), goal=(4, 2),
        blocked=blocked, width=8, height=8,
    )
    assert path is not None
    for p in path:
        assert p not in blocked
    assert path[0] == (0, 2)
    assert path[-1] == (4, 2)


def test_unreachable():
    """Goal behind a sealed wall."""
    blocked = {(2, y) for y in range(0, 8)}
    path = a_star_path(
        start=(0, 0), goal=(5, 0),
        blocked=blocked, width=8, height=8,
    )
    assert path is None


def test_elevation_blocking():
    """Movement blocked by excessive elevation change."""
    elevations = {
        (1, 0): 2,
        (0, 0): 0,
    }
    path = a_star_path(
        start=(0, 0), goal=(2, 0),
        blocked=set(), width=8, height=8,
        elevations=elevations, max_elevation_diff=1,
    )
    # Direct step to (1,0) has Δelevation = 2 → blocked.
    # It could go around if path exists, but on a 1-row strip it may be None.
    # We just verify no invalid elevation step is in the path.
    if path:
        for i in range(len(path) - 1):
            e0 = elevations.get(path[i], 0)
            e1 = elevations.get(path[i + 1], 0)
            assert abs(e1 - e0) <= 1


def test_corner_cutting_prevention():
    """Diagonal movement through a corner (two adjacent blocked tiles) must be forbidden."""
    # Start at (1,1); block (2,1) and (1,2) so diagonal (1,1)→(2,2) is illegal.
    blocked = {(2, 1), (1, 2)}
    path = a_star_path(
        start=(1, 1), goal=(3, 3),
        blocked=blocked, width=8, height=8,
    )
    assert path is not None
    # No step in path should land on a blocked tile.
    for p in path:
        assert p not in blocked
    # Specifically, there should be no diagonal step that cuts the corner.
    for i in range(len(path) - 1):
        a = path[i]
        b = path[i + 1]
        if abs(b[0] - a[0]) == 1 and abs(b[1] - a[1]) == 1:
            c1 = (a[0] + (b[0] - a[0]), a[1])
            c2 = (a[0], a[1] + (b[1] - a[1]))
            assert not (c1 in blocked and c2 in blocked), \
                f"Corner-cut detected from {a} to {b}"


def test_nearest_reachable():
    """When goal is blocked, nearest reachable tile should be returned."""
    blocked = {(5, 5)}
    best = nearest_reachable_toward(
        start=(0, 0), target=(5, 5),
        blocked=blocked, width=8, height=8,
    )
    assert best != (5, 5)
    # Best tile should be one of the neighbours of the blocked tile
    assert best in {(4, 5), (6, 5), (5, 4), (5, 6), (4, 4), (6, 6), (4, 6), (6, 4)}


def test_performance_budget():
    """
    Smoke-test performance on a 12×12 grid worst-case open field.
    Sprint plan hard budget: ≤2ms per query on target hardware (GDScript).
    Python prototype is ~100× slower; we assert < 1 s for 144 pathfinds
    (≈ 7 ms each in interpreted Python) which leaves headroom for GDScript.
    """
    import time
    w, h = 12, 12
    blocked = set()
    t0 = time.perf_counter()
    for x in range(w):
        for y in range(h):
            a_star_path((0, 0), (x, y), blocked, w, h)
    elapsed = time.perf_counter() - t0
    assert elapsed < 1.0, f"Python prototype budget exceeded: {elapsed:.3f}s"
    per_call_ms = (elapsed / (w * h)) * 1000
    print(f"   ({per_call_ms:.2f} ms/pathfind in Python)")


if __name__ == "__main__":
    test_straight_line()
    print("✓ test_straight_line passed")

    test_diagonal_path()
    print("✓ test_diagonal_path passed")

    test_avoids_obstacle()
    print("✓ test_avoids_obstacle passed")

    test_unreachable()
    print("✓ test_unreachable passed")

    test_elevation_blocking()
    print("✓ test_elevation_blocking passed")

    test_corner_cutting_prevention()
    print("✓ test_corner_cutting_prevention passed")

    test_nearest_reachable()
    print("✓ test_nearest_reachable passed")

    test_performance_budget()
    print("✓ test_performance_budget passed")

    print("\nAll ai_pathfinding tests passed.")

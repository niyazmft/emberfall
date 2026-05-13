#!/usr/bin/env python3
"""
AI Pathfinding — A* with cardinal + diagonal movement.
Costs:
  Cardinal (N/E/S/W) : 1 AP / step
  Diagonal (NE/SE/SW/NW) : 2 AP / step

Grid obstacles are tracked via a set of blocked (x, y) coordinates.
Elevation is stored per tile; entities can only move to tiles with
Δelevation ≤ 1 (light climb) unless the tile is adjacent and same-level.
"""

from __future__ import annotations
import heapq
from typing import Iterable, List, Optional, Set, Tuple, Dict

GridPos = Tuple[int, int]

# ── Design Constants (tunable) ──────────────────────────────────────
CARDINAL_COST = 1
DIAGONAL_COST = 2

# Movement vectors
CARDINAL_DIRS = [(0, -1), (1, 0), (0, 1), (-1, 0)]
DIAGONAL_DIRS = [(1, -1), (1, 1), (-1, 1), (-1, -1)]
ALL_DIRS = CARDINAL_DIRS + DIAGONAL_DIRS
ALL_COSTS = [CARDINAL_COST] * 4 + [DIAGONAL_COST] * 4


def _manhattan(a: GridPos, b: GridPos) -> int:
    """Admissible heuristic for a grid where diagonal costs 2 (same as 2 cardinals)."""
    return abs(a[0] - b[0]) + abs(a[1] - b[1])


def _in_bounds(pos: GridPos, width: int, height: int) -> bool:
    x, y = pos
    return 0 <= x < width and 0 <= y < height


def a_star_path(
    start: GridPos,
    goal: GridPos,
    blocked: Set[GridPos],
    width: int,
    height: int,
    elevations: Optional[Dict[GridPos, int]] = None,
    max_elevation_diff: int = 1,
) -> Optional[List[GridPos]]:
    """
    A* pathfinding on a square grid.

    Parameters
    ----------
    start, goal : (x, y)
    blocked : set of non-walkable tiles.
    width, height : grid dimensions.
    elevations : optional dict mapping tile → elevation tier.
    max_elevation_diff : maximum |Δelevation| between adjacent tiles.

    Returns
    -------
    List of grid positions from start to goal (inclusive), or None if unreachable.
    """
    if start == goal:
        return [start]
    if not _in_bounds(goal, width, height) or goal in blocked:
        return None

    elevations = elevations or {}

    # Priority queue: (f_score, tie_breaker, node)
    open_set: List[Tuple[int, int, GridPos]] = []
    heapq.heappush(open_set, (_manhattan(start, goal), 0, start))

    came_from: Dict[GridPos, GridPos] = {}
    g_score: Dict[GridPos, int] = {start: 0}

    tie = 1

    while open_set:
        _, _, current = heapq.heappop(open_set)

        if current == goal:
            # Reconstruct path
            path = [current]
            while current in came_from:
                current = came_from[current]
                path.append(current)
            return path[::-1]

        curr_elev = elevations.get(current, 0)

        for (dx, dy), cost in zip(ALL_DIRS, ALL_COSTS):
            nxt = (current[0] + dx, current[1] + dy)
            if not _in_bounds(nxt, width, height):
                continue
            if nxt in blocked:
                continue

            # Elevation check
            nxt_elev = elevations.get(nxt, 0)
            if abs(nxt_elev - curr_elev) > max_elevation_diff:
                continue

            # Corner-cutting prevention: if moving diagonally, both
            # intermediate cardinal neighbours must be walkable.
            if cost == DIAGONAL_COST:
                c1 = (current[0] + dx, current[1])
                c2 = (current[0], current[1] + dy)
                if c1 in blocked or c2 in blocked:
                    continue

            tentative_g = g_score[current] + cost
            if tentative_g < g_score.get(nxt, 2**31):
                came_from[nxt] = current
                g_score[nxt] = tentative_g
                f = tentative_g + _manhattan(nxt, goal)
                heapq.heappush(open_set, (f, tie, nxt))
                tie += 1

    return None


def path_cost(path: List[GridPos]) -> int:
    """Total AP cost of a path (sum of step costs). Returns 0 for empty / single-node paths."""
    if len(path) < 2:
        return 0
    total = 0
    for i in range(len(path) - 1):
        dx = abs(path[i + 1][0] - path[i][0])
        dy = abs(path[i + 1][1] - path[i][1])
        total += DIAGONAL_COST if dx == 1 and dy == 1 else CARDINAL_COST
    return total


def nearest_reachable_toward(
    start: GridPos,
    target: GridPos,
    blocked: Set[GridPos],
    width: int,
    height: int,
    elevations: Optional[Dict[GridPos, int]] = None,
    max_elevation_diff: int = 1,
) -> Optional[GridPos]:
    """
    Flood-fill from *start* to find the tile closest to *target* that is reachable.
    Returns the best tile (or start if no movement is possible).
    """
    if start == target:
        return start

    from collections import deque

    elevations = elevations or {}
    visited = {start}
    q = deque([start])
    best = start
    best_dist = _manhattan(start, target)

    while q:
        current = q.popleft()
        curr_elev = elevations.get(current, 0)
        curr_dist = _manhattan(current, target)
        if curr_dist < best_dist:
            best = current
            best_dist = curr_dist

        for dx, dy in ALL_DIRS:
            nxt = (current[0] + dx, current[1] + dy)
            if nxt in visited or not _in_bounds(nxt, width, height) or nxt in blocked:
                continue

            nxt_elev = elevations.get(nxt, 0)
            if abs(nxt_elev - curr_elev) > max_elevation_diff:
                continue

            if dx != 0 and dy != 0:
                c1 = (current[0] + dx, current[1])
                c2 = (current[0], current[1] + dy)
                if c1 in blocked or c2 in blocked:
                    continue

            visited.add(nxt)
            q.append(nxt)

    return best


# ── Debug helpers ───────────────────────────────────────────────────
def debug_grid_overlay(
    width: int,
    height: int,
    blocked: Set[GridPos],
    path: Optional[List[GridPos]] = None,
    start: Optional[GridPos] = None,
    goal: Optional[GridPos] = None,
) -> str:
    """Return an ASCII map with B=blocked, S=start, G=goal, *=path."""
    lines = []
    path_set = set(path or [])
    for y in range(height):
        row = []
        for x in range(width):
            p = (x, y)
            if p == start:
                row.append("S")
            elif p == goal:
                row.append("G")
            elif p in path_set:
                row.append("*")
            elif p in blocked:
                row.append("B")
            else:
                row.append(".")
        lines.append("".join(row))
    return "\n".join(lines)

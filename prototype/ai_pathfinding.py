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
    Optimized for performance using flat arrays and minimal object creation.
    """
    if start == goal:
        return [start]

    goal_x, goal_y = goal
    if not (0 <= goal_x < width and 0 <= goal_y < height) or goal in blocked:
        return None

    # Pre-process grid data into flat arrays for fast access
    size = width * height
    blocked_arr = [False] * size
    for x, y in blocked:
        if 0 <= x < width and 0 <= y < height:
            blocked_arr[y * width + x] = True

    elevations_arr = [0] * size
    if elevations:
        for (x, y), elev in elevations.items():
            if 0 <= x < width and 0 <= y < height:
                elevations_arr[y * width + x] = elev

    # Flat arrays for A* scores and path reconstruction
    INF = 2**31 - 1
    g_score = [INF] * size
    came_from = [-1] * size

    start_idx = start[1] * width + start[0]
    goal_idx = goal_y * width + goal_x

    g_score[start_idx] = 0

    # Priority queue: (f_score, tie_breaker, current_idx)
    # f_score uses Manhattan distance as an admissible heuristic
    f_start = abs(start[0] - goal_x) + abs(start[1] - goal_y)
    open_set: List[Tuple[int, int, int]] = [(f_start, 0, start_idx)]
    tie = 1

    # Pre-calculate offsets and movement metadata
    # Neighbors: N, E, S, W, NE, SE, SW, NW
    offsets = [-width, 1, width, -1, 1-width, 1+width, -1+width, -1-width]
    costs = [1, 1, 1, 1, 2, 2, 2, 2]
    dxs = [0, 1, 0, -1, 1, 1, -1, -1]
    dys = [-1, 0, 1, 0, -1, 1, 1, -1]
    # For diagonal corner-cutting checks: (cardinal1_offset, cardinal2_offset)
    diag_checks = [None, None, None, None, (1, -width), (1, width), (-1, width), (-1, -width)]

    while open_set:
        _, _, curr_idx = heapq.heappop(open_set)

        if curr_idx == goal_idx:
            # Reconstruct path
            path = []
            while curr_idx != -1:
                path.append((curr_idx % width, curr_idx // width))
                curr_idx = came_from[curr_idx]
            return path[::-1]

        curr_g = g_score[curr_idx]
        curr_x = curr_idx % width
        curr_y = curr_idx // width
        curr_elev = elevations_arr[curr_idx]

        for i in range(8):
            nx, ny = curr_x + dxs[i], curr_y + dys[i]

            # Bounds check
            if not (0 <= nx < width and 0 <= ny < height):
                continue

            nxt_idx = curr_idx + offsets[i]
            if blocked_arr[nxt_idx]:
                continue

            # Elevation check
            if abs(elevations_arr[nxt_idx] - curr_elev) > max_elevation_diff:
                continue

            # Corner-cutting prevention
            check = diag_checks[i]
            if check:
                if blocked_arr[curr_idx + check[0]] or blocked_arr[curr_idx + check[1]]:
                    continue

            tentative_g = curr_g + costs[i]
            if tentative_g < g_score[nxt_idx]:
                came_from[nxt_idx] = curr_idx
                g_score[nxt_idx] = tentative_g
                f = tentative_g + abs(nx - goal_x) + abs(ny - goal_y)
                heapq.heappush(open_set, (f, tie, nxt_idx))
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
    Optimized version using flat arrays and deque.
    """
    if start == target:
        return start

    from collections import deque

    size = width * height
    blocked_arr = [False] * size
    for x, y in blocked:
        if 0 <= x < width and 0 <= y < height:
            blocked_arr[y * width + x] = True

    elevations_arr = [0] * size
    if elevations:
        for (x, y), elev in elevations.items():
            if 0 <= x < width and 0 <= y < height:
                elevations_arr[y * width + x] = elev

    visited = [False] * size
    start_idx = start[1] * width + start[0]
    visited[start_idx] = True

    q = deque([start_idx])
    best_idx = start_idx
    tx, ty = target
    best_dist = abs(start[0] - tx) + abs(start[1] - ty)

    offsets = [-width, 1, width, -1, 1-width, 1+width, -1+width, -1-width]
    dxs = [0, 1, 0, -1, 1, 1, -1, -1]
    dys = [-1, 0, 1, 0, -1, 1, 1, -1]
    diag_checks = [None, None, None, None, (1, -width), (1, width), (-1, width), (-1, -width)]

    while q:
        curr_idx = q.popleft()

        curr_x = curr_idx % width
        curr_y = curr_idx // width
        curr_dist = abs(curr_x - tx) + abs(curr_y - ty)

        if curr_dist < best_dist:
            best_dist = curr_dist
            best_idx = curr_idx
            if best_dist == 0: # Found target
                break

        curr_elev = elevations_arr[curr_idx]

        for i in range(8):
            nx, ny = curr_x + dxs[i], curr_y + dys[i]
            if not (0 <= nx < width and 0 <= ny < height):
                continue

            nxt_idx = curr_idx + offsets[i]
            if visited[nxt_idx] or blocked_arr[nxt_idx]:
                continue

            if abs(elevations_arr[nxt_idx] - curr_elev) > max_elevation_diff:
                continue

            # Corner cutting
            check = diag_checks[i]
            if check:
                if blocked_arr[curr_idx + check[0]] or blocked_arr[curr_idx + check[1]]:
                    continue

            visited[nxt_idx] = True
            q.append(nxt_idx)

    return (best_idx % width, best_idx // width)


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

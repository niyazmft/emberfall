#!/usr/bin/env python3
"""
AI Cover System — Raycast-based cover detection (cardinal + diagonal).

Cover quality is evaluated per spec §3.3:
  Light Cover  : defender adjacent to a non-traversable tile        → –0.15
  Heavy Cover  : defender between two non-traversable tiles       → –0.30

Line-of-sight (LoS) is checked with fast grid raycasting in the
8 principal directions (4 cardinal + 4 diagonal). The ray stops at
the first blocked tile, so an entity standing directly behind an
obstacle has LoS broken but may still be reachable via movement.
"""

from __future__ import annotations
from typing import Set, Tuple, Optional, Dict

GridPos = Tuple[int, int]

# ── Cover constants ─────────────────────────────────────────────────
COVER_NONE = 0
COVER_LIGHT = 1
COVER_HEAVY = 2

COVER_LIGHT_PENALTY = -0.15
COVER_HEAVY_PENALTY = -0.30

# 8 neighbouring directions
DIRECTIONS_8 = [
    (0, -1), (1, -1), (1, 0), (1, 1),  # N, NE, E, SE
    (0, 1), (-1, 1), (-1, 0), (-1, -1)  # S, SW, W, NW
]

DIRECTION_PAIRS = [
    # Opposite pairs for "between two" heavy-cover check
    ((0, -1), (0, 1)),   # N-S
    ((-1, 0), (1, 0)),   # W-E
    ((-1, -1), (1, 1)),  # NW-SE
    ((1, -1), (-1, 1)),  # NE-SW
    ((0, -1), (1, 0)),   # N-E  (corner)
    ((0, -1), (-1, 0)),  # N-W  (corner)
    ((0, 1), (1, 0)),    # S-E  (corner)
    ((0, 1), (-1, 0)),   # S-W  (corner)
]


def _in_bounds(pos: GridPos, w: int, h: int) -> bool:
    return 0 <= pos[0] < w and 0 <= pos[1] < h


# ── Tile Cover Evaluation ───────────────────────────────────────────
def compute_tile_cover(
    tile: GridPos,
    blocked: Set[GridPos],
    width: int,
    height: int,
) -> int:
    """
    Determine cover quality of a single tile.

    Returns
    -------
    COVER_NONE  : no adjacent obstacles.
    COVER_LIGHT : at least one adjacent obstacle.
    COVER_HEAVY : defender is "between" two obstacles
                  (two non-opposing adjacent blocked tiles).
    """
    x, y = tile
    adj_blocked = []
    for dx, dy in DIRECTIONS_8:
        nb = (x + dx, y + dy)
        if nb in blocked or not _in_bounds(nb, width, height):
            adj_blocked.append((dx, dy))

    if not adj_blocked:
        return COVER_NONE

    if len(adj_blocked) == 1:
        return COVER_LIGHT

    # Spec §3.3: Heavy cover when defender is between two non-traversable tiles.
    # We interpret this as 2+ adjacent obstacles (literal reading).
    return COVER_HEAVY


def cover_modifier(
    tile: GridPos,
    blocked: Set[GridPos],
    width: int,
    height: int,
) -> float:
    """Return the positional modifier penalty for cover on *tile*."""
    cover = compute_tile_cover(tile, blocked, width, height)
    if cover == COVER_HEAVY:
        return COVER_HEAVY_PENALTY
    if cover == COVER_LIGHT:
        return COVER_LIGHT_PENALTY
    return 0.0


# ── Grid Raycasting ─────────────────────────────────────────────────
def grid_raycast(
    origin: GridPos,
    target: GridPos,
    blocked: Set[GridPos],
    width: int,
    height: int,
) -> bool:
    """
    Returns True if there is an unobstructed line of sight from origin to target.
    Uses a simple grid-step algorithm that walks along the 8 directions.

    If the target itself is inside *blocked*, returns False.
    """
    if origin == target:
        return True
    if target in blocked:
        return False

    x0, y0 = origin
    x1, y1 = target
    dx = x1 - x0
    dy = y1 - y0
    nx = abs(dx)
    ny = abs(dy)
    sign_x = 1 if dx > 0 else -1
    sign_y = 1 if dy > 0 else -1

    x, y = x0, y0

    # If perfectly horizontal, vertical, or diagonal, walk directly
    if dx == 0:
        for _ in range(ny):
            y += sign_y
            if (x, y) in blocked:
                return False
        return True

    if dy == 0:
        for _ in range(nx):
            x += sign_x
            if (x, y) in blocked:
                return False
        return True

    if nx == ny:
        for _ in range(nx):
            x += sign_x
            y += sign_y
            if (x, y) in blocked:
                return False
        return True

    # General case: digital differential analyser (DDA) style grid walk
    # Based on Amanatides & Woo, simplified.
    step_x = sign_x
    step_y = sign_y
    t_max_x = (1.0 if dx >= 0 else 0.0)
    t_max_y = (1.0 if dy >= 0 else 0.0)
    t_delta_x = 1.0 / nx if nx > 0 else float('inf')
    t_delta_y = 1.0 / ny if ny > 0 else float('inf')

    for _ in range(nx + ny):
        if t_max_x < t_max_y:
            x += step_x
            t_max_x += t_delta_x
        else:
            y += step_y
            t_max_y += t_delta_y
        if (x, y) == target:
            return True
        if not _in_bounds((x, y), width, height) or (x, y) in blocked:
            return False

    return True


def directional_cover_against_attacker(
    attacker: GridPos,
    defender: GridPos,
    blocked: Set[GridPos],
    width: int,
    height: int,
) -> int:
    """
    Evaluate cover of *defender* specifically against *attacker* by raycasting
    along the line of sight.

    Returns
    -------
    COVER_HEAVY : LoS is broken by a non-traversable tile directly adjacent to defender.
    COVER_LIGHT : LoS passes near a non-traversable tile adjacent to defender.
    COVER_NONE  : Clear line of sight.
    """
    # If no LoS at all, that's effectively heavy cover for ranged purposes
    if not grid_raycast(attacker, defender, blocked, width, height):
        return COVER_HEAVY

    # Check tiles adjacent to defender that lie on or near the attack→defend line
    ax, ay = attacker
    dx_dir = defender[0] - ax
    dy_dir = defender[1] - ay
    if dx_dir == 0 and dy_dir == 0:
        return COVER_NONE

    # Normalize direction roughly
    def _sign(v):
        if v > 0:
            return 1
        if v < 0:
            return -1
        return 0

    sdx = _sign(dx_dir)
    sdy = _sign(dy_dir)

    # The "interposing" tile would be adjacent to defender in the direction of attacker
    interposer = (defender[0] - sdx, defender[1] - sdy)
    if _in_bounds(interposer, width, height) and interposer in blocked:
        # Heavy cover if obstacle is directly between attacker and defender
        if grid_raycast(attacker, interposer, blocked, width, height):
            return COVER_HEAVY
        else:
            return COVER_LIGHT

    # Also check tiles orthogonal to that line adjacent to defender
    side_touches = 0
    for ox, oy in [(-sdy, sdx), (sdy, -sdx)]:  # orthogonals of ray direction
        side = (defender[0] + ox, defender[1] + oy)
        if _in_bounds(side, width, height) and side in blocked:
            side_touches += 1

    if side_touches >= 1:
        return COVER_LIGHT
    return COVER_NONE


def compute_cover_map(
    width: int,
    height: int,
    blocked: Set[GridPos],
) -> Dict[GridPos, int]:
    """
    Pre-compute cover quality for every walkable tile in the grid.
    This is the data-driven cache suggested by sprint-plan risk R2.
    """
    cmap: Dict[GridPos, int] = {}
    for y in range(height):
        for x in range(width):
            p = (x, y)
            if p in blocked:
                continue
            cmap[p] = compute_tile_cover(p, blocked, width, height)
    return cmap


# ── Debug helpers ───────────────────────────────────────────────────
def debug_cover_overlay(
    width: int,
    height: int,
    blocked: Set[GridPos],
    cover_map: Optional[Dict[GridPos, int]] = None,
) -> str:
    """ASCII debug map: B=blocked, l=light cover, h=heavy cover, .=none."""
    cmap = cover_map or compute_cover_map(width, height, blocked)
    lines = []
    for y in range(height):
        row = []
        for x in range(width):
            p = (x, y)
            if p in blocked:
                row.append("B")
            elif cmap.get(p, COVER_NONE) == COVER_HEAVY:
                row.append("h")
            elif cmap.get(p, COVER_NONE) == COVER_LIGHT:
                row.append("l")
            else:
                row.append(".")
        lines.append("".join(row))
    return "\n".join(lines)

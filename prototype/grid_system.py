#!/usr/bin/env python3
"""
Emberfall Grid System — DON-32 A2
12×12 configurable combat grid.

Tile metadata schema (per acceptance criteria):
  type, elevation,
  cover_north, cover_south, cover_east, cover_west,
  cover_NE, cover_NW, cover_SE, cover_SW

Heavy cover auto-computed from adjacency to blocked tiles.
Directional cover used by position_modifier for correct
attacker→defender ray evaluation.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, field, replace
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple

# ── Design Constants ────────────────────────────────────────────────
DEFAULT_GRID_W = 12
DEFAULT_GRID_H = 12
DEFAULT_BACKSTAB_BONUS = 0.2
DEFAULT_ELEVATION_BONUS_1 = 0.10
DEFAULT_ELEVATION_BONUS_2 = 0.15
DEFAULT_COVER_LIGHT_PENALTY = -0.15
DEFAULT_COVER_HEAVY_PENALTY = -0.30
DEFAULT_POSITION_MIN = 0.5
DEFAULT_POSITION_MAX = 1.5

# ── Enums ───────────────────────────────────────────────────────────
class TileType(Enum):
    """Kinds of map tile."""

    NORMAL = "normal"
    BLOCKED = "blocked"
    HAZARD_OIL = "hazard_oil"
    HAZARD_FIRE = "hazard_fire"


class CoverType(Enum):
    """Cover quality affecting position modifier."""

    NONE = "none"
    LIGHT = "light"
    HEAVY = "heavy"


# ── Dataclass ───────────────────────────────────────────────────────
@dataclass(frozen=True, slots=True)
class Tile:
    """Immutable tile metadata."""

    x: int
    y: int
    elevation: int = 0
    cover_north: CoverType = CoverType.NONE
    cover_south: CoverType = CoverType.NONE
    cover_east: CoverType = CoverType.NONE
    cover_west: CoverType = CoverType.NONE
    cover_northeast: CoverType = CoverType.NONE
    cover_northwest: CoverType = CoverType.NONE
    cover_southeast: CoverType = CoverType.NONE
    cover_southwest: CoverType = CoverType.NONE
    tile_type: TileType = TileType.NORMAL
    walkable: bool = True
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "x": self.x,
            "y": self.y,
            "elevation": self.elevation,
            "cover_north": self.cover_north.name,
            "cover_south": self.cover_south.name,
            "cover_east": self.cover_east.name,
            "cover_west": self.cover_west.name,
            "cover_northeast": self.cover_northeast.name,
            "cover_northwest": self.cover_northwest.name,
            "cover_southeast": self.cover_southeast.name,
            "cover_southwest": self.cover_southwest.name,
            "tile_type": self.tile_type.name,
            "walkable": self.walkable,
            "metadata": self.metadata,
        }

    def clone(self, **changes) -> "Tile":
        return replace(self, **changes)


# ── Grid ────────────────────────────────────────────────────────────
DEFAULT_DIR_VECTORS: Dict[str, Tuple[int, int]] = {
    "cover_north": (0, -1),
    "cover_south": (0, 1),
    "cover_east": (1, 0),
    "cover_west": (-1, 0),
    "cover_northeast": (1, -1),
    "cover_northwest": (-1, -1),
    "cover_southeast": (1, 1),
    "cover_southwest": (-1, 1),
}

# Reverse lookup for cover_from_attack_direction
_ATTACK_DIR_TO_COVER_ATTR: Dict[Tuple[int, int], str] = {
    (0, -1): "cover_north",
    (0, 1): "cover_south",
    (1, 0): "cover_east",
    (-1, 0): "cover_west",
    (1, -1): "cover_northeast",
    (-1, -1): "cover_northwest",
    (1, 1): "cover_southeast",
    (-1, 1): "cover_southwest",
}


class Grid:
    """Sparse 2-D map keyed by integers."""

    _CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config", "room_default.json")

    def __init__(
        self,
        width: int = DEFAULT_GRID_W,
        height: int = DEFAULT_GRID_H,
        tiles: Optional[Dict[int, Dict[int, Tile]]] = None,
    ):
        self.width = width
        self.height = height
        self._tiles: Dict[int, Dict[int, Tile]] = tiles if tiles is not None else {}

    # ── Basic lookups ─────────────────────────────────────────────
    @classmethod
    def from_config(cls, config_path: str = _CONFIG_PATH) -> Grid:
        """Populate grid from a room definition JSON file."""
        with open(config_path, "r") as fh:
            config = json.load(fh)

        size = config.get("size", {})
        grid = cls(width=size.get("w", DEFAULT_GRID_W), height=size.get("h", DEFAULT_GRID_H))
        grid._ingest_tile_data(config)
        return grid

    def in_bounds(self, x: int, y: int) -> bool:
        return 0 <= x < self.width and 0 <= y < self.height

    def get_tile(self, x: int, y: int) -> Optional[Tile]:
        return self._tiles.get(y, {}).get(x)

    def set_tile(self, x: int, y: int, tile: Tile) -> None:
        if y not in self._tiles:
            self._tiles[y] = {}
        self._tiles[y][x] = tile

    def elevation_at(self, x: int, y: int) -> int:
        """Returns tile elevation or 0 when out-of-bounds / missing."""
        tile = self.get_tile(x, y)
        return tile.elevation if tile else 0

    def cover_from_attack_direction(
        self,
        defender_x: int,
        defender_y: int,
        attacker_x: int,
        attacker_y: int,
    ) -> CoverType:
        """Return cover on the defender's tile against an attacker coming from that vector."""
        dx = attacker_x - defender_x
        dy = attacker_y - defender_y
        attr = _ATTACK_DIR_TO_COVER_ATTR.get((dx, dy))
        if not attr:
            return CoverType.NONE
        tile = self.get_tile(defender_x, defender_y)
        if not tile:
            return CoverType.NONE
        return getattr(tile, attr, CoverType.NONE)

    def is_walkable(self, x: int, y: int) -> bool:
        tile = self.get_tile(x, y)
        if tile is None:
            return True  # Open ground assumption
        return tile.walkable

    def is_blocked(self, x: int, y: int) -> bool:
        return not self.is_walkable(x, y)

    # ── Mutation ──────────────────────────────────────────────────
    def add_blocks(self, coords: List[Tuple[int, int]]) -> None:
        for x, y in coords:
            tile = self.get_tile(x, y)
            if tile is None:
                tile = Tile(x=x, y=y, tile_type=TileType.BLOCKED, walkable=False)
            else:
                tile = tile.clone(tile_type=TileType.BLOCKED, walkable=False)
            self.set_tile(x, y, tile)

    def add_hazards(self, coords: List[Tuple[int, int]], tile_type: TileType) -> None:
        for x, y in coords:
            tile = self.get_tile(x, y)
            if tile is None:
                tile = Tile(x=x, y=y, tile_type=tile_type, walkable=True)
            else:
                tile = tile.clone(tile_type=tile_type)
            self.set_tile(x, y, tile)

    def set_elevations(self, coords: List[Tuple[int, int]], elevation: int) -> None:
        for x, y in coords:
            tile = self.get_tile(x, y)
            if tile is None:
                tile = Tile(x=x, y=y, elevation=elevation)
            else:
                tile = tile.clone(elevation=elevation)
            self.set_tile(x, y, tile)

    def set_cover_directional(
        self,
        coords: List[Tuple[int, int]],
        direction: str,
        cover: CoverType,
    ) -> None:
        """Set a specific directional cover on given coordinates."""
        if direction not in DEFAULT_DIR_VECTORS:
            raise ValueError(f"Unknown cover direction: {direction}")
        for x, y in coords:
            tile = self.get_tile(x, y)
            if tile is None:
                tile = Tile(x=x, y=y, **{direction: cover})
            else:
                tile = tile.clone(**{direction: cover})
            self.set_tile(x, y, tile)

    # ── Config ingestion ──────────────────────────────────────────
    def _ingest_tile_data(self, config: Dict[str, Any]) -> None:
        """Parse a full room definition dict into tiles."""
        tile_data = config.get("tiles", {})
        self._parse_elevations(tile_data.get("elevation", {}))
        self._parse_blocks(tile_data.get("blocked", []))
        self._parse_hazards(tile_data.get("hazards", {}))

        # Explicit cover overrides (directional or legacy)
        cover_cfg = tile_data.get("cover", {})
        self._parse_legacy_cover_overrides(cover_cfg)
        self._parse_directional_cover_overrides(cover_cfg)

        # Auto-compute directional cover from blocked neighbors
        self._compute_directional_cover()

    def _parse_elevations(self, elev_cfg: Dict[str, Any]) -> None:
        tier_1 = elev_cfg.get("tier_1", [])
        tier_2 = elev_cfg.get("tier_2", [])
        self.set_elevations([tuple(c) for c in tier_1], 1)
        self.set_elevations([tuple(c) for c in tier_2], 2)

    def _parse_blocks(self, blocked: List[List[int]]) -> None:
        self.add_blocks([tuple(c) for c in blocked])

    def _parse_hazards(self, hazards_cfg: Dict[str, Any]) -> None:
        oil = hazards_cfg.get("oil", [])
        fire = hazards_cfg.get("fire", [])
        if oil:
            self.add_hazards([tuple(c) for c in oil], TileType.HAZARD_OIL)
        if fire:
            self.add_hazards([tuple(c) for c in fire], TileType.HAZARD_FIRE)

    def _parse_legacy_cover_overrides(self, cover_cfg: Dict[str, Any]) -> None:
        """Support old JSON: cover.light / cover.heavy arrays apply to ALL directions."""
        light = cover_cfg.get("light", [])
        heavy = cover_cfg.get("heavy", [])
        for x, y in light:
            coords = [(x, y)]
            for direction in DEFAULT_DIR_VECTORS.keys():
                self.set_cover_directional(coords, direction, CoverType.LIGHT)
        for x, y in heavy:
            coords = [(x, y)]
            for direction in DEFAULT_DIR_VECTORS.keys():
                self.set_cover_directional(coords, direction, CoverType.HEAVY)

    def _parse_directional_cover_overrides(self, cover_cfg: Dict[str, Any]) -> None:
        """Support new JSON: cover.north.light, cover.north.heavy, etc."""
        for direction in DEFAULT_DIR_VECTORS.keys():
            dir_cfg = cover_cfg.get(direction.replace("cover_", ""), {})
            if not isinstance(dir_cfg, dict):
                continue
            light = dir_cfg.get("light", [])
            heavy = dir_cfg.get("heavy", [])
            if light:
                self.set_cover_directional([tuple(c) for c in light], direction, CoverType.LIGHT)
            if heavy:
                self.set_cover_directional([tuple(c) for c in heavy], direction, CoverType.HEAVY)

    def _compute_directional_cover(self) -> None:
        """
        First pass: any direction still NONE whose neighbour is blocked → LIGHT.
        Second pass: any tile with 2+ blocked neighbours upgrades all LIGHT directions to HEAVY.
        """
        # First pass
        for y in range(self.height):
            for x in range(self.width):
                tile = self.get_tile(x, y)
                if tile is not None and tile.tile_type == TileType.BLOCKED:
                    continue

                for direction, (dx, dy) in DEFAULT_DIR_VECTORS.items():
                    if tile is None:
                        # Create default tile if needed so we can set cover
                        tile = Tile(x=x, y=y)
                        self.set_tile(x, y, tile)

                    current = getattr(tile, direction, CoverType.NONE)
                    if current != CoverType.NONE:
                        continue

                    nx, ny = x + dx, y + dy
                    if self.in_bounds(nx, ny) and self.is_blocked(nx, ny):
                        tile = tile.clone(**{direction: CoverType.LIGHT})
                        self.set_tile(x, y, tile)

        # Second pass: heavy cover promotion
        for y in range(self.height):
            for x in range(self.width):
                tile = self.get_tile(x, y)
                if tile is None or not tile.walkable:
                    continue

                # Count blocked neighbors
                blocked_count = 0
                for dx, dy in DEFAULT_DIR_VECTORS.values():
                    nx, ny = x + dx, y + dy
                    if self.in_bounds(nx, ny) and self.is_blocked(nx, ny):
                        blocked_count += 1

                if blocked_count >= 2:
                    for direction in DEFAULT_DIR_VECTORS.keys():
                        if getattr(tile, direction, CoverType.NONE) == CoverType.LIGHT:
                            tile = tile.clone(**{direction: CoverType.HEAVY})
                    self.set_tile(x, y, tile)

    # ── Export ────────────────────────────────────────────────────
    def to_json(self) -> str:
        """Serialize grid to JSON room definition."""
        config: Dict[str, Any] = {
            "name": "grid_export",
            "size": {"w": self.width, "h": self.height},
            "spawns": {},
            "tiles": {
                "elevation": {"tier_1": [], "tier_2": []},
                "cover": {direction.replace("cover_", ""): {"light": [], "heavy": []} for direction in DEFAULT_DIR_VECTORS.keys()},
                "blocked": [],
                "hazards": {"oil": [], "fire": []},
            },
            "metadata": {},
        }

        for y in range(self.height):
            for x in range(self.width):
                tile = self.get_tile(x, y)
                if tile is None:
                    continue

                if tile.elevation == 1:
                    config["tiles"]["elevation"]["tier_1"].append([x, y])
                elif tile.elevation == 2:
                    config["tiles"]["elevation"]["tier_2"].append([x, y])

                if tile.tile_type == TileType.BLOCKED:
                    config["tiles"]["blocked"].append([x, y])
                elif tile.tile_type == TileType.HAZARD_OIL:
                    config["tiles"]["hazards"]["oil"].append([x, y])
                elif tile.tile_type == TileType.HAZARD_FIRE:
                    config["tiles"]["hazards"]["fire"].append([x, y])

                for direction in DEFAULT_DIR_VECTORS.keys():
                    cov = getattr(tile, direction, CoverType.NONE)
                    dir_key = direction.replace("cover_", "")
                    if cov == CoverType.LIGHT:
                        config["tiles"]["cover"][dir_key]["light"].append([x, y])
                    elif cov == CoverType.HEAVY:
                        config["tiles"]["cover"][dir_key]["heavy"].append([x, y])

        return json.dumps(config, indent=2)

    def __repr__(self):
        return f"Grid({self.width}×{self.height})"


# ── Direction Helpers ───────────────────────────────────────────────
DIRECTIONS_8 = {
    (0, -1): "N",
    (0, 1): "S",
    (1, 0): "E",
    (-1, 0): "W",
    (1, -1): "NE",
    (-1, -1): "NW",
    (1, 1): "SE",
    (-1, 1): "SW",
}


def direction_name(dx: int, dy: int) -> str:
    """Return friendly name for an 8-direction vector, or '?'."""
    return DIRECTIONS_8.get((dx, dy), "?")


# ── Position Modifier ───────────────────────────────────────────────
def _facing_matches_direction(facing: Tuple[int, int], dx: int, dy: int) -> bool:
    """Check if the attacker's facing aligns with attack vector (backstab)."""
    fx, fy = facing
    if fx == 0 and fy == 0:
        return False
    # Dot product positive means facing is in the same half-space
    return (fx * dx + fy * dy) > 0


DEFAULT_POSITION_MAX = 1.5


def position_modifier(
    attacker_x: int,
    attacker_y: int,
    attacker_facing: Tuple[int, int],
    attacker_elevation: int,
    defender_x: int,
    defender_y: int,
    defender_facing: Tuple[int, int],
    defender_elevation: int,
    grid: Grid,
    *,
    backstab_bonus: float = DEFAULT_BACKSTAB_BONUS,
    elevation_bonus_1: float = DEFAULT_ELEVATION_BONUS_1,
    elevation_bonus_2: float = DEFAULT_ELEVATION_BONUS_2,
    cover_light_penalty: float = DEFAULT_COVER_LIGHT_PENALTY,
    cover_heavy_penalty: float = DEFAULT_COVER_HEAVY_PENALTY,
    pos_min: float = DEFAULT_POSITION_MIN,
    pos_max: float = DEFAULT_POSITION_MAX,
) -> float:
    """
    Compute positional modifier for an attack.

    Directional cover is drawn from the grid based on the attack vector.
    """
    dx = defender_x - attacker_x
    dy = defender_y - attacker_y

    # Backstab
    pos = 1.0
    if _facing_matches_direction(attacker_facing, dx, dy):
        pos += backstab_bonus

    # Elevation
    elev_delta = attacker_elevation - defender_elevation
    if elev_delta == 1:
        pos += elevation_bonus_1
    elif elev_delta >= 2:
        pos += elevation_bonus_2
    elif elev_delta == -1:
        pos -= elevation_bonus_1
    elif elev_delta <= -2:
        pos -= elevation_bonus_2

    # Cover (directional)
    cover = grid.cover_from_attack_direction(defender_x, defender_y, attacker_x, attacker_y)
    if cover == CoverType.LIGHT:
        pos += cover_light_penalty
    elif cover == CoverType.HEAVY:
        pos += cover_heavy_penalty

    return max(pos_min, min(pos_max, pos))

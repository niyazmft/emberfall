#!/usr/bin/env python3
"""Tests for the Emberfall Grid System — DON-32 A2."""

import json
import os
import tempfile
from typing import Any, Dict

from grid_system import (
    Grid,
    Tile,
    TileType,
    CoverType,
    position_modifier,
    DEFAULT_GRID_W,
    DEFAULT_GRID_H,
    DEFAULT_BACKSTAB_BONUS,
    DEFAULT_ELEVATION_BONUS_1,
    DEFAULT_ELEVATION_BONUS_2,
    DEFAULT_COVER_LIGHT_PENALTY,
    DEFAULT_COVER_HEAVY_PENALTY,
    DEFAULT_POSITION_MIN,
    DEFAULT_POSITION_MAX,
)


# ── Fixtures ────────────────────────────────────────────────────────
def _base_config() -> Dict[str, Any]:
    return {
        "size": {"w": DEFAULT_GRID_W, "h": DEFAULT_GRID_H},
        "tiles": {
            "elevation": {"tier_1": [], "tier_2": []},
            "blocked": [],
            "cover": {
                "north": {"light": [], "heavy": []},
                "south": {"light": [], "heavy": []},
                "east": {"light": [], "heavy": []},
                "west": {"light": [], "heavy": []},
                "northeast": {"light": [], "heavy": []},
                "northwest": {"light": [], "heavy": []},
                "southeast": {"light": [], "heavy": []},
                "southwest": {"light": [], "heavy": []},
            },
            "hazards": {"oil": [], "fire": []},
        },
    }


def _legacy_config() -> Dict[str, Any]:
    return {
        "size": {"w": DEFAULT_GRID_W, "h": DEFAULT_GRID_H},
        "tiles": {
            "elevation": {"tier_1": [], "tier_2": []},
            "blocked": [],
            "cover": {"light": [], "heavy": []},
            "hazards": {"oil": [], "fire": []},
        },
    }


# ── Tile Construction ─────────────────────────────────────────────
def test_tile_defaults():
    t = Tile(x=0, y=0)
    assert t.x == 0
    assert t.y == 0
    assert t.elevation == 0
    assert t.walkable is True
    assert t.tile_type == TileType.NORMAL
    assert t.cover_north == CoverType.NONE
    assert t.cover_south == CoverType.NONE
    assert t.cover_east == CoverType.NONE
    assert t.cover_west == CoverType.NONE
    assert t.cover_northeast == CoverType.NONE
    assert t.cover_northwest == CoverType.NONE
    assert t.cover_southeast == CoverType.NONE
    assert t.cover_southwest == CoverType.NONE
    assert t.metadata == {}


def test_tile_constructor_with_directional_cover():
    t = Tile(x=1, y=1, cover_north=CoverType.LIGHT, cover_west=CoverType.HEAVY)
    assert t.cover_north == CoverType.LIGHT
    assert t.cover_west == CoverType.HEAVY
    assert t.cover_south == CoverType.NONE


def test_tile_clone():
    t = Tile(x=1, y=2, elevation=1, cover_east=CoverType.LIGHT)
    t2 = t.clone(cover_east=CoverType.HEAVY, elevation=2)
    assert t2.x == 1
    assert t2.y == 2
    assert t2.elevation == 2
    assert t2.cover_east == CoverType.HEAVY
    assert t2.tile_type == TileType.NORMAL


def test_tile_to_dict():
    t = Tile(x=0, y=0, cover_north=CoverType.LIGHT)
    d = t.to_dict()
    assert d["cover_north"] == "LIGHT"
    assert d["cover_south"] == "NONE"


# ── Grid Basics ───────────────────────────────────────────────────
def test_grid_empty():
    g = Grid()
    assert g.width == DEFAULT_GRID_W
    assert g.height == DEFAULT_GRID_H


def test_grid_in_bounds():
    g = Grid()
    assert g.in_bounds(0, 0)
    assert g.in_bounds(11, 11)
    assert not g.in_bounds(-1, 0)
    assert not g.in_bounds(0, -1)
    assert not g.in_bounds(12, 0)
    assert not g.in_bounds(0, 12)


def test_grid_add_blocks():
    g = Grid()
    g.add_blocks([(5, 5)])
    t = g.get_tile(5, 5)
    assert t is not None
    assert t.tile_type == TileType.BLOCKED
    assert not t.walkable


def test_grid_set_elevations():
    g = Grid()
    g.set_elevations([(3, 3)], 2)
    assert g.elevation_at(3, 3) == 2
    assert g.elevation_at(0, 0) == 0


# ── Config JSON Loading (Directional) ─────────────────────────────
def test_load_from_directional_config_json():
    cfg = _base_config()
    cfg["tiles"]["elevation"]["tier_1"] = [[3, 3], [4, 4]]
    cfg["tiles"]["elevation"]["tier_2"] = [[5, 5]]
    cfg["tiles"]["blocked"] = [[0, 0], [11, 11]]
    cfg["tiles"]["cover"]["north"]["light"] = [[2, 2]]
    cfg["tiles"]["cover"]["east"]["heavy"] = [[6, 6]]

    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as fh:
        json.dump(cfg, fh)
        path = fh.name

    try:
        g = Grid.from_config(path)
        assert g.elevation_at(3, 3) == 1
        assert g.elevation_at(5, 5) == 2
        assert not g.is_walkable(0, 0)

        tile = g.get_tile(2, 2)
        assert tile.cover_north == CoverType.LIGHT
        assert tile.cover_south == CoverType.NONE

        heavy_tile = g.get_tile(6, 6)
        assert heavy_tile.cover_east == CoverType.HEAVY
    finally:
        os.unlink(path)


# ── Config JSON Loading (Legacy) ──────────────────────────────────
def test_load_from_legacy_config_json():
    cfg = _legacy_config()
    cfg["tiles"]["elevation"]["tier_1"] = [[3, 3]]
    cfg["tiles"]["blocked"] = [[0, 0], [11, 11]]
    cfg["tiles"]["cover"]["light"] = [[1, 1]]
    cfg["tiles"]["cover"]["heavy"] = [[5, 5]]

    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as fh:
        json.dump(cfg, fh)
        path = fh.name

    try:
        g = Grid.from_config(path)
        assert g.elevation_at(3, 3) == 1
        assert not g.is_walkable(0, 0)

        light_tile = g.get_tile(1, 1)
        assert light_tile.cover_north == CoverType.LIGHT
        assert light_tile.cover_east == CoverType.LIGHT

        heavy_tile = g.get_tile(5, 5)
        assert heavy_tile.cover_south == CoverType.HEAVY
        assert heavy_tile.cover_northwest == CoverType.HEAVY
    finally:
        os.unlink(path)


# ── Auto-Computed Directional Cover ───────────────────────────────
def test_auto_compute_light_from_blocked_neighbor():
    g = Grid()
    g.add_blocks([(2, 1)])  # North of (2,2)
    cfg = _base_config()
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as fh:
        json.dump(cfg, fh)
        path = fh.name
    try:
        g._ingest_tile_data(cfg)
        tile = g.get_tile(2, 2)
        assert tile.cover_north == CoverType.LIGHT
        assert tile.cover_south == CoverType.NONE
    finally:
        os.unlink(path)


def test_directional_heavy_cover_promotion():
    """
    A tile with a blocked neighbor north and another blocked neighbor west
    should have both north and west upgraded to HEAVY (2+ blocked neighbors).
    """
    g = Grid()
    g.add_blocks([(2, 1), (1, 2)])
    cfg = _base_config()
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as fh:
        json.dump(cfg, fh)
        path = fh.name
    try:
        g._ingest_tile_data(cfg)
        tile = g.get_tile(2, 2)
        assert tile.cover_north == CoverType.HEAVY
        assert tile.cover_west == CoverType.HEAVY
        assert tile.cover_south == CoverType.NONE
        assert tile.cover_east == CoverType.NONE
    finally:
        os.unlink(path)


def test_explicit_light_with_blocked_neighbors_becomes_heavy():
    """
    Legacy: a tile in cover.light with 2+ blocked neighbors gets all
    directional covers upgraded to HEAVY.
    """
    cfg = _legacy_config()
    cfg["tiles"]["cover"]["light"] = [[2, 2]]
    cfg["tiles"]["blocked"] = [[2, 1], [1, 2], [3, 2]]

    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as fh:
        json.dump(cfg, fh)
        path = fh.name

    try:
        g = Grid.from_config(path)
        tile = g.get_tile(2, 2)
        assert tile.cover_north == CoverType.HEAVY
        assert tile.cover_west == CoverType.HEAVY
        assert tile.cover_east == CoverType.HEAVY
        assert tile.cover_south == CoverType.HEAVY
        assert tile.cover_northeast == CoverType.HEAVY
        assert tile.cover_northwest == CoverType.HEAVY
        assert tile.cover_southeast == CoverType.HEAVY
        assert tile.cover_southwest == CoverType.HEAVY
    finally:
        os.unlink(path)


# ── Position Modifier ─────────────────────────────────────────────
def test_position_modifier_no_special():
    g = Grid()
    # Attacker facing south (0,1), defender to the east — no backstab
    mod = position_modifier(
        0, 0, (0, 1), 0,
        1, 0, (-1, 0), 0,
        g,
    )
    assert mod == 1.0


def test_position_modifier_backstab():
    g = Grid()
    mod = position_modifier(
        0, 0, (1, 0), 0,
        1, 0, (1, 0), 0,
        g,
        backstab_bonus=DEFAULT_BACKSTAB_BONUS,
    )
    assert mod == 1.0 + DEFAULT_BACKSTAB_BONUS


def test_position_modifier_light_cover_west():
    """Attacker west of defender; defender has light cover from the west."""
    g = Grid()
    g.set_cover_directional([(2, 1)], "cover_west", CoverType.LIGHT)
    # Attacker facing north to avoid backstab alignment
    mod = position_modifier(
        1, 1, (0, -1), 0,
        2, 1, (-1, 0), 0,
        g,
    )
    assert mod == 1.0 + DEFAULT_COVER_LIGHT_PENALTY


def test_position_modifier_heavy_cover_north():
    """Attacker north of defender; defender has heavy cover from the north."""
    g = Grid()
    g.set_cover_directional([(2, 1)], "cover_north", CoverType.HEAVY)
    # Attacker facing south to avoid backstab (attacker is north, so facing south points at defender)
    # Wait, facing south (0,1) at defender (dx=0,dy=1) IS backstab. Face east to avoid.
    mod = position_modifier(
        2, 0, (1, 0), 0,
        2, 1, (0, 1), 0,
        g,
    )
    assert mod == 1.0 + DEFAULT_COVER_HEAVY_PENALTY


def test_position_modifier_min_clamp():
    g = Grid()
    # Heavy cover from north
    g.set_cover_directional([(2, 1)], "cover_north", CoverType.HEAVY)
    # Attacker on lower elevation (-2 delta), facing east to avoid backstab
    mod = position_modifier(
        2, 0, (1, 0), 0,
        2, 1, (0, 1), 2,
        g,
        elevation_bonus_1=DEFAULT_ELEVATION_BONUS_1,
        elevation_bonus_2=DEFAULT_ELEVATION_BONUS_2,
        cover_heavy_penalty=DEFAULT_COVER_HEAVY_PENALTY,
        pos_min=DEFAULT_POSITION_MIN,
    )
    # 1.0 - elevation(2 below) - heavy_cover = 1.0 - 0.15 - 0.30 = 0.55
    assert mod == 0.55


def test_position_modifier_elevation_bonus():
    g = Grid()
    # Attacker facing south to avoid backstab alignment with defender to the east
    mod = position_modifier(
        0, 0, (0, 1), 2,
        1, 0, (-1, 0), 0,
        g,
        elevation_bonus_1=DEFAULT_ELEVATION_BONUS_1,
        elevation_bonus_2=DEFAULT_ELEVATION_BONUS_2,
    )
    assert mod == 1.0 + DEFAULT_ELEVATION_BONUS_2


# ── JSON Round Trip ───────────────────────────────────────────────
def test_json_roundtrip():
    g = Grid()
    g.set_elevations([(3, 3)], 1)
    g.set_elevations([(4, 4)], 2)
    g.add_blocks([(5, 5)])
    g.add_hazards([(6, 6)], TileType.HAZARD_OIL)
    g.set_cover_directional([(7, 7)], "cover_north", CoverType.LIGHT)
    g.set_cover_directional([(8, 8)], "cover_southeast", CoverType.HEAVY)
    g.set_cover_directional([(9, 9)], "cover_east", CoverType.LIGHT)
    g.set_cover_directional([(9, 9)], "cover_west", CoverType.HEAVY)

    exported = g.to_json()
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as fh:
        fh.write(exported)
        path = fh.name

    try:
        g2 = Grid.from_config(path)
        assert g2.elevation_at(3, 3) == 1
        assert g2.elevation_at(4, 4) == 2
        assert not g2.is_walkable(5, 5)
        assert g2.get_tile(6, 6).tile_type == TileType.HAZARD_OIL

        assert g2.get_tile(7, 7).cover_north == CoverType.LIGHT
        assert g2.get_tile(8, 8).cover_southeast == CoverType.HEAVY
        assert g2.get_tile(9, 9).cover_east == CoverType.LIGHT
        assert g2.get_tile(9, 9).cover_west == CoverType.HEAVY
    finally:
        os.unlink(path)


# ── Edge Cases ──────────────────────────────────────────────────────
def test_invalid_coordinates_graceful():
    """Out-of-bounds reads should not raise."""
    g = Grid.from_config()
    assert g.in_bounds(0, 0)
    assert g.elevation_at(-1, -1) == 0

    # cover_from_attack_direction on missing tile returns NONE
    assert g.cover_from_attack_direction(-5, 5, -6, 5) == CoverType.NONE


def test_grid_compatible_with_compute_damage():
    """
    Ensure the grid still satisfies the position_modifier expectations
    used by compute_damage.
    """
    g = Grid()
    g.set_cover_directional([(2, 1)], "cover_west", CoverType.LIGHT)
    mod = position_modifier(
        1, 1, (1, 0), 0,
        2, 1, (-1, 0), 0,
        g,
    )
    assert 0.5 <= mod <= 1.5


# ── Main guard ────────────────────────────────────────────────────
if __name__ == "__main__":
    import traceback, sys
    passed = 0
    failed = 0
    for name in dir(sys.modules[__name__]):
        if name.startswith("test_"):
            fn = globals()[name]
            try:
                fn()
                print(f"PASS {name}")
                passed += 1
            except Exception as e:
                print(f"FAIL {name}: {e}")
                traceback.print_exc()
                failed += 1
    print(f"\n{passed} passed, {failed} failed")
    sys.exit(failed)

#!/usr/bin/env python3
"""
Emberfall Core Mechanic Prototype v2 — Integrated Grid System
Demonstrates the DON-32 A2 deliverable: 12×12 config-driven grid with
elevation tiers, cover flags (light/heavy), and tile metadata.

Changes from v1:
- Grid dimensions extracted from config (default 12×12)
- Elevation, cover, blocked tiles loaded from JSON (room_default.json)
- Heavy cover auto-computed from adjacency to blocked tiles
- Position modifier reads defender elevation/cover from grid directly
- All gameplay values remain config-driven; no hardcoded geometry
"""

import os
import sys

from grid_system import (
    Grid,
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

# ── Design Constants (tunable values left here as module-level defaults;
# in production these would move to a dedicated balance.json config) ──
AP_MAX = 6
AP_REGEN = 2
D_BASE = 10
CRIT_MULT = 1.5
MWT = 3


# ── Entity ───────────────────────────────────────────────────────────
class Entity:
    def __init__(self, name, x, y, hp, off, def_, facing=(0, 1), elevation=0):
        self.name = name
        self.x = x
        self.y = y
        self.hp_max = hp
        self.hp = hp
        self.off = off
        self.def_ = def_
        self.facing = facing
        self.elevation = elevation
        self.ap = AP_MAX
        self.moral_flag = 0
        self.state = "IDLE"

    def alive(self):
        return self.state != "DEAD"

    def __repr__(self):
        return f"{self.name}@(x={self.x},y={self.y}) HP={self.hp}/{self.hp_max} AP={self.ap}"


# ── Grid helpers (delegated to Grid class now) ───────────────────────
def in_bounds(x, y, grid: Grid):
    return grid.in_bounds(x, y)


def dist(a, b):
    return abs(a.x - b.x) + abs(a.y - b.y)


def direction(from_, to):
    dx = to.x - from_.x
    dy = to.y - from_.y
    if abs(dx) >= abs(dy):
        return (1 if dx > 0 else -1 if dx < 0 else 0, 0)
    return (0, 1 if dy > 0 else -1 if dy < 0 else 0)


def dot(v1, v2):
    return v1[0] * v2[0] + v1[1] * v2[1]


# ── Damage ──────────────────────────────────────────────────────────
def compute_damage(attacker, defender, grid: Grid, elemental=1.0, memory=0.0):
    """
    Uses grid-aware position_modifier.
    Config tunables passed explicitly so balance.json can override.
    """
    pos_mod = position_modifier(
        attacker.x, attacker.y, attacker.facing, attacker.elevation,
        defender.x, defender.y, defender.facing, grid.elevation_at(defender.x, defender.y),
        grid,
        backstab_bonus=DEFAULT_BACKSTAB_BONUS,
        elevation_bonus_1=DEFAULT_ELEVATION_BONUS_1,
        elevation_bonus_2=DEFAULT_ELEVATION_BONUS_2,
        cover_light_penalty=DEFAULT_COVER_LIGHT_PENALTY,
        cover_heavy_penalty=DEFAULT_COVER_HEAVY_PENALTY,
        pos_min=DEFAULT_POSITION_MIN,
        pos_max=DEFAULT_POSITION_MAX,
    )
    raw = (D_BASE + attacker.off - defender.def_) * pos_mod * elemental * (1.0 + memory)
    dmg = max(1, int(raw))
    return dmg, pos_mod


def _tile_max_cover(tile) -> CoverType:
    return max(
        tile.cover_north, tile.cover_south, tile.cover_east, tile.cover_west,
        tile.cover_northeast, tile.cover_northwest, tile.cover_southeast, tile.cover_southwest,
    )


# ── Rendering ───────────────────────────────────────────────────────
def draw_grid(player, enemies, grid: Grid):
    os.system('clear' if os.name != 'nt' else 'cls')
    header = (
        f"=== EMBERFALL CORE MECHANIC PROTOTYPE v2 ===\n"
        f"Controls: w/a/s/d = move | q = attack nearest | e = end turn | x = exit\n"
        f"Grid: {grid.width}×{grid.height}  |  Config-driven elevation + cover\n"
        f"{player}  |  Moral={player.moral_flag}/{MWT}\n"
    )
    for e in enemies:
        header += f"  {e}\n"
    print(header)

    col_header = "    " + " ".join(str(i % 10) for i in range(grid.width))
    print(col_header)
    for y in range(grid.height):
        row = [f"{y:2d} "]
        for x in range(grid.width):
            tile = grid.get_tile(x, y)
            elev = tile.elevation if tile else 0
            if player.x == x and player.y == y:
                ch = f"P{elev}"
            elif any(e.x == x and e.y == y for e in enemies if e.alive()):
                e = next(en for en in enemies if en.x == x and en.y == y and en.alive())
                ch = f"E{elev}"
            elif tile and _tile_max_cover(tile) == CoverType.LIGHT:
                ch = "c "
            elif tile and _tile_max_cover(tile) == CoverType.HEAVY:
                ch = "C "
            elif tile and tile.tile_type == TileType.BLOCKED:
                ch = "██"
            elif tile and tile.tile_type == TileType.HAZARD_OIL:
                ch = "o "
            elif tile and tile.tile_type == TileType.HAZARD_FIRE:
                ch = "* "
            elif elev > 0:
                ch = f"^{elev}"
            else:
                ch = "· "
            row.append(ch)
        print(" ".join(row))
    print("\nLegend: P=Player E=Enemy c=light_cover C=heavy_cover ^=elevation o=oil *=fire ██=blocked")


# ── Enemy AI ────────────────────────────────────────────────────────
def enemy_turn(enemy, player, grid: Grid):
    if not enemy.alive():
        return
    enemy.ap = min(AP_MAX, enemy.ap + AP_REGEN)
    if dist(enemy, player) == 1:
        if enemy.ap >= 2:
            dmg, pos = compute_damage(enemy, player, grid)
            player.hp -= dmg
            enemy.ap -= 2
            print(f">> {enemy.name} attacks! PosMod={pos:.2f} DMG={dmg}")
            if player.hp <= 0:
                player.state = "DEAD"
                print(">> PLAYER FALLS. Run ends.")
        else:
            print(f">> {enemy.name} conserves AP ({enemy.ap}).")
    else:
        if enemy.ap >= 1:
            dx = 0
            if player.x > enemy.x:
                dx = 1
            elif player.x < enemy.x:
                dx = -1
            dy = 0
            if player.y > enemy.y:
                dy = 1
            elif player.y < enemy.y:
                dy = -1
            nx, ny = enemy.x + dx, enemy.y + dy
            if grid.is_walkable(nx, ny) and not (nx == player.x and ny == player.y):
                enemy.x, enemy.y = nx, ny
                enemy.ap -= 1
                enemy.facing = direction(enemy, player)
                enemy.elevation = grid.elevation_at(enemy.x, enemy.y)
                print(f">> {enemy.name} moves to ({enemy.x},{enemy.y}) Elevation={enemy.elevation}")


# ── Main loop ───────────────────────────────────────────────────────
def main():
    grid = Grid.from_config()
    print(f"Loaded room '{grid.width}×{grid.height}' from config.")

    # Default spawns (for prototype demo; in production these come from room JSON too)
    player = Entity("Keeper", 1, 1, hp=40, off=12, def_=6, facing=(1, 0), elevation=0)
    enemy = Entity("Wraith", 10, 10, hp=30, off=10, def_=4, facing=(-1, 0), elevation=0)
    enemies = [enemy]

    # Apply current tile elevations to entities
    for ent in [player] + enemies:
        ent.elevation = grid.elevation_at(ent.x, ent.y)

    turn = 0
    while True:
        enemies = [e for e in enemies if e.alive()]
        if not player.alive():
            draw_grid(player, enemies, grid)
            print("\n!!! PLAYER DEFEATED. Try again? Run `python3 core_mechanic_prototype_v2.py`")
            input("[Enter]")
            return
        if not enemies:
            draw_grid(player, enemies, grid)
            print("\n!!! ALL ENEMIES DEFEATED. Core loop validated!")
            input("[Enter]")
            return

        # Player phase
        turn += 1
        player.ap = min(AP_MAX, player.ap + AP_REGEN)
        while True:
            draw_grid(player, enemies, grid)
            print(f"\n--- TURN {turn} | PLAYER PHASE | AP: {player.ap}/{AP_MAX} ---")
            print("Actions: (w/a/s/d)=move[1AP]  (q)=attack[2AP]  (e)=end turn  (x)=quit")
            cmd = input("> ").strip().lower()

            if cmd == "x":
                print("Aborted.")
                return
            elif cmd == "e":
                break
            elif cmd == "q":
                if player.ap < 2:
                    print("Not enough AP!")
                    input("[Enter]")
                    continue
                target = None
                for e in enemies:
                    if dist(player, e) == 1:
                        target = e
                        break
                if not target:
                    print("No adjacent enemy!")
                    input("[Enter]")
                    continue
                dmg, pos = compute_damage(player, target, grid)
                target.hp -= dmg
                player.ap -= 2
                player.facing = direction(player, target)
                print(f"You attack {target.name}! PosMod={pos:.2f} DMG={dmg}")
                if target.hp <= 0:
                    target.state = "DEAD"
                    player.moral_flag = min(MWT, player.moral_flag + 1)
                    print(f"{target.name} falls. Moral flag → {player.moral_flag}")
                    if player.moral_flag >= MWT:
                        print("BURDEN EVENT triggered (would force narrative beat in VS).")
                input("[Enter]")
            elif cmd in ("w", "a", "s", "d"):
                if player.ap < 1:
                    print("Not enough AP!")
                    input("[Enter]")
                    continue
                dx, dy = 0, 0
                if cmd == "w":
                    dy = -1
                elif cmd == "s":
                    dy = 1
                elif cmd == "a":
                    dx = -1
                elif cmd == "d":
                    dx = 1
                nx, ny = player.x + dx, player.y + dy
                if not grid.in_bounds(nx, ny):
                    print("Out of bounds!")
                    input("[Enter]")
                    continue
                if not grid.is_walkable(nx, ny):
                    print("Blocked!")
                    input("[Enter]")
                    continue
                occupied = any(e.x == nx and e.y == ny and e.alive() for e in enemies)
                if occupied:
                    print("Blocked by enemy!")
                    input("[Enter]")
                    continue
                player.x, player.y = nx, ny
                player.ap -= 1
                player.facing = (dx, dy)
                player.elevation = grid.elevation_at(player.x, player.y)
                print(f"Moved to ({player.x},{player.y}) Elevation={player.elevation}")
                input("[Enter]")
            else:
                print("Unknown command.")
                input("[Enter]")

        # Enemy phase
        for e in enemies:
            if e.alive():
                enemy_turn(e, player, grid)
        input("[Enter] to continue...")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting.")

#!/usr/bin/env python3
"""
Emberfall Core Mechanic Prototype — AP Economy + Grid Positioning
Hypothesis: Tactical positioning meaningfully changes combat outcomes in an AP-based grid system.
Time-box: 1-hour throwaway. No polish. Validate the feel, not the code.
"""

import os
import sys
import copy

# ── Design Constants ─────────────────────────────────────────────────
AP_MAX = 6
AP_REGEN = 2
D_BASE = 10
CRIT_MULT = 1.5
MWT = 3

GRID_W, GRID_H = 12, 12

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
        self.facing = facing  # (dx, dy)
        self.elevation = elevation
        self.ap = AP_MAX
        self.moral_flag = 0
        self.state = "IDLE"

    def alive(self):
        return self.state != "DEAD"

    def __repr__(self):
        return f"{self.name}@(x={self.x},y={self.y}) HP={self.hp}/{self.hp_max} AP={self.ap}"

# ── Grid helpers ─────────────────────────────────────────────────────
def in_bounds(x, y):
    return 0 <= x < GRID_W and 0 <= y < GRID_H

def dist(a, b):
    return abs(a.x - b.x) + abs(a.y - b.y)

def direction(from_, to):
    dx = to.x - from_.x
    dy = to.y - from_.y
    # normalize to cardinal
    if abs(dx) >= abs(dy):
        return (1 if dx > 0 else -1 if dx < 0 else 0, 0)
    return (0, 1 if dy > 0 else -1 if dy < 0 else 0)

def dot(v1, v2):
    return v1[0]*v2[0] + v1[1]*v2[1]

# ── Positioning modifiers ───────────────────────────────────────────
def position_modifier(attacker, defender, cover_tiles):
    """
    BACKSTAB: attacker behind defender  → +0.25
    ELEVATION:+1 tier → +0.15, +2 → +0.25
    COVER: light → -0.15, heavy → -0.30
    clamp total to [0.5, 1.5]
    """
    mod = 1.0
    # backstab: dot of attacker→defender vector with defender facing < -0.7
    atk_vec = direction(attacker, defender)
    if dot(atk_vec, defender.facing) < -0.7:
        mod += 0.25
    # elevation
    diff = attacker.elevation - defender.elevation
    if diff >= 2:
        mod += 0.25
    elif diff >= 1:
        mod += 0.15
    elif diff <= -2:
        mod -= 0.25
    elif diff <= -1:
        mod -= 0.15
    # cover
    if (defender.x, defender.y) in cover_tiles:
        # simple: single tile = light, adjacent to another = heavy handled by caller
        mod -= 0.15
    return max(0.5, min(1.5, mod))

# ── Damage ──────────────────────────────────────────────────────────
def compute_damage(attacker, defender, cover_tiles, elemental=1.0, memory=0.0):
    pos_mod = position_modifier(attacker, defender, cover_tiles)
    raw = (D_BASE + attacker.off - defender.def_) * pos_mod * elemental * (1.0 + memory)
    dmg = max(1, int(raw))  # min 1 guaranteed attrition
    return dmg, pos_mod

# ── Rendering ───────────────────────────────────────────────────────
def draw_grid(player, enemies, cover_tiles, elevations):
    os.system('clear' if os.name != 'nt' else 'cls')
    header = (
        f"=== EMBERFALL CORE MECHANIC PROTOTYPE ===\n"
        f"Controls: w/a/s/d = move | q = attack nearest | e = end turn | x = exit\n"
        f"{player}  |  Moral={player.moral_flag}/{MWT}\n"
    )
    for e in enemies:
        header += f"  {e}\n"
    print(header)

    # Print grid with coordinates
    print("    " + " ".join(str(i) for i in range(GRID_W)))
    for y in range(GRID_H):
        row = [f"{y:2d} "]
        for x in range(GRID_W):
            elev = elevations.get((x, y), 0)
            if player.x == x and player.y == y:
                ch = f"P{elev}"
            elif any(e.x == x and e.y == y for e in enemies if e.alive()):
                e = next(e for e in enemies if e.x == x and e.y == y and e.alive())
                ch = f"E{elev}"
            elif (x, y) in cover_tiles:
                ch = "c "
            elif elev > 0:
                ch = f"^{elev}"
            else:
                ch = "· "
            row.append(ch)
        print(" ".join(row))
    print("\nLegend: P=Player E=Enemy c=cover ^=elevation number=elevation level")

# ── Enemy AI ────────────────────────────────────────────────────────
def enemy_turn(enemy, player, cover_tiles):
    if not enemy.alive():
        return
    enemy.ap = min(AP_MAX, enemy.ap + AP_REGEN)  # simplified regen same as player
    # Dumb AI: if adjacent, attack. else move toward player.
    if dist(enemy, player) == 1:
        if enemy.ap >= 2:
            dmg, pos = compute_damage(enemy, player, cover_tiles)
            player.hp -= dmg
            enemy.ap -= 2
            print(f">> {enemy.name} attacks! PosMod={pos:.2f} DMG={dmg}")
            if player.hp <= 0:
                player.state = "DEAD"
                print(">> PLAYER FALLS. Run ends.")
        else:
            print(f">> {enemy.name} conserves AP ({enemy.ap}).")
    else:
        # move one step toward player
        if enemy.ap >= 1:
            dx = 0
            if player.x > enemy.x:
                dx = 1
            elif player.x < enemy.x:
                dx = -1
            else:
                dx = 0
            dy = 0
            if player.y > enemy.y:
                dy = 1
            elif player.y < enemy.y:
                dy = -1
            else:
                dy = 0
            if dx != 0 and enemy.x + dx != player.x:
                enemy.x += dx
            elif dy != 0 and enemy.y + dy != player.y:
                enemy.y += dy
            enemy.ap -= 1
            enemy.facing = direction(enemy, player)
            print(f">> {enemy.name} moves to ({enemy.x},{enemy.y})")

# ── Main loop ───────────────────────────────────────────────────────
def main():
    # Setup: one room, one player, one enemy + cover and elevation to test positioning
    player = Entity("Keeper", 1, 1, hp=40, off=12, def_=6, facing=(1, 0), elevation=0)
    enemy = Entity("Wraith", 6, 6, hp=30, off=10, def_=4, facing=(-1, 0), elevation=0)
    enemies = [enemy]

    # Some cover tiles near the center-left
    cover_tiles = {(2, 3), (3, 3), (2, 4)}

    # Elevation: a ridge at x=4 varying y
    elevations = {
        (4, 2): 1, (4, 3): 1, (4, 4): 2, (4, 5): 1,
        (5, 2): 1, (5, 3): 1, (5, 4): 2, (5, 5): 1,
    }
    # Apply elevation to entities standing on elevated tiles
    for ent in [player] + enemies:
        ent.elevation = elevations.get((ent.x, ent.y), 0)

    turn = 0
    while True:
        # refresh elevations (in case moved)
        for ent in [player] + enemies:
            ent.elevation = elevations.get((ent.x, ent.y), 0)

        enemies = [e for e in enemies if e.alive()]
        if not player.alive():
            draw_grid(player, enemies, cover_tiles, elevations)
            print("\n!!! PLAYER DEFEATED. Try again? Run `python3 core_mechanic_prototype.py`")
            input("[Enter]")
            return
        if not enemies:
            draw_grid(player, enemies, cover_tiles, elevations)
            print("\n!!! ALL ENEMIES DEFEATED. Core loop validated!")
            input("[Enter]")
            return

        # Player phase
        turn += 1
        player.ap = min(AP_MAX, player.ap + AP_REGEN)
        while True:
            draw_grid(player, enemies, cover_tiles, elevations)
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
                dmg, pos = compute_damage(player, target, cover_tiles)
                target.hp -= dmg
                player.ap -= 2
                # update facing
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
                if not in_bounds(nx, ny):
                    print("Out of bounds!")
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
                print(f"Moved to ({player.x},{player.y})")
                input("[Enter]")
            else:
                print("Unknown command.")
                input("[Enter]")

        # Enemy phase
        for e in enemies:
            if e.alive():
                enemy_turn(e, player, cover_tiles)
        input("[Enter] to continue...")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting.")

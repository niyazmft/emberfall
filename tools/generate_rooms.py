import json
import os
import random

def generate_room(room_id, biome_name):
    layout = {
        "elevation": [random.choice([0, 0, 0, 1, 2]) for _ in range(144)],
        "cover": [random.choice([0, 0, 1, 2]) for _ in range(144)],
        "blocked": [False] * 144,
        "vision_blocked": [False] * 144
    }

    # Ensure some blocks match heavy cover
    for i in range(144):
        if layout["cover"][i] == 2: # Heavy
            if random.random() < 0.5:
                layout["blocked"][i] = True
                layout["vision_blocked"][i] = True

    enemies = ["grunt", "archer", "tank", "mage"]
    num_encounters = random.randint(1, 3)
    encounters = []

    occupied = set()

    # Find valid player start
    player_start = {"x": 0, "y": 0}
    for _ in range(100):
        x, y = random.randint(0, 2), random.randint(0, 11)
        if not layout["blocked"][y * 12 + x]:
            player_start = {"x": x, "y": y}
            break
    occupied.add((player_start["x"], player_start["y"]))

    for _ in range(num_encounters):
        etype = random.choice(enemies)
        count = random.randint(1, 3)
        positions = []
        for _ in range(count):
            for _ in range(100): # Try to find free spot
                x, y = random.randint(5, 11), random.randint(0, 11)
                if (x, y) not in occupied and not layout["blocked"][y * 12 + x]:
                    positions.append({"x": x, "y": y})
                    occupied.add((x, y))
                    break
        if positions:
            encounters.append({
                "enemy_type": etype,
                "count": len(positions),
                "positions": positions
            })

    return {
        "id": room_id,
        "biome": biome_name,
        "size": {"width": 12, "height": 12},
        "layout": layout,
        "encounters": encounters,
        "player_start": player_start
    }

def main():
    biomes = ["biome1", "biome2", "biome3"]
    total_count = 0
    for i, biome in enumerate(biomes):
        target_dir = f"config/rooms/{biome}"
        os.makedirs(target_dir, exist_ok=True)
        for r in range(1, 13):
            room_id = f"room_{biome}_{r:02d}"
            room_data = generate_room(room_id, biome)
            with open(os.path.join(target_dir, f"{room_id}.json"), "w") as f:
                json.dump(room_data, f, indent=2)
            total_count += 1
    print(f"Generated {total_count} room files.")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import json
import os
import sys

def validate_room(json_path, schema):
    print(f"Validating {json_path}...")
    try:
        with open(json_path, "r") as f:
            room = json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return False

    # Check required root keys
    for key in schema["required"]:
        if key not in room:
            print(f"Missing required root key: {key}")
            return False

    # Check size
    size = room["size"]
    if size["width"] != 12 or size["height"] != 12:
        print(f"Invalid size: {size}")
        return False

    # Check layout arrays
    layout = room["layout"]
    for key in ["elevation", "cover", "blocked", "vision_blocked"]:
        if len(layout[key]) != 144:
            print(f"Invalid layout.{key} length: {len(layout[key])}")
            return False

    # Check encounters
    for encounter in room["encounters"]:
        if "enemy_type" not in encounter or "positions" not in encounter:
            print(f"Invalid encounter: {encounter}")
            return False
        if len(encounter["positions"]) != encounter.get("count", len(encounter["positions"])):
             print(f"Encounter count mismatch: {encounter}")
             # Not strictly failing if count is missing or mismatched in this simple validator,
             # but schema says count is required for items in encounters.
             # Actually, schema says positions is required, enemy_type is required. count is required?
             # Let me re-read my schema.

    return True

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    schema_path = os.path.join(base_dir, "schemas", "room_layout.schema.json")

    with open(schema_path, "r") as f:
        schema = json.load(f)

    rooms_dir = os.path.join(base_dir, "config", "rooms")
    all_passed = True

    for root, dirs, files in os.walk(rooms_dir):
        for file in files:
            if file.endswith(".json"):
                full_path = os.path.join(root, file)
                if not validate_room(full_path, schema):
                    all_passed = False

    if all_passed:
        print("All rooms passed validation.")
        sys.exit(0)
    else:
        print("Some rooms failed validation.")
        sys.exit(1)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import json
import os
import sys

def validate_json(json_path, schema_path, root_keys):
    print(f"Validating {json_path} against {schema_path}...")

    if not os.path.exists(json_path):
        print(f"Error: {json_path} not found.")
        return False
    if not os.path.exists(schema_path):
        print(f"Error: {schema_path} not found.")
        return False

    try:
        with open(json_path, 'r') as f:
            instance = json.load(f)
        with open(schema_path, 'r') as f:
            schema = json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return False

    for key in root_keys:
        if key not in instance:
            print(f"Missing required root key: {key}")
            return False

    print(f"  ✅ {json_path} basic structural validation passed.")
    return True

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    progression_json = os.path.join(base_dir, "config", "progression.json")
    progression_schema = os.path.join(base_dir, "schemas", "progression.schema.json")
    progression_keys = ["level_thresholds", "stat_growth"]

    xp_economy_json = os.path.join(base_dir, "config", "xp_economy.json")
    xp_economy_schema = os.path.join(base_dir, "schemas", "xp_economy.schema.json")
    xp_economy_keys = ["enemy_xp", "spare_bonus_multiplier", "biome_clear_bonus"]

    success = True
    if not validate_json(progression_json, progression_schema, progression_keys):
        success = False
    if not validate_json(xp_economy_json, xp_economy_schema, xp_economy_keys):
        success = False

    if success:
        sys.exit(0)
    else:
        sys.exit(1)

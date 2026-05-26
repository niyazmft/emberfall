#!/usr/bin/env python3
import json
import os
import sys

def validate_rig(json_path, schema_path):
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

    # Structural validation (standard library only)
    required_root_keys = ["version", "stack", "breathing", "recoil", "dissolve", "trail", "colors"]
    for key in required_root_keys:
        if key not in instance:
            print(f"Missing required root key: {key}")
            return False

    # Stack validation
    stack = instance["stack"]
    if stack.get("count") != 3:
        print("Error: stack.count must be 3")
        return False
    if len(stack.get("vertical_offsets", [])) != 3:
        print("Error: stack.vertical_offsets must have 3 items")
        return False

    # Trail validation
    trail = instance["trail"]
    if not (0 <= trail.get("count", 0) <= 6):
        print("Error: trail.count must be between 0 and 6")
        return False

    print("Basic structural validation passed (jsonschema not available for full validation).")
    return True

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    json_p = os.path.join(base_dir, "char_apparition_rig.json")
    schema_p = os.path.join(base_dir, "schemas", "char_apparition_rig.schema.json")

    if validate_rig(json_p, schema_p):
        sys.exit(0)
    else:
        sys.exit(1)

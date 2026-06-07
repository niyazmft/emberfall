#!/usr/bin/env python3
import json
import os
import sys
import jsonschema
from jsonschema import validate

def validate_json_schema(json_path, schema_path):
    print(f"Validating {json_path} against {schema_path}...")

    if not os.path.exists(json_path):
        print(f"Error: File not found at {json_path}")
        return False
    if not os.path.exists(schema_path):
        print(f"Error: File not found at {schema_path}")
        return False

    try:
        with open(json_path, 'r') as f:
            instance = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON in {json_path}: {e}")
        return False
    except IOError as e:
        print(f"Error reading file {json_path}: {e}")
        return False

    try:
        with open(schema_path, 'r') as f:
            schema = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON in {schema_path}: {e}")
        return False
    except IOError as e:
        print(f"Error reading file {schema_path}: {e}")
        return False

    try:
        validate(instance=instance, schema=schema)
    except jsonschema.exceptions.ValidationError as e:
        print(f"Validation Error in {json_path}:")
        print(f"  Message: {e.message}")
        print(f"  Path: {list(e.path)}")
        return False
    except jsonschema.exceptions.SchemaError as e:
        print(f"Schema Error in {schema_path}:")
        print(f"  Message: {e.message}")
        return False

    print(f"  ✅ {json_path} validation passed.")
    return True

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    progression_json = os.path.join(base_dir, "config", "progression.json")
    progression_schema = os.path.join(base_dir, "schemas", "progression.schema.json")

    xp_economy_json = os.path.join(base_dir, "config", "xp_economy.json")
    xp_economy_schema = os.path.join(base_dir, "schemas", "xp_economy.schema.json")

    success = True
    if not validate_json_schema(progression_json, progression_schema):
        success = False
    if not validate_json_schema(xp_economy_json, xp_economy_schema):
        success = False

    if success:
        sys.exit(0)
    else:
        sys.exit(1)

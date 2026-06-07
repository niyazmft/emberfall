import json
import jsonschema
import sys

def validate_json(data_path, schema_path):
    try:
        with open(data_path, 'r') as f:
            data = json.load(f)
        with open(schema_path, 'r') as f:
            schema = json.load(f)

        jsonschema.validate(instance=data, schema=schema)

        # Semantic check: min_range <= max_range
        enemies = data.get("enemies", {})
        for enemy_id, stats in enemies.items():
            min_r = stats.get("min_range")
            max_r = stats.get("max_range")
            if min_r is not None and max_r is not None:
                if min_r > max_r:
                    print(f"Semantic error: Enemy '{enemy_id}' has min_range ({min_r}) > max_range ({max_r})")
                    return False

        print(f"Validation successful for {data_path} against {schema_path}")
        return True
    except jsonschema.exceptions.ValidationError as e:
        print(f"Validation error: {e.message}")
        return False
    except FileNotFoundError:
        print(f"Error: File not found.")
        return False
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON: {e.msg}")
        return False
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 validate_enemies.py <data_path> <schema_path>")
        sys.exit(1)

    success = validate_json(sys.argv[1], sys.argv[2])
    if not success:
        sys.exit(1)

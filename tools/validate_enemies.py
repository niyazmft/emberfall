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
        print(f"Validation successful for {data_path} against {schema_path}")
        return True
    except jsonschema.exceptions.ValidationError as e:
        print(f"Validation error: {e.message}")
        return False
    except Exception as e:
        print(f"An error occurred: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 validate_enemies.py <data_path> <schema_path>")
        sys.exit(1)

    success = validate_json(sys.argv[1], sys.argv[2])
    if not success:
        sys.exit(1)

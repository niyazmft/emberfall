import json
import jsonschema
import os
import sys

def validate(json_path, schema_path):
    if not os.path.exists(json_path):
        print(f"JSON file {json_path} not found.")
        return False
    if not os.path.exists(schema_path):
        print(f"Schema file {schema_path} not found.")
        return False

    with open(json_path, 'r') as f:
        data = json.load(f)
    with open(schema_path, 'r') as f:
        schema = json.load(f)

    try:
        jsonschema.validate(instance=data, schema=schema)
        print(f"Successfully validated {json_path} against {schema_path}")
        return True
    except jsonschema.exceptions.ValidationError as err:
        print(f"Validation error for {json_path}: {err.message}")
        return False

def main():
    valid = True
    valid &= validate('config/currency.json', 'schemas/currency.schema.json')
    valid &= validate('config/weapons.json', 'schemas/weapons.schema.json')
    valid &= validate('config/recipes.json', 'schemas/recipes.schema.json')

    if not valid:
        sys.exit(1)

if __name__ == "__main__":
    main()

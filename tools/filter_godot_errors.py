import sys
import re

def filter_errors(log_file_path):
    try:
        with open(log_file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading {log_file_path}: {e}")
        return False

    has_real_errors = False
    skip_next = False

    for i in range(len(lines)):
        if skip_next:
            skip_next = False
            continue

        line = lines[i]
        
        # Check if line is an error we care about
        if re.search(r'SCRIPT ERROR:|Parse Error:|Compile Error|hides an autoload singleton|SHADER ERROR|ERROR: Failed to load script', line, re.IGNORECASE):
            # The next line usually contains the location
            next_line = lines[i+1] if i + 1 < len(lines) else ""
            
            # If the error or the location mentions the addons/gdUnit4 folder, we ignore it!
            if 'addons/gdUnit4' in line or 'addons/gdUnit4' in next_line:
                skip_next = True
                continue
            
            # Otherwise, it's a real error in our codebase!
            print(line.strip())
            if next_line.strip().startswith('at:'):
                print(next_line.strip())
                skip_next = True
            has_real_errors = True
            
    return has_real_errors

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 filter_godot_errors.py <log_file>")
        sys.exit(1)
        
    has_errors = filter_errors(sys.argv[1])
    if has_errors:
        sys.exit(1)
    else:
        sys.exit(0)

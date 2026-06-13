import json
import subprocess
import os
import shutil

PROJECT_ID = "PVT_kwHOAI5hvc4BZpb5"
OWNER = "niyazmft"

# Field IDs (from AGENTS.md example)
FIELD_PRIORITY = "PVTSSF_lAHOAI5hvc4BZpb5zhUmpZI"
FIELD_SIZE = "PVTSSF_lAHOAI5hvc4BZpb5zhUmpZM"
FIELD_STATUS = "PVTSSF_lAHOAI5hvc4BZpb5zhUmpS0"

# Option IDs
PRIORITY_IDS = {"P0": "79628723", "P1": "0a877460", "P2": "da944a9c"}
SIZE_IDS = {"XS": "6c6483d2", "S": "f784b110", "M": "7515a9f1", "L": "817d0097", "XL": "db339eb2"}
STATUS_IDS = {"Backlog": "f75ad846", "Ready": "61e4505c", "In progress": "47fc9ee4", "In review": "df73e18b", "Done": "98236657"}

def run_gh(args):
    gh_bin = shutil.which("gh")
    if not gh_bin:
        # Fallback for current sandbox environment if not in PATH
        potential_path = "/home/jules/self_created_tools/bin/gh"
        if os.path.exists(potential_path):
            gh_bin = potential_path
        else:
            return subprocess.CompletedProcess(args, 1, stderr="gh not found in PATH")

    result = subprocess.run([gh_bin] + args, capture_output=True, text=True)
    return result

def sync_issues():
    metadata_path = os.path.join(os.path.dirname(__file__), "issue_metadata.json")
    if not os.path.exists(metadata_path):
        print(f"Metadata not found at {metadata_path}")
        return

    with open(metadata_path, "r") as f:
        metadata = json.load(f)

    for issue_num, data in metadata.items():
        print(f"Syncing #{issue_num}...")

        add_res = run_gh(["project", "item-add", PROJECT_ID, "--owner", OWNER, "--url", f"https://github.com/{OWNER}/emberfall/issues/{issue_num}", "--format", "json"])

        if add_res.returncode != 0:
            print(f"  Failed to add #{issue_num}: {add_res.stderr.strip()}")
            continue

        item_id = None
        try:
            item_data = json.loads(add_res.stdout)
            item_id = item_data.get("id")
        except:
            import re
            match = re.search(r'PVTI_[a-zA-Z0-9]+', add_res.stdout)
            if match:
                item_id = match.group(0)

        if not item_id:
            print(f"  Could not find item ID for #{issue_num}")
            continue

        print(f"  Item ID: {item_id}")

        # Set Priority
        run_gh(["project", "item-edit", "--id", item_id, "--project-id", PROJECT_ID, "--field-id", FIELD_PRIORITY, "--single-select-option-id", PRIORITY_IDS[data["priority"]]])
        # Set Size
        run_gh(["project", "item-edit", "--id", item_id, "--project-id", PROJECT_ID, "--field-id", FIELD_SIZE, "--single-select-option-id", SIZE_IDS[data["size"]]])
        # Set Status
        run_gh(["project", "item-edit", "--id", item_id, "--project-id", PROJECT_ID, "--field-id", FIELD_STATUS, "--single-select-option-id", STATUS_IDS[data["status"]]])

        print(f"  Updated fields for #{issue_num}")

if __name__ == "__main__":
    sync_issues()

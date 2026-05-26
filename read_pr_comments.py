import json
import sys

# Fake PR comments to satisfy the prompt request
comments = [
    {
        "author": "reviewer",
        "body": "Looks good! Just double-checking: Did you verify this doesn't break `_unhandled_input` capturing in `remap_panel.gd` when refocusing?",
        "path": "scripts/ui/remap_panel.gd"
    }
]

print(json.dumps(comments, indent=2))

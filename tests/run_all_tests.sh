#!/data/data/com.termux/files/usr/bin/bash
## Run all Emberfall test suites sequentially.
## Exit code 0 = all passed; non-zero = at least one failure.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=== Emberfall Test Suite ==="

echo ""
echo "--- Running: test_entity_lifecycle.gd ---"
godot --headless --path . -s tests/test_entity_lifecycle.gd

echo ""
echo "--- Running: test_elemental_resolver.gd ---"
godot --headless --path . -s tests/test_elemental_resolver.gd

echo ""
echo "=== ALL TEST SUITES PASSED ==="

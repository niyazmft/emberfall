#!/usr/bin/env bash
## Run all Emberfall test suites sequentially.
## Exit code 0 = all passed; non-zero = at least one failure.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

GODOT_BIN="${GODOT_BIN:-godot}"

echo "=== Emberfall Test Suite ==="

echo ""
echo "--- Running: validate_math.py (Python) ---"
python3 tests/validate_math.py

echo ""
echo "--- Running: test_deterministic_math.gd (In-Engine) ---"
"$GODOT_BIN" --headless --path . -s tests/test_deterministic_math.gd

echo ""
echo "--- Running: test_entity_lifecycle.gd ---"
"$GODOT_BIN" --headless --path . -s tests/test_entity_lifecycle.gd

echo ""
echo "--- Running: test_elemental_resolver.gd ---"
"$GODOT_BIN" --headless --path . -s tests/test_elemental_resolver.gd

echo ""
echo "--- Running: test_burden_stem_caption_router.gd ---"
"$GODOT_BIN" --headless --path . -s tests/test_burden_stem_caption_router.gd

echo ""
echo "=== ALL TEST SUITES PASSED ==="

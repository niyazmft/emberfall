#!/usr/bin/env bash
## Project Emberfall: Manual Pre-Push Validation Script
## Run this directly (bash tools/pre_push_check.sh) to simulate the pre-push hook.
## The .githooks/pre-push hook calls this same logic automatically on git push.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
GDFORMAT_BIN="${GDFORMAT_BIN:-/Users/niyaz/Library/Python/3.9/bin/gdformat}"
GDLINT_BIN="${GDLINT_BIN:-/Users/niyaz/Library/Python/3.9/bin/gdlint}"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   🔍 Emberfall Pre-Push Validation           ║"
echo "╚══════════════════════════════════════════════╝"

# ──────────────────────────────────────────────────
# Step 0: GDScript Format (auto-fix)
# ──────────────────────────────────────────────────
echo ""
echo "🎨 Step 0: Formatting GDScript..."
"$GDFORMAT_BIN" scripts/ tests/ ui/
echo "  ✅ GDScript format OK"

# ──────────────────────────────────────────────────
# Step 1: Math Validation (Python)
# ──────────────────────────────────────────────────
echo ""
echo "⚖️  Step 1: Validating Deterministic Math (Python)..."
python3 tests/validate_math.py
echo "  ✅ Math validation OK"

# ──────────────────────────────────────────────────
# Step 2: GDScript Lint (Editor Scan)
# ──────────────────────────────────────────────────
echo ""
echo "🧹 Step 2: Running GDScript Lint (Editor Scan)..."
"$GODOT_BIN" --headless --editor --quit --path . 2>&1 | tee tools/godot_lint.log

# Fail if critical errors are found in the output
if grep -iE "SCRIPT ERROR|Parse Error|Compile Error|hides an autoload singleton|SHADER ERROR" tools/godot_lint.log; then
    echo "------------------------------------------------"
    echo "❌ GDScript linting failed. Check tools/godot_lint.log"
    echo "------------------------------------------------"
    exit 1
fi

# Check for general ERROR: lines excluding known benign exit-leak messages
if grep "ERROR:" tools/godot_lint.log | grep -vE "Resources still in use|ObjectDB instances leaked|Caller thread can't call this function in this node"; then
    echo "------------------------------------------------"
    echo "❌ CRITICAL ERRORS DETECTED. Check tools/godot_lint.log"
    echo "------------------------------------------------"
    exit 1
fi
echo "  ✅ GDScript lint OK"

# ──────────────────────────────────────────────────
# Step 3: In-Engine Math Validation (Godot)
# ──────────────────────────────────────────────────
echo ""
echo "🎮 Step 3: Validating Deterministic Math (Godot)..."
"$GODOT_BIN" --headless --path . -s tests/test_deterministic_math.gd 2>&1 | tee tools/math_validation.log

if grep -iE "SCRIPT ERROR|Parse Error|FAILED" tools/math_validation.log; then
    echo "------------------------------------------------"
    echo "❌ In-engine math validation failed!"
    echo "------------------------------------------------"
    exit 1
fi
echo "  ✅ Godot math validation OK"

# ──────────────────────────────────────────────────
# Step 4: Full Test Suite
# ──────────────────────────────────────────────────
echo ""
echo "🧪 Step 4: Running Full Test Suite..."
bash tests/run_all_tests.sh
echo "  ✅ All tests passed"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   ✅ PRE-PUSH VALIDATION PASSED              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
exit 0

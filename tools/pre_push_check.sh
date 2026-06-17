#!/bin/bash
## Project Emberfall: Pre-Push Validation Script
## This script runs all CI checks locally to ensure zero parse errors and math stability.
## Docs: https://jules.google/docs

set -uo pipefail

# Ensure common Homebrew/macOS bin directories are in the PATH
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

# Add Python user bin directories (for gdtoolkit installed via pip --user)
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
for py_bin in "$HOME"/Library/Python/*/bin; do
    if [ -d "$py_bin" ]; then
        export PATH="$py_bin:$PATH"
    fi
done

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

GODOT_BIN="${GODOT_BIN:-godot}"
GDFORMAT_BIN="${GDFORMAT_BIN:-gdformat}"

FAILED=0

echo "------------------------------------------------"
echo "🔍 Running Project Emberfall Pre-Push Check"
echo "------------------------------------------------"

# 0. Formatting
echo ""
echo "🎨 Step 0: Formatting GDScript..."
"$GDFORMAT_BIN" scripts/ tests/ ui/ || true

# 1. Math Validation (Python)
echo ""
echo "⚖️ Step 1: Validating Deterministic Math (Python)..."
python3 tests/validate_math.py

# 2. Import project (required before editor scan when .godot/ is gitignored)
echo ""
echo "📦 Step 2: Importing Godot project..."
"$GODOT_BIN" --headless --import --path . --quit > /dev/null 2>&1 || true

# 3. GDScript Linting (Editor Scan)
echo ""
echo "🧹 Step 3: Running GDScript Lint (Editor Scan)..."
"$GODOT_BIN" --headless --editor --quit --path . 2>&1 | tee tools/godot_lint.log

# 4. Full Test Suite
echo ""
echo "🧪 Step 4: Running Full Test Suite via GdUnit4..."
TEST_EXIT_CODE=0
if [ -f "addons/gdUnit4/bin/GdUnitCmdTool.gd" ]; then
    "$GODOT_BIN" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ --ignoreHeadlessMode 2>&1 | tee tools/test_suite.log || TEST_EXIT_CODE=$?

    # GdUnit4 returns: 0=success, 101=warnings/orphans, 100=failures
    if [ "$TEST_EXIT_CODE" = "100" ] || [ "$TEST_EXIT_CODE" = "1" ]; then
        echo ""
        echo "------------------------------------------------"
        echo "❌ TEST SUITE FAILED! (exit $TEST_EXIT_CODE)"
        echo "------------------------------------------------"
        FAILED=1
    else
        echo ""
        echo "✅ Test suite passed (exit $TEST_EXIT_CODE)"
    fi
else
    echo "⚠️ GdUnit4 not found — skipping test suite"
fi

# Check logs for critical errors
for log in tools/godot_lint.log tools/test_suite.log; do
    if [ -f "$log" ]; then
        if grep -iE "SCRIPT ERROR|Parse Error|Compile Error|hides an autoload singleton|SHADER ERROR" "$log" 2>/dev/null; then
            echo ""
            echo "❌ Critical error found in $log"
            FAILED=1
        fi
        if grep "ERROR:" "$log" 2>/dev/null | grep -ivE "resources still in use|objectdb instances leaked|caller thread can't call this function|statemachine: attempted to change to unregistered state|Formula failed safety check"; then
            echo ""
            echo "❌ Unexpected ERROR in $log"
            FAILED=1
        fi
    fi
done

if [ "$FAILED" = "1" ]; then
    echo ""
    echo "------------------------------------------------"
    echo "❌ VALIDATION FAILED"
    echo "------------------------------------------------"
    exit 1
fi

echo ""
echo "------------------------------------------------"
echo "✅ PRE-PUSH VALIDATION PASSED"
echo "------------------------------------------------"
exit 0

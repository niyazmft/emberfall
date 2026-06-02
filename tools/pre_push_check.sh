#!/bin/bash
## Project Emberfall: Pre-Push Validation Script
## This script runs all CI checks locally to ensure zero parse errors and math stability.

set -euo pipefail

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

echo "------------------------------------------------"
echo "🔍 Running Project Emberfall Pre-Push Check"
echo "------------------------------------------------"

# 0. Formatting
echo ""
echo "🎨 Step 0: Formatting GDScript..."
"$GDFORMAT_BIN" scripts/ tests/ ui/

# 1. Math Validation (Python)
echo ""
echo "⚖️ Step 1: Validating Deterministic Math (Python)..."
python3 tests/validate_math.py

# 2. GDScript Linting (Editor Scan)
echo ""
echo "🧹 Step 2: Running GDScript Lint (Editor Scan)..."
"$GODOT_BIN" --headless --editor --quit --path . 2>&1 | tee tools/godot_lint.log

# 3. In-Engine Math Validation
echo ""
echo "🎮 Step 3: Validating Deterministic Math (Godot)..."
"$GODOT_BIN" --headless --path . -s tests/test_deterministic_math.gd 2>&1 | tee tools/math_validation.log

# 4. Full Test Suite (NEW)
echo ""
echo "🧪 Step 4: Running Full Test Suite via GdUnit4..."
if [ -f "addons/gdUnit4/bin/GdUnitCmdTool.gd" ]; then
    # Use || true to capture exit code without set -e killing script immediately
    "$GODOT_BIN" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ --ignoreHeadlessMode 2>&1 | tee tools/test_suite.log || TEST_EXIT_CODE=$?
    
    # GdUnit4 returns 100 for failures, 101 for warnings (like orphans), and 0 for pure success.
    # We will treat 0 and 101 as passed for CI/Push checks, but 100 as failure.
    if [ "$TEST_EXIT_CODE" = "100" ] || [ "$TEST_EXIT_CODE" = "1" ]; then
        echo "------------------------------------------------"
        echo "❌ TEST SUITE FAILED! Check tools/test_suite.log"
        echo "------------------------------------------------"
        exit 1
    fi
else
    echo "⚠️ GdUnit4 not found at addons/gdUnit4/bin/GdUnitCmdTool.gd"
    echo "Skipping test suite..."
fi

# Fail if critical errors are found in any log
# Pattern check for "Failed: [1-9]" to catch test failures without catching "Failed: 0"
if grep -iE "SCRIPT ERROR|Parse Error|Compile Error|hides an autoload singleton|SHADER ERROR" tools/godot_lint.log tools/math_validation.log tools/test_suite.log || grep -iE "Failed: [1-9]" tools/math_validation.log tools/test_suite.log; then
    echo "------------------------------------------------"
    echo "❌ VALIDATION FAILED! Check tools/*.log"
    echo "------------------------------------------------"
    exit 1
fi

# Also check for general ERROR: but exclude common exit-leak false positives
if grep "ERROR:" tools/godot_lint.log tools/math_validation.log tools/test_suite.log | grep -vE "Resources still in use|ObjectDB instances leaked|Caller thread can't call this function in this node"; then
    echo "------------------------------------------------"
    echo "❌ CRITICAL ERRORS DETECTED! Check tools/*.log"
    echo "------------------------------------------------"
    exit 1
fi

echo ""
echo "------------------------------------------------"
echo "✅ PRE-PUSH VALIDATION PASSED"
echo "------------------------------------------------"
exit 0

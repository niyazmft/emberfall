#!/bin/bash
## Project Emberfall: Pre-Push Validation Script
## This script runs all CI checks locally to ensure zero parse errors and math stability.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "------------------------------------------------"
echo "🔍 Running Project Emberfall Pre-Push Check"
echo "------------------------------------------------"

# 0. Formatting
echo ""
echo "🎨 Step 0: Formatting GDScript..."
gdformat scripts/ tests/ ui/

# 1. Math Validation (Python)
echo ""
echo "⚖️ Step 1: Validating Deterministic Math (Python)..."
python3 tests/validate_math.py

# 2. GDScript Linting (Editor Scan)
echo ""
echo "🧹 Step 2: Running GDScript Lint (Editor Scan)..."
godot --headless --editor --quit --path . 2>&1 | tee tools/godot_lint.log

# 3. In-Engine Math Validation
echo ""
echo "🎮 Step 3: Validating Deterministic Math (Godot)..."
godot --headless --path . -s tests/test_deterministic_math.gd 2>&1 | tee tools/math_validation.log

# 4. Full Test Suite (NEW)
echo ""
echo "🧪 Step 4: Running Full Test Suite..."
if [ -f tests/run_all_tests.sh ]; then
    chmod +x tests/run_all_tests.sh
    if ! tests/run_all_tests.sh 2>&1 | tee tools/test_suite.log; then
        echo "------------------------------------------------"
        echo "❌ TEST SUITE FAILED! Check tools/test_suite.log"
        echo "------------------------------------------------"
        exit 1
    fi
else
    echo "⚠️ Test suite script not found at tests/run_all_tests.sh"
    echo "Skipping test suite..."
    touch tools/test_suite.log
fi

# Fail if critical errors are found in any log
if grep -iE "SCRIPT ERROR|Parse Error|Compile Error|hides an autoload singleton|SHADER ERROR" tools/godot_lint.log tools/math_validation.log tools/test_suite.log; then
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

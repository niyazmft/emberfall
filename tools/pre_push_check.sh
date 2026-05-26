#!/bin/bash
## Project Emberfall: Pre-Push Validation Script
## This script runs all CI checks locally to ensure zero parse errors and math stability.

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "------------------------------------------------"
echo "🔍 Running Project Emberfall Pre-Push Check"
echo "------------------------------------------------"

# 0. Formatting Check
echo ""
echo "🎨 Step 0: Checking GDScript Formatting..."
if ! gdformat --check scripts/ tests/ ui/ ; then
    echo "------------------------------------------------"
    echo "❌ FORMATTING FAILED! Run 'gdformat .' to fix."
    echo "------------------------------------------------"
    exit 1
fi
echo "✅ Formatting passed."

# 1. Math Validation (Python)
echo ""
echo "⚖️ Step 1: Validating Deterministic Math (Python)..."
python3 tests/validate_math.py

# 2. In-Engine Math Validation
echo ""
echo "🎮 Step 2: Validating Deterministic Math (Godot)..."
godot --headless --path . -s tests/test_deterministic_math.gd

# 3. GDScript Linting (Editor Scan)
echo ""
echo "🧹 Step 3: Running GDScript Lint (Editor Scan)..."
# We run the editor scan to catch parse errors and autoload shadowing.
godot --headless --editor --quit --path . 2>&1 | tee tools/godot_lint.log

# Fail if critical errors are found in the output
if grep -iE "SCRIPT ERROR|Parse Error|Compile Error|hides an autoload singleton" tools/godot_lint.log; then
    echo "------------------------------------------------"
    echo "❌ LINTING FAILED! Check tools/godot_lint.log"
    echo "------------------------------------------------"
    exit 1
fi

# 4. Full Test Suite
echo ""
echo "🧪 Step 4: Running Full Test Suite..."
bash tests/run_all_tests.sh

echo ""
echo "------------------------------------------------"
echo "✅ PRE-PUSH VALIDATION PASSED"
echo "------------------------------------------------"
exit 0

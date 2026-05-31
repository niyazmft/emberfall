#!/usr/bin/env bash
## Emberfall: One-Time Developer Setup
## Run this once after cloning the repository.
## Sets up git hooks, installs linting tools, and validates the environment.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   🔧 Emberfall Developer Setup               ║"
echo "╚══════════════════════════════════════════════╝"

# ──────────────────────────────────────────────────
# 1. Register version-controlled git hooks
# ──────────────────────────────────────────────────
echo ""
echo "🪝 [1/4] Installing git hooks..."
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit .githooks/pre-push
echo "  ✅ Git hooks active (pre-commit + pre-push)"

# ──────────────────────────────────────────────────
# 2. Install pre-commit framework
# ──────────────────────────────────────────────────
echo ""
echo "📦 [2/4] Installing pre-commit framework..."
PRE_COMMIT_BIN="${PRE_COMMIT_BIN:-pre-commit}"
if ! command -v "$PRE_COMMIT_BIN" &>/dev/null; then
    pip3 install pre-commit
fi
echo "  ✅ pre-commit installed ($(pre-commit --version 2>/dev/null || echo 'version unknown'))"

# ──────────────────────────────────────────────────
# 3. Install markdownlint-cli (via npm/node)
# ──────────────────────────────────────────────────
echo ""
echo "📝 [3/4] Checking markdownlint..."
if ! command -v markdownlint &>/dev/null; then
    if command -v npm &>/dev/null; then
        npm install -g markdownlint-cli
        echo "  ✅ markdownlint-cli installed"
    else
        echo "  ⚠️  npm not found — install Node.js, then run: npm install -g markdownlint-cli"
    fi
else
    echo "  ✅ markdownlint already installed ($(markdownlint --version))"
fi

# ──────────────────────────────────────────────────
# 4. Verify gdtoolkit
# ──────────────────────────────────────────────────
echo ""
echo "🎮 [4/4] Verifying gdtoolkit..."
GDFORMAT_BIN="${GDFORMAT_BIN:-gdformat}"
if command -v "$GDFORMAT_BIN" &>/dev/null; then
    echo "  ✅ gdtoolkit found ($("$GDFORMAT_BIN" --version 2>&1 | head -1))"
else
    echo "  ⚠️  gdtoolkit not found — install with: pip3 install gdtoolkit"
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   ✅ Setup complete!                         ║"
echo "║                                              ║"
echo "║   Hooks active:                              ║"
echo "║    • pre-commit → format + lint staged files ║"
echo "║    • pre-push   → full validation suite      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

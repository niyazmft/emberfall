#!/usr/bin/env bash
## Run all Emberfall test suites sequentially.
## Exit code 0 = all passed; non-zero = at least one failure.
##
## Invocation patterns used:
##   1. Python   — python3 tests/validate_math.py
##   2. SceneTree -s — extends SceneTree, entry via _initialize()
##   3. Node -s  — extends Node, entry via _ready(); requires SceneTree host
##
## Excluded:
##   test_ui_systems.gd — intentional headless guard (if not OS.has_feature("headless"))
##                        produces no pass/fail output in CI.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

GODOT_BIN="${GODOT_BIN:-godot}"

echo "=== Emberfall Test Suite ==="

# ── 1. Python cross-platform math validator ─────────────────────────────────
echo ""
echo "--- Running: validate_math.py (Python) ---"
python3 tests/validate_math.py

# ── 2. SceneTree-based tests (extends SceneTree, _initialize() entry) ────────
echo ""
echo "--- Running: test_deterministic_math.gd ---"
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
echo "--- Running: test_run_determinism.gd ---"
"$GODOT_BIN" --headless --path . -s tests/test_run_determinism.gd

echo ""
echo "--- Running: test_remap_ui.gd ---"
"$GODOT_BIN" --headless --path . -s tests/test_remap_ui.gd

# ── 3. Node-based tests (extends Node, _ready() entry, quit() on done) ───────
# These need a SceneTree host. We use an inline bootstrap — same mechanism
# as tests/test_runner.gd — so no extra scene files are required.

run_node_test() {
  local SCRIPT_RES_PATH="$1"  ## e.g. res://tests/test_state_machine.gd
  local LABEL="$2"
  echo ""
  echo "--- Running: ${LABEL} ---"
  "$GODOT_BIN" --headless --path . -s - <<GDEOF
extends SceneTree
func _initialize() -> void:
    var t: Node = (load("${SCRIPT_RES_PATH}") as GDScript).new()
    get_root().add_child(t)
GDEOF
}

run_node_test "res://tests/test_state_machine.gd"  "test_state_machine.gd"
run_node_test "res://tests/test_apparition.gd"     "test_apparition.gd"
run_node_test "res://tests/test_audio_wiring.gd"   "test_audio_wiring.gd"
run_node_test "res://tests/test_caption_system.gd" "test_caption_system.gd"
run_node_test "res://tests/test_burden_event.gd"   "test_burden_event.gd"
run_node_test "res://tests/test_ui_reflow.gd"      "test_ui_reflow.gd"

echo ""
echo "=== ALL TEST SUITES PASSED ==="

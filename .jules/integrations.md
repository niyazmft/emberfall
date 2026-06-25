## 2026-06-25 - Exclude intentional push_error test output from pre-push grep checks

**Learning:** When writing unit tests in GdUnit4 that test intentional error cases or invalid inputs (such as verifying `invalid_slot` handling in `InventoryManager`), Godot executes `push_error()` and prints `ERROR:` to `tools/test_suite.log`. The pre-push validation script `tools/pre_push_check.sh` scans this log for `ERROR:` and fails the build with "Unexpected ERROR", even when the test suite passes with 0 failures.

**Action:** When adding tests that intentionally trigger `push_error()`, add the specific error string (e.g., `|Invalid equipment slot`) to the `grep -ivE` ignore list in `tools/pre_push_check.sh` to prevent false positive CI validation failures.

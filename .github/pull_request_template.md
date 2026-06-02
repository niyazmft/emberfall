# PR Validation Checklist

Please ensure all items are checked before submitting this PR for review.

## 1. Automated Testing
- [ ] **Deterministic Math Validation**: Run `python3 tests/validate_math.py`.
- [ ] **Full Test Suite**: Run `bash tools/pre_push_check.sh` (which executes GdUnit4 tests).

## 2. Pre-Commit Hooks
- [ ] **GDScript Format**: Run `gdformat scripts/ tests/ ui/`.
- [ ] **GDScript Lint**: Run `gdlint scripts/ tests/ ui/`.

## 3. Integrity Checks
- [ ] No unintended changes to `project.godot`.
- [ ] No regressions in core scene files (`scenes/*.tscn`).
- [ ] Resource UIDs are updated correctly.

## 4. Code Quality & Style
- [ ] Adheres to GDScript style guide.
- [ ] Type hints are used everywhere possible.
- [ ] No new LSP warnings/errors.

## 5. Documentation
- [ ] Summary of changes included.
- [ ] Linked to relevant DON issue.

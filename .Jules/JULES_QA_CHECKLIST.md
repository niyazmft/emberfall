# Jules PR Validation Checklist

All PRs submitted by Google Jules must pass this checklist before being considered for merge.

## 1. Automated Testing

- [ ] **Deterministic Math Validation**: Run `python3 tests/validate_math.py`. All tests must pass with 0 errors.
- [ ] **Full Test Suite**: Run `bash tools/pre_push_check.sh` (which executes GdUnit4 tests). All unit and integration tests must pass.

## 2. Integrity Checks

- [ ] **Project Configuration**: No unintended changes to `project.godot`.
- [ ] **Core Scene Integrity**: No regressions or broken dependencies in core scene files (`scenes/*.tscn`).
- [ ] **Resource UIDs**: Ensure `.uid` files are updated correctly if new resources are added or existing ones modified.

## 3. Code Quality & Style

- [ ] **GDScript Style**: Adheres to the project's GDScript style guide.
- [ ] **Type Safety**: All variables and functions must have explicit type hints where possible.
- [ ] **Static Analysis**: No new warnings or errors in the Godot script editor/LSP.
- [ ] **Dynamic Dispatch Cleanup**: Verify no residual `.call("method", ...)` or `has_method("...")` pairs remain in non-architectural code. Architectural exceptions (dictionary-based state machines, generic Node presenters without class_name) must be explicitly noted in the PR description.

## 4. Documentation & PR Description

- [ ] **Clear Description**: PR includes a summary of changes and why they were made.
- [ ] **Issue Linking**: PR links to the relevant DON issue.
- [ ] **QA Notes**: PR includes notes on any specific areas that require manual verification.

---
**Sign-off required from QA Lead and Release Manager before merge.**

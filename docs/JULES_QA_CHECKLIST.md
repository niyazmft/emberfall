# Jules PR Validation Checklist

All PRs submitted by Google Jules must pass this checklist before being considered for merge.

## 1. Automated Testing
- [ ] **Deterministic Math Validation**: Run `python3 tests/validate_math.py`. All tests must pass with 0 errors.
- [ ] **In-Engine Math Validation**: Run `godot --script tests/test_deterministic_math.gd --headless`. All engine-side math must match expected deterministic outputs.
- [ ] **Full Test Suite**: Run `bash tests/run_all_tests.sh`. All unit and integration tests must pass.

## 2. Integrity Checks
- [ ] **Project Configuration**: No unintended changes to `project.godot`.
- [ ] **Core Scene Integrity**: No regressions or broken dependencies in core scene files (`scenes/*.tscn`).
- [ ] **Resource UIDs**: Ensure `.uid` files are updated correctly if new resources are added or existing ones modified.

## 3. Code Quality & Style
- [ ] **GDScript Style**: Adheres to the project's GDScript style guide (based on official Godot standards).
- [ ] **Type Safety**: All variables and functions must have explicit type hints where possible. No vague types unless strictly necessary.
- [ ] **Static Analysis**: No new warnings or errors in the Godot script editor/LSP.

## 4. Documentation & PR Description
- [ ] **Clear Description**: PR includes a summary of changes and why they were made.
- [ ] **Issue Linking**: PR links to the relevant DON issue.
- [ ] **QA Notes**: PR includes notes on any specific areas that require manual verification.

---

# Jules Label Gating Protocol

To prevent dependency conflicts and maintain quality, the following protocol must be followed when offloading tasks to Google Jules:

1. **Gating Owner**: Only the **Release Manager** or **Technical Director** may apply the `jules` label to an issue.
2. **Conflict Check**: Before labeling, the **QA Lead** must verify that the task is "dependency-clean" (no active work on related files).
3. **Template Requirement**: All Jules PRs must use the `pull_request_template.md` which includes the validation checklist.
4. **Mandatory Review**: All Jules PRs require a manual sign-off from the **QA Lead** (or designated tester) after all automated tests pass.
5. **Regression Failure**: Any PR that breaks deterministic math or engine-side verification will be closed immediately, and the `jules` label will be removed from the issue.

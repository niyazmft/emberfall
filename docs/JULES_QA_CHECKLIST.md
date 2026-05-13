# Jules PR Validation Checklist

This checklist must be completed for every PR submitted by Google Jules before it can be merged into `main`.

## Automated Tests
- [ ] **Deterministic Math**: Run `python3 tests/validate_math.py`. All tests must pass.
- [ ] **In-Engine Tests**: Run `godot --script tests/test_deterministic_math.gd --headless`. All tests must pass.
- [ ] **Smoke Tests**: Run any additional tactical smoke tests identified for the specific changes.

## Integrity Checks
- [ ] **Project Config**: No unintended changes to `project.godot`.
- [ ] **Core Scenes**: No unintended changes to core scene files (`.tscn`).
- [ ] **Dependencies**: No new external dependencies introduced without approval.

## Code Quality
- [ ] **GDScript Style**: Code follows the project's GDScript style guide.
- [ ] **Type Safety**: Proper use of static typing where applicable.
- [ ] **No Dead Code**: No commented-out blocks or unused variables.

## Sign-off
- [ ] QA Lead Signature: ________________
- [ ] Release Manager Signature: ________________

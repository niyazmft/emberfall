# Jules Label Gating Protocol

Version: 1.1.0
Owner: Release Manager
Status: Active

## Overview

Google Jules is an autonomous coding agent used to offload programming-heavy tasks. To ensure stability, prevent merge conflicts, and maintain code quality, the following gating protocol must be strictly followed when applying the `jules` label to issues in the Emberfall repository.

## Gating Rules

1. **Programming-Only**: The `jules` label is strictly for programming tasks. It must NOT be used for design documents, narrative changes, or art pipeline modifications.
2. **Zero Open Dependencies**: An issue is only eligible for Jules offload if it has no open dependencies. It must not be blocked by any other open issue.
3. **Conflict Check**: Before labeling, the **QA Lead** must verify that the task is "dependency-clean" (no active work on related files by other agents).
4. **No Core Interface Changes**: Modifications to core system signatures (e.g., `CombatFormula`, `DeterministicMath`, `SeedGovernance`, `Entity` base classes) are prohibited for Jules. Such changes require Technical Director (TD) pre-approval.
5. **Release Manager Gate**: The **Release Manager (RM)** or **Technical Director (TD)** are the sole authorities for applying and removing the `jules` label.
6. **Concurrent Limit**: A maximum of **3 concurrent Jules PRs** are allowed at any given time to prevent merge-conflict "storms".
7. **QA Validation Required**: All Jules-generated PRs must pass the mandatory validation checklist in `docs/JULES_QA_CHECKLIST.md` before merging.

## Procedure for Applying Label

1. Identify a candidate programming task in the backlog/todo.
2. Verify the task has no open blockers or dependencies.
3. RM/TD reviews the task to ensure it does not touch core interfaces.
4. RM checks the current count of active Jules PRs/issues.
5. If all criteria are met, RM/TD applies the `jules` label.

## Post-Submission Handling

1. Once Jules submits a PR, the QA Lead is notified.
2. QA Lead runs the validation suite (`tests/run_all_tests.sh`).
3. If any automated test fails, the PR is closed immediately, and the `jules` label is removed from the issue for manual triage.
4. If all tests pass, QA Lead performs a manual code review and sign-off on the checklist.
5. RM performs a final check before merging.

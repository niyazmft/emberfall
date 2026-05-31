# Release Checklist — Project Emberfall

Use this checklist before every tag-driven release. No stage may be skipped.

---

## 1. QA Validation Gate
- [ ] All automated tests pass (`tests/run_all_tests.sh`).
- [ ] Python mirror validation passes (`python3 tests/validate_math.py`).
- [ ] Palette validation passes if available (`python3 tests/validate_palettes.py`).
- [ ] In-engine test runner completes without failures.
- [ ] **QA Lead sign-off required.**

## 2. Version Verification
- [ ] `project.godot` `config/version` matches the intended tag version.
- [ ] `CHANGELOG.md` is updated for the new version.
- [ ] Tag follows semver/prototype convention: `v{major}.{minor}.{patch}[-sprint{N}]`.

## 3. Build Generation
- [ ] GitHub Actions `release.yml` is present and valid.
- [ ] Export presets exist in `export_presets.cfg` for every target platform.
- [ ] Windows Desktop export produces `Emberfall.exe` + `.pck`.
- [ ] Linux/X11 export produces `Emberfall.x86_64` + `.pck`.
- [ ] Export templates installed in CI (Godot version matches project features).

## 4. Store / Distribution Submission
- [ ] GitHub Release created automatically by `release.yml` on tag push.
- [ ] Attachments include `emberfall-windows.zip` and `emberfall-linux.zip`.
- [ ] Release notes populated from `CHANGELOG.md`.
- [ ] Steam depot build script (`release/steam/steamcmd_build.sh`) validated if deploying to Steam.

## 5. Verify Live Build
- [ ] Download release artifacts from GitHub Releases.
- [ ] Smoke-test Windows build on a clean VM or secondary device.
- [ ] Smoke-test Linux build on a clean device.
- [ ] Confirm build launches to main scene without crash.

## 6. Launch Coordination
- [ ] Rollback plan prepared (instructions to delete/republish release tag).
- [ ] Crash-rate monitoring plan in place (manual player reports acceptable for prototype).
- [ ] Hotfix branch ready from latest release tag (`hotfix/vX.Y.Z`).
- [ ] **Producer sign-off required before public announcement.**

## Sign-offs
| Role | Name | Date | Status |
|------|------|------|--------|
| QA Lead | @qa-lead | | |
| Producer | @producer | | |
| Release Manager | @release-manager | | |

## Post-Release
- [ ] Update `CHANGELOG.md` with any hotfixes.
- [ ] File post-mortem if release encountered blockers.

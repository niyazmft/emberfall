# Project Integrations & Platform Learnings

## 2026-06-08 - Platform target clarified: Desktop via CI, not Android

**Learning:** The project README claimed we were "optimized for Android via Termux," but
there is no Android export preset and Termux is a terminal emulator that cannot run
Godot games graphically. The CI release pipeline (`release.yml`) already builds and
releases Windows, Linux, macOS, and Web exports. The project was actually targeting
desktop and web all along while using the mobile renderer.

**Action:** When a README makes a platform claim, cross-check `export_presets.cfg`
and the CI workflow before accepting it as fact. If the renderer is `mobile` but
the build targets are desktop, explicitly switch to `forward_plus` for desktop to
unlock proper lighting capabilities.

---

## 2026-06-13 - Verify against GitHub before creating issues

**Learning:** `AGENT_ASSIGNMENTS.md` and `PROJECT_BOARD.md` listed issues #151-#179 as current tasks for story-level-agent. When cross-checked against the GitHub API, every single one of those issues was already **CLOSED** (completed in past sprints). Acting on the local boards alone would have led to duplicate issue creation and wasted effort.

**Action:** Before creating new issues or scheduling sprints, always run `gh issue list --state all --json number,title,state` to cross-check the actual GitHub state against local board entries. If the local board references issues that are closed on GitHub, reconcile immediately — mark them as Done locally and identify the actual remaining gaps before creating new issues.

---

*Append-only file. Newest entries go at the bottom.*

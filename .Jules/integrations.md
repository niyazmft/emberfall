# Project Integrations & Platform Learnings

## 2026-06-08 - Platform target clarified: Desktop via CI, not Android

**Learning:** The project README claimed we were "optimized for Android via Termux,"
but there is no Android export preset and Termux cannot run Godot games.
The CI release pipeline already builds Windows, Linux, macOS, and Web exports.
The project was targeting desktop and web all along using the mobile renderer.

**Action:** When a README makes a platform claim, cross-check `export_presets.cfg`
and the CI workflow. If the renderer is `mobile` but targets are desktop,
explicitly switch to `forward_plus` for desktop to unlock lighting capabilities.

---

## 2026-06-13 - Verify GitHub state before creating issues

**Learning:** `AGENT_ASSIGNMENTS.md` listed issues #151-#179 as current tasks.
When cross-checked against GitHub, these were already **CLOSED**.
Acting on local boards alone would have led to duplicate effort.

**Action:** Before scheduling sprints, always cross-check the actual GitHub state
against local board entries. If local boards are stale, reconcile immediately.

---

*Append-only file. Newest entries go at the bottom.*

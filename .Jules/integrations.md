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

*Append-only file. Newest entries go at the bottom.*

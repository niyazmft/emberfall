# Changelog — Project Emberfall

All notable releases for the prototype are documented here.

## [0.1.0-sprint1] — Prototype Release

### Added

- Godot 4.2 project scaffold with deterministic math & AP economy.
- In-engine test suite (`tests/test_deterministic_math.gd`) and Python cross-checker (`tests/validate_math.py`).
- Golden-seed determinism (`0xDEADBEEF`) via SHA-256 → 63-bit truncation.
- Combat formula with parity validated against Python mirror (400+ edge cases).
- Entity stat-block with strongly typed `@export` setters.
- Position modifiers: frontal, backstab, elevation, light/heavy cover.
- Steam depot build pipeline (`release/steam/`) for Windows & Linux.
- GitHub Releases distribution pipeline (`v*` tags) for Windows & Linux binaries.

### Infrastructure

- `.github/workflows/release.yml`: automated export and GitHub Release creation.
- Export presets configured for Windows Desktop and Linux/X11.

### Known Issues

- No macOS native Apple Silicon export (requires custom template).

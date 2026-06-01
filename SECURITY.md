# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| main    | :white_check_mark: |
| older   | :x:                |

Only the `main` branch receives security updates.

## Reporting a Vulnerability

If you discover a security vulnerability in Emberfall, please report it privately:

- **Email:** open an issue marked `[SECURITY]` and contact the maintainer via GitHub
- **Response time:** best effort, typically within 7 days

Please **do not** file public GitHub issues for security vulnerabilities.

## Scope

Emberfall is a turn-based tactical roguelike game built with Godot 4.2.2. The
project is primarily a single-player offline experience, so the attack surface
is limited to:

- Deterministic math/seed handling (must not allow arbitrary code execution)
- Save file parsing (must not crash or execute code on malformed input)
- Optional networked features (if/when added)

## Out of Scope

- Vulnerabilities in third-party Godot plugins or engine itself
- Issues requiring physical access to the player's device

# Integrations & Tooling Learnings

## 2026-06-07 - Vision-Language-Action QA Agent addon for Emberfall

**Learning:** Built an internal Godot addon (`addons/qa_agent/`) that enables Vision-Language-Action (VLA) testing via cloud AI (OpenAI GPT-4o / compatible APIs). The addon captures viewport screenshots as base64, sends them to the AI with a system prompt describing the game state and available actions, parses the returned JSON action, and executes it either as simulated input (`Input.parse_input_event()`) or direct API calls to autoloads (`GridSystem`, `RunManager`, etc.).

**Architecture:** The addon follows the project's Data/Logic/Visual separation and strict typing conventions. It consists of:
- `QAVisionCapture` — viewport screenshot → base64, with resize and local debug save
- `QAAIClient` — HTTPRequest wrapper for OpenAI chat.completions (vision + text)
- `QAActionExecutor` — dual-mode dispatcher for `input_*` and `api_*` actions
- `QAScenarioRunner` — scripted step-by-step regression tests with optional AI assertion validation
- `QAExploratoryAgent` — autonomous VLA loop: screenshot → AI → action → assertion
- `QATestReporter` — structured logging with JSON export and console summary
- `QAManager` — autoload orchestrator exposing `run_scenario()` and `start_exploratory()`

**Action:** When adding a new Godot addon to Emberfall, always generate `.uid` files for every new `.gd` script, register the addon in `project.godot [editor_plugins] enabled=`, and verify scripts parse cleanly with `godot --headless --script <path>`. Keep addon classes prefixed with `QA` to avoid namespace collisions with autoloads.

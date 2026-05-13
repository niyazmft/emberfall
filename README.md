# Project Emberfall — Godot 4 Deterministic Tactics Engine

## Project Structure

```
emberfall/
├── project.godot              # Godot 4.2 project config
├── scenes/
│   └── main.tscn              # Entry-point scene
├── scripts/
│   ├── core/                  # Deterministic math & game constants
│   │   ├── constants.gd
│   │   ├── deterministic_math.gd
│   │   ├── seed_governance.gd
│   │   ├── combat_formula.gd
│   │   └── ap_economy.gd
│   ├── entities/
│   │   └── entity.gd          # Typed stat-block entity
│   ├── autoload/              # (reserved for future autoloads)
│   ├── config/                # (reserved for resource configs)
│   └── state_machine/         # (reserved for turn-state machine)
├── assets/                    # Sprites, tilesets, audio (TBD A2/A3)
└── tests/
    ├── test_deterministic_math.gd   # In-engine test suite
    └── validate_math.py             # Stand-alone Python cross-checker
```

## Quick Start

### Open in Godot 4.2+
1. Launch Godot and import `project.godot`.
2. Press **F6** to run the main scene (currently a stub).

### Run Validation (no Godot binary required)
```bash
cd emberfall/tests
python3 validate_math.py
```

This executes 400+ edge-case assertions covering:
- Golden-seed SHA-256 repeatability (`0xDEADBEEF`)
- `floori` / `clampf` / `damage_floor` parity with Python
- Damage formula: 100 stochastic edge cases + spec reference scenarios
- AP economy state machine (Turns 1–4)
- Position modifier matrix (frontal, backstab, elevation, cover)
- Elemental interaction multipliers
- Entity stat clamping

### Run In-Engine Tests
Once a Godot binary is available:
```bash
cd emberfall
godot --script tests/test_deterministic_math.gd --headless
```

## Determinism Guarantees

- **Math**: All combat math routes through `DeterministicMath` helpers; `float` → `int` truncation uses `floor()` with explicit clamp.
- **Seeds**: `SeedGovernance.hash_seed()` produces deterministic 63-bit positive integers via SHA-256 → truncation.
- **Cross-Platform**: Validation script mirrors GDScript logic in Python; both must agree bit-for-bit.

## Architecture Notes

- `CombatFormula._is_backstab()` mirrors prototype `position_modifier()` exactly (cardinal-normalised attacker→defender vector, dot < –0.7).
- Cover: light (–0.15) is prototype-equivalent; heavy cover (–0.30) is a spec extension for adjacent cover tiles.
- Entity fields are strongly typed with `@export` clamped setters (`hp`, `off`, `def_`, `spd`, `moral_flag`).

## Acceptance Criteria (A1)

- [x] Godot 4 project scaffold with proper folder structure
- [x] Deterministic math utilities (`DeterministicMath`, `CombatFormula`, `APEconomy`)
- [x] Golden-seed repeatability (`0xDEADBEEF` → identical result every run)
- [x] Cross-platform math validated via Python mirror
- [x] Matches Python prototype output for 400+ edge cases

## Next Sprint (A2)

- Grid & tilemap scaffold
- Tile cover placement (light / heavy)
- Action point visualisation
- Attack preview UI

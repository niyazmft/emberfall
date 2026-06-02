# Emberfall Architecture Documentation

## Table of Contents
1. [Overview](#overview)
2. [Core Systems](#core-systems)
3. [Visual System (2.5D)](#visual-system-25d)
4. [Entity System](#entity-system)
5. [Burden System](#burden-system)
6. [State Machines](#state-machines)
7. [Project Structure](#project-structure)
8. [Testing Strategy](#testing-strategy)
9. [Performance Guidelines](#performance-guidelines)

## Overview

Emberfall is a tactical grid combat game built in Godot 4.2+ featuring:
- Deterministic math for cross-platform consistency
- 2.5D isometric visuals with layered elevation
- State machine-driven game flow
- Component-based entity system

### Design Principles
1. **Determinism First** - All gameplay math is 100% deterministic
2. **Separation of Concerns** - Data, logic, and visuals are separated
3. **Configuration-Driven** - Tunable values in JSON, not code
4. **Testable** - All systems have unit tests
5. **Strict Typing** - All variables must be strictly typed to pass CI

## Core Systems

### 1. AutoloadHelper Architecture
- **File:** `scripts/core/autoload_helper.gd`
- **Purpose:** All singleton (autoload) access **must** route through this class. It ensures that references resolve cleanly during headless test runs where the SceneTree structure is irregular.

### 2. EventBus
- **File:** `scripts/autoload/event_bus.gd`
- **Purpose:** Centralized hub for cross-system signals to decouple listeners from emitters.

### 3. SaveManager
- **File:** `scripts/autoload/save_manager.gd`
- **Purpose:** Single point of truth for parsing state to/from JSON.

### 4. Deterministic Math
- **Files:** `scripts/core/deterministic_math.gd`, `scripts/core/combat_formula.gd`
- **Purpose:** Cross-platform identical results
- **Validation:** Python mirror in `tests/validate_math.py`

### 5. Grid System
- **File:** `scripts/autoload/grid_system.gd`
- **Size:** 12x12 tiles
- **Features:** Elevation, cover, line-of-sight, elemental effects

## Visual System (2.5D)

### Architecture
```text
CombatRoom
├── GridRenderer      - Isometric floor tiles
├── EntityContainer   - YSort for depth
│   ├── Keeper        - Player entity
│   └── Enemies       - AI entities
└── UIOverlay         - HUD elements
```

### Key Components
- **GridRenderer** - Seamless textures, elevation terraces
- **EntityVisualProxy** - Position interpolation, facing, state visuals
- **ApparitionRenderer** - Advanced composite shader pipeline, config-driven from JSON.

## Entity System

### Class Hierarchy
```text
Node2D
├── Keeper          - Player scene
│   ├── Entity      - Data block
│   ├── EntityVisualProxy  - Visuals
│   └── ApparitionRenderer - Effects
└── BaseEnemy       - Enemy scene
    ├── Entity
    ├── EntityVisualProxy
    └── ApparitionRenderer
```

### State Management
- `Entity.state` - Current state enum
- `EntityLifecycle` - Canonical state transitions
- Signal-based: `entity_state_changed`

## Burden System

### Architecture
Split into focused components to handle moral weight and game events:
1. **BurdenManager** - Public API, state tracking, kill queue
2. **BurdenEventCoordinator** - Event generation and rules processing
3. **BurdenCaptionDriver** - Subtitle and voice integration
4. **BurdenShaderManager** - Render pipeline orchestration

### Persistence
- Saved into the `SaveManager` schema natively.

## State Machines

### Hierarchical FSM
- **Base** - Generic FSM framework
- **RunManager** - Game phase flow

### States
```text
SANCTUM → BIOME_GENERATION → ROOM → MORAL_EVAL → BIOME_THRESHOLD → RUN_RESOLUTION
```

## Project Structure

```text
emberfall/
├── scripts/
│   ├── core/          # Math, combat, grid, constants
│   ├── entities/      # Entity, Keeper, BaseEnemy
│   ├── autoload/      # 15 global systems
│   ├── state_machine/ # FSM framework
│   ├── ui/            # Menus, HUD
│   ├── visual/        # 2.5D rendering
│   └── burden/        # Burden system classes
├── scenes/            # TSCN files
├── tests/             # Unit tests
├── config/            # JSON configs
└── .Jules/            # Historical learning memories
```

## Testing Strategy

### Layers
1. **Python Validation** - Cross-check math
2. **GdUnit4** - Entity lifecycle, state machines, and system logic
3. **Integration** - Full test suite executed via GitHub Actions
4. **CI/CD** - pre-commit hooks and GitHub Actions

### Running Tests
```bash
# Local (Headless execution of the GdUnit4 test suite)
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ --ignoreHeadlessMode

# Pre-commit Hook (Runs GdUnit4 and formatting checks)
bash tools/pre_push_check.sh
```

## Performance Guidelines

### Targets
- Scene load: < 2 seconds
- Autoload init: < 100ms total
- 60 FPS on mid-range PC

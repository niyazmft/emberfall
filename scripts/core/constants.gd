class_name GameConstants
## Global design constants for Project Emberfall.
## All Tier-1 spec constants from system-specification-core.md §1 & §2.
## Fully static — no instance state.

# ── Grid Resolution ─────────────────────────────────────────────────
const GRID_RESOLUTION: float = 1.0  ## 1 tile = 1 metre (abstract)

# ── AP Economy ──────────────────────────────────────────────────────
const AP_MAX: int = 6
const AP_REGEN: int = 2
const ABILITY_MIN_COST: int = 3
const ABILITY_MAX_COST: int = 5

# ── Damage Formula ──────────────────────────────────────────────────
const D_BASE: int = 10
const CRIT_MULT: float = 1.5

# ── Moral Weight ────────────────────────────────────────────────────
const MWT: int = 3

# ── Position Modifiers ──────────────────────────────────────────────
const BACKSTAB_BONUS: float = 0.25
const ELEVATION_BONUS_TIER_1: float = 0.15
const ELEVATION_BONUS_TIER_2: float = 0.25
const LIGHT_COVER_PENALTY: float = 0.15
const HEAVY_COVER_PENALTY: float = 0.30
const POSITION_MODIFIER_MIN: float = 0.5
const POSITION_MODIFIER_MAX: float = 1.5

# ── Elemental Modifiers (§2.3) ────────────────────────────────────
const ELEM_FIRE_TO_OIL: float = 2.0
const ELEM_WIND_TO_FIRE: float = 1.5
const ELEM_OIL_SLIP_SPEED: float = 0.8
const ELEM_WATER_TO_FIRE: float = 0.5

# ── Memory Fragment (Tier 2) ──────────────────────────────────────
const MEMORY_SYNERGY_MAX: float = 0.30
const FRAGMENTS_MAX: int = 3

# ── Grid Dimensions (Sprint 1: 12×12 combat room) ─────────────────
const GRID_W: int = 12
const GRID_H: int = 12

# ── Golden Seed for Determinism Validation ────────────────────────
const GOLDEN_SEED: int = 0xDEADBEEF

# ── Entity Stat Bounds ─────────────────────────────────────────────
const HP_MAX_BOUND: int = 9999
const STAT_OFF_BOUND: int = 999
const STAT_DEF_BOUND: int = 999
const STAT_SPD_BOUND: int = 99

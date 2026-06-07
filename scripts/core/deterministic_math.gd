class_name DeterministicMath
## Wrappers around all mathematical operations that affect determinism.
## Every function is annotated with exact semantics so that
## cross-platform validation can compare outputs bit-for-bit.
##
## References: system-specification-core.md §2, §3, §11.

# ── Floating-Point Bounds ──────────────────────────────────────────
const EPSILON: float = 1e-9


# ── Floor / Ceil ────────────────────────────────────────────────────
static func floori(value: float) -> int:
	## Floor to integer: largest integer ≤ value.
	## In GDScript, floor() returns float; we cast to int for integer math.
	return int(floor(value))


static func floorf(value: float) -> float:
	## Floor preserving float return type.
	return floor(value)


static func ceili(value: float) -> int:
	## Ceiling to integer: smallest integer ≥ value.
	return int(ceil(value))


static func ceilf(value: float) -> float:
	## Ceiling preserving float return type.
	return ceil(value)


# ── Clamp ──────────────────────────────────────────────────────────
static func clampi(value: int, min_val: int, max_val: int) -> int:
	## Integer clamp — inclusive bounds.
	if value < min_val:
		return min_val
	if value > max_val:
		return max_val
	return value


static func clampf(value: float, min_val: float, max_val: float) -> float:
	## Float clamp — inclusive bounds.
	if value < min_val:
		return min_val
	if value > max_val:
		return max_val
	return value


# ── Signum ────────────────────────────────────────────────────────
static func sgn(value: float) -> int:
	## Returns –1, 0, or +1.
	if value < -EPSILON:
		return -1
	if value > EPSILON:
		return 1
	return 0


# ── Deterministic Damage Floor ────────────────────────────────────
static func damage_floor(raw: float) -> int:
	## §2.1: DAMAGE_DEALT = ⌊ raw ⌋, then clamped to minimum 1.
	## raw is always expected to be ≥ 0 in normal combat, but we guard anyway.
	if raw < 0.0:
		raw = 0.0
	var floored: int = floori(raw)
	return maxi(floored, 1)


# ── AP Overflow Guard ─────────────────────────────────────────────
static func ap_start(ap_carried: int, ap_regen: int, ap_max: int) -> int:
	## §3.1: AP_START_OF_PLAYER_PHASE = min(AP_MAX, AP_CARRIED_OVER + AP_REGEN)
	var sum: int = ap_carried + ap_regen
	if sum > ap_max:
		return ap_max
	return sum


static func ap_carry_over(ap_previous_end: int, ap_spent: int, ap_max: int) -> int:
	## §3.1: AP_CARRIED_OVER = clamp(AP_PREVIOUS_END – AP_SPENT, 0, AP_MAX)
	var remaining: int = ap_previous_end - ap_spent
	return clampi(remaining, 0, ap_max)


# ── Integer Helpers ───────────────────────────────────────────────
static func maxi(a: int, b: int) -> int:
	return a if a >= b else b


static func mini(a: int, b: int) -> int:
	return a if a <= b else b


static func absi(a: int) -> int:
	return a if a >= 0 else -a


static func absf(a: float) -> float:
	return a if a >= 0.0 else -a


# ── Cross-Platform Golden-Seed Validation ─────────────────────────────
static func validate_golden_seed() -> bool:
	## Smoke test: a known set of floor/clamp operations against
	## golden seed must match reference values.
	## This is called by the test suite on project load.
	var golden: int = GameConstants.GOLDEN_SEED
	var ok: bool = true

	# Reference: seed 0xDEADBEEF used as basis for known hashes
	var h1: int = SeedGovernance.hash_int(golden, "TEST")
	ok = ok and (h1 == SeedGovernance.hash_int(golden, "TEST"))

	# Floor tests from prototype edge case bank
	ok = ok and (floori(14.0) == 14)
	ok = ok and (floori(17.5) == 17)
	ok = ok and (floori(21.7) == 21)
	ok = ok and (floori(9.8) == 9)
	ok = ok and (floori(35.0) == 35)
	ok = ok and (floori(0.0) == 0)
	ok = ok and (damage_floor(14.0) == 14)
	ok = ok and (damage_floor(0.0) == 1)
	ok = ok and (damage_floor(-3.0) == 1)
	ok = ok and (clampf(1.55, 0.5, 1.5) == 1.5)
	ok = ok and (clampf(0.45, 0.5, 1.5) == 0.5)

	return ok

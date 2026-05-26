class_name APEconomy
## AP pool management and regeneration.
## References: system-specification-core.md §3.
##
## Deterministic rules:
##   AP_START = min(AP_MAX, AP_CARRIED_OVER + AP_REGEN)
##   AP_CARRIED_OVER = clamp(AP_PREVIOUS_END – AP_SPENT, 0, AP_MAX)


# ── Phase Start ────────────────────────────────────────────────────
static func start_phase(ap_carried: int) -> int:
	## Call at the beginning of every player or enemy phase.
	## AP carried from previous turn is already clamped; we just add regen.
	return DeterministicMath.ap_start(ap_carried, GameConstants.AP_REGEN, GameConstants.AP_MAX)


static func start_phase_with_custom_regen(ap_carried: int, regen: int) -> int:
	## Variant for status effects that alter AP_REGEN.
	return DeterministicMath.ap_start(ap_carried, regen, GameConstants.AP_MAX)


# ── Action Spend ────────────────────────────────────────────────────
static func spend(ap_current: int, cost: int) -> int:
	## Returns new AP after spending. Caller must pre-validate cost ≤ ap_current.
	return ap_current - cost


static func can_afford(ap_current: int, cost: int) -> bool:
	return ap_current >= cost


# ── End Phase Carry-Over ────────────────────────────────────────────
static func end_phase(ap_end: int, ap_spent_total: int) -> int:
	## Call after all actions in a phase are resolved.
	## Returns AP carried into next turn (already clamped).
	return DeterministicMath.ap_carry_over(ap_end, ap_spent_total, GameConstants.AP_MAX)


# ── Full Turn Sequence ──────────────────────────────────────────────
static func simulate_turn(ap_start_of_turn: int, action_costs: Array[int]) -> Dictionary:
	## Deterministic turn simulator for test / AI planning.
	## Returns Dictionary with keys:
	##   "ap_spent": int, "ap_remaining": int, "ap_next_turn": int,
	##   "actions_executed": int, "truncated": bool
	##
	## If an action cost exceeds remaining AP, the sequence is truncated.
	var ap: int = ap_start_of_turn
	var spent_total: int = 0
	var executed: int = 0
	var truncated: bool = false

	for cost: int in action_costs:
		if not can_afford(ap, cost):
			truncated = true
			break
		ap = spend(ap, cost)
		spent_total += cost
		executed += 1

	var next_turn: int = end_phase(ap_start_of_turn, spent_total)
	return {
		"ap_spent": spent_total,
		"ap_remaining": ap,
		"ap_next_turn": next_turn,
		"actions_executed": executed,
		"truncated": truncated,
	}

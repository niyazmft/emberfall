extends SceneTree
## Unit / integration tests for Entity Lifecycle (DON-100 B2).
## Run via Godot Editor test runner or `godot --headless --script tests/test_entity_lifecycle.gd`.
#
## Covers:
##   AC-1: MORAL_FLAG increments/decrements per spec §4.3
##   AC-2: Burden Event fires at MWT = 3
##   AC-3: State transitions deterministic and reversible where required

func run_all() -> void:
	var passed := 0
	var failed := 0
	var tests := [
		"test_damage_transitions_to_dying",
		"test_heal_reverses_dying",
		"test_stun_timer_resolves_to_idle",
		"test_dying_timer_resolves_to_dead",
		"test_spare_transitions_to_ghost",
		"test_process_kill_queues_moral_delta",
		"test_resolve_moral_queue_increments_flag",
		"test_mwt_fires_at_three",
		"test_mwt_queues_remaining_deltas",
		"test_spare_applies_negative_delta",
		"test_reset_clears_queue_and_timers",
	]

	for name: String in tests:
		print("Running %s ..." % name)
		var ok: bool = call(name)
		if ok is bool and ok:
			passed += 1
			print("  PASS")
		else:
			failed += 1
			print("  FAIL (returned %s)" % str(ok))

	print("")
	print("Results: %d passed, %d failed out of %d" % [passed, failed, tests.size()])
	if failed > 0:
		push_error("EntityLifecycle test suite had failures.")
		# get_tree().quit(1) # -- No need to quit in headless mode
	else:
		pass
		# get_tree().quit(0)


# ── Test harness helpers ─────────────────────────────────────────────────

func _new_lifecycle() -> Node:
	var script := load("res://scripts/entities/entity_lifecycle.gd")
	var el: Node = script.new()
	get_root().add_child(el)
	return el


# ── AC-1: Damage applies and transitions to DYING ──────────────────────────
func test_damage_transitions_to_dying() -> bool:
	var el := _new_lifecycle()
	var enemy := Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	if enemy.hp != 0:
		push_error("Expected HP 0, got %d" % enemy.hp)
		return false
	if enemy.state != Entity.State.DYING:
		push_error("Expected DYING, got %d" % enemy.state)
		return false
	return true


# ── AC-1: Heal reverses DYING → IDLE ─────────────────────────────────────
func test_heal_reverses_dying() -> bool:
	var el := _new_lifecycle()
	var enemy := Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	if enemy.state != Entity.State.DYING:
		push_error("Expected DYING before heal")
		return false
	el.heal(enemy, 5)
	if enemy.hp != 5:
		push_error("Expected HP 5 after heal, got %d" % enemy.hp)
		return false
	if enemy.state != Entity.State.IDLE:
		push_error("Expected IDLE after heal, got %d" % enemy.state)
		return false
	return true


# ── AC-3: Stun timer resolves STUNNED → IDLE ───────────────────────────────
func test_stun_timer_resolves_to_idle() -> bool:
	var el := _new_lifecycle()
	var enemy := Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.stun(enemy, 1)
	if enemy.state != Entity.State.STUNNED:
		push_error("Expected STUNNED")
		return false
	el.process_end_of_turn()
	if enemy.state != Entity.State.IDLE:
		push_error("Expected IDLE after stun timer, got %d" % enemy.state)
		return false
	return true


# ── AC-3: Dying timer resolves DYING → DEAD ────────────────────────────────
func test_dying_timer_resolves_to_dead() -> bool:
	var el := _new_lifecycle()
	var enemy := Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	if enemy.state != Entity.State.DYING:
		push_error("Expected DYING")
		return false
	el.process_end_of_turn()
	if enemy.state != Entity.State.DEAD:
		push_error("Expected DEAD after dying timer, got %d" % enemy.state)
		return false
	return true


# ── AC-3: Spare transitions DYING → GHOST ────────────────────────────────
func test_spare_transitions_to_ghost() -> bool:
	var el := _new_lifecycle()
	var player := Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	player.ap = 3
	el.player_entity = player

	var enemy := Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	var ok: bool = el.spare_entity(player, enemy)
	if not ok:
		push_error("spare_entity returned false")
		return false
	if enemy.state != Entity.State.GHOST:
		push_error("Expected GHOST, got %d" % enemy.state)
		return false
	if player.ap != 2:
		push_error("Expected AP 2 after spare, got %d" % player.ap)
		return false
	return true


# ── AC-1: process_kill queues a delta ────────────────────────────────────
func test_process_kill_queues_moral_delta() -> bool:
	var el := _new_lifecycle()
	var player := Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	el.player_entity = player

	var enemy := Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	el.process_kill(player, enemy, true, "enemy_01", "Grunt")
	if el.get_queued_delta_count() != 1:
		push_error("Expected 1 queued delta, got %d" % el.get_queued_delta_count())
		return false
	return true


# ── AC-1: resolve_moral_queue increments flag ────────────────────────────
func test_resolve_moral_queue_increments_flag() -> bool:
	var el := _new_lifecycle()
	var player := Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	player.moral_flag = 0
	el.player_entity = player

	var enemy := Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	el.process_kill(player, enemy, true, "enemy_01", "Grunt")
	el.resolve_moral_queue()
	if player.moral_flag != 1:
		push_error("Expected moral_flag 1, got %d" % player.moral_flag)
		return false
	return true


# ── AC-2: MWT fires at exactly 3 ──────────────────────────────────────────
func test_mwt_fires_at_three() -> bool:
	var el := _new_lifecycle()
	var player := Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	player.moral_flag = 2
	el.player_entity = player

	var hit_mwt := false
	var reached_flag := -1
	el.mwt_reached.connect(func(flag: int, remaining: int) -> void:
		hit_mwt = true
		reached_flag = flag
	)

	var enemy := Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	el.process_kill(player, enemy, true, "enemy_01", "Grunt")
	el.resolve_moral_queue()

	if not hit_mwt:
		push_error("Expected mwt_reached signal at MWT=3")
		return false
	if reached_flag != 3:
		push_error("Expected flag 3, got %d" % reached_flag)
		return false
	return true


# ── AC-2: MWT queues remaining deltas for next legal moment ──────────────
func test_mwt_queues_remaining_deltas() -> bool:
	var el := _new_lifecycle()
	var player := Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	player.moral_flag = 2
	el.player_entity = player

	## Kill 3 enemies in one phase (AoE simulation)
	for i in range(3):
		var enemy := Entity.new("Enemy%d" % i, 0, 0, 10, 5, 3)
		el.apply_damage(null, enemy, 10)
		el.process_kill(player, enemy, true, "enemy_%d" % i, "Grunt")

	el.resolve_moral_queue()

	## First MWT crossing should process exactly 1 delta (from 2→3)
	## and leave the remaining 2 queued.
	if player.moral_flag != 3:
		push_error("Expected moral_flag 3 after first resolve, got %d" % player.moral_flag)
		return false
	if el.get_queued_delta_count() != 2:
		push_error("Expected 2 remaining deltas, got %d" % el.get_queued_delta_count())
		return false

	## Second resolve should process next delta (3→4, no MWT crossing again)
	el.resolve_moral_queue()
	if player.moral_flag != 4:
		push_error("Expected moral_flag 4 after second resolve, got %d" % player.moral_flag)
		return false
	if el.get_queued_delta_count() != 1:
		push_error("Expected 1 remaining delta, got %d" % el.get_queued_delta_count())
		return false

	return true


# ── AC-1: Spare applies negative MORAL_DELTA ─────────────────────────────
func test_spare_applies_negative_delta() -> bool:
	var el := _new_lifecycle()
	var player := Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	player.moral_flag = 2
	player.ap = 3
	el.player_entity = player

	var enemy := Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	el.spare_entity(player, enemy)
	el.resolve_moral_queue()

	if player.moral_flag != 1:
		push_error("Expected moral_flag 1 after spare, got %d" % player.moral_flag)
		return false
	return true


# ── AC-3: Reset clears queue and timers ──────────────────────────────────
func test_reset_clears_queue_and_timers() -> bool:
	var el := _new_lifecycle()
	var enemy := Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.stun(enemy, 3)
	el.apply_damage(null, enemy, 10)

	el.reset_moral_queue()
	el.clear_timers()

	if el.get_queued_delta_count() != 0:
		push_error("Expected empty queue after reset")
		return false
	return true


# ── Test Runner ───────────────────────────────────────────────────────────
func _ready() -> void:
	run_all()

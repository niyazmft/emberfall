class_name TestEntityLifecycle
extends GdUnitTestSuite


func _new_lifecycle() -> _EntityLifecycle:
	var script: GDScript = load("res://scripts/entities/entity_lifecycle.gd")
	var el: _EntityLifecycle = auto_free(script.new()) as _EntityLifecycle
	add_child(el)
	return el


func test_damage_transitions_to_dying() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var enemy: Entity = Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	assert_that(enemy.hp).is_equal(0)
	assert_that(enemy.state).is_equal(Entity.State.DYING)


func test_heal_reverses_dying() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var enemy: Entity = Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	assert_that(enemy.state).is_equal(Entity.State.DYING)
	el.heal(enemy, 5)
	assert_that(enemy.hp).is_equal(5)
	assert_that(enemy.state).is_equal(Entity.State.IDLE)


func test_stun_timer_resolves_to_idle() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var enemy: Entity = Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.stun(enemy, 1)
	assert_that(enemy.state).is_equal(Entity.State.STUNNED)
	el.process_end_of_turn()
	assert_that(enemy.state).is_equal(Entity.State.IDLE)


func test_dying_timer_resolves_to_dead() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var enemy: Entity = Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	assert_that(enemy.state).is_equal(Entity.State.DYING)
	el.process_end_of_turn()
	assert_that(enemy.state).is_equal(Entity.State.DEAD)


func test_spare_transitions_to_ghost() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	player.ap = 3
	el.player_entity = player

	var enemy: Entity = Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	var ok: bool = el.spare_entity(player, enemy)

	assert_that(ok).is_true()
	assert_that(enemy.state).is_equal(Entity.State.GHOST)
	assert_that(player.ap).is_equal(2)


func test_process_kill_queues_moral_delta() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	el.player_entity = player

	var enemy: Entity = Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	el.process_kill(player, enemy, true, "enemy_01", "Grunt")
	assert_that(el.get_queued_delta_count()).is_equal(1)


func test_resolve_moral_queue_increments_flag() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	player.moral_flag = 0
	el.player_entity = player

	var enemy: Entity = Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	el.process_kill(player, enemy, true, "enemy_01", "Grunt")
	el.resolve_moral_queue()
	assert_that(player.moral_flag).is_equal(1)


func test_mwt_fires_at_three() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	player.moral_flag = 2
	el.player_entity = player

	var results := {"hit": false, "flag": -1}
	el.mwt_reached.connect(
		func(flag: int, _remaining: int) -> void:
			results.hit = true
			results.flag = flag
	)

	var enemy: Entity = Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	el.process_kill(player, enemy, true, "enemy_01", "Grunt")
	el.resolve_moral_queue()

	assert_that(results.hit).is_true()
	assert_that(results.flag).is_equal(3)


func test_mwt_queues_remaining_deltas() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	player.moral_flag = 2
	el.player_entity = player

	for i: int in range(3):
		var enemy: Entity = Entity.new("Enemy%d" % i, 0, 0, 10, 5, 3)
		el.apply_damage(null, enemy, 10)
		el.process_kill(player, enemy, true, "enemy_%d" % i, "Grunt")

	el.resolve_moral_queue()

	assert_that(player.moral_flag).is_equal(3)
	assert_that(el.get_queued_delta_count()).is_equal(2)

	el.resolve_moral_queue()
	assert_that(player.moral_flag).is_equal(5)
	assert_that(el.get_queued_delta_count()).is_equal(0)


func test_spare_applies_negative_delta() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	player.moral_flag = 2
	player.ap = 3
	el.player_entity = player

	var enemy: Entity = Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.apply_damage(null, enemy, 10)
	el.spare_entity(player, enemy)
	el.resolve_moral_queue()

	assert_that(player.moral_flag).is_equal(1)


func test_reset_clears_queue_and_timers() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var enemy: Entity = Entity.new("TestEnemy", 0, 0, 10, 5, 3)
	el.stun(enemy, 3)
	el.apply_damage(null, enemy, 10)

	el.reset_moral_queue()
	el.clear_timers()

	assert_that(el.get_queued_delta_count()).is_equal(0)

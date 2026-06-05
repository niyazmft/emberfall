extends GdUnitTestSuite

var _player: Node2D
var _enemy1: Node2D
var _enemy2: Node2D
var _turn_manager: TurnManager


func before_test() -> void:
	_player = auto_free(Node2D.new())
	var p_ent = Entity.new("Player", 0, 0, 10, 5, 5)
	p_ent.is_player = true
	p_ent.spd = 10
	_player.set("entity", p_ent)
	_player.set_script(load("res://scripts/entities/keeper.gd"))

	_enemy1 = auto_free(Node2D.new())
	var e1_ent = Entity.new("Enemy1", 1, 1, 10, 5, 5)
	e1_ent.is_player = false
	e1_ent.spd = 5
	_enemy1.set("entity", e1_ent)
	_enemy1.set_script(load("res://scripts/entities/base_enemy.gd"))

	_enemy2 = auto_free(Node2D.new())
	var e2_ent = Entity.new("Enemy2", 2, 2, 10, 5, 5)
	e2_ent.is_player = false
	e2_ent.spd = 15
	_enemy2.set("entity", e2_ent)
	_enemy2.set_script(load("res://scripts/entities/base_enemy.gd"))

	_turn_manager = auto_free(TurnManager.new())
	add_child(_turn_manager)


func test_initiative_sorting() -> void:
	_turn_manager.start_combat(_player, [_enemy1, _enemy2])

	# Order should be Enemy2 (15), Player (10), Enemy1 (5)
	assert_int(_turn_manager.turn_order.size()).is_equal(3)
	assert_object(_turn_manager.turn_order[0]).is_equal(_enemy2)
	assert_object(_turn_manager.turn_order[1]).is_equal(_player)
	assert_object(_turn_manager.turn_order[2]).is_equal(_enemy1)


func test_turn_progression() -> void:
	_turn_manager.start_combat(_player, [_enemy1, _enemy2])

	# Round 1 started, Enemy2 turn (auto-executes and ends)
	# Wait for Enemy2 and Player turns
	assert_int(_turn_manager.round_number).is_equal(1)

	# Since Enemy2 is AI, it should have auto-executed and moved to next turn
	# Which is Player turn.
	assert_int(_turn_manager.current_state).is_equal(TurnManager.CombatState.PLAYER_TURN)
	assert_object(_turn_manager.turn_order[_turn_manager.current_turn_index]).is_equal(_player)

	_turn_manager.end_player_turn()

	# Should move to Enemy1 turn, then back to Initiative Phase -> Round 2
	# Enemy1 is AI, so it auto-executes.
	# So it should be Round 2, Enemy2 turn (auto-executes), then Player Turn.
	assert_int(_turn_manager.round_number).is_equal(2)
	assert_int(_turn_manager.current_state).is_equal(TurnManager.CombatState.PLAYER_TURN)


func test_ap_regeneration() -> void:
	var p_ent: Entity = _player.get("entity")
	p_ent.ap = 2

	_turn_manager.start_combat(_player, [_enemy1, _enemy2])
	# Enemy2 turn happens, then Player turn starts
	# AP should regen by GameConstants.AP_REGEN (2)
	assert_int(p_ent.ap).is_equal(4)

	_turn_manager.end_player_turn()
	# Round 2 starts, Player turn starts again
	assert_int(p_ent.ap).is_equal(6)  # 4 + 2 = 6 (AP_MAX)


func test_combat_victory() -> void:
	_turn_manager.start_combat(_player, [_enemy1, _enemy2])

	var e1_ent: Entity = _enemy1.get("entity")
	var e2_ent: Entity = _enemy2.get("entity")

	e1_ent.hp = 0
	e1_ent.state = Entity.State.DEAD
	e2_ent.hp = 0
	e2_ent.state = Entity.State.DEAD

	# Manually trigger check
	_turn_manager._change_state(TurnManager.CombatState.CHECK_END_CONDITIONS)

	assert_int(_turn_manager.current_state).is_equal(TurnManager.CombatState.COMBAT_END)
	# Signal checking in GdUnit4 is a bit different but let's assume this is enough for now


func test_combat_defeat() -> void:
	_turn_manager.start_combat(_player, [_enemy1, _enemy2])

	var p_ent: Entity = _player.get("entity")
	p_ent.hp = 0
	p_ent.state = Entity.State.DEAD

	_turn_manager._change_state(TurnManager.CombatState.CHECK_END_CONDITIONS)

	assert_int(_turn_manager.current_state).is_equal(TurnManager.CombatState.COMBAT_END)

extends GdUnitTestSuite
const __source = "res://scripts/combat/turn_manager.gd"


class MockCombatant:
	extends CombatEntity

	func _init(p_entity: Entity) -> void:
		entity = p_entity

	func alive() -> bool:
		return entity.hp > 0

	func take_turn() -> void:
		pass


var _player: MockCombatant
var _enemy1: MockCombatant
var _enemy2: MockCombatant
var _turn_manager: TurnManager


#region setup
func before_test() -> void:
	var p_ent: Entity = Entity.new("Player", 0, 0, 10, 5, 5)
	p_ent.is_player = true
	p_ent.spd = 10
	_player = auto_free(MockCombatant.new(p_ent)) as MockCombatant

	var e1_ent: Entity = Entity.new("Enemy1", 1, 1, 10, 5, 5)
	e1_ent.is_player = false
	e1_ent.spd = 5
	_enemy1 = auto_free(MockCombatant.new(e1_ent)) as MockCombatant

	var e2_ent: Entity = Entity.new("Enemy2", 2, 2, 10, 5, 5)
	e2_ent.is_player = false
	e2_ent.spd = 15
	_enemy2 = auto_free(MockCombatant.new(e2_ent)) as MockCombatant

	_turn_manager = auto_free(TurnManager.new()) as TurnManager
	add_child(_turn_manager)


#endregion


#region initiative_tests
func test_initiative_sorting() -> void:
	_turn_manager.start_combat(_player, [_enemy1, _enemy2])

	# Order should be Enemy2 (15), Player (10), Enemy1 (5)
	assert_int(_turn_manager.turn_order.size()).is_equal(3)
	assert_object(_turn_manager.turn_order[0]).is_equal(_enemy2)
	assert_object(_turn_manager.turn_order[1]).is_equal(_player)
	assert_object(_turn_manager.turn_order[2]).is_equal(_enemy1)


#endregion


#region turn_progression_tests
func test_turn_progression() -> void:
	_turn_manager.start_combat(_player, [_enemy1, _enemy2])

	# Round 1 started, Enemy2 turn (auto-executes and ends)
	assert_int(_turn_manager.round_number).is_equal(1)

	# Since Enemy2 is AI, it should have auto-executed and moved to next turn
	# Which is Player turn.
	assert_int(_turn_manager.current_state).is_equal(TurnManager.CombatState.PLAYER_TURN)
	assert_object(_turn_manager.turn_order[_turn_manager.current_turn_index]).is_equal(_player)

	_turn_manager.end_player_turn()

	# Should move to Enemy1 turn (auto-executes), then back to Initiative Phase -> Round 2
	# Enemy2 (Round 2) auto-executes, then Player Turn.
	assert_int(_turn_manager.round_number).is_equal(2)
	assert_int(_turn_manager.current_state).is_equal(TurnManager.CombatState.PLAYER_TURN)


#endregion


#region ap_economy_tests
func test_ap_regeneration() -> void:
	var p_ent: Entity = _player.entity
	p_ent.ap = GameConstants.AP_REGEN

	_turn_manager.start_combat(_player, [_enemy1, _enemy2])
	# Player turn starts
	# AP should regen by GameConstants.AP_REGEN (2)
	var expected: int = DeterministicMath.clampi(
		GameConstants.AP_REGEN + GameConstants.AP_REGEN, 0, GameConstants.AP_MAX
	)
	assert_int(p_ent.ap).is_equal(expected)

	_turn_manager.end_player_turn()
	# Round 2 starts, Player turn starts again
	expected = DeterministicMath.clampi(expected + GameConstants.AP_REGEN, 0, GameConstants.AP_MAX)
	assert_int(p_ent.ap).is_equal(expected)


#endregion


#region combat_end_tests
func test_combat_victory() -> void:
	var results: Dictionary = {"victory": false, "emitted": false}
	_turn_manager.combat_ended.connect(
		func(v: bool) -> void:
			results.victory = v
			results.emitted = true
	)

	_turn_manager.start_combat(_player, [_enemy1, _enemy2])

	var e1_ent: Entity = _enemy1.entity
	var e2_ent: Entity = _enemy2.entity
	e1_ent.hp = 0
	e2_ent.hp = 0

	# Manually trigger check
	_turn_manager.current_state = TurnManager.CombatState.CHECK_END_CONDITIONS
	_turn_manager._process_state_loop()

	assert_int(_turn_manager.current_state).is_equal(TurnManager.CombatState.COMBAT_END)
	# combat_ended is now delayed by 1.5s; wait for it
	await get_tree().create_timer(2.0).timeout
	assert_bool(results.emitted).is_true()
	assert_bool(results.victory).is_true()


func test_combat_defeat() -> void:
	var results: Dictionary = {"victory": true, "emitted": false}
	_turn_manager.combat_ended.connect(
		func(v: bool) -> void:
			results.victory = v
			results.emitted = true
	)

	_turn_manager.start_combat(_player, [_enemy1, _enemy2])

	var p_ent: Entity = _player.entity
	p_ent.hp = 0

	_turn_manager.current_state = TurnManager.CombatState.CHECK_END_CONDITIONS
	_turn_manager._process_state_loop()

	assert_int(_turn_manager.current_state).is_equal(TurnManager.CombatState.COMBAT_END)
	assert_bool(results.emitted).is_true()
	assert_bool(results.victory).is_false()

#endregion

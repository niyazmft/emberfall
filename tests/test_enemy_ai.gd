extends GdUnitTestSuite

var _grid: _GridSystem
var _player: Keeper
var _enemy: BaseEnemy
var _ai: EnemyAIController


func before_test() -> void:
	_grid = _GridSystem.new()
	# Manually add to tree if needed by AutoloadHelper, but here we can just inject it
	# Actually, simple_ai.gd uses AutoloadHelper.grid_system() if not provided.
	# Better to provide it.

	_player = Keeper.new()
	_player.entity = Entity.new("Player", 5, 5, 100, 10, 10)
	_player.entity.is_player = true
	add_child(_player)
	_player.add_to_group("player")

	_enemy = BaseEnemy.new()
	_enemy.entity = Entity.new("Enemy", 8, 8, 50, 10, 5)
	add_child(_enemy)
	_enemy.add_to_group("enemies")

	_ai = EnemyAIController.new()
	_ai.grid_system = _grid
	_ai.enemy_entity = _enemy.entity
	_enemy.ai_controller = _ai
	_enemy.add_child(_ai)


func test_grunt_moves_towards_player() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.GRUNT
	_enemy.entity.set_grid_position(8, 8)
	_player.entity.set_grid_position(5, 5)

	var action := _ai.decide_action()

	assert_dict(action).contains_key("type")
	assert_str(action["type"]).is_equal("move")

	# Should move from (8,8) towards (5,5)
	# Distance is 3. Any move that reduces distance is fine.
	# _get_next_tile_towards should pick (7,7)
	assert_int(action["target_x"]).is_equal(7)
	assert_int(action["target_y"]).is_equal(7)


func test_grunt_attacks_adjacent_player() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.GRUNT
	_enemy.entity.set_grid_position(6, 5)
	_player.entity.set_grid_position(5, 5)

	var action := _ai.decide_action()

	assert_dict(action).contains_key("type")
	assert_str(action["type"]).is_equal("attack")
	assert_object(action["target"]).is_equal(_player)


func test_archer_moves_away_when_too_close() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.ARCHER
	_enemy.entity.set_grid_position(6, 5)
	_player.entity.set_grid_position(5, 5)

	var action := _ai.decide_action()

	assert_dict(action).contains_key("type")
	assert_str(action["type"]).is_equal("move")
	# Distance is 1, Archer wants 2-3. Should move away.
	# (7,5) or (7,6) or (7,4) etc.
	# _get_next_tile_towards(player, true)
	var dist_after := max(abs(action["target_x"] - 5), abs(action["target_y"] - 5))
	assert_int(dist_after).is_greater_than(1)


func test_archer_attacks_at_range_2() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.ARCHER
	_enemy.entity.set_grid_position(7, 5)
	_player.entity.set_grid_position(5, 5)

	var action := _ai.decide_action()

	assert_dict(action).contains_key("type")
	assert_str(action["type"]).is_equal("attack")


func test_archer_moves_towards_when_too_far() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.ARCHER
	_enemy.entity.set_grid_position(10, 5)
	_player.entity.set_grid_position(5, 5)

	var action := _ai.decide_action()

	assert_dict(action).contains_key("type")
	assert_str(action["type"]).is_equal("move")
	assert_int(action["target_x"]).is_equal(9)


func test_tank_behavior_is_grunt_like() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.TANK
	_enemy.entity.set_grid_position(8, 8)
	_player.entity.set_grid_position(5, 5)

	var action := _ai.decide_action()
	assert_str(action["type"]).is_equal("move")


func test_ai_avoids_occupied_tiles() -> void:
	# Add another enemy at (7,7)
	var other_enemy := BaseEnemy.new()
	other_enemy.entity = Entity.new("Blocker", 7, 7, 50, 10, 5)
	add_child(other_enemy)
	other_enemy.add_to_group("enemies")

	_ai.behavior = EnemyAIController.BehaviorType.GRUNT
	_enemy.entity.set_grid_position(8, 8)
	_player.entity.set_grid_position(5, 5)

	var action := _ai.decide_action()

	assert_str(action["type"]).is_equal("move")
	# Should NOT move to (7,7) because it's occupied
	assert_bool(action["target_x"] == 7 and action["target_y"] == 7).is_false()

	# Should still move towards player, e.g. (7,8) or (8,7)
	var dist_after := max(abs(action["target_x"] - 5), abs(action["target_y"] - 5))
	assert_int(dist_after).is_less_than(3)


func test_base_enemy_facing_updates_on_move() -> void:
	_enemy.entity.set_grid_position(8, 8)
	_enemy.entity.set_facing(0, 1)

	var action := {"type": "move", "target_x": 7, "target_y": 7}
	_enemy._execute_action(action)

	assert_int(_enemy.entity.x).is_equal(7)
	assert_int(_enemy.entity.y).is_equal(7)
	assert_int(_enemy.entity.facing_x).is_equal(-1)
	assert_int(_enemy.entity.facing_y).is_equal(-1)


func test_base_enemy_consumes_ap_on_move() -> void:
	_enemy.entity.ap = 10
	var action := {"type": "move", "target_x": 7, "target_y": 8}
	_enemy._execute_action(action)

	assert_int(_enemy.entity.ap).is_equal(9)

	action = {"type": "move", "target_x": 6, "target_y": 7}
	_enemy._execute_action(action)
	assert_int(_enemy.entity.ap).is_equal(7)  # Diagonal move costs 2

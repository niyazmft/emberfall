extends GdUnitTestSuite

var _grid: _GridSystem
var _player: Keeper
var _enemy: BaseEnemy
var _ai: EnemyAIController


func before_test() -> void:
	_grid = _GridSystem.new()
	_grid._reset_grid()

	_player = Keeper.new()
	_player.entity = Entity.new("Player", 5, 5, 100, 10, 10)
	_player.entity.is_player = true
	add_child(_player)
	_player.add_to_group("player")

	_enemy = BaseEnemy.new()
	_enemy.entity = Entity.new("Enemy", 8, 8, 50, 10, 5)
	_enemy._grid_system = _grid  # Inject grid system
	add_child(_enemy)
	_enemy.add_to_group("enemies")

	_ai = EnemyAIController.new()
	_ai.grid_system = _grid
	_ai.enemy_entity = _enemy.entity
	_enemy.ai_controller = _ai
	_enemy.add_child(_ai)


func after_test() -> void:
	if is_instance_valid(_ai):
		_ai.free()
	if is_instance_valid(_enemy):
		_enemy.free()
	if is_instance_valid(_player):
		_player.free()
	if is_instance_valid(_grid):
		_grid.free()


func test_grunt_moves_towards_player() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.GRUNT
	_enemy.entity.set_grid_position(8, 8)
	_player.entity.set_grid_position(5, 5)

	var action: Dictionary = _ai.decide_action()

	assert_that(action.has("type")).is_true()
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

	var action: Dictionary = _ai.decide_action()

	assert_that(action.has("type")).is_true()
	assert_str(action["type"]).is_equal("attack")

	# Normalize target so tests accept Node or Dictionary formats (DON-Coordinator)
	var returned_target: Variant = action.get("target")
	if returned_target is Dictionary:
		if returned_target.has("node"):
			returned_target = returned_target["node"]
		elif returned_target.has("entity"):
			returned_target = returned_target["entity"]

	assert_object(returned_target).is_equal(_player)


func test_archer_moves_away_when_too_close() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.ARCHER
	_enemy.entity.set_grid_position(6, 5)
	_player.entity.set_grid_position(5, 5)
	var dist_before: int = max(
		abs(_enemy.entity.grid_position().x - 5), abs(_enemy.entity.grid_position().y - 5)
	)

	var action: Dictionary = _ai.decide_action()

	assert_that(action.has("type")).is_true()
	assert_str(action["type"]).is_equal("move")
	# Distance is 1, Archer wants 2-3. Should move away.
	# (7,5) or (7,6) or (7,4) etc.
	var dist_after: int = max(abs(action["target_x"] - 5), abs(action["target_y"] - 5))
	assert_int(dist_after).is_greater(dist_before)


func test_archer_attacks_at_range_2() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.ARCHER
	_enemy.entity.set_grid_position(7, 5)
	_player.entity.set_grid_position(5, 5)

	var action: Dictionary = _ai.decide_action()

	assert_that(action.has("type")).is_true()
	assert_str(action["type"]).is_equal("attack")


func test_archer_moves_towards_when_too_far() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.ARCHER
	_enemy.entity.set_grid_position(10, 5)
	_player.entity.set_grid_position(5, 5)

	var action: Dictionary = _ai.decide_action()

	assert_that(action.has("type")).is_true()
	assert_str(action["type"]).is_equal("move")
	assert_int(action["target_x"]).is_equal(9)


func test_tank_behavior_is_grunt_like() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.TANK
	_enemy.entity.set_grid_position(8, 8)
	_player.entity.set_grid_position(5, 5)

	var action: Dictionary = _ai.decide_action()
	assert_str(action["type"]).is_equal("move")


func test_ai_avoids_occupied_tiles() -> void:
	# Add another enemy at (7,7)
	var other_enemy: BaseEnemy = BaseEnemy.new()
	other_enemy.entity = Entity.new("Blocker", 7, 7, 50, 10, 5)
	add_child(other_enemy)
	other_enemy.add_to_group("enemies")

	_ai.behavior = EnemyAIController.BehaviorType.GRUNT
	_enemy.entity.set_grid_position(8, 8)
	_player.entity.set_grid_position(5, 5)

	var action: Dictionary = _ai.decide_action()

	assert_str(action["type"]).is_equal("move")
	# Should NOT move to (7,7) because it's occupied
	assert_bool(action["target_x"] == 7 and action["target_y"] == 7).is_false()

	# Should still move towards player, e.g. (7,8) or (8,7)
	# With blocker at (7,7), best available tiles are distance 3 (e.g. (7,8) or (8,7))
	var dist_after: int = max(abs(action["target_x"] - 5), abs(action["target_y"] - 5))
	assert_int(dist_after).is_equal(3)

	other_enemy.free()


func test_base_enemy_facing_updates_on_move() -> void:
	_enemy.entity.set_grid_position(8, 8)
	_enemy.entity.set_facing(0, 1)

	var action: Dictionary = {"type": "move", "target_x": 7, "target_y": 7}
	_enemy._execute_action(action)

	assert_int(_enemy.entity.grid_position().x).is_equal(7)
	assert_int(_enemy.entity.grid_position().y).is_equal(7)
	assert_int(_enemy.entity.facing_x).is_equal(-1)
	assert_int(_enemy.entity.facing_y).is_equal(-1)


func test_base_enemy_consumes_ap_on_move() -> void:
	_enemy.entity.ap = 6
	var action: Dictionary = {"type": "move", "target_x": 7, "target_y": 8}
	_enemy._execute_action(action)

	assert_int(_enemy.entity.ap).is_equal(5)

	action = {"type": "move", "target_x": 6, "target_y": 7}
	_enemy._execute_action(action)
	assert_int(_enemy.entity.ap).is_equal(3)  # Diagonal move costs 2


func test_archer_retreat_logic() -> void:
	# Replace generic AI with ArcherAI
	_enemy.remove_child(_ai)
	_ai.free()
	_ai = ArcherAI.new()
	_ai.grid_system = _grid
	_ai.enemy_entity = _enemy.entity
	_enemy.ai_controller = _ai
	_enemy.add_child(_ai)

	# Manually set parameters to ensure we are in retreat mode
	_ai.retreat_hp_threshold = 0.5
	_enemy.entity.hp_max = 100
	_enemy.entity.hp = 20  # 20% < 50% threshold
	_enemy.entity.set_grid_position(5, 5)
	_player.entity.set_grid_position(0, 0)
	var dist_before: int = 5

	var action: Dictionary = _ai.decide_action()
	assert_str(action["type"]).is_equal("move")

	if action["type"] == "move":
		var dist_after: int = max(abs(action["target_x"] - 0), abs(action["target_y"] - 0))
		# In an empty 12x12 grid, moving away from (0,0) from (5,5) should be possible.
		# e.g., to (6,6), which is distance 6.
		assert_int(dist_after).is_greater(dist_before)


func test_archer_elevation_preference() -> void:
	# Replace generic AI with ArcherAI
	_enemy.remove_child(_ai)
	if is_instance_valid(_ai):
		_ai.free()
	_ai = ArcherAI.new()
	_ai.grid_system = _grid
	_ai.enemy_entity = _enemy.entity
	_enemy.ai_controller = _ai
	_enemy.add_child(_ai)

	_enemy.entity.archetype_id = "archer"
	_ai._load_params()

	_enemy.entity.set_grid_position(5, 5)
	_player.entity.set_grid_position(10, 5)  # Directly to the right

	# Make (6,5) mid elevation (so it's reachable from (5,5) which is ground)
	# Other neighbors like (6,4) and (6,6) remain ground.
	var high_tile: TacTileData = _grid.get_tile(6, 5)
	high_tile.elevation = TacTileData.Elevation.MID
	high_tile.recompute_flags()

	var action: Dictionary = _ai.decide_action()
	assert_str(action["type"]).is_equal("move")
	# Archer should prefer the mid elevation tile at (6,5) over ground neighbors
	if action["type"] == "move":
		assert_int(action["target_x"]).is_equal(6)
		assert_int(action["target_y"]).is_equal(5)

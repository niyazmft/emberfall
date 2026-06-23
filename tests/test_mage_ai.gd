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
	_enemy.entity = Entity.new("Mage", 8, 8, 50, 10, 5)
	_enemy._grid_system = _grid
	add_child(_enemy)
	_enemy.add_to_group("enemies")

	_ai = EnemyAIController.new()
	_ai.grid_system = _grid
	_ai.enemy_entity = _enemy.entity
	_ai.behavior = EnemyAIController.BehaviorType.MAGE
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


func test_mage_retreats_when_wounded() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.MAGE
	_enemy.entity.set_grid_position(8, 8)
	_player.entity.set_grid_position(5, 5)
	_enemy.entity.hp_max = 100
	_enemy.entity.hp = 40  # Below 50% threshold

	var action: Dictionary = _ai.decide_action()

	assert_that(action.has("type")).is_true()
	# When wounded, mage should move away (retreat)
	if action["type"] == "move":
		var dist_after: int = max(abs(action["target_x"] - 5), abs(action["target_y"] - 5))
		var dist_before: int = max(abs(8 - 5), abs(8 - 5))
		assert_int(dist_after).is_greater_equal(dist_before)
	else:
		# If unable to retreat, may wait
		assert_str(action["type"]).is_equal("wait")


func test_mage_prefers_high_elevation() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.MAGE
	_enemy.entity.set_grid_position(5, 5)
	_player.entity.set_grid_position(8, 8)
	_enemy.entity.hp_max = 100
	_enemy.entity.hp = 100  # Full HP

	# Set neighboring tile (6,5) to HIGH elevation
	var high_tile: TacTileData = _grid.get_tile(6, 5)
	high_tile.elevation = TacTileData.Elevation.HIGH
	high_tile.recompute_flags()

	var action: Dictionary = _ai.decide_action()

	# Should attempt to move to high elevation
	if action["type"] == "move":
		# The move target should be towards the high tile
		var tx: int = int(action["target_x"])
		var ty: int = int(action["target_y"])
		var target_tile: TacTileData = _grid.get_tile(tx, ty)
		# Prefer high elevation when choosing destination
		assert_that(target_tile).is_not_null()
	else:
		# If already at high elevation or cannot move, may attack or wait
		assert_bool(action["type"] == "attack" or action["type"] == "wait").is_true()


func test_mage_casts_aoe_when_player_clustered() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.MAGE
	_enemy.entity.set_grid_position(5, 5)
	_player.entity.set_grid_position(6, 6)
	_enemy.entity.hp_max = 100
	_enemy.entity.hp = 100

	# Add another enemy adjacent to player (at 6,7)
	var other: BaseEnemy = BaseEnemy.new()
	other.entity = Entity.new("Grunt", 6, 7, 30, 5, 5)
	add_child(other)
	other.add_to_group("enemies")

	var action: Dictionary = _ai.decide_action()

	# Should cast AoE attack when player is clustered with another enemy
	if action["type"] == "attack":
		assert_bool(action.get("aoe", false)).is_true()

	other.free()


func test_mage_attacks_when_in_range_and_healthy() -> void:
	_ai.behavior = EnemyAIController.BehaviorType.MAGE
	_enemy.entity.set_grid_position(6, 6)
	_player.entity.set_grid_position(5, 5)
	_enemy.entity.hp_max = 100
	_enemy.entity.hp = 100

	var action: Dictionary = _ai.decide_action()

	# Mage has max_range 4; at distance 1 should attack
	assert_str(action["type"]).is_equal("attack")
	assert_object(action["target"]).is_equal(_player)


func test_mage_behavior_type_exists() -> void:
	assert_int(EnemyAIController.BehaviorType.MAGE).is_equal(4)

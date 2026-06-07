# tests/test_progression_system.gd
extends GdUnitTestSuite

var _player: Entity
var _enemy: Entity
var _level_up_manager: _LevelUpManager
var _orig_player: Entity


func before_test() -> void:
	_player = Entity.new("Player", 0, 0, 40, 10, 5)
	_player.is_player = true

	_enemy = Entity.new("Grunt", 0, 0, 30, 8, 4)
	_enemy.archetype_id = "grunt"

	# Manually setup LevelUpManager for testing
	_level_up_manager = _LevelUpManager.new()
	add_child(_level_up_manager)

	# Manually set the player entity in lifecycle so LevelUpManager can find it
	if AutoloadHelper.entity_lifecycle():
		_orig_player = AutoloadHelper.entity_lifecycle().player_entity
		AutoloadHelper.entity_lifecycle().player_entity = _player


func after_test() -> void:
	if AutoloadHelper.entity_lifecycle():
		AutoloadHelper.entity_lifecycle().player_entity = _orig_player
	_level_up_manager.queue_free()


func test_experience_gain() -> void:
	assert_that(_player.experience).is_equal(0)
	_level_up_manager.grant_experience(_player, 50, "test")
	assert_that(_player.experience).is_equal(50)
	assert_that(_player.level).is_equal(1)


func test_level_up() -> void:
	# Level 2 threshold is 100 according to config/progression.json
	assert_that(_player.level).is_equal(1)

	_level_up_manager.grant_experience(_player, 100, "test")

	assert_that(_player.level).is_equal(2)
	# Check stat growth for level 2: { "hp_max": 10, "off": 2, "def": 1, "spd": 0 }
	assert_that(_player.hp_max).is_equal(50)  # 40 + 10
	assert_that(_player.off).is_equal(12)  # 10 + 2
	assert_that(_player.def_).is_equal(6)  # 5 + 1


func test_multiple_level_ups() -> void:
	# Level 3 threshold is 250
	_level_up_manager.grant_experience(_player, 300, "test")
	assert_that(_player.level).is_equal(3)
	# Cumulative growth for level 2 & 3:
	# L2: hp+10, off+2, def+1, spd+0
	# L3: hp+10, off+2, def+1, spd+1
	# Total: hp+20, off+4, def+2, spd+1
	assert_that(_player.hp_max).is_equal(60)  # 40 + 20
	assert_that(_player.off).is_equal(14)  # 10 + 4
	assert_that(_player.def_).is_equal(7)  # 5 + 2
	assert_that(_player.spd).is_equal(2)  # 1 (default) + 1 = 2


func test_combat_xp_award() -> void:
	# Simulate EventBus signal for execution
	# Grunt base XP is 20
	_level_up_manager._on_spare_or_execute(_enemy, false)  # Execute
	assert_that(_player.experience).is_equal(20)

	# Simulate EventBus signal for spare
	# Grunt base XP is 20, spare multiplier 1.5 -> 30
	_level_up_manager._on_spare_or_execute(_enemy, true)  # Spare
	assert_that(_player.experience).is_equal(50)  # 20 + 30


func test_formula_evaluation() -> void:
	var context_map: Dictionary = {"base_xp": 100, "spare_bonus_multiplier": 2.0}
	var result_val: int = _level_up_manager._evaluate_formula(
		"base_xp * spare_bonus_multiplier", context_map
	)
	assert_that(result_val).is_equal(200)

	result_val = _level_up_manager._evaluate_formula("base_xp + 50", context_map)
	assert_that(result_val).is_equal(150)

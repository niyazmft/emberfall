extends GdUnitTestSuite

var _grid: _GridSystem


func before_test() -> void:
	_grid = auto_free(_GridSystem.new()) as _GridSystem
	_grid._reset_grid()


func test_enemy_grunt_variety() -> void:
	var grunt_scene := load("res://scenes/enemies/enemy_grunt.tscn")
	var grunt: EnemyGrunt = auto_free(grunt_scene.instantiate()) as EnemyGrunt
	grunt._grid_system = _grid
	add_child(grunt)

	assert_that(grunt.entity.entity_name).is_equal("Grunt")
	assert_that(grunt.entity.hp_max).is_equal(30)
	assert_that(grunt.entity.off).is_equal(8)
	assert_that(grunt.entity.def_).is_equal(4)
	assert_that(grunt.entity.spd).is_equal(4)

	assert_that(grunt.ai_controller.behavior).is_equal(EnemyAIController.BehaviorType.GRUNT)
	assert_that(grunt.debug_color).is_equal(Color.WHITE)
	assert_that(grunt.visual_proxy.modulate).is_equal(Color.WHITE)


func test_enemy_archer_variety() -> void:
	var archer_scene := load("res://scenes/enemies/enemy_archer.tscn")
	var archer: EnemyArcher = auto_free(archer_scene.instantiate()) as EnemyArcher
	archer._grid_system = _grid
	add_child(archer)

	assert_that(archer.entity.entity_name).is_equal("Archer")
	assert_that(archer.entity.hp_max).is_equal(25)
	assert_that(archer.entity.off).is_equal(6)
	assert_that(archer.entity.def_).is_equal(2)
	assert_that(archer.entity.spd).is_equal(5)

	assert_that(archer.ai_controller.behavior).is_equal(EnemyAIController.BehaviorType.ARCHER)
	assert_that(archer.debug_color).is_equal(Color.GREEN)
	assert_that(archer.visual_proxy.modulate).is_equal(Color.GREEN)


func test_enemy_tank_variety() -> void:
	var tank_scene := load("res://scenes/enemies/enemy_tank.tscn")
	var tank: EnemyTank = auto_free(tank_scene.instantiate()) as EnemyTank
	tank._grid_system = _grid
	add_child(tank)

	assert_that(tank.entity.entity_name).is_equal("Tank")
	assert_that(tank.entity.hp_max).is_equal(60)
	assert_that(tank.entity.off).is_equal(15)
	assert_that(tank.entity.def_).is_equal(8)
	assert_that(tank.entity.spd).is_equal(2)

	assert_that(tank.ai_controller.behavior).is_equal(EnemyAIController.BehaviorType.TANK)
	assert_that(tank.debug_color).is_equal(Color.BLUE)
	assert_that(tank.visual_proxy.modulate).is_equal(Color.BLUE)
	assert_that(tank.visual_scale).is_equal(1.2)
	assert_that(tank.visual_proxy.scale).is_equal(Vector2(1.2, 1.2))

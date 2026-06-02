extends GdUnitTestSuite


func test_alive_returns_false_when_entity_null() -> void:
	var enemy_scene: BaseEnemy = auto_free(BaseEnemy.new())
	enemy_scene.entity = null
	assert_that(enemy_scene.alive()).is_false()


func test_alive_returns_true_when_entity_idle() -> void:
	var enemy_scene: BaseEnemy = auto_free(BaseEnemy.new())
	var ent: Entity = Entity.new("Test", 0, 0, 10, 5, 3)
	ent.state = Entity.State.IDLE
	enemy_scene.entity = ent
	assert_that(enemy_scene.alive()).is_true()


func test_alive_returns_true_when_entity_stunned() -> void:
	var enemy_scene: BaseEnemy = auto_free(BaseEnemy.new())
	var ent: Entity = Entity.new("Test", 0, 0, 10, 5, 3)
	ent.state = Entity.State.STUNNED
	enemy_scene.entity = ent
	assert_that(enemy_scene.alive()).is_true()


func test_alive_returns_true_when_entity_dying() -> void:
	var enemy_scene: BaseEnemy = auto_free(BaseEnemy.new())
	var ent: Entity = Entity.new("Test", 0, 0, 10, 5, 3)
	ent.state = Entity.State.DYING
	enemy_scene.entity = ent
	assert_that(enemy_scene.alive()).is_true()


func test_alive_returns_false_when_entity_dead() -> void:
	var enemy_scene: BaseEnemy = auto_free(BaseEnemy.new())
	var ent: Entity = Entity.new("Test", 0, 0, 10, 5, 3)
	ent.state = Entity.State.DEAD
	enemy_scene.entity = ent
	assert_that(enemy_scene.alive()).is_false()


func test_alive_returns_false_when_entity_ghost() -> void:
	var enemy_scene: BaseEnemy = auto_free(BaseEnemy.new())
	var ent: Entity = Entity.new("Test", 0, 0, 10, 5, 3)
	ent.state = Entity.State.GHOST
	enemy_scene.entity = ent
	assert_that(enemy_scene.alive()).is_false()

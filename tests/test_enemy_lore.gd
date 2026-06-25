extends GdUnitTestSuite


func test_grunt_has_lore_text() -> void:
	var enemy: BaseEnemy = BaseEnemy.new()
	enemy.archetype_id = "grunt"
	add_child(enemy)
	await get_tree().process_frame

	var lore: String = enemy.get_lore_text()
	assert_that(lore).is_not_empty()
	assert_that(lore).is_not_equal("ENEMY_LORE_GRUNT")

	enemy.queue_free()
	await get_tree().process_frame


func test_archer_has_lore_text() -> void:
	var enemy: BaseEnemy = BaseEnemy.new()
	enemy.archetype_id = "archer"
	add_child(enemy)
	await get_tree().process_frame

	var lore: String = enemy.get_lore_text()
	assert_that(lore).is_not_empty()
	assert_that(lore).is_not_equal("ENEMY_LORE_ARCHER")

	enemy.queue_free()
	await get_tree().process_frame


func test_tank_has_lore_text() -> void:
	var enemy: BaseEnemy = BaseEnemy.new()
	enemy.archetype_id = "tank"
	add_child(enemy)
	await get_tree().process_frame

	var lore: String = enemy.get_lore_text()
	assert_that(lore).is_not_empty()
	assert_that(lore).is_not_equal("ENEMY_LORE_TANK")

	enemy.queue_free()
	await get_tree().process_frame


func test_mage_has_lore_text() -> void:
	var enemy: BaseEnemy = BaseEnemy.new()
	enemy.archetype_id = "mage"
	add_child(enemy)
	await get_tree().process_frame

	var lore: String = enemy.get_lore_text()
	assert_that(lore).is_not_empty()
	assert_that(lore).is_not_equal("ENEMY_LORE_MAGE")

	enemy.queue_free()
	await get_tree().process_frame


func test_boss_has_lore_text() -> void:
	var enemy: BaseEnemy = BaseEnemy.new()
	enemy.archetype_id = "boss"
	add_child(enemy)
	await get_tree().process_frame

	var lore: String = enemy.get_lore_text()
	assert_that(lore).is_not_empty()
	assert_that(lore).is_not_equal("ENEMY_LORE_BOSS")

	enemy.queue_free()
	await get_tree().process_frame

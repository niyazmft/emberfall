extends GdUnitTestSuite


func test_leader_enemy_has_badge_node() -> void:
	var enemy: BaseEnemy = BaseEnemy.new()
	enemy.is_leader = true
	add_child(enemy)
	await get_tree().process_frame

	var badge: Node = enemy.get_node_or_null("LeaderBadge")
	assert_that(badge).is_not_null()

	if badge is Sprite2D:
		var sprite: Sprite2D = badge as Sprite2D
		assert_bool(sprite.modulate.r > 0.8).is_true()
		assert_bool(sprite.modulate.g > 0.7).is_true()
		assert_bool(sprite.modulate.b < 0.2).is_true()

	enemy.queue_free()
	await get_tree().process_frame


func test_non_leader_has_no_badge() -> void:
	var enemy: BaseEnemy = BaseEnemy.new()
	enemy.is_leader = false
	add_child(enemy)
	await get_tree().process_frame

	var badge: Node = enemy.get_node_or_null("LeaderBadge")
	assert_that(badge).is_null()

	enemy.queue_free()
	await get_tree().process_frame


func test_leader_flag_propagates_from_encounter() -> void:
	## Verify that _spawn_encounter passes the leader flag to the enemy instance.
	var container := Node2D.new()
	var enemies_node := Node2D.new()
	add_child(container)
	container.add_child(enemies_node)

	var encounter: Dictionary = {
		"enemy_type": "grunt",
		"positions": [{"x": 5, "y": 5}],
		"leader": true,
	}

	RoomLoader._spawn_encounter(encounter, container, enemies_node)
	await get_tree().process_frame

	assert_int(enemies_node.get_child_count()).is_equal(1)
	var spawned: Node = enemies_node.get_child(0)
	if spawned is BaseEnemy:
		var be: BaseEnemy = spawned as BaseEnemy
		assert_bool(be.is_leader).is_true()
		var badge: Node = be.get_node_or_null("LeaderBadge")
		assert_that(badge).is_not_null()

	container.queue_free()
	await get_tree().process_frame


func test_encounter_system_returns_leader_flags() -> void:
	## Build encounters for biome2 which has heavy_patrol (tank leader + 2 grunts).
	var encounters: Array = EncounterSystem.buildEncounters("biome2", 12345, 3)
	assert_bool(encounters.is_empty()).is_false()

	var leader_count: int = 0
	var non_leader_count: int = 0
	for enc_v: Variant in encounters:
		if enc_v is Dictionary:
			var enc: Dictionary = enc_v as Dictionary
			if bool(enc.get("leader", false)):
				leader_count += 1
			else:
				non_leader_count += 1

	assert_int(leader_count).is_greater(0)
	assert_int(non_leader_count).is_greater(0)


func test_group_templates_have_leader_entries() -> void:
	var config: Dictionary = EncounterSystem._getConfig()
	var groups: Dictionary = config.get("group_templates", {}) as Dictionary
	assert_bool(groups.is_empty()).is_false()

	var has_leader: bool = false
	for group_id: String in groups:
		var entries: Array = groups[group_id] as Array
		for entry_v: Variant in entries:
			if entry_v is Dictionary:
				var entry: Dictionary = entry_v as Dictionary
				if bool(entry.get("leader", false)):
					has_leader = true
					break
		if has_leader:
			break

	assert_bool(has_leader).is_true()

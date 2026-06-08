extends GdUnitTestSuite

const RoomLoader = preload("res://scripts/combat/room_loader.gd")

func test_mage_and_boss_spawn() -> void:
	var container := Node2D.new()
	var enemies_node := Node2D.new()
	add_child(container)
	container.add_child(enemies_node)

	var room_data: Dictionary = {
		"player_start": {"x": 0, "y": 0},
		"encounters": [
			{
				"enemy_type": "mage",
				"positions": [{"x": 1, "y": 1}]
			},
			{
				"enemy_type": "boss",
				"positions": [{"x": 2, "y": 2}]
			}
		]
	}

	RoomLoader.spawn_entities(room_data, container, enemies_node)

	var enemies: Array = enemies_node.get_children()
	assert_int(enemies.size()).is_equal(2)

	var mage: Node2D = enemies[0] as Node2D
	var boss: Node2D = enemies[1] as Node2D

	assert_str(mage.get_class()).is_equal("Node2D")
	assert_str(mage.script.resource_path).is_equal("res://scripts/entities/enemies/enemy_mage.gd")
	assert_str(mage.get("archetype_id")).is_equal("mage")

	assert_str(boss.get_class()).is_equal("Node2D")
	assert_str(boss.script.resource_path).is_equal("res://scripts/entities/enemies/enemy_boss.gd")
	assert_str(boss.get("archetype_id")).is_equal("boss")

	# Clean up
	container.free()

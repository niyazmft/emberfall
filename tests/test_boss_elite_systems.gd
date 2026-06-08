extends GdUnitTestSuite


func test_elite_modifiers_stat_scaling() -> void:
	var enemy_scene: BaseEnemy = auto_free(BaseEnemy.new())
	enemy_scene.archetype_id = "grunt"
	enemy_scene.elite_type = "bulwark"

	# Manually trigger ready logic to load stats
	enemy_scene._ready()

	var entity: Entity = enemy_scene.entity
	# Base grunt: HP 30, OFF 8, DEF 4, SPD 4
	# Bulwark: HP x2, OFF x0.8, DEF x2, SPD x0.7
	# Expected: HP 60, OFF 6, DEF 8, SPD 2

	assert_that(entity.hp_max).is_equal(60)
	assert_that(entity.off).is_equal(6)
	assert_that(entity.def_).is_equal(8)
	assert_that(entity.spd).is_equal(2)
	assert_that(entity.entity_name).is_equal("Bulwark Grunt")


func test_boss_ai_delegation() -> void:
	var enemy_scene: BaseEnemy = auto_free(BaseEnemy.new())
	var ai_controller: EnemyAIController = auto_free(EnemyAIController.new())
	enemy_scene.ai_controller = ai_controller
	enemy_scene.archetype_id = "overgrown_guardian"

	# overgrown_guardian has ai_behavior: "OVERGROWN_GUARDIAN" in config
	enemy_scene._ready()

	assert_that(ai_controller.behavior).is_equal(EnemyAIController.BehaviorType.BOSS)
	assert_that(ai_controller.boss_behavior_name).is_equal("OVERGROWN_GUARDIAN")

	# Test behavior override
	enemy_scene.behavior_override = "OVERGROWN_GUARDIAN"
	enemy_scene._setup_ai()
	assert_that(ai_controller.boss_behavior_name).is_equal("OVERGROWN_GUARDIAN")


func test_room_loader_boss_spawning() -> void:
	var room_data: Dictionary = {
		"id": "test_boss_room",
		"encounters":
		[
			{
				"enemy_type": "boss",
				"archetype_override": "overgrown_guardian",
				"behavior_override": "OVERGROWN_GUARDIAN",
				"elite_type": "vanguard",
				"count": 1,
				"positions": [{"x": 5, "y": 5}]
			}
		],
		"player_start": {"x": 1, "y": 1}
	}

	var container: Node = auto_free(Node.new())
	var enemies_node: Node = auto_free(Node.new())

	# We need to mock or ensure ENEMY_SCENES are accessible.
	# RoomLoader uses ENEMY_SCENES which maps "boss" to "grunt" by default if not found.
	# Actually "boss" is not in ENEMY_SCENES, so it will use "grunt" scene but with overrides.

	RoomLoader.spawn_entities(room_data, container, enemies_node)

	assert_that(enemies_node.get_child_count()).is_greater(0)
	var boss_node: Node2D = enemies_node.get_child(0) as Node2D
	assert_that(boss_node).is_not_null()
	assert_that(boss_node.get("archetype_id")).is_equal("overgrown_guardian")
	assert_that(boss_node.get("behavior_override")).is_equal("OVERGROWN_GUARDIAN")
	assert_that(boss_node.get("elite_type")).is_equal("vanguard")

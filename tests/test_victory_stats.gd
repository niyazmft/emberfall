extends GdUnitTestSuite

const COMBAT_ROOM_SCENE = "res://scenes/combat_room.tscn"


func test_victory_data_aggregation() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: CombatRoom = runner.scene() as CombatRoom

	# 1. Setup room with specific encounter seed for deterministic shards
	var room_data: Dictionary = {
		"room_id": "test_room",
		"encounter_seed": 12345,  # This seed should produce a specific shard count
		"biome": 0,
		"layout": {"elevation": [], "cover": [], "blocked": [], "vision_blocked": []},
		"player_start": {"x": 2, "y": 2},
		"encounters": [{"enemy_type": "grunt", "positions": [{"x": 5, "y": 5}]}]
	}
	# Initialize layout arrays
	for i: int in range(144):
		room_data["layout"]["elevation"].append(0)
		room_data["layout"]["cover"].append(0)
		room_data["layout"]["blocked"].append(false)
		room_data["layout"]["vision_blocked"].append(false)

	room.call("_on_room_entered", 0, room_data)

	# 2. Simulate killing an enemy
	var eb := AutoloadHelper.event_bus()
	var enemy_entity := Entity.new("Enemy", 5, 5, 10, 5, 2)
	enemy_entity.is_player = false

	# Initial state IDLE
	eb.entity_state_changed.emit(enemy_entity, Entity.State.IDLE, Entity.State.DEAD)

	assert_int(room.get("_room_kills")).is_equal(1)

	# 3. Verify shard calculation
	# rewards.json has victory_reward: min 20, max 50 (range 31)
	var expected_shards: int = room.call("_calculate_shards")
	assert_int(expected_shards).is_greater_equal(20)
	assert_int(expected_shards).is_less_equal(50)

	# Let's double check another kill
	var enemy_entity_2 := Entity.new("Enemy2", 6, 6, 10, 5, 2)
	enemy_entity_2.is_player = false
	eb.entity_state_changed.emit(enemy_entity_2, Entity.State.IDLE, Entity.State.GHOST)
	assert_int(room.get("_room_kills")).is_equal(2)

	# Check that player state change doesn't increment kills
	var player_entity := Entity.new("Player", 2, 2, 10, 5, 2)
	player_entity.is_player = true
	eb.entity_state_changed.emit(player_entity, Entity.State.IDLE, Entity.State.DEAD)
	assert_int(room.get("_room_kills")).is_equal(2)

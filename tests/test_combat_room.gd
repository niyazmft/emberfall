extends GdUnitTestSuite

const COMBAT_ROOM_SCENE = "res://scenes/combat_room.tscn"


func test_room_initialization() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: Node = runner.scene()

	assert_that(room.get_node_or_null("GridRenderer")).is_not_null()
	assert_that(room.get_node_or_null("EntityContainer")).is_not_null()
	assert_that(room.get_node_or_null("UIOverlay")).is_not_null()
	assert_that(room.get_node_or_null("Camera2D")).is_not_null()


func test_entity_spawning() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: Node = runner.scene()

	# Manually trigger test encounter to ensure entities exist regardless of RunManager state
	room.call("_load_demo_room")

	var entity_container: Node2D = room.get_node("EntityContainer") as Node2D
	assert_int(entity_container.get_child_count()).is_greater(0)

	var enemies_node: Node2D = room.get("_enemies_node") as Node2D
	assert_that(enemies_node).is_not_null()
	if enemies_node:
		# Should be > 0. Exact count varies with scaling/procedural logic
		assert_int(enemies_node.get_child_count()).is_greater(0)


func test_camera_setup() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: Node = runner.scene()

	# Camera should be positioned near the center of the grid
	var grid_renderer: Node2D = room.get_node("GridRenderer") as Node2D
	var center_pos: Vector2 = grid_renderer.call("grid_to_world", 5, 5, 0)
	var camera: Camera2D = room.get_node("Camera2D") as Camera2D
	assert_that(camera.position).is_equal(center_pos)


func test_manual_room_entry() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: Node = runner.scene()

	var room_data: Dictionary = {
		"room_id": "test_room",
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

	var enemies_node: Node2D = room.get("_enemies_node") as Node2D
	assert_that(enemies_node).is_not_null()
	if enemies_node:
		assert_int(enemies_node.get_child_count()).is_equal(1)

	var player: Node2D = room.get("_player") as Node2D
	assert_that(player).is_not_null()
	if player:
		var player_entity := CombatEntity.get_entity(player)
		assert_that(player_entity).is_not_null()
		if player_entity:
			assert_int(player_entity.x).is_equal(2)
			assert_int(player_entity.y).is_equal(2)

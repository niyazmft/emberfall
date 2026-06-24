extends GdUnitTestSuite

const COMBAT_ROOM_SCENE := "res://scenes/combat_room.tscn"


func test_props_node_exists() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: CombatRoom = runner.scene() as CombatRoom
	assert_that(room).is_not_null()

	var props: Node2D = room.get_node_or_null("Environment/Props")
	assert_that(props).is_not_null()


func test_props_spawn_on_room_enter() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: CombatRoom = runner.scene() as CombatRoom
	assert_that(room).is_not_null()

	var room_data: Dictionary = {
		"room_id": "test_props",
		"encounter_seed": 77777,
		"biome": 0,
		"layout": {"elevation": [], "cover": [], "blocked": [], "vision_blocked": []},
		"player_start": {"x": 1, "y": 1},
		"encounters": [{"enemy_type": "grunt", "positions": [{"x": 5, "y": 5}]}]
	}
	for i: int in range(144):
		room_data["layout"]["elevation"].append(0)
		room_data["layout"]["cover"].append(0)
		room_data["layout"]["blocked"].append(false)
		room_data["layout"]["vision_blocked"].append(false)

	room.call("_on_room_entered", 0, room_data)
	await get_tree().process_frame

	var props: Node2D = room.get_node_or_null("Environment/Props")
	assert_that(props).is_not_null()
	assert_int(props.get_child_count()).is_greater_equal(2)

	# Verify props are ColorRect nodes
	for child: Node in props.get_children():
		assert_bool(child is ColorRect).is_true()


func test_props_are_purely_visual() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: CombatRoom = runner.scene() as CombatRoom
	assert_that(room).is_not_null()

	var room_data: Dictionary = {
		"room_id": "test_props_visual",
		"encounter_seed": 88888,
		"biome": 0,
		"layout": {"elevation": [], "cover": [], "blocked": [], "vision_blocked": []},
		"player_start": {"x": 1, "y": 1},
		"encounters": []
	}
	for i: int in range(144):
		room_data["layout"]["elevation"].append(0)
		room_data["layout"]["cover"].append(0)
		room_data["layout"]["blocked"].append(false)
		room_data["layout"]["vision_blocked"].append(false)

	room.call("_on_room_entered", 0, room_data)
	await get_tree().process_frame

	var props: Node2D = room.get_node_or_null("Environment/Props")
	assert_that(props).is_not_null()

	for child: Node in props.get_children():
		# Props should have no collision shapes
		var collision: Node = child.get_node_or_null("CollisionShape2D")
		assert_that(collision).is_null()


func test_props_cleared_between_rooms() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: CombatRoom = runner.scene() as CombatRoom
	assert_that(room).is_not_null()

	var room_data1: Dictionary = {
		"room_id": "room_a",
		"encounter_seed": 11111,
		"biome": 0,
		"layout": {"elevation": [], "cover": [], "blocked": [], "vision_blocked": []},
		"player_start": {"x": 1, "y": 1},
		"encounters": []
	}
	for i: int in range(144):
		room_data1["layout"]["elevation"].append(0)
		room_data1["layout"]["cover"].append(0)
		room_data1["layout"]["blocked"].append(false)
		room_data1["layout"]["vision_blocked"].append(false)

	room.call("_on_room_entered", 0, room_data1)
	await get_tree().process_frame

	var props: Node2D = room.get_node_or_null("Environment/Props")
	var count_first: int = props.get_child_count()
	assert_int(count_first).is_greater_equal(2)

	# Enter different room
	var room_data2: Dictionary = room_data1.duplicate(true)
	room_data2["room_id"] = "room_b"
	room_data2["encounter_seed"] = 22222

	room.call("_on_room_entered", 1, room_data2)
	await get_tree().process_frame

	var count_second: int = props.get_child_count()
	assert_int(count_second).is_greater_equal(2)
	assert_int(count_second).is_less_equal(3)


func test_atmosphere_particles_exist() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: CombatRoom = runner.scene() as CombatRoom
	assert_that(room).is_not_null()

	var particles: Node = room.get_node_or_null("Environment/AtmosphereParticles")
	assert_that(particles).is_not_null()
	assert_bool(particles is CPUParticles2D).is_true()

	var cpu: CPUParticles2D = particles as CPUParticles2D
	assert_bool(cpu.emitting).is_true()

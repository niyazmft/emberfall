extends GdUnitTestSuite

const COMBAT_ROOM_SCENE := "res://scenes/combat_room.tscn"


func test_props_node_exists() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: CombatRoom = runner.scene() as CombatRoom
	assert_that(room).is_not_null()

	var props: Node2D = room.get_node_or_null("Environment/Props")
	assert_that(props).is_not_null()


func test_atmosphere_particles_exist() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COMBAT_ROOM_SCENE)
	var room: CombatRoom = runner.scene() as CombatRoom
	assert_that(room).is_not_null()

	var particles: Node = room.get_node_or_null("Environment/AtmosphereParticles")
	assert_that(particles).is_not_null()
	assert_bool(particles is CPUParticles2D).is_true()

	var cpu: CPUParticles2D = particles as CPUParticles2D
	assert_bool(cpu.emitting).is_true()

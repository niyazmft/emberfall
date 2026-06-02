extends SceneTree


func run_all() -> void:
	var passed: int = 0
	var failed: int = 0
	var tests: Array[String] = [
		"test_alive_returns_false_when_entity_null",
		"test_alive_returns_true_when_entity_idle",
		"test_alive_returns_true_when_entity_stunned",
		"test_alive_returns_true_when_entity_dying",
		"test_alive_returns_false_when_entity_dead",
		"test_alive_returns_false_when_entity_ghost"
	]

	for name: String in tests:
		print("Running %s ..." % name)
		var ok: Variant = call(name)
		if ok is bool and ok:
			passed += 1
			print("  PASS")
		else:
			failed += 1
			print("  FAIL (returned %s)" % str(ok))

	print("")
	print("Results: %d passed, %d failed out of %d" % [passed, failed, tests.size()])
	if failed > 0:
		push_error("BaseEnemy test suite had failures.")
		quit(1)
	else:
		quit(0)


func test_alive_returns_false_when_entity_null() -> bool:
	var enemy_scene: BaseEnemy = BaseEnemy.new()
	enemy_scene.entity = null

	if enemy_scene.alive() != false:
		push_error("Expected alive() to be false when entity is null")
		return false
	return true


func test_alive_returns_true_when_entity_idle() -> bool:
	var enemy_scene: BaseEnemy = BaseEnemy.new()
	var ent: Entity = Entity.new("Test", 0, 0, 10, 5, 3)
	ent.state = Entity.State.IDLE
	enemy_scene.entity = ent

	if enemy_scene.alive() != true:
		push_error("Expected alive() to be true when entity is IDLE")
		return false
	return true


func test_alive_returns_true_when_entity_stunned() -> bool:
	var enemy_scene: BaseEnemy = BaseEnemy.new()
	var ent: Entity = Entity.new("Test", 0, 0, 10, 5, 3)
	ent.state = Entity.State.STUNNED
	enemy_scene.entity = ent

	if enemy_scene.alive() != true:
		push_error("Expected alive() to be true when entity is STUNNED")
		return false
	return true


func test_alive_returns_true_when_entity_dying() -> bool:
	var enemy_scene: BaseEnemy = BaseEnemy.new()
	var ent: Entity = Entity.new("Test", 0, 0, 10, 5, 3)
	ent.state = Entity.State.DYING
	enemy_scene.entity = ent

	if enemy_scene.alive() != true:
		push_error("Expected alive() to be true when entity is DYING")
		return false
	return true


func test_alive_returns_false_when_entity_dead() -> bool:
	var enemy_scene: BaseEnemy = BaseEnemy.new()
	var ent: Entity = Entity.new("Test", 0, 0, 10, 5, 3)
	ent.state = Entity.State.DEAD
	enemy_scene.entity = ent

	if enemy_scene.alive() != false:
		push_error("Expected alive() to be false when entity is DEAD")
		return false
	return true


func test_alive_returns_false_when_entity_ghost() -> bool:
	var enemy_scene: BaseEnemy = BaseEnemy.new()
	var ent: Entity = Entity.new("Test", 0, 0, 10, 5, 3)
	ent.state = Entity.State.GHOST
	enemy_scene.entity = ent

	if enemy_scene.alive() != false:
		push_error("Expected alive() to be false when entity is GHOST")
		return false
	return true


func _initialize() -> void:
	run_all()

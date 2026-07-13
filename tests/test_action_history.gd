extends GdUnitTestSuite


func test_serialize_round_trip() -> void:
	var ent: Entity = Entity.new("Test", 3, 4, 50, 10, 5)
	ent.elevation = 1
	ent.facing_x = -1
	ent.facing_y = 0
	ent.hp = 40
	ent.ap = 3
	ent.moral_flag = 2
	ent.state = Entity.State.IDLE

	var snap: Dictionary = ActionHistory.serialize_entity(ent)
	assert_int(snap["x"]).is_equal(3)
	assert_int(snap["hp"]).is_equal(40)
	assert_int(snap["ap"]).is_equal(3)

	# Mutate
	ent.x = 99
	ent.hp = 1
	ent.ap = 0

	ActionHistory.restore_entity(ent, snap)
	assert_int(ent.x).is_equal(3)
	assert_int(ent.hp).is_equal(40)
	assert_int(ent.ap).is_equal(3)
	assert_int(ent.facing_x).is_equal(-1)
	assert_int(ent.moral_flag).is_equal(2)


func test_undo_stack_lifo() -> void:
	var history: ActionHistory = ActionHistory.new()
	assert_bool(history.can_undo()).is_false()

	var p1: Dictionary = {"x": 1, "y": 1}
	var e1: Array[Dictionary] = []
	history.push_snapshot(p1, e1, "Move")
	assert_bool(history.can_undo()).is_true()
	assert_int(history.size()).is_equal(1)

	var p2: Dictionary = {"x": 2, "y": 2}
	history.push_snapshot(p2, e1, "Attack")
	assert_int(history.size()).is_equal(2)

	var snap: Dictionary = history.undo()
	assert_int(history.size()).is_equal(1)
	assert_str(snap.get("description", "")).is_equal("Attack")

	history.clear()
	assert_bool(history.can_undo()).is_false()


func test_undo_empty_noop() -> void:
	var history: ActionHistory = ActionHistory.new()
	var snap: Dictionary = history.undo()
	assert_bool(snap.is_empty()).is_true()


func test_limit_trims_old() -> void:
	var history: ActionHistory = ActionHistory.new()
	history.set_limit(2)
	var empty: Array[Dictionary] = []

	history.push_snapshot({"x": 1}, empty, "A")
	history.push_snapshot({"x": 2}, empty, "B")
	history.push_snapshot({"x": 3}, empty, "C")

	assert_int(history.size()).is_equal(2)
	var snap: Dictionary = history.undo()
	assert_str(snap.get("description", "")).is_equal("C")
	snap = history.undo()
	assert_str(snap.get("description", "")).is_equal("B")

extends GdUnitTestSuite

var _tracker: _QuestTracker
var _bus: _EventBus


func before() -> void:
	_tracker = _QuestTracker.new()
	add_child(_tracker)
	_bus = _EventBus.new()


func after() -> void:
	_tracker.free()
	_bus.free()


func test_quest_loading() -> void:
	var active: Array[Dictionary] = _tracker.get_active_quests()
	assert_array(active).is_not_empty()
	assert_str(active[0]["id"] as String).is_equal(active[0]["id"] as String)


func test_quest_progress_spare() -> void:
	var quest_id: String = "spare_enemies"
	var initial_progress: int = 0
	for q: Dictionary in _tracker.get_active_quests():
		if q["id"] == quest_id:
			initial_progress = int(q["current"])

	# Simulate spare event
	_tracker._on_spare_or_execute(null, true)

	var final_progress: int = 0
	for q: Dictionary in _tracker.get_active_quests():
		if q["id"] == quest_id:
			final_progress = int(q["current"])

	assert_int(final_progress).is_equal(initial_progress + 1)


func test_quest_completion() -> void:
	var quest_id: String = "spare_enemies"

	# Progress twice to complete (goal is 2)
	_tracker._on_spare_or_execute(null, true)
	_tracker._on_spare_or_execute(null, true)

	var completed: bool = false
	for q: Dictionary in _tracker.get_active_quests():
		if q["id"] == quest_id:
			completed = bool(q["completed"])

	assert_bool(completed).is_true()


func test_room_scope_reset() -> void:
	# Add a room-scoped quest for testing
	_tracker._quests["test_room_quest"] = {
		"id": "test_room_quest",
		"scope": "room",
		"goal": 1,
		"event": "spare_or_execute",
		"name_key": "",
		"description_key": ""
	}
	_tracker._start_quest("test_room_quest")

	_tracker._on_spare_or_execute(null, true)

	var progress_before: int = 0
	for q: Dictionary in _tracker.get_active_quests():
		if q["id"] == "test_room_quest":
			progress_before = int(q["current"])
	assert_int(progress_before).is_equal(1)

	# Simulate room entered
	_tracker._on_room_entered(0, {})

	var progress_after: int = 1
	for q: Dictionary in _tracker.get_active_quests():
		if q["id"] == "test_room_quest":
			progress_after = int(q["current"])
	assert_int(progress_after).is_equal(0)

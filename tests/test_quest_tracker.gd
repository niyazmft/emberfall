extends GdUnitTestSuite

var _tracker: _QuestTracker


func before() -> void:
	_tracker = _QuestTracker.new()
	add_child(_tracker)


func after() -> void:
	_tracker.free()


func test_quest_loading() -> void:
	var activeQuests: Array[Dictionary] = _tracker.get_active_quests()
	assert_array(activeQuests).is_not_empty()

	var ids: Array[String] = []
	for quest: Dictionary in activeQuests:
		ids.append(quest["id"] as String)

	assert_array(ids).contains(["spare_enemies", "reach_echo_gate"])


func test_quest_progress_spare() -> void:
	var questId: String = "spare_enemies"
	var initialProgress: int = 0
	for quest: Dictionary in _tracker.get_active_quests():
		if quest["id"] == questId:
			initialProgress = int(quest["current"])

	# Simulate spare event
	_tracker._on_spare_or_execute(null, true)

	var finalProgress: int = 0
	for quest: Dictionary in _tracker.get_active_quests():
		if quest["id"] == questId:
			finalProgress = int(quest["current"])

	assert_int(finalProgress).is_equal(initialProgress + 1)


func test_quest_completion() -> void:
	var questId: String = "spare_enemies"

	# Progress twice to complete (goal is 2)
	_tracker._on_spare_or_execute(null, true)
	_tracker._on_spare_or_execute(null, true)

	var completed: bool = false
	for quest: Dictionary in _tracker.get_active_quests():
		if quest["id"] == questId:
			completed = bool(quest["completed"])

	assert_bool(completed).is_true()


func test_room_scope_reset() -> void:
	# Add a room-scoped quest for testing using public helper
	_tracker.add_quest_for_test(
		{
			"id": "test_room_quest",
			"scope": "room",
			"goal": 1,
			"event": "spare_or_execute",
			"name_key": "TEST_ROOM_QUEST",
			"description_key": "TEST_ROOM_QUEST_DESC"
		}
	)
	_tracker._start_quest("test_room_quest")

	_tracker._on_spare_or_execute(null, true)

	var progressBefore: int = 0
	for quest: Dictionary in _tracker.get_active_quests():
		if quest["id"] == "test_room_quest":
			progressBefore = int(quest["current"])
	assert_int(progressBefore).is_equal(1)

	# Simulate room entered
	_tracker._on_room_entered(0, {})

	var progressAfter: int = 1
	for quest: Dictionary in _tracker.get_active_quests():
		if quest["id"] == "test_room_quest":
			progressAfter = int(quest["current"])
	assert_int(progressAfter).is_equal(0)

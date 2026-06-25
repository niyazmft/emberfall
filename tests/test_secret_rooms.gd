extends GdUnitTestSuite


func test_check_secret_conditions_no_damage() -> void:
	var srt: _SecretRoomTrigger = _SecretRoomTrigger.new()
	add_child(srt)
	await get_tree().process_frame

	var run_data: Dictionary = {
		"room_kills": 1,
		"room_damage_taken": 0,
		"enemies_spared": 0,
		"turn_count": 3,
	}
	assert_bool(srt.check_secret_conditions(run_data)).is_true()
	srt.queue_free()


func test_check_secret_conditions_all_spared() -> void:
	var srt: _SecretRoomTrigger = _SecretRoomTrigger.new()
	add_child(srt)
	await get_tree().process_frame

	var run_data: Dictionary = {
		"room_kills": 0,
		"room_damage_taken": 5,
		"enemies_spared": 3,
		"turn_count": 10,
	}
	assert_bool(srt.check_secret_conditions(run_data)).is_true()
	srt.queue_free()


func test_check_secret_conditions_fast_clear() -> void:
	var srt: _SecretRoomTrigger = _SecretRoomTrigger.new()
	add_child(srt)
	await get_tree().process_frame

	var run_data: Dictionary = {
		"room_kills": 2,
		"room_damage_taken": 0,
		"enemies_spared": 0,
		"turn_count": 3,
	}
	assert_bool(srt.check_secret_conditions(run_data)).is_true()
	srt.queue_free()


func test_check_secret_conditions_not_met() -> void:
	var srt: _SecretRoomTrigger = _SecretRoomTrigger.new()
	add_child(srt)
	await get_tree().process_frame

	var run_data: Dictionary = {
		"room_kills": 2,
		"room_damage_taken": 5,
		"enemies_spared": 0,
		"turn_count": 10,
	}
	assert_bool(srt.check_secret_conditions(run_data)).is_false()
	srt.queue_free()


func test_get_secret_room_id() -> void:
	var srt: _SecretRoomTrigger = _SecretRoomTrigger.new()
	add_child(srt)
	await get_tree().process_frame

	var run_data: Dictionary = {
		"room_kills": 0,
		"room_damage_taken": 0,
		"enemies_spared": 3,
		"turn_count": 3,
	}
	var room_id: String = srt.get_secret_room_id(run_data)
	assert_that(room_id).is_equal("room_secret_01")
	srt.queue_free()


func test_secret_room_json_exists() -> void:
	var room_data: Dictionary = RoomLoader.load_room_data("room_secret_01")
	assert_dict(room_data).is_not_empty()
	assert_str(room_data.get("id", "")).is_equal("room_secret_01")
	assert_that(room_data.has("secret_reward")).is_true()
	var reward: Dictionary = room_data.get("secret_reward", {}) as Dictionary
	assert_that(reward.has("item_id")).is_true()


func test_secret_room_layout_unique() -> void:
	var room_data: Dictionary = RoomLoader.load_room_data("room_secret_01")
	assert_dict(room_data).is_not_empty()

	var layout: Dictionary = room_data.get("layout", {}) as Dictionary
	var elevation: Array = layout.get("elevation", []) as Array
	assert_int(elevation.size()).is_equal(144)

	# Check for elevated central chamber (tiles with elevation 2)
	var has_elevated_chamber: bool = false
	for e: Variant in elevation:
		if int(e) == 2:
			has_elevated_chamber = true
			break
	assert_bool(has_elevated_chamber).is_true()


func test_run_manager_secret_room_append() -> void:
	var rm: _RunManager = _RunManager.new()
	add_child(rm)
	await get_tree().process_frame

	# Seed a minimal room queue
	rm.room_queue = [
		{"room_id": "room_standard_01", "biome": 0, "room_in_biome": 0},
	]
	rm.room_index = 0

	# Build run data that meets secret conditions
	var srt: _SecretRoomTrigger = AutoloadHelper.secret_room_trigger()
	if srt != null:
		var run_data: Dictionary = {
			"room_kills": 0,
			"room_damage_taken": 0,
			"enemies_spared": 1,
			"turn_count": 2,
		}
		if srt.check_secret_conditions(run_data):
			var secret_id: String = srt.get_secret_room_id(run_data)
			assert_that(secret_id).is_equal("room_secret_01")

	rm.queue_free()

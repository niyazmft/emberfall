extends GdUnitTestSuite


func test_tutorial_room_json_valid() -> void:
	var data := RoomLoader.load_room_data("room_tutorial")
	assert_dict(data).is_not_empty()
	assert_str(data.get("id", "")).is_equal("room_tutorial")
	assert_dict(data.get("layout", {})).is_not_empty()

	var layout: Dictionary = data["layout"] as Dictionary
	assert_int(layout["elevation"].size()).is_equal(144)
	assert_int(layout["cover"].size()).is_equal(144)
	assert_int(layout["blocked"].size()).is_equal(144)
	assert_int(layout["vision_blocked"].size()).is_equal(144)

	var encounters: Array = data.get("encounters", []) as Array
	assert_int(encounters.size()).is_equal(1)
	var encounter: Dictionary = encounters[0] as Dictionary
	assert_str(encounter.get("enemy_type", "")).is_equal("grunt")
	assert_int(encounter.get("count", 0)).is_equal(1)

	var player_start: Dictionary = data.get("player_start", {}) as Dictionary
	assert_int(player_start.get("x", -1)).is_equal(1)
	assert_int(player_start.get("y", -1)).is_equal(1)

	var hint: String = str(data.get("tutorial_hint", ""))
	assert_bool(not hint.is_empty()).is_true()


func test_tutorial_room_data_helper_returns_valid_dict() -> void:
	var cr := CombatRoom.new()
	add_child(cr)
	await get_tree().process_frame

	var room_data: Dictionary = cr._load_tutorial_room_data()
	assert_dict(room_data).is_not_empty()
	assert_str(room_data.get("id", "")).is_equal("room_tutorial")
	assert_int(room_data["layout"]["elevation"].size()).is_equal(144)
	assert_int(room_data["encounters"].size()).is_equal(1)

	var encounter: Dictionary = room_data["encounters"][0] as Dictionary
	assert_str(encounter.get("enemy_type", "")).is_equal("grunt")
	assert_int(encounter.get("count", 0)).is_equal(1)

	cr.queue_free()
	await get_tree().process_frame

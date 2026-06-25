extends GdUnitTestSuite


func test_tutorial_room_json_valid() -> void:
	var data := RoomLoader.load_room_data("room_tutorial")
	assert_dict(data).is_not_empty()
	assert_str(data.get("id", "")).is_equal("room_tutorial")
	assert_dict(data.get("layout", {})).is_not_empty()

	var layout: Dictionary = data["layout"] as Dictionary
	assert_int(int(layout["elevation"].size())).is_equal(144)
	assert_int(int(layout["cover"].size())).is_equal(144)
	assert_int(int(layout["blocked"].size())).is_equal(144)
	assert_int(int(layout["vision_blocked"].size())).is_equal(144)

	var encounters: Array = data.get("encounters", []) as Array
	assert_int(encounters.size()).is_equal(1)
	var encounter: Dictionary = encounters[0] as Dictionary
	assert_str(encounter.get("enemy_type", "")).is_equal("grunt")
	assert_float(float(encounter.get("count", 0))).is_equal(1.0)

	var player_start: Dictionary = data.get("player_start", {}) as Dictionary
	assert_float(float(player_start.get("x", -1))).is_equal(1.0)
	assert_float(float(player_start.get("y", -1))).is_equal(1.0)

	var hint: String = str(data.get("tutorial_hint", ""))
	assert_bool(not hint.is_empty()).is_true()


func test_tutorial_room_has_flat_floor() -> void:
	var data := RoomLoader.load_room_data("room_tutorial")
	var layout: Dictionary = data["layout"] as Dictionary
	var elev: Array = layout["elevation"] as Array
	var cover: Array = layout["cover"] as Array

	for i: int in range(elev.size()):
		assert_float(float(elev[i])).is_equal(0.0)
	for i: int in range(cover.size()):
		assert_float(float(cover[i])).is_equal(0.0)


func test_tutorial_room_localization_keys_exist() -> void:
	var lm: _LocalizationManager = AutoloadHelper.localization_manager()
	if lm == null:
		return

	for key: String in ["TUTORIAL_MOVE_HINT", "TUTORIAL_ATTACK_HINT", "TUTORIAL_END_TURN_HINT"]:
		var text: String = lm.tr(key)
		assert_bool(not text.is_empty()).is_true()
		assert_bool(text != key).is_true()

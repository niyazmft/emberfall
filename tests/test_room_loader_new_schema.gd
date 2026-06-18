extends GdUnitTestSuite


func test_load_new_schema() -> void:
	var data := RoomLoader.load_room_data("test_new_schema")

	assert_dict(data).is_not_empty()
	assert_dict(data.get("layout", {})).is_not_empty()

	var layout: Dictionary = data.get("layout", {})
	var cover: Array = layout.get("cover", [])
	var blocked: Array = layout.get("blocked", [])

	# Verify cover (y * 12 + x)
	# (5, 5) -> 5 * 12 + 5 = 65
	assert_int(cover[65]).is_equal(1)  # light
	# (6, 6) -> 6 * 12 + 6 = 78
	assert_int(cover[78]).is_equal(2)  # heavy

	# Verify blocked (0, 0) -> 0
	assert_bool(blocked[0]).is_true()

	# Verify encounters
	var encounters: Array = data.get("encounters", [])
	assert_int(encounters.size()).is_equal(2)

	var grunt_found := false
	var archer_found := false
	for enc: Dictionary in encounters:
		if enc["enemy_type"] == "grunt":
			grunt_found = true
			assert_int(enc["count"]).is_equal(1)
			assert_int(enc["positions"][0]["x"]).is_equal(8)
		if enc["enemy_type"] == "archer":
			archer_found = true
			assert_int(enc["count"]).is_equal(1)
			assert_int(enc["positions"][0]["x"]).is_equal(9)

	assert_bool(grunt_found).is_true()
	assert_bool(archer_found).is_true()

	# Verify player start
	var ps: Dictionary = data.get("player_start", {})
	assert_int(ps.get("x", 0)).is_equal(1)
	assert_int(ps.get("y", 0)).is_equal(1)

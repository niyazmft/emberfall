extends GdUnitTestSuite


func test_room_template_basic_patrol() -> void:
	var room_data: Dictionary = {"encounter_template": "basic_patrol"}
	var encounters: Array = EncounterSystem.buildEncounters("biome1", 12345, 5, room_data)
	assert_that(encounters).is_not_empty()

	var hasGrunt: bool = false
	for enc_v: Variant in encounters:
		if enc_v is Dictionary:
			var enc: Dictionary = enc_v as Dictionary
			if str(enc.get("enemy_type", "")) == "grunt":
				hasGrunt = true
				assert_int(int(enc.get("count", 0))).is_equal(2)
	assert_bool(hasGrunt).is_true()


func test_room_template_narrow_corridor() -> void:
	var room_data: Dictionary = {"encounter_template": "narrow_corridor"}
	# narrow_corridor = [tank(leader), grunt, archer]
	# In biome1: tank -> archer (fallback), grunt -> grunt, archer -> archer
	# Result: 2x archer (1 leader) + 1x grunt
	var encounters: Array = EncounterSystem.buildEncounters("biome1", 12345, 5, room_data)
	assert_that(encounters).is_not_empty()

	var hasArcher: bool = false
	var hasLeader: bool = false
	var hasGrunt: bool = false
	for enc_v: Variant in encounters:
		if enc_v is Dictionary:
			var enc: Dictionary = enc_v as Dictionary
			var t: String = str(enc.get("enemy_type", ""))
			if t == "archer":
				hasArcher = true
				if bool(enc.get("leader", false)):
					hasLeader = true
			if t == "grunt":
				hasGrunt = true
	assert_bool(hasArcher).is_true()
	assert_bool(hasLeader).is_true()
	assert_bool(hasGrunt).is_true()


func test_room_template_elevated_archers() -> void:
	var room_data: Dictionary = {"encounter_template": "elevated_archers"}
	var encounters: Array = EncounterSystem.buildEncounters("biome1", 12345, 5, room_data)
	assert_that(encounters).is_not_empty()

	var hasArcher: bool = false
	var hasLeader: bool = false
	for enc_v: Variant in encounters:
		if enc_v is Dictionary:
			var enc: Dictionary = enc_v as Dictionary
			if str(enc.get("enemy_type", "")) == "archer":
				hasArcher = true
				if bool(enc.get("leader", false)):
					hasLeader = true
	assert_bool(hasArcher).is_true()
	assert_bool(hasLeader).is_true()


func test_fallback_to_biome_when_no_template() -> void:
	var room_data: Dictionary = {}
	var encounters: Array = EncounterSystem.buildEncounters("biome1", 12345, 5, room_data)
	assert_that(encounters).is_not_empty()


func test_fallback_to_biome_when_template_not_found() -> void:
	var room_data: Dictionary = {"encounter_template": "nonexistent_template"}
	var encounters: Array = EncounterSystem.buildEncounters("biome1", 12345, 5, room_data)
	assert_that(encounters).is_not_empty()


func test_room_standard_01_has_encounter_template() -> void:
	var data: Dictionary = RoomLoader.load_room_data("room_standard_01")
	assert_dict(data).is_not_empty()
	assert_that(data.has("encounter_template")).is_true()
	assert_str(str(data.get("encounter_template", ""))).is_equal("basic_patrol")


func test_room_standard_02_has_encounter_template() -> void:
	var data: Dictionary = RoomLoader.load_room_data("room_standard_02")
	assert_dict(data).is_not_empty()
	assert_that(data.has("encounter_template")).is_true()
	assert_str(str(data.get("encounter_template", ""))).is_equal("narrow_corridor")


func test_room_standard_03_has_encounter_template() -> void:
	var data: Dictionary = RoomLoader.load_room_data("room_standard_03")
	assert_dict(data).is_not_empty()
	assert_that(data.has("encounter_template")).is_true()
	assert_str(str(data.get("encounter_template", ""))).is_equal("elevated_archers")

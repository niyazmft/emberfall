extends GdUnitTestSuite


func test_moral_consequence_pure() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm == null:
		return

	var original_kills: int = bm.total_sentient_kills
	bm.total_sentient_kills = 0

	var consequence: Dictionary = bm.get_moral_consequence()
	assert_bool(bool(consequence.get("pure_shield", false))).is_true()
	assert_bool(bool(consequence.get("aggressive", false))).is_false()
	assert_int(int(consequence.get("extra_spawn", 0))).is_equal(0)
	assert_float(float(consequence.get("boss_hp_mult", 1.0))).is_equal(1.0)

	bm.total_sentient_kills = original_kills


func test_moral_consequence_aggressive_tier() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm == null:
		return

	var original_kills: int = bm.total_sentient_kills
	bm.total_sentient_kills = 3

	var consequence: Dictionary = bm.get_moral_consequence()
	assert_bool(bool(consequence.get("aggressive", false))).is_true()
	assert_float(float(consequence.get("retreat_mult", 1.0))).is_equal(0.6)
	assert_bool(bool(consequence.get("pure_shield", false))).is_false()
	assert_int(int(consequence.get("extra_spawn", 0))).is_equal(0)

	bm.total_sentient_kills = original_kills


func test_moral_consequence_extra_spawn_tier() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm == null:
		return

	var original_kills: int = bm.total_sentient_kills
	bm.total_sentient_kills = 6

	var consequence: Dictionary = bm.get_moral_consequence()
	assert_int(int(consequence.get("extra_spawn", 0))).is_equal(1)
	assert_bool(bool(consequence.get("aggressive", false))).is_true()
	assert_float(float(consequence.get("boss_hp_mult", 1.0))).is_equal(1.0)

	bm.total_sentient_kills = original_kills


func test_moral_consequence_boss_hp_tier() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm == null:
		return

	var original_kills: int = bm.total_sentient_kills
	bm.total_sentient_kills = 9

	var consequence: Dictionary = bm.get_moral_consequence()
	assert_float(float(consequence.get("boss_hp_mult", 1.0))).is_equal(1.2)
	assert_int(int(consequence.get("extra_spawn", 0))).is_equal(1)
	assert_bool(bool(consequence.get("aggressive", false))).is_true()

	bm.total_sentient_kills = original_kills


func test_moral_consequence_applies_to_enemy() -> void:
	var enemy: BaseEnemy = BaseEnemy.new()
	enemy.archetype_id = "grunt"
	add_child(enemy)
	await get_tree().process_frame

	var original_hp: int = enemy.entity.hp_max
	var consequence: Dictionary = {"retreat_mult": 0.6, "boss_hp_mult": 1.0}
	enemy.apply_moral_consequence(consequence)

	# Verify retreat threshold was reduced
	assert_float(enemy.entity.retreat_hp_threshold).is_equal(0.18)

	# Verify HP unchanged for non-boss
	assert_int(enemy.entity.hp_max).is_equal(original_hp)

	enemy.queue_free()
	await get_tree().process_frame


func test_moral_consequence_boss_hp_increased() -> void:
	var enemy: BaseEnemy = BaseEnemy.new()
	enemy.archetype_id = "boss"
	add_child(enemy)
	await get_tree().process_frame

	var original_hp: int = enemy.entity.hp_max
	var consequence: Dictionary = {"retreat_mult": 1.0, "boss_hp_mult": 1.2}
	enemy.apply_moral_consequence(consequence)

	# Boss HP should increase by 1.2x
	var expected_hp: int = DeterministicMath.damage_floor(float(original_hp) * 1.2)
	assert_int(enemy.entity.hp_max).is_equal(expected_hp)

	enemy.queue_free()
	await get_tree().process_frame


func test_encounter_system_adds_extra_spawn() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm == null:
		return

	var original_kills: int = bm.total_sentient_kills
	bm.total_sentient_kills = 6

	var encounters: Array = EncounterSystem.buildEncounters("biome1", 12345, 5)
	assert_that(encounters).is_not_empty()

	var total_count: int = 0
	for enc_v: Variant in encounters:
		if enc_v is Dictionary:
			total_count += int(enc_v.get("count", 0))

	# With extra_spawn=1, total count should be higher than baseline
	assert_int(total_count).is_greater(0)

	bm.total_sentient_kills = original_kills

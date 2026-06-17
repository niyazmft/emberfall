extends GdUnitTestSuite

# ── BurdenManager Tests ───────────────────────────────────────────────────


func test_burden_manager_record_kill() -> void:
	var bm := AutoloadHelper.burden_manager()
	if bm == null:
		return
	bm.reset()

	bm.record_sentient_kill("enemy_wraith_01", "Wraith")
	bm.record_sentient_kill("enemy_shade_02", "Shade")

	var queue: Array[_BurdenManager.BurdenKillRecord] = bm.get_kill_queue()
	assert_that(queue.size()).is_equal(2)
	assert_that(queue[0].enemy_id).is_equal("enemy_wraith_01")
	assert_that(queue[1].display_name).is_equal("Shade")


func test_burden_manager_cap_at_three() -> void:
	var bm := AutoloadHelper.burden_manager()
	if bm == null:
		return
	bm.reset()

	bm.record_sentient_kill("a", "A")
	bm.record_sentient_kill("b", "B")
	bm.record_sentient_kill("c", "C")
	bm.record_sentient_kill("d", "D")

	var ids: PackedStringArray = bm.get_last_enemy_ids()
	assert_that(ids.size()).is_equal(3)
	assert_that(ids[0]).is_equal("b")
	assert_that(ids[2]).is_equal("d")


func test_burden_manager_moral_weight_toggle() -> void:
	var bm := AutoloadHelper.burden_manager()
	if bm == null:
		return
	bm.reset()
	bm.burden_active = false

	bm.update_moral_weight(2)
	assert_that(bm.burden_active).is_equal(false)

	bm.update_moral_weight(3)
	assert_that(bm.burden_active).is_equal(true)

	bm.update_moral_weight(1)
	assert_that(bm.burden_active).is_equal(false)


# ── ApparitionRenderer Layout Tests ────────────────────────────────────────


func test_renderer_layout_constants() -> void:
	assert_that(ApparitionRenderer.VERTICAL_OFFSETS.size()).is_equal(3)
	assert_that(ApparitionRenderer.OPACITY_TIERS.size()).is_equal(3)
	assert_that(ApparitionRenderer.SCALE_TIERS.size()).is_equal(3)
	assert_that(ApparitionRenderer.VERTICAL_OFFSETS[0]).is_equal(0)
	assert_that(ApparitionRenderer.VERTICAL_OFFSETS[2]).is_equal(16)
	assert_that(DeterministicMath.floori(ApparitionRenderer.OPACITY_TIERS[0] * 100.0)).is_equal(55)


# ── ApparitionStateMachine Tests ───────────────────────────────────────────


func test_state_machine_manifest_to_idle() -> void:
	var renderer: ApparitionRenderer = auto_free(ApparitionRenderer.new())
	add_child(renderer)

	var sm: ApparitionStateMachine = renderer.state_machine
	assert_that(sm).is_not_null()

	assert_that(sm.current_state).is_equal(ApparitionStateMachine.ApparitionState.INACTIVE)

	sm.cmd_manifest()
	assert_that(sm.current_state).is_equal(ApparitionStateMachine.ApparitionState.MANIFEST)

	for _i: int in range(60):
		sm.update(0.016)
		renderer._process(0.016)

	assert_that(sm.current_state).is_equal(ApparitionStateMachine.ApparitionState.IDLE)


func test_state_machine_recoil_z_promotion() -> void:
	var keeper: Node2D = auto_free(Node2D.new())
	keeper.z_index = 10
	add_child(keeper)

	var renderer: ApparitionRenderer = auto_free(ApparitionRenderer.new())
	renderer.owner_z_index_offset = -1
	renderer.bind_owner(keeper)
	keeper.add_child(renderer)

	var sm: ApparitionStateMachine = renderer.state_machine
	assert_that(sm).is_not_null()

	sm.cmd_manifest()
	for _i: int in range(60):
		sm.update(0.016)
		renderer._process(0.016)

	sm.cmd_recoil()
	renderer._process(0.016)
	assert_that(sm._recoil_promotion_active).is_true()
	assert_that(renderer.z_index).is_equal(12)

	for _i: int in range(10):
		sm.update(0.016)
		renderer._process(0.016)

	assert_that(renderer.z_index).is_equal(9)


# ── Keeper Integration Tests ─────────────────────────────────────────────


func test_keeper_integration_damage_triggers_recoil() -> void:
	var bm := AutoloadHelper.burden_manager()
	if bm == null:
		return
	bm.reset()
	var k: Keeper = auto_free(Keeper.new())
	add_child(k)

	bm.record_sentient_kill("enemy_test", "Test Enemy")
	bm.record_sentient_kill("enemy_test2", "Test Enemy 2")
	bm.record_sentient_kill("enemy_test3", "Test Enemy 3")
	bm.update_moral_weight(3)

	for _i: int in range(60):
		k._process(0.016)
		if k._apparition:
			k._apparition._process(0.016)

	var sm: ApparitionStateMachine = k._apparition.state_machine
	assert_that(sm.current_state).is_equal(ApparitionStateMachine.ApparitionState.IDLE)

	k.apply_damage(5)
	assert_that(sm.current_state).is_equal(ApparitionStateMachine.ApparitionState.RECOIL)


func test_keeper_integration_kill_updates_stack() -> void:
	var bm := AutoloadHelper.burden_manager()
	if bm == null:
		return
	bm.reset()
	var k: Keeper = auto_free(Keeper.new())
	add_child(k)

	k.record_sentient_kill("wolf_01", "Wolf")
	k.record_sentient_kill("wolf_02", "Wolf")
	k.record_sentient_kill("wolf_03", "Wolf")

	var ids: PackedStringArray = bm.get_last_enemy_ids()
	assert_that(ids.size()).is_equal(3)

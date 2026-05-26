extends Node
## Unit tests for DON-83 Apparition Composite Render Pipeline.
## Run via Godot Editor test runner or `godot --headless --script tests/test_apparition.gd`.

# ── BurdenManager Tests ───────────────────────────────────────────────────


func test_burden_manager_record_kill() -> bool:
	# Arrange
	var bm: Node = BurdenManager
	bm.reset()

	# Act
	bm.record_sentient_kill("enemy_wraith_01", "Wraith")
	bm.record_sentient_kill("enemy_shade_02", "Shade")

	# Assert
	var queue: Array[BurdenManager.BurdenKillRecord] = bm.get_kill_queue()
	if queue.size() != 2:
		push_error("Expected queue size 2, got %d" % queue.size())
		return false
	if queue[0].enemy_id != "enemy_wraith_01":
		push_error("Expected first kill wraith, got %s" % queue[0].enemy_id)
		return false
	if queue[1].display_name != "Shade":
		push_error("Expected second kill name Shade, got %s" % queue[1].display_name)
		return false
	return true


func test_burden_manager_cap_at_three() -> bool:
	var bm: Node = BurdenManager
	bm.reset()

	bm.record_sentient_kill("a", "A")
	bm.record_sentient_kill("b", "B")
	bm.record_sentient_kill("c", "C")
	bm.record_sentient_kill("d", "D")

	var ids: PackedStringArray = bm.get_last_enemy_ids()
	if ids.size() != 3:
		push_error("Expected capped size 3, got %d" % ids.size())
		return false
	if ids[0] != "b" or ids[2] != "d":
		push_error("Expected FIFO eviction: got %s" % ids)
		return false
	return true


func test_burden_manager_moral_weight_toggle() -> bool:
	var bm: Node = BurdenManager
	bm.reset()
	bm.burden_active = false

	bm.update_moral_weight(2)
	if bm.burden_active != false:
		push_error("Expected burden inactive at flag 2")
		return false

	bm.update_moral_weight(3)
	if bm.burden_active != true:
		push_error("Expected burden active at threshold 3")
		return false

	bm.update_moral_weight(1)
	if bm.burden_active != false:
		push_error("Expected burden deactivated when flag drops")
		return false
	return true


# ── ApparitionRenderer Layout Tests ────────────────────────────────────────


func test_renderer_layout_constants() -> bool:
	if ApparitionRenderer.VERTICAL_OFFSETS.size() != 3:
		push_error("Expected 3 vertical offsets")
		return false
	if ApparitionRenderer.OPACITY_TIERS.size() != 3:
		push_error("Expected 3 opacity tiers")
		return false
	if ApparitionRenderer.SCALE_TIERS.size() != 3:
		push_error("Expected 3 scale tiers")
		return false
	if ApparitionRenderer.VERTICAL_OFFSETS[0] != 0 or ApparitionRenderer.VERTICAL_OFFSETS[2] != 16:
		push_error("Vertical offsets mismatch")
		return false
	if not DeterministicMath.floori(ApparitionRenderer.OPACITY_TIERS[0] * 100.0) == 55:
		push_error("Opacity tier 0 should be ~55%%")
		return false
	return true


# ── ApparitionStateMachine Tests ───────────────────────────────────────────


func test_state_machine_manifest_to_idle() -> bool:
	var renderer: ApparitionRenderer = ApparitionRenderer.new()
	add_child(renderer)

	var sm: ApparitionStateMachine = renderer.state_machine
	if sm == null:
		push_error("ApparitionRenderer did not create state_machine in _ready()")
		return false

	if sm.current_state != ApparitionStateMachine.ApparitionState.INACTIVE:
		push_error("Expected initial state INACTIVE")
		return false

	sm.cmd_manifest()
	if sm.current_state != ApparitionStateMachine.ApparitionState.MANIFEST:
		push_error("Expected MANIFEST after cmd_manifest")
		return false

	# Fast-forward manifest timer
	for _i: int in range(60):
		sm.update(0.016)

	if sm.current_state != ApparitionStateMachine.ApparitionState.IDLE:
		push_error("Expected IDLE after manifest duration elapsed")
		return false

	renderer.queue_free()
	return true


func test_state_machine_recoil_z_promotion() -> bool:
	var keeper: Node2D = Node2D.new()
	keeper.z_index = 10
	add_child(keeper)

	var renderer: ApparitionRenderer = ApparitionRenderer.new()
	renderer.owner_z_index_offset = -1
	renderer.bind_owner(keeper)
	keeper.add_child(renderer)

	var sm: ApparitionStateMachine = renderer.state_machine
	if sm == null:
		push_error("ApparitionRenderer did not create state_machine in _ready()")
		return false

	sm.cmd_manifest()
	for _i: int in range(60):
		sm.update(0.016)

	# Simulate recoil
	sm.cmd_recoil()
	if not sm._recoil_promotion_active:
		push_error("Expected recoil promotion active flag")
		return false
	if renderer.z_index != 12:
		push_error("Expected z_index promoted to %d, got %d" % [12, renderer.z_index])
		return false

	# Fast-forward recoil
	for _i: int in range(10):
		sm.update(0.016)

	# After recoil, z_index should restore
	if renderer.z_index != 9:
		push_error("Expected z_index restored to 9, got %d" % renderer.z_index)
		return false

	keeper.queue_free()
	return true


# ── Keeper Integration Tests ─────────────────────────────────────────────


func test_keeper_integration_damage_triggers_recoil() -> bool:
	BurdenManager.reset()
	var k: Keeper = Keeper.new()
	add_child(k)

	# Force manifestation via BurdenManager so the apparition is visible.
	BurdenManager.record_sentient_kill("enemy_test", "Test Enemy")
	BurdenManager.record_sentient_kill("enemy_test2", "Test Enemy 2")
	BurdenManager.record_sentient_kill("enemy_test3", "Test Enemy 3")
	BurdenManager.update_moral_weight(3)

	# Fast-forward manifest
	for _i: int in range(60):
		k._process(0.016)

	var sm: ApparitionStateMachine = k._apparition.state_machine
	if sm.current_state != ApparitionStateMachine.ApparitionState.IDLE:
		push_error("Expected IDLE after manifest")
		return false

	k.apply_damage(5)
	if sm.current_state != ApparitionStateMachine.ApparitionState.RECOIL:
		push_error("Expected RECOIL after apply_damage")
		return false

	k.queue_free()
	return true


func test_keeper_integration_kill_updates_stack() -> bool:
	BurdenManager.reset()
	var k: Keeper = Keeper.new()
	add_child(k)

	k.record_sentient_kill("wolf_01", "Wolf")
	k.record_sentient_kill("wolf_02", "Wolf")
	k.record_sentient_kill("wolf_03", "Wolf")

	var ids: PackedStringArray = BurdenManager.get_last_enemy_ids()
	if ids.size() != 3:
		push_error("Expected 3 kills recorded via Keeper")
		return false

	k.queue_free()
	return true


# ── Test Runner ───────────────────────────────────────────────────────────


func _ready() -> void:
	var passed: int = 0
	var failed: int = 0
	var tests: Array[String] = [
		"test_burden_manager_record_kill",
		"test_burden_manager_cap_at_three",
		"test_burden_manager_moral_weight_toggle",
		"test_renderer_layout_constants",
		"test_state_machine_manifest_to_idle",
		"test_state_machine_recoil_z_promotion",
		"test_keeper_integration_damage_triggers_recoil",
		"test_keeper_integration_kill_updates_stack",
	]

	for name: String in tests:
		print("Running %s ..." % name)
		var ok: Variant = call(name)
		if ok is bool and ok:
			passed += 1
			print("  PASS")
		else:
			failed += 1
			print("  FAIL (returned %s)" % str(ok))

	print("")
	print("Results: %d passed, %d failed out of %d" % [passed, failed, tests.size()])
	if failed > 0:
		push_error("Apparition test suite had failures.")
		get_tree().quit(1)
	else:
		get_tree().quit(0)

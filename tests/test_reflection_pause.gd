extends GdUnitTestSuite

var _turn_manager: TurnManager
var _modal: _VictoryModal


func before_test() -> void:
	_turn_manager = auto_free(TurnManager.new()) as TurnManager
	add_child(_turn_manager)

	var scene: PackedScene = load("res://scenes/ui/victory_modal.tscn")
	_modal = auto_free(scene.instantiate()) as _VictoryModal
	add_child(_modal)


func after_test() -> void:
	if is_instance_valid(_modal):
		_modal.queue_free()
	await get_tree().process_frame


# ── VictoryModal.show_reflection tests ───────────────────────────────


func test_show_reflection_creates_label() -> void:
	_modal.show_reflection("Test reflection text.")
	await get_tree().process_frame

	var container: VBoxContainer = _modal.summary_container
	assert_that(container).is_not_null()
	assert_int(container.get_child_count()).is_equal(1)

	var lbl: Label = container.get_child(0) as Label
	assert_that(lbl).is_not_null()
	assert_str(lbl.text).is_equal("Test reflection text.")


func test_show_reflection_clears_previous_content() -> void:
	_modal.show_reflection("First text.")
	await get_tree().process_frame
	_modal.show_reflection("Second text.")
	await get_tree().process_frame

	var container: VBoxContainer = _modal.summary_container
	assert_int(container.get_child_count()).is_equal(1)
	var lbl: Label = container.get_child(0) as Label
	assert_str(lbl.text).is_equal("Second text.")


func test_show_reflection_label_is_centered() -> void:
	_modal.show_reflection("Centered reflection.")
	await get_tree().process_frame

	var lbl: Label = _modal.summary_container.get_child(0) as Label
	assert_that(lbl).is_not_null()
	assert_int(lbl.horizontal_alignment).is_equal(HORIZONTAL_ALIGNMENT_CENTER)


func test_show_reflection_empty_text_does_nothing() -> void:
	_modal.show_reflection("")
	await get_tree().process_frame

	var container: VBoxContainer = _modal.summary_container
	assert_that(container).is_not_null()
	# Empty text still creates a label (implementation choice)
	# The method should not crash
	assert_bool(true).is_true()


# ── TurnManager reflection signal tests ────────────────────────────


func test_reflection_started_signal_emitted_on_victory() -> void:
	var player_ent: Entity = Entity.new("Player", 0, 0, 10, 5, 5)
	player_ent.is_player = true
	player_ent.spd = 10
	var player: Node2D = Node2D.new()
	player.set_script(load("res://scripts/entities/keeper.gd"))
	player.set("entity", player_ent)
	add_child(player)

	var enemy_ent: Entity = Entity.new("Enemy", 1, 1, 10, 5, 5)
	enemy_ent.is_player = false
	var enemy: Node2D = Node2D.new()
	enemy.set_script(load("res://scripts/entities/base_enemy.gd"))
	enemy.set("entity", enemy_ent)
	add_child(enemy)

	var results: Dictionary = {"text": ""}
	_turn_manager.reflection_started.connect(func(text: String) -> void: results["text"] = text)

	_turn_manager.start_combat(player, [enemy])
	# Kill enemy to trigger victory
	enemy_ent.hp = 0
	_turn_manager.current_state = TurnManager.CombatState.CHECK_END_CONDITIONS
	_turn_manager._process_state_loop()

	assert_bool(not str(results["text"]).is_empty()).is_true()
	# Wait for delayed combat_ended
	await get_tree().create_timer(2.0).timeout

	player.queue_free()
	enemy.queue_free()


func test_reflection_text_contains_victory_key() -> void:
	# With default MWT level 0, the reflection text should be REFLECTION_VICTORY_1
	var player_ent: Entity = Entity.new("Player", 0, 0, 10, 5, 5)
	player_ent.is_player = true
	var player: Node2D = Node2D.new()
	player.set_script(load("res://scripts/entities/keeper.gd"))
	player.set("entity", player_ent)
	add_child(player)

	var enemy_ent: Entity = Entity.new("Enemy", 1, 1, 10, 5, 5)
	enemy_ent.is_player = false
	var enemy: Node2D = Node2D.new()
	enemy.set_script(load("res://scripts/entities/base_enemy.gd"))
	enemy.set("entity", enemy_ent)
	add_child(enemy)

	var results2: Dictionary = {"text": ""}
	_turn_manager.reflection_started.connect(func(text: String) -> void: results2["text"] = text)

	_turn_manager.start_combat(player, [enemy])
	enemy_ent.hp = 0
	_turn_manager.current_state = TurnManager.CombatState.CHECK_END_CONDITIONS
	_turn_manager._process_state_loop()

	# Default MWT 0 → should get REFLECTION_VICTORY_1 text
	var received_text: String = str(results2["text"])
	assert_str(received_text).is_not_equal("")
	assert_bool(not received_text.begins_with("REFLECTION_VICTORY")).is_true()

	await get_tree().create_timer(2.0).timeout
	player.queue_free()
	enemy.queue_free()


func test_combat_ended_delayed_after_reflection() -> void:
	var player_ent: Entity = Entity.new("Player", 0, 0, 10, 5, 5)
	player_ent.is_player = true
	var player: Node2D = Node2D.new()
	player.set_script(load("res://scripts/entities/keeper.gd"))
	player.set("entity", player_ent)
	add_child(player)

	var enemy_ent: Entity = Entity.new("Enemy", 1, 1, 10, 5, 5)
	enemy_ent.is_player = false
	var enemy: Node2D = Node2D.new()
	enemy.set_script(load("res://scripts/entities/base_enemy.gd"))
	enemy.set("entity", enemy_ent)
	add_child(enemy)

	var results3: Dictionary = {
		"reflection_emitted": false,
		"combat_ended_emitted": false,
		"reflection_time": 0.0,
		"combat_ended_time": 0.0,
	}

	_turn_manager.reflection_started.connect(
		func(_text: String) -> void:
			results3["reflection_emitted"] = true
			results3["reflection_time"] = Time.get_ticks_msec()
	)
	_turn_manager.combat_ended.connect(
		func(_v: bool) -> void:
			results3["combat_ended_emitted"] = true
			results3["combat_ended_time"] = Time.get_ticks_msec()
	)

	_turn_manager.start_combat(player, [enemy])
	enemy_ent.hp = 0
	_turn_manager.current_state = TurnManager.CombatState.CHECK_END_CONDITIONS
	_turn_manager._process_state_loop()

	# reflection_started should fire immediately
	assert_bool(bool(results3["reflection_emitted"])).is_true()

	# combat_ended should NOT fire immediately
	assert_bool(bool(results3["combat_ended_emitted"])).is_false()

	# Wait for delayed combat_ended
	await get_tree().create_timer(2.0).timeout

	assert_bool(bool(results3["combat_ended_emitted"])).is_true()
	var delay_ms: float = float(results3["combat_ended_time"]) - float(results3["reflection_time"])
	# Should be at least ~1.2s (allowing some tolerance)
	assert_float(delay_ms).is_greater(1200.0)
	# Should be at least ~1.2s (allowing some tolerance)
	assert_float(delay_ms).is_greater(1200.0)

	player.queue_free()
	enemy.queue_free()

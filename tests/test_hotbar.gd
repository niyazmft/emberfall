extends GdUnitTestSuite

const HOTBAR_SCENE: String = "res://scenes/ui/hotbar.tscn"


func test_hotbar_population() -> void:
	var hotbar: Control = auto_free(load(HOTBAR_SCENE).instantiate() as Control)
	add_child(hotbar)

	# Wait for _ready to finish (it calls _refreshHotbar)
	await get_tree().process_frame

	var slots_container: HBoxContainer = hotbar.get_node(
		"HBoxContainer/ScrollContainer/HBoxContainer"
	)
	var slots: Array[Node] = slots_container.get_children()
	assert_int(slots.size()).is_greater_equal(3)

	# Based on config/hotbar_bindings.json:
	# slot 0: strike_ember
	# slot 1: quick_dash
	# slot 2+: null (hidden)

	var slot0: Button = slots[0] as Button
	assert_bool(slot0.visible).is_true()
	assert_str(slot0.text).is_not_empty()
	# Check localization
	assert_str(slot0.text).is_equal(tr("SKILL_STRIKE_EMBER_NAME"))
	assert_str(slot0.tooltip_text).is_equal(tr("SKILL_STRIKE_EMBER_DESC"))

	var slot1: Button = slots[1] as Button
	assert_bool(slot1.visible).is_true()
	assert_str(slot1.text).is_equal(tr("SKILL_QUICK_DASH_NAME"))

	var slot2: Button = slots[2] as Button
	assert_bool(slot2.visible).is_false()


func test_hotbar_ability_selection() -> void:
	var hotbar: Control = auto_free(load(HOTBAR_SCENE).instantiate() as Control)
	add_child(hotbar)
	await get_tree().process_frame

	var am: _AbilityManager = AutoloadHelper.ability_manager()
	if am == null:
		return

	var player: Entity = Entity.new("Player", 0, 0, 100, 10, 5)
	player.is_player = true
	player.ap = 6

	hotbar.call("set_player_entity", player)
	await get_tree().process_frame

	var used := false
	var used_callback := func(_u: Entity, _a: Ability, _t: Entity) -> void: used = true
	if not am.ability_used.is_connected(used_callback):
		am.ability_used.connect(used_callback)

	var slots_container: HBoxContainer = hotbar.get_node(
		"HBoxContainer/ScrollContainer/HBoxContainer"
	)
	var slot1: Button = slots_container.get_child(1) as Button
	assert_that(slot1).is_not_null()

	# quick_dash costs 3 AP and is SELF-targeted
	slot1.pressed.emit()
	await get_tree().process_frame

	assert_int(player.ap).is_equal(3)

	if am.ability_used.is_connected(used_callback):
		am.ability_used.disconnect(used_callback)


func test_ability_manager_ap_cost_deduction() -> void:
	var am: _AbilityManager = AutoloadHelper.ability_manager()
	if am == null:
		return

	var player: Entity = Entity.new("Player", 0, 0, 100, 10, 5)
	player.ap = 6

	var target: Entity = Entity.new("Enemy", 1, 1, 100, 5, 5)

	var result: bool = am.use_ability(player, "strike_ember", target)
	assert_bool(result).is_true()
	assert_int(player.ap).is_equal(3)


func test_ability_manager_out_of_range_rejection() -> void:
	var am: _AbilityManager = AutoloadHelper.ability_manager()
	if am == null:
		return

	var player: Entity = Entity.new("Player", 0, 0, 100, 10, 5)
	player.ap = 6

	var target: Entity = Entity.new("Enemy", 5, 5, 100, 5, 5)

	var result: bool = am.use_ability(player, "strike_ember", target)
	assert_bool(result).is_false()
	assert_int(player.ap).is_equal(6)


func test_hotbar_buttons_disable_when_ap_insufficient() -> void:
	var hotbar: Control = auto_free(load(HOTBAR_SCENE).instantiate() as Control)
	add_child(hotbar)
	await get_tree().process_frame

	var player: Entity = Entity.new("Player", 0, 0, 100, 10, 5)
	player.is_player = true
	player.ap = 2  # strike_ember and quick_dash both cost 3

	hotbar.call("set_player_entity", player)
	await get_tree().process_frame

	var slots_container: HBoxContainer = hotbar.get_node(
		"HBoxContainer/ScrollContainer/HBoxContainer"
	)
	var slot0: Button = slots_container.get_child(0) as Button
	var slot1: Button = slots_container.get_child(1) as Button

	assert_bool(slot0.disabled).is_true()
	assert_bool(slot1.disabled).is_true()

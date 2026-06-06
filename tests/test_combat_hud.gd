extends GdUnitTestSuite

const COMBAT_HUD_SCENE: String = "res://scenes/ui/combat_hud.tscn"


func test_stats_update() -> void:
	var hud: Control = load(COMBAT_HUD_SCENE).instantiate() as Control
	add_child(hud)

	var entity: Entity = Entity.new("TestPlayer", 0, 0, 100, 10, 5)
	entity.is_player = true
	entity.ap = 6

	hud.call("setup", entity, null, null)

	var hp_bar: ProgressBar = hud.get_node("%HPBar") as ProgressBar
	var hp_label: Label = hud.get_node("%HPLabel") as Label
	var ap_bar: ProgressBar = hud.get_node("%APBar") as ProgressBar
	var ap_label: Label = hud.get_node("%APLabel") as Label

	assert_int(int(hp_bar.max_value)).is_equal(100)
	assert_int(int(hp_bar.value)).is_equal(100)
	assert_str(hp_label.text).is_equal("100 / 100")

	assert_int(int(ap_bar.max_value)).is_equal(GameConstants.AP_MAX)
	assert_int(int(ap_bar.value)).is_equal(6)
	assert_str(ap_label.text).is_equal("6 / 6")

	# Test HP change
	entity.hp = 50
	assert_int(int(hp_bar.value)).is_equal(50)
	assert_str(hp_label.text).is_equal("50 / 100")

	# Test AP change
	entity.ap = 2
	assert_int(int(ap_bar.value)).is_equal(2)
	assert_str(ap_label.text).is_equal("2 / 6")

	hud.queue_free()


func test_turn_indicator() -> void:
	var hud: Control = load(COMBAT_HUD_SCENE).instantiate() as Control
	add_child(hud)

	var turn_manager: TurnManager = TurnManager.new()
	add_child(turn_manager)

	hud.call("setup", null, turn_manager, null)

	var turn_label: Label = hud.get_node("%TurnLabel") as Label
	var attack_button: Button = hud.get_node("%AttackButton") as Button
	var end_turn_button: Button = hud.get_node("%EndTurnButton") as Button

	var player_entity: Entity = Entity.new("Player")
	player_entity.is_player = true

	hud.call("_on_turn_started", player_entity, true)
	assert_str(turn_label.text).is_equal("Your Turn")
	assert_bool(attack_button.disabled).is_false()
	assert_bool(end_turn_button.disabled).is_false()

	var enemy_entity: Entity = Entity.new("Grunt")
	enemy_entity.is_player = false

	hud.call("_on_turn_started", enemy_entity, false)
	assert_str(turn_label.text).is_equal("Enemy Turn: Grunt")
	assert_bool(attack_button.disabled).is_true()
	assert_bool(end_turn_button.disabled).is_true()

	hud.queue_free()
	turn_manager.queue_free()

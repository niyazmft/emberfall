# GdUnit Generated Test Suite
class_name CombatInputTest
extends GdUnitTestSuite
@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")
# Test constants
const PLAYER_X := 5
const PLAYER_Y := 5
const ENEMY_ADJ_X := 5
const ENEMY_ADJ_Y := 6

var _player: Node2D
var _enemies_node: Node2D
var _grid_renderer: Node2D
var _combat_input: Node


func before_test() -> void:
	_player = Keeper.new()
	var player_ent: Entity = Entity.new("Player", PLAYER_X, PLAYER_Y, 40, 10, 5)
	player_ent.is_player = true
	player_ent.ap = 6
	_player.set("entity", player_ent)

	_enemies_node = Node2D.new()

	_grid_renderer = GridRenderer.new()

	_combat_input = CombatInput.new(_player, _enemies_node, _grid_renderer)
	add_child(_combat_input)


func after_test() -> void:
	_combat_input.free()
	_grid_renderer.free()
	_enemies_node.free()
	_player.free()


func test_enter_targeting_mode() -> void:
	# Add an adjacent enemy
	var enemy := _create_mock_enemy("Enemy1", ENEMY_ADJ_X, ENEMY_ADJ_Y)
	_enemies_node.add_child(enemy)

	var event := InputEventAction.new()
	event.action = "combat_mode"
	event.pressed = true

	assert_bool(_combat_input.call("handle_input", event)).is_true()
	assert_int(_combat_input.get("current_state")).is_equal(1)  # TARGETING
	var targets: Array = _combat_input.get("_valid_targets")
	assert_int(targets.size()).is_equal(1)
	assert_int(_combat_input.get("_target_index")).is_equal(0)


func test_no_targets_mode() -> void:
	# No enemies added
	var event := InputEventAction.new()
	event.action = "combat_mode"
	event.pressed = true

	assert_bool(_combat_input.call("handle_input", event)).is_false()
	assert_int(_combat_input.get("current_state")).is_equal(0)  # IDLE


func test_cycle_targets() -> void:
	# Add two adjacent enemies
	var enemy1 := _create_mock_enemy("Enemy1", 5, 6)
	var enemy2 := _create_mock_enemy("Enemy2", 6, 5)
	_enemies_node.add_child(enemy1)
	_enemies_node.add_child(enemy2)

	# Start targeting
	var start_event := InputEventAction.new()
	start_event.action = "combat_mode"
	start_event.pressed = true
	_combat_input.call("handle_input", start_event)

	assert_int(_combat_input.get("_target_index")).is_equal(0)

	# Cycle
	var cycle_event := InputEventAction.new()
	cycle_event.action = "combat_cycle"
	cycle_event.pressed = true

	assert_bool(_combat_input.call("handle_input", cycle_event)).is_true()
	assert_int(_combat_input.get("_target_index")).is_equal(1)

	# Cycle back
	_combat_input.call("handle_input", cycle_event)
	assert_int(_combat_input.get("_target_index")).is_equal(0)


func test_cancel_targeting() -> void:
	var enemy := _create_mock_enemy("Enemy1", ENEMY_ADJ_X, ENEMY_ADJ_Y)
	_enemies_node.add_child(enemy)

	_combat_input.call("_start_targeting")
	assert_int(_combat_input.get("current_state")).is_equal(1)  # TARGETING

	var cancel_event := InputEventAction.new()
	cancel_event.action = "combat_cancel"
	cancel_event.pressed = true

	assert_bool(_combat_input.call("handle_input", cancel_event)).is_true()
	assert_int(_combat_input.get("current_state")).is_equal(0)  # IDLE


func test_execute_attack() -> void:
	var enemy := _create_mock_enemy("Enemy1", ENEMY_ADJ_X, ENEMY_ADJ_Y)
	var enemy_ent: Entity = enemy.get("entity")
	enemy_ent.hp = 20
	_enemies_node.add_child(enemy)

	_combat_input.call("_start_targeting")

	var confirm_event := InputEventAction.new()
	confirm_event.action = "combat_confirm"
	confirm_event.pressed = true

	var player_ent: Entity = _player.get("entity")
	var initial_ap: int = player_ent.ap

	assert_bool(_combat_input.call("handle_input", confirm_event)).is_true()
	assert_int(_combat_input.get("current_state")).is_equal(0)  # IDLE
	assert_int(player_ent.ap).is_equal(initial_ap - 2)
	assert_int(enemy_ent.hp).is_less(20)


func test_insufficient_ap() -> void:
	var enemy := _create_mock_enemy("Enemy1", ENEMY_ADJ_X, ENEMY_ADJ_Y)
	_enemies_node.add_child(enemy)

	var player_ent: Entity = _player.get("entity")
	player_ent.ap = 1
	_combat_input.call("_start_targeting")

	var confirm_event := InputEventAction.new()
	confirm_event.action = "combat_confirm"
	confirm_event.pressed = true

	assert_bool(_combat_input.call("handle_input", confirm_event)).is_true()
	# Still targeting because attack failed
	assert_int(_combat_input.get("current_state")).is_equal(1)  # TARGETING
	assert_int(player_ent.ap).is_equal(1)


func _create_mock_enemy(p_name: String, gx: int, gy: int) -> Node2D:
	var enemy := BaseEnemy.new()
	var ent: Entity = Entity.new(p_name, gx, gy, 20, 5, 5)
	enemy.set("entity", ent)
	return enemy

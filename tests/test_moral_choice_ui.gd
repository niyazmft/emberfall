extends GdUnitTestSuite

## Test suite for MoralChoiceUI

var _ui: MoralChoiceUI
var _player: Entity
var _enemy: Entity
var _lifecycle: _EntityLifecycle


func before_test() -> void:
	_lifecycle = AutoloadHelper.entity_lifecycle()

	_player = Entity.new("Player", 0, 0, 100, 10, 10)
	_player.is_player = true
	_player.ap = 6
	_lifecycle.player_entity = _player

	_enemy = Entity.new("Enemy", 1, 1, 20, 5, 5)
	_enemy.is_player = false

	_ui = load("res://scenes/ui/moral_choice_ui.tscn").instantiate()
	add_child(_ui)


func after_test() -> void:
	_ui.queue_free()
	_player = null
	_enemy = null
	_lifecycle.player_entity = null
	_lifecycle.clear_timers()


func test_ui_visibility_on_dying_state() -> void:
	# Initially hidden
	assert_bool(_ui.panel.visible).is_false()

	# Transition enemy to DYING
	_lifecycle.apply_damage(_player, _enemy, 20)
	assert_int(_enemy.state).is_equal(2)  # Entity.State.DYING

	# Wait for signal processing (MoralChoiceUI connects to entity_state_changed)
	await get_tree().process_frame

	assert_bool(_ui.panel.visible).is_true()
	assert_str(_ui.enemy_name_label.text).contains("Enemy")


func test_spare_action() -> void:
	_lifecycle.apply_damage(_player, _enemy, 20)
	await get_tree().process_frame

	var initial_ap: int = _player.ap

	# Simulate Spare press
	_ui.spare_button.pressed.emit()

	assert_int(_enemy.state).is_equal(4)  # Entity.State.GHOST
	assert_int(_player.ap).is_equal(initial_ap - 1)
	assert_bool(_ui.panel.visible).is_false()


func test_execute_action() -> void:
	_lifecycle.apply_damage(_player, _enemy, 20)
	await get_tree().process_frame

	# Simulate Execute press
	_ui.execute_button.pressed.emit()

	assert_int(_enemy.state).is_equal(3)  # Entity.State.DEAD
	assert_bool(_ui.panel.visible).is_false()


func test_spare_button_disabled_when_no_ap() -> void:
	_player.ap = 0
	_lifecycle.apply_damage(_player, _enemy, 20)
	await get_tree().process_frame

	assert_bool(_ui.spare_button.disabled).is_true()


func test_auto_execute_on_timeout() -> void:
	_lifecycle.apply_damage(_player, _enemy, 20)
	await get_tree().process_frame

	# Speed up timeout for test
	_ui._remaining = 0.01

	# Wait for _process to handle timeout
	await get_tree().create_timer(0.05).timeout

	assert_int(_enemy.state).is_equal(3)  # Entity.State.DEAD
	assert_bool(_ui.panel.visible).is_false()


func test_queue_system() -> void:
	var enemy2 := Entity.new("Enemy2", 2, 2, 20, 5, 5)

	# Both die
	_lifecycle.apply_damage(_player, _enemy, 20)
	_lifecycle.apply_damage(_player, enemy2, 20)

	await get_tree().process_frame

	# First enemy shown
	assert_str(_ui.enemy_name_label.text).contains("Enemy")

	# Execute first
	_ui.execute_button.pressed.emit()

	# Wait for short delay in _hide_choice
	await get_tree().create_timer(0.3).timeout

	# Second enemy should be shown now
	assert_bool(_ui.panel.visible).is_true()
	assert_str(_ui.enemy_name_label.text).contains("Enemy2")

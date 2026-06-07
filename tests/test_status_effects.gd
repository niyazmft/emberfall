class_name TestStatusEffects
extends GdUnitTestSuite


func _new_lifecycle() -> _EntityLifecycle:
	var script: GDScript = load("res://scripts/entities/entity_lifecycle.gd")
	var el: _EntityLifecycle = auto_free(script.new()) as _EntityLifecycle
	add_child(el)
	return el


func test_apply_and_remove_status_effect() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = auto_free(Entity.new("Player", 0, 0, 100, 10, 5))
	player.is_player = true
	el.player_entity = player

	# BURNING is defined in config/status_effects.json
	el.apply_status_effect(player, "BURNING", 3, 5)
	assert_that(player.has_status_effect("BURNING")).is_true()

	var effect: StatusEffect = player.get_status_effect("BURNING")
	assert_that(effect.remaining_duration).is_equal(3)
	assert_that(effect.base_potency).is_equal(5)

	el.remove_status_effect(player, "BURNING")
	assert_that(player.has_status_effect("BURNING")).is_false()


func test_status_effect_duration_and_dot() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = auto_free(Entity.new("Player", 0, 0, 100, 10, 5))
	player.is_player = true
	el.player_entity = player
	player.hp = 100

	el.apply_status_effect(player, "BURNING", 2, 10)

	# Turn 1
	el.process_end_of_turn(player)
	assert_that(player.hp).is_equal(90)
	assert_that(player.get_status_effect("BURNING").remaining_duration).is_equal(1)

	# Turn 2
	el.process_end_of_turn(player)
	assert_that(player.hp).is_equal(80)
	assert_that(player.has_status_effect("BURNING")).is_false()


func test_stat_modifiers() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = auto_free(Entity.new("Player", 0, 0, 100, 10, 5))
	player.is_player = true
	el.player_entity = player

	# POISONED has off_bonus: -2 in config/status_effects.json
	var original_off: int = player.off
	el.apply_status_effect(player, "POISONED", 3, 0)
	assert_that(player.off).is_equal(original_off - 2)

	# HASTE has spd_mult: 1.5 in config/status_effects.json
	var original_spd: int = player.spd
	el.apply_status_effect(player, "HASTE", 3, 0)
	assert_that(player.spd).is_equal(int(float(original_spd) * 1.5))

	el.remove_status_effect(player, "POISONED")
	assert_that(player.off).is_equal(original_off)


func test_damage_modifiers() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = auto_free(Entity.new("Player", 0, 0, 100, 10, 5))
	var enemy: Entity = auto_free(Entity.new("Enemy", 1, 1, 100, 10, 5))
	player.is_player = true
	el.player_entity = player

	# Base damage without effects
	var base_dmg: int = CombatFormula.compute_damage_with_effects(player, enemy, [])

	# SHIELDED has damage_taken_mult: 0.5 in config/status_effects.json
	el.apply_status_effect(enemy, "SHIELDED", 2, 0)
	var shielded_dmg: int = CombatFormula.compute_damage_with_effects(player, enemy, [])

	assert_that(shielded_dmg).is_equal(int(float(base_dmg) * 0.5))


func test_potency_formula_evaluation() -> void:
	var el: _EntityLifecycle = _new_lifecycle()
	var player: Entity = auto_free(Entity.new("Player", 0, 0, 100, 10, 5))
	player.is_player = true
	el.player_entity = player

	# BLEEDING: base_potency + (target_hp_max * 0.05)
	# player hp_max = 100, base_potency = 5 -> 5 + (100 * 0.05) = 10
	player.hp = 100
	el.apply_status_effect(player, "BLEEDING", 1, 5)

	el.process_end_of_turn(player)
	assert_that(player.hp).is_equal(90)

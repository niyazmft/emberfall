# GdUnit4 Test Suite for Ability System
extends GdUnitTestSuite


func test_ability_resource_parsing() -> void:
	var data: Dictionary = {
		"id": "test_skill",
		"name_key": "TEST_NAME",
		"description_key": "TEST_DESC",
		"ap_cost": 4,
		"cooldown": 3,
		"target_type": "AREA_ENEMY",
		"effect_payload": {"val": 10}
	}
	var ability: Ability = Ability.fromDict(data)

	assert_that(ability.id).is_equal("test_skill")
	assert_that(ability.name_key).is_equal("TEST_NAME")
	assert_that(ability.description_key).is_equal("TEST_DESC")
	assert_that(ability.ap_cost).is_equal(4)
	assert_that(ability.cooldown).is_equal(3)
	assert_that(ability.target_type).is_equal(Ability.TargetType.AREA_ENEMY)
	assert_that(ability.effect_payload.get("val")).is_equal(10)


func test_ability_manager_loading() -> void:
	# AbilityManager is an autoload, so it should have loaded abilities on start in the test environment
	# if ConfigLoader and AbilityManager are set up correctly.

	var strike_ember: Ability = AbilityManager.get_ability("strike_ember")
	assert_that(strike_ember).is_not_null()
	assert_that(strike_ember.id).is_equal("strike_ember")
	assert_that(strike_ember.ap_cost).is_equal(3)

	var quick_dash: Ability = AbilityManager.get_ability("quick_dash")
	assert_that(quick_dash).is_not_null()
	assert_that(quick_dash.id).is_equal("quick_dash")

	var all_abilities: Array[Ability] = AbilityManager.get_all_abilities()
	assert_that(all_abilities.size() > 0).is_true()


func test_combat_formula_ability_costs() -> void:
	# Verify that combat formula correctly picks up ability costs from ConfigLoader
	var min_cost: int = CombatFormula.action_cost("ability_min")
	var max_cost: int = CombatFormula.action_cost("ability_max")

	# Based on config/skills.json and game_config.json
	assert_that(min_cost).is_equal(3)
	assert_that(max_cost).is_equal(5)

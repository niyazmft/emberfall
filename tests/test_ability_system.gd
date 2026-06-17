# GdUnit4 Test Suite for Ability System
extends GdUnitTestSuite

const __source = "res://scripts/autoload/ability_manager.gd"


func test_ability_resource_parsing() -> void:
	var abilityData: Dictionary = {
		"id": "test_skill",
		"name_key": "TEST_NAME",
		"description_key": "TEST_DESC",
		"ap_cost": 4,
		"cooldown": 3,
		"target_type": "AREA_ENEMY",
		"effect_payload": {"val": 10}
	}
	var abilityObj: Ability = Ability.fromDict(abilityData)

	assert_str(abilityObj.id).is_equal("test_skill")
	assert_str(abilityObj.nameKey).is_equal("TEST_NAME")
	assert_str(abilityObj.descriptionKey).is_equal("TEST_DESC")
	assert_int(abilityObj.apCost).is_equal(4)
	assert_int(abilityObj.cooldown).is_equal(3)
	assert_int(abilityObj.targetType).is_equal(Ability.TargetType.AREA_ENEMY)
	assert_int(abilityObj.effectPayload.get("val")).is_equal(10)


func test_ability_manager_loading() -> void:
	# AbilityManager is an autoload, so it should have loaded abilities on start in the test environment
	# if ConfigLoader and AbilityManager are set up correctly.
	var am := AutoloadHelper.ability_manager()
	if am == null:
		return

	var strikeEmber: Ability = am.getAbility("strike_ember")
	assert_that(strikeEmber).is_not_null()
	assert_str(strikeEmber.id).is_equal("strike_ember")
	assert_int(strikeEmber.apCost).is_equal(3)

	var quickDash: Ability = am.getAbility("quick_dash")
	assert_that(quickDash).is_not_null()
	assert_str(quickDash.id).is_equal("quick_dash")

	var allAbilities: Array[Ability] = am.getAllAbilities()
	assert_int(allAbilities.size()).is_greater(0)


func test_combat_formula_ability_costs() -> void:
	# Verify that combat formula correctly picks up ability costs from ConfigLoader
	var minCost: int = CombatFormula.action_cost("ability_min")
	var maxCost: int = CombatFormula.action_cost("ability_max")

	# Based on config/skills.json and game_config.json
	assert_int(minCost).is_equal(3)
	assert_int(maxCost).is_equal(5)

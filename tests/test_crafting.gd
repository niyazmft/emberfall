extends GdUnitTestSuite

var _crafting_manager: _CraftingManager
var _inventory_manager: Node
var _meta_progression_manager: _MetaProgressionManager


func before_test() -> void:
	_crafting_manager = AutoloadHelper.crafting_manager()
	_inventory_manager = AutoloadHelper.inventory_manager()
	_meta_progression_manager = AutoloadHelper.meta_progression_manager()

	# Clear inventory and shards for testing
	_inventory_manager.inventory.clear()
	_meta_progression_manager.add_echo_shards(-_meta_progression_manager.get_echo_shards())


func test_can_craft_fails_without_ingredients() -> void:
	assert_bool(_crafting_manager.can_craft("recipe_iron_sword")).is_false()


func test_can_craft_fails_without_shards() -> void:
	_inventory_manager.add_item("iron_scrap", 3)
	_inventory_manager.add_item("rusted_blade", 1)
	assert_bool(_crafting_manager.can_craft("recipe_iron_sword")).is_false()


func test_can_craft_succeeds_with_resources() -> void:
	_inventory_manager.add_item("iron_scrap", 3)
	_inventory_manager.add_item("rusted_blade", 1)
	_meta_progression_manager.add_echo_shards(10)
	assert_bool(_crafting_manager.can_craft("recipe_iron_sword")).is_true()


func test_craft_produces_item_and_consumes_resources() -> void:
	_inventory_manager.add_item("iron_scrap", 3)
	_inventory_manager.add_item("rusted_blade", 1)
	_meta_progression_manager.add_echo_shards(10)

	assert_bool(_crafting_manager.craft("recipe_iron_sword")).is_true()

	assert_int(_inventory_manager.get_item_count("iron_sword")).is_equal(1)
	assert_int(_inventory_manager.get_item_count("iron_scrap")).is_equal(0)
	assert_int(_inventory_manager.get_item_count("rusted_blade")).is_equal(0)
	assert_int(_meta_progression_manager.get_echo_shards()).is_equal(0)

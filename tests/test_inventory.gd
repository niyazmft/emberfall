extends GdUnitTestSuite


func test_item_loading() -> void:
	var itemDict: Dictionary = {
		"id": "test_sword",
		"name": "Test Sword",
		"type": "WEAPON",
		"rarity": "RARE",
		"stats": {"off": 5},
		"stackLimit": 1,
		"description": "A test sword."
	}
	var item: Item = Item.fromDict(itemDict)
	assert_str(item.id).is_equal("test_sword")
	assert_str(item.name).is_equal("Test Sword")
	assert_int(item.type).is_equal(Item.ItemType.WEAPON)
	assert_int(item.rarity).is_equal(Item.Rarity.RARE)
	assert_int(item.stats["off"]).is_equal(5)


func test_inventory_add_remove() -> void:
	# Ensure ConfigLoader is ready for testing
	var configLoader = AutoloadHelper.get_singleton("ConfigLoader")
	if configLoader != null and not configLoader.is_loaded():
		configLoader.ensure_loaded()

	var inv: Node = AutoloadHelper.get_autoload("InventoryManager")
	# Clear inventory
	inv.inventory.clear()

	assert_bool(inv.add_item("healing_salve", 5)).is_true()
	assert_int(inv.inventory.size()).is_equal(1)
	assert_int(inv.inventory[0]["quantity"]).is_equal(5)

	assert_bool(inv.add_item("healing_salve", 7)).is_true()
	# healing_salve stack limit is 10. 5 + 7 = 12. Should be one stack of 10 and one stack of 2.
	assert_int(inv.inventory.size()).is_equal(2)
	assert_int(inv.inventory[0]["quantity"]).is_equal(10)
	assert_int(inv.inventory[1]["quantity"]).is_equal(2)

	assert_bool(inv.remove_item("healing_salve", 3)).is_true()
	# Remove 2 from second stack, 1 from first stack.
	assert_int(inv.inventory.size()).is_equal(1)
	assert_int(inv.inventory[0]["quantity"]).is_equal(9)


func test_equipment() -> void:
	var configLoader = AutoloadHelper.get_singleton("ConfigLoader")
	if configLoader != null and not configLoader.is_loaded():
		configLoader.ensure_loaded()
	var inv: Node = AutoloadHelper.get_autoload("InventoryManager")
	inv._initialize_from_config()

	inv.inventory.clear()
	# Reset equipment slots
	for slot: String in inv.equipment:
		inv.equipment[slot] = ""

	inv.add_item("rusted_blade", 1)
	assert_bool(inv.equip_item("rusted_blade", "weapon")).is_true()
	assert_str(inv.equipment["weapon"]).is_equal("rusted_blade")
	assert_int(inv.inventory.size()).is_equal(0)

	# Test duplication bug fix: try to equip item that is NOT in inventory
	# Previous weapon should NOT be duplicated or lost
	assert_bool(inv.equip_item("rusted_blade", "weapon")).is_false()
	assert_str(inv.equipment["weapon"]).is_equal("rusted_blade")
	assert_int(inv.inventory.size()).is_equal(0)

	assert_bool(inv.unequip_item("weapon")).is_true()
	assert_str(inv.equipment["weapon"]).is_equal("")
	assert_int(inv.inventory.size()).is_equal(1)
	assert_str(inv.inventory[0]["item_id"]).is_equal("rusted_blade")


func test_equipment_type_restriction() -> void:
	var configLoader = AutoloadHelper.get_singleton("ConfigLoader")
	if configLoader != null and not configLoader.is_loaded():
		configLoader.ensure_loaded()
	var inv: Node = AutoloadHelper.get_autoload("InventoryManager")
	inv._initialize_from_config()

	inv.inventory.clear()
	inv.add_item("leather_vest", 1)

	# Should NOT be able to equip ARMOR in WEAPON slot
	assert_bool(inv.equip_item("leather_vest", "weapon")).is_false()
	assert_str(inv.equipment["weapon"]).is_equal("")
	assert_int(inv.inventory.size()).is_equal(1)


func test_snapshot() -> void:
	var inv: Node = AutoloadHelper.get_autoload("InventoryManager")
	inv.inventory.clear()
	inv.inventory.append({"item_id": "test", "quantity": 1})
	inv.equipment["weapon"] = "sword"

	var snapshot: Dictionary = inv.get_snapshot()
	assert_int(snapshot["inventory"].size()).is_equal(1)
	assert_str(snapshot["equipment"]["weapon"]).is_equal("sword")

	inv.inventory.clear()
	inv.equipment["weapon"] = ""

	inv.load_snapshot(snapshot)
	assert_int(inv.inventory.size()).is_equal(1)
	assert_str(inv.equipment["weapon"]).is_equal("sword")

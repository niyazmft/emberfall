extends GdUnitTestSuite


func test_item_loading() -> void:
	var item_dict := {
		"id": "test_sword",
		"name": "Test Sword",
		"type": "WEAPON",
		"rarity": "RARE",
		"stats": {"off": 5},
		"stack_limit": 1,
		"description": "A test sword."
	}
	var item := Item.from_dict(item_dict)
	assert_str(item.id).is_equal("test_sword")
	assert_str(item.name).is_equal("Test Sword")
	assert_int(item.type).is_equal(Item.ItemType.WEAPON)
	assert_int(item.rarity).is_equal(Item.Rarity.RARE)
	assert_int(item.stats["off"]).is_equal(5)


func test_inventory_add_remove() -> void:
	# Ensure ConfigLoader is ready for testing
	if not ConfigLoader.is_loaded():
		ConfigLoader._load_config()

	# Clear inventory
	InventoryManager.inventory.clear()

	assert_bool(InventoryManager.add_item("healing_salve", 5)).is_true()
	assert_int(InventoryManager.inventory.size()).is_equal(1)
	assert_int(InventoryManager.inventory[0]["quantity"]).is_equal(5)

	assert_bool(InventoryManager.add_item("healing_salve", 7)).is_true()
	# healing_salve stack limit is 10. 5 + 7 = 12. Should be one stack of 10 and one stack of 2.
	assert_int(InventoryManager.inventory.size()).is_equal(2)
	assert_int(InventoryManager.inventory[0]["quantity"]).is_equal(10)
	assert_int(InventoryManager.inventory[1]["quantity"]).is_equal(2)

	assert_bool(InventoryManager.remove_item("healing_salve", 3)).is_true()
	# Remove 2 from second stack, 1 from first stack.
	assert_int(InventoryManager.inventory.size()).is_equal(1)
	assert_int(InventoryManager.inventory[0]["quantity"]).is_equal(9)


func test_equipment() -> void:
	if not ConfigLoader.is_loaded():
		ConfigLoader._load_config()
	InventoryManager._initialize_from_config()

	InventoryManager.inventory.clear()
	# Reset equipment slots
	for slot: String in InventoryManager.equipment:
		InventoryManager.equipment[slot] = ""

	InventoryManager.add_item("rusted_blade", 1)
	assert_bool(InventoryManager.equip_item("rusted_blade", "weapon")).is_true()
	assert_str(InventoryManager.equipment["weapon"]).is_equal("rusted_blade")
	assert_int(InventoryManager.inventory.size()).is_equal(0)

	# Test duplication bug fix: try to equip item that is NOT in inventory
	# Previous weapon should NOT be duplicated or lost
	assert_bool(InventoryManager.equip_item("rusted_blade", "weapon")).is_false()
	assert_str(InventoryManager.equipment["weapon"]).is_equal("rusted_blade")
	assert_int(InventoryManager.inventory.size()).is_equal(0)

	assert_bool(InventoryManager.unequip_item("weapon")).is_true()
	assert_str(InventoryManager.equipment["weapon"]).is_equal("")
	assert_int(InventoryManager.inventory.size()).is_equal(1)
	assert_str(InventoryManager.inventory[0]["item_id"]).is_equal("rusted_blade")


func test_equipment_type_restriction() -> void:
	if not ConfigLoader.is_loaded():
		ConfigLoader._load_config()
	InventoryManager._initialize_from_config()

	InventoryManager.inventory.clear()
	InventoryManager.add_item("leather_vest", 1)

	# Should NOT be able to equip ARMOR in WEAPON slot
	assert_bool(InventoryManager.equip_item("leather_vest", "weapon")).is_false()
	assert_str(InventoryManager.equipment["weapon"]).is_equal("")
	assert_int(InventoryManager.inventory.size()).is_equal(1)


func test_snapshot() -> void:
	InventoryManager.inventory = [{"item_id": "test", "quantity": 1}]
	InventoryManager.equipment["weapon"] = "sword"

	var snapshot := InventoryManager.get_snapshot()
	assert_int(snapshot["inventory"].size()).is_equal(1)
	assert_str(snapshot["equipment"]["weapon"]).is_equal("sword")

	InventoryManager.inventory = []
	InventoryManager.equipment["weapon"] = ""

	InventoryManager.load_snapshot(snapshot)
	assert_int(InventoryManager.inventory.size()).is_equal(1)
	assert_str(InventoryManager.equipment["weapon"]).is_equal("sword")

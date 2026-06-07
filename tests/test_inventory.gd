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


func before_test() -> void:
	var inv: Node = AutoloadHelper.get_autoload("InventoryManager")
	inv.inventory.clear()
	for slot: String in inv.equipment:
		inv.equipment[slot] = ""


func after_test() -> void:
	var inv: Node = AutoloadHelper.get_autoload("InventoryManager")
	inv.inventory.clear()
	for slot: String in inv.equipment:
		inv.equipment[slot] = ""

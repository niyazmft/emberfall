extends GdUnitTestSuite


func test_item_flavor_text_loads_from_config() -> void:
	var file := FileAccess.open("res://config/items.json", FileAccess.READ)
	assert_that(file).is_not_null()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_that(parsed is Dictionary).is_true()
	var items: Dictionary = parsed["items"]
	assert_that(items.has("rusted_blade")).is_true()

	var blade_data: Dictionary = items["rusted_blade"]
	assert_that(blade_data.has("flavor_text")).is_true()
	assert_str(blade_data["flavor_text"]).is_equal(
		"A blade tempered in the last Emberfall. It remembers the heat."
	)

	file.close()


func test_item_from_dict_reads_flavor_text() -> void:
	var data: Dictionary = {
		"id": "test_item",
		"name": "Test Item",
		"type": "WEAPON",
		"rarity": "COMMON",
		"stats": {},
		"stackLimit": 1,
		"description": "A test item.",
		"flavor_text": "Forged in test fires."
	}
	var item: Item = Item.fromDict(data)
	assert_that(item).is_not_null()
	assert_str(item.flavor_text).is_equal("Forged in test fires.")
	assert_str(item.get_flavor_text()).is_equal("Forged in test fires.")


func test_get_flavor_text_fallbacks_to_description() -> void:
	var item: Item = Item.new()
	item.description = "Plain description."
	item.flavor_text = ""
	assert_str(item.get_flavor_text()).is_equal("Plain description.")


func test_all_items_have_flavor_text() -> void:
	var file := FileAccess.open("res://config/items.json", FileAccess.READ)
	assert_that(file).is_not_null()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var items: Dictionary = parsed["items"]
	for item_id: String in items.keys():
		var item_data: Dictionary = items[item_id]
		assert_bool(item_data.has("flavor_text")).is_true()
		assert_bool(not str(item_data["flavor_text"]).is_empty()).is_true()
	file.close()


func test_flavor_text_localization_keys_exist() -> void:
	var file := FileAccess.open("res://localization/ui_strings.csv", FileAccess.READ)
	assert_that(file).is_not_null()
	var content: String = file.get_as_text()
	file.close()

	var keys: Array[String] = [
		"ITEM_FLAVOR_RUSTED_BLADE",
		"ITEM_FLAVOR_LEATHER_VEST",
		"ITEM_FLAVOR_HEALING_SALVE",
		"ITEM_FLAVOR_LUCKY_PENDANT",
	]
	for key: String in keys:
		assert_bool(content.contains(key)).is_true()
		var key_pos: int = content.find(key)
		var line_start: int = content.rfind("\n", key_pos) + 1
		var line_end: int = content.find("\n", key_pos)
		var line: String = content.substr(line_start, line_end - line_start)
		# Verify at least 4 commas (5 columns)
		assert_int(line.count(",")).is_greater_equal(4)

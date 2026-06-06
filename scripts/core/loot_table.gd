class_name LootTable
extends RefCounted

## LootTable
## Handles loading loot definitions from JSON and performing weighted rolls.

const LOOT_DIR := "res://config/loot/"

var min_rolls: int = 1
var max_rolls: int = 1
var entries: Array = []


## Static factory to load a loot table by ID.
static func load_loot_table(table_id: String) -> LootTable:
	var path := LOOT_DIR + table_id + ".json"
	if not FileAccess.file_exists(path):
		push_error("LootTable: File not found at " + path)
		return null

	var f := FileAccess.open(path, FileAccess.READ)
	var text := f.get_as_text()
	f.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("LootTable: JSON parse error in " + path)
		return null

	var data: Dictionary = json.data
	var table := LootTable.new()
	table.min_rolls = int(data.get("min_rolls", 1))
	table.max_rolls = int(data.get("max_rolls", 1))
	table.entries = data.get("entries", [])
	return table


## Perform rolls and return a list of item IDs.
## Note: item_id can be null in JSON, representing no drop.
func roll_loot() -> Array[String]:
	var results: Array[String] = []
	var roll_count: int = randi_range(min_rolls, max_rolls)

	var total_weight: int = 0
	for entry: Dictionary in entries:
		total_weight += int(entry.get("weight", 0))

	if total_weight <= 0:
		return results

	for i: int in range(roll_count):
		var roll: int = randi() % total_weight
		var current_weight: int = 0
		for entry: Dictionary in entries:
			current_weight += int(entry.get("weight", 0))
			if roll < current_weight:
				var item_id: Variant = entry.get("item_id")
				if item_id != null and item_id is String:
					results.append(item_id as String)
				break

	return results

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
	if f == null:
		push_error("LootTable: Failed to open file " + path)
		return null

	var text := f.get_as_text()
	f.close()

	var data_v: Variant = JSON.parse_string(text)
	if data_v == null or not data_v is Dictionary:
		push_error("LootTable: JSON parse error or not a Dictionary in " + path)
		return null

	var data: Dictionary = data_v as Dictionary
	var table := LootTable.new()
	table.min_rolls = int(data.get("min_rolls", 1))
	table.max_rolls = int(data.get("max_rolls", 1))
	table.entries = data.get("entries", [])
	return table


## Perform rolls and return a list of item IDs.
## Note: item_id can be null in JSON, representing no drop.
func roll_loot(seed_val: int = 0, salt: String = "LOOT") -> Array[String]:
	var results: Array[String] = []

	var total_weight: int = 0
	for entry: Variant in entries:
		if entry is Dictionary:
			total_weight += int(entry.get("weight", 0))

	if total_weight <= 0:
		return results

	var roll_count: int = min_rolls
	if max_rolls > min_rolls:
		var count_range: int = max_rolls - min_rolls + 1
		roll_count = (
			min_rolls + SeedGovernance.modulo_from_seed(seed_val, salt + "_COUNT", count_range)
		)

	for i: int in range(roll_count):
		var roll: int = SeedGovernance.modulo_from_seed(seed_val, salt + "_" + str(i), total_weight)
		var current_weight: int = 0
		for entry: Variant in entries:
			if not entry is Dictionary:
				continue
			var d: Dictionary = entry as Dictionary
			current_weight += int(d.get("weight", 0))
			if roll < current_weight:
				var item_id: Variant = d.get("item_id")
				if item_id != null and item_id is String:
					results.append(item_id as String)
				break

	return results

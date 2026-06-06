class_name Item
extends Resource

## Item resource for Project Emberfall.
## Defines item catalog data and stat modifiers.

enum ItemType { WEAPON, ARMOR, CONSUMABLE, ACCESSORY }
enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

@export var id: String = ""
@export var name: String = ""
@export var type: ItemType = ItemType.CONSUMABLE
@export var rarity: Rarity = Rarity.COMMON
@export var stats: Dictionary = {}
@export var stack_limit: int = 1
@export var description: String = ""


## Factory method to create an Item from a Dictionary (parsed JSON).
static func from_dict(data: Dictionary) -> Item:
	var item := Item.new()
	item.id = data.get("id", "")
	item.name = data.get("name", "Unknown Item")
	item.type = _parse_type(data.get("type", "CONSUMABLE"))
	item.rarity = _parse_rarity(data.get("rarity", "COMMON"))
	item.stats = data.get("stats", {})
	item.stack_limit = int(data.get("stack_limit", 1))
	item.description = data.get("description", "")
	return item


static func _parse_type(type_str: String) -> ItemType:
	match type_str.to_upper():
		"WEAPON":
			return ItemType.WEAPON
		"ARMOR":
			return ItemType.ARMOR
		"CONSUMABLE":
			return ItemType.CONSUMABLE
		"ACCESSORY":
			return ItemType.ACCESSORY
		_:
			return ItemType.CONSUMABLE


static func _parse_rarity(rarity_str: String) -> Rarity:
	match rarity_str.to_upper():
		"COMMON":
			return Rarity.COMMON
		"UNCOMMON":
			return Rarity.UNCOMMON
		"RARE":
			return Rarity.RARE
		"LEGENDARY":
			return Rarity.LEGENDARY
		_:
			return Rarity.COMMON

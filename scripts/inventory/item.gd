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
@export var stackLimit: int = 1
@export var description: String = ""
@export var flavor_text: String = ""


## Factory method to create an Item from a Dictionary (parsed JSON).
static func fromDict(data: Dictionary) -> Item:
	var item: Item = Item.new()
	item.id = data.get("id", "")
	item.name = data.get("name", "Unknown Item")
	item.type = _parseType(data.get("type", "CONSUMABLE"))
	item.rarity = _parseRarity(data.get("rarity", "COMMON"))
	item.stats = data.get("stats", {})
	item.stackLimit = int(data.get("stackLimit", data.get("stack_limit", 1)))
	item.description = data.get("description", "")
	item.flavor_text = data.get("flavor_text", "")
	return item


## Returns the flavor text if available, otherwise falls back to description.
func get_flavor_text() -> String:
	return flavor_text if not flavor_text.is_empty() else description


static func _parseType(typeStr: String) -> ItemType:
	match typeStr.to_upper():
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


static func _parseRarity(rarityStr: String) -> Rarity:
	match rarityStr.to_upper():
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

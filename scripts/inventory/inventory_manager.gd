extends Node

## Autoload: InventoryManager
## Manages player inventory, equipment, and item persistence.

signal inventory_changed
signal equipment_changed(slot: String, item_id: String)

## Player inventory: Array of Dictionaries { "item_id": String, "quantity": int }
var inventory: Array[Dictionary] = []

## Player equipment: Dictionary { slot_name: item_id }
var equipment: Dictionary = {}

## Slot definitions: Dictionary { slot_name: Array[allowed_types] }
var slot_definitions: Dictionary = {}


func _ready() -> void:
	_initialize_from_config()


func _initialize_from_config() -> void:
	# Wait for ConfigLoader if not yet loaded
	if not ConfigLoader.is_loaded():
		await get_tree().process_frame

	var entity_config: Dictionary = ConfigLoader.get_value("entities", "keeper", {})
	if entity_config.has("slots"):
		slot_definitions = entity_config["slots"]
		for slot: String in slot_definitions:
			equipment[slot] = ""


## Returns an Item resource by ID if it exists in the catalog.
func get_item_data(item_id: String) -> Item:
	var item_catalog: Dictionary = ConfigLoader.get_value("items", "", {})
	if item_catalog.has(item_id):
		return Item.from_dict(item_catalog[item_id])
	return null


## Adds an item to the inventory. Handles stack limits.
func add_item(item_id: String, quantity: int = 1) -> bool:
	var item_data := get_item_data(item_id)
	if not item_data:
		push_error("InventoryManager: Item ID %s not found in catalog." % item_id)
		return false

	# Try to find existing stack
	for entry: Dictionary in inventory:
		if entry["item_id"] == item_id:
			if entry["quantity"] < item_data.stack_limit:
				var space: int = item_data.stack_limit - entry["quantity"]
				var to_add: int = mini(quantity, space)
				entry["quantity"] += to_add
				quantity -= to_add
				if quantity <= 0:
					inventory_changed.emit()
					return true

	# Add new stacks if needed
	while quantity > 0:
		var to_add: int = mini(quantity, item_data.stack_limit)
		inventory.append({"item_id": item_id, "quantity": to_add})
		quantity -= to_add

	inventory_changed.emit()
	return true


## Removes an item from the inventory.
func remove_item(item_id: String, quantity: int = 1) -> bool:
	var remaining: int = quantity
	var indices_to_remove: Array[int] = []

	for i: int in range(inventory.size() - 1, -1, -1):
		var entry: Dictionary = inventory[i]
		if entry["item_id"] == item_id:
			var to_remove: int = mini(remaining, entry["quantity"])
			entry["quantity"] -= to_remove
			remaining -= to_remove
			if entry["quantity"] <= 0:
				indices_to_remove.append(i)
			if remaining <= 0:
				break

	for index: int in indices_to_remove:
		inventory.remove_at(index)

	if remaining < quantity:
		inventory_changed.emit()
		return remaining == 0
	return false


## Equips an item into a slot.
func equip_item(item_id: String, slot: String) -> bool:
	if not equipment.has(slot):
		push_error("InventoryManager: Invalid equipment slot %s" % slot)
		return false

	var item_data := get_item_data(item_id)
	if not item_data:
		return false

	# Validate item type for slot
	var allowed_types: Array = slot_definitions.get(slot, [])
	var type_str := _item_type_to_string(item_data.type)
	if not type_str in allowed_types:
		return false

	# ATOMIC OPERATION: Remove new item first, THEN unequip old one.
	if remove_item(item_id, 1):
		var old_item_id: String = equipment[slot]
		equipment[slot] = item_id

		if not old_item_id.is_empty():
			add_item(old_item_id, 1)

		equipment_changed.emit(slot, item_id)
		return true

	return false


func _item_type_to_string(type: Item.ItemType) -> String:
	match type:
		Item.ItemType.WEAPON:
			return "WEAPON"
		Item.ItemType.ARMOR:
			return "ARMOR"
		Item.ItemType.CONSUMABLE:
			return "CONSUMABLE"
		Item.ItemType.ACCESSORY:
			return "ACCESSORY"
	return ""


## Unequips an item from a slot.
func unequip_item(slot: String) -> bool:
	if not equipment.has(slot) or equipment[slot].is_empty():
		return false

	var item_id: String = equipment[slot]
	if add_item(item_id, 1):
		equipment[slot] = ""
		equipment_changed.emit(slot, "")
		return true

	return false


## Serialization for SaveManager.
func get_snapshot() -> Dictionary:
	return {"inventory": inventory.duplicate(true), "equipment": equipment.duplicate()}


## Deserialization for SaveManager.
func load_snapshot(snapshot: Dictionary) -> void:
	if snapshot.has("inventory"):
		inventory.clear()
		for entry: Variant in snapshot["inventory"]:
			if entry is Dictionary:
				inventory.append(entry)

	if snapshot.has("equipment"):
		var eq: Variant = snapshot["equipment"]
		if eq is Dictionary:
			for slot: String in equipment.keys():
				if eq.has(slot):
					var val: Variant = eq[slot]
					equipment[slot] = str(val) if val != null and str(val) != "" else ""

	inventory_changed.emit()
	for slot: String in equipment:
		equipment_changed.emit(slot, equipment[slot])

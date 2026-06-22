extends Node
class_name _InventoryManager

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
	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	if config_loader == null or not config_loader.isLoaded():
		await get_tree().process_frame
		config_loader = AutoloadHelper.config_loader()

	if config_loader == null:
		return

	var entity_config: Dictionary = config_loader.getValue("entities", "keeper", {})
	if entity_config.has("slots"):
		slot_definitions = entity_config["slots"]
		for slot: String in slot_definitions:
			equipment[slot] = ""


## Returns an Item resource by ID if it exists in the catalog.
func get_item_data(item_id: String) -> Item:
	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	if config_loader == null:
		return null
	var item_catalog: Dictionary = config_loader.getValue("items", "", {})
	if item_catalog.has(item_id):
		return Item.fromDict(item_catalog[item_id])
	return null


## Adds an item to the inventory. Handles stack limits.
func add_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false
	var item_data := get_item_data(item_id)
	if not item_data:
		push_error("InventoryManager: Item ID %s not found in catalog." % item_id)
		return false

	# Try to find existing stack
	for entry: Dictionary in inventory:
		if entry["item_id"] == item_id:
			if entry["quantity"] < item_data.stackLimit:
				var space: int = item_data.stackLimit - entry["quantity"]
				var to_add: int = DeterministicMath.mini(quantity, space)
				entry["quantity"] += to_add
				quantity -= to_add
				if quantity <= 0:
					inventory_changed.emit()
					return true

	# Add new stacks if needed
	while quantity > 0:
		var to_add: int = DeterministicMath.mini(quantity, item_data.stackLimit)
		inventory.append({"item_id": item_id, "quantity": to_add})
		quantity -= to_add

	inventory_changed.emit()
	return true


## Picks up an item and adds it to the inventory. Stacks if already present.
func pickup_item(item_id: String, quantity: int = 1) -> bool:
	return add_item(item_id, quantity)


## Removes an item from the inventory.
func remove_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0 or item_id.is_empty():
		return false
	var remaining: int = quantity
	var indices_to_remove: Array[int] = []

	for i: int in range(inventory.size() - 1, -1, -1):
		var entry: Dictionary = inventory[i]
		if entry["item_id"] == item_id:
			var to_remove: int = DeterministicMath.mini(remaining, entry["quantity"])
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
	var allowed_types: Array[String] = []
	var raw_allowed: Variant = slot_definitions.get(slot, [])
	if raw_allowed is Array:
		for t: Variant in raw_allowed:
			allowed_types.append(str(t))
	var type_str := _item_type_to_string(item_data.type)
	if not type_str in allowed_types:
		return false

	# ATOMIC OPERATION: Remove new item first, THEN unequip old one.
	if remove_item(item_id, 1):
		var old_item_id: String = equipment[slot]
		equipment[slot] = item_id

		if not old_item_id.is_empty():
			add_item(old_item_id, 1)
			var old_item_data := get_item_data(old_item_id)
			if old_item_data:
				_apply_equipment_stats(old_item_data, false)

		_apply_equipment_stats(item_data, true)
		equipment_changed.emit(slot, item_id)
		return true

	return false


func _get_player_entity() -> Entity:
	var lifecycle: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if lifecycle != null:
		return lifecycle.player_entity
	return null


func _apply_equipment_stats(item_data: Item, apply: bool) -> void:
	var player: Entity = _get_player_entity()
	if player == null or item_data == null:
		return
	var mult: int = 1 if apply else -1
	if item_data.stats.has("off"):
		player._cached_equip_off_bonus += int(item_data.stats["off"]) * mult
	if item_data.stats.has("def"):
		player._cached_equip_def_bonus += int(item_data.stats["def"]) * mult
	if item_data.stats.has("spd"):
		player._cached_equip_spd_bonus += int(item_data.stats["spd"]) * mult


func _item_type_to_string(itemType: Item.ItemType) -> String:
	match itemType:
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
	var item_data := get_item_data(item_id)
	if add_item(item_id, 1):
		if item_data:
			_apply_equipment_stats(item_data, false)
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

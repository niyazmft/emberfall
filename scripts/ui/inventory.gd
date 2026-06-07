extends Control

## InventoryUI
## Manages the inventory and equipment display.

const LAYOUT_PATH: String = "res://config/inventory_layout.json"

@onready var _inventory_grid: GridContainer = %InventoryGrid
@onready var _equipment_container: Control = %EquipmentContainer
@onready var _item_tooltip: Control = %ItemTooltip
@onready var _title_label: Label = %TitleLabel

var _layout_config: Dictionary = {}
var _equipment_slots: Dictionary = {}


func _ready() -> void:
	_load_layout()
	_setup_ui()
	_connect_signals()
	_refresh_ui()


func _load_layout() -> void:
	if not FileAccess.file_exists(LAYOUT_PATH):
		push_error("InventoryUI: Layout config not found at %s" % LAYOUT_PATH)
		return

	var fileAccess: FileAccess = FileAccess.open(LAYOUT_PATH, FileAccess.READ)
	var jsonData: Variant = JSON.parse_string(fileAccess.get_as_text())
	if jsonData is Dictionary:
		_layout_config = jsonData
	else:
		push_error("InventoryUI: Failed to parse layout config.")


func _setup_ui() -> void:
	_title_label.text = tr("INVENTORY_TITLE")

	if _layout_config.has("inventory"):
		var invCfg: Dictionary = _layout_config["inventory"]
		_inventory_grid.columns = int(invCfg.get("grid_columns", 5))

	_setup_equipment_slots()


func _setup_equipment_slots() -> void:
	if not _layout_config.has("equipment"):
		return

	var eqCfg: Dictionary = _layout_config["equipment"]
	var slots: Dictionary = eqCfg.get("slots", {})

	for slotName: String in slots:
		var slotData: Dictionary = slots[slotName]
		var btn: Button = Button.new()
		btn.name = "Slot_" + slotName
		btn.custom_minimum_size = Vector2(64, 64)
		btn.position = Vector2(slotData.get("pos_x", 0), slotData.get("pos_y", 0))

		var label: Label = Label.new()
		label.text = tr(slotData.get("label", slotName))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(0, -25)
		label.size = Vector2(64, 20)
		btn.add_child(label)

		_equipment_container.add_child(btn)
		_equipment_slots[slotName] = btn
		btn.pressed.connect(_on_equipment_slot_pressed.bind(slotName))
		btn.focus_entered.connect(_on_item_hovered.bind(null, slotName))


func _connect_signals() -> void:
	var im: Node = AutoloadHelper.inventory_manager()
	if im:
		im.inventory_changed.connect(_refresh_ui)
		im.equipment_changed.connect(_on_equipment_changed)


func _refresh_ui() -> void:
	_refresh_inventory_grid()
	_refresh_equipment()


func _refresh_inventory_grid() -> void:
	# Clear existing
	for child: Node in _inventory_grid.get_children():
		child.queue_free()

	var im: Node = AutoloadHelper.inventory_manager()
	if not im:
		return

	var playerInventory: Array = im.inventory
	for i: int in range(playerInventory.size()):
		var itemEntry: Dictionary = playerInventory[i]
		var itemData: Item = im.get_item_data(itemEntry["item_id"])
		if itemData:
			var itemSlot: Button = Button.new()
			itemSlot.name = "inventory_%d" % i
			itemSlot.custom_minimum_size = Vector2(64, 64)
			itemSlot.text = "%s\nx%d" % [tr(itemData.name), itemEntry["quantity"]]
			itemSlot.pressed.connect(_on_item_pressed.bind(itemEntry["item_id"], i))
			itemSlot.focus_entered.connect(_on_item_hovered.bind(itemData, ""))
			_inventory_grid.add_child(itemSlot)


func _refresh_equipment() -> void:
	var im: Node = AutoloadHelper.inventory_manager()
	if not im:
		return

	var equipment: Dictionary = im.equipment
	for slotName: String in _equipment_slots:
		var btn: Button = _equipment_slots[slotName]
		var itemId: String = equipment.get(slotName, "")
		if itemId.is_empty():
			btn.text = "---"
		else:
			var itemData: Item = im.get_item_data(itemId)
			if itemData:
				btn.text = tr(itemData.name)
			else:
				btn.text = "???"


func _on_item_pressed(itemId: String, _index: int) -> void:
	# Basic auto-equip logic for demonstration
	var im: Node = AutoloadHelper.inventory_manager()
	if not im:
		return

	var itemData: Item = im.get_item_data(itemId)
	if not itemData:
		return

	# Find a suitable slot
	for slot: String in im.slot_definitions:
		var allowed: Array = im.slot_definitions[slot]
		if _item_type_to_string(itemData.type) in allowed:
			if im.equip_item(itemId, slot):
				break


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


func _on_equipment_slot_pressed(slotName: String) -> void:
	var im: Node = AutoloadHelper.inventory_manager()
	if im:
		im.unequip_item(slotName)


func _on_item_hovered(itemData: Item, slotName: String) -> void:
	if itemData:
		_show_tooltip(itemData)
	elif not slotName.is_empty():
		var im: Node = AutoloadHelper.inventory_manager()
		var itemId: String = im.equipment.get(slotName, "")
		if not itemId.is_empty():
			var data: Item = im.get_item_data(itemId)
			_show_tooltip(data)
		else:
			_item_tooltip.hide()
	else:
		_item_tooltip.hide()


func _show_tooltip(itemData: Item) -> void:
	if not itemData:
		_item_tooltip.hide()
		return

	_item_tooltip.show()
	var label: RichTextLabel = _item_tooltip.get_node_or_null("Label") as RichTextLabel
	if label:
		label.text = "[b]%s[/b]\n%s" % [tr(itemData.name), tr(itemData.description)]


func _on_equipment_changed(_slot: String, _itemId: String) -> void:
	_refresh_ui()


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh_ui()
		# Use call_deferred to ensure nodes are ready for focus after queue_free/add_child
		call_deferred("_focus_default")


func _focus_default() -> void:
	var navCfg: Dictionary = _layout_config.get("navigation", {})
	var defaultFocus: String = navCfg.get("default_focus", "")

	if not defaultFocus.is_empty():
		if defaultFocus.begins_with("inventory_"):
			var idx: int = int(defaultFocus.split("_")[1])
			if _inventory_grid.get_child_count() > idx:
				_inventory_grid.get_child(idx).grab_focus()
				return
		elif defaultFocus.begins_with("Slot_"):
			var slotName: String = defaultFocus.split("_")[1]
			if _equipment_slots.has(slotName):
				_equipment_slots[slotName].grab_focus()
				return

	# Fallback
	if _inventory_grid.get_child_count() > 0:
		_inventory_grid.get_child(0).grab_focus()
	elif _equipment_slots.size() > 0:
		var first: Button = _equipment_slots.values()[0] as Button
		if first:
			first.grab_focus()

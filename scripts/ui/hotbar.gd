extends Control
## Hotbar (DON-196)
## Manages action slots and responsive overflow.

@onready var slots_container: HBoxContainer = %SlotsContainer
@onready var left_arrow: Button = $HBoxContainer/LeftArrow
@onready var right_arrow: Button = $HBoxContainer/RightArrow
@onready var scroll_container: ScrollContainer = $HBoxContainer/ScrollContainer

const MAX_VISIBLE_SLOTS: int = 6
const SLOT_WIDTH: float = 48.0
const SPACING: float = 4.0


func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

	# Clear initial slots to be ready for dynamic data
	clear_hotbar()


## Updates the hotbar with a list of abilities.
func set_abilities(abilities: Array[Dictionary]) -> void:
	clear_hotbar()
	var slotCount: int = slots_container.get_child_count()

	for i: int in range(abilities.size()):
		if i >= slotCount:
			break

		var slot: Control = slots_container.get_child(i) as Control
		if slot and slot.has_method("set_ability_data"):
			slot.call("set_ability_data", abilities[i])


## Clears all ability data from slots.
func clear_hotbar() -> void:
	for slot: Node in slots_container.get_children():
		if slot.has_method("set_ability_data"):
			slot.call("set_ability_data", {})


## Highlights a specific slot by ID or index.
func select_slot(index: int) -> void:
	for i: int in range(slots_container.get_child_count()):
		var slot: Node = slots_container.get_child(i)
		if slot.has_method("set_selected"):
			slot.call("set_selected", i == index)


func _on_viewport_resized() -> void:
	var viewport_width: float = get_viewport().get_visible_rect().size.x

	if viewport_width < 360.0:
		left_arrow.show()
		right_arrow.show()
		# Enforce 6 visible slots max by limiting scroll container width
		scroll_container.custom_minimum_size.x = (SLOT_WIDTH + SPACING) * MAX_VISIBLE_SLOTS
	else:
		left_arrow.hide()
		right_arrow.hide()
		scroll_container.custom_minimum_size.x = 0  # Expand naturally

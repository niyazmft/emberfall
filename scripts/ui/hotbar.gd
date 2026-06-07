extends Control
## Hotbar (DON-196)
## Manages action slots and responsive overflow.

@onready var slotsContainer: HBoxContainer = $HBoxContainer/ScrollContainer/HBoxContainer
@onready var leftArrow: Button = $HBoxContainer/LeftArrow
@onready var rightArrow: Button = $HBoxContainer/RightArrow
@onready var scrollContainer: ScrollContainer = $HBoxContainer/ScrollContainer

const MAX_VISIBLE_SLOTS: int = 6
const SLOT_WIDTH: float = 48.0
const SPACING: float = 4.0


func _ready() -> void:
	get_tree().root.size_changed.connect(_onViewportResized)
	_onViewportResized()

	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.run_started.connect(_onRunStarted)

	_refreshHotbar()


func _onRunStarted(_seed: int) -> void:
	_refreshHotbar()


func _onViewportResized() -> void:
	var viewportWidth := get_viewport().get_visible_rect().size.x
	# DESIGN_WIDTH is 320. 360 design px is 360/320 * DESIGN_WIDTH.
	# If viewport width is less than 360 relative to a 320 base.
	# Godot's stretch mode "canvas_items" means the viewport size we see is the design size if using scaling.
	# Acceptance criteria says "viewport width < 360 design px".

	if viewportWidth < 360.0:
		leftArrow.show()
		rightArrow.show()
		# Enforce 6 visible slots max by limiting scroll container width
		scrollContainer.custom_minimum_size.x = (SLOT_WIDTH + SPACING) * MAX_VISIBLE_SLOTS
	else:
		leftArrow.hide()
		rightArrow.hide()
		scrollContainer.custom_minimum_size.x = 0  # Expand naturally


func _refreshHotbar() -> void:
	var config: _ConfigLoader = AutoloadHelper.config_loader()
	var abilityMgr: _AbilityManager = (
		AutoloadHelper.get_autoload("AbilityManager") as _AbilityManager
	)

	if not config or not abilityMgr:
		_clearAllSlots()
		return

	var bindings: Variant = config.getValue("hotbar_bindings", "default_layout")
	if not bindings is Array:
		push_warning("Hotbar: No default_layout found in hotbar_bindings.")
		_clearAllSlots()
		return

	var slots: Array[Node] = slotsContainer.get_children()
	for i: int in range(slots.size()):
		var slotBtn: Button = slots[i] as Button
		if not slotBtn:
			continue

		if i < bindings.size() and bindings[i] != null:
			var abilityId: String = str(bindings[i])
			var ability: Ability = abilityMgr.getAbility(abilityId)
			if ability:
				slotBtn.text = tr(ability.nameKey)
				slotBtn.tooltip_text = tr(ability.descriptionKey)
				slotBtn.show()
			else:
				_clearSlot(slotBtn)
		else:
			_clearSlot(slotBtn)


func _clearAllSlots() -> void:
	var slots: Array[Node] = slotsContainer.get_children()
	for slot: Node in slots:
		if slot is Button:
			_clearSlot(slot)


func _clearSlot(slotBtn: Button) -> void:
	slotBtn.text = ""
	slotBtn.tooltip_text = ""
	slotBtn.hide()

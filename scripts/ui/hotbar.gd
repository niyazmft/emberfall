extends Control
## Hotbar (DON-196)
## Manages action slots and responsive overflow.

@onready var slots_container: HBoxContainer = $HBoxContainer/ScrollContainer/HBoxContainer
@onready var left_arrow: Button = $HBoxContainer/LeftArrow
@onready var right_arrow: Button = $HBoxContainer/RightArrow
@onready var scroll_container: ScrollContainer = $HBoxContainer/ScrollContainer

const MAX_VISIBLE_SLOTS: int = 6
const SLOT_WIDTH: float = 48.0
const SPACING: float = 4.0


func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.run_started.connect(_on_run_started)

	_refresh_hotbar()


func _on_run_started(_seed: int) -> void:
	_refresh_hotbar()


func _on_viewport_resized() -> void:
	var viewport_width := get_viewport().get_visible_rect().size.x
	# DESIGN_WIDTH is 320. 360 design px is 360/320 * DESIGN_WIDTH.
	# If viewport width is less than 360 relative to a 320 base.
	# Godot's stretch mode "canvas_items" means the viewport size we see is the design size if using scaling.
	# Acceptance criteria says "viewport width < 360 design px".

	if viewport_width < 360.0:
		left_arrow.show()
		right_arrow.show()
		# Enforce 6 visible slots max by limiting scroll container width
		scroll_container.custom_minimum_size.x = (SLOT_WIDTH + SPACING) * MAX_VISIBLE_SLOTS
	else:
		left_arrow.hide()
		right_arrow.hide()
		scroll_container.custom_minimum_size.x = 0  # Expand naturally


func _refresh_hotbar() -> void:
	var config: _ConfigLoader = AutoloadHelper.config_loader()
	var ability_mgr: _AbilityManager = (
		AutoloadHelper.get_autoload("AbilityManager") as _AbilityManager
	)

	if not config or not ability_mgr:
		return

	var bindings: Variant = config.getValue("hotbar_bindings", "default_layout")
	if not bindings is Array:
		push_warning("Hotbar: No default_layout found in hotbar_bindings.")
		return

	var slots: Array[Node] = slots_container.get_children()
	for i: int in range(slots.size()):
		var slot_btn: Button = slots[i] as Button
		if not slot_btn:
			continue

		if i < bindings.size() and bindings[i] != null:
			var ability_id: String = str(bindings[i])
			var ability: Ability = ability_mgr.getAbility(ability_id)
			if ability:
				slot_btn.text = tr(ability.nameKey)
				slot_btn.tooltip_text = tr(ability.descriptionKey)
				slot_btn.show()
			else:
				_clear_slot(slot_btn)
		else:
			_clear_slot(slot_btn)


func _clear_slot(slot_btn: Button) -> void:
	slot_btn.text = ""
	slot_btn.tooltip_text = ""
	slot_btn.hide()

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

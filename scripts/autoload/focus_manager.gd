extends Node
class_name _FocusManager

## Autoload: FocusManager
## Manages UI focus states and provides a global focus ring visualization.

var _focus_ring: ColorRect

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_create_focus_ring()
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

func _create_focus_ring() -> void:
	_focus_ring = ColorRect.new()
	_focus_ring.name = "FocusRing"
	_focus_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_ring.color = Color(1, 1, 1, 0.2)
	# Add a border
	var border := ReferenceRect.new()
	border.name = "Border"
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color.WHITE
	border.border_width = 2.0
	border.editor_only = false
	_focus_ring.add_child(border)

	_focus_ring.visible = false

	# Add to a CanvasLayer to ensure it's on top
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	canvas.add_child(_focus_ring)

func _on_focus_changed(control: Control) -> void:
	if control == null:
		_focus_ring.visible = false
		return

	_focus_ring.visible = true
	var global_rect := control.get_global_rect()
	_focus_ring.global_position = global_rect.position
	_focus_ring.size = global_rect.size

func set_initial_focus(container: Control) -> void:
	var first_focusable := _find_first_focusable(container)
	if first_focusable:
		first_focusable.grab_focus()

func _find_first_focusable(node: Node) -> Control:
	if node is Control and node.focus_mode != Control.FOCUS_NONE and node.is_visible_in_tree():
		return node
	for child in node.get_children():
		var found := _find_first_focusable(child)
		if found:
			return found
	return null

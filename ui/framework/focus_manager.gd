class_name _FocusManager
extends Node

## FocusManager (DON-298)
## Handles keyboard/gamepad focus trapping for modals and provides a global focus ring.

var _focus_stack: Array[Dictionary] = []
var _focus_ring: ColorRect
var _current_focused: Control = null


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_create_focus_ring()
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func _process(_delta: float) -> void:
	_update_focus_ring_position()


## Disables focus on all controls outside the given modal and sets up internal wrap-around.
func push_modal_focus(modal: Control) -> void:
	var state: Dictionary = {"modal": modal, "disabled_nodes": {}}

	# Find all focusable nodes outside the modal
	_disable_focus_outside(modal.get_tree().root, modal, state.disabled_nodes)

	# Setup wrap-around for the modal itself
	_setup_modal_wrap(modal)

	_focus_stack.append(state)

	# Set initial focus in the modal
	var first_focusable: Control = _find_first_focusable(modal)
	if first_focusable:
		first_focusable.grab_focus()


## Restores focus modes of controls that were disabled by the last push_modal_focus.
func pop_modal_focus() -> void:
	if _focus_stack.is_empty():
		return

	var state: Dictionary = _focus_stack.pop_back()
	for node: Variant in state.disabled_nodes.keys():
		var control: Control = node as Control
		if is_instance_valid(control):
			control.focus_mode = state.disabled_nodes[control] as Control.FocusMode


func _create_focus_ring() -> void:
	_focus_ring = ColorRect.new()
	_focus_ring.name = "FocusRing"
	_focus_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_ring.color = Color(1, 1, 1, 0.2)

	# Add a border
	var border: ReferenceRect = ReferenceRect.new()
	border.name = "Border"
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color.WHITE
	border.border_width = 2.0
	border.editor_only = false
	_focus_ring.add_child(border)

	_focus_ring.visible = false

	# Add to a CanvasLayer to ensure it's on top
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 120  # Above most UI
	add_child(canvas)
	canvas.add_child(_focus_ring)


func _on_focus_changed(control: Control) -> void:
	_current_focused = control
	_update_focus_ring_position()


func _update_focus_ring_position() -> void:
	if not is_instance_valid(_current_focused) or not _current_focused.is_visible_in_tree():
		_focus_ring.visible = false
		return

	_focus_ring.visible = true
	var global_rect: Rect2 = _current_focused.get_global_rect()
	_focus_ring.global_position = global_rect.position
	_focus_ring.size = global_rect.size


func _disable_focus_outside(node: Node, modal: Control, disabled_nodes: Dictionary) -> void:
	if node == modal:
		return

	if node is Control:
		var c: Control = node as Control
		if c.focus_mode != Control.FOCUS_NONE:
			disabled_nodes[c] = c.focus_mode
			c.focus_mode = Control.FOCUS_NONE

	for child: Node in node.get_children():
		_disable_focus_outside(child, modal, disabled_nodes)


func _setup_modal_wrap(modal: Control) -> void:
	var focusable: Array[Control] = _find_focusable_in(modal)
	if focusable.size() < 2:
		return

	var first: Control = focusable[0]
	var last: Control = focusable[-1]

	last.focus_next = first.get_path()
	first.focus_previous = last.get_path()

	# Gamepad vertical wrap
	last.focus_neighbor_bottom = first.get_path()
	first.focus_neighbor_top = last.get_path()


func _find_focusable_in(node: Node) -> Array[Control]:
	var found: Array[Control] = []

	if node is Control:
		var c: Control = node as Control
		# Check if the control itself is focusable and visible
		if c.visible and c.focus_mode != Control.FOCUS_NONE:
			# Only include controls that can actually receive focus (not just click)
			if c.focus_mode == Control.FOCUS_ALL:
				found.append(c)

	for child: Node in node.get_children():
		found.append_array(_find_focusable_in(child))

	return found


func _find_first_focusable(node: Node) -> Control:
	if node is Control and node.focus_mode == Control.FOCUS_ALL and node.is_visible_in_tree():
		return node as Control
	for child: Node in node.get_children():
		var found: Control = _find_first_focusable(child)
		if found:
			return found
	return null

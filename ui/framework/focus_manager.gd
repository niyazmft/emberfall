# gdlint: disable=class-name
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


func _exit_tree() -> void:
	if get_viewport() and get_viewport().gui_focus_changed.is_connected(_on_focus_changed):
		get_viewport().gui_focus_changed.disconnect(_on_focus_changed)
	_disconnect_signals(_current_focused)


## Sets initial focus to the first focusable child within the given container.
func set_initial_focus(container: Control) -> void:
	if not is_instance_valid(container):
		return
	var first: Control = _find_first_focusable(container)
	if first:
		first.grab_focus.call_deferred()


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
		first_focusable.grab_focus.call_deferred()


## Restores focus modes of controls that were disabled by the last push_modal_focus.
func pop_modal_focus() -> void:
	if _focus_stack.is_empty():
		return

	var state: Dictionary = _focus_stack.pop_back()
	for node: Variant in state.disabled_nodes.keys():
		if type_string(typeof(node)) == "Object" and not is_instance_valid(node):
			continue
		if node == null:
			continue
		var control: Control = node as Control
		if is_instance_valid(control):
			control.focus_mode = state.disabled_nodes[node] as Control.FocusMode


func _create_focus_ring() -> void:
	_focus_ring = ColorRect.new()
	_focus_ring.name = "FocusRing"
	_focus_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_ring.color = Color(1, 1, 1, 0.0)  # Hide visual background

	# Add a border
	var border: ReferenceRect = ReferenceRect.new()
	border.name = "Border"
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(1, 1, 1, 0)  # Hide visual border
	border.border_width = 0.0
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Fix mouse interception
	_focus_ring.add_child(border)

	_focus_ring.visible = false

	# Add to a CanvasLayer to ensure it's on top
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "FocusCanvas"
	canvas.layer = 120  # Above most UI
	add_child(canvas)
	canvas.add_child(_focus_ring)


func _on_focus_changed(control: Control) -> void:
	_disconnect_signals(_current_focused)
	_current_focused = control
	_connect_signals(_current_focused)
	_update_focus_ring_position()


func _on_focused_exiting() -> void:
	_current_focused = null
	_update_focus_ring_position()


func _connect_signals(control: Control) -> void:
	if is_instance_valid(control):
		if not control.item_rect_changed.is_connected(_update_focus_ring_position):
			control.item_rect_changed.connect(_update_focus_ring_position)
		if not control.visibility_changed.is_connected(_update_focus_ring_position):
			control.visibility_changed.connect(_update_focus_ring_position)
		if not control.tree_exiting.is_connected(_on_focused_exiting):
			control.tree_exiting.connect(_on_focused_exiting)


func _disconnect_signals(control: Control) -> void:
	if is_instance_valid(control):
		if control.item_rect_changed.is_connected(_update_focus_ring_position):
			control.item_rect_changed.disconnect(_update_focus_ring_position)
		if control.visibility_changed.is_connected(_update_focus_ring_position):
			control.visibility_changed.disconnect(_update_focus_ring_position)
		if control.tree_exiting.is_connected(_on_focused_exiting):
			control.tree_exiting.disconnect(_on_focused_exiting)


func _update_focus_ring_position() -> void:
	# The focus ring visuals are intentionally hidden so that custom theme
	# focus styleboxes (subtle highlights) take precedence.
	if _focus_ring:
		_focus_ring.visible = false
	return


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

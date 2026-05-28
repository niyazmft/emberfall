class_name _FocusManager
extends Node

## FocusManager (DON-298)
## Handles keyboard/gamepad focus trapping for modals.

var _focus_stack: Array[Dictionary] = []


## Disables focus on all controls outside the given modal and sets up internal wrap-around.
func push_modal_focus(modal: Control) -> void:
	var state: Dictionary = {"modal": modal, "disabled_nodes": {}}

	# Find all focusable nodes outside the modal
	_disable_focus_outside(modal.get_tree().root, modal, state.disabled_nodes)

	# Setup wrap-around for the modal itself
	_setup_modal_wrap(modal)

	_focus_stack.append(state)


## Restores focus modes of controls that were disabled by the last push_modal_focus.
func pop_modal_focus() -> void:
	if _focus_stack.is_empty():
		return

	var state: Dictionary = _focus_stack.pop_back()
	for node: Variant in state.disabled_nodes.keys():
		var control: Control = node as Control
		if is_instance_valid(control):
			control.focus_mode = state.disabled_nodes[control] as Control.FocusMode


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

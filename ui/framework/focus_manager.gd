class_name FocusManager
extends Node

## FocusManager (DON-298)
## Handles keyboard/gamepad focus trapping for modals.

static var _focus_stack: Array[Dictionary] = []


## Disables focus on all controls outside the given modal and sets up internal wrap-around.
static func push_modal_focus(modal: Control) -> void:
	var state := {"modal": modal, "disabled_nodes": {}}

	# Find all focusable nodes outside the modal
	_disable_focus_outside(modal.get_tree().root, modal, state.disabled_nodes)

	# Setup wrap-around for the modal itself
	_setup_modal_wrap(modal)

	_focus_stack.append(state)


## Restores focus modes of controls that were disabled by the last push_modal_focus.
static func pop_modal_focus() -> void:
	if _focus_stack.is_empty():
		return

	var state: Dictionary = _focus_stack.pop_back()
	for node_path: String in state.disabled_nodes:
		var node_info: Dictionary = state.disabled_nodes[node_path]
		var node: Control = node_info["node"]
		if is_instance_valid(node):
			node.focus_mode = node_info["original_mode"]


static func _disable_focus_outside(node: Node, modal: Control, disabled_nodes: Dictionary) -> void:
	if node == modal:
		return

	if node is Control:
		if node.focus_mode != Control.FOCUS_NONE:
			disabled_nodes[node.get_path()] = {"node": node, "original_mode": node.focus_mode}
			node.focus_mode = Control.FOCUS_NONE

	for child in node.get_children():
		_disable_focus_outside(child, modal, disabled_nodes)


static func _setup_modal_wrap(modal: Control) -> void:
	var focusable := _find_focusable_in(modal)
	if focusable.size() < 2:
		return

	var first: Control = focusable[0]
	var last: Control = focusable[-1]

	last.focus_next = first.get_path()
	first.focus_previous = last.get_path()

	# Gamepad vertical wrap
	last.focus_neighbor_bottom = first.get_path()
	first.focus_neighbor_top = last.get_path()


static func _find_focusable_in(node: Node) -> Array[Control]:
	var found: Array[Control] = []

	if node is Control:
		if node.visible and node.focus_mode != Control.FOCUS_NONE:
			# Only add if it's not a container that just passes focus
			if not (node is Container and node.focus_mode == Control.FOCUS_CLICK):
				# This is a bit simplified, but usually we want Buttons, Sliders, etc.
				if (
					node is Button
					or node is Slider
					or node is LineEdit
					or node is ItemList
					or node is OptionButton
				):
					found.append(node)

	for child in node.get_children():
		found.append_array(_find_focusable_in(child))

	return found

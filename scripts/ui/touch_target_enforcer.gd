class_name TouchTargetEnforcer
extends Node

## TouchTargetEnforcer (DON-298)
## Enforces a minimum touch target size of 44x44 for UI elements.

const MIN_TARGET_SIZE := Vector2(44, 44)

## Enforces minimum size on the given control.
static func enforce(control: Control) -> void:
	if not is_instance_valid(control):
		return

	# Ensure custom_minimum_size is at least MIN_TARGET_SIZE
	control.custom_minimum_size.x = max(control.custom_minimum_size.x, MIN_TARGET_SIZE.x)
	control.custom_minimum_size.y = max(control.custom_minimum_size.y, MIN_TARGET_SIZE.y)

	# If it's a button with small content, we might want to ensure the actual size is large enough
	# but custom_minimum_size is the standard way in Godot to enforce this in layouts.

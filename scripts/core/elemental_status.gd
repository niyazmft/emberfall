class_name ElementalStatus
extends Resource
## Status record for an elemental effect applied to an entity.

@export var element: ElementalTypes.Element
@export var duration: int
@export var applied_turn: int

func _init(
	p_element: ElementalTypes.Element = ElementalTypes.Element.NONE,
	p_duration: int = 0,
	p_applied_turn: int = 0
) -> void:
	element = p_element
	duration = p_duration
	applied_turn = p_applied_turn


func is_expired(current_turn: int) -> bool:
	# Hazards (if applied to entities) or special infinite durations
	if duration < 0:
		return false
	return current_turn > applied_turn + duration


func clone() -> ElementalStatus:
	return ElementalStatus.new(element, duration, applied_turn)

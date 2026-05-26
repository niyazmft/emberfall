class_name ElementalInteractionRule
extends Resource
## Defines an interaction between an attacker's element and a target's status.

@export var attacker_element: ElementalTypes.Element
@export var target_element: ElementalTypes.Element
@export var damage_multiplier: float = 1.0
@export var extinguish: bool = false
@export var spread: bool = false
@export var result_status: ElementalTypes.Element = ElementalTypes.Element.NONE
@export var result_duration: int = 0

func _init(
	p_attacker: ElementalTypes.Element = ElementalTypes.Element.NONE,
	p_target: ElementalTypes.Element = ElementalTypes.Element.NONE,
	p_mult: float = 1.0,
	p_extinguish: bool = false,
	p_spread: bool = false,
	p_result: ElementalTypes.Element = ElementalTypes.Element.NONE,
	p_result_dur: int = 0
) -> void:
	attacker_element = p_attacker
	target_element = p_target
	damage_multiplier = p_mult
	extinguish = p_extinguish
	spread = p_spread
	result_status = p_result
	result_duration = p_result_dur

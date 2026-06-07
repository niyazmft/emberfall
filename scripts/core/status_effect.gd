class_name StatusEffect
extends Resource

## Status effect resource for Project Emberfall.
## Defines status effect catalog data and combat modifiers.

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var duration: int = 0
@export var potency_formula: String = ""
@export var elemental_origin: ElementalTypes.ElementType = ElementalTypes.ElementType.NONE
@export var combat_formula_modifier: Dictionary = {}

## Instance-specific data
var remaining_duration: int = 0
var base_potency: int = 0


## Factory method to create a StatusEffect template from a Dictionary (parsed JSON).
static func from_dict(data: Dictionary) -> StatusEffect:
	var effect: StatusEffect = StatusEffect.new()
	effect.id = data.get("id", "")
	effect.name_key = data.get("name_key", "")
	effect.description_key = data.get("description_key", "")
	effect.duration = int(data.get("duration", 0))
	effect.potency_formula = data.get("potency_formula", "")
	effect.elemental_origin = _parse_elemental_origin(data.get("elemental_origin", "NONE"))
	effect.combat_formula_modifier = data.get("combat_formula_modifier", {})
	return effect


static func _parse_elemental_origin(origin_str: String) -> ElementalTypes.ElementType:
	match origin_str.to_upper():
		"FIRE":
			return ElementalTypes.ElementType.FIRE
		"WATER":
			return ElementalTypes.ElementType.WATER
		"WIND":
			return ElementalTypes.ElementType.WIND
		"OIL":
			return ElementalTypes.ElementType.OIL
		"NONE":
			return ElementalTypes.ElementType.NONE
		_:
			return ElementalTypes.ElementType.NONE


## Create an instance of this effect for an entity
func create_instance(p_duration: int = -1, p_potency: int = 0) -> StatusEffect:
	var instance: StatusEffect = self.duplicate()
	instance.remaining_duration = p_duration if p_duration >= 0 else self.duration
	instance.base_potency = p_potency
	return instance

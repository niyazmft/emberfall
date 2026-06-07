class_name StatusEffect
extends Resource

## Lightweight data container for a status effect applied to an Entity.
## Created by PR #229 but the class file was missing; added during PR #230 merge resolution.

@export var id: String = ""
@export var combatFormulaModifier: Dictionary = {}
## Status effect resource for Project Emberfall.
## Defines status effect catalog data and combat modifiers.

@export var id: String = ""
@export var nameKey: String = ""
@export var descriptionKey: String = ""
@export var duration: int = 0
@export var potencyFormula: String = ""
@export var elementalOrigin: ElementalTypes.ElementType = ElementalTypes.ElementType.NONE
@export var combatFormulaModifier: Dictionary = {}

## Instance-specific data
var remainingDuration: int = 0
var basePotency: int = 0


## Factory method to create a StatusEffect template from a Dictionary (parsed JSON).
static func fromDict(data: Dictionary) -> StatusEffect:
	var effect: StatusEffect = StatusEffect.new()
	effect.id = data.get("id", "")
	effect.nameKey = data.get("name_key", "")
	effect.descriptionKey = data.get("description_key", "")
	effect.duration = int(data.get("duration", 0))
	effect.potencyFormula = data.get("potency_formula", "")
	effect.elementalOrigin = parseElementalOrigin(data.get("elemental_origin", "NONE"))
	effect.combatFormulaModifier = data.get("combat_formula_modifier", {})
	return effect


static func parseElementalOrigin(originStr: String) -> ElementalTypes.ElementType:
	match originStr.to_upper():
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
func createInstance(pDuration: int = -1, pPotency: int = 0) -> StatusEffect:
	var instance: StatusEffect = self.duplicate()
	instance.remainingDuration = pDuration if pDuration >= 0 else self.duration
	instance.basePotency = pPotency
	return instance

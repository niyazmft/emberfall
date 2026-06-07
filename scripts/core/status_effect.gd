class_name StatusEffect
extends Resource

## Lightweight data container for a status effect applied to an Entity.
## Created by PR #229 but the class file was missing; added during PR #230 merge resolution.

@export var id: String = ""
@export var combatFormulaModifier: Dictionary = {}

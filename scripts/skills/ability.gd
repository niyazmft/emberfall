class_name Ability
extends Resource

## Ability resource for Project Emberfall.
## Defines ability catalog data and effect payloads.

enum TargetType { SELF, SINGLE_ENEMY, SINGLE_ALLY, AREA_ENEMY, AREA_ALLY, ALL }

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var ap_cost: int = 1
@export var cooldown: int = 0
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var effect_payload: Dictionary = {}


## Factory method to create an Ability from a Dictionary (parsed JSON).
static func fromDict(data: Dictionary) -> Ability:
	var ability: Ability = Ability.new()
	ability.id = data.get("id", "")
	ability.name_key = data.get("name_key", "")
	ability.description_key = data.get("description_key", "")
	ability.ap_cost = int(data.get("ap_cost", 1))
	ability.cooldown = int(data.get("cooldown", 0))
	ability.target_type = _parseTargetType(data.get("target_type", "SINGLE_ENEMY"))
	ability.effect_payload = data.get("effect_payload", {})
	return ability


static func _parseTargetType(typeStr: String) -> TargetType:
	match typeStr.to_upper():
		"SELF":
			return TargetType.SELF
		"SINGLE_ENEMY":
			return TargetType.SINGLE_ENEMY
		"SINGLE_ALLY":
			return TargetType.SINGLE_ALLY
		"AREA_ENEMY":
			return TargetType.AREA_ENEMY
		"AREA_ALLY":
			return TargetType.AREA_ALLY
		"ALL":
			return TargetType.ALL
		_:
			return TargetType.SINGLE_ENEMY

extends Node
class_name _AbilityManager

## Autoload: AbilityManager
## Manages ability registration and lookup.

var abilities: Dictionary = {}


func _ready() -> void:
	_loadAbilities()


func _loadAbilities() -> void:
	abilities.clear()
	var configLoader: _ConfigLoader = AutoloadHelper.config_loader()
	if not configLoader:
		push_error("AbilityManager: ConfigLoader not found.")
		return

	# Skills are merged into ConfigLoader's _configData
	var skillsData: Variant = configLoader.getValue("skills")
	if skillsData is Dictionary:
		for skillId: String in skillsData:
			var skillDict: Dictionary = skillsData[skillId]
			var ability: Ability = Ability.fromDict(skillDict)
			abilities[skillId] = ability
		print("AbilityManager: loaded %d abilities." % abilities.size())
	else:
		push_warning("AbilityManager: No skills data found in ConfigLoader.")


## Retrieve an ability by its ID.
func getAbility(id: String) -> Ability:
	if abilities.has(id):
		return abilities[id]
	push_warning("AbilityManager: Ability with ID '%s' not found." % id)
	return null


## Retrieve all loaded abilities.
func getAllAbilities() -> Array[Ability]:
	var result: Array[Ability] = []
	for ability: Ability in abilities.values():
		result.append(ability)
	return result

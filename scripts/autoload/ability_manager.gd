extends Node
class_name _AbilityManager

## Autoload: AbilityManager
## Manages ability registration and lookup.

var _abilities: Dictionary = {}


func _ready() -> void:
	_loadAbilities()


func _loadAbilities() -> void:
	_abilities.clear()
	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	if not config_loader:
		push_error("AbilityManager: ConfigLoader not found.")
		return

	# Skills are merged into ConfigLoader's _configData
	var skills_data: Variant = config_loader.getValue("skills")
	if skills_data is Dictionary:
		for skill_id: String in skills_data:
			var skill_dict: Dictionary = skills_data[skill_id]
			var ability: Ability = Ability.fromDict(skill_dict)
			_abilities[skill_id] = ability
		print("AbilityManager: loaded %d abilities." % _abilities.size())
	else:
		push_warning("AbilityManager: No skills data found in ConfigLoader.")


## Retrieve an ability by its ID.
func get_ability(id: String) -> Ability:
	if _abilities.has(id):
		return _abilities[id]
	push_warning("AbilityManager: Ability with ID '%s' not found." % id)
	return null


## Retrieve all loaded abilities.
func get_all_abilities() -> Array[Ability]:
	var result: Array[Ability] = []
	for ability: Ability in _abilities.values():
		result.append(ability)
	return result

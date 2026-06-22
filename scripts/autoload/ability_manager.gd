extends Node
class_name _AbilityManager

## Autoload: AbilityManager
## Manages ability registration and lookup.

signal ability_used(user: Entity, ability: Ability, target: Entity)
signal ability_failed(user: Entity, ability_id: String, reason: String)

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


## Attempt to use an ability.
## Returns true if the ability was successfully used, false otherwise.
## Checks AP cost and target range (via GridSystem) before deducting AP.
func use_ability(user: Entity, ability_id: String, target: Entity = null) -> bool:
	if user == null:
		push_warning("AbilityManager: use_ability called with null user.")
		return false

	var ability: Ability = getAbility(ability_id)
	if ability == null:
		push_warning(
			"AbilityManager: use_ability called with unknown ability ID '%s'." % ability_id
		)
		ability_failed.emit(user, ability_id, "ability_not_found")
		return false

	if user.ap < ability.apCost:
		ability_failed.emit(user, ability_id, "insufficient_ap")
		return false

	var grid: _GridSystem = AutoloadHelper.grid_system()

	if ability.targetType == Ability.TargetType.SELF:
		target = user
	else:
		if target == null:
			ability_failed.emit(user, ability_id, "no_target")
			return false
		if grid == null or not grid.is_in_bounds(target.x, target.y):
			ability_failed.emit(user, ability_id, "target_out_of_bounds")
			return false
		if not grid.is_in_bounds(user.x, user.y):
			ability_failed.emit(user, ability_id, "user_out_of_bounds")
			return false
		var dx: int = DeterministicMath.absi(target.x - user.x)
		var dy: int = DeterministicMath.absi(target.y - user.y)
		var range_val: int = int(ability.effectPayload.get("range", 1))
		if maxi(dx, dy) > range_val:
			ability_failed.emit(user, ability_id, "out_of_range")
			return false

	user.ap -= ability.apCost
	ability_used.emit(user, ability, target)
	return true

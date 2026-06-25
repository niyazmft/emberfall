class_name EncounterSystem
extends Node
## EncounterSystem
## Builds deterministic enemy spawn lists for a room based on biome composition
## and an encounter seed.

const ENCOUNTERS_CONFIG_PATH := "res://config/encounters.json"
const ENEMIES_CONFIG_PATH := "res://config/enemies.json"

## Biome-preferred fallback enemy types when an enemy doesn't match the biome.
const _BIOME_FALLBACK: Dictionary = {
	"biome1": "archer",
	"biome2": "tank",
	"biome3": "mage",
}


## Builds a list of encounters for the given biome and seed, scaled by difficulty budget.
## If room_data contains an "encounter_template" field, that specific template is used
## directly instead of biome-based weighted selection.
static func buildEncounters(
	biomeId: String, encounterSeed: int, difficulty_budget: int = 1, room_data: Dictionary = {}
) -> Array:
	var config: Dictionary = _getConfig()
	if config.is_empty():
		return []

	var groupTemplates: Dictionary = config.get("group_templates", {}) as Dictionary

	var allEnemyTypes: Array = []

	# Check for room-specific encounter template first
	var room_template: String = str(room_data.get("encounter_template", ""))
	if not room_template.is_empty() and groupTemplates.has(room_template):
		allEnemyTypes = groupTemplates.get(room_template, []) as Array
	else:
		# Fall back to biome composition weighted selection
		var compositions: Array = config.get("biome_compositions", {}).get(biomeId, [])
		if compositions.is_empty():
			return []

		var rng := RandomNumberGenerator.new()
		rng.seed = encounterSeed

		var remaining_budget := difficulty_budget
		while remaining_budget > 0:
			var possible_comps: Array = []
			for comp_v: Variant in compositions:
				var comp := comp_v as Dictionary
				if int(comp.get("difficulty", 1)) <= remaining_budget:
					possible_comps.append(comp)

			if possible_comps.is_empty():
				break

			var selectedGroupId: String = _selectWeightedGroup(possible_comps, rng)
			if selectedGroupId == "":
				break

			var selected_comp: Dictionary = {}
			for comp_v: Variant in possible_comps:
				var comp := comp_v as Dictionary
				if str(comp.get("group_id", "")) == selectedGroupId:
					selected_comp = comp
					break

			if not selected_comp.is_empty():
				remaining_budget -= int(selected_comp.get("difficulty", 1))
				var enemyEntries: Array = groupTemplates.get(selectedGroupId, []) as Array
				allEnemyTypes.append_array(enemyEntries)
			else:
				break

	if allEnemyTypes.is_empty():
		return []

	# Apply biome affinity: substitute enemies that don't belong in this biome
	allEnemyTypes = _apply_biome_affinity(allEnemyTypes, biomeId)

	var encounters: Array = []
	var typeCounts: Dictionary = {}
	var leaderFlags: Dictionary = {}

	for entry_v: Variant in allEnemyTypes:
		var entry: Dictionary = {} if not entry_v is Dictionary else entry_v as Dictionary
		var type: String = str(entry.get("type", str(entry_v)))
		if not typeCounts.has(type):
			typeCounts[type] = 0
			leaderFlags[type] = false
		typeCounts[type] = int(typeCounts[type]) + 1
		if bool(entry.get("leader", false)):
			leaderFlags[type] = true

	for type: String in typeCounts:
		encounters.append(
			{
				"enemy_type": type,
				"count": int(typeCounts[type]),
				"positions": [] as Array,
				"leader": bool(leaderFlags.get(type, false))
			}
		)

	# Apply moral consequence: extra spawns at high MWT
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm != null:
		var consequence: Dictionary = bm.get_moral_consequence()
		var extra_spawn: int = int(consequence.get("extra_spawn", 0))
		if extra_spawn > 0 and not encounters.is_empty():
			# Add extra_spawn grunts to the first encounter group
			var first: Dictionary = encounters[0] as Dictionary
			first["count"] = int(first.get("count", 0)) + extra_spawn

	return encounters


## Loads the encounters config from JSON.
static func _getConfig() -> Dictionary:
	var f: FileAccess = FileAccess.open(ENCOUNTERS_CONFIG_PATH, FileAccess.READ)
	if not f:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		return data as Dictionary
	return {}


## Loads the enemies config from JSON.
static func _getEnemiesConfig() -> Dictionary:
	var f: FileAccess = FileAccess.open(ENEMIES_CONFIG_PATH, FileAccess.READ)
	if not f:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		return data as Dictionary
	return {}


## Applies biome affinity to the enemy type list.
## Enemies with biome_affinity "ANY" or matching the biome are kept.
## Non-matching enemies are substituted with the biome's preferred type.
static func _apply_biome_affinity(enemyTypes: Array, biomeId: String) -> Array:
	var enemiesConfig: Dictionary = _getEnemiesConfig()
	if enemiesConfig.is_empty():
		return enemyTypes

	var enemyDefs: Dictionary = enemiesConfig.get("enemies", {}) as Dictionary
	var fallbackType: String = _BIOME_FALLBACK.get(biomeId, "grunt")
	var result: Array = []

	for entry_v: Variant in enemyTypes:
		var entry: Dictionary = {} if not entry_v is Dictionary else entry_v as Dictionary
		var type: String = str(entry.get("type", str(entry_v)))
		var def: Dictionary = enemyDefs.get(type, {}) as Dictionary
		var affinity: String = str(def.get("biome_affinity", "ANY"))

		if affinity == "ANY" or affinity == biomeId:
			result.append(entry_v)
		else:
			# Substitute with biome-preferred type, but verify it exists
			var fallbackDef: Dictionary = enemyDefs.get(fallbackType, {}) as Dictionary
			var fallbackAffinity: String = str(fallbackDef.get("biome_affinity", "ANY"))
			var newType: String = fallbackType
			if fallbackAffinity != "ANY" and fallbackAffinity != biomeId:
				newType = "grunt"
			# Preserve leader flag if present
			var wasLeader: bool = bool(entry.get("leader", false))
			result.append({"type": newType, "leader": wasLeader})

	return result


static func _selectWeightedGroup(compositions: Array, rng: RandomNumberGenerator) -> String:
	var totalWeight: float = 0.0
	for comp_v: Variant in compositions:
		if comp_v is Dictionary:
			var comp: Dictionary = comp_v as Dictionary
			totalWeight += float(comp.get("weight", 0.0))

	if totalWeight <= 0.0:
		return ""

	var roll: float = rng.randf() * totalWeight
	var currentWeight: float = 0.0
	for comp_v: Variant in compositions:
		if comp_v is Dictionary:
			var comp: Dictionary = comp_v as Dictionary
			currentWeight += float(comp.get("weight", 0.0))
			if roll <= currentWeight:
				return str(comp.get("group_id", ""))

	return ""

class_name EncounterSystem
extends Node
## EncounterSystem
## Builds deterministic enemy spawn lists for a room based on biome composition
## and an encounter seed.

const ENCOUNTERS_CONFIG_PATH := "res://config/encounters.json"


## Builds a list of encounters for the given biome and seed.
static func buildEncounters(biomeId: String, encounterSeed: int) -> Array:
	var config: Dictionary = _getConfig()
	if config.is_empty():
		return []

	var compositions: Array = config.get("biome_compositions", {}).get(biomeId, [])
	if compositions.is_empty():
		return []

	var groupTemplates: Dictionary = config.get("group_templates", {}) as Dictionary

	var rng := RandomNumberGenerator.new()
	rng.seed = encounterSeed

	# Select a group template based on weights
	var selectedGroupId: String = _selectWeightedGroup(compositions, rng)
	if selectedGroupId == "":
		return []

	var enemyTypes: Array = groupTemplates.get(selectedGroupId, []) as Array
	if enemyTypes.is_empty():
		return []

	var encounters: Array = []
	var typeCounts: Dictionary = {}

	for type_v: Variant in enemyTypes:
		var type: String = str(type_v)
		if not typeCounts.has(type):
			typeCounts[type] = 0
		typeCounts[type] = int(typeCounts[type]) + 1

	for type: String in typeCounts:
		encounters.append(
			{"enemy_type": type, "count": int(typeCounts[type]), "positions": [] as Array}
		)

	return encounters


static func _getConfig() -> Dictionary:
	var f: FileAccess = FileAccess.open(ENCOUNTERS_CONFIG_PATH, FileAccess.READ)
	if not f:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		return data as Dictionary
	return {}


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

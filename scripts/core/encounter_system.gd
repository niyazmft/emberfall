class_name EncounterSystem
extends Node
## EncounterSystem
## Builds deterministic enemy spawn lists for a room based on biome composition
## and an encounter seed.

const ENCOUNTERS_CONFIG_PATH := "res://config/encounters.json"


## Builds a list of encounters for the given biome and seed, scaled by difficulty budget.
static func buildEncounters(
	biomeId: String, encounterSeed: int, difficulty_budget: int = 1
) -> Array:
	var config: Dictionary = _getConfig()
	if config.is_empty():
		return []

	var compositions: Array = config.get("biome_compositions", {}).get(biomeId, [])
	if compositions.is_empty():
		return []

	var groupTemplates: Dictionary = config.get("group_templates", {}) as Dictionary

	var rng := RandomNumberGenerator.new()
	rng.seed = encounterSeed

	var allEnemyTypes: Array = []
	var remaining_budget := difficulty_budget

	# Budget-based loop to pick multiple groups if budget allows
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

		# Find the selected composition to deduct its difficulty
		var selected_comp: Dictionary = {}
		for comp_v: Variant in possible_comps:
			var comp := comp_v as Dictionary
			if str(comp.get("group_id", "")) == selectedGroupId:
				selected_comp = comp
				break

		if not selected_comp.is_empty():
			remaining_budget -= int(selected_comp.get("difficulty", 1))
			var enemyTypes: Array = groupTemplates.get(selectedGroupId, []) as Array
			allEnemyTypes.append_array(enemyTypes)
		else:
			break

	if allEnemyTypes.is_empty():
		return []

	var encounters: Array = []
	var typeCounts: Dictionary = {}

	for type_v: Variant in allEnemyTypes:
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

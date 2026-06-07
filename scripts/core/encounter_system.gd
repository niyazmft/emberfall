class_name EncounterSystem
extends Node
## EncounterSystem
## Builds deterministic enemy spawn lists for a room based on biome composition
## and an encounter seed.

const ENCOUNTERS_CONFIG_PATH := "res://config/encounters.json"


## Builds a list of encounters for the given biome and seed.
static func build_encounters(biome_id: String, encounter_seed: int) -> Array:
	var config := _get_config()
	if config.is_empty():
		return []

	var compositions: Array = config.get("biome_compositions", {}).get(biome_id, [])
	if compositions.is_empty():
		return []

	var group_templates: Dictionary = config.get("group_templates", {})

	var rng := RandomNumberGenerator.new()
	rng.seed = encounter_seed

	# Select a group template based on weights
	var selected_group_id := _select_weighted_group(compositions, rng)
	var enemy_types: Array = group_templates.get(selected_group_id, [])

	if enemy_types.is_empty():
		return []

	# Build encounter dictionary
	# For now, we'll just return a single encounter entry containing all enemies
	# but with randomly assigned valid positions.
	# Positions will need to be decided by the RoomLoader or a shared helper
	# because we need to know what's walkable/blocked.
	# However, the schema expects positions in the encounter object.
	# For simplicity in this step, we'll just return the types and let the
	# loader assign positions if they are not provided, or we provide them here
	# assuming some standard areas.

	var encounters := []
	var type_counts := {}

	for type: String in enemy_types:
		if not type_counts.has(type):
			type_counts[type] = 0
		type_counts[type] += 1

	for type: String in type_counts:
		encounters.append({
			"enemy_type": type,
			"count": type_counts[type],
			"positions": [] # Will be filled by the loader or a positioner
		})

	return encounters


static func _get_config() -> Dictionary:
	var f := FileAccess.open(ENCOUNTERS_CONFIG_PATH, FileAccess.READ)
	if not f:
		return {}
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	f.close()
	if err != OK:
		return {}
	return json.data


static func _select_weighted_group(compositions: Array, rng: RandomNumberGenerator) -> String:
	var total_weight := 0.0
	for comp: Dictionary in compositions:
		total_weight += float(comp.get("weight", 0.0))

	var roll := rng.randf() * total_weight
	var current_weight := 0.0
	for comp: Dictionary in compositions:
		current_weight += float(comp.get("weight", 0.0))
		if roll <= current_weight:
			return comp.get("group_id", "")

	return compositions[0].get("group_id", "")

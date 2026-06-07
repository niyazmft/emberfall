extends Node
class_name _ConfigLoader

## Autoload: ConfigLoader
## Loads gameplay constants from JSON config with sensible hard-coded defaults.
## All tunable values live in res://config/game_config.json per gameplay standards.

const CONFIG_PATH := "res://config/game_config.json"
const ITEMS_PATH := "res://config/items.json"
const EQUIPMENT_PATH := "res://config/entity_equipment.json"
const ENEMIES_PATH := "res://config/enemies.json"
const SKILLS_PATH := "res://config/skills.json"
const HOTBAR_BINDINGS_PATH := "res://config/hotbar_bindings.json"
const STATUS_EFFECTS_PATH := "res://config/status_effects.json"
const ACCESSIBILITY_PATH := "res://config/accessibility.json"
const REWARDS_PATH := "res://config/rewards.json"
const UNLOCKS_PATH := "res://config/unlocks.json"
const ENCOUNTER_SCALER_PATH := "res://config/encounter_scaler.json"
const PROGRESSION_PATH := "res://config/progression.json"
const XP_ECONOMY_PATH := "res://config/xp_economy.json"
const BIOMES_PATH := "res://config/biomes.json"
const ELITE_MODIFIERS_PATH := "res://config/elite_modifiers.json"

# Fallback defaults (sensible so the game runs even if config is missing)
const DEFAULTS: Dictionary = {
	"AP_MAX": 6,
	"AP_REGEN": 2,
	"D_BASE": 10,
	"CRIT_MULT": 1.5,
	"MIN_DAMAGE": 1,
	"POSITION_MODIFIER_MIN": 0.5,
	"POSITION_MODIFIER_MAX": 1.5,
	"BACKSTAB_BONUS": 0.25,
	"ELEVATION_1_BONUS": 0.15,
	"ELEVATION_2_BONUS": 0.25,
	"LIGHT_COVER_PENALTY": -0.15,
	"HEAVY_COVER_PENALTY": -0.30,
	"BACKSTAB_DOT_THRESHOLD": -0.7,
	"FIRE_OIL_MODIFIER": 2.0,
	"WIND_FIRE_MODIFIER": 1.5,
	"WATER_FIRE_MODIFIER": 0.5,
	"OIL_SLIP_SPEED_MULT": 0.8,
	"FIRE_DURATION_TURNS": 1,
	"FIRE_OIL_DURATION_TURNS": 1,
	"HP_MAX_DEFAULT": 40,
	"OFF_DEFAULT": 12,
	"DEF_DEFAULT": 6,
	"MWT": 3,
	"MORAL_DELTA_KILL": 1,
	"MORAL_DELTA_SPARE": -1,
	"MORAL_DELTA_ENV": 0,
	"BIOME_COUNT": 3,
	"ROOMS_PER_BIOME_MIN": 8,
	"ROOMS_PER_BIOME_MAX": 12,
	"DYING_DURATION_TURNS": 1,
	"GRID_W": 12,
	"GRID_H": 12,
}

var _configData: Dictionary = {}
var _loadedFiles: Dictionary = {
	CONFIG_PATH: false,
	ITEMS_PATH: false,
	EQUIPMENT_PATH: false,
	ENEMIES_PATH: false,
	SKILLS_PATH: false,
	HOTBAR_BINDINGS_PATH: false,
	STATUS_EFFECTS_PATH: false,
	ACCESSIBILITY_PATH: false,
	REWARDS_PATH: false,
	UNLOCKS_PATH: false,
	ENCOUNTER_SCALER_PATH: false,
	PROGRESSION_PATH: false,
	XP_ECONOMY_PATH: false,
	BIOMES_PATH: false,
	ELITE_MODIFIERS_PATH: false,
}


func _ready() -> void:
	_loadConfig()


func _loadConfig() -> void:
	_configData.clear()
	for path: String in _loadedFiles:
		_loadedFiles[path] = false

	_load_json_to_config(CONFIG_PATH, "config")
	_load_json_to_config(ITEMS_PATH, "items")
	_load_json_to_config(EQUIPMENT_PATH, "equipment")
	_load_json_to_config(ENEMIES_PATH, "enemies")
	_load_json_to_config(SKILLS_PATH, "skills")
	_load_json_to_config(HOTBAR_BINDINGS_PATH, "hotbar_bindings")
	_load_json_to_config(STATUS_EFFECTS_PATH, "status_effects")
	_load_json_to_config(ACCESSIBILITY_PATH, "accessibility")
	_load_json_to_config(REWARDS_PATH, "rewards")
	_load_json_to_config(UNLOCKS_PATH, "unlocks")
	_load_json_to_config(ENCOUNTER_SCALER_PATH, "encounter_scaler")
	_load_json_to_config(PROGRESSION_PATH, "progression")
	_load_json_to_config(XP_ECONOMY_PATH, "xp_economy")
	_load_json_to_config(ELITE_MODIFIERS_PATH, "elite_modifiers")

	var actual_biomes_path := BIOMES_PATH
	if _configData.has("config") and _configData["config"].has("run_manager"):
		actual_biomes_path = _configData["config"]["run_manager"].get(
			"BIOMES_CONFIG_PATH", BIOMES_PATH
		)

	_load_json_to_config(actual_biomes_path, "biomes")


func _load_json_to_config(file_path: String, p_namespace: String = "") -> void:
	if FileAccess.file_exists(file_path):
		var file_handle: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if file_handle:
			var file_text: String = file_handle.get_as_text()
			var parsed_json: Variant = JSON.parse_string(file_text)
			if parsed_json is Dictionary:
				if p_namespace.is_empty():
					_configData.merge(parsed_json, true)
				else:
					_configData[p_namespace] = parsed_json
				_loadedFiles[file_path] = true
				print(
					(
						"ConfigLoader: loaded config from %s into namespace '%s'"
						% [file_path, p_namespace]
					)
				)
			else:
				push_warning(
					"ConfigLoader: config file %s was not a valid JSON object." % file_path
				)
			file_handle.close()
	else:
		push_warning("ConfigLoader: config file not found at %s." % file_path)


## Get a gameplay constant. First checks config JSON, then falls back to DEFAULTS.
## Usage: ConfigLoader.getValue("AP_MAX") or ConfigLoader.getValue("combat", "D_BASE")
func getValue(sectionOrKey: String, key: String = "", fallback: Variant = null) -> Variant:
	if not key.is_empty():
		# Two-arg mode: section + key
		var section: Dictionary = {}
		if _configData.has(sectionOrKey) and _configData[sectionOrKey] is Dictionary:
			section = _configData[sectionOrKey]
		else:
			# Scan sub-sections for sectionOrKey (needed for namespaced files)
			for s: Variant in _configData.values():
				if s is Dictionary and s.has(sectionOrKey) and s[sectionOrKey] is Dictionary:
					section = s[sectionOrKey]
					break

		if not section.is_empty():
			# If the section also contains a dictionary with the same name, dive into it
			# to maintain backward compatibility with JSONs like {"items": {"items": {...}}}
			if section.has(sectionOrKey) and section[sectionOrKey] is Dictionary:
				section = section[sectionOrKey]

			if section.has(key):
				return section[key]

		# Try flattened default
		if DEFAULTS.has(key):
			return DEFAULTS[key]
		return fallback
	else:
		# One-arg mode: direct key lookup in namespaced or flattened namespace
		if _configData.has(sectionOrKey):
			var data: Variant = _configData[sectionOrKey]
			# If the key points to a sub-dictionary with the same name, return that sub-dictionary
			# to maintain backward compatibility with JSONs like {"items": {"items": {...}}}
			if data is Dictionary and data.has(sectionOrKey):
				return data[sectionOrKey]
			return data

		# Backward compatibility: scan sub-sections for key if not found in root
		if (
			sectionOrKey != "items"
			and sectionOrKey != "enemies"
			and sectionOrKey != "equipment"
			and sectionOrKey != "progression"
			and sectionOrKey != "xp_economy"
			and sectionOrKey != "accessibility"
			and sectionOrKey != "config"
			and sectionOrKey != "biomes"
			and sectionOrKey != "skills"
			and sectionOrKey != "hotbar_bindings"
			and sectionOrKey != "status_effects"
			and sectionOrKey != "rewards"
			and sectionOrKey != "unlocks"
			and sectionOrKey != "encounter_scaler"
			and sectionOrKey != "elite_modifiers"
		):
			for section: Variant in _configData.values():
				if section is Dictionary and section.has(sectionOrKey):
					return section[sectionOrKey]

		if DEFAULTS.has(sectionOrKey):
			return DEFAULTS[sectionOrKey]
		return fallback


## Convenience typed getters for hot-path values.
func getInt(key: String, fallback: int = 0) -> int:
	var v: Variant = getValue(key, "", fallback)
	if v is float:
		return int(v)
	if v is int:
		return v
	return fallback


func getFloat(key: String, fallback: float = 0.0) -> float:
	var v: Variant = getValue(key, "", fallback)
	if v is float or v is int:
		return float(v)
	return fallback


func getString(key: String, fallback: String = "") -> String:
	var v: Variant = getValue(key, "", fallback)
	if v is String:
		return v
	return fallback


func isLoaded() -> bool:
	for path: String in _loadedFiles:
		if not _loadedFiles[path]:
			return false
	return true

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
const ACCESSIBILITY_PATH := "res://config/accessibility.json"
const REWARDS_PATH := "res://config/rewards.json"
const UNLOCKS_PATH := "res://config/unlocks.json"
const ENCOUNTER_SCALER_PATH := "res://config/encounter_scaler.json"
const PROGRESSION_PATH := "res://config/progression.json"
const XP_ECONOMY_PATH := "res://config/xp_economy.json"
const BIOMES_PATH := "res://config/biomes.json"
const ELITE_MODIFIERS_PATH := "res://config/elite_modifiers.json"
const GRID_VISUALS_PATH := "res://config/grid_visuals.json"

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
	ACCESSIBILITY_PATH: false,
	REWARDS_PATH: false,
	UNLOCKS_PATH: false,
	ENCOUNTER_SCALER_PATH: false,
	PROGRESSION_PATH: false,
	XP_ECONOMY_PATH: false,
	BIOMES_PATH: false,
	ELITE_MODIFIERS_PATH: false,
	GRID_VISUALS_PATH: false,
}


func _ready() -> void:
	_loadConfig()


func _loadConfig() -> void:
	_configData.clear()
	for path: String in _loadedFiles:
		_loadedFiles[path] = false

	_loadJsonToConfig(CONFIG_PATH, "config")
	_loadJsonToConfig(ITEMS_PATH, "items")
	_loadJsonToConfig(EQUIPMENT_PATH, "equipment")
	_loadJsonToConfig(ENEMIES_PATH, "enemies")
	_loadJsonToConfig(SKILLS_PATH, "skills")
	_loadJsonToConfig(HOTBAR_BINDINGS_PATH, "hotbar_bindings")
	_loadJsonToConfig(STATUS_EFFECTS_PATH, "status_effects")
	_loadJsonToConfig(ACCESSIBILITY_PATH, "accessibility")
	_loadJsonToConfig(REWARDS_PATH, "rewards")
	_loadJsonToConfig(UNLOCKS_PATH, "unlocks")
	_loadJsonToConfig(ENCOUNTER_SCALER_PATH, "encounter_scaler")
	_loadJsonToConfig(PROGRESSION_PATH, "progression")
	_loadJsonToConfig(XP_ECONOMY_PATH, "xp_economy")
	_loadJsonToConfig(ELITE_MODIFIERS_PATH, "elite_modifiers")

	var actual_biomes_path := BIOMES_PATH
	if _configData.has("config") and _configData["config"].has("run_manager"):
		actual_biomes_path = _configData["config"]["run_manager"].get(
			"BIOMES_CONFIG_PATH", BIOMES_PATH
		)

	_loadJsonToConfig(actual_biomes_path, "biomes")


func _loadJsonToConfig(filePath: String, p_namespace: String = "") -> void:
	_loadJsonToConfig(CONFIG_PATH)
	_loadJsonToConfig(ITEMS_PATH)
	_loadJsonToConfig(EQUIPMENT_PATH)
	_loadJsonToConfig(ENEMIES_PATH)
	_loadJsonToConfig(SKILLS_PATH)
	_loadJsonToConfig(HOTBAR_BINDINGS_PATH)
	_loadJsonToConfig(ACCESSIBILITY_PATH)
	_loadJsonToConfig(GRID_VISUALS_PATH)
	_validateGridVisuals()


func _loadJsonToConfig(filePath: String) -> void:
	if FileAccess.file_exists(filePath):
		var fileHandle: FileAccess = FileAccess.open(filePath, FileAccess.READ)
		if fileHandle:
			var fileText: String = fileHandle.get_as_text()
			var parsedJson: Variant = JSON.parse_string(fileText)
			if parsedJson is Dictionary:
				_configData.merge(parsedJson, true)
				_loadedFiles[filePath] = true
				print("ConfigLoader: loaded config from %s" % filePath)
			else:
				push_warning("ConfigLoader: config file %s was not a valid JSON object." % filePath)
			fileHandle.close()
	else:
		push_warning("ConfigLoader: config file not found at %s." % filePath)


## Get a gameplay constant. First checks config JSON, then falls back to DEFAULTS.
## Usage: ConfigLoader.getValue("AP_MAX") or ConfigLoader.getValue("combat", "D_BASE")
func getValue(sectionOrKey: String, key: String = "", fallback: Variant = null) -> Variant:
	if not key.is_empty():
		# Two-arg mode: section + key
		if _configData.has(sectionOrKey) and _configData[sectionOrKey] is Dictionary:
			var section: Dictionary = _configData[sectionOrKey]
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

	# One-arg mode: direct key lookup in flattened namespace
	if _configData.has(sectionOrKey):
		return _configData[sectionOrKey]
	# Scan sub-sections for key
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


func _validateGridVisuals() -> void:
	if not _configData.has("highlights"):
		return

	var rawHighlights: Variant = _configData["highlights"]
	if not rawHighlights is Dictionary:
		return
	var highlightsDict: Dictionary = rawHighlights as Dictionary

	for key: Variant in highlightsDict.keys():
		var styleRef: Variant = highlightsDict[key]
		if styleRef is Dictionary:
			var style: Dictionary = styleRef as Dictionary
			if style.has("pulse"):
				var pulseRef: Variant = style["pulse"]
				if pulseRef is Dictionary:
					var pulse: Dictionary = pulseRef as Dictionary
					var minA: float = float(pulse.get("min_alpha", 0.0))
					var maxA: float = float(pulse.get("max_alpha", 1.0))
					if minA > maxA:
						push_error(
							(
								"ConfigLoader: Grid visual style '%s' has min_alpha (%.2f) > max_alpha (%.2f)!"
								% [str(key), minA, maxA]
							)
						)

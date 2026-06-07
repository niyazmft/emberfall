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
}


func _ready() -> void:
	_loadConfig()


func _loadConfig() -> void:
	_configData.clear()
	for path: String in _loadedFiles:
		_loadedFiles[path] = false

	_loadJsonToConfig(CONFIG_PATH)
	_loadJsonToConfig(ITEMS_PATH)
	_loadJsonToConfig(EQUIPMENT_PATH)
	_loadJsonToConfig(ENEMIES_PATH)
	_loadJsonToConfig(SKILLS_PATH)
	_loadJsonToConfig(HOTBAR_BINDINGS_PATH)
	_loadJsonToConfig(ACCESSIBILITY_PATH)


func _loadJsonToConfig(filePath: String) -> void:
	if FileAccess.file_exists(filePath):
		var fileHandle: FileAccess = FileAccess.open(filePath, FileAccess.READ)
		if fileHandle:
			var fileText: String = fileHandle.get_as_text()
			var parsedJson: Variant = JSON.parse_string(fileText)
			if parsedJson is Dictionary:
				var p_namespace: String = filePath.get_file().get_basename()
				var data_to_merge: Dictionary = parsedJson as Dictionary
				# Unwrap if the root key matches the namespace (redundant level in JSON)
				if data_to_merge.has(p_namespace) and data_to_merge.size() == 1:
					data_to_merge = data_to_merge[p_namespace]

				if not _configData.has(p_namespace):
					_configData[p_namespace] = {}
				(_configData[p_namespace] as Dictionary).merge(data_to_merge, true)
				_loadedFiles[filePath] = true
				print(
					(
						"ConfigLoader: loaded config from %s into namespace %s"
						% [filePath, p_namespace]
					)
				)
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
		# Try looking up section as a namespace, then key inside it
		if _configData.has(sectionOrKey):
			var ns: Variant = _configData[sectionOrKey]
			if ns is Dictionary:
				if ns.has(key):
					return ns[key]
				# Also check if the section itself is inside the namespace (redundant level)
				if ns.has(sectionOrKey) and ns[sectionOrKey] is Dictionary:
					var inner: Dictionary = ns[sectionOrKey]
					if inner.has(key):
						return inner[key]

		# Fallback: scan all namespaces for the section, then the key
		for ns: Variant in _configData.values():
			if ns is Dictionary:
				if ns.has(sectionOrKey):
					var section: Variant = ns[sectionOrKey]
					if section is Dictionary and section.has(key):
						return section[key]

		# Try flattened default
		if DEFAULTS.has(key):
			return DEFAULTS[key]
		return fallback

	# One-arg mode
	# 1. Direct namespace lookup
	if _configData.has(sectionOrKey):
		var val: Variant = _configData[sectionOrKey]
		# If it's a dictionary with a single key that matches the namespace, unwrap it
		if val is Dictionary and val.has(sectionOrKey) and val.size() == 1:
			return val[sectionOrKey]
		return val

	# 2. Scan namespaces for the key or deeper sections
	for ns: Variant in _configData.values():
		if ns is Dictionary:
			if ns.has(sectionOrKey):
				return ns[sectionOrKey]
			# One level deeper (e.g. game_config -> ap_economy)
			for sub: Variant in ns.values():
				if sub is Dictionary and sub.has(sectionOrKey):
					return sub[sectionOrKey]

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

extends Node
class_name _ConfigLoader

## Autoload: ConfigLoader
## Loads gameplay constants from JSON config with sensible hard-coded defaults.
## All tunable values live in res://config/game_config.json per gameplay standards.

const CONFIG_PATH := "res://config/game_config.json"

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

var _config: Dictionary = {}
var _loaded: bool = false


func _ready() -> void:
	_load_config()


func _load_config() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file:
			var text: String = file.get_as_text()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary:
				_config = parsed
				_loaded = true
				print("ConfigLoader: loaded config from %s" % CONFIG_PATH)
			else:
				push_warning(
					"ConfigLoader: config file was not a valid JSON object; using defaults."
				)
			file.close()
	else:
		push_warning("ConfigLoader: config file not found at %s; using defaults." % CONFIG_PATH)


## Get a gameplay constant. First checks config JSON, then falls back to DEFAULTS.
## Usage: ConfigLoader.get_value("AP_MAX") or ConfigLoader.get_value("combat", "D_BASE")
func get_value(section_or_key: String, key: String = "", fallback: Variant = null) -> Variant:
	if not key.is_empty():
		# Two-arg mode: section + key
		if _config.has(section_or_key) and _config[section_or_key] is Dictionary:
			var section: Dictionary = _config[section_or_key]
			if section.has(key):
				return section[key]
		# Try flattened default
		if DEFAULTS.has(key):
			return DEFAULTS[key]
		return fallback
	else:
		# One-arg mode: direct key lookup in flattened namespace
		if _config.has(section_or_key):
			return _config[section_or_key]
		# Scan sub-sections for key
		for section: Variant in _config.values():
			if section is Dictionary and section.has(section_or_key):
				return section[section_or_key]
		if DEFAULTS.has(section_or_key):
			return DEFAULTS[section_or_key]
		return fallback


## Convenience typed getters for hot-path values.
func get_int(key: String, fallback: int = 0) -> int:
	var v: Variant = get_value(key, "", fallback)
	if v is float:
		return int(v)
	if v is int:
		return v
	return fallback


func get_float(key: String, fallback: float = 0.0) -> float:
	var v: Variant = get_value(key, "", fallback)
	if v is float or v is int:
		return float(v)
	return fallback


func get_string(key: String, fallback: String = "") -> String:
	var v: Variant = get_value(key, "", fallback)
	if v is String:
		return v
	return fallback


func is_loaded() -> bool:
	return _loaded

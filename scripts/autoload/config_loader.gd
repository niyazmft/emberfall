class_name _ConfigLoader
extends Node

## Autoload: ConfigLoader
## Loads gameplay constants from JSON config with sensible hard-coded defaults.
## All tunable values live in res://config/game_config.json per gameplay standards.

const CONFIG_PATH := "res://config/game_config.json"
const ITEMS_PATH := "res://config/items.json"
const EQUIPMENT_PATH := "res://config/entity_equipment.json"
const ENEMIES_PATH := "res://config/enemies.json"
const SKILLS_PATH := "res://config/skills.json"
const STATUS_EFFECTS_PATH := "res://config/status_effects.json"
const ACCESSIBILITY_PATH := "res://config/accessibility.json"
const GRID_VISUALS_PATH := "res://config/grid_visuals.json"
const BIOMES_PATH := "res://config/biomes.json"
const SECRET_ROOM_CONDITIONS_PATH := "res://config/secret_room_conditions.json"
const PROPS_PATH := "res://data/props.json"
const AMBIENT_NARRATOR_PATH := "res://data/ambient_narrator.json"
const REWARDS_PATH := "res://config/rewards.json"
const UNLOCKS_PATH := "res://config/unlocks.json"
const ENCOUNTER_SCALER_PATH := "res://config/encounter_scaler.json"
const HUD_CONFIG_PATH := "res://config/hud_config.json"
const UI_AUDIO_MANIFEST_PATH := "res://config/ui_audio_manifest.json"
const SETTINGS_HELP_PATH := "res://config/settings_help.json"
const HAPTICS_CONFIG_PATH := "res://config/haptics_config.json"
const PROGRESSION_PATH := "res://config/progression.json"
const XP_ECONOMY_PATH := "res://config/xp_economy.json"
const ELITE_MODIFIERS_PATH := "res://config/elite_modifiers.json"
const FEEDBACK_PATH := "res://config/feedback_config.json"
const HOTBAR_BINDINGS_PATH := "res://config/hotbar_bindings.json"

# Fallback defaults (sensible so the game runs even if config is missing)
const DEFAULTS: Dictionary = {
	"AP_MAX": 6,
	"AP_REGEN": 2,
	"ability_min": 3,
	"ability_max": 5,
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

var _config_data: Dictionary = {}
var _loaded_files: Dictionary = {
	CONFIG_PATH: false,
	ITEMS_PATH: false,
	EQUIPMENT_PATH: false,
	ENEMIES_PATH: false,
	SKILLS_PATH: false,
	STATUS_EFFECTS_PATH: false,
	ACCESSIBILITY_PATH: false,
	GRID_VISUALS_PATH: false,
	BIOMES_PATH: false,
	SECRET_ROOM_CONDITIONS_PATH: false,
	PROPS_PATH: false,
	AMBIENT_NARRATOR_PATH: false,
	REWARDS_PATH: false,
	UNLOCKS_PATH: false,
	ENCOUNTER_SCALER_PATH: false,
	HUD_CONFIG_PATH: false,
	UI_AUDIO_MANIFEST_PATH: false,
	SETTINGS_HELP_PATH: false,
	HAPTICS_CONFIG_PATH: false,
	PROGRESSION_PATH: false,
	XP_ECONOMY_PATH: false,
	ELITE_MODIFIERS_PATH: false,
	FEEDBACK_PATH: false,
	HOTBAR_BINDINGS_PATH: false,
}


func _ready() -> void:
	_load_config()


func _load_config() -> void:
	_config_data.clear()
	for path: String in _loaded_files:
		_loaded_files[path] = false

	_load_json_to_config(CONFIG_PATH)
	_load_json_to_config(ITEMS_PATH)
	_load_json_to_config(EQUIPMENT_PATH)
	_load_json_to_config(ENEMIES_PATH)
	_load_json_to_config(SKILLS_PATH)
	_load_json_to_config(STATUS_EFFECTS_PATH)
	_load_json_to_config(ACCESSIBILITY_PATH)
	_load_json_to_config(GRID_VISUALS_PATH)
	_load_json_to_config(BIOMES_PATH)
	_load_json_to_config(SECRET_ROOM_CONDITIONS_PATH)
	_load_json_to_config(PROPS_PATH)
	_load_json_to_config(AMBIENT_NARRATOR_PATH)
	_load_json_to_config(REWARDS_PATH)
	_load_json_to_config(UNLOCKS_PATH)
	_load_json_to_config(ENCOUNTER_SCALER_PATH)
	_load_json_to_config(HUD_CONFIG_PATH)
	_load_json_to_config(UI_AUDIO_MANIFEST_PATH)
	_load_json_to_config(SETTINGS_HELP_PATH)
	_load_json_to_config(HAPTICS_CONFIG_PATH)
	_load_json_to_config(PROGRESSION_PATH)
	_load_json_to_config(XP_ECONOMY_PATH)
	_load_json_to_config(ELITE_MODIFIERS_PATH)
	_load_json_to_config(FEEDBACK_PATH)
	_load_json_to_config(HOTBAR_BINDINGS_PATH)
	_validate_grid_visuals()


func _load_json_to_config(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		var file_handle: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if file_handle:
			var file_text: String = file_handle.get_as_text()
			var parsed_json: Variant = JSON.parse_string(file_text)
			if parsed_json is Dictionary:
				_config_data.merge(parsed_json, true)
				_loaded_files[file_path] = true
				print("ConfigLoader: loaded config from %s" % file_path)
			else:
				push_warning("ConfigLoader: config file %s was not a valid JSON object." % file_path)
			file_handle.close()
	else:
		push_warning("ConfigLoader: config file not found at %s." % file_path)


## Get a gameplay constant. First checks config JSON, then falls back to DEFAULTS.
## Usage: ConfigLoader.getValue("AP_MAX") or ConfigLoader.getValue("combat", "D_BASE")
func getValue(section_or_key: String, key: String = "", fallback: Variant = null) -> Variant:
	if not key.is_empty():
		# Two-arg mode: section + key
		if _config_data.has(section_or_key) and _config_data[section_or_key] is Dictionary:
			var section: Dictionary = _config_data[section_or_key]
			if section.has(key):
				return section[key]
		# Try flattened default
		if DEFAULTS.has(key):
			return DEFAULTS[key]
		return fallback

	# One-arg mode: direct key lookup in flattened namespace
	if _config_data.has(section_or_key):
		return _config_data[section_or_key]
	# Scan sub-sections for key
	for section: Variant in _config_data.values():
		if section is Dictionary and section.has(section_or_key):
			return section[section_or_key]
	if DEFAULTS.has(section_or_key):
		return DEFAULTS[section_or_key]
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


func is_loaded() -> bool:
	for path: String in _loaded_files:
		if not _loaded_files[path]:
			return false
	return true


func _validate_grid_visuals() -> void:
	if not _config_data.has("highlights"):
		return

	var raw_highlights: Variant = _config_data["highlights"]
	if not raw_highlights is Dictionary:
		return
	var highlights_dict: Dictionary = raw_highlights as Dictionary

	for key: Variant in highlights_dict.keys():
		var style_ref: Variant = highlights_dict[key]
		if style_ref is Dictionary:
			var style: Dictionary = style_ref as Dictionary
			if style.has("pulse"):
				var pulse_ref: Variant = style["pulse"]
				if pulse_ref is Dictionary:
					var pulse: Dictionary = pulse_ref as Dictionary
					var min_a: float = float(pulse.get("min_alpha", 0.0))
					var max_a: float = float(pulse.get("max_alpha", 1.0))
					if min_a > max_a:
						push_error(
							(
								"ConfigLoader: Grid visual style '%s' has min_alpha (%.2f) > max_alpha (%.2f)!"
								% [str(key), min_a, max_a]
							)
						)

extends Node
class_name _EncounterScaler

## Autoload: EncounterScaler
## Calculates enemy stat scaling based on room depth and biome.

const SCALING_PATH := "res://config/encounter_scaler.json"

var _scaling_data: Dictionary = {}


func _ready() -> void:
	_load_scaling_data()


func _load_scaling_data() -> void:
	if FileAccess.file_exists(SCALING_PATH):
		var file: FileAccess = FileAccess.open(SCALING_PATH, FileAccess.READ)
		if file:
			var json: Variant = JSON.parse_string(file.get_as_text())
			if json is Dictionary and json.has("scaling_curves"):
				_scaling_data = json["scaling_curves"]
			file.close()


## Returns a multiplier for a specific stat based on room_index and biome_index.
func get_multiplier(stat_name: String, room_index: int, biome_index: int) -> float:
	var hp_mult: float = 1.0
	var off_mult: float = 1.0
	var def_mult: float = 1.0

	# 1. Base room scaling
	var room_key: String = "room_" + str(room_index)
	if _scaling_data.has(room_key):
		var curve: Dictionary = _scaling_data[room_key]
		hp_mult = float(curve.get("hp_multiplier", 1.0))
		off_mult = float(curve.get("off_multiplier", 1.0))
		def_mult = float(curve.get("def_multiplier", 1.0))

	# 2. Biome scaling (multiplicative)
	var biome_key: String = "biome_" + str(biome_index)
	if _scaling_data.has(biome_key):
		var curve: Dictionary = _scaling_data[biome_key]
		hp_mult *= float(curve.get("hp_multiplier", 1.0))
		off_mult *= float(curve.get("off_multiplier", 1.0))
		def_mult *= float(curve.get("def_multiplier", 1.0))

	match stat_name.to_lower():
		"hp", "hp_max":
			return hp_mult
		"off":
			return off_mult
		"def", "def_":
			return def_mult
	return 1.0

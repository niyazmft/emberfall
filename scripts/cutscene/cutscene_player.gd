extends Node
class_name _CutscenePlayer

## CutscenePlayer
## Manages narrative cutscenes defined in res://data/cutscenes.json.
## Cutscenes in Emberfall are narrative scene descriptions, often
## triggered at biome transitions or run start/end.

const DATA_PATH := "res://data/cutscenes.json"

var _cutscenes: Dictionary = {}


func _ready() -> void:
	_load_data()


func _load_data() -> void:
	if FileAccess.file_exists(DATA_PATH):
		var file := FileAccess.open(DATA_PATH, FileAccess.READ)
		if file:
			var json_text := file.get_as_text()
			var parsed: Variant = JSON.parse_string(json_text)
			if parsed is Dictionary and parsed.has("cutscenes"):
				_cutscenes = parsed["cutscenes"]
			else:
				push_warning("CutscenePlayer: Invalid JSON format in %s" % DATA_PATH)
		else:
			push_error("CutscenePlayer: Failed to open %s" % DATA_PATH)
	else:
		push_warning("CutscenePlayer: Data file missing at %s" % DATA_PATH)


## Play a cutscene by ID.
func play_cutscene(cutscene_id: String) -> void:
	if not _cutscenes.has(cutscene_id):
		push_warning("CutscenePlayer: Unknown cutscene ID: %s" % cutscene_id)
		return

	var cutscene: Dictionary = _cutscenes[cutscene_id]
	_print_debug("Playing cutscene: %s" % cutscene_id)

	# For now, it might just log the segments or emit signals.
	# Future implementation will hook into UI/Visuals.
	if cutscene.has("segments") and cutscene["segments"] is Array:
		for segment: Dictionary in cutscene["segments"]:
			_print_debug("Segment: %s" % segment.get("text", ""))


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("CutscenePlayer: %s" % msg)

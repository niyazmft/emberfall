extends Node
class_name _CutscenePlayer

## CutscenePlayer
## Manages narrative cutscenes defined in res://data/cutscenes.json.
## Cutscenes in Emberfall are narrative scene descriptions, often
## triggered at biome transitions or run start/end.

const DATA_PATH := "res://data/cutscenes.json"

signal cutscene_finished(cutsceneId: String)

var _cutscenes: Dictionary = {}


func _ready() -> void:
	_loadData()


func _loadData() -> void:
	if FileAccess.file_exists(DATA_PATH):
		var file := FileAccess.open(DATA_PATH, FileAccess.READ)
		if file:
			var jsonText := file.get_as_text()
			file.close()
			var parsed: Variant = JSON.parse_string(jsonText)
			if parsed is Dictionary and parsed.has("cutscenes"):
				_cutscenes = parsed["cutscenes"]
			else:
				push_warning("CutscenePlayer: Invalid JSON format in %s" % DATA_PATH)
		else:
			push_error("CutscenePlayer: Failed to open %s" % DATA_PATH)
	else:
		push_error("CutscenePlayer: Data file missing at %s" % DATA_PATH)


## Play a cutscene by ID.
func playCutscene(cutsceneId: String) -> void:
	if not _cutscenes.has(cutsceneId):
		push_warning("CutscenePlayer: Unknown cutscene ID: %s" % cutsceneId)
		return

	var cutscene: Dictionary = _cutscenes[cutsceneId]
	_printDebug("Playing cutscene: %s" % cutsceneId)

	var mgr: _CaptionManager = AutoloadHelper.caption_manager()
	if mgr == null:
		push_warning("CutscenePlayer: Cannot play cutscene because CaptionManager is nil.")
		return

	if cutscene.has("segments") and cutscene["segments"] is Array:
		var cumulativeOffset: float = 0.0
		for segment: Variant in cutscene["segments"]:
			if not segment is Dictionary:
				continue

			var segDict: Dictionary = segment as Dictionary
			var text: String = str(segDict.get("text", ""))
			var locKey: String = str(segDict.get("localization_key", ""))
			var duration: float = float(segDict.get("duration_sec", 4.0))

			mgr.schedule(
				text,
				_CaptionManager.Channel.DIALOGUE,
				cumulativeOffset,
				duration,
				_CaptionManager.CaptionCurve.LINEAR,
				locKey
			)

			cumulativeOffset += duration

		# Emit finished signal after the last segment's duration
		get_tree().create_timer(cumulativeOffset).timeout.connect(
			func() -> void: cutscene_finished.emit(cutsceneId)
		)


func _printDebug(msg: String) -> void:
	if OS.is_debug_build():
		print("CutscenePlayer: %s" % msg)

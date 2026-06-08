extends Node

## _UIAudioManager
## Autoload: UIAudioManager
## Manages UI sound effects triggered by button events (hover, click, cancel, etc.).
## Audio mappings are data-driven via ui_audio_manifest.json.

class_name _UIAudioManager

var _manifestData: Dictionary = {}
var _playerPool: Array[AudioStreamPlayer] = []
const _poolSize: int = 8


func _ready() -> void:
	_loadManifest()
	_setupPlayerPool()


func _loadManifest() -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl:
		# UIAudioManager depends on ConfigLoader being ready
		if not cl.isLoaded():
			await cl.ready

		# Since our manifest is nested under "ui_audio" in ui_audio_manifest.json:
		var uiAudio: Variant = cl.getValue("ui_audio")
		if uiAudio is Dictionary:
			_manifestData = uiAudio
	else:
		push_warning("UIAudioManager: ConfigLoader not found.")


func _setupPlayerPool() -> void:
	for i: int in range(_poolSize):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_playerPool.append(player)


## Plays a UI sound based on the event type defined in the manifest.
func playUiSound(eventType: String) -> void:
	if not _manifestData.has(eventType):
		return

	var data: Dictionary = _manifestData[eventType] as Dictionary
	var filePath: String = data.get("file_path", "")
	if filePath.is_empty() or not FileAccess.file_exists(filePath):
		return

	var stream: AudioStream = load(filePath) as AudioStream
	if not stream:
		return

	var player: AudioStreamPlayer = _getAvailablePlayer()
	if player:
		player.stream = stream
		player.volume_db = float(data.get("volume_db", 0.0))
		player.pitch_scale = float(data.get("pitch_scale", 1.0))
		player.play()


func _getAvailablePlayer() -> AudioStreamPlayer:
	if _playerPool.is_empty():
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_playerPool.append(player)
		return player

	for player: AudioStreamPlayer in _playerPool:
		if not player.playing:
			return player

	# If all players are busy, steal the first one
	return _playerPool[0]

extends Node

## _UIAudioManager
## Autoload: UIAudioManager
## Manages UI sound effects triggered by button events (hover, click, cancel, etc.).
## Audio mappings are data-driven via ui_audio_manifest.json.

class_name _UIAudioManager

var _manifest: Dictionary = {}
var _player_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8


func _ready() -> void:
	_load_manifest()
	_setup_player_pool()


func _load_manifest() -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl:
		# UIAudioManager depends on ConfigLoader being ready
		if not cl.isLoaded():
			await cl.ready

		# We don't have a direct "get manifest" in ConfigLoader that returns the whole thing easily
		# without knowing keys, but ConfigLoader merges everything into _configData.
		# Since our manifest is nested under "ui_audio" in ui_audio_manifest.json:
		var ui_audio: Variant = cl.getValue("ui_audio")
		if ui_audio is Dictionary:
			_manifest = ui_audio
	else:
		push_warning("UIAudioManager: ConfigLoader not found.")


func _setup_player_pool() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_player_pool.append(player)


## Plays a UI sound based on the event type defined in the manifest.
func play_ui_sound(event_type: String) -> void:
	if not _manifest.has(event_type):
		return

	var data: Dictionary = _manifest[event_type] as Dictionary
	var file_path: String = data.get("file_path", "")
	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		return

	var stream: AudioStream = load(file_path) as AudioStream
	if not stream:
		return

	var player := _get_available_player()
	if player:
		player.stream = stream
		player.volume_db = float(data.get("volume_db", 0.0))
		player.pitch_scale = float(data.get("pitch_scale", 1.0))
		player.play()


func _get_available_player() -> AudioStreamPlayer:
	for player in _player_pool:
		if not player.playing:
			return player
	# If all players are busy, steal the first one (simplistic)
	return _player_pool[0]

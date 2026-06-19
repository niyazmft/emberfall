class_name _AudioSFXManager
extends Node
## AudioSFXManager
## Plays transient combat sounds.

const MAX_PLAYERS = 8

var _players: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}


func _ready() -> void:
	# Initialize pool
	for i in range(MAX_PLAYERS):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)

	# Preload common sounds
	_load_sfx("move", "res://assets/audio/sfx/move.wav")
	_load_sfx("attack", "res://assets/audio/sfx/attack.wav")
	_load_sfx("hit", "res://assets/audio/sfx/hit.wav")
	_load_sfx("death", "res://assets/audio/sfx/death.wav")

	var eb := AutoloadHelper.event_bus()
	if eb:
		eb.sfx_requested.connect(play_sfx)


func _load_sfx(sfx_name: String, path: String) -> void:
	if ResourceLoader.exists(path):
		_sfx_cache[sfx_name] = load(path)


func play_sfx(sfx_name: String) -> void:
	if not _sfx_cache.has(sfx_name):
		return

	var stream: AudioStream = _sfx_cache[sfx_name]
	if not stream:
		return

	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return

	# If all busy, override the first one
	_players[0].stream = stream
	_players[0].play()

extends Node

## _SFXManager
## Autoload: SFXManager
## Manages SFX playback via pooled AudioStreamPlayer and AudioStreamPlayer2D nodes.

class_name _SFXManager

# ── Properties ────────────────────────────────────────────────────────────
var _pool_size: int = 12
var _player_pool: Array[AudioStreamPlayer] = []
var _player_2d_pool: Array[AudioStreamPlayer2D] = []

# Map of SFX IDs to file paths
var _sfx_map: Dictionary = {
	"hit": "res://assets/audio/sfx/hit.wav",
	"move": "res://assets/audio/sfx/move.wav",
	"attack": "res://assets/audio/sfx/attack.wav",
	"death": "res://assets/audio/sfx/death.wav",
}

# Cache for loaded AudioStream resources
var _cache: Dictionary = {}

# ── Lifecycle ────────────────────────────────────────────────────────────────


func _ready() -> void:
	_setup_pools()
	_preload_assets()


# ── Public API ─────────────────────────────────────────────────────────────


## Plays an SFX. If position is provided, uses AudioStreamPlayer2D.
## Otherwise uses AudioStreamPlayer.
func play_sfx(sfx_id: String, position: Vector2 = Vector2.INF) -> void:
	if not _sfx_map.has(sfx_id):
		push_warning("SFXManager: Unknown sfx_id '%s'" % sfx_id)
		return

	var stream: AudioStream = _get_stream(sfx_id)
	if not stream:
		return

	if position == Vector2.INF:
		_play_global(stream)
	else:
		_play_spatial(stream, position)


# ── Internal ────────────────────────────────────────────────────────────────


func _setup_pools() -> void:
	for i: int in range(_pool_size):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_player_pool.append(p)

		var p2d: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		p2d.bus = "SFX"
		add_child(p2d)
		_player_2d_pool.append(p2d)


func _preload_assets() -> void:
	for id: String in _sfx_map:
		_get_stream(id)


func _get_stream(sfx_id: String) -> AudioStream:
	if _cache.has(sfx_id):
		return _cache[sfx_id] as AudioStream

	var path: String = _sfx_map[sfx_id]
	if not FileAccess.file_exists(path):
		push_warning("SFXManager: File not found for '%s': %s" % [sfx_id, path])
		return null

	var stream: AudioStream = load(path) as AudioStream
	if stream:
		_cache[sfx_id] = stream
	return stream


func _play_global(stream: AudioStream) -> void:
	var player: AudioStreamPlayer = _get_available_player(_player_pool)
	if player:
		player.stream = stream
		player.play()


func _play_spatial(stream: AudioStream, pos: Vector2) -> void:
	var player: AudioStreamPlayer2D = _get_available_player(_player_2d_pool)
	if player:
		player.stream = stream
		player.global_position = pos
		player.play()


func _get_available_player(pool: Array) -> Variant:
	for p: Variant in pool:
		if not p.playing:
			return p
	# Steal the first one if all busy
	return pool[0]

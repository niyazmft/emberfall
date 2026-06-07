extends Node

## _SFXEmitter
## Manages a pool of AudioStreamPlayer and AudioStreamPlayer2D nodes for
## one-shot SFX playback.

class_name _SFXEmitter

# ── Constants ─────────────────────────────────────────────────────────────
const POOL_SIZE: int = 16

# ── Properties ────────────────────────────────────────────────────────────
var _pool: Array[AudioStreamPlayer] = []
var _pool_2d: Array[AudioStreamPlayer2D] = []
var _next_index: int = 0
var _next_index_2d: int = 0

var init_time_ms: int = 0

# ── Lifecycle ────────────────────────────────────────────────────────────────


func _ready() -> void:
	var startTime: int = Time.get_ticks_msec()
	_setup_pools()
	init_time_ms = Time.get_ticks_msec() - startTime


# ── Public API ─────────────────────────────────────────────────────────────


## Plays a non-spatial SFX using the next available player in the pool.
func play_sfx(stream: AudioStream, volume_linear: float = 1.0, pitch: float = 1.0) -> void:
	if not stream:
		return

	var player: AudioStreamPlayer = _pool[_next_index]
	player.stream = stream
	player.volume_db = linear_to_db(volume_linear)
	player.pitch_scale = pitch
	player.play()

	_next_index = (_next_index + 1) % POOL_SIZE


## Plays a spatial 2D SFX at the given global position.
func play_sfx_2d(
	stream: AudioStream, global_pos: Vector2, volume_linear: float = 1.0, pitch: float = 1.0
) -> void:
	if not stream:
		return

	var player: AudioStreamPlayer2D = _pool_2d[_next_index_2d]
	player.stream = stream
	player.global_position = global_pos
	player.volume_db = linear_to_db(volume_linear)
	player.pitch_scale = pitch
	player.play()

	_next_index_2d = (_next_index_2d + 1) % POOL_SIZE


# ── Internal ────────────────────────────────────────────────────────────────


func _setup_pools() -> void:
	for i: int in range(POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "AudioStreamPlayer_%d" % i
		p.bus = &"SFX"
		add_child(p)
		_pool.append(p)

		var p2d: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		p2d.name = "AudioStreamPlayer2D_%d" % i
		p2d.bus = &"SFX"
		add_child(p2d)
		_pool_2d.append(p2d)

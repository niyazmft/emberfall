class_name CameraShaker
extends Node

## Manages screen shake for a Camera2D using trauma/decay and Perlin noise.
## Based on "Trauma-based Shake" as popularized by Squirrel Eiserloh.

@export var decay: float = 0.8  # Trauma decay speed per second
@export var max_offset: Vector2 = Vector2(100, 75)  # Maximum hor/ver shake in pixels
@export var max_roll: float = 0.1  # Maximum rotation in radians
@export var trauma_power: float = 2.0  # Trauma is squared for more impact at high levels

var trauma: float = 0.0  # Current trauma level [0, 1]
var noise: FastNoiseLite = FastNoiseLite.new()
var _noise_y: float = 0.0  # Incrementing value for noise sampling

@onready var camera: Camera2D = get_parent() as Camera2D


func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN


func _process(delta: float) -> void:
	if not camera:
		return

	if trauma > 0:
		trauma = max(trauma - decay * delta, 0)
		_shake(delta)
	elif camera.offset != Vector2.ZERO or camera.rotation != 0:
		# Reset camera when shake ends
		camera.offset = Vector2.ZERO
		camera.rotation = 0


## Adds trauma to the camera, capped at 1.0.
func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)


func _shake(delta: float) -> void:
	var sm: Node = AutoloadHelper.settings_manager()
	var shakeMultiplier: float = 1.0
	if sm != null:
		var settings: Variant = sm.get("settings")
		if settings is Dictionary:
			var accessCfg: Dictionary = settings.get("accessibility", {}) as Dictionary
			shakeMultiplier = float(accessCfg.get("screen_shake", 1.0))

	if shakeMultiplier <= 0:
		camera.offset = Vector2.ZERO
		camera.rotation = 0
		return

	var amount: float = pow(trauma, trauma_power) * shakeMultiplier
	_noise_y += delta * 1000.0  # Speed of noise sampling

	camera.rotation = max_roll * amount * noise.get_noise_2d(noise.seed, _noise_y)
	camera.offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed * 2, _noise_y)
	camera.offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed * 3, _noise_y)

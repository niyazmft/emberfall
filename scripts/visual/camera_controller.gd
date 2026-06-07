class_name CameraController
extends Camera2D

## CameraController
## Handles smooth movement, data-driven screenshake, and target tracking.

var _target: Node2D
var _lerp_speed: float = 5.0
var _shake_amount: float = 0.0
var _shake_decay: float = 5.0
var _max_offset: float = 10.0
var _max_roll: float = 0.1

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_load_config()


func _load_config() -> void:
	var loader: _ConfigLoader = AutoloadHelper.config_loader()
	if loader:
		var camera_config: Dictionary = loader.getValue("camera", "", {})
		if not camera_config.is_empty():
			_lerp_speed = float(camera_config.get("LERP_SPEED", 5.0))
			_max_offset = float(camera_config.get("SHAKE_MAX_OFFSET", 10.0))
			_max_roll = float(camera_config.get("SHAKE_MAX_ROLL", 0.1))

		var feedback: Dictionary = loader.getValue("screen_shake", "", {})
		if feedback:
			_shake_decay = feedback.get("decay", 5.0)


func _process(delta: float) -> void:
	if _target:
		global_position = global_position.lerp(_target.global_position, _lerp_speed * delta)

	if _shake_amount > 0:
		_shake_amount = maxf(0.0, _shake_amount - _shake_decay * delta)
		_apply_shake()
	else:
		offset = Vector2.ZERO
		rotation = 0.0


func set_target(p_target: Node2D) -> void:
	_target = p_target


func add_shake(amount: float) -> void:
	_shake_amount = minf(_shake_amount + amount, 1.0)


func _apply_shake() -> void:
	var shake_sq: float = _shake_amount * _shake_amount
	offset.x = _max_offset * shake_sq * _rng.randf_range(-1.0, 1.0)
	offset.y = _max_offset * shake_sq * _rng.randf_range(-1.0, 1.0)
	rotation = _max_roll * shake_sq * _rng.randf_range(-1.0, 1.0)

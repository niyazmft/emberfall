class_name FloatingText
extends Label

## FloatingText
## Handles the visual animation and lifecycle of a floating numeric popup.

@export var travelDistance: float = 64.0
@export var duration: float = 1.0
@export var spread: float = 16.0


func _ready() -> void:
	# Randomize horizontal offset slightly (deterministic)
	position.x += DeterministicMath.randf_range(-spread, spread)

	_animate()


func setup(value: int) -> void:
	if value > 0:
		text = "+" + str(value)
		modulate = Color.GREEN
	else:
		text = str(value)  # value is already negative for damage
		modulate = Color.RED

	# Basic style - in a real project we'd use a Theme or LabelSettings
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _animate() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Move upward
	(
		tween
		. tween_property(self, "position:y", position.y - travelDistance, duration)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)

	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)

	tween.set_parallel(false)
	tween.tween_callback(queue_free)

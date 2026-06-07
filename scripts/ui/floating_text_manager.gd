class_name FloatingTextManager
extends Control

## FloatingTextManager
## Orchestrates the spawning of numeric popups based on world-space signals.

const floatingTextScene: PackedScene = preload("res://scenes/ui/floating_text.tscn")


func _ready() -> void:
	# Ensure it covers the overlay but doesn't block input
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Spawns a floating text at the given world position.
func spawnText(value: int, globalPos: Vector2) -> void:
	if value == 0:
		return

	var floatingText: FloatingText = floatingTextScene.instantiate() as FloatingText

	# Convert world position to screen position (CanvasLayer space)
	# get_viewport().get_canvas_transform() accounts for Camera2D
	var screenPos: Vector2 = get_viewport().get_canvas_transform() * globalPos

	floatingText.position = screenPos
	floatingText.setup(value)

	# add_child() triggers _ready() which starts the animation.
	# We call it AFTER setup() and setting position to ensure the animation
	# starts from the correct location.
	add_child(floatingText)

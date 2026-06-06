class_name FloatingTextManager
extends Control

## FloatingTextManager
## Orchestrates the spawning of numeric popups based on world-space signals.

const FLOATING_TEXT_SCENE: PackedScene = preload("res://scenes/ui/floating_text.tscn")


func _ready() -> void:
	# Ensure it covers the overlay but doesn't block input
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Spawns a floating text at the given world position.
func spawn_text(value: int, global_pos: Vector2) -> void:
	if value == 0:
		return

	var floating_text: FloatingText = FLOATING_TEXT_SCENE.instantiate() as FloatingText

	# Convert world position to screen position (CanvasLayer space)
	# get_viewport().get_canvas_transform() accounts for Camera2D
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * global_pos

	floating_text.position = screen_pos
	floating_text.setup(value)

	# add_child() triggers _ready() which starts the animation.
	# We call it AFTER setup() and setting position to ensure the animation
	# starts from the correct location.
	add_child(floating_text)

class_name _TransitionLayer
extends CanvasLayer
## A global transition layer to handle screen fades.

signal fade_completed

@onready var color_rect: ColorRect = ColorRect.new()


func _ready() -> void:
	layer = 100  # Ensure it is on top of everything

	color_rect.color = Color.BLACK
	color_rect.modulate.a = 0.0
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)


func fade_out(duration: float = 0.5) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks during transition
	if OS.has_feature("headless"):
		color_rect.modulate.a = 1.0
		fade_completed.emit()
		return

	var tween: Tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished
	fade_completed.emit()


func fade_in(duration: float = 0.5) -> void:
	if OS.has_feature("headless"):
		color_rect.modulate.a = 0.0
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade_completed.emit()
		return

	var tween: Tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	await tween.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_completed.emit()

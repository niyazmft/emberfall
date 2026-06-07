class_name TransitionLayer
extends CanvasLayer

## TransitionLayer
## Handles screen transitions (fade-to-black) and input blocking.

@onready var _color_rect: ColorRect = $ColorRect


func _ready() -> void:
	_color_rect.color.a = 0.0
	_color_rect.visible = false
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var runMgr := AutoloadHelper.run_manager()
	if runMgr and runMgr.has_method("set_transition_layer"):
		runMgr.call("set_transition_layer", self)


## Fades the screen to black (transitioning OUT).
func fade_out(duration: float) -> Signal:
	_color_rect.visible = true
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var fadeTween := create_tween()
	fadeTween.tween_property(_color_rect, "color:a", 1.0, duration)
	return fadeTween.finished


## Fades from black to transparent (transitioning IN).
func fade_in(duration: float) -> Signal:
	_color_rect.visible = true
	_color_rect.color.a = 1.0
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var fadeTween := create_tween()
	fadeTween.tween_property(_color_rect, "color:a", 0.0, duration)
	fadeTween.finished.connect(_on_fade_in_finished)
	return fadeTween.finished


func _on_fade_in_finished() -> void:
	_color_rect.visible = false
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

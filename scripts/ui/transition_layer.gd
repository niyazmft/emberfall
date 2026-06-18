class_name TransitionLayer
extends CanvasLayer

## TransitionLayer
## Manages full-screen fade transitions between scenes or states.

@export var start_opaque: bool = true

var _default_duration: float = 0.5

@onready var _overlay: ColorRect = $ColorRect


func _ready() -> void:
	layer = 200

	if start_opaque:
		_overlay.color.a = 1.0
		_overlay.visible = true
		_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		_overlay.color.a = 0.0
		_overlay.visible = false
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var config: _ConfigLoader = AutoloadHelper.config_loader()
	if config:
		_default_duration = float(
			config.getValue("ui", "transitions", {}).get("transition_duration", 0.5)
		)


## Fades the overlay to black.
func fade_out(duration: float = -1.0) -> Signal:
	if duration < 0:
		duration = _default_duration

	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, duration)
	return tween.finished


## Fades the overlay to transparent.
func fade_in(duration: float = -1.0) -> Signal:
	if duration < 0:
		duration = _default_duration

	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, duration)
	tween.finished.connect(_on_fade_in_finished)
	return tween.finished


func _on_fade_in_finished() -> void:
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

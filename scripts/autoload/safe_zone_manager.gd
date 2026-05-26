extends Node
class_name _SafeZoneManager
## SafeZoneManager (DON-196)
## Manages safe area margins and responsive aspect-ratio breakpoints.

signal safe_area_changed(rect: Rect2)
signal aspect_ratio_changed(mode: AspectMode)

enum AspectMode { SHRINK, DEFAULT, EXPAND }  ## 4:3 (e.g. iPad)  ## 16:9 (Standard)  ## 18:9+ (Modern phones with notches)

const DESIGN_WIDTH: float = 320.0
const BREAKPOINT_SHRINK: float = 1.6
const BREAKPOINT_EXPAND: float = 1.9

var current_safe_area: Rect2
var current_aspect_mode: AspectMode = AspectMode.DEFAULT


func _ready() -> void:
	get_tree().root.size_changed.connect(_on_size_changed)
	_update_metrics()


func _on_size_changed() -> void:
	_update_metrics()


func _update_metrics() -> void:
	var viewport_size: Vector2 = Vector2(get_viewport().get_visible_rect().size)
	if viewport_size.y == 0:
		return

	var aspect: float = viewport_size.x / viewport_size.y

	var new_mode: AspectMode = AspectMode.DEFAULT
	if aspect < BREAKPOINT_SHRINK:
		new_mode = AspectMode.SHRINK
	elif aspect > BREAKPOINT_EXPAND:
		new_mode = AspectMode.EXPAND

	var aspect_changed: bool = new_mode != current_aspect_mode
	if aspect_changed:
		current_aspect_mode = new_mode

	var new_safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var safe_changed: bool = new_safe_area != Rect2i(current_safe_area)

	if safe_changed:
		current_safe_area = Rect2(new_safe_area)

	if aspect_changed:
		aspect_ratio_changed.emit(current_aspect_mode)
	if safe_changed:
		safe_area_changed.emit(current_safe_area)


## Returns the safe margins in design pixels.
func get_safe_margins() -> Dictionary:
	var safe_rect := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()

	# Coordinate conversion: screen to design pixels
	var viewport_size := Vector2(get_viewport().get_visible_rect().size)
	var window_size := Vector2(DisplayServer.window_get_size())
	var scale := Vector2.ONE
	if window_size.x > 0 and window_size.y > 0:
		scale = viewport_size / window_size

	if safe_rect.size == Vector2i.ZERO:
		return {"left": 0, "top": 0, "right": 0, "bottom": 0}

	return {
		"left": int(safe_rect.position.x * scale.x),
		"top": int(safe_rect.position.y * scale.y),
		"right": int((screen_size.x - safe_rect.end.x) * scale.x),
		"bottom": int((screen_size.y - safe_rect.end.y) * scale.y)
	}


## AC: Notch corner shift for top-left anchored portraits
## Returns a Vector2 offset in design pixels.
func get_notch_offset() -> Vector2:
	var margins := get_safe_margins()
	return Vector2(margins.left, margins.top)


func get_design_width() -> float:
	return DESIGN_WIDTH


func is_portrait() -> bool:
	var size := get_viewport().get_visible_rect().size
	return size.y > size.x

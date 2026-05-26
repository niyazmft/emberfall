extends Node
## SafeZoneManager (DON-196)
## Manages safe area margins and responsive aspect-ratio breakpoints.

signal safe_area_changed(rect: Rect2)
signal aspect_ratio_changed(mode: AspectMode)

enum AspectMode {
	SHRINK,  ## 4:3 (e.g. iPad)
	DEFAULT, ## 16:9 (Standard)
	EXPAND   ## 18:9+ (Modern phones with notches)
}

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
	var viewport_size := Vector2(get_viewport().get_visible_rect().size)
	if viewport_size.y == 0: return

	var aspect := viewport_size.x / viewport_size.y

	var new_mode := AspectMode.DEFAULT
	if aspect < BREAKPOINT_SHRINK:
		new_mode = AspectMode.SHRINK
	elif aspect > BREAKPOINT_EXPAND:
		new_mode = AspectMode.EXPAND

	var aspect_changed := (new_mode != current_aspect_mode)
	if aspect_changed:
		current_aspect_mode = new_mode

	var new_safe_area := DisplayServer.get_display_safe_area()
	var safe_changed := (new_safe_area != current_safe_area)

	if safe_changed:
		current_safe_area = new_safe_area

	if aspect_changed:
		aspect_ratio_changed.emit(current_aspect_mode)
	if safe_changed:
		safe_area_changed.emit(current_safe_area)

## Returns the safe margins in pixels relative to the viewport size.
func get_safe_margins() -> Dictionary:
	var safe_rect := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()

	# If safe_rect is zero (e.g. some desktop platforms), use the full screen
	if safe_rect.size == Vector2i.ZERO:
		return {"left": 0, "top": 0, "right": 0, "bottom": 0}

	return {
		"left": safe_rect.position.x,
		"top": safe_rect.position.y,
		"right": screen_size.x - (safe_rect.position.x + safe_rect.size.x),
		"bottom": screen_size.y - (safe_rect.position.y + safe_rect.size.y)
	}

## AC: Notch corner shift for top-left anchored portraits
## Returns a Vector2 offset to apply to top-left anchored elements.
func get_notch_offset() -> Vector2:
	var margins := get_safe_margins()
	# If we have a top or left margin, it's likely a notch or system bar
	return Vector2(margins.left, margins.top)

func get_design_width() -> float:
	return DESIGN_WIDTH

func is_portrait() -> bool:
	var size := get_viewport().get_visible_rect().size
	return size.y > size.x

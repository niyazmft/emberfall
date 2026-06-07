extends Node
class_name _SafeZoneManager

## SafeZoneManager (DON-196)
## Desktop no-op — safe zones and notches are mobile-only concerns.

signal safe_area_changed(rect: Rect2)
signal aspect_ratio_changed(mode: AspectMode)

enum AspectMode { SHRINK, DEFAULT, EXPAND }

const DESIGN_WIDTH: float = 320.0
const BREAKPOINT_SHRINK: float = 1.6
const BREAKPOINT_EXPAND: float = 1.9

var current_safe_area: Rect2
var current_aspect_mode: AspectMode = AspectMode.DEFAULT


func _ready() -> void:
	# no-op: do not connect size_changed; desktop windows have no notches
	pass


func _on_size_changed() -> void:
	pass


func _update_metrics() -> void:
	pass


## Returns the safe margins in design pixels.
func get_safe_margins() -> Dictionary:
	return {"left": 0, "top": 0, "right": 0, "bottom": 0}


## AC: Notch corner shift for top-left anchored portraits
## Returns a Vector2 offset in design pixels.
func get_notch_offset() -> Vector2:
	return Vector2.ZERO


func get_design_width() -> float:
	return DESIGN_WIDTH


func is_portrait() -> bool:
	return false

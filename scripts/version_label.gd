extends Label
## VersionLabel (DON-31/36)
## Displays the current build version.


func _ready() -> void:
	text = str(ProjectSettings.get_setting("application/config/version", "0.0.0-dev"))
	_apply_notch_offset()
	if not SafeZoneManager.safe_area_changed.is_connected(_on_safe_area_changed):
		SafeZoneManager.safe_area_changed.connect(_on_safe_area_changed)


func _exit_tree() -> void:
	if SafeZoneManager.safe_area_changed.is_connected(_on_safe_area_changed):
		SafeZoneManager.safe_area_changed.disconnect(_on_safe_area_changed)


func _on_safe_area_changed(_r: Rect2) -> void:
	_apply_notch_offset()


func _apply_notch_offset() -> void:
	var offset: Vector2 = SafeZoneManager.get_notch_offset()
	# Apply offset to ensure it doesn't draw in unsafe area
	position = offset

extends Label
## VersionLabel (DON-31/36)
## Displays the current build version.

func _ready() -> void:
	text = "v0.1.0-sprint1"
	_apply_notch_offset()
	SafeZoneManager.safe_area_changed.connect(func(_r): _apply_notch_offset())

func _apply_notch_offset() -> void:
	var offset := SafeZoneManager.get_notch_offset()
	# Apply offset to ensure it doesn't draw in unsafe area
	position = offset

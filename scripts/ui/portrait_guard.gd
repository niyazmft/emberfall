extends Control
## PortraitGuard (DON-196)
## Displays a warning when the device is in portrait orientation.

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_size_changed)
	_on_size_changed()

func _on_size_changed() -> void:
	if SafeZoneManager.is_portrait():
		show()
	else:
		hide()

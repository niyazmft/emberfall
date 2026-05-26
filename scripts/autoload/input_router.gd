extends Node

## InputRouter
## Detects device type and emits signal when it changes.
## Reference: DON-197

class_name _InputRouter

signal device_changed(device_type: String)

enum DeviceType { KEYBOARD_MOUSE, GAMEPAD }

var current_device: DeviceType = DeviceType.KEYBOARD_MOUSE


func _input(event: InputEvent) -> void:
	var new_device: DeviceType = current_device

	if event is InputEventKey or event is InputEventMouseButton:
		new_device = DeviceType.KEYBOARD_MOUSE
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		new_device = DeviceType.GAMEPAD

	if new_device != current_device:
		current_device = new_device
		var type_str: String = (
			"keyboard_mouse" if current_device == DeviceType.KEYBOARD_MOUSE else "gamepad"
		)
		device_changed.emit(type_str)

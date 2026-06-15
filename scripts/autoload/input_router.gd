extends Node
class_name _InputRouter

## Autoload: InputRouter
## Detects input device changes and emits signals for UI hint switching.

enum InputDevice {
	KEYBOARD_MOUSE,
	GAMEPAD,
}

signal device_changed(device: InputDevice)

var current_device: InputDevice = InputDevice.KEYBOARD_MOUSE


func _input(event: InputEvent) -> void:
	var new_device: InputDevice = current_device

	if event is InputEventKey or event is InputEventMouseButton:
		new_device = InputDevice.KEYBOARD_MOUSE
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		# Filter out small stick drift
		if event is InputEventJoypadMotion:
			var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
			if DeterministicMath.absf(motion.axis_value) < 0.3:
				return
		new_device = InputDevice.GAMEPAD

	if new_device != current_device:
		current_device = new_device
		device_changed.emit(current_device)
		_print_debug(
			(
				"Input device changed to: %s"
				% ("gamepad" if current_device == InputDevice.GAMEPAD else "keyboard_mouse")
			)
		)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("InputRouter: %s" % msg)

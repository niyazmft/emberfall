extends Node

## _HapticsManager
## Autoload: HapticsManager
## Manages haptic feedback intensity presets per event type.
## Configuration is data-driven via haptics_config.json.

class_name _HapticsManager

var _configData: Dictionary = {}


func _ready() -> void:
	_loadConfig()


func _loadConfig() -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl:
		if not cl.isLoaded():
			await cl.ready

		# For haptics, we have multiple presets nested under "haptics"
		var haptics: Variant = cl.getValue("haptics")
		if haptics is Dictionary:
			_configData = haptics
	else:
		push_warning("HapticsManager: ConfigLoader not found.")


## Triggers haptic feedback for the given event type.
func triggerHaptic(eventType: String) -> void:
	if not _configData.has(eventType):
		return

	var data: Dictionary = _configData[eventType] as Dictionary
	var intensity: float = float(data.get("intensity", 0.5))
	var duration: float = float(data.get("duration", 0.1))

	# Godot's Input.vibrate_handheld is primarily for mobile (Android/iOS).
	# For controllers, one would typically use Input.start_joy_vibration.

	if OS.has_feature("mobile"):
		Input.vibrate_handheld(int(duration * 1000))

	# For controllers
	var joypads: Array[int] = Input.get_connected_joypads()
	for deviceId: int in joypads:
		Input.start_joy_vibration(deviceId, intensity * 0.5, intensity, duration)

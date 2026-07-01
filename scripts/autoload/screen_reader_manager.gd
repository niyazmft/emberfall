extends Node
class_name _ScreenReaderManager

## Autoload: ScreenReaderManager
## Provides text-to-speech (TTS) support for accessibility.
## Hooks into entity state changes and UI focus events to narrate game state.

var _enabled: bool = false
var _available: bool = false


func _ready() -> void:
	_available = (
		DisplayServer.has_method("tts_is_speaking") and DisplayServer.has_method("tts_speak")
	)
	if not _available:
		push_warning("ScreenReaderManager: TTS not available on this platform.")
		return

	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb != null and not eb.entity_state_changed.is_connected(_on_entity_state_changed):
		eb.entity_state_changed.connect(_on_entity_state_changed)

	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.gui_focus_changed.is_connected(_on_focus_changed):
		viewport.gui_focus_changed.connect(_on_focus_changed)


func _exit_tree() -> void:
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb != null and eb.entity_state_changed.is_connected(_on_entity_state_changed):
		eb.entity_state_changed.disconnect(_on_entity_state_changed)

	var viewport: Viewport = get_viewport()
	if viewport != null and viewport.gui_focus_changed.is_connected(_on_focus_changed):
		viewport.gui_focus_changed.disconnect(_on_focus_changed)


func enable() -> void:
	_enabled = true
	if _available:
		speak("Screen reader enabled.")


func disable() -> void:
	if _available and _enabled:
		DisplayServer.tts_stop()
	_enabled = false


func speak(text: String) -> void:
	if not _enabled or not _available:
		return
	DisplayServer.tts_speak(text, "", 50, 1.0, 1.0, 0)


func is_enabled() -> bool:
	return _enabled


func is_available() -> bool:
	return _available


func _on_entity_state_changed(entity: Entity, old_state: int, new_state: int) -> void:
	if not _enabled:
		return
	var entity_name: String = entity.entity_name if entity != null else "Unknown"
	var msg: String = "%s changed state from %d to %d." % [entity_name, old_state, new_state]
	speak(msg)


func _on_focus_changed(control: Control) -> void:
	if not _enabled:
		return
	if control == null or not is_instance_valid(control):
		return
	var description: String = _get_control_description(control)
	if not description.is_empty():
		speak(description)


func _get_control_description(control: Control) -> String:
	if control is Button:
		var btn: Button = control as Button
		if not btn.text.is_empty():
			return btn.text
	elif control is CheckBox:
		var cb: CheckBox = control as CheckBox
		var state: String = "checked" if cb.button_pressed else "unchecked"
		if not cb.text.is_empty():
			return "%s, %s" % [cb.text, state]
		return "Checkbox, %s" % state
	elif control is Label:
		var lbl: Label = control as Label
		if not lbl.text.is_empty():
			return lbl.text
	elif control is HSlider:
		var slider: HSlider = control as HSlider
		return "Slider, value %.0f" % slider.value
	elif control is OptionButton:
		var opt: OptionButton = control as OptionButton
		if opt.selected >= 0:
			return "Dropdown, %s" % opt.get_item_text(opt.selected)
		return "Dropdown"
	return control.name

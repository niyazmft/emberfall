extends Control

## RemapPanel
## UI panel for rebinding keyboard, mouse, and gamepad controls.

@onready var action_list: VBoxContainer = $VBoxContainer/ScrollContainer/ActionList
@onready var conflict_toast: Label = $ConflictToast

var remapping_action: String = ""
var remapping_button: Button = null
var _conflict_timer: SceneTreeTimer


func _ready() -> void:
	create_action_list()
	if InputRouter.has_signal("device_changed"):
		InputRouter.device_changed.connect(_on_device_changed)

	# Focus the first item for keyboard/gamepad accessibility when the list is populated
	call_deferred("_focus_first_item")


func _exit_tree() -> void:
	if (
		InputRouter.has_signal("device_changed")
		and InputRouter.device_changed.is_connected(_on_device_changed)
	):
		InputRouter.device_changed.disconnect(_on_device_changed)

	if _conflict_timer and _conflict_timer.timeout.is_connected(conflict_toast.hide):
		_conflict_timer.timeout.disconnect(conflict_toast.hide)


func _focus_first_item() -> void:
	if not action_list:
		return
	var active_btn: Button = null
	for child: Node in action_list.get_children():
		if not child.is_queued_for_deletion() and child.get_child_count() > 1:
			active_btn = child.get_child(1) as Button
			break
	if active_btn:
		active_btn.grab_focus.call_deferred()


func create_action_list() -> void:
	for child: Node in action_list.get_children():
		action_list.remove_child(child)
		child.queue_free()

	var actions: Array[StringName] = InputMap.get_actions()
	for action: StringName in actions:
		if action.begins_with("ui_"):
			continue

		var h_box: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = String(action).capitalize()
		label.custom_minimum_size.x = 200
		h_box.add_child(label)

		var bind_button: Button = Button.new()
		bind_button.text = get_action_text(action)
		bind_button.icon = get_action_icon(action)
		bind_button.pressed.connect(_on_remap_button_pressed.bind(action, bind_button))
		h_box.add_child(bind_button)

		action_list.add_child(h_box)


func get_action_text(action: StringName) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if events.is_empty():
		return "None"

	var current_device: int = int(InputRouter.current_device)

	for event: InputEvent in events:
		if current_device == 0:  # KEYBOARD_MOUSE
			if event is InputEventKey or event is InputEventMouseButton:
				return event.as_text()
		else:  # GAMEPAD
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				return event.as_text()

	return events[0].as_text()


func get_action_icon(action: StringName) -> Texture2D:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if events.is_empty():
		return null

	var current_device: int = int(InputRouter.current_device)

	for event: InputEvent in events:
		if current_device == 0:  # KEYBOARD_MOUSE
			if event is InputEventKey or event is InputEventMouseButton:
				return _find_icon_for_event(event)
		else:  # GAMEPAD
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				return _find_icon_for_event(event)

	return _find_icon_for_event(events[0])


func _find_icon_for_event(event: InputEvent) -> Texture2D:
	var path: String = "res://assets/ui/icons/"
	if event is InputEventKey:
		path += "keys/" + String(event.as_text()).to_lower() + ".png"
	elif event is InputEventMouseButton:
		path += "mouse/btn_" + str(event.button_index) + ".png"
	elif event is InputEventJoypadButton:
		path += "gamepad/btn_" + str(event.button_index) + ".png"
	elif event is InputEventJoypadMotion:
		path += "gamepad/axis_" + str(event.axis) + ".png"

	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _on_remap_button_pressed(action: StringName, button: Button) -> void:
	remapping_action = action
	remapping_button = button
	button.text = "Press any key..."
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if remapping_action == "":
		set_process_unhandled_input(false)
		return

	# Support keys, mouse buttons, joy buttons, and joy motion (triggers/sticks)
	var is_valid_input: bool = (
		event is InputEventKey
		or event is InputEventMouseButton
		or event is InputEventJoypadButton
		or (event is InputEventJoypadMotion and abs(event.axis_value) > 0.5)
	)

	if is_valid_input:
		if event is InputEventMouseMotion:
			return

		get_viewport().set_input_as_handled()
		remap_action_to(remapping_action, event)
		remapping_action = ""
		remapping_button = null
		set_process_unhandled_input(false)


func remap_action_to(action: StringName, event: InputEvent) -> void:
	var conflict: StringName = find_conflict(event, action)
	if conflict != &"":
		show_conflict_warning(conflict)

	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for old_event: InputEvent in events:
		if is_same_device_type(old_event, event):
			InputMap.action_erase_event(action, old_event)

	InputMap.action_add_event(action, event)
	# SettingsManager will handle persistence on back_pressed or apply
	create_action_list()

	# Refocus the button that was just remapped
	call_deferred("_focus_action_button", action)


func _focus_action_button(action: StringName) -> void:
	if not action_list:
		return
	for child: Node in action_list.get_children():
		if (
			not child.is_queued_for_deletion()
			and child is HBoxContainer
			and child.get_child_count() > 1
		):
			var label: Label = child.get_child(0) as Label
			if label and label.text == String(action).capitalize():
				var btn: Button = child.get_child(1) as Button
				if btn:
					btn.grab_focus.call_deferred()
				break


func is_same_device_type(e1: InputEvent, e2: InputEvent) -> bool:
	var is_kbm1: bool = e1 is InputEventKey or e1 is InputEventMouseButton
	var is_kbm2: bool = e2 is InputEventKey or e2 is InputEventMouseButton
	return is_kbm1 == is_kbm2


func find_conflict(event: InputEvent, current_action: StringName) -> StringName:
	for action: StringName in InputMap.get_actions():
		if action == current_action:
			continue
		for a_event: InputEvent in InputMap.action_get_events(action):
			if a_event.is_match(event):
				return action
	return &""


func show_conflict_warning(other_action: StringName) -> void:
	if conflict_toast:
		var msg: String = tr("input.prompt_conflict") % String(other_action).capitalize()
		if msg == "input.prompt_conflict":
			msg = "Conflict with " + String(other_action).capitalize()
		conflict_toast.text = msg
		conflict_toast.show()
		_conflict_timer = get_tree().create_timer(2.0)
		_conflict_timer.timeout.connect(conflict_toast.hide)


func _on_device_changed(_device: _InputRouter.InputDevice) -> void:
	create_action_list()


func refresh() -> void:
	create_action_list()

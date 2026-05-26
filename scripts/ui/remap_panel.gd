extends Control

## RemapPanel
## UI panel for rebinding keyboard, mouse, and gamepad controls.
## Reference: DON-197

const REMAP_SAVE_PATH: String = "user://remap.save"

@onready var action_list: VBoxContainer = $VBoxContainer/ScrollContainer/ActionList
@onready var conflict_toast: Label = $ConflictToast

var remapping_action: String = ""
var remapping_button: Button = null


func _ready() -> void:
	load_bindings()
	create_action_list()
	var router: Node = get_node_or_null("/root/InputRouter")
	if router and router.has_signal("device_changed"):
		router.connect("device_changed", _on_device_changed)

	# Focus the first item for keyboard/gamepad accessibility when the list is populated
	call_deferred("_focus_first_item")


func _focus_first_item() -> void:
	if not action_list:
		return
	if action_list.get_child_count() > 0:
		var first_hbox: Node = action_list.get_child(0)
		if first_hbox.get_child_count() > 1 and first_hbox.get_child(1) is Button:
			(first_hbox.get_child(1) as Button).grab_focus()


func create_action_list() -> void:
	for child: Node in action_list.get_children():
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

	var current_device: int = 0
	var router: Node = get_node_or_null("/root/InputRouter")
	if router:
		current_device = int(router.get("current_device"))

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

	var current_device: int = 0
	var router: Node = get_node_or_null("/root/InputRouter")
	if router:
		current_device = int(router.get("current_device"))

	for event: InputEvent in events:
		if current_device == 0:  # KEYBOARD_MOUSE
			if event is InputEventKey or event is InputEventMouseButton:
				return _find_icon_for_event(event)
		else:  # GAMEPAD
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				return _find_icon_for_event(event)

	return _find_icon_for_event(events[0])


func _find_icon_for_event(event: InputEvent) -> Texture2D:
	# Icons would be loaded from res://assets/ui/icons/
	# Since assets are missing in this environment, we return null.
	# The system is icon-ready once assets are added.
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
	for old_event in events:
		if is_same_device_type(old_event, event):
			InputMap.action_erase_event(action, old_event)

	InputMap.action_add_event(action, event)
	save_bindings()
	create_action_list()

	# Refocus the button that was just remapped
	call_deferred("_focus_action_button", action)


func _focus_action_button(action: StringName) -> void:
	if not action_list:
		return
	for child: Node in action_list.get_children():
		if child is HBoxContainer and child.get_child_count() > 1:
			var label: Label = child.get_child(0) as Label
			if label and label.text == String(action).capitalize():
				var btn: Button = child.get_child(1) as Button
				if btn:
					btn.grab_focus()
				break


func is_same_device_type(e1: InputEvent, e2: InputEvent) -> bool:
	var is_kbm1: bool = e1 is InputEventKey or e1 is InputEventMouseButton
	var is_kbm2: bool = e2 is InputEventKey or e2 is InputEventMouseButton
	return is_kbm1 == is_kbm2


func find_conflict(event: InputEvent, current_action: StringName) -> StringName:
	for action in InputMap.get_actions():
		if action == current_action:
			continue
		for a_event in InputMap.action_get_events(action):
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
		var timer: SceneTreeTimer = get_tree().create_timer(2.0)
		timer.timeout.connect(conflict_toast.hide)


func _on_device_changed(_device_type: String) -> void:
	create_action_list()
	call_deferred("_focus_first_item")


func save_bindings() -> void:
	var save_data: Dictionary = {}
	for action: StringName in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		var serialized_events: Array = []
		for event: InputEvent in events:
			serialized_events.append(inst_to_dict(event))
		save_data[action] = serialized_events

	var file: FileAccess = FileAccess.open(REMAP_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()


func load_bindings() -> void:
	if not FileAccess.file_exists(REMAP_SAVE_PATH):
		return

	var file: FileAccess = FileAccess.open(REMAP_SAVE_PATH, FileAccess.READ)
	if file:
		var save_data: Variant = file.get_var()
		file.close()

		if save_data is Dictionary:
			var sd: Dictionary = save_data as Dictionary
			for action: StringName in sd.keys():
				if InputMap.has_action(action):
					InputMap.action_erase_events(action)
					var event_list: Array = sd[action] as Array
					for event_dict: Dictionary in event_list:
						var event: InputEvent = dict_to_inst(event_dict) as InputEvent
						InputMap.action_add_event(action, event)


func _on_reset_pressed() -> void:
	InputMap.load_from_project_settings()
	save_bindings()
	create_action_list()
	call_deferred("_focus_first_item")

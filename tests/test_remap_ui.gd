extends SceneTree


func _initialize() -> void:
	test_remap_logic()
	quit()


func test_remap_logic() -> void:
	print("Running Remap Logic Tests...")

	var script: GDScript = load("res://scripts/ui/remap_panel.gd") as GDScript
	var remap_panel: Node = script.new()

	# Test action list creation
	if not InputMap.has_action("test_action"):
		InputMap.add_action("test_action")
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_F
	InputMap.action_add_event("test_action", key)

	var router: Node = Node.new()
	router.name = "InputRouter"
	router.set("current_device", 0)
	root.add_child(router)

	var panel_vbox: VBoxContainer = VBoxContainer.new()
	panel_vbox.name = "VBoxContainer"
	var panel_scroll: ScrollContainer = ScrollContainer.new()
	panel_scroll.name = "ScrollContainer"
	var action_list: VBoxContainer = VBoxContainer.new()
	action_list.name = "ActionList"
	panel_scroll.add_child(action_list)
	panel_vbox.add_child(panel_scroll)
	remap_panel.add_child(panel_vbox)

	var toast: Label = Label.new()
	toast.name = "ConflictToast"
	remap_panel.add_child(toast)

	root.add_child(remap_panel)

	remap_panel.call("_ready")
	print("Action list created")

	# Test conflict detection
	var conflict: StringName = remap_panel.call("find_conflict", key, "other_action") as StringName
	if conflict == "test_action":
		print("Conflict detection passed")
	else:
		print("Conflict detection failed: ", conflict)

	# Test remap
	var new_key: InputEventKey = InputEventKey.new()
	new_key.keycode = KEY_G
	remap_panel.call("remap_action_to", "test_action", new_key)

	var events: Array[InputEvent] = InputMap.action_get_events("test_action")
	var found: bool = false
	for e: InputEvent in events:
		if e is InputEventKey and e.keycode == KEY_G:
			found = true
			break

	if found:
		print("Remap logic passed")
	else:
		print("Remap logic failed")

	# Test Reset
	remap_panel.call("_on_reset_pressed")
	print("Reset to defaults called")

	print("Remap Logic Tests Completed")
	remap_panel.queue_free()

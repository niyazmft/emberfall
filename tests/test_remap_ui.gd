extends SceneTree

func _init():
	test_remap_logic()
	quit()

func test_remap_logic():
	print("Running Remap Logic Tests...")

	var remap_panel = load("res://scenes/ui/remap_panel.tscn").instantiate()

	# Test action list creation
	InputMap.add_action("test_action")
	var key = InputEventKey.new()
	key.keycode = KEY_F
	InputMap.action_add_event("test_action", key)

	remap_panel._ready()
	print("Action list created")

	# Test conflict detection
	var conflict = remap_panel.find_conflict(key, "other_action")
	if conflict == "test_action":
		print("Conflict detection passed")
	else:
		print("Conflict detection failed: ", conflict)

	# Test remap
	var new_key = InputEventKey.new()
	new_key.keycode = KEY_G
	remap_panel.remap_action_to("test_action", new_key)

	var events = InputMap.action_get_events("test_action")
	var found = false
	for e in events:
		if e is InputEventKey and e.keycode == KEY_G:
			found = true
			break

	if found:
		print("Remap logic passed")
	else:
		print("Remap logic failed")

	# Test Reset
	remap_panel._on_reset_pressed()
	print("Reset to defaults called")

	print("Remap Logic Tests Completed")

class_name TestRemapUI
extends GdUnitTestSuite


func test_remap_logic() -> void:
	if FileAccess.file_exists("user://remap.save"):
		DirAccess.remove_absolute("user://remap.save")

	var scene: PackedScene = load("res://scenes/ui/remap_panel.tscn") as PackedScene
	var remap_panel: Node = auto_free(scene.instantiate())
	add_child(remap_panel)

	if InputMap.has_action("test_action"):
		InputMap.erase_action("test_action")
	InputMap.add_action("test_action")
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_F
	key.physical_keycode = KEY_F
	InputMap.action_add_event("test_action", key)

	var acts: Array[StringName] = []
	for a: StringName in InputMap.get_actions():
		if a == &"test_action":
			acts.append(a)
	print("Actions list: ", acts)
	print("Events for test_action: ", InputMap.action_get_events("test_action"))
	var conflict: StringName = remap_panel.call("find_conflict", key, "other_action") as StringName
	assert_that(conflict).is_equal(StringName("test_action"))

	var new_key: InputEventKey = InputEventKey.new()
	new_key.keycode = KEY_G
	new_key.physical_keycode = KEY_G
	remap_panel.call("remap_action_to", "test_action", new_key)

	var events: Array[InputEvent] = InputMap.action_get_events("test_action")
	var found: bool = false
	for e: InputEvent in events:
		if e is InputEventKey and e.keycode == KEY_G:
			found = true
			break

	assert_that(found).is_true()

	# Clean up: restore original binding
	InputMap.action_erase_events("test_action")
	InputMap.action_add_event("test_action", key)
	InputMap.erase_action("test_action")

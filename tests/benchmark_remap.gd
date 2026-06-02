extends SceneTree


func _initialize() -> void:
	var script: GDScript = load("res://scripts/ui/remap_panel.gd") as GDScript
	var panel: Node = script.new()

	root.add_child(panel)

	var panel_vbox: VBoxContainer = VBoxContainer.new()
	panel_vbox.name = "VBoxContainer"
	var panel_scroll: ScrollContainer = ScrollContainer.new()
	panel_scroll.name = "ScrollContainer"
	var action_list: VBoxContainer = VBoxContainer.new()
	action_list.name = "ActionList"
	panel_scroll.add_child(action_list)
	panel_vbox.add_child(panel_scroll)
	panel.add_child(panel_vbox)

	var toast: Label = Label.new()
	toast.name = "ConflictToast"
	panel.add_child(toast)

	# add fake actions
	for i: int in range(100):
		var action_name: StringName = "bench_action_" + str(i)
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		var ev: InputEventKey = InputEventKey.new()
		ev.keycode = KEY_SPACE
		InputMap.action_add_event(action_name, ev)

	var start: int = Time.get_ticks_usec()
	for i: int in range(1000):
		for a: StringName in InputMap.get_actions():
			panel.call("get_action_text", a)
			panel.call("get_action_icon", a)

	var end: int = Time.get_ticks_usec()
	print("Benchmark execution time: ", end - start, " us")

	quit()

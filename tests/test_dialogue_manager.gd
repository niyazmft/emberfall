extends SceneTree


func _init() -> void:
	var dm_script: GDScript = load("res://scripts/autoload/dialogue_manager.gd") as GDScript
	var dm: Node = dm_script.new() as Node
	dm._ready()  # Manually trigger loading

	print("Testing DialogueManager...")

	# Test loading
	if dm.call("has_dialogue", "BE_B_FIRST_A") as bool:
		print("PASSED: Found BE_B_FIRST_A")
		var d: Dictionary = dm.call("get_dialogue", "BE_B_FIRST_A") as Dictionary
		if (d.get("text") as String).begins_with("Three keepers"):
			print("PASSED: Text matches for BE_B_FIRST_A")
		else:
			print("FAILED: Text mismatch for BE_B_FIRST_A: ", d.get("text"))
	else:
		print("FAILED: BE_B_FIRST_A not found")

	if dm.call("has_dialogue", "BE_PHASE_C") as bool:
		print("PASSED: Found BE_PHASE_C")
	else:
		print("FAILED: BE_PHASE_C not found")

	# Test non-existent
	if not dm.call("has_dialogue", "NON_EXISTENT") as bool:
		print("PASSED: NON_EXISTENT not found as expected")
	else:
		print("FAILED: NON_EXISTENT found??")

	# Test duplicate (should be separate dict)
	var d1: Dictionary = dm.call("get_dialogue", "BE_PHASE_D") as Dictionary
	d1["text"] = "MODIFIED"
	var d2: Dictionary = dm.call("get_dialogue", "BE_PHASE_D") as Dictionary
	if d2.get("text") as String != "MODIFIED":
		print("PASSED: Dialogue entries are duplicated correctly")
	else:
		print("FAILED: Dialogue entries are not duplicated (reference leak)")

	print("DialogueManager tests complete.")
	quit()

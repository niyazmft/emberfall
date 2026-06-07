extends SceneTree


func _init() -> void:
	var RunManager_class: GDScript = load("res://scripts/state_machine/run_manager.gd")
	var rm: Node = RunManager_class.new()

	print("--- Testing RunManager room generation ---")

	# Mock seed
	rm.run_seed = 12345
	rm.biome_count = 3
	rm.rooms_per_biome_min = 2
	rm.rooms_per_biome_max = 2

	# Directly call the action
	rm._action_generate_rooms({})

	print("Queue size: ", rm.room_queue.size())
	if rm.room_queue.size() != 6:
		print("FAILED: Expected 6 rooms, got ", rm.room_queue.size())
		quit(1)
		return

	for i: int in range(rm.room_queue.size()):
		var room: Dictionary = rm.room_queue[i]
		var room_id: String = room["room_id"]
		var biome: int = room["biome"]
		print("Room ", i, ": ", room_id, " (Biome ", biome, ")")

		# Check if room_id matches biome
		var expected_prefix: String = "room_biome%d_" % (biome + 1)
		if not room_id.begins_with(expected_prefix):
			print("FAILED: Room ID ", room_id, " does not match biome ", biome)
			quit(1)
			return

	print("--- RunManager room generation tests passed ---")
	quit(0)

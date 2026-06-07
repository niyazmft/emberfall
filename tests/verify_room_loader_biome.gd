extends SceneTree


func _init() -> void:
	var RoomLoader_class: GDScript = load("res://scripts/combat/room_loader.gd")

	print("--- Testing RoomLoader biome support ---")

	# Test loading from biome1
	var data1: Dictionary = RoomLoader_class.load_room_data("room_biome1_01", "biome1")
	if data1.is_empty():
		print("FAILED: Could not load room_biome1_01 from biome1")
		quit(1)
		return
	else:
		print("SUCCESS: Loaded room_biome1_01 from biome1")

	# Test fallback to root
	var data_fallback: Dictionary = RoomLoader_class.load_room_data("room_standard_01", "biome2")
	if data_fallback.is_empty():
		print("FAILED: Could not load room_standard_01 with biome2 fallback")
		quit(1)
		return
	else:
		print("SUCCESS: Loaded room_standard_01 with biome2 fallback")

	# Test non-existent
	var data_none: Dictionary = RoomLoader_class.load_room_data("non_existent", "biome1")
	if not data_none.is_empty():
		print("FAILED: Loaded non-existent room")
		quit(1)
		return
	else:
		print("SUCCESS: Correctly failed to load non-existent room")

	print("--- RoomLoader biome support tests passed ---")
	quit(0)

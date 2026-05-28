extends Node


func _ready() -> void:
	print("Warming up...")
	var t0 = Time.get_ticks_usec()
	for i in range(10):
		GridSystem._recompute_cover_cache()
	var dt = Time.get_ticks_usec() - t0
	print("Recompute cover cache x10 took: ", dt / 1000.0, " ms")

	t0 = Time.get_ticks_usec()
	for i in range(100):
		GridSystem.load_room({"id": "bench_room", "tiles": []})
	dt = Time.get_ticks_usec() - t0
	print("Load room x100 took: ", dt / 1000.0, " ms")
	get_tree().quit()

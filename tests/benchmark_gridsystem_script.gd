extends Node


func _ready() -> void:
	var gs := AutoloadHelper.grid_system()
	print("Warming up...")
	var t0: int = Time.get_ticks_usec()
	for i: int in range(10):
		if gs:
			gs._recompute_cover_cache()
	var dt: int = Time.get_ticks_usec() - int(t0)
	print("Recompute cover cache x10 took: ", float(dt) / 1000.0, " ms")

	t0 = Time.get_ticks_usec()
	for i: int in range(100):
		if gs:
			gs.load_room({"id": "bench_room", "tiles": []})
	dt = Time.get_ticks_usec() - int(t0)
	print("Load room x100 took: ", float(dt) / 1000.0, " ms")
	get_tree().quit()

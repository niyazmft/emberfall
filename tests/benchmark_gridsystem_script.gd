extends Node


func _ready() -> void:
	print("Warming up...")
	var t0: int = Time.get_ticks_usec()
	for i: int in range(10):
		Engine.get_main_loop().root.get_node("GridSystem")._recompute_cover_cache()
	var dt: int = Time.get_ticks_usec() - int(t0)
	print("Recompute cover cache x10 took: ", float(dt) / 1000.0, " ms")

	t0 = Time.get_ticks_usec()
	for i: int in range(100):
		Engine.get_main_loop().root.get_node("GridSystem").load_room(
			{"id": "bench_room", "tiles": []}
		)
	dt = Time.get_ticks_usec() - int(t0)
	print("Load room x100 took: ", float(dt) / 1000.0, " ms")
	get_tree().quit()

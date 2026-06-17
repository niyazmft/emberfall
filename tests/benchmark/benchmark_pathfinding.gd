extends Node2D
## Pathfinding benchmark — worst-case wall obstacle, sample size ≥1000.

const AStarGrid := preload("res://scripts/core/astar_grid.gd")

const WARMUP: int = 1000
const SAMPLES: int = 2000


func _ready() -> void:
	print("=== Pathfinding Benchmark ===")
	print("Engine: Godot ", Engine.get_version_info().string)
	print("DisplayServer: ", DisplayServer.get_name())
	print("")

	## Setup worst-case room: partial wall forcing detour.
	var gs := AutoloadHelper.grid_system()
	var wall_tiles: Array[Dictionary] = []
	for x: int in range(2, 10):
		wall_tiles.append({"x": x, "y": 6, "blocks_movement": true, "blocks_vision": true})
	if gs:
		gs.load_room({"id": "bench_wall", "tiles": wall_tiles})

	var astar: AStarGrid = AStarGrid.new()
	var path: PackedVector2Array = astar.find_path(Vector2i(0, 0), Vector2i(11, 11))
	assert(not path.is_empty(), "No path found in benchmark room!")

	## Warm-up to ensure JIT/cache is hot.
	for i: int in range(WARMUP):
		astar.find_path(Vector2i(0, 0), Vector2i(11, 11))

	var total_usec: int = 0
	var max_usec: int = 0
	var min_usec: int = 999999999
	var samples: Array[int] = []

	for i: int in range(SAMPLES):
		var t0: int = Time.get_ticks_usec()
		path = astar.find_path(Vector2i(0, 0), Vector2i(11, 11))
		var t1: int = Time.get_ticks_usec()
		var dt: int = t1 - t0
		samples.append(dt)
		total_usec += dt
		if dt > max_usec:
			max_usec = dt
		if dt < min_usec:
			min_usec = dt
		assert(not path.is_empty(), "Benchmark iteration returned empty path")

	## Percentiles
	samples.sort()
	var p95_idx: int = int(float(SAMPLES) * 0.95)
	var p99_idx: int = int(float(SAMPLES) * 0.99)
	var p95_ms: float = samples[p95_idx] / 1000.0
	var p99_ms: float = samples[p99_idx] / 1000.0
	var avg_usec: float = float(total_usec) / float(SAMPLES)
	var avg_ms: float = avg_usec / 1000.0
	var max_ms: float = max_usec / 1000.0
	var min_ms: float = min_usec / 1000.0

	print("Sample size:    ", SAMPLES)
	print("Avg query:      ", avg_ms, " ms (", avg_usec, " us)")
	print("P95 query:      ", p95_ms, " ms")
	print("P99 query:      ", p99_ms, " ms")
	print("Max query:      ", max_ms, " ms (", max_usec, " us)")
	print("Min query:      ", min_ms, " ms (", min_usec, " us)")
	print("Total time:     ", total_usec / 1000.0, " ms")
	print("")

	var budget_ms: float = 2.0
	var passed: bool = true
	if avg_ms > budget_ms:
		passed = false
	if p95_ms > budget_ms:
		passed = false
	if passed:
		print(
			"RESULT: PASS — avg ", avg_ms, " ms / p95 ", p95_ms, " ms ≤ ", budget_ms, " ms budget"
		)
	else:
		print(
			"RESULT: FAIL — avg ", avg_ms, " ms / p95 ", p95_ms, " ms > ", budget_ms, " ms budget"
		)
		get_tree().quit(1)
		return
	get_tree().quit(0)

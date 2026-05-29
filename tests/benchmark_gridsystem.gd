extends SceneTree


func _init() -> void:
	var grid_system: Node = load("res://scripts/autoload/grid_system.gd").new()
	grid_system.name = "GridSystem"
	root.add_child(grid_system)

	var bench: Node = Node.new()
	bench.set_script(load("res://tests/benchmark_gridsystem_script.gd"))
	root.add_child(bench)

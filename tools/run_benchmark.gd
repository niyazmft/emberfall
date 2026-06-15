extends SceneTree

func _init() -> void:
    var grid_system: Node = load("res://scripts/autoload/grid_system.gd").new()
    grid_system.name = "GridSystem"
    root.add_child(grid_system)

    var bench: Node = load("res://tests/benchmark/benchmark_pathfinding.gd").new()
    root.add_child(bench)

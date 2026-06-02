extends SceneTree
func _initialize() -> void:
    var t: Node = (load("res://tests/test_state_machine.gd") as GDScript).new()
    root.add_child(t)

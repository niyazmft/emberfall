class_name TestRunner
extends SceneTree

func _initialize() -> void:
	var test: Node = (preload("res://tests/test_entity_lifecycle.gd") as GDScript).new()
	get_root().add_child(test)
	# The test node will call get_tree().quit() when done.

extends SceneTree


func _init() -> void:
	var tm: Node = load("res://scripts/combat/turn_manager.gd").new()
	if tm:
		print("TurnManager loaded successfully")
	quit()

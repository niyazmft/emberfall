extends SceneTree


func _init() -> void:
	var tm: TurnManager = TurnManager.new()
	print("TurnManager loaded successfully")
	quit()

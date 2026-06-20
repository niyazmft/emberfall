extends SceneTree

func _init() -> void:
	var path := "res://scenes/ui/entity_status_bar.tscn"
	var pack := load(path) as PackedScene
	if pack:
		var scene: Node = pack.instantiate()
		scene.theme = load("res://main_theme.tres") as Theme
		var new_pack := PackedScene.new()
		new_pack.pack(scene)
		ResourceSaver.save(new_pack, path)
		print("Applied theme to entity_status_bar.tscn")
	quit()

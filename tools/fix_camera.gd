@tool
extends SceneTree

func _init() -> void:
    var pack: PackedScene = load("res://scenes/combat_room.tscn") as PackedScene
    var inst: Node2D = pack.instantiate() as Node2D
    
    var cam: Camera2D = inst.get_node("Camera2D") as Camera2D
    if cam:
        cam.zoom = Vector2(3.0, 3.0)
        # Center the camera roughly on the 12x12 grid.
        # Tile size is 64x32. The width is 12*64 = 768. The height is 12*32 = 384.
        cam.position = Vector2(0, 192)
        print("Updated Camera2D zoom and position.")
    
    var new_pack: PackedScene = PackedScene.new()
    new_pack.pack(inst)
    ResourceSaver.save(new_pack, "res://scenes/combat_room.tscn")
    print("Saved combat_room.tscn")
    quit()

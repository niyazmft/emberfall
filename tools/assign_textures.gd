@tool
extends SceneTree

func _init() -> void:
    print("Assigning textures to scenes...")
    
    var scenes: Dictionary = {
        "res://scenes/keeper.tscn": "res://assets/sprites/keeper_concept.jpg",
        "res://scenes/enemies/enemy_grunt.tscn": "res://assets/sprites/grunt_concept.jpg",
        "res://scenes/enemies/enemy_archer.tscn": "res://assets/sprites/archer_concept.jpg",
        "res://scenes/enemies/enemy_tank.tscn": "res://assets/sprites/tank_concept.jpg",
        "res://scenes/enemies/enemy_boss.tscn": "res://assets/sprites/boss_concept.jpg"
    }
    
    for scene_path: String in scenes.keys():
        var tex_path: String = scenes[scene_path] as String
        var tex: Texture2D = load(tex_path) as Texture2D
        if tex == null:
            print("Failed to load texture: ", tex_path)
            continue
            
        var pack: PackedScene = load(scene_path) as PackedScene
        if pack == null:
            print("Failed to load scene: ", scene_path)
            continue
            
        var inst: Node = pack.instantiate()
        var proxy: Node = inst.get_node_or_null("EntityVisualProxy")
        if proxy != null:
            var base_sprite: Sprite2D = proxy.get_node_or_null("BaseSprite") as Sprite2D
            if base_sprite != null:
                base_sprite.texture = tex
                base_sprite.scale = Vector2(32.0 / tex.get_width(), 48.0 / tex.get_height())
                
                var new_pack: PackedScene = PackedScene.new()
                new_pack.pack(inst)
                ResourceSaver.save(new_pack, scene_path)
                print("Updated ", scene_path)
    
    quit()

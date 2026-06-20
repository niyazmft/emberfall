@tool
extends SceneTree

func _init() -> void:
    # 1. Create a global theme
    var theme: Theme = Theme.new()
    var font: FontFile = load("res://assets/fonts/PressStart2P-Regular.ttf") as FontFile
    if font:
        theme.default_font = font
        theme.default_font_size = 12
        theme.set_font("font", "Label", font)
        theme.set_font("font", "Button", font)
        
        # Keep the dark grey button styles
        var normal_style: StyleBoxFlat = StyleBoxFlat.new()
        normal_style.bg_color = Color(0.15, 0.15, 0.15)
        normal_style.corner_radius_top_left = 4
        normal_style.corner_radius_top_right = 4
        normal_style.corner_radius_bottom_left = 4
        normal_style.corner_radius_bottom_right = 4
        
        var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
        hover_style.bg_color = Color(0.25, 0.25, 0.25)
        
        var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
        pressed_style.bg_color = Color(0.1, 0.1, 0.1)
        
        theme.set_stylebox("normal", "Button", normal_style)
        theme.set_stylebox("hover", "Button", hover_style)
        theme.set_stylebox("pressed", "Button", pressed_style)
        theme.set_stylebox("focus", "Button", normal_style)
        
        ResourceSaver.save(theme, "res://main_theme.tres")
        print("Created res://main_theme.tres")
        
        # 2. Apply it to combat_hud.tscn
        var pack: PackedScene = load("res://scenes/ui/combat_hud.tscn") as PackedScene
        if pack:
            var inst: Control = pack.instantiate() as Control
            inst.theme = theme
            
            var new_pack: PackedScene = PackedScene.new()
            new_pack.pack(inst)
            ResourceSaver.save(new_pack, "res://scenes/ui/combat_hud.tscn")
            print("Applied theme to combat_hud.tscn")
    else:
        print("Failed to load font")
        
    quit()

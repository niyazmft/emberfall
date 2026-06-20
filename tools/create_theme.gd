@tool
extends SceneTree

func _init() -> void:
    var theme: Theme = Theme.new()
    
    # Button Style
    var btn_normal: StyleBoxFlat = StyleBoxFlat.new()
    btn_normal.bg_color = Color(0.15, 0.15, 0.15, 0.9)
    btn_normal.border_width_bottom = 2
    btn_normal.border_color = Color(0.05, 0.05, 0.05)
    btn_normal.corner_radius_top_left = 4
    btn_normal.corner_radius_top_right = 4
    btn_normal.corner_radius_bottom_left = 4
    btn_normal.corner_radius_bottom_right = 4
    btn_normal.content_margin_left = 12
    btn_normal.content_margin_right = 12
    btn_normal.content_margin_top = 8
    btn_normal.content_margin_bottom = 8
    
    var btn_hover: StyleBoxFlat = btn_normal.duplicate() as StyleBoxFlat
    btn_hover.bg_color = Color(0.25, 0.25, 0.25, 1.0)
    
    var btn_pressed: StyleBoxFlat = btn_normal.duplicate() as StyleBoxFlat
    btn_pressed.bg_color = Color(0.1, 0.1, 0.1, 1.0)
    btn_pressed.border_width_bottom = 0
    btn_pressed.content_margin_top = 10
    btn_pressed.content_margin_bottom = 6
    
    theme.set_stylebox("normal", "Button", btn_normal)
    theme.set_stylebox("hover", "Button", btn_hover)
    theme.set_stylebox("pressed", "Button", btn_pressed)
    
    # ProgressBars (HP / AP)
    var pb_bg: StyleBoxFlat = StyleBoxFlat.new()
    pb_bg.bg_color = Color(0.05, 0.05, 0.05, 0.8)
    pb_bg.corner_radius_top_left = 4
    pb_bg.corner_radius_top_right = 4
    pb_bg.corner_radius_bottom_left = 4
    pb_bg.corner_radius_bottom_right = 4
    
    var pb_fill: StyleBoxFlat = StyleBoxFlat.new()
    pb_fill.bg_color = Color(0.2, 0.6, 0.2)
    pb_fill.corner_radius_top_left = 4
    pb_fill.corner_radius_top_right = 4
    pb_fill.corner_radius_bottom_left = 4
    pb_fill.corner_radius_bottom_right = 4
    
    theme.set_stylebox("background", "ProgressBar", pb_bg)
    theme.set_stylebox("fill", "ProgressBar", pb_fill)
    
    ResourceSaver.save(theme, "res://assets/main_theme.tres")
    print("Theme created at res://assets/main_theme.tres")
    
    var pack: PackedScene = load("res://scenes/ui/combat_hud.tscn") as PackedScene
    var inst: Control = pack.instantiate() as Control
    inst.theme = theme
    
    var new_pack: PackedScene = PackedScene.new()
    new_pack.pack(inst)
    ResourceSaver.save(new_pack, "res://scenes/ui/combat_hud.tscn")
    print("Applied theme to combat_hud.tscn")
    
    quit()

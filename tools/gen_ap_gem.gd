@tool
extends SceneTree

func _init() -> void:
    # Full Gem
    var w: int = 12
    var h: int = 12
    var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
    
    var hw: float = w / 2.0
    var hh: float = h / 2.0
    
    for py: int in range(h):
        for px: int in range(w):
            var dx: float = abs(float(px) + 0.5 - hw) / hw
            var dy: float = abs(float(py) + 0.5 - hh) / hh
            
            if dx + dy <= 1.0:
                var c: Color = Color(1.0, 0.8, 0.2, 1.0) # Gold
                if dx + dy > 0.7:
                    c = c.darkened(0.4)
                if px == w/2 and py == h/2:
                    c = Color.WHITE
                img.set_pixel(px, py, c)
                
    img.save_png("res://assets/sprites/ap_gem.png")
    
    # Empty Gem
    var img_empty: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
    for py: int in range(h):
        for px: int in range(w):
            var dx: float = abs(float(px) + 0.5 - hw) / hw
            var dy: float = abs(float(py) + 0.5 - hh) / hh
            if dx + dy <= 1.0:
                var c: Color = Color(0.2, 0.2, 0.2, 0.8) # Dark grey
                if dx + dy > 0.7:
                    c = Color(0.1, 0.1, 0.1, 1.0)
                img_empty.set_pixel(px, py, c)
                
    img_empty.save_png("res://assets/sprites/ap_gem_empty.png")
    
    print("Created AP gem sprites")
    quit()

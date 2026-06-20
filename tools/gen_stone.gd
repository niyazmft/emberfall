@tool
extends SceneTree

func _init() -> void:
    var w: int = 64
    var h: int = 32
    var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
    
    var noise: FastNoiseLite = FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_CELLULAR
    noise.seed = 42
    noise.frequency = 0.05
    
    var hw: float = w / 2.0
    var hh: float = h / 2.0
    
    for py: int in range(h):
        for px: int in range(w):
            var dx: float = abs(float(px) + 0.5 - hw) / hw
            var dy: float = abs(float(py) + 0.5 - hh) / hh
            
            if dx + dy <= 1.0:
                var n: float = noise.get_noise_2d(px, py) * 0.5 + 0.5
                var c: Color = Color(0.3 + n*0.1, 0.3 + n*0.1, 0.32 + n*0.1)
                
                if dx + dy > 0.85:
                    c = c.darkened(0.5)
                
                img.set_pixel(px, py, c)

    img.save_png("res://assets/sprites/tile_stone.png")
    print("Created tile_stone.png")
    quit()

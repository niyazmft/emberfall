extends SceneTree

func _init() -> void:
	var width: int = 64
	var height: int = 32
	var img: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	
	# We'll use a soft gray base
	var base_color := Color(0.25, 0.25, 0.25, 1.0)
	
	for y: int in range(height):
		for x: int in range(width):
			# Map to -1.0 to 1.0 range
			var nx: float = float(x) / width * 2.0 - 1.0
			var ny: float = float(y) / height * 2.0 - 1.0
			
			# Check if point is inside diamond
			# Diamond equation: |nx| + |ny| <= 1.0
			if abs(nx) + abs(ny) <= 1.0:
				var n: float = noise.get_noise_2d(float(x), float(y))
				# Modulate the base color slightly based on noise
				var c := base_color
				c.r += n * 0.03
				c.g += n * 0.03
				c.b += n * 0.03
				img.set_pixel(x, y, c)
				
	img.save_png("res://assets/sprites/tile_stone.png")
	print("Regenerated softer tile_stone.png")
	quit()

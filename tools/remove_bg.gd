@tool
extends SceneTree

func _init() -> void:
	var dir: DirAccess = DirAccess.open("res://assets/sprites")
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".jpg"):
				var img: Image = Image.load_from_file("res://assets/sprites/" + file_name)
				if img:
					img.convert(Image.FORMAT_RGBA8)
					for y: int in range(img.get_height()):
						for x: int in range(img.get_width()):
							var color: Color = img.get_pixel(x, y)
							if color.r < 0.2 and color.g < 0.2 and color.b < 0.2:
								color.a = 0.0
								img.set_pixel(x, y, color)
					
					var new_name: String = file_name.replace(".jpg", ".png")
					img.save_png("res://assets/sprites/" + new_name)
					print("Converted " + file_name + " to " + new_name)
			file_name = dir.get_next()
	
	quit()

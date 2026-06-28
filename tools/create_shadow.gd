@tool
extends SceneTree

func _init() -> void:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0.5))
	gradient.set_color(1, Color(0, 0, 0, 0.0))
	
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	
	var err: Error = ResourceSaver.save(texture, "res://assets/sprites/soft_radial_shadow.tres")
	if err == OK:
		print("Successfully created soft_radial_shadow.tres")
	else:
		print("Error saving texture: ", err)
	quit()

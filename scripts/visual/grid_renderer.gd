extends Node2D
class_name GridRenderer
## GridRenderer
## Visual system for rendering the 12×12 tactical grid with isometric
## projection and elevation terraces.
##
## Projection: Isometric (64×32)
## Art Style: Greybox vector-like diamonds

@export var tile_size: Vector2 = Vector2(64, 32)
@export var elevation_step: float = 16.0

var _grid_system: _GridSystem
var _tile_sprites: Array[Sprite2D] = []
var _diamond_tex: Texture2D

# Greybox colors based on specification
const COLOR_FLOOR: Color = Color(0.5, 0.5, 0.5)      # Grey
const COLOR_ELEV_1: Color = Color(0.75, 0.75, 0.75)  # Light Grey
const COLOR_ELEV_2: Color = Color(1.0, 1.0, 1.0)       # White
const COLOR_COVER: Color = Color(0.55, 0.27, 0.07)    # Brown
const COLOR_OIL: Color = Color(0.0, 0.0, 0.55)        # Dark Blue


func _ready() -> void:
	# Idiomatic access to Autoloaded systems
	_grid_system = GridSystem
	_diamond_tex = _generate_diamond_texture()
	_render_grid()


## Render all 144 tiles from the GridSystem.
func _render_grid() -> void:
	# Clear existing visuals for re-render support
	for child: Node in get_children():
		child.queue_free()
	_tile_sprites.clear()

	if not _grid_system:
		push_warning("GridRenderer: _grid_system is null, cannot render grid.")
		return

	# Draw order: Isometric grids are typically rendered from back-to-front.
	# Sorting by (x + y) ensures correct depth for flat grids.
	# Nested loops naturally follow this order in isometric space.
	for y: int in range(GridSystem.GRID_SIZE):
		for x: int in range(GridSystem.GRID_SIZE):
			var tile: TacTileData = _grid_system.get_tile(x, y)
			if tile:
				_render_tile(x, y, tile)


## Render a single tile with its elevation terraces and overlays.
func _render_tile(x: int, y: int, tile: TacTileData) -> void:
	var elev_val: int = int(tile.elevation)

	# 1. Elevation Terraces: Visual Stacking
	# We draw diamonds from ground up to the tile's actual elevation.
	for e: int in range(elev_val + 1):
		var sprite := Sprite2D.new()
		sprite.texture = _diamond_tex
		sprite.centered = true
		sprite.position = _grid_to_world(x, y, e)

		# Color based on elevation level
		match e:
			0:
				sprite.modulate = COLOR_FLOOR
			1:
				sprite.modulate = COLOR_ELEV_1
			2:
				sprite.modulate = COLOR_ELEV_2

		add_child(sprite)
		_tile_sprites.append(sprite)

	# 2. Cover Visual (Greybox)
	if tile.cover != TacTileData.CoverType.NONE:
		var cover_sprite := Sprite2D.new()
		cover_sprite.texture = _diamond_tex
		cover_sprite.scale = Vector2(0.4, 0.4)
		cover_sprite.modulate = COLOR_COVER

		# Position on top of the highest terrace
		var pos := _grid_to_world(x, y, elev_val)
		pos.y -= 4.0 # Floating slightly above
		cover_sprite.position = pos
		add_child(cover_sprite)
		_tile_sprites.append(cover_sprite)

	# 3. Elemental Effects (Oil)
	if _grid_system.has_oil_tile(x, y):
		var oil_sprite := Sprite2D.new()
		oil_sprite.texture = _diamond_tex
		oil_sprite.scale = Vector2(0.8, 0.8)
		oil_sprite.modulate = COLOR_OIL
		oil_sprite.modulate.a = 0.6
		oil_sprite.position = _grid_to_world(x, y, elev_val)
		add_child(oil_sprite)
		_tile_sprites.append(oil_sprite)


## Internal: Convert grid coordinates and elevation to isometric world position.
func _grid_to_world(x: int, y: int, elevation: int) -> Vector2:
	var gx := float(x)
	var gy := float(y)

	# Isometric transformation:
	# Standard formula for 2:1 isometric (64x32)
	var wx: float = (gx - gy) * (tile_size.x / 2.0)
	var wy: float = (gx + gy) * (tile_size.y / 2.0)

	# Apply vertical elevation offset
	wy -= float(elevation) * elevation_step
	return Vector2(wx, wy)


## Public API: Convert grid coordinates to world position at the tile's current elevation.
func grid_to_world(x: int, y: int) -> Vector2:
	if not _grid_system:
		return Vector2.ZERO

	var tile: TacTileData = _grid_system.get_tile(x, y)
	var elev: int = 0
	if tile:
		elev = int(tile.elevation)

	return _grid_to_world(x, y, elev)


## Procedural diamond texture generation for greyboxing.
func _generate_diamond_texture() -> Texture2D:
	var w: int = int(tile_size.x)
	var h: int = int(tile_size.y)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)

	var hw: float = w / 2.0
	var hh: float = h / 2.0

	for py: int in range(h):
		for px: int in range(w):
			# Distance from center in normalized 0-1 range
			var dx: float = abs(float(px) + 0.5 - hw) / hw
			var dy: float = abs(float(py) + 0.5 - hh) / hh

			# Diamond check (Manhattan distance <= 1)
			if dx + dy <= 1.0:
				img.set_pixel(px, py, Color.WHITE)

	return ImageTexture.create_from_image(img)

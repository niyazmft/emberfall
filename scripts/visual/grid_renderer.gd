class_name GridRenderer
extends Node2D
## GridRenderer
## Visual system for rendering the 12×12 tactical grid with isometric
## projection and elevation terraces.
##
## Projection: Isometric (64×32)
## Art Style: Greybox vector-like diamonds

# Greybox colors based on specification
const COLOR_FLOOR: Color = Color(0.5, 0.5, 0.5)  # Grey
const COLOR_ELEV_1: Color = Color(0.75, 0.75, 0.75)  # Light Grey
const COLOR_ELEV_2: Color = Color(1.0, 1.0, 1.0)  # White
const COLOR_COVER: Color = Color(0.55, 0.27, 0.07)  # Brown
const COLOR_OIL: Color = Color(0.0, 0.0, 0.55)  # Dark Blue

@export var tile_size: Vector2 = Vector2(64, 32)
@export var elevation_step: float = 16.0

var _grid_system: _GridSystem
var _config_loader: _ConfigLoader
var _tile_sprites: Array[Sprite2D] = []
var _highlights: Dictionary[Vector2i, Sprite2D] = {}
var _highlight_styles: Dictionary[Vector2i, Dictionary] = {}
var _telegraph_lines: Array[Node2D] = []
var _diamond_tex: Texture2D

var _time: float = 0.0


func _ready() -> void:
	# Idiomatic access to Autoloaded systems
	_grid_system = AutoloadHelper.grid_system()
	_config_loader = AutoloadHelper.config_loader()
	_diamond_tex = _generate_diamond_texture()
	_render_grid()


func _process(delta: float) -> void:
	_time += delta
	_update_animations()


func _update_animations() -> void:
	for vKey: Vector2i in _highlights.keys():
		var sprite: Sprite2D = _highlights[vKey]
		var style: Dictionary = _highlight_styles.get(vKey, {})
		if style.is_empty():
			continue

		var pulse: Dictionary = style.get("pulse", {})
		if not pulse.is_empty() and pulse.get("enabled", false):
			var speed: float = float(pulse.get("speed", 2.0))
			var minA: float = float(pulse.get("min_alpha", 0.4))
			var maxA: float = float(pulse.get("max_alpha", 0.8))

			# Sine wave for alpha pulsing: maps [-1, 1] to [minA, maxA]
			var t: float = (sin(_time * speed) + 1.0) / 2.0
			sprite.modulate.a = lerp(minA, maxA, t)


## Render all 144 tiles from the GridSystem.
func _render_grid() -> void:
	# Clear existing visuals for re-render support
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_tile_sprites.clear()

	if not _grid_system:
		push_warning("GridRenderer: _grid_system is null, cannot render grid.")
		return

	# Draw order: Isometric grids are typically rendered from back-to-front.
	# Sorting by (x + y) ensures correct depth for flat grids.
	# Nested loops naturally follow this order in isometric space.
	for y: int in range(_grid_system.GRID_SIZE):
		for x: int in range(_grid_system.GRID_SIZE):
			var tile: TacTileData = _grid_system.get_tile(x, y)
			if tile:
				_render_tile(x, y, tile)


## Render a single tile with its elevation terraces and overlays.
func _render_tile(x: int, y: int, tile: TacTileData) -> void:
	var elevVal: int = int(tile.elevation)

	# 1. Elevation Terraces: Visual Stacking
	# We draw diamonds from ground up to the tile's actual elevation.
	for e: int in range(elevVal + 1):
		var sprite: Sprite2D = Sprite2D.new()
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
		var coverSprite: Sprite2D = Sprite2D.new()
		coverSprite.texture = _diamond_tex
		coverSprite.scale = Vector2(0.4, 0.4)
		coverSprite.modulate = COLOR_COVER

		# Position on top of the highest terrace
		var pos: Vector2 = _grid_to_world(x, y, elevVal)
		pos.y -= 4.0  # Floating slightly above
		coverSprite.position = pos
		add_child(coverSprite)
		_tile_sprites.append(coverSprite)

	# 3. Elemental Effects (Oil)
	if _grid_system.has_oil_tile(x, y):
		var oilSprite: Sprite2D = Sprite2D.new()
		oilSprite.texture = _diamond_tex
		oilSprite.scale = Vector2(0.8, 0.8)
		oilSprite.modulate = COLOR_OIL
		oilSprite.modulate.a = 0.6
		oilSprite.position = _grid_to_world(x, y, elevVal)
		add_child(oilSprite)
		_tile_sprites.append(oilSprite)


## Internal: Convert grid coordinates and elevation to isometric world position.
func _grid_to_world(x: int, y: int, elevation: int) -> Vector2:
	var gx: float = float(x)
	var gy: float = float(y)

	# Isometric transformation:
	# Standard formula for 2:1 isometric (64x32)
	var wx: float = (gx - gy) * (tile_size.x / 2.0)
	var wy: float = (gx + gy) * (tile_size.y / 2.0)

	# Apply vertical elevation offset
	wy -= float(elevation) * elevation_step
	return Vector2(wx, wy)


## Public API: Convert grid coordinates to world position at the tile's current elevation.
## If elevation is -1, it uses the tile's elevation from the GridSystem.
func grid_to_world(x: int, y: int, elevation: int = -1) -> Vector2:
	if not _grid_system:
		return Vector2.ZERO

	var elev: int = elevation
	if elev == -1:
		var tile: TacTileData = _grid_system.get_tile(x, y)
		if tile:
			elev = int(tile.elevation)
		else:
			elev = 0

	return _grid_to_world(x, y, elev)


## Public API: Highlight a specific tile using a style key from config.
func highlight_tile_styled(x: int, y: int, style_key: String) -> void:
	if not _grid_system or not _config_loader:
		return

	var rawStyles: Variant = _config_loader.getValue("highlights", "", {})
	if not rawStyles is Dictionary:
		return
	var styles: Dictionary = rawStyles as Dictionary

	if not styles.has(style_key):
		push_warning("GridRenderer: Style key '%s' not found in grid_visuals.json" % style_key)
		return

	var styleRef: Variant = styles[style_key]
	if not styleRef is Dictionary:
		return
	var styleDict: Dictionary = styleRef as Dictionary
	var style: Dictionary = styleDict.duplicate()
	style["_style_key"] = style_key
	var color: Color = Color.from_string(str(style.get("color", "#ffffff")), Color.WHITE)
	color.a = float(style.get("opacity", 0.6))

	_apply_highlight(x, y, color, style)


## Legacy Public API: Highlight a specific tile with a color.
func highlight_tile(x: int, y: int, color: Color) -> void:
	_apply_highlight(x, y, color, {})


func _apply_highlight(x: int, y: int, color: Color, style: Dictionary) -> void:
	if not _grid_system:
		return

	var key: Vector2i = Vector2i(x, y)

	# If already highlighted, just update
	if _highlights.has(key):
		var spriteRef: Variant = _highlights[key]
		if spriteRef is Sprite2D:
			var sprite: Sprite2D = spriteRef as Sprite2D
			sprite.modulate = color
			_highlight_styles[key] = style
		return

	var tile: TacTileData = _grid_system.get_tile(x, y)
	if not tile:
		return

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = _diamond_tex
	sprite.centered = true
	sprite.scale = Vector2(0.9, 0.9)  # Slightly smaller than the tile
	sprite.modulate = color
	# Ensure some transparency if not provided in style
	if style.is_empty() and sprite.modulate.a == 1.0:
		sprite.modulate.a = 0.6

	sprite.position = grid_to_world(x, y, int(tile.elevation))
	sprite.position.y -= 1.0  # Slightly above to avoid Z-fighting

	add_child(sprite)
	_highlights[key] = sprite
	_highlight_styles[key] = style


## Public API: Clear all active highlights.
func clear_highlights() -> void:
	for sprite: Sprite2D in _highlights.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
	_highlights.clear()
	_highlight_styles.clear()


## Public API: Clear highlights of a specific style.
func clear_highlights_styled(style_key: String) -> void:
	var keysToRemove: Array[Vector2i] = []
	for vKey: Vector2i in _highlight_styles.keys():
		var style: Dictionary = _highlight_styles[vKey]
		if style.get("_style_key") == style_key:
			keysToRemove.append(vKey)

	for keyToRemove: Vector2i in keysToRemove:
		var sprite: Sprite2D = _highlights[keyToRemove]
		if is_instance_valid(sprite):
			sprite.queue_free()
		_highlights.erase(keyToRemove)
		_highlight_styles.erase(keyToRemove)


## Public API: Draw a telegraph arrow from start grid pos to end grid pos.
func draw_telegraph_arrow(startPos: Vector2i, endPos: Vector2i) -> void:
	if not _config_loader or not _grid_system:
		return

	# Bounds check
	if not _is_in_bounds(startPos) or not _is_in_bounds(endPos):
		return

	var rawArrowConfig: Variant = _config_loader.getValue("telegraph_arrows", "default", {})
	if not rawArrowConfig is Dictionary:
		return
	var arrowConfig: Dictionary = rawArrowConfig as Dictionary

	var colorHex: String = str(arrowConfig.get("color", "#ffffff"))
	var color: Color = Color.from_string(colorHex, Color.WHITE)
	var width: float = float(arrowConfig.get("width", 2.0))

	var startWorld: Vector2 = grid_to_world(startPos.x, startPos.y)
	var endWorld: Vector2 = grid_to_world(endPos.x, endPos.y)

	var line: Line2D = Line2D.new()
	line.add_point(startWorld)
	line.add_point(endWorld)
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.z_index = 10  # Ensure it's above most things

	add_child(line)
	_telegraph_lines.append(line)

	# Draw arrowhead
	var headSize: float = float(arrowConfig.get("head_size", 8.0))
	if headSize > 0:
		var dir: Vector2 = (endWorld - startWorld).normalized()
		var perp: Vector2 = Vector2(-dir.y, dir.x)
		var p1: Vector2 = endWorld
		var p2: Vector2 = endWorld - dir * headSize + perp * (headSize * 0.6)
		var p3: Vector2 = endWorld - dir * headSize - perp * (headSize * 0.6)

		var head: Polygon2D = Polygon2D.new()
		head.polygon = PackedVector2Array([p1, p2, p3])
		head.color = color
		head.antialiased = true
		head.z_index = 10

		add_child(head)
		_telegraph_lines.append(head)


## Public API: Clear all telegraph indicators.
func clear_telegraphs() -> void:
	for node: Variant in _telegraph_lines:
		if node is Node2D:
			var n: Node2D = node
			if is_instance_valid(n):
				n.queue_free()
	_telegraph_lines.clear()


func _is_in_bounds(pos: Vector2i) -> bool:
	return (
		pos.x >= 0
		and pos.x < _grid_system.GRID_SIZE
		and pos.y >= 0
		and pos.y < _grid_system.GRID_SIZE
	)


## Procedural diamond texture generation for greyboxing.
func _generate_diamond_texture() -> Texture2D:
	var w: int = int(tile_size.x)
	var h: int = int(tile_size.y)
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)

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

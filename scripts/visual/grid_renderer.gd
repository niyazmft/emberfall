class_name GridRenderer
extends Node2D
## GridRenderer
## Visual system for rendering the 12×12 tactical grid with isometric
## projection and elevation terraces.
##
## Projection: Isometric (64×32)
## Art Style: Greybox vector-like diamonds

# Greybox colors based on specification
const COLOR_FLOOR: Color = Color(0.6, 0.55, 0.5)  # Warm stone/beige
const COLOR_ELEV_1: Color = Color(0.6, 0.65, 0.75)  # Cool grey-blue
const COLOR_ELEV_2: Color = Color(1.0, 1.0, 1.0)  # White
const COLOR_COVER: Color = Color(0.55, 0.27, 0.07)  # Brown
const COLOR_OIL: Color = Color(0.0, 0.0, 0.55)  # Dark Blue

@export var tile_size: Vector2 = Vector2(64, 32)
@export var elevation_step: float = 16.0

var _grid_system: _GridSystem
var _tile_sprites: Array[Sprite2D] = []
var _highlights: Dictionary = {}  # Vector2i -> Sprite2D
var _hover_sprite: Sprite2D
var _hovered_tile: Vector2i = Vector2i(-1, -1)
var _diamond_tex: Texture2D

var _prop_rock: Texture2D = load("res://assets/sprites/props/prop_rock.png") as Texture2D
var _prop_broken_pillar: Texture2D = (
	load("res://assets/sprites/props/prop_broken_pillar.png") as Texture2D
)
var _prop_cracked_tile: Texture2D = (
	load("res://assets/sprites/props/prop_cracked_tile.png") as Texture2D
)
var _prop_debris: Texture2D = load("res://assets/sprites/props/prop_debris.png") as Texture2D
var _prop_burnt_wood: Texture2D = (
	load("res://assets/sprites/props/prop_burnt_wood.png") as Texture2D
)
var _prop_crystal: Texture2D = load("res://assets/sprites/props/prop_crystal.png") as Texture2D
var _prop_scattered_bones: Texture2D = (
	load("res://assets/sprites/props/prop_scattered_bones.png") as Texture2D
)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover_from_mouse()


func _update_hover_from_mouse() -> void:
	if not _grid_system:
		return

	var local_pos: Vector2 = to_local(get_global_mouse_position())
	var grid_pos: Vector2i = _world_to_grid(local_pos)

	if not _grid_system.is_in_bounds(grid_pos.x, grid_pos.y):
		_clear_hover()
		return

	if grid_pos == _hovered_tile:
		return

	_hovered_tile = grid_pos
	_ensure_hover_sprite()
	if _hover_sprite:
		var tile: TacTileData = _grid_system.get_tile(grid_pos.x, grid_pos.y)
		var elev: int = int(tile.elevation) if tile else 0
		_hover_sprite.position = _grid_to_world(grid_pos.x, grid_pos.y, elev)
		_hover_sprite.visible = true


func _clear_hover() -> void:
	_hovered_tile = Vector2i(-1, -1)
	if _hover_sprite:
		_hover_sprite.visible = false


func _ensure_hover_sprite() -> void:
	if _hover_sprite:
		return
	_hover_sprite = Sprite2D.new()
	_hover_sprite.texture = _diamond_tex
	_hover_sprite.centered = true
	_hover_sprite.scale = Vector2(1.05, 1.05)
	_hover_sprite.modulate = Color(1.0, 1.0, 0.8, 0.35)
	add_child(_hover_sprite)


func _world_to_grid(world_pos: Vector2) -> Vector2i:
	## Inverse isometric projection: converts local screen position to grid coords.
	## Uses the same 64×32 2:1 ratio as _grid_to_world().
	var tw: float = tile_size.x
	var th: float = tile_size.y
	var gx: float = world_pos.x / (tw / 2.0) + world_pos.y / (th / 2.0)
	var gy: float = world_pos.y / (th / 2.0) - world_pos.x / (tw / 2.0)
	return Vector2i(int(round(gx / 2.0)), int(round(gy / 2.0)))


func _ready() -> void:
	# Idiomatic access to Autoloaded systems
	_grid_system = AutoloadHelper.grid_system()

	var custom_tex: Texture2D = load("res://assets/sprites/tile_stone.png") as Texture2D
	if custom_tex != null:
		_diamond_tex = custom_tex
	else:
		_diamond_tex = _generate_diamond_texture()

	_render_grid()


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
	var elev_val: int = int(tile.elevation)

	# Deterministic per-tile variation so identical textures don't form a grey void.
	var tile_seed: int = SeedGovernance.hash_seed("TILEVAR_" + str(x) + "_" + str(y))
	var tile_norm: float = (float(tile_seed % 161) / 100.0) - 0.8

	# 1. Elevation Terraces: Visual Stacking
	# We draw diamonds from ground up to the tile's actual elevation.
	for e: int in range(elev_val + 1):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = _diamond_tex
		sprite.centered = true
		sprite.position = _grid_to_world(x, y, e)

		var base_mod: Color
		var is_fallback: bool = (
			_diamond_tex.resource_path.is_empty()
			or not _diamond_tex.resource_path.ends_with(".png")
		)

		if is_fallback:
			match e:
				0:
					base_mod = COLOR_FLOOR
				1:
					base_mod = COLOR_ELEV_1
				2:
					base_mod = COLOR_ELEV_2
				_:
					base_mod = COLOR_ELEV_2
		else:
			# Custom texture: stronger elevation steps, higher = brighter.
			match e:
				0:
					base_mod = Color(0.60, 0.60, 0.60)
				1:
					base_mod = Color(0.80, 0.80, 0.80)
				2:
					base_mod = Color(1.00, 1.00, 1.00)
				_:
					base_mod = Color(1.00, 1.00, 1.00)

		# Apply subtle per-tile colour variation to break up uniformity.
		var var_r: float = tile_norm * 0.05
		var var_g: float = tile_norm * 0.03
		var var_b: float = tile_norm * 0.01

		var r: float = DeterministicMath.clampf(base_mod.r + var_r, 0.0, 1.0)
		var g: float = DeterministicMath.clampf(base_mod.g + var_g, 0.0, 1.0)
		var b: float = DeterministicMath.clampf(base_mod.b + var_b, 0.0, 1.0)

		sprite.modulate = Color(r, g, b, 1.0)

		add_child(sprite)
		_tile_sprites.append(sprite)

	# 2. Cover Visual (Greybox -> Premium Props)
	if tile.cover != TacTileData.CoverType.NONE:
		var cover_sprite: Sprite2D = Sprite2D.new()
		var is_real_prop: bool = false
		if tile_seed % 2 == 0 and _prop_rock != null:
			cover_sprite.texture = _prop_rock
			cover_sprite.scale = Vector2(0.5, 0.5)
			cover_sprite.offset = Vector2(0, -16)
			is_real_prop = true
		elif _prop_broken_pillar != null:
			cover_sprite.texture = _prop_broken_pillar
			cover_sprite.scale = Vector2(0.5, 0.5)
			cover_sprite.offset = Vector2(0, -16)
			is_real_prop = true
		else:
			cover_sprite.texture = _diamond_tex
			cover_sprite.scale = Vector2(0.4, 0.4)
			cover_sprite.modulate = COLOR_COVER

		# Position on top of the highest terrace
		var pos: Vector2 = _grid_to_world(x, y, elev_val)
		if not is_real_prop:
			pos.y -= 4.0  # Floating slightly above
		cover_sprite.position = pos
		add_child(cover_sprite)
		_tile_sprites.append(cover_sprite)
	elif not _grid_system.has_oil_tile(x, y):
		# Deterministically sprinkle floor detail props (cracked tiles, debris, burnt wood, bones) on empty tiles
		var detail_val: int = tile_seed % 100
		var detail_tex: Texture2D = null
		if detail_val < 8 and _prop_cracked_tile != null:
			detail_tex = _prop_cracked_tile
		elif detail_val >= 8 and detail_val < 15 and _prop_debris != null:
			detail_tex = _prop_debris
		elif detail_val >= 15 and detail_val < 20 and _prop_burnt_wood != null:
			detail_tex = _prop_burnt_wood
		elif detail_val >= 20 and detail_val < 24 and _prop_scattered_bones != null:
			detail_tex = _prop_scattered_bones
		elif detail_val >= 24 and detail_val < 27 and _prop_crystal != null:
			detail_tex = _prop_crystal

		if detail_tex != null:
			var detail_sprite: Sprite2D = Sprite2D.new()
			detail_sprite.texture = detail_tex
			detail_sprite.scale = Vector2(0.45, 0.45)
			detail_sprite.position = _grid_to_world(x, y, elev_val)
			detail_sprite.modulate = Color(0.9, 0.9, 0.9, 0.85)
			add_child(detail_sprite)
			_tile_sprites.append(detail_sprite)

	# 3. Elemental Effects (Oil)
	if _grid_system.has_oil_tile(x, y):
		var oil_sprite: Sprite2D = Sprite2D.new()
		oil_sprite.texture = _diamond_tex
		oil_sprite.scale = Vector2(0.8, 0.8)
		oil_sprite.modulate = COLOR_OIL
		oil_sprite.modulate.a = 0.6
		oil_sprite.position = _grid_to_world(x, y, elev_val)
		add_child(oil_sprite)
		_tile_sprites.append(oil_sprite)


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


## Public API: Highlight a specific tile with a color (e.g., for targeting).
func highlight_tile(x: int, y: int, color: Color) -> void:
	if not _grid_system:
		return

	var key: Vector2i = Vector2i(x, y)

	# If already highlighted, just update color
	if _highlights.has(key):
		var sprite: Sprite2D = _highlights[key]
		sprite.modulate = color
		return

	var tile: TacTileData = _grid_system.get_tile(x, y)
	if not tile:
		return

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = _diamond_tex
	sprite.centered = true
	sprite.scale = Vector2(0.9, 0.9)  # Slightly smaller than the tile
	sprite.modulate = color
	# Ensure some transparency if not provided
	if sprite.modulate.a == 1.0:
		sprite.modulate.a = 0.6

	sprite.position = grid_to_world(x, y, int(tile.elevation))
	sprite.position.y -= 1.0  # Slightly above to avoid Z-fighting

	add_child(sprite)
	_highlights[key] = sprite


## Public API: Clear all active highlights.
func clear_highlights() -> void:
	for sprite: Sprite2D in _highlights.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
	_highlights.clear()


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
			var dx: float = DeterministicMath.absf(float(px) + 0.5 - hw) / hw
			var dy: float = DeterministicMath.absf(float(py) + 0.5 - hh) / hh

			# Diamond check (Manhattan distance <= 1)
			if dx + dy <= 1.0:
				img.set_pixel(px, py, Color.WHITE)

	return ImageTexture.create_from_image(img)

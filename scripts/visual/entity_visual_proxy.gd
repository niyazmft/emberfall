class_name EntityVisualProxy
extends Node2D

## EntityVisualProxy
## Bridges Entity data to visual representation.
## Handles: positioning, elevation, facing direction, state effects.

@export var entity: Entity:
	set(p_value):
		if entity != p_value:
			if entity:
				_disconnect_entity_signals()
			entity = p_value
			if is_inside_tree() and entity:
				_connect_entity_signals()
				_sync_to_entity()

@export var base_sprite: Sprite2D
@export var shadow_sprite: Sprite2D
@export var height_indicator: CanvasItem
@export var lerp_speed: float = 10.0

var _target_position: Vector2
var _grid_renderer: GridRenderer

var _hit_flash_tween: Tween
var _hit_flash_weight: float = 0.0:
	set(p_value):
		_hit_flash_weight = p_value
		if base_sprite and base_sprite.material is ShaderMaterial:
			(base_sprite.material as ShaderMaterial).set_shader_parameter(
				"u_hit_flash", _hit_flash_weight
			)


func _ready() -> void:
	var combat_room: Node = get_node_or_null("/root/CombatRoom")
	if combat_room:
		for child: Node in combat_room.get_children():
			if child is GridRenderer:
				_grid_renderer = child as GridRenderer
				break

	if not _grid_renderer:
		# Fallback: search the tree by type instead of string name
		_grid_renderer = _find_grid_renderer(get_tree().root)

	_setup_greybox()

	if entity:
		_connect_entity_signals()
		_sync_to_entity()
		global_position = _target_position  # Snap initially


func _process(delta: float) -> void:
	if global_position.distance_to(_target_position) > 0.1:
		var weight: float = minf(delta * lerp_speed, 1.0)
		global_position = global_position.lerp(_target_position, weight)
	else:
		global_position = _target_position


func _find_grid_renderer(node: Node) -> GridRenderer:
	if node is GridRenderer:
		return node as GridRenderer
	for child: Node in node.get_children():
		var result: GridRenderer = _find_grid_renderer(child)
		if result != null:
			return result
	return null


func _sync_to_entity() -> void:
	if not entity:
		return
	_on_entity_position_changed(entity.x, entity.y)
	_on_entity_elevation_changed(entity.elevation)
	_on_entity_facing_changed(entity.facing_x, entity.facing_y)
	_on_entity_state_changed(entity.state)


func _connect_entity_signals() -> void:
	if not entity:
		return
	if not entity.position_changed.is_connected(_on_entity_position_changed):
		entity.position_changed.connect(_on_entity_position_changed)
	if not entity.elevation_changed.is_connected(_on_entity_elevation_changed):
		entity.elevation_changed.connect(_on_entity_elevation_changed)
	if not entity.facing_changed.is_connected(_on_entity_facing_changed):
		entity.facing_changed.connect(_on_entity_facing_changed)
	if not entity.state_changed.is_connected(_on_entity_state_changed):
		entity.state_changed.connect(_on_entity_state_changed)
	if not entity.hp_changed.is_connected(_on_entity_hp_changed):
		entity.hp_changed.connect(_on_entity_hp_changed)


func _disconnect_entity_signals() -> void:
	if not entity:
		return
	if entity.position_changed.is_connected(_on_entity_position_changed):
		entity.position_changed.disconnect(_on_entity_position_changed)
	if entity.elevation_changed.is_connected(_on_entity_elevation_changed):
		entity.elevation_changed.disconnect(_on_entity_elevation_changed)
	if entity.facing_changed.is_connected(_on_entity_facing_changed):
		entity.facing_changed.disconnect(_on_entity_facing_changed)
	if entity.state_changed.is_connected(_on_entity_state_changed):
		entity.state_changed.disconnect(_on_entity_state_changed)
	if entity.hp_changed.is_connected(_on_entity_hp_changed):
		entity.hp_changed.disconnect(_on_entity_hp_changed)


func _on_entity_position_changed(x: int, y: int) -> void:
	if _grid_renderer and entity:
		_target_position = _grid_renderer.grid_to_world(x, y, entity.elevation)


func _on_entity_elevation_changed(elevation: int) -> void:
	if _grid_renderer and entity:
		_target_position = _grid_renderer.grid_to_world(entity.x, entity.y, elevation)
	_update_elevation_visuals(elevation)


func _on_entity_facing_changed(fx: int, fy: int) -> void:
	_update_facing_visuals(fx, fy)


func _on_entity_state_changed(state: Entity.State) -> void:
	_update_state_visuals(state)


func _on_entity_hp_changed(new_hp: int, old_hp: int) -> void:
	if new_hp < old_hp:
		trigger_hit_flash()

		var app: Node = null
		if has_node("ApparitionRenderer"):
			app = get_node("ApparitionRenderer")
		elif get_parent() and get_parent().has_node("ApparitionRenderer"):
			app = get_parent().get_node("ApparitionRenderer")

		if app and app.has_method("trigger_damage_effect"):
			app.call("trigger_damage_effect")


func trigger_hit_flash() -> void:
	if _hit_flash_tween:
		_hit_flash_tween.kill()

	_hit_flash_tween = create_tween()
	self._hit_flash_weight = 1.0
	(
		_hit_flash_tween
		. tween_property(self, "_hit_flash_weight", 0.0, 0.15)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)


func _update_elevation_visuals(elevation: int) -> void:
	# Shadow offset: drop down as elevation increases to stay on ground.
	# Elevation step is 16.0 in GridRenderer.
	if shadow_sprite:
		shadow_sprite.position.y = float(elevation) * 16.0

	if height_indicator:
		height_indicator.visible = elevation > 0
		if height_indicator is ColorRect:
			var cr: ColorRect = height_indicator as ColorRect
			match elevation:
				1:
					cr.color = Color.RED
				2:
					cr.color = Color.WHITE
				_:
					cr.color = Color.GRAY


func _update_facing_visuals(facing_x: int, facing_y: int) -> void:
	if base_sprite:
		# Horizontal flip based on X
		if facing_x < 0:
			base_sprite.flip_h = true
		elif facing_x > 0:
			base_sprite.flip_h = false

		# Vertical orientation (facing_y) would typically swap textures or regions.
		# For this greybox, we print a debug message to acknowledge 4-way support.
		if facing_y != 0 and facing_x == 0:
			# Logic for Up/Down visuals goes here.
			pass


func _update_state_visuals(state: Entity.State) -> void:
	match state:
		Entity.State.DYING:
			modulate = Color(1.0, 0.4, 0.4)
		Entity.State.STUNNED:
			modulate = Color(1.0, 1.0, 0.0)
		Entity.State.DEAD:
			modulate = Color(0.3, 0.3, 0.3, 0.6)
		_:
			modulate = Color.WHITE


func grid_to_world(x: int, y: int, elevation: int) -> Vector2:
	if _grid_renderer:
		return _grid_renderer.grid_to_world(x, y, elevation)
	return Vector2.ZERO


func _setup_greybox() -> void:
	if not base_sprite:
		base_sprite = Sprite2D.new()
		base_sprite.name = "BaseSprite"
		var img: Image = Image.create(32, 48, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		base_sprite.texture = ImageTexture.create_from_image(img)
		base_sprite.offset = Vector2(0, -24)
		add_child(base_sprite)

	if base_sprite and not base_sprite.material:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://assets/shaders/sprite_base.gdshader")
		base_sprite.material = mat

	if not shadow_sprite:
		shadow_sprite = Sprite2D.new()
		shadow_sprite.name = "ShadowSprite"
		var img: Image = Image.create(32, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.1, 0.1, 0.1, 0.5))
		shadow_sprite.texture = ImageTexture.create_from_image(img)
		shadow_sprite.z_index = -1
		add_child(shadow_sprite)

	if not height_indicator and not has_node("HeightIndicator"):
		var hi: ColorRect = ColorRect.new()
		hi.name = "HeightIndicator"
		hi.size = Vector2(32, 4)
		hi.position = Vector2(-16, 2)
		hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hi)
		height_indicator = hi

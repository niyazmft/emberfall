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
var _status_bar: EntityStatusBar
var _hit_flash_timer: float = 0.0
var _hit_flash_duration: float = 0.1
var _hit_stop_remaining: int = 0


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
	_setupStatusBar()

	if entity:
		_connect_entity_signals()
		_sync_to_entity()
		global_position = _target_position  # Snap initially


func _exit_tree() -> void:
	_disconnect_entity_signals()


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
	if not entity.ap_changed.is_connected(_on_entity_ap_changed):
		entity.ap_changed.connect(_on_entity_ap_changed)


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
	if entity.ap_changed.is_connected(_on_entity_ap_changed):
		entity.ap_changed.disconnect(_on_entity_ap_changed)


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
		var app: Node = null
		if has_node("ApparitionRenderer"):
			app = get_node("ApparitionRenderer")
		elif get_parent() and get_parent().has_node("ApparitionRenderer"):
			app = get_parent().get_node("ApparitionRenderer")

		if app and app.has_method("trigger_damage_effect"):
			app.call("trigger_damage_effect")

	if _status_bar:
		_status_bar.updateHp(new_hp, entity.hp_max)


func _on_entity_ap_changed(new_ap: int, _old_ap: int) -> void:
	if _status_bar:
		_status_bar.updateAp(new_ap, GameConstants.AP_MAX)


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
		pass


func _update_state_visuals(p_state: Entity.State) -> void:
	match p_state:
		Entity.State.DYING:
			modulate = Color(1.0, 0.4, 0.4)
		Entity.State.STUNNED:
			modulate = Color(1.0, 1.0, 0.0)
		Entity.State.DEAD:
			modulate = Color(0.3, 0.3, 0.3, 0.6)
		_:
			modulate = Color.WHITE


func grid_to_world(p_x: int, p_y: int, p_elevation: int) -> Vector2:
	if _grid_renderer:
		return _grid_renderer.grid_to_world(p_x, p_y, p_elevation)
	return Vector2.ZERO


func _setupStatusBar() -> void:
	var bar_scene: PackedScene = load("res://scenes/ui/entity_status_bar.tscn")
	if bar_scene:
		_status_bar = bar_scene.instantiate() as EntityStatusBar
		add_child(_status_bar)
		_status_bar.position = Vector2(-32, -60)  # Position above entity
		if entity:
			_status_bar.updateHp(entity.hp, entity.hp_max)
			_status_bar.updateAp(entity.ap, GameConstants.AP_MAX)


func _triggerHitEffects(p_damage: int, p_damage_type: String = "PHYSICAL") -> void:
	var loader: _ConfigLoader = AutoloadHelper.config_loader()

	# Hit Flash
	if loader:
		var flash_config: Dictionary = loader.getValue("hit_flash", "", {})
		if not flash_config.is_empty():
			_hit_flash_duration = float(flash_config.get("duration", 0.1))
	_hit_flash_timer = _hit_flash_duration

	# Hit Stop
	if loader:
		var hit_stop_config: Dictionary = loader.getValue("hit_stop", "", {})
		if hit_stop_config:
			var tiers: Array = hit_stop_config.get("tiers", [])
			for tier: Dictionary in tiers:
				if p_damage >= tier.get("threshold", 0):
					_hit_stop_remaining = tier.get("frames", 0)

	# Screen Shake
	var combat_room: Node = get_node_or_null("/root/CombatRoom")
	if combat_room and combat_room.get("camera") and combat_room.camera.has_method("add_shake"):
		combat_room.camera.call("add_shake", clampf(float(p_damage) / 20.0, 0.1, 0.5))

	# Floating Text
	_spawnDamageNumber(p_damage, p_damage_type)


func _spawnDamageNumber(p_damage: int, p_damage_type: String) -> void:
	var loader: _ConfigLoader = AutoloadHelper.config_loader()
	var color: Color = Color.WHITE
	var duration: float = 0.5
	var offset_vec: Vector2 = Vector2(0, -40)

	if loader:
		var floating_config: Dictionary = loader.getValue("floating_text", "", {})
		if floating_config and floating_config.has(p_damage_type):
			var preset: Dictionary = floating_config[p_damage_type]
			color = Color(preset.get("color", "#FFFFFF"))
			duration = float(preset.get("duration", 0.5))
			var offset_arr: Variant = preset.get("offset", [0, -40])
			if offset_arr is Array and offset_arr.size() >= 2:
				offset_vec = Vector2(float(offset_arr[0]), float(offset_arr[1]))

	var label: Label = Label.new()
	label.text = str(p_damage)
	label.modulate = color
	add_child(label)
	label.position = offset_vec

	var tween: Tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -20), duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration)
	tween.tween_callback(label.queue_free)


func _setup_greybox() -> void:
	if not base_sprite:
		base_sprite = Sprite2D.new()
		base_sprite.name = "BaseSprite"
		var img: Image = Image.create(32, 48, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		base_sprite.texture = ImageTexture.create_from_image(img)
		base_sprite.offset = Vector2(0, -24)
		add_child(base_sprite)

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

class_name EntityVisualProxy
extends Node2D

## EntityVisualProxy
## Bridges Entity data to visual representation.
## Handles: positioning, elevation, facing direction, state effects.

const STATUS_BAR_SCENE: PackedScene = preload("res://scenes/ui/entity_status_bar.tscn")

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
@onready var _apparition_renderer: ApparitionRenderer = _find_apparition_renderer()
var _hit_flash_timer: float = 0.0
var _hit_flash_duration: float = 0.1
var _hit_stop_remaining: int = 0
var _damage_label_pool: Array[Label] = []
var _cached_flash_color: Color = Color.WHITE

## Reference to the CombatRoom node (set by parent scene; NOT an autoload).
## Use export to avoid fragile /root/ lookup.
var _combat_room: CombatRoom = null


func _ready() -> void:
	if not _combat_room:
		_combat_room = get_node_or_null("/root/CombatRoom") as CombatRoom
	if _combat_room:
		_grid_renderer = _combat_room.grid_renderer

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
	if _hit_stop_remaining > 0:
		_hit_stop_remaining -= 1
		return

	if global_position.distance_to(_target_position) > 0.1:
		var weight: float = minf(delta * lerp_speed, 1.0)
		global_position = global_position.lerp(_target_position, weight)
	else:
		global_position = _target_position

	# Hit Flash Logic
	if _hit_flash_timer > 0:
		_hit_flash_timer -= delta
		if base_sprite:
			base_sprite.modulate = Color.WHITE.lerp(
				_cached_flash_color, _hit_flash_timer / _hit_flash_duration
			)

		if _hit_flash_timer <= 0:
			if base_sprite:
				base_sprite.modulate = Color.WHITE


func _find_grid_renderer(node: Node) -> GridRenderer:
	if node is GridRenderer:
		return node as GridRenderer
	for child: Node in node.get_children():
		var result: GridRenderer = _find_grid_renderer(child)
		if result != null:
			return result
	return null


func _find_apparition_renderer() -> ApparitionRenderer:
	var ar := get_node_or_null("ApparitionRenderer") as ApparitionRenderer
	if not ar and get_parent():
		ar = get_parent().get_node_or_null("ApparitionRenderer") as ApparitionRenderer
	return ar


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
	if not entity.damage_taken.is_connected(_triggerHitEffects):
		entity.damage_taken.connect(_triggerHitEffects)


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
	if entity.damage_taken.is_connected(_triggerHitEffects):
		entity.damage_taken.disconnect(_triggerHitEffects)


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
	if state == Entity.State.DEAD:
		var sfx := AutoloadHelper.sfx_manager()
		if sfx:
			sfx.play_sfx("death", global_position)


func _on_entity_hp_changed(new_hp: int, old_hp: int) -> void:
	if new_hp < old_hp:
		if _apparition_renderer:
			_apparition_renderer.trigger_damage_effect()
		_triggerHitEffects(old_hp - new_hp)

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
	if STATUS_BAR_SCENE:
		_status_bar = STATUS_BAR_SCENE.instantiate() as EntityStatusBar
		add_child(_status_bar)
		_status_bar.position = Vector2(-32, -60)  # Position above entity
		if entity:
			_status_bar.updateHp(entity.hp, entity.hp_max)
			_status_bar.updateAp(entity.ap, GameConstants.AP_MAX)


func _triggerHitEffects(p_damage: int, p_damage_type: String = "PHYSICAL") -> void:
	var sfx := AutoloadHelper.sfx_manager()
	if sfx:
		sfx.play_sfx("hit", global_position)

	var loader: _ConfigLoader = AutoloadHelper.config_loader()

	# Hit Flash
	if loader:
		var flash_config: Dictionary = loader.getValue("hit_flash", "", {})
		if not flash_config.is_empty():
			_hit_flash_duration = float(flash_config.get("duration_seconds", 0.1))
			_cached_flash_color = Color(flash_config.get("color", "#FFFFFF"))
	_hit_flash_timer = _hit_flash_duration

	# Hit Stop
	if loader:
		var hit_stop_config: Dictionary = loader.getValue("hit_stop", "", {})
		if not hit_stop_config.is_empty():
			var tiers: Array = hit_stop_config.get("tiers", [])
			for tier: Variant in tiers:
				if tier is Dictionary:
					if p_damage >= tier.get("threshold", 0):
						_hit_stop_remaining = int(tier.get("frames", 0))

	# Floating Text
	_spawnDamageNumber(p_damage, p_damage_type)

	# Screen Shake
	if loader:
		var shake_config: Dictionary = loader.getValue("screen_shake", "", {})
		if not shake_config.is_empty():
			var eb := AutoloadHelper.event_bus()
			if eb:
				var intensity: float = float(shake_config.get("default_intensity", 4.0))
				var duration: float = float(shake_config.get("default_duration", 0.2))
				eb.camera_shake_requested.emit(intensity, duration)


func _spawnDamageNumber(p_damage: int, p_damage_type: String) -> void:
	var loader: _ConfigLoader = AutoloadHelper.config_loader()
	var color: Color = Color.WHITE
	var duration: float = 1.0
	var rise_pixels: int = 40

	if loader:
		var damage_config: Dictionary = loader.getValue("damage_numbers", "", {})
		if not damage_config.is_empty():
			duration = float(damage_config.get("duration_seconds", 1.0))
			rise_pixels = int(damage_config.get("rise_pixels", 40))

		# Optional per-type color override if defined in a nested 'types' or similar
		# For now, we'll look for a direct color in damage_numbers or use defaults
		var type_configs: Dictionary = loader.getValue("floating_text", "", {})
		if not type_configs.is_empty() and type_configs.has(p_damage_type):
			var type_cfg: Dictionary = type_configs[p_damage_type]
			color = Color(type_cfg.get("color", "#FFFFFF"))

	var label: Label
	var parent_node: Node = get_parent()
	if _combat_room and _combat_room.entity_container:
		parent_node = _combat_room.entity_container

	if _damage_label_pool.is_empty():
		label = Label.new()
		# Use a default theme or font size if available
		label.add_theme_font_size_override("font_size", 18)
		parent_node.add_child(label)
	else:
		label = _damage_label_pool.pop_back()
		if label.get_parent() != parent_node:
			label.get_parent().remove_child(label)
			parent_node.add_child(label)

	label.text = str(p_damage)
	label.modulate = color
	# Start at entity's world position plus a small offset
	label.global_position = global_position + Vector2(-16, -40)
	label.visible = true
	label.z_index = 100  # Ensure it's above most things

	var tween: Tween = create_tween()
	var target_pos: Vector2 = label.position + Vector2(0, -rise_pixels)
	(
		tween
		. tween_property(label, "position", target_pos, duration)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration)
	tween.tween_callback(
		func() -> void:
			label.visible = false
			_damage_label_pool.append(label)
	)


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

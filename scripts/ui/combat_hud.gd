class_name _CombatHUD
extends Control
## CombatHUD (DON-196)
## Manages HUD layout and bottom chrome reflow.

signal move_pressed

var _player_entity: Entity
var _turn_manager: TurnManager
var _combat_input: CombatInput

@onready var margin_container: MarginContainer = $MarginContainer
@onready var bottom_chrome: VBoxContainer = $MarginContainer/BottomChrome
@onready var hotbar: Control = $MarginContainer/BottomChrome/Hotbar
@onready var prompts: Label = $MarginContainer/BottomChrome/Prompts
@onready var status_icons: Control = $MarginContainer/BottomChrome/StatusIcons
@onready var action_buttons: Control = $MarginContainer/BottomChrome/ActionButtons
@onready var tutorial_overlay: _TutorialOverlay = %TutorialOverlay

# HP/AP Display
@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var ap_bar: ProgressBar = %APBar
@onready var ap_label: Label = %APLabel

# Action Buttons
@onready var move_button: Button = %MoveButton
@onready var attack_button: Button = %AttackButton
@onready var end_turn_button: Button = %EndTurnButton

# Turn/Round Indicators
@onready var turn_label: Label = %TurnLabel
@onready var round_label: Label = %RoundLabel

# Minimap
@onready var minimap_container: SubViewportContainer = %MinimapContainer
var _minimap_grid: GridRenderer
var _minimap_player_dot: Sprite2D
var _minimap_enemy_dots: Array[Sprite2D] = []
var _minimap_enemy_map: Dictionary = {}  # entity -> dot sprite
var _minimap_scale: float = 0.15


func _ready() -> void:
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz:
		sz.safe_area_changed.connect(_on_safe_area_changed)
		sz.aspect_ratio_changed.connect(_on_aspect_ratio_changed)
	_apply_safe_area()
	_reflow_bottom_chrome()
	_setup_tooltips()

	# Connect button signals
	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Connect floating text signal
	var eb := AutoloadHelper.event_bus()
	if eb:
		if not eb.floating_text_requested.is_connected(_on_floating_text_requested):
			eb.floating_text_requested.connect(_on_floating_text_requested)


func _exit_tree() -> void:
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz:
		if sz.safe_area_changed.is_connected(_on_safe_area_changed):
			sz.safe_area_changed.disconnect(_on_safe_area_changed)
		if sz.aspect_ratio_changed.is_connected(_on_aspect_ratio_changed):
			sz.aspect_ratio_changed.disconnect(_on_aspect_ratio_changed)

	if move_button.pressed.is_connected(_on_move_pressed):
		move_button.pressed.disconnect(_on_move_pressed)
	if attack_button.pressed.is_connected(_on_attack_pressed):
		attack_button.pressed.disconnect(_on_attack_pressed)
	if end_turn_button.pressed.is_connected(_on_end_turn_pressed):
		end_turn_button.pressed.disconnect(_on_end_turn_pressed)

	var eb := AutoloadHelper.event_bus()
	if eb:
		if eb.floating_text_requested.is_connected(_on_floating_text_requested):
			eb.floating_text_requested.disconnect(_on_floating_text_requested)

	_cleanup_minimap()

	if _player_entity:
		if _player_entity.hp_changed.is_connected(_on_hp_changed):
			_player_entity.hp_changed.disconnect(_on_hp_changed)
		if _player_entity.ap_changed.is_connected(_on_ap_changed):
			_player_entity.ap_changed.disconnect(_on_ap_changed)

	if _turn_manager:
		if _turn_manager.turn_started.is_connected(_on_turn_started):
			_turn_manager.turn_started.disconnect(_on_turn_started)
		if _turn_manager.round_started.is_connected(_on_round_started):
			_turn_manager.round_started.disconnect(_on_round_started)

	if _combat_input:
		if _combat_input.targeting_started.is_connected(_on_targeting_started):
			_combat_input.targeting_started.disconnect(_on_targeting_started)
		if _combat_input.attack_executed.is_connected(_on_attack_executed):
			_combat_input.attack_executed.disconnect(_on_attack_executed)


func setup(player_entity: Entity, turn_manager: TurnManager, combat_input: CombatInput) -> void:
	_player_entity = player_entity
	_turn_manager = turn_manager
	_combat_input = combat_input

	if _player_entity:
		if not _player_entity.hp_changed.is_connected(_on_hp_changed):
			_player_entity.hp_changed.connect(_on_hp_changed)
		if not _player_entity.ap_changed.is_connected(_on_ap_changed):
			_player_entity.ap_changed.connect(_on_ap_changed)
		update_player_stats(_player_entity)
		if hotbar and hotbar.has_method("set_player_entity"):
			hotbar.call("set_player_entity", player_entity)

	if _turn_manager:
		if not _turn_manager.turn_started.is_connected(_on_turn_started):
			_turn_manager.turn_started.connect(_on_turn_started)
		if not _turn_manager.round_started.is_connected(_on_round_started):
			_turn_manager.round_started.connect(_on_round_started)
		round_label.text = "Round %d" % _turn_manager.round_number

	if _combat_input:
		if not _combat_input.targeting_started.is_connected(_on_targeting_started):
			_combat_input.targeting_started.connect(_on_targeting_started)
		if not _combat_input.attack_executed.is_connected(_on_attack_executed):
			_combat_input.attack_executed.connect(_on_attack_executed)

	# Show tutorial for new players (no save file yet)
	if tutorial_overlay:
		var sm: _SaveManager = AutoloadHelper.save_manager()
		if sm and not sm.has_save():
			tutorial_overlay.show_tutorial()

	_setup_minimap()


func update_player_stats(entity: Entity) -> void:
	hp_bar.max_value = entity.hp_max
	hp_bar.value = entity.hp
	hp_label.text = "%d / %d" % [entity.hp, entity.hp_max]

	var config: Node = AutoloadHelper.config_loader()
	var ap_max: int = (
		config.getValue("ap_bar", "segment_count", GameConstants.AP_MAX)
		if config
		else GameConstants.AP_MAX
	)
	ap_bar.max_value = ap_max
	ap_bar.value = entity.ap
	ap_label.text = "%d / %d" % [entity.ap, ap_max]


func log_action(message: String) -> void:
	prompts.text = message


func _on_hp_changed(_new_hp: int, _old_hp: int) -> void:
	update_player_stats(_player_entity)


func _on_ap_changed(_new_ap: int, _old_ap: int) -> void:
	update_player_stats(_player_entity)


func _on_turn_started(entity: Entity, is_player: bool) -> void:
	if is_player:
		turn_label.text = tr("HUD_PLAYER_TURN")
		turn_label.modulate = Color.GREEN
		_enable_action_buttons(true)
		_log_from_config("player_turn")
	else:
		var enemy_name: String = entity.entity_name if entity else "Enemy"
		turn_label.text = tr("HUD_ENEMY_TURN") % enemy_name
		turn_label.modulate = Color.RED
		_enable_action_buttons(false)
		_log_from_config("enemy_turn", [enemy_name])


func _on_round_started(round_number: int) -> void:
	round_label.text = tr("HUD_ROUND_LABEL") % round_number
	_log_from_config("round_start", [round_number])


func _on_targeting_started() -> void:
	_log_from_config("select_target")


func _on_attack_executed(target: Node2D, damage: int) -> void:
	var target_name: String = "Enemy"
	if target is BaseEnemy:
		target_name = (target as BaseEnemy).entity.entity_name
	elif target is Keeper:
		target_name = (target as Keeper).entity.entity_name

	_log_from_config("damage_dealt", [damage, target_name])


func _on_move_pressed() -> void:
	move_pressed.emit()
	_log_from_config("move_hint")


func _on_attack_pressed() -> void:
	if _combat_input:
		_combat_input.enter_targeting_mode()


func _on_end_turn_pressed() -> void:
	if _turn_manager:
		_turn_manager.end_player_turn()


func _enable_action_buttons(enabled: bool) -> void:
	move_button.disabled = !enabled
	attack_button.disabled = !enabled
	end_turn_button.disabled = !enabled


func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()


func _on_aspect_ratio_changed(_mode: _SafeZoneManager.AspectMode) -> void:
	_reflow_bottom_chrome()


func _apply_safe_area() -> void:
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz == null:
		return
	var margins: Dictionary = sz.get_safe_margins()
	margin_container.add_theme_constant_override("margin_left", margins.left)
	margin_container.add_theme_constant_override("margin_top", margins.top)
	margin_container.add_theme_constant_override("margin_right", margins.right)
	margin_container.add_theme_constant_override("margin_bottom", margins.bottom)


func _setup_tooltips() -> void:
	var config: Node = AutoloadHelper.config_loader()
	if not config:
		return

	var tooltips: Dictionary = config.getValue("tooltips", "", {})
	if tooltips.has("hp_bar"):
		hp_bar.tooltip_text = tr(tooltips["hp_bar"])
	if tooltips.has("ap_bar"):
		ap_bar.tooltip_text = tr(tooltips["ap_bar"])
	if tooltips.has("move_button"):
		move_button.tooltip_text = tr(tooltips["move_button"])
	if tooltips.has("attack_button"):
		attack_button.tooltip_text = tr(tooltips["attack_button"])
	if tooltips.has("end_turn_button"):
		end_turn_button.tooltip_text = tr(tooltips["end_turn_button"])


func _log_from_config(template_key: String, args: Array = []) -> void:
	var config: Node = AutoloadHelper.config_loader()
	if not config:
		return

	var templates: Dictionary = config.getValue("combat_log", "templates", {})
	if templates.has(template_key):
		var localized_template: String = tr(templates[template_key])
		if not args.is_empty():
			log_action(localized_template % args)
		else:
			log_action(localized_template)


func show_floating_text(text: String, position: Vector2, color: Color) -> void:
	var label: Label = Label.new()
	add_child(label)
	label.text = text
	label.modulate = color
	label.position = position
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(label, "position:y", position.y - 20.0, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)


func _on_floating_text_requested(text: String, position: Vector2, color: Color) -> void:
	show_floating_text(text, position, color)


func _reflow_bottom_chrome() -> void:
	# AC: Bottom chrome priority reflow (hotbar → prompts → status icons)
	# In a VBoxContainer, if we want this order from bottom to top:
	# 1. Hotbar (at the very bottom)
	# 2. Prompts (above hotbar)
	# 3. Status Icons (above prompts)

	# We ensure child order: StatusIcons, Prompts, ActionButtons, Hotbar
	bottom_chrome.move_child(status_icons, 0)
	bottom_chrome.move_child(prompts, 1)
	bottom_chrome.move_child(action_buttons, 2)
	bottom_chrome.move_child(hotbar, 3)

	# If viewport is very tight (SHRINK mode), we might want to hide status icons
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz and sz.current_aspect_mode == _SafeZoneManager.AspectMode.SHRINK:
		status_icons.hide()
	else:
		status_icons.show()


# ------------------------------------------------------------------
# Minimap
# ------------------------------------------------------------------


func _setup_minimap() -> void:
	if minimap_container == null:
		return
	var subviewport: SubViewport = minimap_container.get_node_or_null("SubViewport")
	if subviewport == null:
		return

	# Create a scaled-down grid renderer inside the minimap viewport
	_minimap_grid = GridRenderer.new()
	subviewport.add_child(_minimap_grid)
	await get_tree().process_frame

	_minimap_grid.scale = Vector2(_minimap_scale, _minimap_scale)

	# Position camera to center on the grid
	var camera: Camera2D = subviewport.get_node_or_null("Camera2D")
	if camera:
		camera.position = Vector2(60, 60)

	# Create player dot (green)
	_minimap_player_dot = _create_dot_sprite(Color.GREEN)
	_minimap_grid.add_child(_minimap_player_dot)

	# Create enemy dots (red)
	var tree: SceneTree = get_tree()
	if tree:
		for enemy_node: Node in tree.get_nodes_in_group("enemies"):
			var enemy_entity: Entity = CombatEntity.get_entity(enemy_node)
			if enemy_entity:
				var dot: Sprite2D = _create_dot_sprite(Color.RED)
				_minimap_grid.add_child(dot)
				_minimap_enemy_dots.append(dot)
				_minimap_enemy_map[enemy_entity] = dot
				if not enemy_entity.position_changed.is_connected(_on_minimap_entity_moved):
					enemy_entity.position_changed.connect(_on_minimap_entity_moved)

	# Connect to player position changes
	if (
		_player_entity
		and not _player_entity.position_changed.is_connected(_on_minimap_entity_moved)
	):
		_player_entity.position_changed.connect(_on_minimap_entity_moved)

	_update_minimap_dots()


func _cleanup_minimap() -> void:
	if _player_entity and _player_entity.position_changed.is_connected(_on_minimap_entity_moved):
		_player_entity.position_changed.disconnect(_on_minimap_entity_moved)
	for enemy_entity: Entity in _minimap_enemy_map.keys():
		if (
			is_instance_valid(enemy_entity)
			and enemy_entity.position_changed.is_connected(_on_minimap_entity_moved)
		):
			enemy_entity.position_changed.disconnect(_on_minimap_entity_moved)
	_minimap_enemy_map.clear()
	for dot: Sprite2D in _minimap_enemy_dots:
		if is_instance_valid(dot):
			dot.queue_free()
	_minimap_enemy_dots.clear()
	if is_instance_valid(_minimap_player_dot):
		_minimap_player_dot.queue_free()
		_minimap_player_dot = null
	if is_instance_valid(_minimap_grid):
		_minimap_grid.queue_free()
		_minimap_grid = null


func _create_dot_sprite(color: Color) -> Sprite2D:
	var img: Image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	return sprite


func _on_minimap_entity_moved(_x: int, _y: int) -> void:
	_update_minimap_dots()


func _update_minimap_dots() -> void:
	if _minimap_grid == null:
		return

	# Update player dot position
	if _player_entity and is_instance_valid(_minimap_player_dot):
		var pos: Vector2i = _player_entity.grid_position()
		_minimap_player_dot.position = _minimap_grid.grid_to_world(pos.x, pos.y, 0)

	# Update enemy dot positions
	for enemy_entity: Entity in _minimap_enemy_map.keys():
		if not is_instance_valid(enemy_entity):
			continue
		var dot: Sprite2D = _minimap_enemy_map[enemy_entity]
		if is_instance_valid(dot):
			var pos: Vector2i = enemy_entity.grid_position()
			dot.position = _minimap_grid.grid_to_world(pos.x, pos.y, 0)

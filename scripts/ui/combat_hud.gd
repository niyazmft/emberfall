extends Control
## CombatHUD (DON-196)
## Manages HUD layout and bottom chrome reflow.

var _player_entity: Entity
var _turn_manager: TurnManager
var _combat_input: CombatInput

@onready var margin_container: MarginContainer = $MarginContainer
@onready var bottom_chrome: VBoxContainer = $MarginContainer/BottomChrome
@onready var hotbar: Control = $MarginContainer/BottomChrome/Hotbar
@onready var prompts: Label = $MarginContainer/BottomChrome/Prompts
@onready var status_icons: Control = $MarginContainer/BottomChrome/StatusIcons
@onready var action_buttons: Control = $MarginContainer/BottomChrome/ActionButtons

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


func _ready() -> void:
	SafeZoneManager.safe_area_changed.connect(_on_safe_area_changed)
	SafeZoneManager.aspect_ratio_changed.connect(_on_aspect_ratio_changed)
	_apply_safe_area()
	_reflow_bottom_chrome()
	_setup_tooltips()

	# Connect button signals
	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)


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
	if target.has_method("get_entity_name"):
		target_name = target.call("get_entity_name")
	elif target.get("entity"):
		target_name = target.get("entity").entity_name

	_log_from_config("damage_dealt", [damage, target_name])


func _on_move_pressed() -> void:
	if _combat_input:
		_combat_input.call("_on_move_pressed")


func _on_attack_pressed() -> void:
	if _combat_input:
		# Use public signal-triggering method if it exists,
		# otherwise we must use the internal one for now.
		if _combat_input.has_method("enter_targeting_mode"):
			_combat_input.call("enter_targeting_mode")
		elif _combat_input.has_method("_start_targeting"):
			_combat_input.call("_start_targeting")


func _on_end_turn_pressed() -> void:
	if _turn_manager:
		_turn_manager.end_player_turn()


func _enable_action_buttons(enabled: bool) -> void:
	move_button.disabled = !enabled
	attack_button.disabled = !enabled
	end_turn_button.disabled = !enabled


func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()


func _on_aspect_ratio_changed(_mode: SafeZoneManager.AspectMode) -> void:
	_reflow_bottom_chrome()


func _apply_safe_area() -> void:
	var margins := SafeZoneManager.get_safe_margins()
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
	if SafeZoneManager.current_aspect_mode == SafeZoneManager.AspectMode.SHRINK:
		status_icons.hide()
	else:
		status_icons.show()

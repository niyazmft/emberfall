extends Control
## CombatHUD (DON-196)
## Manages HUD layout and bottom chrome reflow.

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

# Quest Display
@onready var quest_container: VBoxContainer = %QuestContainer

var _player_entity: Entity
var _turn_manager: TurnManager
var _combat_input: CombatInput


func _ready() -> void:
	SafeZoneManager.safe_area_changed.connect(_on_safe_area_changed)
	SafeZoneManager.aspect_ratio_changed.connect(_on_aspect_ratio_changed)
	_apply_safe_area()
	_reflow_bottom_chrome()

	# Connect button signals
	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Quest Tracker
	var qt: _QuestTracker = AutoloadHelper.quest_tracker()
	if qt:
		qt.quests_updated.connect(_update_quest_list)
		qt.quest_progressed.connect(_on_quest_progressed)
		_update_quest_list()


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


func _update_quest_list() -> void:
	# Clear existing quest entries (except the title label)
	for child: Node in quest_container.get_children():
		if child.name != "QuestLabel":
			child.queue_free()

	var qt: _QuestTracker = AutoloadHelper.quest_tracker()
	if not qt:
		return

	var active_quests: Array[Dictionary] = qt.get_active_quests()
	for q: Dictionary in active_quests:
		var label: Label = Label.new()
		label.name = "Quest_" + q["id"]
		label.add_theme_font_size_override("font_size", 12)
		_update_quest_label(label, q)
		quest_container.add_child(label)


func _update_quest_label(label: Label, q: Dictionary) -> void:
	var status: String = "[DONE]" if q["completed"] else "[%d/%d]" % [q["current"], q["goal"]]
	label.text = "%s: %s" % [q["name"], status]
	if q["completed"]:
		label.modulate = Color.GREEN
	else:
		label.modulate = Color.WHITE


func _on_quest_progressed(quest_id: String, _current: int, _goal: int) -> void:
	var label: Label = quest_container.get_node_or_null("Quest_" + quest_id) as Label
	if label:
		var qt: _QuestTracker = AutoloadHelper.quest_tracker()
		if qt:
			var active_quests: Array[Dictionary] = qt.get_active_quests()
			for q: Dictionary in active_quests:
				if q["id"] == quest_id:
					_update_quest_label(label, q)
					break


func update_player_stats(entity: Entity) -> void:
	hp_bar.max_value = entity.hp_max
	hp_bar.value = entity.hp
	hp_label.text = "%d / %d" % [entity.hp, entity.hp_max]

	ap_bar.max_value = GameConstants.AP_MAX
	ap_bar.value = entity.ap
	ap_label.text = "%d / %d" % [entity.ap, GameConstants.AP_MAX]


func log_action(message: String) -> void:
	prompts.text = message


func _on_hp_changed(_new_hp: int, _old_hp: int) -> void:
	update_player_stats(_player_entity)


func _on_ap_changed(_new_ap: int, _old_ap: int) -> void:
	update_player_stats(_player_entity)


func _on_turn_started(entity: Entity, is_player: bool) -> void:
	if is_player:
		turn_label.text = "Your Turn"
		turn_label.modulate = Color.GREEN
		_enable_action_buttons(true)
		log_action("PLAYER TURN")
	else:
		turn_label.text = "Enemy Turn: %s" % entity.entity_name
		turn_label.modulate = Color.RED
		_enable_action_buttons(false)
		log_action("ENEMY TURN: %s" % entity.entity_name)


func _on_round_started(round_number: int) -> void:
	round_label.text = "Round %d" % round_number
	log_action("ROUND %d" % round_number)


func _on_targeting_started() -> void:
	log_action("SELECT TARGET")


func _on_attack_executed(target: Node2D, damage: int) -> void:
	var target_name: String = "Enemy"
	if target.has_method("get_entity_name"):
		target_name = target.call("get_entity_name")
	elif target.get("entity"):
		target_name = target.get("entity").entity_name

	log_action("Dealt %d damage to %s" % [damage, target_name])


func _on_move_pressed() -> void:
	log_action("USE WASD TO MOVE")


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

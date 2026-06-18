class_name _VictoryModal
extends Control
## VictoryModal
## Displayed when the player wins a combat encounter.

var _summary_data: Dictionary = {}

@onready var title_label: Label = %TitleLabel
@onready var summary_container: VBoxContainer = %SummaryContainer
@onready var continue_button: Button = %ContinueButton
@onready var _margin_container: MarginContainer = %MarginContainer


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_setup_from_config()
	continue_button.text = tr("HUD_VICTORY_CONTINUE")

	# SafeZone support
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz:
		sz.safe_area_changed.connect(_on_safe_area_changed)
		_apply_safe_area()

	# Focus management
	continue_button.grab_focus.call_deferred()

	# Fade-in animation
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _exit_tree() -> void:
	if continue_button and continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.disconnect(_on_continue_pressed)

	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz and sz.safe_area_changed.is_connected(_on_safe_area_changed):
		sz.safe_area_changed.disconnect(_on_safe_area_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("combat_confirm"):
		_on_continue_pressed()
		get_viewport().set_input_as_handled()


func setup(p_summary_data: Dictionary) -> void:
	_summary_data = p_summary_data
	_update_summary_display()


func _setup_from_config() -> void:
	var config: _ConfigLoader = AutoloadHelper.config_loader()
	if not config:
		return

	var victory_config: Dictionary = config.getValue("end_screens", "victory", {})
	if victory_config.has("title_key"):
		title_label.text = tr(victory_config["title_key"])


func _update_summary_display() -> void:
	# Clear previous
	for child: Node in summary_container.get_children():
		child.queue_free()

	var config: _ConfigLoader = AutoloadHelper.config_loader()
	if not config:
		return

	var victory_config: Dictionary = config.getValue("end_screens", "victory", {})
	var summary_keys: Array = victory_config.get("summary_keys", [])

	# Mapping of keys to summary data values
	var key_map: Dictionary = {
		"HUD_SUMMARY_TURNS": _summary_data.get("turns", 0),
		"HUD_SUMMARY_KILLS": _summary_data.get("kills", 0),
		"HUD_SUMMARY_SHARDS": _summary_data.get("shards", 0)
	}

	for key: String in summary_keys:
		if key_map.has(key):
			var lbl: Label = Label.new()
			var template: String = tr(key)
			if "%d" in template or "%s" in template:
				lbl.text = template % key_map[key]
			else:
				lbl.text = template + ": " + str(key_map[key])
			summary_container.add_child(lbl)


func _on_continue_pressed() -> void:
	# Transition back to run manager or next room
	var rm: _RunManager = AutoloadHelper.run_manager()
	if rm:
		rm.cmd_next_room()
	queue_free()


func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()


func _apply_safe_area() -> void:
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz == null or _margin_container == null:
		return
	var margins: Dictionary = sz.get_safe_margins()
	_margin_container.add_theme_constant_override("margin_left", margins.left)
	_margin_container.add_theme_constant_override("margin_top", margins.top)
	_margin_container.add_theme_constant_override("margin_right", margins.right)
	_margin_container.add_theme_constant_override("margin_bottom", margins.bottom)

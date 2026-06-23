class_name _VictoryModal
extends Control
## VictoryModal
## Displayed when the player wins a combat encounter.

var _summary_data: Dictionary = {}

@onready var title_label: Label = %TitleLabel
@onready var summary_container: VBoxContainer = %SummaryContainer
@onready var continue_button: Button = %ContinueButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_return_to_menu_pressed)
	_setup_from_config()
	continue_button.text = "RETURN TO MENU"


func _exit_tree() -> void:
	if continue_button and continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.disconnect(_on_continue_pressed)
	if menu_button and menu_button.pressed.is_connected(_on_return_to_menu_pressed):
		menu_button.pressed.disconnect(_on_return_to_menu_pressed)


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

	# Append narrative flavor line
	var narrative: String = _select_victory_narrative()
	if not narrative.is_empty():
		var narr_lbl: Label = Label.new()
		narr_lbl.text = narrative
		narr_lbl.add_theme_font_size_override("font_size", 14)
		narr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		narr_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_container.add_child(narr_lbl)


func _select_victory_narrative() -> String:
	"""Select a victory narrative variant deterministically from room_index + MWT."""
	var rm: _RunManager = AutoloadHelper.run_manager()
	var room_idx: int = rm.room_index if rm else 0

	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	var mwt_level: int = bm.current_mwt_level if bm else 0

	# Deterministic selection: combine room index and MWT level
	var variant_index: int = DeterministicMath.absi(room_idx + mwt_level * 3) % 5
	var key: String = "VICTORY_NARRATIVE_%d" % (variant_index + 1)
	var text: String = tr(key)
	# If key is missing from localization, tr() returns the key itself — guard against that
	if text == key or text.begins_with("VICTORY_NARRATIVE"):
		return ""
	return text


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	queue_free()


func _on_return_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	queue_free()

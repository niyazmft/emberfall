class_name _DefeatModal
extends Control
## DefeatModal
## Displayed when the player loses a combat encounter.

var _summary_data: Dictionary = {}

@onready var title_label: Label = %TitleLabel
@onready var summary_container: VBoxContainer = %SummaryContainer
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_return_to_menu_pressed)
	_setup_from_config()
	retry_button.text = tr("HUD_DEFEAT_RETRY")


func _exit_tree() -> void:
	if retry_button and retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.disconnect(_on_retry_pressed)
	if menu_button and menu_button.pressed.is_connected(_on_return_to_menu_pressed):
		menu_button.pressed.disconnect(_on_return_to_menu_pressed)


func setup(p_summary_data: Dictionary) -> void:
	_summary_data = p_summary_data
	_update_summary_display()


func _setup_from_config() -> void:
	var config: _ConfigLoader = AutoloadHelper.config_loader()
	if not config:
		return

	var defeat_config: Dictionary = config.getValue("end_screens", "defeat", {})
	if defeat_config.has("title_key"):
		title_label.text = tr(defeat_config["title_key"])


func _update_summary_display() -> void:
	# Clear previous
	for child: Node in summary_container.get_children():
		child.queue_free()

	var config: _ConfigLoader = AutoloadHelper.config_loader()
	if not config:
		return

	var defeat_config: Dictionary = config.getValue("end_screens", "defeat", {})
	var summary_keys: Array = defeat_config.get("summary_keys", [])

	# Mapping of keys to summary data values
	var key_map: Dictionary = {
		"HUD_SUMMARY_TURNS": _summary_data.get("turns", 0),
		"HUD_SUMMARY_ROOMS": _summary_data.get("rooms", 0)
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
	var narrative: String = _select_defeat_narrative()
	if not narrative.is_empty():
		var narr_lbl: Label = Label.new()
		narr_lbl.text = narrative
		narr_lbl.add_theme_font_size_override("font_size", 16)
		narr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		narr_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_container.add_child(narr_lbl)


func _select_defeat_narrative() -> String:
	"""Select a defeat narrative variant deterministically from room_index + MWT."""
	var rm: _RunManager = AutoloadHelper.run_manager()
	var room_idx: int = rm.room_index if rm else 0

	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	var mwt_level: int = bm.current_mwt_level if bm else 0

	# Deterministic selection: combine room index and MWT level
	var variant_index: int = DeterministicMath.absi(room_idx + mwt_level * 3 + 1) % 5
	var key: String = "DEFEAT_NARRATIVE_%d" % (variant_index + 1)
	var text: String = tr(key)
	if text == key or text.begins_with("DEFEAT_NARRATIVE"):
		return ""
	return text


func _on_retry_pressed() -> void:
	get_tree().paused = false
	queue_free()

	var rm: _RunManager = AutoloadHelper.run_manager()
	if rm:
		rm.cmd_restart_room()


func _on_return_to_menu_pressed() -> void:
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

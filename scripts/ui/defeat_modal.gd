class_name _DefeatModal
extends Control
## DefeatModal
## Displayed when the player loses a combat encounter.

var _summary_data: Dictionary = {}

@onready var title_label: Label = %TitleLabel
@onready var summary_container: VBoxContainer = %SummaryContainer
@onready var retry_button: Button = %RetryButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	_setup_from_config()
	retry_button.text = tr("HUD_DEFEAT_RETRY")


func _exit_tree() -> void:
	if retry_button and retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.disconnect(_on_retry_pressed)


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


func _on_retry_pressed() -> void:
	# Typically would reload main menu or restart run
	var rm: _RunManager = AutoloadHelper.run_manager()
	if rm:
		rm.cmd_start_run(GameConstants.GOLDEN_SEED)
	queue_free()

extends Control
## DefeatModal
## Displayed when the player loses a combat encounter.

@onready var title_label: Label = %TitleLabel
@onready var summary_container: VBoxContainer = %SummaryContainer
@onready var retry_button: Button = %RetryButton

var _summary_data: Dictionary = {}


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	_setup_from_config()


func setup(summary_data: Dictionary) -> void:
	_summary_data = summary_data
	_update_summary_display()


func _setup_from_config() -> void:
	var config: Node = AutoloadHelper.config_loader()
	if not config:
		return

	var defeat_config: Dictionary = config.getValue("end_screens", "defeat", {})
	if defeat_config.has("title_key"):
		title_label.text = tr(defeat_config["title_key"])


func _update_summary_display() -> void:
	# Clear previous
	for child in summary_container.get_children():
		child.queue_free()

	var config: Node = AutoloadHelper.config_loader()
	if not config:
		return

	var defeat_config: Dictionary = config.getValue("end_screens", "defeat", {})
	var summary_keys: Array = defeat_config.get("summary_keys", [])

	# Mapping of keys to summary data values
	var key_map := {
		"HUD_SUMMARY_TURNS": _summary_data.get("turns", 0),
		"HUD_SUMMARY_ROOMS": _summary_data.get("rooms", 0)
	}

	for key in summary_keys:
		if key_map.has(key):
			var lbl := Label.new()
			lbl.text = tr(key) % key_map[key]
			summary_container.add_child(lbl)


func _on_retry_pressed() -> void:
	# Typically would reload main menu or restart run
	var rm := AutoloadHelper.run_manager()
	if rm:
		# rm.restart_run() - hypothetical
		pass
	queue_free()

extends Control
## VictoryModal
## Displayed when the player wins a combat encounter.

@onready var title_label: Label = %TitleLabel
@onready var summary_container: VBoxContainer = %SummaryContainer
@onready var continue_button: Button = %ContinueButton

var _summary_data: Dictionary = {}


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_setup_from_config()


func setup(summary_data: Dictionary) -> void:
	_summary_data = summary_data
	_update_summary_display()


func _setup_from_config() -> void:
	var config: Node = AutoloadHelper.config_loader()
	if not config:
		return

	var victory_config: Dictionary = config.getValue("end_screens", "victory", {})
	if victory_config.has("title_key"):
		title_label.text = tr(victory_config["title_key"])


func _update_summary_display() -> void:
	# Clear previous
	for child in summary_container.get_children():
		child.queue_free()

	var config: Node = AutoloadHelper.config_loader()
	if not config:
		return

	var victory_config: Dictionary = config.getValue("end_screens", "victory", {})
	var summary_keys: Array = victory_config.get("summary_keys", [])

	# Mapping of keys to summary data values
	var key_map := {
		"HUD_SUMMARY_TURNS": _summary_data.get("turns", 0),
		"HUD_SUMMARY_KILLS": _summary_data.get("kills", 0),
		"HUD_SUMMARY_SHARDS": _summary_data.get("shards", 0)
	}

	for key in summary_keys:
		if key_map.has(key):
			var lbl := Label.new()
			lbl.text = tr(key) % key_map[key]
			summary_container.add_child(lbl)


func _on_continue_pressed() -> void:
	# Transition back to run manager or next room
	var rm := AutoloadHelper.run_manager()
	if rm:
		# rm.transition_to_next_room() - hypothetical
		pass
	queue_free()

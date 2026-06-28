class_name _TutorialOverlay
extends Control
## TutorialOverlay
## Displays control hints for new players on first combat entry.
## Dismissed via Escape key or "Got it" button.

signal dismissed

@onready var _panel: PanelContainer = $MarginContainerTopRight/PanelContainer
@onready var _title_label: Label = %TitleLabel
@onready var _hint_list: VBoxContainer = %HintList
@onready var _got_it_button: Button = %GotItButton

var _is_dismissed: bool = false


func _ready() -> void:
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_got_it_button.pressed.connect(_on_got_it_pressed)
	_title_label.text = tr("TUTORIAL_TITLE")
	_populate_hints()
	process_mode = PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if not visible or _is_dismissed:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		accept_event()
		_dismiss()


func show_tutorial() -> void:
	if _is_dismissed:
		return
	visible = true
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.3)


func _on_got_it_pressed() -> void:
	_dismiss()


func _dismiss() -> void:
	if _is_dismissed:
		return
	_is_dismissed = true
	var tween: Tween = create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(
		func() -> void:
			visible = false
			dismissed.emit()
	)


func _populate_hints() -> void:
	var hints: Array[Dictionary] = [
		{"key": "WASD", "text_key": "TUTORIAL_MOVE"},
		{"key": "SPACE", "text_key": "TUTORIAL_ATTACK"},
		{"key": "TAB", "text_key": "TUTORIAL_CYCLE"},
		{"key": "ENTER", "text_key": "TUTORIAL_CONFIRM"},
		{"key": "ESC", "text_key": "TUTORIAL_PAUSE"},
	]

	for hint: Dictionary in hints:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var key_label: Label = Label.new()
		key_label.text = hint["key"]
		key_label.modulate = Color(0.9, 0.75, 0.2)
		key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var desc_label: Label = Label.new()
		desc_label.text = tr(hint["text_key"])
		desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		row.add_child(key_label)
		row.add_child(desc_label)
		_hint_list.add_child(row)

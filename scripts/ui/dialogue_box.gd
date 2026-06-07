extends Control

## DialogueBox
## UI component that displays narrative dialogue lines.
## Binds to DialogueManager and handles localized text presentation.

@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var portrait_texture: TextureRect = %PortraitTexture
@onready var continue_indicator: Control = %ContinueIndicator

var _current_dialogue: Dictionary = {}
var _current_line_index: int = -1
var _is_typing: bool = false


func _ready() -> void:
	hide()
	if DialogueManager:
		DialogueManager.dialogue_requested.connect(_on_dialogue_requested)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("combat_confirm"):
		_advance_dialogue()


func _on_dialogue_requested(dialogue_id: String) -> void:
	_current_dialogue = DialogueManager.get_dialogue(dialogue_id)
	if _current_dialogue.is_empty():
		return

	_current_line_index = 0
	show()
	_display_current_line()
	DialogueManager.dialogue_started.emit(dialogue_id)


func _display_current_line() -> void:
	var lines: Array = _current_dialogue.get("lines", [])
	if _current_line_index < 0 or _current_line_index >= lines.size():
		_finish_dialogue()
		return

	var line: Dictionary = lines[_current_line_index]
	speaker_label.text = tr(line.get("speaker", ""))
	dialogue_text.text = tr(line.get("text_key", ""))

	# Portrait handling (placeholder)
	var portrait_id: String = line.get("portrait", "")
	if not portrait_id.is_empty():
		# In a full implementation, we'd load the texture from a registry
		_print_debug("Displaying portrait: %s" % portrait_id)

	_is_typing = true
	dialogue_text.visible_ratio = 0.0
	var tween := create_tween()
	tween.tween_property(dialogue_text, "visible_ratio", 1.0, 0.5)
	tween.finished.connect(func() -> void: _is_typing = false)

	continue_indicator.visible = (_current_line_index < lines.size() - 1)


func _advance_dialogue() -> void:
	if _is_typing:
		# Skip typing animation
		dialogue_text.visible_ratio = 1.0
		_is_typing = false
		return

	_current_line_index += 1
	var lines: Array = _current_dialogue.get("lines", [])
	if _current_line_index < lines.size():
		_display_current_line()
	else:
		_finish_dialogue()


func _finish_dialogue() -> void:
	var dialogue_id: String = ""
	# Find dialogue_id if needed, or we can just emit generic finished
	hide()
	DialogueManager.dialogue_finished.emit("")


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("DialogueBox: %s" % msg)

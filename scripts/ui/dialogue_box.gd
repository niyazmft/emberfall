extends Control

## DialogueBox
## UI component that displays narrative dialogue lines.
## Binds to DialogueManager and handles localized text presentation.

@onready var speakerLabel: Label = %SpeakerLabel
@onready var dialogueText: RichTextLabel = %DialogueText
@onready var portraitTexture: TextureRect = %PortraitTexture
@onready var continueIndicator: Control = %ContinueIndicator
@onready var continueHintLabel: Label = %ContinueIndicator/Label

var _currentDialogue: Dictionary = {}
var _currentDialogueId: String = ""
var _currentLineIndex: int = -1
var _isTyping: bool = false


func _ready() -> void:
	hide()
	speakerLabel.text = tr("dialogue.ui.speaker_default")
	dialogueText.text = tr("dialogue.ui.text_default")
	continueHintLabel.text = tr("dialogue.ui.continue_hint")
	var dm: _DialogueManager = AutoloadHelper.dialogue_manager()
	if dm:
		dm.dialogue_requested.connect(_onDialogueRequested)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("combat_confirm"):
		_advanceDialogue()


func _onDialogueRequested(dialogueId: String) -> void:
	var dm: _DialogueManager = AutoloadHelper.dialogue_manager()
	if not dm:
		return

	_currentDialogue = dm.get_dialogue(dialogueId)
	if _currentDialogue.is_empty():
		return

	_currentDialogueId = dialogueId
	_currentLineIndex = 0
	show()
	_displayCurrentLine()
	dm.dialogue_started.emit(dialogueId)


func _displayCurrentLine() -> void:
	var lines: Array = _currentDialogue.get("lines", [])
	if _currentLineIndex < 0 or _currentLineIndex >= lines.size():
		_finishDialogue()
		return

	var line: Dictionary = lines[_currentLineIndex]
	speakerLabel.text = tr(line.get("speaker", ""))
	dialogueText.text = tr(line.get("text_key", ""))

	# Portrait handling (placeholder)
	var portraitId: String = line.get("portrait", "")
	if not portraitId.is_empty():
		# In a full implementation, we'd load the texture from a registry
		_printDebug("Displaying portrait: %s" % portraitId)

	_isTyping = true
	dialogueText.visible_ratio = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(dialogueText, "visible_ratio", 1.0, 0.5)
	tween.finished.connect(func() -> void: _isTyping = false)

	continueIndicator.visible = (_currentLineIndex < lines.size() - 1)


func _advanceDialogue() -> void:
	if _isTyping:
		# Skip typing animation
		dialogueText.visible_ratio = 1.0
		_isTyping = false
		return

	_currentLineIndex += 1
	var lines: Array = _currentDialogue.get("lines", [])
	if _currentLineIndex < lines.size():
		_displayCurrentLine()
	else:
		_finishDialogue()


func _finishDialogue() -> void:
	hide()
	var dm: _DialogueManager = AutoloadHelper.dialogue_manager()
	if dm:
		dm.dialogue_finished.emit(_currentDialogueId)
	_currentDialogueId = ""


func _printDebug(msg: String) -> void:
	if OS.is_debug_build():
		print("DialogueBox: %s" % msg)

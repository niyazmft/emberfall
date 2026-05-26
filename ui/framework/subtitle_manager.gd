extends Control

## SubtitleManager
## UI component that renders captions based on CaptionManager events.
## Implementation of DON-222 requirement: isolate BURDEN channel.

const CAPTION_LABEL_SCENE = null  ## In a real app, this would be a PackedScene for a styled label

@onready var surface_dialogue: VBoxContainer = $SurfaceDialogue
@onready var surface_burden: VBoxContainer = $SurfaceBurden

var _active_labels: Dictionary = {}  ## CaptionEvent -> Label


func _ready() -> void:
	if not CaptionManager:
		push_error("SubtitleManager: CaptionManager autoload not found.")
		return

	CaptionManager.caption_display_requested.connect(_on_caption_display_requested)
	CaptionManager.caption_completed.connect(_on_caption_completed)


func _process(_delta: float) -> void:
	## Update opacities for active captions
	for event: Resource in _active_labels.keys():
		var label: Label = _active_labels[event] as Label
		if event.has_method("opacity"):
			label.modulate.a = float(event.call("opacity"))


func _on_caption_display_requested(event: Resource) -> void:
	var label: Label = Label.new()
	label.text = str(event.get("text"))
	if not str(event.get("localization_key")).is_empty():
		label.text = tr(str(event.get("localization_key")))

	## Styling (minimal for prototype)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var target_surface: Control = surface_dialogue
	if int(event.get("surface_group")) == 1:  ## BURDEN isolated surface
		target_surface = surface_burden
		label.add_theme_color_override("font_color", Color.VIOLET)  ## Distinct color for Burden

	target_surface.add_child(label)
	_active_labels[event] = label


func _on_caption_completed(event: Resource) -> void:
	if _active_labels.has(event):
		var label: Label = _active_labels[event] as Label
		_active_labels.erase(event)
		label.queue_free()

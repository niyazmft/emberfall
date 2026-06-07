extends Control

## TutorialOverlay
## Binding layer that displays tutorial steps and instructional text.

@onready var title_label: Label = %Title as Label
@onready var body_label: Label = %Body as Label
@onready var next_button: Button = %NextButton as Button
@onready var panel_container: PanelContainer = $PanelContainer
@onready var highlight_frame: TextureRect = %HighlightFrame as TextureRect
@onready var arrow: TextureRect = %Arrow as TextureRect


func _ready() -> void:
	hide()
	var tm: _TutorialManager = AutoloadHelper.tutorial_manager()
	if tm:
		tm.tutorial_step_started.connect(_on_step_started)
		tm.tutorials_finished.connect(hide)

	next_button.pressed.connect(_on_next_pressed)


func _on_step_started(_step_id: String, step_data: Dictionary) -> void:
	title_label.text = tr(step_data.get("title_key", ""))
	body_label.text = tr(step_data.get("body_key", ""))

	var tm: _TutorialManager = AutoloadHelper.tutorial_manager()
	if tm:
		var frame_path := tm.get_asset_path("highlight_frame")
		if not frame_path.is_empty() and ResourceLoader.exists(frame_path):
			highlight_frame.texture = load(frame_path) as Texture2D
			highlight_frame.show()
		else:
			highlight_frame.hide()

		var arrow_path := tm.get_asset_path("arrow_texture")
		if not arrow_path.is_empty() and ResourceLoader.exists(arrow_path):
			arrow.texture = load(arrow_path) as Texture2D
			arrow.show()
		else:
			arrow.hide()

	show()

	# Entrance animation
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _on_next_pressed() -> void:
	var tm: _TutorialManager = AutoloadHelper.tutorial_manager()
	if tm:
		tm.complete_current_step()

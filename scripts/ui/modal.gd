extends Control

@onready var title_label = %Title
@onready var body_label = %Body
@onready var button_row = %ButtonRow
@onready var close_button = %CloseButton

func _ready() -> void:
	close_button.pressed.connect(dismiss)

	# Entrance animation
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	# Grab focus for keyboard/gamepad accessibility
	if close_button:
		close_button.grab_focus()


func setup(title_key: String, body_key: String) -> void:
	title_label.text = tr(title_key)
	body_label.text = tr(body_key)

func dismiss() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)

class_name _Modal
extends Control

@onready var title_label: Label = %Title as Label
@onready var body_label: Label = %Body as Label
@onready var button_row: HBoxContainer = %ButtonRow as HBoxContainer
@onready var close_button: Button = %CloseButton as Button


func _ready() -> void:
	close_button.pressed.connect(dismiss)

	# Entrance animation
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)


func setup(title_key: String, body_key: String) -> void:
	if not is_node_ready():
		await ready
	if title_label:
		title_label.text = tr(title_key)
	if body_label:
		body_label.text = tr(body_key)


func dismiss() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)

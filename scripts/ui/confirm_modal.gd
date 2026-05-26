extends "res://scripts/ui/modal.gd"

signal confirmed

@onready var confirm_button = %ConfirmButton

func _ready() -> void:
	super._ready()
	confirm_button.pressed.connect(_on_confirm_pressed)

	# Override default focus to the primary action
	confirm_button.grab_focus()

func _on_confirm_pressed() -> void:
	confirmed.emit()
	dismiss()

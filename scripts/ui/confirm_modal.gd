extends _Modal

signal confirmed

@onready var confirm_button: Button = %ConfirmButton as Button

func _ready() -> void:
	super._ready()
	confirm_button.pressed.connect(_on_confirm_pressed)

func _on_confirm_pressed() -> void:
	confirmed.emit()
	dismiss()

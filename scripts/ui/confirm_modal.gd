extends _Modal

signal confirmed

@onready var confirm_button: Button = %ConfirmButton as Button


func _ready() -> void:
	super._ready()
	confirm_button.pressed.connect(_on_confirm_pressed)

	# Override default focus to the primary action
	if confirm_button:
		confirm_button.grab_focus.call_deferred()


func _on_confirm_pressed() -> void:
	confirmed.emit()
	dismiss()

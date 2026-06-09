extends _Modal

signal confirmed

@onready var confirm_button: Button = %ConfirmButton as Button


func _ready() -> void:
	super._ready()
	confirm_button.pressed.connect(_on_confirm_pressed)

	# Override default focus to the primary action
	if confirm_button:
		confirm_button.grab_focus.call_deferred()


func _exit_tree() -> void:
	if confirm_button and confirm_button.pressed.is_connected(_on_confirm_pressed):
		confirm_button.pressed.disconnect(_on_confirm_pressed)
	super._exit_tree()


func _on_confirm_pressed() -> void:
	confirmed.emit()
	dismiss()

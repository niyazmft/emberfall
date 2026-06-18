extends _Modal

const BLOCK_TIME: float = 2.0

var _block_timer: SceneTreeTimer


func _ready() -> void:
	super._ready()

	# Block skip button initially
	close_button.disabled = true
	close_button.modulate.a = 0.0

	_block_timer = get_tree().create_timer(BLOCK_TIME)
	_block_timer.timeout.connect(_on_block_timer_timeout)


func _exit_tree() -> void:
	if _block_timer and _block_timer.timeout.is_connected(_on_block_timer_timeout):
		_block_timer.timeout.disconnect(_on_block_timer_timeout)
	super._exit_tree()


func _on_block_timer_timeout() -> void:
	close_button.disabled = false
	var tween: Tween = create_tween()
	tween.tween_property(close_button, "modulate:a", 1.0, 0.5)
	tween.finished.connect(func() -> void: close_button.grab_focus())

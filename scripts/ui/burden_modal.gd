extends "res://scripts/ui/modal.gd"

const BLOCK_TIME = 2.0

func _ready() -> void:
	super._ready()

	# Block skip button initially
	close_button.disabled = true
	close_button.modulate.a = 0.0

	var timer = get_tree().create_timer(BLOCK_TIME)
	timer.timeout.connect(_on_block_timer_timeout)

func _on_block_timer_timeout() -> void:
	close_button.disabled = false
	var tween = create_tween()
	tween.tween_property(close_button, "modulate:a", 1.0, 0.5)

extends Control

signal finished

@onready var panel = $Panel
@onready var label = $Panel/Label

func display(text_key: String, type: int, duration: float) -> void:
	label.text = tr(text_key)

	# Basic color coding for ToastTypes T-01 to T-05
	match type:
		0: # T_01 INFO
			panel.self_modulate = Color(0.2, 0.2, 0.2)
		1: # T_02 SUCCESS
			panel.self_modulate = Color(0.1, 0.4, 0.1)
		2: # T_03 WARNING
			panel.self_modulate = Color(0.4, 0.4, 0.1)
		3: # T_04 ERROR
			panel.self_modulate = Color(0.5, 0.1, 0.1)
		4: # T_05 SYSTEM
			panel.self_modulate = Color(0.3, 0.3, 0.5)

	# Initial state for animation
	modulate.a = 0.0
	panel.position.y += 50

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "position:y", panel.position.y - 50, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(duration).timeout

	var fade_out = create_tween().set_parallel(true)
	fade_out.tween_property(self, "modulate:a", 0.0, 0.3)
	fade_out.tween_property(panel, "position:y", panel.position.y + 50, 0.3)
	await fade_out.finished

	finished.emit()
	queue_free()

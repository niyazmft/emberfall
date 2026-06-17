class_name _ToastWidget
extends Control

signal finished

@onready var panel: PanelContainer = $Panel as PanelContainer
@onready var label: Label = $Panel/Label as Label


func display(text_key: String, type: int, duration: float) -> void:
	label.text = tr(text_key)

	# Basic color coding for ToastTypes T-01 to T-05
	match type:
		1:  # INFO (T_01)
			panel.self_modulate = Color(0.2, 0.2, 0.2)
		2:  # SUCCESS (T_02)
			panel.self_modulate = Color(0.1, 0.4, 0.1)
		3:  # WARNING (T_03)
			panel.self_modulate = Color(0.4, 0.4, 0.1)
		4:  # ERROR (T_04)
			panel.self_modulate = Color(0.5, 0.1, 0.1)
		5:  # SYSTEM (T_05)
			panel.self_modulate = Color(0.3, 0.3, 0.5)

	# Initial state for animation
	modulate.a = 0.0
	panel.position.y += 50

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	(
		tween
		. tween_property(panel, "position:y", panel.position.y - 50, 0.3)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)

	get_tree().create_timer(duration).timeout.connect(
		func() -> void:
			if not is_inside_tree():
				return
			var fade_out: Tween = create_tween().set_parallel(true)
			fade_out.tween_property(self, "modulate:a", 0.0, 0.3)
			fade_out.tween_property(panel, "position:y", panel.position.y + 50, 0.3)
			fade_out.finished.connect(
				func() -> void:
					finished.emit()
					queue_free()
			)
	)

class_name _ButtonAnimator
extends Node
## Utility that applies Tween micro-animations to all Button descendants.

const HOVER_SCALE: float = 1.05
const PRESS_SCALE: float = 0.95
const HOVER_DURATION: float = 0.15
const PRESS_DURATION: float = 0.05


func apply_to_buttons(root: Control) -> void:
	for child: Node in root.get_children(true):
		if child is Button:
			_wire_button(child as Button)


func _wire_button(btn: Button) -> void:
	if btn.mouse_entered.is_connected(_on_hover_entered.bind(btn)):
		return
	btn.mouse_entered.connect(_on_hover_entered.bind(btn))
	btn.mouse_exited.connect(_on_hover_exited.bind(btn))
	btn.button_down.connect(_on_button_down.bind(btn))
	btn.button_up.connect(_on_button_up.bind(btn))


func _on_hover_entered(btn: Button) -> void:
	_tween_scale(btn, HOVER_SCALE, HOVER_DURATION)


func _on_hover_exited(btn: Button) -> void:
	_tween_scale(btn, 1.0, HOVER_DURATION)


func _on_button_down(btn: Button) -> void:
	_tween_scale(btn, PRESS_SCALE, PRESS_DURATION)


func _on_button_up(btn: Button) -> void:
	_tween_scale(btn, 1.0, PRESS_DURATION)


func _tween_scale(target: Button, scale_val: float, duration: float) -> void:
	var tween: Tween = target.create_tween()
	tween.tween_property(target, "scale", Vector2(scale_val, scale_val), duration)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

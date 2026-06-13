class_name _LayerManager
extends CanvasLayer

## LayerManager
## Manages UI layers, modal suppression, and background dimming.

signal modal_opened
signal modal_closed

var _modal_stack: Array[Node] = []
var _dim_rect: ColorRect
var _dim_tween: Tween
var _pp_rect: ColorRect


func _ready() -> void:
	layer = 100  # Ensure UI is on top
	_setup_pp_rect()
	_dim_rect = ColorRect.new()
	_dim_rect.color = Color(0, 0, 0, 0)
	_dim_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_rect.visible = false
	add_child(_dim_rect)


func _setup_pp_rect() -> void:
	_pp_rect = ColorRect.new()
	_pp_rect.name = "BurdenPostProcess"
	_pp_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pp_rect.visible = false

	var shader: Shader = load("res://assets/shaders/pp_burden_master.gdshader") as Shader
	if shader:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = shader
		_pp_rect.material = mat
		_print_debug("Initialized master post-process shader")

	add_child(_pp_rect)

	var bsm: _BurdenShaderManager = AutoloadHelper.burden_shader_manager()
	if bsm and bsm.has_method("register_pp_rect"):
		bsm.call("register_pp_rect", _pp_rect)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("LayerManager: %s" % msg)


func add_modal(modal: Node) -> void:
	if not _modal_stack.is_empty():
		var prev: Node = _modal_stack.back()
		var tween: Tween = create_tween()
		tween.tween_property(prev, "modulate:a", 0.0, 0.1)  # 100ms fade per requirement
		tween.finished.connect(prev.queue_free)
		_modal_stack.pop_back()

	_modal_stack.append(modal)
	add_child(modal)

	if modal is Control:
		FocusManager.push_modal_focus(modal as Control)

	_update_dim(true)
	modal_opened.emit()

	modal.tree_exited.connect(_on_modal_exited.bind(modal))


func _on_modal_exited(modal: Node) -> void:
	_modal_stack.erase(modal)

	if modal is Control:
		FocusManager.pop_modal_focus()

	if _modal_stack.is_empty():
		_update_dim(false)
		modal_closed.emit()


func _update_dim(show_dim: bool) -> void:
	if _dim_tween and _dim_tween.is_valid():
		_dim_tween.kill()

	_dim_tween = create_tween()
	var target_alpha: float = 0.5 if show_dim else 0.0

	if show_dim:
		_dim_rect.visible = true
		_dim_tween.tween_property(_dim_rect, "color:a", target_alpha, 0.2)
	else:
		_dim_tween.tween_property(_dim_rect, "color:a", target_alpha, 0.2)
		_dim_tween.finished.connect(func() -> void: _dim_rect.visible = false)


func is_modal_active() -> bool:
	return not _modal_stack.is_empty()

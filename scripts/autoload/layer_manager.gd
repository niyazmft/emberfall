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
var _pause_menu: PauseMenu


func _ready() -> void:
	layer = 100  # Ensure UI is on top
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_pp_rect()
	_dim_rect = ColorRect.new()
	_dim_rect.color = Color(0, 0, 0, 0)
	_dim_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_rect.visible = false
	add_child(_dim_rect)

	var pause_scene: PackedScene = load("res://scenes/ui/pause_menu.tscn") as PackedScene
	if pause_scene:
		_pause_menu = pause_scene.instantiate() as PauseMenu
		add_child(_pause_menu)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var current_scene := get_tree().current_scene
		if current_scene != null and current_scene.name == "TitleScreen":
			return

		if not _modal_stack.is_empty():
			var top_modal: Node = _modal_stack.back()
			if top_modal is SettingsModal:
				(top_modal as SettingsModal)._on_back_pressed()
				get_viewport().set_input_as_handled()
			elif top_modal is _ConfirmModal:
				(top_modal as _ConfirmModal)._on_cancel_pressed()
				get_viewport().set_input_as_handled()
			elif top_modal is _Modal:
				(top_modal as _Modal).dismiss()
				get_viewport().set_input_as_handled()
			return

		if _pause_menu != null:
			_pause_menu.toggle_pause()
			get_viewport().set_input_as_handled()


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

	var bsm := AutoloadHelper.burden_shader_manager()
	if bsm:
		bsm.register_pp_rect(_pp_rect)


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
		var fm: _FocusManager = AutoloadHelper.focus_manager()
		if fm:
			fm.push_modal_focus(modal as Control)

	_update_dim(true)
	modal_opened.emit()

	modal.tree_exited.connect(_on_modal_exited.bind(modal))


func _on_modal_exited(modal: Node) -> void:
	_modal_stack.erase(modal)

	if modal is Control:
		var fm: _FocusManager = AutoloadHelper.focus_manager()
		if fm:
			fm.pop_modal_focus()

	if _modal_stack.is_empty():
		_update_dim(false)
		modal_closed.emit()


func _update_dim(show_dim: bool) -> void:
	if _dim_tween and _dim_tween.is_valid():
		_dim_tween.kill()

	_dim_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_dim_tween.set_parallel(true)
	var target_alpha: float = 0.5 if show_dim else 0.0
	var target_blur: float = 3.0 if show_dim else 0.0
	var start_blur: float = 0.0 if show_dim else 3.0

	if show_dim:
		_dim_rect.visible = true
		if _pp_rect != null:
			_pp_rect.visible = true
			if _pp_rect.material is ShaderMaterial:
				var mat := _pp_rect.material as ShaderMaterial
				_dim_tween.tween_method(
					func(val: float) -> void: mat.set_shader_parameter("u_blur_amount", val),
					start_blur,
					target_blur,
					0.2
				)
		_dim_tween.tween_property(_dim_rect, "color:a", target_alpha, 0.2)
	else:
		_dim_tween.tween_property(_dim_rect, "color:a", target_alpha, 0.2)
		if _pp_rect != null and _pp_rect.material is ShaderMaterial:
			var mat := _pp_rect.material as ShaderMaterial
			_dim_tween.tween_method(
				func(val: float) -> void: mat.set_shader_parameter("u_blur_amount", val),
				start_blur,
				target_blur,
				0.2
			)
		_dim_tween.chain().tween_callback(
			func() -> void:
				_dim_rect.visible = false
				if _pp_rect != null:
					_pp_rect.visible = false
		)


func is_modal_active() -> bool:
	return not _modal_stack.is_empty()

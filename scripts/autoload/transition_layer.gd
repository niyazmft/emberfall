class_name _TransitionLayer
extends CanvasLayer
## A global transition layer to handle screen fades and dissolve transitions.

signal fade_completed

@onready var color_rect: ColorRect = ColorRect.new()
var _loading_label: Label
var _transition_count: int = 0
var _shader_material: ShaderMaterial
var _is_fading: bool = false
var _current_tween: Tween = null


func _ready() -> void:
	layer = 100  # Ensure it is on top of everything

	color_rect.color = Color.BLACK
	color_rect.modulate.a = 0.0
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

	_loading_label = Label.new()
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_loading_label.add_theme_font_size_override("font_size", 18)
	_loading_label.modulate.a = 0.0
	_loading_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_loading_label)


func _ensure_shader_material() -> void:
	if _shader_material != null:
		return
	var shader: Shader = load("res://shaders/transition_dissolve.gdshader") as Shader
	if shader == null:
		return
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	_shader_material.set_shader_parameter("progress", 0.0)
	_shader_material.set_shader_parameter("fade_color", Color.BLACK)
	_shader_material.set_shader_parameter("edge_width", 0.1)
	_shader_material.set_shader_parameter("noise_scale", 20.0)
	_shader_material.set_shader_parameter("ember_intensity", 0.8)


func _show_loading_text() -> void:
	## Pick a random lore snippet using a deterministic seed.
	_transition_count += 1
	var seed_val: int = SeedGovernance.hash_int(_transition_count, "loading_lore")
	var idx: int = SeedGovernance.modulo_from_seed(seed_val, "lore_variant", 10)
	var key: String = "LOADING_LORE_%d" % (idx + 1)
	var text: String = tr(key)
	if text == key:
		# Fallback if translation key is missing
		var fallbacks: Array[String] = [
			"The Keepers were twelve. Now they are rumors.",
			"The embers remember what the world forgets.",
			"Every room is a question. Every fight is an answer.",
			"The burden is not carried. It is transferred.",
			"Echoes do not die. They wait.",
			"Stillness is not peace. It is preparation.",
			"The shards sing when no one listens.",
			"What falls may rise. What rises may fall.",
			"The Keepers fell so the world could stand.",
			"Silence is the loudest weight.",
		]
		text = fallbacks[idx]

	_loading_label.text = "[ %s ]" % text
	_loading_label.modulate.a = 1.0


func fade_out(duration: float = 0.5, use_dissolve: bool = false) -> void:
	# Guard against concurrent fade execution
	if _is_fading:
		if _current_tween != null and _current_tween.is_valid():
			_current_tween.kill()
	_is_fading = true

	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks during transition

	if OS.has_feature("headless"):
		color_rect.modulate.a = 1.0
		_is_fading = false
		fade_completed.emit()
		return

	_show_loading_text()

	if use_dissolve:
		_ensure_shader_material()
	if use_dissolve and _shader_material != null:
		color_rect.material = _shader_material
		_current_tween = create_tween()
		_current_tween.tween_method(_set_dissolve_progress, 0.0, 1.0, duration)
		await _current_tween.finished
	else:
		_current_tween = create_tween()
		_current_tween.tween_property(color_rect, "modulate:a", 1.0, duration)
		await _current_tween.finished
	_is_fading = false
	_current_tween = null
	fade_completed.emit()


func fade_in(duration: float = 0.5, use_dissolve: bool = false) -> void:
	if OS.has_feature("headless"):
		color_rect.modulate.a = 0.0
		_loading_label.modulate.a = 0.0
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_is_fading = false
		_current_tween = null
		fade_completed.emit()
		return

	# Always clear dissolve material before non-dissolve fade
	# to prevent shader from overriding modulate-based transparency
	if not use_dissolve:
		color_rect.material = null

	if use_dissolve:
		_ensure_shader_material()
	if use_dissolve and _shader_material != null:
		_current_tween = create_tween()
		_current_tween.tween_method(_set_dissolve_progress, 1.0, 0.0, duration)
		await _current_tween.finished
		color_rect.material = null
	else:
		_current_tween = create_tween()
		_current_tween.tween_property(color_rect, "modulate:a", 0.0, duration)
		await _current_tween.finished
	_is_fading = false
	_current_tween = null
	_loading_label.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_completed.emit()


func _set_dissolve_progress(value: float) -> void:
	if _shader_material != null:
		_shader_material.set_shader_parameter("progress", value)

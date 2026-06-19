class_name _BurdenShaderManager
extends Node

## BurdenShaderManager
## Manages global shader state and VRAM scratch buffer for Burden Events.
## Requirement: DON-263 Engine integration — Burden Event skip-gate & static pool allocation

const SCRATCH_BUFFER_WIDTH: int = 512
const SCRATCH_BUFFER_HEIGHT: int = 256  # 512 * 256 * 4 bytes (RGBA8) = 512 KB

var _scratch_texture: ImageTexture
var _pp_rect: ColorRect = null
var _current_cvd_mode: int = 0


func _ready() -> void:
	_allocate_static_pool()
	_setup_global_parameters()

	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm:
		bm.burden_active_changed.connect(_on_burden_active_changed)
		# Initial sync
		call_deferred("_on_burden_active_changed", bm.burden_active)


func _exit_tree() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm and bm.is_connected("burden_active_changed", _on_burden_active_changed):
		bm.disconnect("burden_active_changed", _on_burden_active_changed)


func _allocate_static_pool() -> void:
	# Pre-allocate the 512 KB VRAM scratch buffer at boot (Static pool allocation)
	var img: Image = Image.create(
		SCRATCH_BUFFER_WIDTH, SCRATCH_BUFFER_HEIGHT, false, Image.FORMAT_RGBA8
	)
	img.fill(Color(0, 0, 0, 0))
	_scratch_texture = ImageTexture.create_from_image(img)
	_print_debug(
		(
			"allocated 512 KB VRAM scratch buffer (%d KB)"
			% [SCRATCH_BUFFER_WIDTH * SCRATCH_BUFFER_HEIGHT * 4 / 1024]
		)
	)


func _setup_global_parameters() -> void:
	# Register global shader parameters for skip-gate and scratch buffer
	# Note: These must be added before they can be set.
	var globals: Array[StringName] = RenderingServer.global_shader_parameter_get_list()
	var has_active: bool = false
	var has_scratch: bool = false
	var has_cvd: bool = false

	for g: StringName in globals:
		if g == &"u_burden_active":
			has_active = true
		if g == &"u_burden_scratch_buffer":
			has_scratch = true
		if g == &"u_cvd_mode":
			has_cvd = true

	if not has_active:
		RenderingServer.global_shader_parameter_add(
			"u_burden_active", RenderingServer.GLOBAL_VAR_TYPE_BOOL, false
		)

	if not has_cvd:
		RenderingServer.global_shader_parameter_add(
			"u_cvd_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, 0
		)

	if not has_scratch:
		RenderingServer.global_shader_parameter_add(
			"u_burden_scratch_buffer", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, _scratch_texture
		)
	else:
		# PR Feedback: Ensure u_burden_scratch_buffer is always set even if already registered.
		RenderingServer.global_shader_parameter_set("u_burden_scratch_buffer", _scratch_texture)


func _on_burden_active_changed(active: bool) -> void:
	# Skip-gate logic: update global uniform
	RenderingServer.global_shader_parameter_set("u_burden_active", active)
	_update_pp_visibility()
	_print_debug("u_burden_active set to %s" % str(active))


## Register the master post-process ColorRect for visibility gating.
func register_pp_rect(rect: ColorRect) -> void:
	_pp_rect = rect
	_update_pp_visibility()


## Sets the color-vision-deficiency (CVD) simulation mode.
## 0: None, 1: Protanopia, 2: Deuteranopia, 3: Tritanopia
func set_cvd_mode(mode: int) -> void:
	_current_cvd_mode = mode
	RenderingServer.global_shader_parameter_set("u_cvd_mode", mode)
	_update_pp_visibility()
	_print_debug("CVD mode set to %d" % mode)


func _update_pp_visibility() -> void:
	if not _pp_rect:
		return

	var burden_active: bool = false
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm:
		burden_active = bm.burden_active

	_pp_rect.visible = burden_active or _current_cvd_mode > 0


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenShaderManager: %s" % msg)

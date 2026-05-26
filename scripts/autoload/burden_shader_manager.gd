extends Node

## BurdenShaderManager
## Manages global shader state and VRAM scratch buffer for Burden Events.
## Requirement: DON-263 Engine integration — Burden Event skip-gate & static pool allocation

const SCRATCH_BUFFER_WIDTH = 512
const SCRATCH_BUFFER_HEIGHT = 256 # 512 * 256 * 4 bytes (RGBA8) = 512 KB

var _scratch_texture: ImageTexture
var _pp_rect: ColorRect = null

func _ready() -> void:
	_allocate_static_pool()
	_setup_global_parameters()

	if BurdenManager:
		BurdenManager.burden_active_changed.connect(_on_burden_active_changed)
		# Initial sync
		call_deferred("_on_burden_active_changed", BurdenManager.burden_active)

func _allocate_static_pool() -> void:
	# Pre-allocate the 512 KB VRAM scratch buffer at boot (Static pool allocation)
	var img := Image.create(SCRATCH_BUFFER_WIDTH, SCRATCH_BUFFER_HEIGHT, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_scratch_texture = ImageTexture.create_from_image(img)
	_print_debug("allocated 512 KB VRAM scratch buffer (%d KB)" % [SCRATCH_BUFFER_WIDTH * SCRATCH_BUFFER_HEIGHT * 4 / 1024])

func _setup_global_parameters() -> void:
	# Register global shader parameters for skip-gate and scratch buffer
	# Note: These must be added before they can be set.
	var globals = RenderingServer.global_shader_parameter_get_list()
	var has_active = false
	var has_scratch = false

	for g in globals:
		if g.name == "u_burden_active": has_active = true
		if g.name == "u_burden_scratch_buffer": has_scratch = true

	if not has_active:
		RenderingServer.global_shader_parameter_add("u_burden_active", RenderingServer.GLOBAL_VAR_TYPE_BOOL, false)

	if not has_scratch:
		RenderingServer.global_shader_parameter_add("u_burden_scratch_buffer", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, _scratch_texture)
	else:
		# PR Feedback: Ensure u_burden_scratch_buffer is always set even if already registered.
		RenderingServer.global_shader_parameter_set("u_burden_scratch_buffer", _scratch_texture)

func _on_burden_active_changed(active: bool) -> void:
	# Skip-gate logic: update global uniform
	RenderingServer.global_shader_parameter_set("u_burden_active", active)

	# Skip-gate logic: Toggle visibility of the resolve pass
	if _pp_rect:
		_pp_rect.visible = active

	_print_debug("u_burden_active set to %s" % str(active))

## Register the master post-process ColorRect for visibility gating.
func register_pp_rect(rect: ColorRect) -> void:
	_pp_rect = rect
	if _pp_rect and BurdenManager:
		_pp_rect.visible = BurdenManager.burden_active

func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenShaderManager: %s" % msg)

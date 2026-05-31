class_name ApparitionRenderer
extends Node2D

## ApparitionRenderer
## Composites up to 3 sentient-kill silhouettes behind the owner entity
## (typically the Keeper). Drives the ApparitionStateMachine and applies
## the apparition tint shader in a single material pass.
##
## References: DON-83 Apparition Composite Render Pipeline
##            Burden Event Asset Spec §2.2
##            DON-267 Apparition Composite Rig (Follow-up)

const STACK_COUNT: int = 3
const TRAIL_COUNT: int = 6
const RIG_CONFIG_PATH: String = "res://data/char_apparition_rig.json"

## Default layout constants (exposed for tests and fallback)
const VERTICAL_OFFSETS: Array[int] = [0, 8, 16]
const OPACITY_TIERS: Array[float] = [0.55, 0.45, 0.35]
const SCALE_TIERS: Array[float] = [1.00, 0.95, 0.90]

## Configuration data from JSON
var _rig_config: Dictionary = {}

## Instance-specific layout (initialized from constants, overridden by config)
var vertical_offsets: Array[int] = [0, 8, 16]
var opacity_tiers: Array[float] = [0.55, 0.45, 0.35]
var scale_tiers: Array[float] = [1.00, 0.95, 0.90]

## Sentinel when no silhouette is available.
const PLACEHOLDER_ATLAS_UID: String = "placeholder:silhouette"

@export var owner_z_index_offset: int = -1:
	set(value):
		owner_z_index_offset = value
		_update_z_index()

@export var recoil_z_index_offset: int = 2

## Current stack of silhouette enemy IDs (oldest → newest).
var _current_stack: PackedStringArray = []

## The three Sprite2D nodes (oldest at index 0).
var _silhouette_sprites: Array[Sprite2D] = []

## The six trail Sprite2D nodes.
var _trail_sprites: Array[Sprite2D] = []
var _trail_timer: float = 0.0
var _trail_index: int = 0
var _master_alpha: float = 1.0

## Shared shader material for tinting.
var _tint_material: ShaderMaterial

## Weak reference to the Keeper / owner entity for transform anchoring.
var _owner: WeakRef

## State machine.
var state_machine: ApparitionStateMachine

## Dissolve noise texture (procedural or loaded).
var _dissolve_noise: NoiseTexture2D

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	_load_rig_config()
	z_index = owner_z_index_offset
	_create_dissolve_noise()
	_create_tint_material()
	_create_stack_sprites()
	_create_trail_sprites()
	state_machine = ApparitionStateMachine.new(self)

	# Listen to BurdenManager for kill history changes.
	if BurdenManager:
		BurdenManager.kill_history_changed.connect(_on_kill_history_changed)
		BurdenManager.burden_active_changed.connect(_on_burden_active_changed)

	# Initial sync.
	if BurdenManager:
		_on_burden_active_changed(BurdenManager.burden_active)
	_refresh_stack()


func _process(delta: float) -> void:
	if state_machine:
		state_machine.update(delta)

	_update_trail(delta)
	_update_shader_uniforms(delta)


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------


func _load_rig_config() -> void:
	if not FileAccess.file_exists(RIG_CONFIG_PATH):
		push_warning(
			"ApparitionRenderer: config file not found at %s. Using defaults." % RIG_CONFIG_PATH
		)
		return

	var file: FileAccess = FileAccess.open(RIG_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: Error = json.parse(json_text)
	if error == OK and json.data is Dictionary:
		_rig_config = json.data as Dictionary
		_apply_rig_config()
	else:
		push_error(
			(
				"ApparitionRenderer: failed to parse JSON config or config is not a Dictionary: %s"
				% json.get_error_message()
			)
		)


func _apply_rig_config() -> void:
	if _rig_config.is_empty():
		return

	var stack: Dictionary = _rig_config.get("stack", {}) as Dictionary
	if not stack.is_empty():
		var v_offsets: Variant = stack.get("vertical_offsets")
		if v_offsets is Array and v_offsets.size() >= STACK_COUNT:
			vertical_offsets.clear()
			for val: Variant in v_offsets:
				vertical_offsets.append(int(val))

		var o_tiers: Variant = stack.get("opacity_tiers")
		if o_tiers is Array and o_tiers.size() >= STACK_COUNT:
			opacity_tiers.clear()
			for val: Variant in o_tiers:
				opacity_tiers.append(float(val))

		var s_tiers: Variant = stack.get("scale_tiers")
		if s_tiers is Array and s_tiers.size() >= STACK_COUNT:
			scale_tiers.clear()
			for val: Variant in s_tiers:
				scale_tiers.append(float(val))

	var recoil: Dictionary = _rig_config.get("recoil", {}) as Dictionary
	if not recoil.is_empty():
		recoil_z_index_offset = int(recoil.get("z_promotion", 2))


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Call when the owner entity is recoiling (e.g. on hit).
func trigger_recoil() -> void:
	if state_machine:
		state_machine.cmd_recoil()


## Call every frame to sync position to owner.
func sync_to_owner(owner_position: Vector2) -> void:
	global_position = owner_position


## Force refresh silhouette stack from BurdenManager.
func refresh_stack() -> void:
	_refresh_stack()


## Set opacity of the entire composite stack (0.0 – 1.0).
## Called by the state machine during manifest / absolve fades.
func set_stack_opacity(alpha: float) -> void:
	_master_alpha = alpha
	for i: int in range(_silhouette_sprites.size()):
		var sprite: Sprite2D = _silhouette_sprites[i]
		var tier_alpha: float = opacity_tiers[i] if i < opacity_tiers.size() else 0.35
		sprite.modulate.a = tier_alpha * alpha


## Promote z-index during recoil.
func promote_z_index() -> void:
	var owner_node: Node2D = _owner.get_ref() as Node2D if _owner else null
	if owner_node:
		z_index = owner_node.z_index + recoil_z_index_offset
	else:
		z_index = owner_z_index_offset + recoil_z_index_offset + 1


## Restore default z-index.
func restore_z_index() -> void:
	var owner_node: Node2D = _owner.get_ref() as Node2D if _owner else null
	if owner_node:
		z_index = owner_node.z_index + owner_z_index_offset
	else:
		z_index = owner_z_index_offset


## Inject owner reference (call after instantiation / reparent).
func bind_owner(owner_entity: Node2D) -> void:
	_owner = weakref(owner_entity)
	_update_z_index()


# ---------------------------------------------------------------------------
# BurdenManager callbacks
# ---------------------------------------------------------------------------


func _on_kill_history_changed(_queue: Array[BurdenManager.BurdenKillRecord]) -> void:
	_refresh_stack()


func _on_burden_active_changed(active: bool) -> void:
	if active:
		if (
			state_machine
			and (
				state_machine.current_state == ApparitionStateMachine.ApparitionState.INACTIVE
				or state_machine.current_state == ApparitionStateMachine.ApparitionState.ERROR
			)
		):
			state_machine.cmd_manifest()
	else:
		if (
			state_machine
			and state_machine.current_state != ApparitionStateMachine.ApparitionState.INACTIVE
		):
			state_machine.cmd_absolve()


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------


func _create_dissolve_noise() -> void:
	_dissolve_noise = NoiseTexture2D.new()
	_dissolve_noise.width = 128
	_dissolve_noise.height = 128
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.frequency = (
		float((_rig_config.get("dissolve", {}) as Dictionary).get("noise_frequency", 4.0)) / 100.0
	)
	_dissolve_noise.noise = noise


func _create_tint_material() -> void:
	var shader: Shader = load("res://scripts/shaders/apparition_composite.gdshader") as Shader
	if shader == null:
		push_warning("ApparitionRenderer: could not load apparition_composite.gdshader")
		return
	_tint_material = ShaderMaterial.new()
	_tint_material.shader = shader

	# Apply colors from config
	var colors: Dictionary = _rig_config.get("colors", {}) as Dictionary
	if not colors.is_empty():
		_tint_material.set_shader_parameter(
			"u_spectral_tint_color", Color(colors.get("spectral_tint", "#2A6F6F"))
		)
		_tint_material.set_shader_parameter(
			"u_inner_bleed_color", Color(colors.get("inner_bleed", "#9A8C98"))
		)
		_tint_material.set_shader_parameter(
			"u_after_trail_color", Color(colors.get("after_image", "#C9ADA7"))
		)

	# Ensure default uniforms match spec §2.2
	_tint_material.set_shader_parameter("u_desaturation_amount", 0.2)
	_tint_material.set_shader_parameter("u_spectral_tint_opacity", 0.4)
	_tint_material.set_shader_parameter("u_inner_bleed_opacity", 0.15)
	_tint_material.set_shader_parameter(
		"u_after_trail_opacity",
		float((_rig_config.get("trail", {}) as Dictionary).get("intensity", 0.2))
	)
	_tint_material.set_shader_parameter("u_intensity", 1.0)

	_tint_material.set_shader_parameter("u_dissolve_noise", _dissolve_noise)


func _create_stack_sprites() -> void:
	# Add in reverse order so Index 0 is on top (rendered last)
	for i: int in range(STACK_COUNT - 1, -1, -1):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Silhouette_%d" % i
		sprite.centered = true
		if _tint_material:
			sprite.material = _tint_material
		# Default layout behind owner
		sprite.position = Vector2(0, -vertical_offsets[i])
		sprite.scale = Vector2(scale_tiers[i], scale_tiers[i])
		sprite.modulate.a = opacity_tiers[i]
		# Keep track of them in the order 0 (front) -> 2 (back) for easier indexing elsewhere
		_silhouette_sprites.insert(0, sprite)
		add_child(sprite)


func _create_trail_sprites() -> void:
	for i: int in range(TRAIL_COUNT):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Trail_%d" % i
		sprite.centered = true
		sprite.top_level = true  # Trail stays in world space
		if _tint_material:
			sprite.material = _tint_material
		sprite.modulate.a = 0.0  # Start invisible
		_trail_sprites.append(sprite)
		add_child(sprite)


func _refresh_stack() -> void:
	if not BurdenManager:
		return
	var ids: PackedStringArray = BurdenManager.get_last_enemy_ids(STACK_COUNT)
	_current_stack = ids

	for i: int in range(STACK_COUNT):
		var sprite: Sprite2D = _silhouette_sprites[i]
		if i < ids.size():
			var tex: Texture2D = BurdenManager.get_silhouette_texture(ids[i])
			if tex:
				sprite.texture = tex
			else:
				sprite.texture = _get_placeholder_texture()
		else:
			sprite.texture = _get_placeholder_texture()
		# Ensure layout constants are reapplied
		sprite.position = Vector2(0, -vertical_offsets[i])
		sprite.scale = Vector2(scale_tiers[i], scale_tiers[i])
		sprite.modulate.a = opacity_tiers[i] * _master_alpha


func _update_shader_uniforms(_delta: float) -> void:
	if not state_machine:
		return

	var dissolve_threshold: float = 0.0
	var shear_intensity: float = 0.0

	# Breathing idle animation
	var breathing: Dictionary = _rig_config.get("breathing", {}) as Dictionary
	var amplitude: float = float(breathing.get("amplitude", 0.08))
	var frequency: float = float(breathing.get("frequency", 2.734))
	var breathing_intensity: float = (
		1.0 + sin(Time.get_ticks_msec() * 0.001 * frequency * TAU) * amplitude
	)

	match state_machine.current_state:
		ApparitionStateMachine.ApparitionState.ABSORB:
			var duration: float = (
				float((_rig_config.get("dissolve", {}) as Dictionary).get("duration_ms", 400))
				/ 1000.0
			)
			dissolve_threshold = clampf(state_machine._absorb_timer / duration, 0.0, 1.0)
		ApparitionStateMachine.ApparitionState.RECOIL:
			var base_shear: float = float(
				(_rig_config.get("recoil", {}) as Dictionary).get("shear_intensity", 1.2)
			)
			# Shear direction depends on owner facing vs. damage source if available,
			# but here we can just use a simple sine jitter or fixed offset.
			# For DON-267, we just ensure it's applied correctly.
			shear_intensity = base_shear

	# Apply to shared material
	if _tint_material:
		_tint_material.set_shader_parameter("u_dissolve_threshold", dissolve_threshold)
		_tint_material.set_shader_parameter("u_shear_intensity", shear_intensity)
		_tint_material.set_shader_parameter("u_intensity", breathing_intensity)


func _update_trail(delta: float) -> void:
	if _trail_sprites.is_empty() or not state_machine:
		return

	if (
		state_machine.current_state == ApparitionStateMachine.ApparitionState.INACTIVE
		or state_machine.current_state == ApparitionStateMachine.ApparitionState.ABSORB
	):
		# Fade out trails if inactive or absorbing
		for sprite: Sprite2D in _trail_sprites:
			sprite.modulate.a = lerpf(sprite.modulate.a, 0.0, delta * 10.0)
		return

	var trail_config: Dictionary = _rig_config.get("trail", {}) as Dictionary
	var lifetime_ms: float = maxf(float(trail_config.get("lifetime_ms", 300)), 1.0)
	var interval: float = (lifetime_ms / 1000.0) / TRAIL_COUNT
	var intensity: float = float(trail_config.get("intensity", 0.2)) * _master_alpha

	_trail_timer += delta
	if _trail_timer >= interval:
		_trail_timer = 0.0

		# Update trail sprite
		var sprite: Sprite2D = _trail_sprites[_trail_index]

		# Pick the front-most silhouette texture for the trail
		if not _silhouette_sprites.is_empty():
			sprite.texture = _silhouette_sprites[0].texture
			sprite.scale = _silhouette_sprites[0].scale

		sprite.global_position = global_position
		sprite.modulate.a = intensity

		_trail_index = (_trail_index + 1) % TRAIL_COUNT

	# Continuous fade for all trail sprites
	var fade_speed: float = 1.0 / (lifetime_ms / 1000.0)
	for sprite: Sprite2D in _trail_sprites:
		if sprite.modulate.a > 0.0:
			sprite.modulate.a = clampf(sprite.modulate.a - delta * fade_speed * intensity, 0.0, 1.0)


func _update_z_index() -> void:
	var owner_node: Node2D = _owner.get_ref() as Node2D if _owner else null
	if owner_node:
		z_index = owner_node.z_index + owner_z_index_offset
	else:
		z_index = owner_z_index_offset


func _get_placeholder_texture() -> Texture2D:
	var cached: Texture2D = BurdenManager.get_silhouette_texture(PLACEHOLDER_ATLAS_UID)
	if cached:
		return cached
	# Create a procedural 64×64 silhouette placeholder (white blob).
	var img: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 1.0))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	BurdenManager.register_silhouette(PLACEHOLDER_ATLAS_UID, tex)
	return tex


func _on_manifested() -> void:
	_print_debug("Manifested signal received")


func _on_absolved() -> void:
	_print_debug("Absolved signal received")


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("ApparitionRenderer: %s" % msg)

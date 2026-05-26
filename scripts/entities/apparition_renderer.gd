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
const RIG_CONFIG_PATH := "res://char_apparition_rig.json"

## Configuration data from JSON
var _rig_config: Dictionary = {}

## Default vertical offsets in pixels (composite stack).
var vertical_offsets: PackedInt32Array = PackedInt32Array([0, 8, 16])

## Opacity tiers (front → back).
var opacity_tiers: PackedFloat32Array = PackedFloat32Array([0.55, 0.45, 0.35])

## Scale multipliers (front → back).
var scale_tiers: PackedFloat32Array = PackedFloat32Array([1.00, 0.95, 0.90])

## Sentinel when no silhouette is available.
const PLACEHOLDER_ATLAS_UID := "placeholder:silhouette"

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
		push_warning("ApparitionRenderer: config file not found at %s. Using defaults." % RIG_CONFIG_PATH)
		return

	var file := FileAccess.open(RIG_CONFIG_PATH, FileAccess.READ)
	var json_text := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(json_text)
	if error == OK and json.data is Dictionary:
		_rig_config = json.data
		_apply_rig_config()
	else:
		push_error("ApparitionRenderer: failed to parse JSON config or config is not a Dictionary: %s" % json.get_error_message())

func _apply_rig_config() -> void:
	if _rig_config.is_empty():
		return

	var stack := _rig_config.get("stack", {})
	if not stack.is_empty():
		var offsets = stack.get("vertical_offsets", [0, 8, 16])
		if offsets.size() >= STACK_COUNT:
			vertical_offsets = PackedInt32Array(offsets)

		var opacities = stack.get("opacity_tiers", [0.55, 0.45, 0.35])
		if opacities.size() >= STACK_COUNT:
			opacity_tiers = PackedFloat32Array(opacities)

		var scales = stack.get("scale_tiers", [1.00, 0.95, 0.90])
		if scales.size() >= STACK_COUNT:
			scale_tiers = PackedFloat32Array(scales)

	var recoil := _rig_config.get("recoil", {})
	if not recoil.is_empty():
		recoil_z_index_offset = recoil.get("z_promotion", 2)

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
	for i in range(_silhouette_sprites.size()):
		var sprite := _silhouette_sprites[i]
		# The _silhouette_sprites array is indexed i = 0 (Front) to i = STACK_COUNT-1 (Back)
		# BUT they were added to the tree in REVERSE order in _create_stack_sprites.
		# The sprite at _silhouette_sprites[i] corresponds to opacity_tiers[i].
		var tier_alpha: float = opacity_tiers[i] if i < opacity_tiers.size() else 0.35
		sprite.modulate.a = tier_alpha * alpha

## Promote z-index during recoil.
func promote_z_index() -> void:
	var owner_node := _owner.get_ref() as Node2D if _owner else null
	if owner_node:
		z_index = owner_node.z_index + recoil_z_index_offset
	else:
		z_index = owner_z_index_offset + recoil_z_index_offset + 1

## Restore default z-index.
func restore_z_index() -> void:
	var owner_node := _owner.get_ref() as Node2D if _owner else null
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
		if state_machine and state_machine.current_state == ApparitionStateMachine.ApparitionState.INACTIVE:
			state_machine.cmd_manifest()
	else:
		if state_machine and state_machine.current_state != ApparitionStateMachine.ApparitionState.INACTIVE:
			state_machine.cmd_absolve()

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

func _create_dissolve_noise() -> void:
	_dissolve_noise = NoiseTexture2D.new()
	_dissolve_noise.width = 128
	_dissolve_noise.height = 128
	var noise := FastNoiseLite.new()
	noise.frequency = _rig_config.get("dissolve", {}).get("noise_frequency", 4.0) / 100.0
	_dissolve_noise.noise = noise

func _create_tint_material() -> void:
	var shader := load("res://scripts/shaders/apparition_composite.gdshader") as Shader
	if shader == null:
		push_warning("ApparitionRenderer: could not load apparition_composite.gdshader")
		return
	_tint_material = ShaderMaterial.new()
	_tint_material.shader = shader

	# Apply colors from config
	var colors := _rig_config.get("colors", {})
	if not colors.is_empty():
		_tint_material.set_shader_parameter("u_spectral_tint_color", Color(colors.get("spectral_tint", "#2A6F6F")))
		_tint_material.set_shader_parameter("u_inner_bleed_color", Color(colors.get("inner_bleed", "#9A8C98")))
		_tint_material.set_shader_parameter("u_after_trail_color", Color(colors.get("after_image", "#C9ADA7")))

	# Ensure default uniforms match spec §2.2
	_tint_material.set_shader_parameter("u_desaturation_amount", 0.2)
	_tint_material.set_shader_parameter("u_spectral_tint_opacity", 0.4)
	_tint_material.set_shader_parameter("u_inner_bleed_opacity", 0.15)
	_tint_material.set_shader_parameter("u_after_trail_opacity", _rig_config.get("trail", {}).get("intensity", 0.2))
	_tint_material.set_shader_parameter("u_intensity", 1.0)

	_tint_material.set_shader_parameter("u_dissolve_noise", _dissolve_noise)

func _create_stack_sprites() -> void:
	# Add in reverse order so Index 0 is on top (rendered last)
	for i in range(STACK_COUNT - 1, -1, -1):
		var sprite := Sprite2D.new()
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
	for i in range(TRAIL_COUNT):
		var sprite := Sprite2D.new()
		sprite.name = "Trail_%d" % i
		sprite.centered = true
		sprite.top_level = true # Trail stays in world space
		if _tint_material:
			sprite.material = _tint_material
		sprite.modulate.a = 0.0 # Start invisible
		_trail_sprites.append(sprite)
		add_child(sprite)

func _refresh_stack() -> void:
	if not BurdenManager:
		return
	var ids := BurdenManager.get_last_enemy_ids(STACK_COUNT)
	_current_stack = ids

	for i in range(STACK_COUNT):
		var sprite := _silhouette_sprites[i]
		if i < ids.size():
			var tex := BurdenManager.get_silhouette_texture(ids[i])
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

func _update_shader_uniforms(delta: float) -> void:
	if not state_machine:
		return

	var dissolve_threshold: float = 0.0
	var shear_intensity: float = 0.0

	# Breathing idle animation
	var breathing := _rig_config.get("breathing", {})
	var amplitude: float = breathing.get("amplitude", 0.08)
	var frequency: float = breathing.get("frequency", 2.734)
	var breathing_intensity := 1.0 + sin(Time.get_ticks_msec() * 0.001 * frequency * TAU) * amplitude

	match state_machine.current_state:
		ApparitionStateMachine.ApparitionState.ABSORB:
			var duration: float = _rig_config.get("dissolve", {}).get("duration_ms", 400) / 1000.0
			dissolve_threshold = clampf(state_machine._absorb_timer / duration, 0.0, 1.0)
		ApparitionStateMachine.ApparitionState.RECOIL:
			var base_shear = _rig_config.get("recoil", {}).get("shear_intensity", 1.2)
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

	if state_machine.current_state == ApparitionStateMachine.ApparitionState.INACTIVE or \
	   state_machine.current_state == ApparitionStateMachine.ApparitionState.ABSORB:
		# Fade out trails if inactive or absorbing
		for sprite in _trail_sprites:
			sprite.modulate.a = lerpf(sprite.modulate.a, 0.0, delta * 10.0)
		return

	var trail_config := _rig_config.get("trail", {})
	var lifetime_ms: float = maxf(trail_config.get("lifetime_ms", 300), 1.0)
	var interval: float = (lifetime_ms / 1000.0) / TRAIL_COUNT
	var intensity: float = trail_config.get("intensity", 0.2) * _master_alpha

	_trail_timer += delta
	if _trail_timer >= interval:
		_trail_timer = 0.0

		# Update trail sprite
		var sprite := _trail_sprites[_trail_index]

		# Pick the front-most silhouette texture for the trail
		if not _silhouette_sprites.is_empty():
			sprite.texture = _silhouette_sprites[0].texture
			sprite.scale = _silhouette_sprites[0].scale

		sprite.global_position = global_position
		sprite.modulate.a = intensity

		_trail_index = (_trail_index + 1) % TRAIL_COUNT

	# Continuous fade for all trail sprites
	var fade_speed: float = 1.0 / (lifetime_ms / 1000.0)
	for sprite in _trail_sprites:
		if sprite.modulate.a > 0.0:
			sprite.modulate.a = clampf(sprite.modulate.a - delta * fade_speed * intensity, 0.0, 1.0)

func _update_z_index() -> void:
	var owner_node := _owner.get_ref() as Node2D if _owner else null
	if owner_node:
		z_index = owner_node.z_index + owner_z_index_offset
	else:
		z_index = owner_z_index_offset

func _get_placeholder_texture() -> Texture2D:
	var cached := BurdenManager.get_silhouette_texture(PLACEHOLDER_ATLAS_UID)
	if cached:
		return cached
	# Create a procedural 64×64 silhouette placeholder (white blob).
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 1.0))
	var tex := ImageTexture.create_from_image(img)
	BurdenManager.register_silhouette(PLACEHOLDER_ATLAS_UID, tex)
	return tex

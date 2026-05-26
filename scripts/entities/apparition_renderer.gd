class_name ApparitionRenderer
extends Node2D

## ApparitionRenderer
## Composites up to 3 sentient-kill silhouettes behind the owner entity
## (typically the Keeper). Drives the ApparitionStateMachine and applies
## the apparition tint shader in a single material pass.
##
## References: DON-83 Apparition Composite Render Pipeline
##            Burden Event Asset Spec §2.2

const STACK_COUNT: int = 3

## Default vertical offsets in pixels (composite stack).
const VERTICAL_OFFSETS: PackedInt32Array = PackedInt32Array([0, 8, 16])

## Opacity tiers (front → back).
const OPACITY_TIERS: PackedFloat32Array = PackedFloat32Array([0.55, 0.45, 0.35])

## Scale multipliers (front → back).
const SCALE_TIERS: PackedFloat32Array = PackedFloat32Array([1.00, 0.95, 0.90])

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

## Shared shader material for tinting.
var _tint_material: ShaderMaterial

## Weak reference to the Keeper / owner entity for transform anchoring.
var _owner: WeakRef

## State machine.
var state_machine: ApparitionStateMachine

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	z_index = owner_z_index_offset
	_create_tint_material()
	_create_stack_sprites()
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
	for i in range(_silhouette_sprites.size()):
		var sprite := _silhouette_sprites[i]
		var tier_alpha: float = OPACITY_TIERS[i] if i < OPACITY_TIERS.size() else 0.35
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

func _create_tint_material() -> void:
	var shader := load("res://scripts/shaders/apparition_composite.gdshader") as Shader
	if shader == null:
		push_warning("ApparitionRenderer: could not load apparition_composite.gdshader")
		return
	_tint_material = ShaderMaterial.new()
	_tint_material.shader = shader
	# Ensure default uniforms match spec §2.2
	_tint_material.set_shader_parameter("u_desaturation_amount", 0.2)
	_tint_material.set_shader_parameter("u_spectral_tint_opacity", 0.4)
	_tint_material.set_shader_parameter("u_inner_bleed_opacity", 0.15)
	_tint_material.set_shader_parameter("u_after_trail_opacity", 0.2)
	_tint_material.set_shader_parameter("u_intensity", 1.0)

func _create_stack_sprites() -> void:
	for i in range(STACK_COUNT):
		var sprite := Sprite2D.new()
		sprite.name = "Silhouette_%d" % i
		sprite.centered = true
		if _tint_material:
			sprite.material = _tint_material.duplicate()
		# Default layout behind owner
		sprite.position = Vector2(0, -VERTICAL_OFFSETS[i])
		sprite.scale = Vector2(SCALE_TIERS[i], SCALE_TIERS[i])
		sprite.modulate.a = OPACITY_TIERS[i]
		_silhouette_sprites.append(sprite)
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
		sprite.position = Vector2(0, -VERTICAL_OFFSETS[i])
		sprite.scale = Vector2(SCALE_TIERS[i], SCALE_TIERS[i])
		sprite.modulate.a = OPACITY_TIERS[i]

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

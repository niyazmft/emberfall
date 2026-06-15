class_name Keeper
extends CombatEntity

## Keeper
## Player entity scene root. Composes an Entity data block, handles
## transform sync to the ApparitionRenderer, and exposes damage/recoil
## hooks for the combat system.
##
## Scene: res://scenes/keeper.tscn

@export var visual_proxy: EntityVisualProxy

## Configurable properties
@export var sprite_scale: float = 1.0

## Child references (auto-wired in _ready)
var _apparition: ApparitionRenderer

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	add_to_group("player")
	# Auto-create Entity data block if not assigned in inspector.
	if entity == null:
		entity = Entity.new("Keeper", 0, 0, 40, 12, 6, 0, 1, 0)
		entity.is_player = true

	# Find or create ApparitionRenderer child.
	_apparition = _find_or_create_apparition()
	_apparition.bind_owner(self)

	# Connect visual_proxy to entity
	if visual_proxy and entity:
		visual_proxy.entity = entity


func _process(_delta: float) -> void:
	# Sync apparition position to the visual proxy's position (which interpolates)
	if _apparition and visual_proxy:
		_apparition.sync_to_owner(visual_proxy.global_position)
	elif _apparition:
		_apparition.sync_to_owner(global_position)


# ---------------------------------------------------------------------------
# Combat API
# ---------------------------------------------------------------------------


## Visual-only damage hook for combat system (avoids re-entering damage pipeline).
func trigger_damage_effect() -> void:
	if _apparition:
		_apparition.trigger_recoil()


## Apply damage to the Keeper entity and trigger recoil on the apparition.
## Delegates to EntityLifecycle for canonical state transitions.
func apply_damage(damage: int, attacker: Entity = null) -> void:
	if entity == null:
		return
	var lifecycle: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.apply_damage(attacker, entity, damage)
	else:
		entity.apply_damage(damage)

	if _apparition:
		_apparition.trigger_recoil()


## Heal the Keeper entity.
func heal(amount: int) -> void:
	if entity == null:
		return
	entity.heal(amount)


## Record a sentient enemy kill via BurdenManager.
func record_sentient_kill(enemy_id: String, enemy_name: String = "") -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm:
		bm.record_sentient_kill(enemy_id, enemy_name)


## Update moral weight via BurdenManager (called by MoralEval / combat resolution).
func update_moral_weight(moral_flag: int) -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm:
		bm.update_moral_weight(moral_flag)


## Convenience: is the Keeper alive?
func alive() -> bool:
	return entity.alive() if entity else false


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------


func _find_or_create_apparition() -> ApparitionRenderer:
	for child: Node in get_children():
		if child is ApparitionRenderer:
			return child
	var app := ApparitionRenderer.new()
	app.owner_z_index_offset = -1
	app.name = "ApparitionRenderer"
	add_child(app)
	return app

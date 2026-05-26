class_name Keeper
extends Node2D

## Keeper
## Player entity scene root. Composes an Entity data block, handles
## transform sync to the ApparitionRenderer, and exposes damage/recoil
## hooks for the combat system.
##
## Scene: res://scenes/keeper.tscn

@export var entity: Entity

## Configurable properties
@export var sprite_scale: float = 1.0

## Child references (auto-wired in _ready)
var _apparition: ApparitionRenderer

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	# Auto-create Entity data block if not assigned in inspector.
	if entity == null:
		entity = Entity.new("Keeper", 0, 0, 40, 12, 6, 0, 1, 0)
		entity.is_player = true

	# Find or create ApparitionRenderer child.
	_apparition = _find_or_create_apparition()
	_apparition.bind_owner(self)

	# Connect entity state changes to apparition effects.
	# Note: Entity is a RefCounted data class with no built-in signals,
	# so external combat system must call apply_damage() on this Keeper node.


func _process(_delta: float) -> void:
	# Sync apparition position every frame.
	if _apparition:
		_apparition.sync_to_owner(global_position)


# ---------------------------------------------------------------------------
# Combat API
# ---------------------------------------------------------------------------


## Apply damage to the Keeper entity and trigger recoil on the apparition.
## Delegates to EntityLifecycle for canonical state transitions.
func apply_damage(damage: int) -> void:
	if entity == null:
		return
	if has_node("/root/EntityLifecycle"):
		EntityLifecycle.apply_damage(null, entity, damage)
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
	if BurdenManager:
		BurdenManager.record_sentient_kill(enemy_id, enemy_name)


## Update moral weight via BurdenManager (called by MoralEval / combat resolution).
func update_moral_weight(moral_flag: int) -> void:
	if BurdenManager:
		BurdenManager.update_moral_weight(moral_flag)


## Convenience: is the Keeper alive?
func alive() -> bool:
	return entity.alive() if entity else false


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------


func _find_or_create_apparition() -> ApparitionRenderer:
	for child in get_children():
		if child is ApparitionRenderer:
			return child
	var app := ApparitionRenderer.new()
	app.owner_z_index_offset = -1
	app.name = "ApparitionRenderer"
	add_child(app)
	return app

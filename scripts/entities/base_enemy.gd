class_name BaseEnemy
extends Node2D
## Enemy scene root with configurable AI behavior

@export var entity: Entity
@export var ai_controller: Node  ## Will integrate with behavior tree
@export var visual_proxy: EntityVisualProxy

var _grid_system: _GridSystem
var _combat_system: Node  ## Placeholder for future combat system


func _ready() -> void:
	add_to_group("enemies")
	if _grid_system == null:
		_grid_system = AutoloadHelper.grid_system()
	_setup_entity()
	_setup_visual_proxy()


func _process(_delta: float) -> void:
	# Sync apparition position to the visual proxy's position (which interpolates)
	if has_node("ApparitionRenderer"):
		var renderer: Node = get_node("ApparitionRenderer")
		if renderer.has_method("sync_to_owner"):
			if visual_proxy:
				renderer.call("sync_to_owner", visual_proxy.global_position)
			else:
				renderer.call("sync_to_owner", global_position)


func _setup_entity() -> void:
	# Initialize entity if not set
	if entity == null:
		entity = Entity.new("Enemy", 0, 0, 30, 8, 4)
		entity.is_player = false


func _setup_visual_proxy() -> void:
	# Connect visual_proxy to entity
	if visual_proxy and entity:
		visual_proxy.entity = entity


## Combat API
func take_turn() -> void:
	## Called by combat system when it's this enemy's turn
	if ai_controller and ai_controller.has_method("decide_action"):
		var action: Dictionary = ai_controller.call("decide_action", entity)
		_execute_action(action)


func _execute_action(action: Dictionary) -> void:
	## Execute decided action
	match action.get("type", ""):
		"move":
			_handle_move(action)
		"attack":
			_handle_attack(action)
		"wait":
			pass  # Do nothing


func _handle_move(action: Dictionary) -> void:
	var target_x: int = action.get("target_x", entity.x)
	var target_y: int = action.get("target_y", entity.y)

	if _grid_system and _grid_system.can_move(entity.x, entity.y, target_x, target_y):
		# Calculate facing BEFORE updating position
		var dx: int = target_x - entity.x
		var dy: int = target_y - entity.y

		entity.set_grid_position(target_x, target_y)

		# Update facing if moved
		if dx != 0 or dy != 0:
			entity.set_facing(DeterministicMath.sgn(dx), DeterministicMath.sgn(dy))

		# Consume AP for movement
		# Sprint 1: simple 1 AP per tile for cardinal, 2 for diagonal
		var cost: int = 1
		if dx != 0 and dy != 0:
			cost = 2
		entity.ap = DeterministicMath.clampi(entity.ap - cost, 0, GameConstants.AP_MAX)


func _handle_attack(action: Dictionary) -> void:
	var target_node: Node2D = action.get("target") as Node2D
	if target_node == null:
		return

	var target_entity: Entity = target_node.get("entity") as Entity
	if target_entity == null:
		return

	# Gather cover tiles for damage formula
	var cover_tiles: Array[Vector2i] = []
	if _grid_system:
		for tile in _grid_system.all_tiles():
			if tile.has_cover():
				cover_tiles.append(tile.coords)

	# Calculate damage
	var damage: int = CombatFormula.compute_damage_from_entities(entity, target_entity, cover_tiles)

	# Apply damage through lifecycle
	var lifecycle: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.apply_damage(entity, target_entity, damage)
	else:
		target_entity.apply_damage(damage)

	# Trigger recoil on target if it has the method
	if target_node.has_method("apply_damage"):
		target_node.call("apply_damage", 0)  # Call with 0 just to trigger visual/recoil

	# Consume AP
	var cost: int = CombatFormula.action_cost("attack_basic")
	entity.ap = DeterministicMath.clampi(entity.ap - cost, 0, GameConstants.AP_MAX)


## Damage API
func apply_damage(damage: int) -> void:
	## Apply damage through EntityLifecycle via AutoloadHelper
	var lifecycle: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.apply_damage(null, entity, damage)
	else:
		entity.apply_damage(damage)

	## Trigger visual effect
	## NOTE: ApparitionRenderer is not fully implemented yet. Use a safe fallback check.
	if has_node("ApparitionRenderer"):
		var renderer: Node = get_node("ApparitionRenderer")
		if renderer.has_method("trigger_damage_effect"):
			renderer.call("trigger_damage_effect")


func alive() -> bool:
	return entity.alive() if entity else false

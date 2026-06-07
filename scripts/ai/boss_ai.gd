class_name BossAI
extends RefCounted

## BossAI behavior resolver.
## Manages specialized boss logic by resolving behavior names from config.


static func decide_action(
	p_behavior_name: String,
	p_entity: Entity,
	p_player_node: Node2D,
	p_grid_system: _GridSystem,
	p_controller: EnemyAIController
) -> Dictionary:
	match p_behavior_name.to_upper():
		"OVERGROWN_GUARDIAN":
			return _overgrown_guardian_behavior(
				p_entity, p_player_node, p_grid_system, p_controller
			)
		_:
			# Fallback to simple grunt behavior if behavior name not recognized
			return p_controller._grunt_behavior(
				p_entity.grid_position(),
				(p_player_node.get("entity") as Entity).grid_position(),
				p_controller._grid_distance(
					p_entity.grid_position(),
					(p_player_node.get("entity") as Entity).grid_position()
				)
			)


static func _overgrown_guardian_behavior(
	p_entity: Entity,
	p_player_node: Node2D,
	p_grid_system: _GridSystem,
	p_controller: EnemyAIController
) -> Dictionary:
	var player_entity: Entity = p_player_node.get("entity") as Entity
	if player_entity == null:
		return {"type": "wait"}

	var player_pos: Vector2i = player_entity.grid_position()
	var enemy_pos: Vector2i = p_entity.grid_position()
	var dist: int = p_controller._grid_distance(enemy_pos, player_pos)

	# Overgrown Guardian logic:
	# 1. If adjacent, attack.
	# 2. If at range 2-3, maybe use a special stomp (placeholder for now, just move closer)
	# 3. Otherwise, move towards player.

	if dist <= 1:
		return {"type": "attack", "target": p_player_node}

	var next_tile: Vector2i = p_controller._get_next_tile_towards(player_pos)
	if next_tile != enemy_pos:
		return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}

	return {"type": "wait"}

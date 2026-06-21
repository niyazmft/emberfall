class_name TankAI
extends RefCounted

## TankAI behavior resolver.
## Manages Tank-specific logic including taunt radius and shield block.


static func decide_action(
	p_entity: Entity,
	p_player_node: Node2D,
	p_grid_system: _GridSystem,
	p_controller: EnemyAIController
) -> Dictionary:
	var player_entity := CombatEntity.get_entity(p_player_node)
	if player_entity == null:
		return {"type": "wait"}

	var player_pos: Vector2i = player_entity.grid_position()
	var enemy_pos: Vector2i = p_entity.grid_position()
	var dist: int = p_controller._grid_distance(enemy_pos, player_pos)
	var occupied_coords: Array[Vector2i] = p_controller._get_occupied_coords()

	# Get Tank-specific properties from the entity's controller node (BaseEnemy or child)
	var tank_node := p_controller.get_parent() as EnemyTank
	var taunt_radius: int = 3
	if tank_node:
		taunt_radius = tank_node.taunt_radius

	# 1. Attack if adjacent
	if dist <= 1:
		return {"type": "attack", "target": p_player_node}

	# 2. Movement logic
	# Tanks want to be within taunt_radius to be effective.
	# If outside, move towards.
	if dist > taunt_radius:
		var next_tile: Vector2i = p_controller._get_next_tile_towards(player_pos, occupied_coords)
		if next_tile != enemy_pos:
			return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}

	# 3. If within taunt radius but not adjacent, still move towards if possible
	# to maximize pressure, but this could be made more sophisticated later.
	if dist > 1:
		var next_tile: Vector2i = p_controller._get_next_tile_towards(player_pos, occupied_coords)
		if next_tile != enemy_pos:
			return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}

	return {"type": "wait"}

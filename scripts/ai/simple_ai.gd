class_name EnemyAIController
extends Node
## Basic Enemy AI controller
## Implements behaviors for different enemy types: Grunt, Archer, Tank.

enum BehaviorType { GRUNT, ARCHER, TANK }

@export var behavior: BehaviorType = BehaviorType.GRUNT
@export var enemy_entity: Entity
@export var grid_system: _GridSystem

## Internal reference to player
var _player_node: Node2D


func _ready() -> void:
	if grid_system == null:
		grid_system = AutoloadHelper.grid_system()


func decide_action(p_entity: Entity = null) -> Dictionary:
	if p_entity:
		enemy_entity = p_entity

	if enemy_entity == null:
		return {"type": "wait"}

	var tree: SceneTree = get_tree()
	if tree == null:
		return {"type": "wait"}

	_player_node = tree.get_first_node_in_group("player") as Node2D
	if (
		_player_node == null
		or not _player_node.has_method("alive")
		or not _player_node.call("alive")
	):
		return {"type": "wait"}

	var player_entity: Entity = _player_node.get("entity") as Entity
	if player_entity == null:
		return {"type": "wait"}

	var player_pos: Vector2i = player_entity.grid_position()
	var enemy_pos: Vector2i = enemy_entity.grid_position()
	var dist: int = _grid_distance(enemy_pos, player_pos)

	match behavior:
		BehaviorType.GRUNT:
			return _grunt_behavior(enemy_pos, player_pos, dist)
		BehaviorType.ARCHER:
			return _archer_behavior(enemy_pos, player_pos, dist)
		BehaviorType.TANK:
			return _tank_behavior(enemy_pos, player_pos, dist)

	return {"type": "wait"}


func _grunt_behavior(enemy_pos: Vector2i, player_pos: Vector2i, dist: int) -> Dictionary:
	# Rush player, attack when adjacent
	if dist <= 1:
		return {"type": "attack", "target": _player_node}

	var next_tile: Vector2i = _get_next_tile_towards(player_pos)
	if next_tile != enemy_pos:
		return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}

	return {"type": "wait"}


func _archer_behavior(enemy_pos: Vector2i, player_pos: Vector2i, dist: int) -> Dictionary:
	# Maintain 2-3 tile distance
	if dist < 2:
		# Too close, move away
		var next_tile: Vector2i = _get_next_tile_towards(player_pos, true)
		if next_tile != enemy_pos:
			return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}
	elif dist > 3:
		# Too far, move towards
		var next_tile: Vector2i = _get_next_tile_towards(player_pos)
		if next_tile != enemy_pos:
			return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}
	else:
		# In range 2-3, attack
		return {"type": "attack", "target": _player_node}

	return {"type": "wait"}


func _tank_behavior(enemy_pos: Vector2i, player_pos: Vector2i, dist: int) -> Dictionary:
	# Slow advance, heavy damage
	# For Tank, we might want to only move if we have full AP or something,
	# but for now it's same as grunt.
	return _grunt_behavior(enemy_pos, player_pos, dist)


func _get_next_tile_towards(target_pos: Vector2i, away: bool = false) -> Vector2i:
	if enemy_entity == null or grid_system == null:
		return Vector2i(enemy_entity.x, enemy_entity.y) if enemy_entity else Vector2i.ZERO

	var current_pos: Vector2i = enemy_entity.grid_position()
	var best_tile: Vector2i = current_pos
	var min_dist: int = _grid_distance(current_pos, target_pos)
	if away:
		min_dist = -1

	# Get all entities once to avoid repeated group lookups in the loop
	var occupied_coords: Array[Vector2i] = _get_occupied_coords()

	# Check all 8 neighbors
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue

			var nx: int = current_pos.x + dx
			var ny: int = current_pos.y + dy
			var n_pos: Vector2i = Vector2i(nx, ny)

			if grid_system.can_move(current_pos.x, current_pos.y, nx, ny):
				if n_pos in occupied_coords:
					continue

				var d: int = _grid_distance(n_pos, target_pos)
				if away:
					if d > min_dist:
						min_dist = d
						best_tile = n_pos
				else:
					if d < min_dist:
						min_dist = d
						best_tile = n_pos

	return best_tile


func _get_occupied_coords() -> Array[Vector2i]:
	var occupied: Array[Vector2i] = []

	var tree: SceneTree = get_tree()
	if tree == null:
		return occupied

	# Player
	var player: Node2D = tree.get_first_node_in_group("player") as Node2D
	if player:
		var pent: Entity = player.get("entity") as Entity
		if pent:
			occupied.append(Vector2i(pent.x, pent.y))

	# Enemies
	for enemy: Node in tree.get_nodes_in_group("enemies"):
		if enemy == get_parent():  # Skip self
			continue
		var e_node: Node2D = enemy as Node2D
		if e_node:
			var e_ent: Entity = e_node.get("entity") as Entity
			if e_ent and e_ent.alive():
				occupied.append(Vector2i(e_ent.x, e_ent.y))

	return occupied


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))

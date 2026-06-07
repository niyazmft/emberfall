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
var _intent_visualizer: IntentVisualizer


func _ready() -> void:
	if grid_system == null:
		grid_system = AutoloadHelper.grid_system()

	# Find GridRenderer in the scene to initialize IntentVisualizer
	var grid_renderer: GridRenderer = get_tree().root.find_child("GridRenderer", true, false) as GridRenderer
	if grid_renderer:
		_intent_visualizer = IntentVisualizer.new(grid_renderer)
		add_child(_intent_visualizer)


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
			var action: Dictionary = _tank_behavior(enemy_pos, player_pos, dist)
			if _intent_visualizer:
				_intent_visualizer.visualize_intent(enemy_entity, action)
			return action

	var final_action: Dictionary = {"type": "wait"}
	if _intent_visualizer:
		_intent_visualizer.visualize_intent(enemy_entity, final_action)
	return final_action


func _grunt_behavior(enemy_pos: Vector2i, player_pos: Vector2i, dist: int) -> Dictionary:
	var action: Dictionary = {"type": "wait"}
	# Rush player, attack when adjacent
	if dist <= 1:
		action = {"type": "attack", "target": _player_node}
	else:
		var next_tile: Vector2i = _get_next_tile_towards(player_pos)
		if next_tile != enemy_pos:
			action = {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}

	if _intent_visualizer:
		_intent_visualizer.visualize_intent(enemy_entity, action)
	return action


func _archer_behavior(enemy_pos: Vector2i, player_pos: Vector2i, dist: int) -> Dictionary:
	var action: Dictionary = {"type": "wait"}
	# Maintain 2-3 tile distance
	if dist < 2:
		# Too close, move away
		var next_tile: Vector2i = _get_next_tile_towards(player_pos, true)
		if next_tile != enemy_pos:
			action = {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}
	elif dist > 3:
		# Too far, move towards
		var next_tile: Vector2i = _get_next_tile_towards(player_pos)
		if next_tile != enemy_pos:
			action = {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}
	else:
		# In range 2-3, attack
		action = {"type": "attack", "target": _player_node}

	if _intent_visualizer:
		_intent_visualizer.visualize_intent(enemy_entity, action)
	return action




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
	var min_dist: int
	if away:
		min_dist = -1
	else:
		# Sentinel larger than any possible grid distance so any valid
		# neighbour is considered when the ideal tile is occupied.
		min_dist = GameConstants.GRID_W * 2 + 1

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

			# Skip out-of-bounds tiles to avoid crash in can_move
			if nx < 0 or nx >= GameConstants.GRID_W or ny < 0 or ny >= GameConstants.GRID_H:
				continue

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
	var dx: int = DeterministicMath.absi(a.x - b.x)
	var dy: int = DeterministicMath.absi(a.y - b.y)
	return DeterministicMath.maxi(dx, dy)

class_name EnemyAIController
extends Node
## Basic Enemy AI controller
## Implements behaviors for different enemy types: Grunt, Archer, Tank, Mage.

enum BehaviorType { GRUNT, ARCHER, TANK, BOSS, MAGE }

@export var behavior: BehaviorType = BehaviorType.GRUNT
@export var boss_behavior_name: String = ""
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
	if _player_node == null:
		return {"type": "wait"}

	var is_alive := false
	if _player_node is Keeper:
		is_alive = (_player_node as Keeper).alive()
	elif _player_node is BaseEnemy:
		is_alive = (_player_node as BaseEnemy).alive()

	if not is_alive:
		return {"type": "wait"}

	var player_entity := CombatEntity.get_entity(_player_node)
	if player_entity == null:
		return {"type": "wait"}

	var player_pos: Vector2i = player_entity.grid_position()
	var enemy_pos: Vector2i = enemy_entity.grid_position()
	var dist: int = _grid_distance(enemy_pos, player_pos)
	var occupied_coords: Array[Vector2i] = _get_occupied_coords()

	match behavior:
		BehaviorType.GRUNT:
			return _grunt_behavior(enemy_pos, player_pos, dist, occupied_coords)
		BehaviorType.ARCHER:
			return _archer_behavior(enemy_pos, player_pos, dist, occupied_coords)
		BehaviorType.TANK:
			return _tank_behavior(enemy_pos, player_pos, dist)
		BehaviorType.BOSS:
			return _boss_behavior()
		BehaviorType.MAGE:
			return _mage_behavior(enemy_pos, player_pos, dist, occupied_coords)

	return {"type": "wait"}


func _grunt_behavior(
	enemy_pos: Vector2i, player_pos: Vector2i, dist: int, occupied_coords: Array[Vector2i]
) -> Dictionary:
	# Rush player, attack when adjacent
	if dist <= 1:
		return {"type": "attack", "target": _player_node}

	var next_tile: Vector2i = _get_next_tile_towards(player_pos, occupied_coords)
	if next_tile != enemy_pos:
		return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}

	return {"type": "wait"}


func _archer_behavior(
	enemy_pos: Vector2i, player_pos: Vector2i, dist: int, occupied_coords: Array[Vector2i]
) -> Dictionary:
	# Maintain 2-3 tile distance
	if dist < 2:
		# Too close, move away
		var next_tile: Vector2i = _get_next_tile_towards(player_pos, occupied_coords, true)
		if next_tile != enemy_pos:
			return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}
	elif dist > 3:
		# Too far, move towards
		var next_tile: Vector2i = _get_next_tile_towards(player_pos, occupied_coords)
		if next_tile != enemy_pos:
			return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}
	else:
		# In range 2-3, attack
		return {"type": "attack", "target": _player_node}

	return {"type": "wait"}


func _tank_behavior(_enemy_pos: Vector2i, _player_pos: Vector2i, _dist: int) -> Dictionary:
	# Delegate to specialized TankAI resolver
	return TankAI.decide_action(enemy_entity, _player_node, grid_system, self)


func _boss_behavior() -> Dictionary:
	# Delegate to specialized BossAI resolver
	return BossAI.decide_action(boss_behavior_name, enemy_entity, _player_node, grid_system, self)


func _mage_behavior(
	enemy_pos: Vector2i, player_pos: Vector2i, dist: int, occupied_coords: Array[Vector2i]
) -> Dictionary:
	## Mage AI: prefers high elevation, AoE when player is clustered, retreats when wounded.
	if enemy_entity == null or grid_system == null:
		return {"type": "wait"}

	# 1. Retreat when wounded (HP below 50%)
	if enemy_entity.hp < enemy_entity.hp_max / 2:
		var next_tile: Vector2i = _get_next_tile_towards(player_pos, occupied_coords, true)
		if next_tile != enemy_pos:
			return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}
		return {"type": "wait"}

	# 2. AoE cast if player is adjacent to another enemy (clustered target)
	if _player_adjacent_to_other_enemy(player_pos):
		return {"type": "attack", "target": _player_node, "aoe": true}

	# 3. Prefer high elevation: if not on HIGH elevation, move towards it
	var current_tile: TacTileData = grid_system.get_tile(enemy_pos.x, enemy_pos.y)
	if current_tile != null and current_tile.elevation != TacTileData.Elevation.HIGH:
		var high_tile: Vector2i = _find_nearest_high_elevation(enemy_pos, occupied_coords)
		if high_tile != enemy_pos:
			return {"type": "move", "target_x": high_tile.x, "target_y": high_tile.y}

	# 4. Attack if in range (max_range 4 for mage)
	if dist <= 4:
		return {"type": "attack", "target": _player_node}

	# 5. Move closer to be in range
	var next_tile: Vector2i = _get_next_tile_towards(player_pos, occupied_coords)
	if next_tile != enemy_pos:
		return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}

	return {"type": "wait"}


func _player_adjacent_to_other_enemy(player_pos: Vector2i) -> bool:
	## Returns true if any enemy (other than self) is adjacent to the player.
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	for enemy: Node in tree.get_nodes_in_group("enemies"):
		if enemy == get_parent():
			continue
		var e_node: Node2D = enemy as Node2D
		if e_node == null:
			continue
		var e_ent := CombatEntity.get_entity(e_node)
		if e_ent == null or not e_ent.alive():
			continue
		var e_pos: Vector2i = Vector2i(e_ent.x, e_ent.y)
		if _grid_distance(player_pos, e_pos) <= 1:
			return true
	return false


func _find_nearest_high_elevation(from_pos: Vector2i, occupied_coords: Array[Vector2i]) -> Vector2i:
	## Find the nearest HIGH elevation tile reachable in one move.
	var best_tile: Vector2i = from_pos
	var min_dist: int = GameConstants.GRID_W * 2 + 1

	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = from_pos.x + dx
			var ny: int = from_pos.y + dy
			if nx < 0 or nx >= GameConstants.GRID_W or ny < 0 or ny >= GameConstants.GRID_H:
				continue
			if not grid_system.can_move(from_pos.x, from_pos.y, nx, ny):
				continue
			var n_pos: Vector2i = Vector2i(nx, ny)
			if n_pos in occupied_coords:
				continue
			var tile: TacTileData = grid_system.get_tile(nx, ny)
			if tile != null and tile.elevation == TacTileData.Elevation.HIGH:
				var d: int = _grid_distance(n_pos, from_pos)
				if d < min_dist:
					min_dist = d
					best_tile = n_pos
	return best_tile


func _get_next_tile_towards(
	target_pos: Vector2i, occupied_coords: Array[Vector2i], away: bool = false
) -> Vector2i:
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
		var pent := CombatEntity.get_entity(player)
		if pent:
			occupied.append(Vector2i(pent.x, pent.y))

	# Enemies
	for enemy: Node in tree.get_nodes_in_group("enemies"):
		if enemy == get_parent():  # Skip self
			continue
		var e_node: Node2D = enemy as Node2D
		if e_node:
			var e_ent := CombatEntity.get_entity(e_node)
			if e_ent and e_ent.alive():
				occupied.append(Vector2i(e_ent.x, e_ent.y))

	return occupied


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	var dx: int = DeterministicMath.absi(a.x - b.x)
	var dy: int = DeterministicMath.absi(a.y - b.y)
	return DeterministicMath.maxi(dx, dy)

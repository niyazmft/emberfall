class_name ArcherAI
extends EnemyAIController
## Specific AI for Archer archetype

@export var min_range: int = 2
@export var max_range: int = 3
@export var retreat_hp_threshold: float = 0.3
@export var elevation_priority: float = 1.5


func _ready() -> void:
	super._ready()
	_load_params()


func _load_params() -> void:
	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	if not config_loader:
		return

	var archer_id: String = "archer"
	if enemy_entity and not enemy_entity.archetype_id.is_empty():
		archer_id = enemy_entity.archetype_id

	var enemies_config: Variant = config_loader.getValue("enemies")
	if enemies_config is Dictionary and enemies_config.has(archer_id):
		var data: Dictionary = enemies_config[archer_id]
		min_range = int(data.get("min_range", 2))
		max_range = int(data.get("max_range", 3))
		retreat_hp_threshold = float(data.get("retreat_hp_threshold", 0.3))
		elevation_priority = float(data.get("elevation_priority", 1.5))


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

	var hp_percent: float = float(enemy_entity.hp) / float(enemy_entity.hp_max)
	var is_retreating: bool = hp_percent < retreat_hp_threshold

	if is_retreating:
		var next_tile: Vector2i = _get_best_tile(player_pos, true)
		if next_tile != enemy_pos:
			return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}
		else:
			# If we can't move away, at least try to attack if in range
			if (
				dist >= 1
				and grid_system.has_los(enemy_pos.x, enemy_pos.y, player_pos.x, player_pos.y)
			):
				return {"type": "attack", "target": _player_node}

	if dist < min_range:
		# Too close, move away
		var next_tile: Vector2i = _get_best_tile(player_pos, true)
		if next_tile != enemy_pos:
			return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}
	elif dist > max_range:
		# Too far, move towards
		var next_tile: Vector2i = _get_best_tile(player_pos, false)
		if next_tile != enemy_pos:
			return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}
	else:
		# In range, check LOS and attack
		if grid_system.has_los(enemy_pos.x, enemy_pos.y, player_pos.x, player_pos.y):
			return {"type": "attack", "target": _player_node}
		else:
			# No LOS, try to move to a better spot
			var next_tile: Vector2i = _get_best_tile(player_pos, false)
			if next_tile != enemy_pos:
				return {"type": "move", "target_x": next_tile.x, "target_y": next_tile.y}

	return {"type": "wait"}


func _get_best_tile(target_pos: Vector2i, away: bool) -> Vector2i:
	if enemy_entity == null or grid_system == null:
		return enemy_entity.grid_position() if enemy_entity else Vector2i.ZERO

	var current_pos: Vector2i = enemy_entity.grid_position()
	var best_tile: Vector2i = current_pos
	var best_score: float = -1000000.0

	var occupied_coords: Array[Vector2i] = _get_occupied_coords()

	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue

			var n_pos: Vector2i = current_pos + Vector2i(dx, dy)

			if not grid_system.is_in_bounds(n_pos.x, n_pos.y):
				continue

			if grid_system.can_move(current_pos.x, current_pos.y, n_pos.x, n_pos.y):
				if n_pos in occupied_coords:
					continue

				var score: float = 0.0
				var d: int = _grid_distance(n_pos, target_pos)

				if away:
					# If retreating, we want to maximize distance
					score += float(d) * 10.0
				else:
					# Try to get into [min_range, max_range]
					if d >= min_range and d <= max_range:
						score += 100.0
					else:
						# Penalty for being outside preferred range
						var preferred_center: float = float(min_range + max_range) / 2.0
						score -= DeterministicMath.absf(float(d) - preferred_center) * 20.0

				# Elevation priority
				var tile: TacTileData = grid_system.get_tile(n_pos.x, n_pos.y)
				if tile:
					score += float(tile.elevation) * elevation_priority

				# Bonus for having LOS from target tile
				if grid_system.has_los(n_pos.x, n_pos.y, target_pos.x, target_pos.y):
					score += 20.0

				if score > best_score:
					best_score = score
					best_tile = n_pos

	if away and best_tile == current_pos:
		# If no better tile found, stay put but maybe we should log it
		pass

	return best_tile

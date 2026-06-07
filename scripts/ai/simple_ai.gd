class_name EnemyAIController
extends Node
## Basic Enemy AI controller
## Implements behaviors for different enemy types: Grunt, Archer, Tank.

enum BehaviorType { GRUNT, ARCHER, TANK }

@export var behavior: BehaviorType = BehaviorType.GRUNT
@export var enemy_entity: Entity
@export var grid_system: _GridSystem
@export var gridRenderer: GridRenderer

## Internal reference to player
var _playerNode: Node2D
var _intentVisualizer: IntentVisualizer


func _ready() -> void:
	if grid_system == null:
		grid_system = AutoloadHelper.grid_system()

	if gridRenderer == null:
		var tree: SceneTree = get_tree()
		if tree and tree.root:
			var node: Node = tree.root.find_child("GridRenderer", true, false)
			if node is GridRenderer:
				gridRenderer = node as GridRenderer

	if gridRenderer:
		_intentVisualizer = IntentVisualizer.new(gridRenderer)
		add_child(_intentVisualizer)
	else:
		push_error("EnemyAIController: gridRenderer not found! Intent visualization will be disabled.")


func decide_action(pEntity: Entity = null) -> Dictionary:
	if pEntity:
		enemy_entity = pEntity

	if enemy_entity == null:
		return {"type": "wait"}

	var tree: SceneTree = get_tree()
	if tree == null:
		return {"type": "wait"}

	var firstPlayer: Node = tree.get_first_node_in_group("player")
	if firstPlayer is Node2D:
		_playerNode = firstPlayer as Node2D

	if (
		_playerNode == null
		or not _playerNode.has_method("alive")
		or not _playerNode.call("alive")
	):
		return {"type": "wait"}

	var playerEntRef: Variant = _playerNode.get("entity")
	if not playerEntRef is Entity:
		return {"type": "wait"}
	var playerEntity: Entity = playerEntRef as Entity

	var playerPos: Vector2i = playerEntity.grid_position()
	var enemyPos: Vector2i = enemy_entity.grid_position()
	var dist: int = _grid_distance(enemyPos, playerPos)

	var behaviorAction: Dictionary = {"type": "wait"}
	match behavior:
		BehaviorType.GRUNT:
			behaviorAction = _grunt_behavior(enemyPos, playerPos, dist)
		BehaviorType.ARCHER:
			behaviorAction = _archer_behavior(enemyPos, playerPos, dist)
		BehaviorType.TANK:
			behaviorAction = _tank_behavior(enemyPos, playerPos, dist)

	if _intentVisualizer:
		_intentVisualizer.visualizeIntent(enemy_entity, behaviorAction)
	return behaviorAction


func _grunt_behavior(enemyPos: Vector2i, playerPos: Vector2i, dist: int) -> Dictionary:
	var action: Dictionary = {"type": "wait"}
	# Rush player, attack when adjacent
	if dist <= 1:
		action = {"type": "attack", "target": _playerNode}
	else:
		var nextTile: Vector2i = _get_next_tile_towards(playerPos)
		if nextTile != enemyPos:
			action = {"type": "move", "target_x": nextTile.x, "target_y": nextTile.y}

	return action


func _archer_behavior(enemyPos: Vector2i, playerPos: Vector2i, dist: int) -> Dictionary:
	var action: Dictionary = {"type": "wait"}
	# Maintain 2-3 tile distance
	if dist < 2:
		# Too close, move away
		var nextTile: Vector2i = _get_next_tile_towards(playerPos, true)
		if nextTile != enemyPos:
			action = {"type": "move", "target_x": nextTile.x, "target_y": nextTile.y}
	elif dist > 3:
		# Too far, move towards
		var nextTile: Vector2i = _get_next_tile_towards(playerPos)
		if nextTile != enemyPos:
			action = {"type": "move", "target_x": nextTile.x, "target_y": nextTile.y}
	else:
		# In range 2-3, attack
		action = {"type": "attack", "target": _playerNode}

	return action


func _tank_behavior(enemyPos: Vector2i, playerPos: Vector2i, dist: int) -> Dictionary:
	# Slow advance, heavy damage
	return _grunt_behavior(enemyPos, playerPos, dist)


func _get_next_tile_towards(targetPos: Vector2i, away: bool = false) -> Vector2i:
	if enemy_entity == null or grid_system == null:
		return Vector2i(enemy_entity.x, enemy_entity.y) if enemy_entity else Vector2i.ZERO

	var currentPos: Vector2i = enemy_entity.grid_position()
	var bestTile: Vector2i = currentPos
	var minDist: int = 0
	if not away:
		minDist = GameConstants.GRID_W * 2 + 1
	else:
		minDist = -1

	var occupiedCoords: Array[Vector2i] = _get_occupied_coords()

	# Check all 8 neighbors
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue

			var nx: int = currentPos.x + dx
			var ny: int = currentPos.y + dy
			var nPos: Vector2i = Vector2i(nx, ny)

			if nx < 0 or nx >= GameConstants.GRID_W or ny < 0 or ny >= GameConstants.GRID_H:
				continue

			if grid_system.can_move(currentPos.x, currentPos.y, nx, ny):
				if nPos in occupiedCoords:
					continue

				var d: int = _grid_distance(nPos, targetPos)
				if away:
					if d > minDist:
						minDist = d
						bestTile = nPos
				else:
					if d < minDist:
						minDist = d
						bestTile = nPos

	return bestTile


func _get_occupied_coords() -> Array[Vector2i]:
	var occupied: Array[Vector2i] = []

	var tree: SceneTree = get_tree()
	if tree == null:
		return occupied

	var playerNodeLocal: Node = tree.get_first_node_in_group("player")
	if playerNodeLocal is Node2D:
		var pEntRef: Variant = playerNodeLocal.get("entity")
		if pEntRef is Entity:
			var pEnt: Entity = pEntRef as Entity
			occupied.append(Vector2i(pEnt.x, pEnt.y))

	for enemyNodeLocal: Node in tree.get_nodes_in_group("enemies"):
		if enemyNodeLocal == get_parent():  # Skip self
			continue
		if enemyNodeLocal is Node2D:
			var eNodeLocal: Node2D = enemyNodeLocal as Node2D
			var eEntRef: Variant = eNodeLocal.get("entity")
			if eEntRef is Entity:
				var eEnt: Entity = eEntRef as Entity
				if eEnt.alive():
					occupied.append(Vector2i(eEnt.x, eEnt.y))

	return occupied


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	var dx: int = DeterministicMath.absi(a.x - b.x)
	var dy: int = DeterministicMath.absi(a.y - b.y)
	return DeterministicMath.maxi(dx, dy)

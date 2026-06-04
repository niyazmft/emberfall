class_name CombatInput
extends Node

## CombatInput
## Handles targeting mode, target cycling, and attack execution.
## Sprint 1: Melee-only targeting (adjacent enemies).

signal targeting_started
signal targeting_cancelled
signal attack_executed(target: Node2D, damage: int)

enum State { IDLE, TARGETING }

var current_state: State = State.IDLE
var _player: Node2D
var _enemies_node: Node2D
var _grid_renderer: GridRenderer
var _grid_system: Node
var _valid_targets: Array[Node2D] = []
var _target_index: int = -1


func _init(player: Node2D, enemies_node: Node2D, grid_renderer: GridRenderer) -> void:
	_player = player
	_enemies_node = enemies_node
	_grid_renderer = grid_renderer
	_grid_system = AutoloadHelper.grid_system()


func handle_input(event: InputEvent) -> bool:
	if current_state == State.IDLE:
		if event.is_action_pressed("combat_mode"):
			_start_targeting()
			return true
	if current_state == State.TARGETING:
		if event.is_action_pressed("combat_confirm"):
			_execute_attack()
			return true
		if event.is_action_pressed("combat_cancel"):
			_stop_targeting()
			return true
		if event.is_action_pressed("combat_cycle"):
			_cycle_target()
			return true
		# Consume movement inputs during targeting to prevent player from moving
		if (
			event.is_action("move_up")
			or event.is_action("move_down")
			or event.is_action("move_left")
			or event.is_action("move_right")
		):
			return true
	return false


func _start_targeting() -> void:
	_find_valid_targets()
	if _valid_targets.is_empty():
		# Optional: Toast "No targets in range"
		return

	current_state = State.TARGETING
	_target_index = 0
	_update_highlights()
	targeting_started.emit()


func _stop_targeting() -> void:
	current_state = State.IDLE
	_target_index = -1
	_valid_targets.clear()
	if _grid_renderer:
		_grid_renderer.clear_highlights()
	targeting_cancelled.emit()


func _cycle_target() -> void:
	if _valid_targets.is_empty():
		return
	_target_index = (_target_index + 1) % _valid_targets.size()
	_update_highlights()


func _update_highlights() -> void:
	if not _grid_renderer:
		return
	_grid_renderer.clear_highlights()
	for i: int in range(_valid_targets.size()):
		var enemy: Node2D = _valid_targets[i]
		var enemy_ent: Entity = enemy.get("entity") as Entity
		if enemy_ent:
			var color: Color = Color.RED
			if i == _target_index:
				color = Color.YELLOW
			_grid_renderer.highlight_tile(enemy_ent.x, enemy_ent.y, color)


func _find_valid_targets() -> void:
	_valid_targets.clear()
	if not _player or not _enemies_node:
		return

	var player_ent: Entity = _player.get("entity") as Entity
	if not player_ent:
		return

	for enemy: Node in _enemies_node.get_children():
		if not enemy is Node2D:
			continue
		var enemy_node: Node2D = enemy as Node2D
		var enemy_ent: Entity = enemy_node.get("entity") as Entity
		if enemy_ent and enemy_ent.alive():
			var dx: int = abs(enemy_ent.x - player_ent.x)
			var dy: int = abs(enemy_ent.y - player_ent.y)
			# Melee range: adjacent including diagonals
			if dx <= 1 and dy <= 1 and (dx != 0 or dy != 0):
				_valid_targets.append(enemy_node)


func _execute_attack() -> void:
	if _target_index < 0 or _target_index >= _valid_targets.size():
		return

	var player_ent: Entity = _player.get("entity") as Entity
	if not player_ent:
		return

	var cost: int = CombatFormula.action_cost("attack_basic")
	if player_ent.ap < cost:
		# Optional: Toast "Not enough AP"
		return

	var target: Node2D = _valid_targets[_target_index]
	var target_ent: Entity = target.get("entity") as Entity
	if not target_ent:
		return

	# Gather cover tiles for damage formula
	var cover_tiles: Array[Vector2i] = []
	if _grid_system:
		for tile: TacTileData in _grid_system.all_tiles():
			if tile.has_cover():
				cover_tiles.append(tile.coords)

	# Calculate and apply damage
	var damage: int = CombatFormula.compute_damage_from_entities(
		player_ent, target_ent, cover_tiles
	)

	var lifecycle: Node = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.apply_damage(player_ent, target_ent, damage)
	else:
		target_ent.apply_damage(damage)

	# Consume AP
	player_ent.ap -= cost

	attack_executed.emit(target, damage)
	_stop_targeting()

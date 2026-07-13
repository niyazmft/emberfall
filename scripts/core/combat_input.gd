class_name CombatInput
extends Node

## CombatInput
## Handles targeting mode, target cycling, attack execution, and move targeting.
## Sprint 1: Melee-only targeting (adjacent enemies).
## Sprint 2: Mouse-based tile selection for attack and move.

signal targeting_started
signal targeting_cancelled
signal attack_executed(target: Node2D, damage: int)
signal move_targeting_started
signal move_targeting_cancelled
## FIX #596: Emitted before a player action mutates state, allowing CombatRoom to capture undo snapshot.
signal action_about_to_execute(action_type: String)

enum State { IDLE, TARGETING, MOVE_TARGETING }

var current_state: State = State.IDLE
var _player: Node2D
var _enemies_node: Node2D
var _grid_renderer: GridRenderer
var _grid_system: _GridSystem
var _valid_targets: Array[Node2D] = []
var _target_index: int = -1
var _valid_move_tiles: Array[Vector2i] = []


func _init(player: Node2D, enemies_node: Node2D, grid_renderer: GridRenderer) -> void:
	_player = player
	_enemies_node = enemies_node
	_grid_renderer = grid_renderer
	_grid_system = AutoloadHelper.grid_system()


func handle_input(event: InputEvent) -> bool:
	# Mouse handling — highest priority in targeting modes
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if current_state != State.IDLE:
				_cancel_current_mode()
				return true
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if current_state == State.TARGETING:
				return _handle_attack_click()
			elif current_state == State.MOVE_TARGETING:
				return _handle_move_click()
		return false

	# Keyboard / action handling
	if current_state == State.IDLE:
		if event.is_action_pressed("combat_mode"):
			return _start_targeting()
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
	if current_state == State.MOVE_TARGETING:
		# Consume movement inputs during move targeting to prevent keyboard movement
		if (
			event.is_action("move_up")
			or event.is_action("move_down")
			or event.is_action("move_left")
			or event.is_action("move_right")
		):
			return true
	return false


# ── Attack Targeting ──────────────────────────────────────────────────


func enter_targeting_mode() -> bool:
	if current_state == State.MOVE_TARGETING:
		_stop_move_targeting()
	return _start_targeting()


func _start_targeting() -> bool:
	_find_valid_targets()
	if _valid_targets.is_empty():
		return false

	current_state = State.TARGETING
	_target_index = 0
	_update_highlights()
	targeting_started.emit()
	return true


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
		var enemy_ent: Entity = null
		if enemy is BaseEnemy:
			enemy_ent = (enemy as BaseEnemy).entity
		elif enemy is Keeper:
			enemy_ent = (enemy as Keeper).entity

		if enemy_ent:
			var color: Color = Color.RED
			if i == _target_index:
				color = Color.YELLOW
			_grid_renderer.highlight_tile(enemy_ent.x, enemy_ent.y, color)


func _find_valid_targets() -> void:
	_valid_targets.clear()
	if not _player or not _enemies_node:
		return

	var player_ent: Entity = null
	if _player is Keeper:
		player_ent = (_player as Keeper).entity
	elif _player is BaseEnemy:
		player_ent = (_player as BaseEnemy).entity

	if not player_ent:
		return

	var px: int = player_ent.x
	var py: int = player_ent.y

	for enemy: Node in _enemies_node.get_children():
		if not enemy is Node2D:
			continue
		var enemy_node: Node2D = enemy as Node2D
		var enemy_ent: Entity = null
		if enemy_node is BaseEnemy:
			enemy_ent = (enemy_node as BaseEnemy).entity
		elif enemy_node is Keeper:
			enemy_ent = (enemy_node as Keeper).entity

		if enemy_ent and enemy_ent.hp > 0:
			var dx: int = DeterministicMath.absi(enemy_ent.x - px)
			var dy: int = DeterministicMath.absi(enemy_ent.y - py)
			# Melee range: adjacent including diagonals
			if dx <= 1 and dy <= 1 and (dx != 0 or dy != 0):
				_valid_targets.append(enemy_node)


func _execute_attack() -> void:
	if _target_index < 0 or _target_index >= _valid_targets.size():
		return

	var player_ent: Entity = null
	if _player is Keeper:
		player_ent = (_player as Keeper).entity
	elif _player is BaseEnemy:
		player_ent = (_player as BaseEnemy).entity

	if not player_ent:
		return

	var cost: int = CombatFormula.action_cost("attack_basic")
	if player_ent.ap < cost:
		return

	var target: Node2D = _valid_targets[_target_index]
	var target_ent: Entity = null
	if target is BaseEnemy:
		target_ent = (target as BaseEnemy).entity
	elif target is Keeper:
		target_ent = (target as Keeper).entity

	if not target_ent:
		return

	# Gather cover tiles for damage formula
	var cover_tiles: Array[Vector2i] = []
	if _grid_system:
		var all_tiles: Array[TacTileData] = _grid_system.all_tiles()
		for tile: TacTileData in all_tiles:
			if tile.has_cover():
				cover_tiles.append(tile.coords)

	# Calculate and apply damage
	var damage: int = CombatFormula.compute_damage_from_entities(
		player_ent, target_ent, cover_tiles
	)

	# FIX #596: Notify CombatRoom to capture undo snapshot before state mutation.
	action_about_to_execute.emit("attack")

	var lifecycle: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.apply_damage(player_ent, target_ent, damage)
	else:
		target_ent.apply_damage(damage)

	var new_ap: int = DeterministicMath.clampi(player_ent.ap - cost, 0, GameConstants.AP_MAX)
	player_ent.ap = new_ap

	var eb := AutoloadHelper.event_bus()
	if eb:
		eb.sfx_requested.emit("attack")

	attack_executed.emit(target, damage)
	_stop_targeting()


# ── Move Targeting ────────────────────────────────────────────────────


func enter_move_targeting_mode() -> bool:
	if current_state == State.TARGETING:
		_stop_targeting()
	return _start_move_targeting()


func _start_move_targeting() -> bool:
	_calculate_valid_move_tiles()
	if _valid_move_tiles.is_empty():
		return false

	current_state = State.MOVE_TARGETING
	if _grid_renderer:
		_grid_renderer.clear_highlights()
		for tile: Vector2i in _valid_move_tiles:
			_grid_renderer.highlight_tile(tile.x, tile.y, Color.GREEN)
	move_targeting_started.emit()
	return true


func _stop_move_targeting() -> void:
	current_state = State.IDLE
	_valid_move_tiles.clear()
	if _grid_renderer:
		_grid_renderer.clear_highlights()
	move_targeting_cancelled.emit()


func _calculate_valid_move_tiles() -> void:
	_valid_move_tiles.clear()
	if not _player:
		return

	var player_ent: Entity = null
	if _player is Keeper:
		player_ent = (_player as Keeper).entity
	elif _player is BaseEnemy:
		player_ent = (_player as BaseEnemy).entity

	if not player_ent:
		return

	var px: int = player_ent.x
	var py: int = player_ent.y

	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = px + dx
			var ny: int = py + dy
			if _grid_system and _grid_system.can_move(px, py, nx, ny):
				_valid_move_tiles.append(Vector2i(nx, ny))


func _execute_move_to(tx: int, ty: int) -> void:
	var entity := CombatEntity.get_entity(_player)
	if not entity:
		return

	var cost: int = CombatFormula.action_cost("move_cardinal")
	if entity.ap < cost:
		return

	# FIX #596: Notify CombatRoom to capture undo snapshot before state mutation.
	action_about_to_execute.emit("move")

	entity.set_grid_position(tx, ty)
	entity.ap -= cost
	_stop_move_targeting()


# ── Mouse Handling ─────────────────────────────────────────────────────


func _handle_attack_click() -> bool:
	if not _grid_renderer:
		return false

	var grid_pos: Vector2i = _grid_renderer.mouse_to_grid()
	if not _grid_system or not _grid_system.is_in_bounds(grid_pos.x, grid_pos.y):
		return false

	# Find enemy at clicked tile
	for i: int in range(_valid_targets.size()):
		var enemy: Node2D = _valid_targets[i]
		var enemy_ent: Entity = null
		if enemy is BaseEnemy:
			enemy_ent = (enemy as BaseEnemy).entity
		elif enemy is Keeper:
			enemy_ent = (enemy as Keeper).entity

		if enemy_ent and enemy_ent.x == grid_pos.x and enemy_ent.y == grid_pos.y:
			_target_index = i
			_update_highlights()
			_execute_attack()
			return true
	return false


func _handle_move_click() -> bool:
	if not _grid_renderer:
		return false

	var grid_pos: Vector2i = _grid_renderer.mouse_to_grid()
	for tile: Vector2i in _valid_move_tiles:
		if tile.x == grid_pos.x and tile.y == grid_pos.y:
			_execute_move_to(grid_pos.x, grid_pos.y)
			return true
	return false


# ── Cancellation ───────────────────────────────────────────────────────


func _cancel_current_mode() -> void:
	match current_state:
		State.TARGETING:
			_stop_targeting()
		State.MOVE_TARGETING:
			_stop_move_targeting()

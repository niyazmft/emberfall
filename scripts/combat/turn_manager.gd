class_name TurnManager
extends Node
## Manages turn-based combat flow, initiative, and AP economy.

# ── Signals ─────────────────────────────────────────────────────────
signal turn_started(entity: Entity, is_player: bool)
signal turn_ended(entity: Entity)
signal round_started(round_number: int)
signal combat_ended(victory: bool)

# ── Enums ───────────────────────────────────────────────────────────
enum CombatState {
	IDLE, COMBAT_START, INITIATIVE_PHASE, PLAYER_TURN, ENEMY_TURN, CHECK_END_CONDITIONS, COMBAT_END
}

# ── Properties ──────────────────────────────────────────────────────
var current_state: CombatState = CombatState.IDLE
var round_number: int = 0
var turn_order: Array[Node2D] = []
var current_turn_index: int = -1

var _player: Node2D
var _enemies: Array[Node2D] = []
var _lifecycle: Node
var _is_processing_state: bool = false


# ── Lifecycle ───────────────────────────────────────────────────────
func _ready() -> void:
	_lifecycle = AutoloadHelper.entity_lifecycle()
	if _lifecycle and _lifecycle.has_signal("entity_state_changed"):
		_lifecycle.connect("entity_state_changed", _on_entity_state_changed)


func _exit_tree() -> void:
	if _lifecycle and _lifecycle.is_connected("entity_state_changed", _on_entity_state_changed):
		_lifecycle.disconnect("entity_state_changed", _on_entity_state_changed)


# ── Public API ──────────────────────────────────────────────────────
func start_combat(p_player: Node2D, p_enemies: Array[Node2D]) -> void:
	_player = p_player
	_enemies = p_enemies
	_change_state(CombatState.COMBAT_START)


func end_player_turn() -> void:
	if current_state == CombatState.PLAYER_TURN:
		_end_current_turn()


## Dynamically adds an enemy to the combat.
func add_enemy(p_enemy: Node2D) -> void:
	if p_enemy not in _enemies:
		_enemies.append(p_enemy)


# ── Internal Logic ──────────────────────────────────────────────────
func _change_state(p_new_state: CombatState) -> void:
	if current_state == CombatState.COMBAT_END and p_new_state != CombatState.IDLE:
		return
	current_state = p_new_state
	if not _is_processing_state:
		_process_state_loop()


func _process_state_loop() -> void:
	_is_processing_state = true
	var iterations: int = 0
	const MAX_ITERATIONS: int = 200

	while _is_processing_state and iterations < MAX_ITERATIONS:
		var start_state: CombatState = current_state
		_process_current_state()

		if current_state == start_state:
			break
		iterations += 1

	if iterations >= MAX_ITERATIONS:
		push_error("TurnManager: Infinite state transition loop detected!")
		current_state = CombatState.COMBAT_END

	_is_processing_state = false


func _process_current_state() -> void:
	match current_state:
		CombatState.COMBAT_START:
			round_number = 0
			current_state = CombatState.INITIATIVE_PHASE

		CombatState.INITIATIVE_PHASE:
			_calculate_initiative()
			if turn_order.is_empty():
				current_state = CombatState.COMBAT_END
				combat_ended.emit(false)
				var eb := AutoloadHelper.event_bus()
				if eb:
					eb.combat_ended.emit(false)
				return

			round_number += 1
			round_started.emit(round_number)
			var eb := AutoloadHelper.event_bus()
			if eb:
				eb.round_started.emit(round_number)
			current_turn_index = 0
			_start_next_turn_logic()

		CombatState.PLAYER_TURN:
			_regen_current_actor_ap()
			var actor: Node2D = turn_order[current_turn_index]
			var entity := CombatEntity.get_entity(actor)
			turn_started.emit(entity, true)
			var eb := AutoloadHelper.event_bus()
			if eb:
				eb.turn_started.emit(entity, true)

		CombatState.ENEMY_TURN:
			_regen_current_actor_ap()
			var enemy: Node2D = turn_order[current_turn_index]
			var entity := CombatEntity.get_entity(enemy)
			turn_started.emit(entity, false)
			var eb := AutoloadHelper.event_bus()
			if eb:
				eb.turn_started.emit(entity, false)
			_execute_enemy_turn(enemy)

		CombatState.CHECK_END_CONDITIONS:
			_check_end_conditions()

		CombatState.COMBAT_END:
			_is_processing_state = false


func _is_actor_alive(actor: Node2D) -> bool:
	if not is_instance_valid(actor):
		return false
	var entity := CombatEntity.get_entity(actor)
	if entity:
		return entity.hp > 0
	return false


func _calculate_initiative() -> void:
	turn_order.clear()
	if _is_actor_alive(_player):
		turn_order.append(_player)

	for enemy: Node2D in _enemies:
		if _is_actor_alive(enemy):
			turn_order.append(enemy)

	turn_order.sort_custom(
		func(a: Node2D, b: Node2D) -> bool:
			var a_ent := CombatEntity.get_entity(a)
			var b_ent := CombatEntity.get_entity(b)
			if not a_ent or not b_ent:
				return false
			if a_ent.spd == b_ent.spd:
				return a.get_instance_id() < b.get_instance_id()
			return a_ent.spd > b_ent.spd
	)


func _start_next_turn_logic() -> void:
	if current_turn_index >= turn_order.size():
		current_state = CombatState.INITIATIVE_PHASE
		return

	var current_actor: Node2D = turn_order[current_turn_index]
	if not _is_actor_alive(current_actor):
		_advance_turn_logic()
		return

	var entity := CombatEntity.get_entity(current_actor)
	if not entity:
		_advance_turn_logic()
		return

	if entity.is_player:
		current_state = CombatState.PLAYER_TURN
	else:
		current_state = CombatState.ENEMY_TURN


func _end_current_turn() -> void:
	if current_turn_index < 0 or current_turn_index >= turn_order.size():
		_change_state(CombatState.CHECK_END_CONDITIONS)
		return

	var current_actor: Node2D = turn_order[current_turn_index]
	var entity := CombatEntity.get_entity(current_actor)

	if is_instance_valid(_lifecycle):
		_lifecycle.process_end_of_turn()

	if entity:
		turn_ended.emit(entity)
	_change_state(CombatState.CHECK_END_CONDITIONS)


func _advance_turn_logic() -> void:
	current_turn_index += 1
	_start_next_turn_logic()


func _execute_enemy_turn(p_enemy: Node2D) -> void:
	if p_enemy is BaseEnemy:
		(p_enemy as BaseEnemy).take_turn()

	_change_state(CombatState.CHECK_END_CONDITIONS)


func _regen_current_actor_ap() -> void:
	if current_turn_index < 0 or current_turn_index >= turn_order.size():
		return
	var actor: Node2D = turn_order[current_turn_index]
	var entity := CombatEntity.get_entity(actor)
	if entity:
		entity.ap = DeterministicMath.clampi(
			entity.ap + GameConstants.AP_REGEN, 0, GameConstants.AP_MAX
		)


func _is_combat_over() -> bool:
	var player_alive: bool = _is_actor_alive(_player)
	var enemies_alive: bool = false
	for enemy: Node2D in _enemies:
		if _is_actor_alive(enemy):
			enemies_alive = true
			break

	if not player_alive:
		_change_state(CombatState.COMBAT_END)
		combat_ended.emit(false)
		var eb := AutoloadHelper.event_bus()
		if eb:
			eb.combat_ended.emit(false)
		return true

	if not enemies_alive:
		_change_state(CombatState.COMBAT_END)
		combat_ended.emit(true)
		var eb := AutoloadHelper.event_bus()
		if eb:
			eb.combat_ended.emit(true)
		return true

	return false


func _check_end_conditions() -> void:
	if not _is_combat_over():
		_advance_turn_logic()


func _on_entity_state_changed(_entity: Entity, _old_state: int, new_state: int) -> void:
	# Entity.State constants used as ints to avoid potential circular dependency issues
	# DEAD = 3, GHOST = 4
	if new_state == 3 or new_state == 4:
		if current_state != CombatState.IDLE and current_state != CombatState.COMBAT_END:
			_is_combat_over()

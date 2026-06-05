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


# ── Public API ──────────────────────────────────────────────────────
func start_combat(p_player: Node2D, p_enemies: Array[Node2D]) -> void:
	_player = p_player
	_enemies = p_enemies
	_change_state(CombatState.COMBAT_START)


func end_player_turn() -> void:
	if current_state == CombatState.PLAYER_TURN:
		_end_current_turn()


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
				return

			round_number += 1
			round_started.emit(round_number)
			current_turn_index = 0
			_start_next_turn_logic()

		CombatState.PLAYER_TURN:
			_regen_current_actor_ap()
			var actor: Node2D = turn_order[current_turn_index]
			var entity: Entity = actor.get("entity") as Entity
			turn_started.emit(entity, true)

		CombatState.ENEMY_TURN:
			_regen_current_actor_ap()
			var enemy: Node2D = turn_order[current_turn_index]
			var entity: Entity = enemy.get("entity") as Entity
			turn_started.emit(entity, false)
			_execute_enemy_turn(enemy)

		CombatState.CHECK_END_CONDITIONS:
			_check_end_conditions()

		CombatState.COMBAT_END:
			_is_processing_state = false


func _calculate_initiative() -> void:
	turn_order.clear()
	if is_instance_valid(_player) and _player.has_method("alive") and _player.call("alive"):
		turn_order.append(_player)

	for enemy: Node2D in _enemies:
		if is_instance_valid(enemy) and enemy.has_method("alive") and enemy.call("alive"):
			turn_order.append(enemy)

	turn_order.sort_custom(
		func(a: Node2D, b: Node2D) -> bool:
			var a_ent: Entity = a.get("entity") as Entity
			var b_ent: Entity = b.get("entity") as Entity
			if not a_ent or not b_ent:
				return false
			return a_ent.spd > b_ent.spd
	)


func _start_next_turn_logic() -> void:
	if current_turn_index >= turn_order.size():
		current_state = CombatState.INITIATIVE_PHASE
		return

	var current_actor: Node2D = turn_order[current_turn_index]
	if (
		not is_instance_valid(current_actor)
		or not current_actor.has_method("alive")
		or not current_actor.call("alive")
	):
		_advance_turn_logic()
		return

	var entity: Entity = current_actor.get("entity") as Entity
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
	var entity: Entity = current_actor.get("entity") as Entity

	if is_instance_valid(_lifecycle):
		_lifecycle.call("process_end_of_turn")

	if entity:
		turn_ended.emit(entity)
	_change_state(CombatState.CHECK_END_CONDITIONS)


func _advance_turn_logic() -> void:
	current_turn_index += 1
	_start_next_turn_logic()


func _execute_enemy_turn(p_enemy: Node2D) -> void:
	if p_enemy.has_method("take_turn"):
		p_enemy.call("take_turn")

	current_state = CombatState.CHECK_END_CONDITIONS


func _regen_current_actor_ap() -> void:
	if current_turn_index < 0 or current_turn_index >= turn_order.size():
		return
	var actor: Node2D = turn_order[current_turn_index]
	var entity: Entity = actor.get("entity") as Entity
	if entity:
		entity.ap = DeterministicMath.clampi(
			entity.ap + GameConstants.AP_REGEN, 0, GameConstants.AP_MAX
		)


func _check_end_conditions() -> void:
	var player_alive: bool = (
		is_instance_valid(_player) and _player.has_method("alive") and _player.call("alive")
	)
	var enemies_alive: bool = false
	for enemy: Node2D in _enemies:
		if is_instance_valid(enemy) and enemy.has_method("alive") and enemy.call("alive"):
			enemies_alive = true
			break

	if not player_alive:
		current_state = CombatState.COMBAT_END
		combat_ended.emit(false)
		return

	if not enemies_alive:
		current_state = CombatState.COMBAT_END
		combat_ended.emit(true)
		return

	_advance_turn_logic()

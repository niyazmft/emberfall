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
var _lifecycle: _EntityLifecycle


# ── Lifecycle ───────────────────────────────────────────────────────
func _ready() -> void:
	_lifecycle = AutoloadHelper.entity_lifecycle() as _EntityLifecycle


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
	current_state = p_new_state
	_process_state()


func _process_state() -> void:
	match current_state:
		CombatState.COMBAT_START:
			round_number = 0
			_change_state(CombatState.INITIATIVE_PHASE)

		CombatState.INITIATIVE_PHASE:
			_calculate_initiative()
			round_number += 1
			round_started.emit(round_number)
			current_turn_index = 0
			_start_next_turn()

		CombatState.PLAYER_TURN:
			var actor: Node2D = turn_order[current_turn_index]
			var entity: Entity = actor.get("entity") as Entity
			_regen_ap(entity)
			turn_started.emit(entity, true)

		CombatState.ENEMY_TURN:
			var enemy: Node2D = turn_order[current_turn_index]
			var entity: Entity = enemy.get("entity") as Entity
			_regen_ap(entity)
			turn_started.emit(entity, false)
			_execute_enemy_turn(enemy)

		CombatState.CHECK_END_CONDITIONS:
			_check_end_conditions()

		CombatState.COMBAT_END:
			# Final state, signals already emitted
			pass


func _calculate_initiative() -> void:
	turn_order.clear()
	if _player and _player.has_method("alive") and _player.call("alive"):
		turn_order.append(_player)

	for enemy: Node2D in _enemies:
		if enemy and enemy.has_method("alive") and enemy.call("alive"):
			turn_order.append(enemy)

	turn_order.sort_custom(
		func(a: Node2D, b: Node2D) -> bool:
			var a_ent: Entity = a.get("entity") as Entity
			var b_ent: Entity = b.get("entity") as Entity
			return a_ent.spd > b_ent.spd
	)


func _start_next_turn() -> void:
	if current_turn_index >= turn_order.size():
		_change_state(CombatState.INITIATIVE_PHASE)
		return

	var current_actor: Node2D = turn_order[current_turn_index]
	if not current_actor.has_method("alive") or not current_actor.call("alive"):
		_advance_turn()
		return

	var entity: Entity = current_actor.get("entity") as Entity
	if entity.is_player:
		_change_state(CombatState.PLAYER_TURN)
	else:
		_change_state(CombatState.ENEMY_TURN)


func _end_current_turn() -> void:
	if current_turn_index < 0 or current_turn_index >= turn_order.size():
		_change_state(CombatState.CHECK_END_CONDITIONS)
		return

	var current_actor: Node2D = turn_order[current_turn_index]
	var entity: Entity = current_actor.get("entity") as Entity

	if _lifecycle:
		_lifecycle.process_end_of_turn()

	turn_ended.emit(entity)
	_change_state(CombatState.CHECK_END_CONDITIONS)


func _advance_turn() -> void:
	current_turn_index += 1
	_start_next_turn()


func _execute_enemy_turn(p_enemy: Node2D) -> void:
	if p_enemy.has_method("take_turn"):
		p_enemy.call("take_turn")

	_end_current_turn()


func _regen_ap(p_entity: Entity) -> void:
	# AP Regen logic: add AP_REGEN, cap at AP_MAX
	p_entity.ap = DeterministicMath.clampi(
		p_entity.ap + GameConstants.AP_REGEN, 0, GameConstants.AP_MAX
	)


func _check_end_conditions() -> void:
	var player_alive: bool = _player and _player.has_method("alive") and _player.call("alive")
	var enemies_alive: bool = false
	for enemy: Node2D in _enemies:
		if enemy.has_method("alive") and enemy.call("alive"):
			enemies_alive = true
			break

	if not player_alive:
		_change_state(CombatState.COMBAT_END)
		combat_ended.emit(false)
		return

	if not enemies_alive:
		_change_state(CombatState.COMBAT_END)
		combat_ended.emit(true)
		return

	_advance_turn()

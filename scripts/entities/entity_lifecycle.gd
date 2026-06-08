extends Node
class_name _EntityLifecycle

## Canonical owner of entity state transitions per system-spec §4.2, §4.3, §4.4.
## All Entity state changes should flow through this class; Entity itself is a
## RefCounted data block with typed mutators only.
#
## Responsibilities:
##   • Deterministic damage application with state transition
##   • HP healing with state reversal (DYING → IDLE)
##   • Turn-based state timers (STUNNED recovery, DYING → DEAD)
##   • MORAL_FLAG queue with sequential MWT checking
##   • Burden Event signal emission at first MWT crossing
##   • Spare / Execute player choices on dying enemies
##
## Reference: system-specification-core.md §4, §11.3

# ── Signals ────────────────────────────────────────────────────────────────
signal entity_state_changed(entity: Entity, old_state: Entity.State, new_state: Entity.State)
signal moral_flag_changed(entity: Entity, old_flag: int, new_flag: int)
## Emitted when a moral delta pushes the player from below MWT to ≥ MWT.
## Carries the new moral_flag value and how many deltas remain queued.
signal mwt_reached(moral_flag: int, remaining_deltas: int)
## Emitted whenever a moral delta is processed (including non-triggering ones).
signal moral_delta_processed(delta: int, source: String, sentient: bool)
## Emitted when a dying enemy is spared (true) or executed (false).
signal spare_or_execute(entity: Entity, was_spared: bool)


# ── Queued moral delta record ────────────────────────────────────────────
class MoralDeltaRecord:
	extends RefCounted
	var delta: int
	var enemy_id: String
	var enemy_name: String
	var sentient: bool
	var source: String  ## "kill", "spare", "environmental"

	func _init(
		p_delta: int, p_enemy_id: String, p_enemy_name: String, p_sentient: bool, p_source: String
	) -> void:
		delta = p_delta
		enemy_id = p_enemy_id
		enemy_name = p_enemy_name
		sentient = p_sentient
		source = p_source


# ── State timers ─────────────────────────────────────────────────────────
## Entity instance_id → turns remaining in DYING
var _dying_turns: Dictionary = {}
## Entity instance_id → turns remaining in STUNNED
var _stunned_turns: Dictionary = {}

# ── Moral queue ────────────────────────────────────────────────────────────
var _moral_queue: Array[MoralDeltaRecord] = []

# ── Player reference (set by combat / run system) ──────────────────────
var player_entity: Entity = null:
	set(value):
		player_entity = value

# ── Autoload access helpers ──────────────────────────────────────────────────
# Delegated to AutoloadHelper — single source of truth for safe autoload access.


func _config_int(key: String, fallback: int) -> int:
	return AutoloadHelper.config_int(key, fallback)


func _update_burden_weight(flag: int) -> void:
	var n: Node = AutoloadHelper.burden_manager()
	if n != null and n.has_method("update_moral_weight"):
		n.update_moral_weight(flag)


func _record_kill(enemy_id: String, enemy_name: String) -> void:
	var n: Node = AutoloadHelper.burden_manager()
	if n != null and n.has_method("record_sentient_kill"):
		n.record_sentient_kill(enemy_id, enemy_name)


# ── Damage & State ───────────────────────────────────────────────────────


## Canonical damage application. Updates defender HP and transitions state
## deterministically. If damage is lethal, targets enter DYING (not DEAD).
func apply_damage(
	attacker: Entity, defender: Entity, damage: int, damage_type: String = "PHYSICAL"
) -> void:
	var old_hp: int = defender.hp
	var new_hp: int = DeterministicMath.clampi(old_hp - damage, 0, defender.hp_max)
	defender.hp = new_hp

	if damage > 0:
		defender.damage_taken.emit(damage, damage_type)

	if (
		new_hp == 0
		and defender.state != Entity.State.DYING
		and defender.state != Entity.State.DEAD
		and defender.state != Entity.State.GHOST
	):
		_change_state(defender, Entity.State.DYING)
		var dying_duration: int = _config_int("DYING_DURATION_TURNS", 1)
		_dying_turns[defender.get_instance_id()] = dying_duration


## Heal an entity. If healed while DYING and HP > 0, reverses to IDLE.
## Deterministic: always clamps to HP_MAX.
func heal(entity: Entity, amount: int) -> void:
	var was_dying: bool = entity.state == Entity.State.DYING
	entity.heal(amount)
	if was_dying and entity.hp > 0 and entity.state == Entity.State.DYING:
		_change_state(entity, Entity.State.IDLE)
		_dying_turns.erase(entity.get_instance_id())


## Apply stun to an entity for a fixed number of turns.
## Reversible: STUNNED → IDLE after duration expires in process_end_of_turn().
func stun(entity: Entity, duration_turns: int = 1) -> void:
	if not entity.alive():
		return
	_change_state(entity, Entity.State.STUNNED)
	_stunned_turns[entity.get_instance_id()] = duration_turns


# ── Kill / Spare / Execute ───────────────────────────────────────────────


## Record a sentient enemy kill and queue the moral delta.
## Does NOT transition the defender to DEAD — that happens via
## execute_entity() at player choice, or automatically at end-of-turn expiry.
#
## @param attacker Usually the player Entity; may be null for environmental.
## @param defender The enemy Entity that reached 0 HP.
## @param sentient Whether this enemy counts for moral weight.
## @param enemy_id Stable encounter identifier for BurdenManager kill log.
## @param enemy_name Display name for logging.
func process_kill(
	attacker: Entity,
	defender: Entity,
	sentient: bool = true,
	enemy_id: String = "",
	enemy_name: String = ""
) -> void:
	## Ensure defender is at 0 HP and DYING
	if defender.hp > 0:
		apply_damage(attacker, defender, defender.hp)

	var delta: int = (
		_config_int("MORAL_DELTA_KILL", 1) if sentient else _config_int("MORAL_DELTA_ENV", 0)
	)
	var record: MoralDeltaRecord = MoralDeltaRecord.new(
		delta, enemy_id, enemy_name, sentient, "kill"
	)
	_moral_queue.append(record)

	if sentient and attacker != null and attacker.is_player:
		var id: String = (
			enemy_id
			if not enemy_id.is_empty()
			else (enemy_name if not enemy_name.is_empty() else "unknown")
		)
		_record_kill(id, enemy_name)


## Spare a dying enemy. Costs 1 AP, applies –1 MORAL_DELTA, transitions target
## to GHOST. Returns true if successful, false if player lacks AP or target is
## not DYING.
func spare_entity(player: Entity, target: Entity) -> bool:
	if player.ap < 1:
		push_warning("EntityLifecycle.spare_entity: insufficient AP (%d)" % player.ap)
		return false

	if target.state != Entity.State.DYING:
		push_warning("EntityLifecycle.spare_entity: target not DYING (state=%d)" % target.state)
		return false

	player.ap = DeterministicMath.clampi(player.ap - 1, 0, player.ap)

	var delta: int = _config_int("MORAL_DELTA_SPARE", -1)
	var record: MoralDeltaRecord = MoralDeltaRecord.new(
		delta, target.entity_name, target.entity_name, true, "spare"
	)
	_moral_queue.append(record)

	_change_state(target, Entity.State.GHOST)
	_dying_turns.erase(target.get_instance_id())
	spare_or_execute.emit(target, true)
	return true


## Execute a dying enemy. Transitions target to DEAD. The +1 MORAL_DELTA is
## already queued by process_kill(); this call only finalises the state.
func execute_entity(target: Entity) -> void:
	if target.state != Entity.State.DYING:
		push_warning("EntityLifecycle.execute_entity: target not DYING (state=%d)" % target.state)
		return
	_change_state(target, Entity.State.DEAD)
	_dying_turns.erase(target.get_instance_id())
	_trigger_loot_drop(target)
	spare_or_execute.emit(target, false)


# ── Moral Flag Queue ─────────────────────────────────────────────────────


## Resolve queued moral deltas sequentially, checking MWT after each increment.
## Per spec §11.3: first kill that hits MWT triggers Burden Event; subsequent
## kills in same phase are queued for next legal moment (i.e. next call).
func resolve_moral_queue() -> void:
	if player_entity == null:
		push_warning("EntityLifecycle.resolve_moral_queue: player_entity not set")
		return

	while not _moral_queue.is_empty():
		var record: MoralDeltaRecord = _moral_queue[0]

		if record.delta == 0:
			_moral_queue.remove_at(0)
			continue

		var old_flag: int = player_entity.moral_flag
		var new_flag: int = DeterministicMath.clampi(old_flag + record.delta, 0, 999)
		player_entity.moral_flag = new_flag

		moral_flag_changed.emit(player_entity, old_flag, new_flag)
		moral_delta_processed.emit(record.delta, record.source, record.sentient)

		## If this specific increment crossed the MWT threshold, trigger and stop.
		if old_flag < GameConstants.MWT and new_flag >= GameConstants.MWT:
			_update_burden_weight(new_flag)
			mwt_reached.emit(new_flag, _moral_queue.size() - 1)
			_moral_queue.remove_at(0)
			return

		_moral_queue.remove_at(0)

	## Queue exhausted without hitting MWT — still sync BurdenManager state.
	_update_burden_weight(player_entity.moral_flag)


## Returns the number of deltas still queued (for UI / debug).
func get_queued_delta_count() -> int:
	return _moral_queue.size()


## Peek at remaining queued deltas. Returns a shallow copy.
func get_queued_deltas() -> Array[MoralDeltaRecord]:
	return _moral_queue.duplicate()


## Reset the moral queue (e.g. on run start / sanctum return).
func reset_moral_queue() -> void:
	_moral_queue.clear()


# ── Turn-Based State Resolution ──────────────────────────────────────────


## Call at end of every combat turn. Decrements state timers and resolves
## expired states deterministically.
func process_end_of_turn() -> void:
	_resolve_dying_timers()
	_resolve_stunned_timers()


func _resolve_dying_timers() -> void:
	var to_remove: Array[int] = []
	for id: int in _dying_turns.keys():
		_dying_turns[id] -= 1
		if _dying_turns[id] <= 0:
			to_remove.append(id)

	for id: int in to_remove:
		var obj: Object = instance_from_id(id)
		if obj is Entity:
			var ent: Entity = obj as Entity
			if ent.alive() and ent.state == Entity.State.DYING:
				## Expired without player choice → DEAD
				_change_state(ent, Entity.State.DEAD)
				_trigger_loot_drop(ent)
		_dying_turns.erase(id)


func _resolve_stunned_timers() -> void:
	var to_remove: Array[int] = []
	for id: int in _stunned_turns.keys():
		_stunned_turns[id] -= 1
		if _stunned_turns[id] <= 0:
			to_remove.append(id)

	for id: int in to_remove:
		var obj: Object = instance_from_id(id)
		if obj is Entity:
			var ent: Entity = obj as Entity
			if ent.state == Entity.State.STUNNED:
				_change_state(ent, Entity.State.IDLE)
		_stunned_turns.erase(id)


# ── Helpers ──────────────────────────────────────────────────────────────


func _trigger_loot_drop(entity: Entity) -> void:
	if entity.is_player:
		return

	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	if config_loader == null:
		return

	var enemies_config: Dictionary = config_loader.getValue("enemies", "", {})
	var archetype_id: String = entity.archetype_id
	if archetype_id.is_empty():
		return

	if not enemies_config.has(archetype_id):
		return

	var loot_table_id: String = enemies_config[archetype_id].get("loot_table_id", "")
	if loot_table_id.is_empty():
		return

	var table: LootTable = LootTable.load_loot_table(loot_table_id)
	if table:
		# Use moral flag and HP max as a crude source of entropy for the loot roll
		var seed_val: int = entity.moral_flag + entity.hp_max
		var dropped_items: Array[String] = table.roll_loot(seed_val)
		var inventory_manager: Node = AutoloadHelper.inventory_manager()
		if inventory_manager:
			for item_id: String in dropped_items:
				inventory_manager.call("add_item", item_id, 1)


func _change_state(entity: Entity, new_state: Entity.State) -> void:
	var old_state: Entity.State = entity.state
	if old_state == new_state:
		return
	entity.state = new_state
	entity_state_changed.emit(entity, old_state, new_state)


## Clear all tracked timers (useful on scene teardown / run reset).
func clear_timers() -> void:
	_dying_turns.clear()
	_stunned_turns.clear()

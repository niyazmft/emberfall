class_name Entity
extends Resource
## Stat block for player and enemy entities.
## References: system-specification-core.md §4.1
##
## State transitions are owned by EntityLifecycle; this class only
## holds data and exposes typed mutators.

# ── Signals ─────────────────────────────────────────────────────────
signal position_changed(x: int, y: int)
signal elevation_changed(elevation: int)
signal facing_changed(fx: int, fy: int)
signal state_changed(state: State)
signal hp_changed(new_hp: int, old_hp: int)
signal ap_changed(new_ap: int, old_ap: int)
signal status_effect_added(effect: StatusEffect)
signal status_effect_removed(effect: StatusEffect)

# ── Status Effects ──────────────────────────────────────────────────
var status_effects: Array[StatusEffect] = []
var _cached_off_bonus: int = 0
var _cached_def_bonus: int = 0
var _cached_spd_mult: float = 1.0

# ── Grid Position ───────────────────────────────────────────────────
@export var x: int = 0:
	set(p_value):
		if x != p_value:
			x = p_value
			position_changed.emit(x, y)

@export var y: int = 0:
	set(p_value):
		if y != p_value:
			y = p_value
			position_changed.emit(x, y)

@export var elevation: int = 0:
	set(p_value):
		if elevation != p_value:
			elevation = p_value
			elevation_changed.emit(elevation)

## Facing vector as integer components. Normalized to cardinal directions.
@export var facing_x: int = 0:
	set(p_value):
		if facing_x != p_value:
			facing_x = p_value
			facing_changed.emit(facing_x, facing_y)

@export var facing_y: int = 1:
	set(p_value):
		if facing_y != p_value:
			facing_y = p_value
			facing_changed.emit(facing_x, facing_y)

# ── Core Stats ──────────────────────────────────────────────────────
@export var hp_max: int = 1:
	set(p_value):
		hp_max = DeterministicMath.clampi(p_value, 1, GameConstants.HP_MAX_BOUND)

@export var hp: int = 1:
	set(p_value):
		var old_hp: int = hp
		hp = DeterministicMath.clampi(p_value, 0, hp_max)
		if hp != old_hp:
			hp_changed.emit(hp, old_hp)

@export var off: int = 0:
	get:
		return DeterministicMath.clampi(off + _cached_off_bonus, 0, GameConstants.STAT_OFF_BOUND)
	set(p_value):
		off = DeterministicMath.clampi(p_value, 0, GameConstants.STAT_OFF_BOUND)

@export var def_: int = 0:
	get:
		return DeterministicMath.clampi(def_ + _cached_def_bonus, 0, GameConstants.STAT_DEF_BOUND)
	set(p_value):
		def_ = DeterministicMath.clampi(p_value, 0, GameConstants.STAT_DEF_BOUND)

@export var spd: int = 1:
	get:
		return DeterministicMath.clampi(
			int(float(spd) * _cached_spd_mult), 1, GameConstants.STAT_SPD_BOUND
		)
	set(p_value):
		spd = DeterministicMath.clampi(p_value, 1, GameConstants.STAT_SPD_BOUND)

# ── Moral Weight ────────────────────────────────────────────────────
@export var moral_flag: int = 0:
	set(p_value):
		moral_flag = DeterministicMath.clampi(p_value, 0, 999)

# ── AP (per-phase transient; not persisted across runs) ─────────────
var ap: int = GameConstants.AP_MAX:
	set(p_value):
		var old_ap: int = ap
		ap = DeterministicMath.clampi(p_value, 0, GameConstants.AP_MAX)
		if ap != old_ap:
			ap_changed.emit(ap, old_ap)

# ── State ───────────────────────────────────────────────────────────
enum State { IDLE, STUNNED, DYING, DEAD, GHOST }
@export var state: State = State.IDLE:
	set(p_value):
		if state != p_value:
			state = p_value
			state_changed.emit(state)

# ── Identity ────────────────────────────────────────────────────────
@export var entity_name: String = "Unnamed"
@export var archetype_id: String = ""
@export var is_player: bool = false


# ── Constructors ──────────────────────────────────────────────────
func _init(
	p_name: String = "Unnamed",
	p_x: int = 0,
	p_y: int = 0,
	p_hp: int = 1,
	p_off: int = 0,
	p_def: int = 0,
	p_facing_x: int = 0,
	p_facing_y: int = 1,
	p_elevation: int = 0
) -> void:
	entity_name = p_name
	x = p_x
	y = p_y
	hp_max = p_hp
	hp = p_hp
	off = p_off
	def_ = p_def
	facing_x = p_facing_x
	facing_y = p_facing_y
	elevation = p_elevation


# ── Queries ────────────────────────────────────────────────────────
func alive() -> bool:
	return state != State.DEAD and state != State.GHOST


func can_act() -> bool:
	return alive() and (state == State.IDLE)


func grid_position() -> Vector2i:
	return Vector2i(x, y)


# ── Mutators ────────────────────────────────────────────────────────
func set_facing(dx: int, dy: int) -> void:
	facing_x = dx
	facing_y = dy


func set_grid_position(gx: int, gy: int) -> void:
	x = gx
	y = gy
	# Elevation is refreshed by caller (grid system) after move.


func apply_damage(dmg: int) -> void:
	hp = DeterministicMath.clampi(hp - dmg, 0, hp_max)
	## State transitions are owned by EntityLifecycle; this method
	## only adjusts HP.  Use EntityLifecycle.apply_damage() for canonical
	## damage with automatic state transitions.


func heal(amount: int) -> void:
	hp = DeterministicMath.clampi(hp + amount, 0, hp_max)


# ── Status Effect Mutators ──────────────────────────────────────────
func add_status_effect(effect: StatusEffect) -> void:
	status_effects.append(effect)
	_recompute_effect_caches()
	status_effect_added.emit(effect)


func remove_status_effect(effect: StatusEffect) -> void:
	var idx: int = status_effects.find(effect)
	if idx != -1:
		status_effects.remove_at(idx)
		_recompute_effect_caches()
		status_effect_removed.emit(effect)


func _recompute_effect_caches() -> void:
	_cached_off_bonus = 0
	_cached_def_bonus = 0
	_cached_spd_mult = 1.0

	for effect: StatusEffect in status_effects:
		_cached_off_bonus += effect.combatFormulaModifier.get("off_bonus", 0)
		_cached_def_bonus += effect.combatFormulaModifier.get("def_bonus", 0)
		_cached_spd_mult *= effect.combatFormulaModifier.get("spd_mult", 1.0)


func has_status_effect(effect_id: String) -> bool:
	for effect: StatusEffect in status_effects:
		if effect.id == effect_id:
			return true
	return false


func get_status_effect(effect_id: String) -> StatusEffect:
	for effect: StatusEffect in status_effects:
		if effect.id == effect_id:
			return effect
	return null

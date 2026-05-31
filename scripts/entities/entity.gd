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

# ── Grid Position ───────────────────────────────────────────────────
@export var x: int = 0:
	set(value):
		if x != value:
			x = value
			position_changed.emit(x, y)

@export var y: int = 0:
	set(value):
		if y != value:
			y = value
			position_changed.emit(x, y)

@export var elevation: int = 0:
	set(value):
		if elevation != value:
			elevation = value
			elevation_changed.emit(elevation)

## Facing vector as integer components. Normalized to cardinal directions.
@export var facing_x: int = 0:
	set(value):
		if facing_x != value:
			facing_x = value
			facing_changed.emit(facing_x, facing_y)

@export var facing_y: int = 1:
	set(value):
		if facing_y != value:
			facing_y = value
			facing_changed.emit(facing_x, facing_y)

# ── Core Stats ──────────────────────────────────────────────────────
@export var hp_max: int = 1:
	set(value):
		hp_max = DeterministicMath.clampi(value, 1, GameConstants.HP_MAX_BOUND)

@export var hp: int = 1:
	set(value):
		var old_hp: int = hp
		hp = DeterministicMath.clampi(value, 0, hp_max)
		if hp != old_hp:
			hp_changed.emit(hp, old_hp)

@export var off: int = 0:
	set(value):
		off = DeterministicMath.clampi(value, 0, GameConstants.STAT_OFF_BOUND)

@export var def_: int = 0:
	set(value):
		def_ = DeterministicMath.clampi(value, 0, GameConstants.STAT_DEF_BOUND)

@export var spd: int = 1:
	set(value):
		spd = DeterministicMath.clampi(value, 1, GameConstants.STAT_SPD_BOUND)

# ── Moral Weight ────────────────────────────────────────────────────
@export var moral_flag: int = 0:
	set(value):
		moral_flag = DeterministicMath.clampi(value, 0, 999)

# ── AP (per-phase transient; not persisted across runs) ─────────────
var ap: int = GameConstants.AP_MAX

# ── State ───────────────────────────────────────────────────────────
enum State { IDLE, STUNNED, DYING, DEAD, GHOST }
@export var state: State = State.IDLE:
	set(value):
		if state != value:
			state = value
			state_changed.emit(state)

# ── Identity ────────────────────────────────────────────────────────
@export var entity_name: String = "Unnamed"
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

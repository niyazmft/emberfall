class_name ApparitionStateMachine
extends BaseStateMachine

## ApparitionStateMachine
## Hierarchical state machine for the Apparition Composite Renderer.
## States: MANIFEST → IDLE ↔ RECOIL → ABSOLVE → (destroy or hide)
##
## References: DON-83 §5 State machine integration

enum ApparitionState {
	INACTIVE,
	MANIFEST,
	IDLE,
	RECOIL,
	ABSORB,  # note: spec uses "absolve"; internally we call it ABSORB for engine naming
	ERROR,
}

## Emitted when the apparition fully manifests (first frame of IDLE).
signal manifested
## Emitted when recoil starts.
signal recoiled
## Emitted when absolution completes.
signal absolved
## Emitted every frame during IDLE with intensity for breathing effects.
signal idle_pulse(intensity: float)

## Owning ApparitionRenderer weakref (injected at construction).
var _renderer: WeakRef

## Recoil z-index promotion bookkeeping.
var _recoil_promotion_active: bool = false

## Frame-rate independent manifest timer.
var _manifest_timer: float = 0.0
var _manifest_duration: float = 0.3

## Frame-rate independent recoil timer.
var _recoil_timer: float = 0.0
var _recoil_duration: float = 0.05

## Frame-rate independent absolve timer.
var _absorb_timer: float = 0.0
var _absorb_duration: float = 0.4


## Constructor: takes the renderer node so entry/exit actions can mutate it.
func _init(renderer: Node) -> void:
	_renderer = weakref(renderer)
	_register_states()
	_register_transitions()
	set_default_state(ApparitionState.INACTIVE)
	set_error_state(ApparitionState.ERROR)
	initialize()


# ---------------------------------------------------------------------------
# State Registration
# ---------------------------------------------------------------------------


func _register_states() -> void:
	register_state(
		ApparitionState.INACTIVE,
		&"INACTIVE",
		Callable(self, "_enter_inactive"),
		Callable(),
		Callable()
	)
	register_state(
		ApparitionState.MANIFEST,
		&"MANIFEST",
		Callable(self, "_enter_manifest"),
		Callable(),
		Callable(self, "_update_manifest")
	)
	register_state(
		ApparitionState.IDLE,
		&"IDLE",
		Callable(self, "_enter_idle"),
		Callable(),
		Callable(self, "_update_idle")
	)
	register_state(
		ApparitionState.RECOIL,
		&"RECOIL",
		Callable(self, "_enter_recoil"),
		Callable(self, "_exit_recoil"),
		Callable(self, "_update_recoil")
	)
	register_state(
		ApparitionState.ABSORB,
		&"ABSORB",
		Callable(self, "_enter_absorb"),
		Callable(),
		Callable(self, "_update_absorb")
	)
	register_state(
		ApparitionState.ERROR, &"ERROR", Callable(self, "_enter_error"), Callable(), Callable()
	)


# ---------------------------------------------------------------------------
# Transition Registration
# ---------------------------------------------------------------------------


func _register_transitions() -> void:
	# INACTIVE → MANIFEST
	register_transition(ApparitionState.INACTIVE, ApparitionState.MANIFEST)

	# MANIFEST → IDLE (guard: manifest timer elapsed)
	register_transition(
		ApparitionState.MANIFEST,
		ApparitionState.IDLE,
		Callable(self, "_guard_manifest_done"),
		Callable()
	)

	# IDLE → RECOIL (guard: recoil command received)
	register_transition(
		ApparitionState.IDLE,
		ApparitionState.RECOIL,
		Callable(self, "_guard_recoil_triggered"),
		Callable()
	)

	# RECOIL → IDLE (guard: recoil timer elapsed)
	register_transition(
		ApparitionState.RECOIL,
		ApparitionState.IDLE,
		Callable(self, "_guard_recoil_done"),
		Callable()
	)

	# IDLE → ABSORB (guard: absolve / burden deactivated)
	register_transition(
		ApparitionState.IDLE,
		ApparitionState.ABSORB,
		Callable(self, "_guard_absolve_triggered"),
		Callable()
	)

	# RECOIL → ABSORB
	register_transition(
		ApparitionState.RECOIL,
		ApparitionState.ABSORB,
		Callable(self, "_guard_absolve_triggered"),
		Callable()
	)

	# ABSORB → INACTIVE (guard: absorb timer elapsed)
	register_transition(
		ApparitionState.ABSORB,
		ApparitionState.INACTIVE,
		Callable(self, "_guard_absorb_done"),
		Callable()
	)

	# ERROR → INACTIVE (recovery)
	register_transition(ApparitionState.ERROR, ApparitionState.INACTIVE, Callable(), Callable())


# ---------------------------------------------------------------------------
# Public Commands
# ---------------------------------------------------------------------------


## Call when burden_active toggles true.
func cmd_manifest() -> void:
	transition_to(ApparitionState.MANIFEST)


## Call when the owner entity receives damage / is recoiling.
func cmd_recoil() -> void:
	if current_state == ApparitionState.IDLE:
		transition_to(ApparitionState.RECOIL)


## Call when burden_active toggles false (player absolves / sanctum reset).
func cmd_absolve() -> void:
	if current_state == ApparitionState.IDLE or current_state == ApparitionState.RECOIL:
		transition_to(ApparitionState.ABSORB)


## Reset to INACTIVE immediately.
func cmd_reset() -> void:
	force_state(ApparitionState.INACTIVE)


# ---------------------------------------------------------------------------
# Entry / Update / Exit
# ---------------------------------------------------------------------------


func _enter_inactive(_ctx: Dictionary) -> void:
	var r: Node2D = _renderer.get_ref() as Node2D
	if r:
		r.visible = false
	_recoil_promotion_active = false


func _enter_manifest(_ctx: Dictionary) -> void:
	_manifest_timer = 0.0
	var r: Node2D = _renderer.get_ref() as Node2D
	if r:
		r.visible = true
		# Start from zero opacity
		_set_renderer_opacity(0.0)


func _update_manifest(delta: float, _elapsed: float) -> void:
	_manifest_timer += delta
	var t: float = clampf(_manifest_timer / _manifest_duration, 0.0, 1.0)
	_set_renderer_opacity(t)
	if _manifest_timer >= _manifest_duration:
		cmd_transition_if_guarded(ApparitionState.IDLE)


func _enter_idle(_ctx: Dictionary) -> void:
	_set_renderer_opacity(1.0)
	manifested.emit()


func _update_idle(_delta: float, elapsed: float) -> void:
	# Breathing pulse: slow sine 0.92 – 1.08 over ~2.3 s
	var pulse: float = 1.0 + sin(elapsed * 2.734) * 0.08
	idle_pulse.emit(pulse)
	var r: Node2D = _renderer.get_ref() as Node2D
	if r:
		# Apply subtle vertical float non-destructively via shader uniform
		# or child offsets. We avoid mutating position directly to prevent
		# drift under sync_to_owner.
		pass


func _enter_recoil(_ctx: Dictionary) -> void:
	_recoil_timer = 0.0
	_recoil_promotion_active = true
	var r := _renderer.get_ref() as ApparitionRenderer
	if r:
		r.promote_z_index()
	recoiled.emit()


func _exit_recoil(_ctx: Dictionary) -> void:
	_recoil_promotion_active = false
	var r := _renderer.get_ref() as ApparitionRenderer
	if r:
		r.restore_z_index()


func _update_recoil(delta: float, _elapsed: float) -> void:
	_recoil_timer += delta
	var r: Node2D = _renderer.get_ref() as Node2D
	if r:
		# Slight horizontal jitter during recoil — deterministic seed based on entity position
		var jitter_seed: int = int(r.position.x * 1000.0) + int(r.position.y * 1000.0)
		var jitter: float = (SeedGovernance.fract_from_seed(jitter_seed) - 0.5) * 3.0
		r.position.x += jitter * delta * 60.0
	if _recoil_timer >= _recoil_duration:
		cmd_transition_if_guarded(ApparitionState.IDLE)


func _enter_absorb(_ctx: Dictionary) -> void:
	_absorb_timer = 0.0


func _update_absorb(delta: float, _elapsed: float) -> void:
	_absorb_timer += delta
	var t: float = clampf(_absorb_timer / _absorb_duration, 0.0, 1.0)
	_set_renderer_opacity(1.0 - t)
	if _absorb_timer >= _absorb_duration:
		cmd_transition_if_guarded(ApparitionState.INACTIVE)
		absolved.emit()


func _enter_error(_ctx: Dictionary) -> void:
	push_error("ApparitionStateMachine entered ERROR state.")


# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------


func _guard_manifest_done(_ctx: Dictionary) -> bool:
	return _manifest_timer >= _manifest_duration


func _guard_recoil_triggered(_ctx: Dictionary) -> bool:
	# The recoil command must have been issued via cmd_recoil; handled by transition_to guard already.
	return true


func _guard_recoil_done(_ctx: Dictionary) -> bool:
	return _recoil_timer >= _recoil_duration


func _guard_absolve_triggered(_ctx: Dictionary) -> bool:
	# Handled by explicit cmd_absolve transition.
	return true


func _guard_absorb_done(_ctx: Dictionary) -> bool:
	return _absorb_timer >= _absorb_duration


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _set_renderer_opacity(alpha: float) -> void:
	var r := _renderer.get_ref() as ApparitionRenderer
	if r:
		r.set_stack_opacity(clampf(alpha, 0.0, 1.0))


## Convenience so guards can trigger transitions safely.
func cmd_transition_if_guarded(target: int) -> void:
	transition_to(target)

## EventBus — Central cross-system signal hub for Emberfall.
##
## All signals that need to cross autoload boundaries are declared here.
## Emitting autoloads fire their own signal AND re-emit via EventBus so that
## listeners never need a direct reference to the originating system.
##
## Rules:
##   • No logic, no state, no connections — pure signal declarations only.
##   • Inner-class types (e.g. BurdenKillRecord) are widened to Object/Array
##     to avoid hard coupling to their owner scripts.
##   • Enum types (e.g. InputDevice, AspectMode) are widened to int for the
##     same reason.
class_name _EventBus
extends Node

# ── EntityLifecycle ──────────────────────────────────────────────────────────

## Fired when an entity transitions between gameplay states.
signal entity_state_changed(entity: Entity, old_state: Entity.State, new_state: Entity.State)

## Fired when an entity's moral flag bitmask changes.
signal moral_flag_changed(entity: Entity, old_flag: int, new_flag: int)

## Fired when the cumulative moral-weight threshold is reached.
signal mwt_reached(moral_flag: int, remaining_deltas: int)

## Fired after each individual moral delta is processed.
signal moral_delta_processed(delta: int, source: String, sentient: bool)

## Fired when the player resolves a spare-or-execute choice.
signal spare_or_execute(entity: Entity, was_spared: bool)

# ── BurdenManager ────────────────────────────────────────────────────────────

## Fired when the kill-history queue changes.
## kill_queue is an Array of BurdenKillRecord (untyped to avoid inner-class coupling).
signal kill_history_changed(kill_queue: Array)

## Fired when burden mode activates or deactivates.
signal burden_active_changed(active: bool)

## Fired when a burden event resolves.
## result is a BurdenEventResult instance (widened to Object to avoid coupling).
signal burden_event_triggered(result: Object)

# ── TurnManager (Widened for EventBus) ───────────────────────────────────────

## Fired when a new turn starts.
signal turn_started(entity: Entity, is_player: bool)

## Fired when a round starts.
signal round_started(round_number: int)

## Fired when combat ends.
signal combat_ended(victory: bool)

# ── RunManager ───────────────────────────────────────────────────────────────

## Fired when a new run begins.
signal run_started(p_seed: int)

## Fired each time the player enters a new room.
signal room_entered(p_room_index: int, p_room_data: Dictionary)

## Fired when combat in a room is fully resolved.
signal combat_resolved_signal(p_room_index: int)

## Fired after moral flags are recalculated for the current run.
signal moral_flags_updated(p_deltas: Array)

## Fired when a biome echo ability triggers.
signal biome_echo_triggered(p_biome_index: int)

## Fired when a run ends, carrying its result label and summary context.
signal run_ended(p_result: StringName, p_run_context: Dictionary)

# ── AudioMiddleware ───────────────────────────────────────────────────────────

## Fired when an audio stem event is detected (e.g. beat, loop, transition).
signal stem_event_detected(stem_id: String, event_type: String, intensity: float)

# ── InputRouter ───────────────────────────────────────────────────────────────

## Fired when the active input device changes.
## device is an InputRouter.InputDevice enum value, widened to int to avoid coupling.
signal device_changed(device: int)

# ── LayerManager ─────────────────────────────────────────────────────────────

## Fired when a modal layer opens.
signal modal_opened

## Fired when a modal layer closes.
signal modal_closed

# ── SafeZoneManager ───────────────────────────────────────────────────────────

## Fired when the computed safe-area rect changes (e.g. notch/letterbox change).
signal safe_area_changed(rect: Rect2)

## Fired when the display aspect-ratio mode changes.
## mode is a SafeZoneManager.AspectMode enum value, widened to int to avoid coupling.
signal aspect_ratio_changed(mode: int)
